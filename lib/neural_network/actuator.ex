defmodule NeuralNetwork.Actuator do
  use GenServer

  defstruct [:id]

  def start_link(%__MODULE__{id: actuator_name} = actuator) do
    GenServer.start_link(__MODULE__, actuator, name: actuator_name)
  end

  def act(actuator_name, value), do: GenServer.cast(actuator_name, {:act, value})

  # def inbound_signal(node_name, _input_id, input_value) do
  #   GenServer.cast(node_name, {:inbound_signal, input_value})
  # end

  def handle_cast({:act, value}, actuator) do
    IO.puts("#{actuator.id}: Got #{inspect(value)}")

    {:noreply, actuator}
  end

  def handle_cast({:inbound_signal, _input_id, input_value}, actuator) do
    act(actuator.id, input_value)
    NeuralNetwork.Cortex.trigger()

    {:noreply, actuator}
  end
end
