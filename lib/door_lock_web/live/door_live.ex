defmodule DoorLockWeb.DoorLive do
  use DoorLockWeb, :live_view

  alias DoorLock.Lock

  def mount(_params, _session, socket) do
    {:ok, assign(socket, is_locked: true)}
  end

  def handle_event("press_button", %{"num" => num}, socket) do
    IO.puts("Pressed button: #{num}")
    _ = Lock.press_button(String.to_integer(num))

    {:noreply, assign(socket, is_locked: Lock.is_locked())}
  end

  def render(assigns) do
    ~H"""
    <div class="flex py-10 justify-center min-h-screen">
      <div class="relative w-[500px] h-[800px] bg-amber-600 rounded-lg shadow-2xl overflow-hidden">
        <!-- Door Frame -->
        <div class="absolute inset-0 border-8 border-amber-700 rounded-lg"></div>
        
    <!-- Door Panels -->
        <div class="absolute inset-0 flex flex-col p-8">
          <!-- Top Panel -->
          <div class="flex-1 border-4 border-amber-700 rounded-lg"></div>
          
    <!-- Middle Panel -->
          <div class="flex-1 border-4 border-amber-700 rounded-lg my-4"></div>
          
    <!-- Bottom Panel -->
          <div class="flex-1 border-4 border-amber-700 rounded-lg"></div>
        </div>
        
    <!-- Door Handle -->
        <div class="absolute right-12 top-1/2 -translate-y-1/2">
          <div class="w-6 h-20 bg-amber-500 rounded-full"></div>
          <div class="absolute -right-2 top-1/2 -translate-y-1/2 w-4 h-12 bg-amber-500 rounded-full">
          </div>
        </div>
        
    <!-- Keypad -->
        <div class="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-80 h-96 bg-gray-700 rounded-lg p-6">
          <div class="grid grid-cols-3 gap-6">
            <%= for num <- 1..9 do %>
              <button
                phx-click="press_button"
                phx-value-num={num}
                class="w-full h-20 bg-gray-600 hover:bg-gray-500 text-white text-3xl font-bold rounded-lg transition-colors duration-200"
              >
                {num}
              </button>
            <% end %>
          </div>
          <!-- Status Label -->
          <div class="mt-6 text-center">
            <%= if @is_locked do %>
              <div class="inline-flex items-center px-4 py-2 bg-red-600 text-white rounded-lg">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z"
                    clip-rule="evenodd"
                  />
                </svg>
                <span class="font-semibold">LOCKED</span>
              </div>
            <% else %>
              <div class="inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-lg">
                <span class="font-semibold">UNLOCKED</span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
