defmodule NeuralNetwork.Genotype do
  defstruct [
    :cortex, 
    :sensors, 
    :neurons, 
    :actuators,
    :fitness_score,
    :outcome
  ]

  alias NeuralNetwork.{Sensor, Neuron, Actuator, Cortex}

  def random_start_network() do
    sensors = [
      %Sensor{id: :sensor_1, type: :left, outbound_nodes: [:neuron_1_1, :neuron_1_2]},
      %Sensor{id: :sensor_2, type: :right, outbound_nodes: [:neuron_1_1, :neuron_1_2]}
    ]

    # [2,3,3,1]
    # neurons = [
    #   build_random_neuron(:neuron_1_1, [:sensor_1, :sensor_2], [:neuron_2_1, :neuron_2_2, :neuron_2_3]),
    #   build_random_neuron(:neuron_1_2, [:sensor_1, :sensor_2], [:neuron_2_1, :neuron_2_2, :neuron_2_3]),
    #   build_random_neuron(:neuron_2_1, [:neuron_1_1, :neuron_1_2], [:neuron_3_1, :neuron_3_2, :neuron_3_3]),
    #   build_random_neuron(:neuron_2_2, [:neuron_1_1, :neuron_1_2], [:neuron_3_1, :neuron_3_2, :neuron_3_3]),
    #   build_random_neuron(:neuron_2_3, [:neuron_1_1, :neuron_1_2], [:neuron_3_1, :neuron_3_2, :neuron_3_3]),
    #   build_random_neuron(:neuron_3_1, [:neuron_2_1, :neuron_2_2, :neuron_2_3], [:neuron_4_1]),
    #   build_random_neuron(:neuron_3_2, [:neuron_2_1, :neuron_2_2, :neuron_2_3], [:neuron_4_1]),
    #   build_random_neuron(:neuron_3_3, [:neuron_2_1, :neuron_2_2, :neuron_2_3], [:neuron_4_1]),
    #   build_random_neuron(:neuron_4_1, [:neuron_3_1, :neuron_3_2, :neuron_3_3], [:actuator_1])
    # ]

    # [2,2,1]
    neurons = [
      build_random_neuron(:neuron_1_1, [:sensor_1, :sensor_2], [:neuron_2_1, :neuron_2_2]),
      build_random_neuron(:neuron_1_2, [:sensor_1, :sensor_2], [:neuron_2_1, :neuron_2_2]),
      build_random_neuron(:neuron_2_1, [:neuron_1_1, :neuron_1_2], [:neuron_3_1]),
      build_random_neuron(:neuron_2_2, [:neuron_1_1, :neuron_1_2], [:neuron_3_1]),
      build_random_neuron(:neuron_3_1, [:neuron_2_1, :neuron_2_2], [:actuator_1])
    ]

    actuators = [
      %Actuator{id: :actuator_1}
    ]

    cortex = %Cortex{sensors: sensors, actuators: actuators, total_fitness: 0}

    %__MODULE__{sensors: sensors, neurons: neurons, actuators: actuators, cortex: cortex, fitness_score: 0, outcome: []}
  end

  defp random_value(), do: Neuron.random_weight()

  defp build_random_neuron(id, inbound_ids, outbound_ids) do
    %Neuron{id: id, 
      inbound_nodes: Enum.map(inbound_ids, & %{id: &1, weight: random_value(), value: nil}),
      outbound_nodes: outbound_ids,
      bias: random_value()
    }
  end
end
