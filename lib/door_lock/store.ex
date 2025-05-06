defmodule DoorLock.Store do
  @moduledoc """
  A GenServer that creates an ETS table to store the state of the pressed buttons.

  Benefits of using this strategy vs. using an Agent:

  - State persistence across process crashes.
  - Agent state is stored in the process heap vs. ETS tables are stored in a separate
  memory space from the Erlang VM heap, which means they don't contribute to garbage
  collection pressure.
  """

  use GenServer
  require Logger

  @table_name :door_lock_store

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_pressed_buttons() do
    case :ets.lookup(@table_name, :pressed_buttons) do
      [{:pressed_buttons, value}] -> value
      [] -> []
    end
  end

  def put_pressed_buttons(buttons) do
    :ets.insert(@table_name, {:pressed_buttons, buttons})
    :ok
  end

  # Server callbacks

  @impl true
  def init(_) do
    Logger.info("Creating ETS table: #{@table_name}")

    table =
      :ets.new(@table_name, [
        # Type of table
        :set,
        # Give it a name so other processes can access it
        :named_table,
        # Allow any process to read/write
        :public
        # # Optimize for concurrent reads
        # read_concurrency: true,
        # # Optimize for concurrent writes
        # write_concurrency: true
      ])

    # Initialize with default values
    :ets.insert(@table_name, {:pressed_buttons, []})

    {:ok, %{table: table}}
  end
end
