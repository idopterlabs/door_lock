defmodule DoorLock.LockManager do
  use Supervisor

  alias DoorLock.Lock

  require Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    children = [
      {DoorLock.Lock, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def register_callback(callback_pid) do
    Lock.register_callback(callback_pid)
  end

  def press_button(code) do
    Lock.press_button(code)
  end

  def is_locked do
    Lock.is_locked()
  end

  def pressed_buttons do
    Lock.pressed_buttons()
  end
end
