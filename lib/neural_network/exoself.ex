defmodule NeuralNetwork.Exoself do
  use GenServer

  alias NeuralNetwork.{Cortex, Genotype, Sensor, Neuron, Actuator}

  def start_link(_) do
    GenServer.start_link(__MODULE__, Genotype.example())
  end

  def init(%Genotype{sensors: sensors, neurons: neurons, actuators: actuators} = phenotype) do
    children = [
      Enum.map(sensors, &{Sensor, &1}),
      Enum.map(neurons, fn neuron -> Supervisor.child_spec({Neuron, neuron}, id: neuron.id) end),
      Enum.map(actuators, &{Actuator, &1}),
      {Cortex, %Cortex{sensors: sensors, actuators: actuators, count: 1000}}
    ] |> List.flatten

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
    
    {:ok, phenotype}
  end
end
