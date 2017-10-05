defmodule NeuralNetwork.Genotype do
  defstruct [:cortex, :sensors, :neurons, :actuators]

  alias NeuralNetwork.{Sensor, Neuron, Actuator}

  def example() do
    sensors = [
      %Sensor{id: :sensor_1, outbound_nodes: [:neuron_1_1], value: random_value()}
    ]

    neurons = [
      %Neuron{id: :neuron_1_1, 
        inbound_nodes: [
          %{id: :sensor_1, value: random_value(), weight: random_value(), received: false}
        ],
        outbound_nodes: [:neuron_2_1, :neuron_2_2],
        bias: 1.0
      },
      %Neuron{id: :neuron_2_1, 
        inbound_nodes: [
          %{id: :neuron_1_1, value: random_value(), weight: random_value(), received: false}
        ],
        outbound_nodes: [:neuron_3_1],
        bias: 1.0
      },
      %Neuron{id: :neuron_2_2, 
        inbound_nodes: [
          %{id: :neuron_1_1, value: random_value(), weight: random_value(), received: false}
        ],
        outbound_nodes: [:neuron_3_1],
        bias: 1.0
      },
      %Neuron{id: :neuron_3_1, 
        inbound_nodes: [
          %{id: :neuron_2_1, value: random_value(), weight: random_value(), received: false},
          %{id: :neuron_2_2, value: random_value(), weight: random_value(), received: false}
        ],
        outbound_nodes: [:actuator_1],
        bias: 1.0
      }
    ]

    actuators = [
      %Actuator{id: :actuator_1}
    ]

    %__MODULE__{sensors: sensors, neurons: neurons, actuators: actuators}
  end

  defp random_value(), do: :rand.uniform()
end
