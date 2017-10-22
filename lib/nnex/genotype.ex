defmodule NNex.Genotype do
  @moduledoc """
    Creates all elements of any neural network system in a minimal start setup and links them together:
    * Agent
    * Cortex
    * Sensors
    * Neurons
    * Actuators

    These elements are being persisted on disc via NNex.Repo

    During training phase Genotype can apply mutations to the phenotype and persist them.
  """
  defstruct [
    :cortex, 
    :sensors, 
    :neurons, 
    :actuators,
    :fitness_score,
    :outcome
  ]

  alias NNex.{Agent, Sensor, Neuron, Actuator, Cortex, Constraint, Repo, Morphology}

  @doc """
    Setup function to create agent, cortex, sensors, neurons, actuators
  """
  def create_start_phenotype(specie_id, %Constraint{morphology: morphology, activation_funs: activation_funs} = constraint) do
    cortex = Repo.create(%Cortex{})

    sensors_neurons =
      Enum.map(Morphology.sensor_types(morphology), fn type ->
        with sensor <- Repo.create(%Sensor{type: type}),
          neuron <- create_neuron(select_random_activation_fun(activation_funs), [sensor.id], []) 
        do
          Repo.save(%Sensor{sensor | outbound_ids: [neuron.id]})
          {sensor, neuron}
        end
      end)

    actuators_neurons = 
      Enum.map(Morphology.actuator_types(morphology), fn type ->
        with actuator <- create_actuator(type, cortex.id),
          neuron <- create_neuron(select_random_activation_fun(activation_funs), [], [actuator.id]) 
        do
          {actuator, neuron}
        end
      end)

    updated_sensors_neurons = 
      Enum.map(sensors_neurons, fn {_, sensor_neuron} -> 
        outbound_ids = Enum.map(actuators_neurons, fn {_, actuator_neuron} -> actuator_neuron.id end)
        %Neuron{sensor_neuron | outbound_ids: outbound_ids }
      end)

    updated_actuators_neurons = 
      Enum.map(actuators_neurons, fn {_, actuator_neuron} -> 
        inbound_ids = Enum.map(sensors_neurons, fn {_, sensor_neuron} -> sensor_neuron.id end)
        %Neuron{actuator_neuron | inbound_ids: inbound_ids }
      end)

    all_neurons = updated_sensors_neurons ++ updated_actuators_neurons
  
    Enum.each(all_neurons, fn neuron -> Repo.save(neuron) end)

    sensor_ids = Enum.map(sensors_neurons, fn {sensor, _} -> sensor.id end)
    neuron_ids = Enum.map(all_neurons, fn neuron -> neuron.id end)
    actuator_ids = Enum.map(actuators_neurons, fn {actuator, _} -> actuator.id end)
    
    pattern = [length(sensors_neurons), length(actuators_neurons)]

    cortex = %{cortex | sensor_ids: sensor_ids, actuator_ids: actuator_ids}
    :ok = Repo.save(cortex)

    agent = create_agent(specie_id, cortex.id, pattern, constraint)

    {:ok, agent.id, cortex.id, sensor_ids, neuron_ids, actuator_ids, pattern}
  end

  defp create_agent(specie_id, cortex_id, pattern, constraint) do
    agent = %Agent{
      cortex_id: cortex_id,
      specie_id: specie_id,
      constraint: constraint,
      generation: 0,
      pattern: pattern,
      evolution_history: []
    }

    Repo.create(agent)
  end

  defp create_actuator(type, cortex_id) do
    actuator = %Actuator{
      type: type,
      cortex_id: cortex_id
    }

    Repo.create(actuator)
  end

  defp create_neuron(activation_fun, inbound_ids, outbound_ids) do
    neuron = %Neuron{
      inbound_ids: Enum.map(inbound_ids, & %{id: &1, weight: Neuron.random_weight(), value: nil}),
      outbound_ids: outbound_ids,
      activation_fun: activation_fun
    }

    Repo.create(neuron)
  end

  defp select_random_activation_fun([]), do: :tanh
  defp select_random_activation_fun(activation_funs), do: List.pop_at(activation_funs, :rand.uniform(length(activation_funs)))

  def fingerprint(agent_id) do
    Repo.find(Agent, agent_id)
  end
end
