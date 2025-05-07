defmodule DoorLockWeb.DoorLive do
  use DoorLockWeb, :live_view

  alias DoorLock.LockManager

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Registers this LV to be called when the lock state changes
      LockManager.register_callback()
    end

    {:ok,
     assign(socket,
       is_locked: true,
       pressed_numbers: []
     )}
  end

  def handle_event("press_button", %{"num" => num}, socket) do
    _ = LockManager.press_button(String.to_integer(num))

    {:noreply,
     assign(socket,
       is_locked: LockManager.is_locked(),
       pressed_numbers: LockManager.pressed_buttons()
     )}
  end

  def handle_info(:lock, socket) do
    {:noreply,
     assign(socket,
       is_locked: true,
       pressed_numbers: []
     )}
  end
end
