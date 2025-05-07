defmodule DoorLock.LockManager do
  use DynamicSupervisor

  alias DoorLock.Lock

  require Logger

  ## Public API

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def register_callback do
    with {:ok, lock_pid} <- get_or_create_lock() do
      Lock.register_callback(lock_pid, self())
    end
  end

  def press_button(code) do
    with {:ok, lock_pid} <- get_or_create_lock() do
      Lock.press_button(lock_pid, code)
    end
  end

  ## Callbacks

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 3,
      max_seconds: 5
    )
  end

  def is_locked do
    with {:ok, lock_pid} <- get_or_create_lock() do
      Lock.is_locked(lock_pid)
    end
  end

  def pressed_buttons do
    with {:ok, lock_pid} <- get_or_create_lock() do
      Lock.pressed_buttons(lock_pid)
    end
  end

  ## Private Functions

  defp get_or_create_lock do
    case start_lock() do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        wait_for_process(pid)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp start_lock do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Lock, [code: get_lock_code(), is_registered: true]}
    )
  end

  defp get_lock_code do
    Application.get_env(:door_lock, __MODULE__)
    |> Keyword.fetch!(:lock_code)
  end

  defp wait_for_process(pid) do
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, reason} ->
        {:error, reason}
    after
      0 ->
        Process.demonitor(ref, [:flush])

        try do
          :sys.get_state(pid)
          {:ok, pid}
        catch
          :exit, _ -> {:error, :process_not_ready}
        end
    end
  end
end
