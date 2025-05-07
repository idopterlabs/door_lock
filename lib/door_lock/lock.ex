defmodule DoorLock.Lock do
  @behaviour :gen_statem

  alias DoorLock.Store

  @default_lock_again_timeout 5_000

  def start_link(opts) do
    code = Keyword.fetch!(opts, :code)

    {lock_again_timeout, opts} =
      Keyword.pop(opts, :lock_again_timeout, @default_lock_again_timeout)

    {is_registered, opts} = Keyword.pop(opts, :is_registered, true)

    if is_registered do
      :gen_statem.start_link({:local, __MODULE__}, __MODULE__, {code, lock_again_timeout}, opts)
    else
      :gen_statem.start_link(__MODULE__, {code, lock_again_timeout}, opts)
    end
  end

  def is_locked(pid \\ __MODULE__) do
    :gen_statem.call(pid, :is_locked)
  end

  def press_button(pid \\ __MODULE__, code) do
    :gen_statem.cast(pid, {:press_button, code})
  end

  def pressed_buttons(pid \\ __MODULE__) do
    :gen_statem.call(pid, :pressed_buttons)
  end

  def register_callback(pid \\ __MODULE__, callback_pid) when is_pid(callback_pid) do
    :gen_statem.call(pid, {:register_callback, callback_pid})
  end

  ## Callbacks

  def locked(:cast, {:press_button, code}, data) do
    # Does something "dangerous" with code
    # to force a process crash
    _dangerous_code = 10 / code

    pressed_buttons =
      (data.pressed_buttons ++ [code])
      |> Enum.take(-4)

    Store.put_pressed_buttons(pressed_buttons)

    data = %{data | pressed_buttons: pressed_buttons}

    if pressed_buttons == data.code do
      actions = [{:state_timeout, data.lock_again_timeout, :lock}]
      {:next_state, :unlocked, data, actions}
    else
      {:keep_state, data}
    end
  end

  def locked({:call, from}, :is_locked, _data) do
    {:keep_state_and_data, {:reply, from, true}}
  end

  def locked({:call, from}, :pressed_buttons, %{pressed_buttons: pressed_buttons} = _data) do
    {:keep_state_and_data, {:reply, from, pressed_buttons}}
  end

  def locked({:call, from}, {:register_callback, callback_pid}, data) do
    {:keep_state, %{data | callback_pid: callback_pid}, {:reply, from, :ok}}
  end

  def unlocked(:state_timeout, :lock, data) do
    if is_pid(data.callback_pid) do
      send(data.callback_pid, :lock)
    end

    {:next_state, :locked, %{data | pressed_buttons: []}}
  end

  def unlocked({:call, from}, :is_locked, _data) do
    {:keep_state_and_data, {:reply, from, false}}
  end

  def unlocked({:call, from}, :pressed_buttons, %{pressed_buttons: pressed_buttons} = _data) do
    {:keep_state_and_data, {:reply, from, pressed_buttons}}
  end

  def init({code, lock_again_timeout}) do
    # Retrieves the pressed buttons from the store
    pressed_buttons = Store.get_pressed_buttons()

    {:ok, :locked,
     %{
       code: code,
       lock_again_timeout: lock_again_timeout,
       pressed_buttons: pressed_buttons,
       callback_pid: nil
     }}
  end

  def callback_mode, do: :state_functions

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end
end
