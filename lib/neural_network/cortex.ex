defmodule NeuralNetwork.Cortex do
  use GenServer

  alias NeuralNetwork.{Sensor}

  defstruct [:sensors, :actuators, :count]

  def start_link(%__MODULE__{} = cortex) do
    GenServer.start_link(__MODULE__, cortex, name: :cortex)
  end

  def trigger(), do: GenServer.cast(:cortex, :trigger)

  def handle_cast(:trigger, cortex) do
    updated_count = cortex.count - 1

    cond do
      updated_count > 0 ->
        Enum.each(cortex.sensors, fn(sensor) -> Sensor.sense(sensor.id) end)

      true ->
        IO.puts("Cortex: end of game.")
    end
    

    {:noreply, %{cortex | count: updated_count}}
  end
end
