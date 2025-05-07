defmodule DoorLockWeb.DoorLive do
  use DoorLockWeb, :live_view

  alias DoorLock.LockManager

  def mount(_params, _session, socket) do
    if connected?(socket) do
      LockManager.register_callback(self())
    end

    {:ok,
     assign(socket,
       is_locked: true,
       pressed_numbers: []
     )}
  end

  def handle_event("press_button", %{"num" => num}, socket) do
    _ = LockManager.press_button(String.to_integer(num))

    # Not ideal solution to wait for the Lock process to
    # restart in case it crashes.
    Process.send_after(self(), :update_state, 100)

    {:noreply, socket}
  end

  def handle_info(:lock, socket) do
    {:noreply,
     assign(socket,
       is_locked: true,
       pressed_numbers: []
     )}
  end

  def handle_info(:update_state, socket) do
    {:noreply,
     assign(socket,
       is_locked: LockManager.is_locked(),
       pressed_numbers: LockManager.pressed_buttons()
     )}
  end
end
