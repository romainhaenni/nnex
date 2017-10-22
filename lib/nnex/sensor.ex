defmodule NNex.Sensor do
  use GenServer

  alias NNex.{Neuron, Scape}

  defstruct [:id, :type, :scape, :outbound_ids]

  def start_link(%__MODULE__{id: sensor_name} = sensor) do
    GenServer.start_link(__MODULE__, sensor, name: sensor_name)
  end

  def sense(sensor_name), do: GenServer.cast(sensor_name, :sense)

  def handle_cast(:sense, sensor) do
    sensed_value = Scape.sense(sensor.type)

    Enum.each(sensor.outbound_nodes, fn(node_name) -> Neuron.inbound_signal(node_name, sensor.id, sensed_value) end)

    {:noreply, sensor}
  end
end
