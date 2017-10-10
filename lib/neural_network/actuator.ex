defmodule NeuralNetwork.Actuator do
  use GenServer

  alias NeuralNetwork.{Scape, Cortex}

  defstruct [:id]

  def start_link(%__MODULE__{id: actuator_name} = actuator) do
    GenServer.start_link(__MODULE__, actuator, name: actuator_name)
  end

  def handle_cast({:inbound_signal, _input_id, input_value}, actuator) do
    with {life_cycle, total_fitness, outcome} <- Scape.act(input_value), do: Cortex.trigger(life_cycle, total_fitness, outcome)

    {:noreply, actuator}
  end
end
