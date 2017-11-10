defmodule NNex.Sensor do
  use GenServer

  alias NNex.{Scape}

  defstruct [:id, :type, :scape_id, :outbound_nodes]

  def start_link(%__MODULE__{id: sensor_id} = sensor) do
    GenServer.start_link(__MODULE__, sensor, name: {:global, {__MODULE__, sensor_id}})
  end

  def sense(id), do: GenServer.cast({:global, {__MODULE__, id}}, :sense)

  def handle_cast(:sense, sensor) do
    sensed_value = Scape.sense(sensor.scape_id, sensor.type)

    Enum.each(sensor.outbound_nodes, fn {node, id} -> node.inbound_signal(id, sensor.id, sensed_value) end)

    {:noreply, sensor}
  end
end
