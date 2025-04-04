defmodule DoorLock.Lock do
  @behaviour :gen_statem

  @default_lock_again_timeout 20_000

  def is_locked(pid \\ __MODULE__) do
    :gen_statem.call(pid, :is_locked)
  end

  def press_button(pid \\ __MODULE__, code) do
    :gen_statem.cast(pid, {:press_button, code})
  end

  ## Callbacks

  def locked(:cast, {:press_button, code}, data) do
    pressed_buttons = data.pressed_buttons ++ [code]

    if pressed_buttons == data.code do
      actions = [{:state_timeout, data.lock_again_timeout, :lock}]
      {:next_state, :unlocked, data, actions}
    else
      {:keep_state, %{data | pressed_buttons: pressed_buttons}}
    end
  end

  def locked({:call, from}, :is_locked, _data) do
    {:keep_state_and_data, {:reply, from, true}}
  end

  def unlocked(:state_timeout, :lock, data) do
    {:next_state, :locked, %{data | pressed_buttons: []}}
  end

  def unlocked({:call, from}, :is_locked, _data) do
    {:keep_state_and_data, {:reply, from, false}}
  end

  def start_link(opts) do
    {code, opts} = Keyword.pop(opts, :code)

    {lock_again_timeout, opts} =
      Keyword.pop(opts, :lock_again_timeout, @default_lock_again_timeout)

    {is_registered, opts} = Keyword.pop(opts, :is_registered, true)

    if is_registered do
      :gen_statem.start_link({:local, __MODULE__}, __MODULE__, {code, lock_again_timeout}, opts)
    else
      :gen_statem.start_link(__MODULE__, {code, lock_again_timeout}, opts)
    end
  end

  def init({code, lock_again_timeout}) do
    {:ok, :locked, %{code: code, lock_again_timeout: lock_again_timeout, pressed_buttons: []}}
  end

  def callback_mode, do: :state_functions

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
