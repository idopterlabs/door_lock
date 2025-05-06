defmodule DoorLockWeb.DoorLive do
  use DoorLockWeb, :live_view

  alias DoorLock.Lock

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Lock.register_callback(self())
    end

    {:ok,
     assign(socket,
       is_locked: Lock.is_locked(),
       pressed_numbers: Lock.pressed_buttons()
     )}
  end

  def handle_event("press_button", %{"num" => num}, socket) do
    _ = Lock.press_button(String.to_integer(num))

    {:noreply,
     assign(socket,
       is_locked: Lock.is_locked(),
       pressed_numbers: Lock.pressed_buttons()
     )}
  end

  def handle_info(:lock, socket) do
    {:noreply,
     assign(socket,
       is_locked: true,
       pressed_numbers: []
     )}
  end

  def handle_info({:state_change, is_locked, pressed_buttons}, socket) do
    {:noreply,
     assign(socket,
       is_locked: is_locked,
       pressed_numbers: pressed_buttons
     )}
  end
end
