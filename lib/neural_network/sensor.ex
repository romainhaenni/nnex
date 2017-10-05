defmodule NeuralNetwork.Sensor do
  use GenServer

  alias NeuralNetwork.{Neuron}

  defstruct [:id, :outbound_nodes, :value]

  def start_link(%__MODULE__{id: sensor_name} = sensor) do
    GenServer.start_link(__MODULE__, sensor, name: sensor_name)
  end

  def sense(sensor_name), do: GenServer.cast(sensor_name, :sense)

  def handle_cast(:sense, sensor) do
    sensed_value = :rand.uniform()

    Enum.each(sensor.outbound_nodes, fn(node_name) -> Neuron.inbound_signal(node_name, sensor.id, sensed_value) end)

    {:noreply, %{sensor | value: sensed_value}}
  end
end
