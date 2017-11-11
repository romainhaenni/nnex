defmodule NNex.Genotype do
  @moduledoc """
    Creates all elements of any neural network system in a minimal start setup and links them together:
    * Agent
    * Cortex
    * Sensors
    * Neurons
    * Actuators

    These elements are being persisted on disc via NNex.Repo

    During training phase mutations can apply to the genotype:
    * Mutate/reset bias
    * Mutate/reset weight
    * Mutate/reset activation_fun
    * Add/remove bias
    * Add/remove sensor
    * Add/remove neuron
    * Add/remove actuator
    * Add/remove/splice link
  """
  defstruct [
    :cortex, 
    :sensors, 
    :neurons, 
    :actuators
  ]

  alias NNex.{Agent, Sensor, Neuron, Actuator, Cortex, Repo}

  @doc """
    Setup function to create agent, cortex, sensors, neurons, actuators
  """
  def seed(agent) do
    cortex = Repo.create(%Cortex{})

    %{sensor_types: sensor_types, actuator_types: actuator_types, activation_funs: activation_funs} = agent.scape.morphology()

    sensors = Enum.map(sensor_types, fn type -> Repo.create(%Sensor{type: type, scape_id: agent.id}) end)

    sensor_neurons = for _ <- 1..length(sensors), do: create_neuron(select_random_activation_fun(activation_funs), Enum.map(sensors, fn sensor -> sensor.id end), [])

    sensors = Enum.map(sensors, fn sensor -> %{sensor | outbound_nodes: Enum.map(sensor_neurons, fn neuron -> {Neuron, neuron.id} end)} end)

    actuators = Enum.map(actuator_types, fn type -> Repo.create(%Actuator{type: type, cortex_id: cortex.id, scape_id: agent.id}) end)

    actuator_neurons = for _ <- 1..length(actuators), do: create_neuron(select_random_activation_fun(activation_funs), [], Enum.map(actuators, fn actuator -> {Actuator, actuator.id} end))

    actuators = Enum.map(actuators, fn actuator -> %{actuator | inbound_nodes: Enum.map(actuator_neurons, fn neuron -> %{id: neuron.id, value: nil} end)} end)

    sensor_neurons = Enum.map(sensor_neurons, fn neuron -> %{neuron | outbound_nodes: Enum.map(actuator_neurons, fn actuator_neuron -> {Neuron, actuator_neuron.id} end)} end)

    actuator_neurons = Enum.map(actuator_neurons, fn neuron -> %{neuron | inbound_nodes: Enum.map(sensor_neurons, fn sensor_neuron -> %{id: sensor_neuron.id, weight: Neuron.random_weight(), value: nil} end)} end)

    all_neurons = sensor_neurons ++ actuator_neurons

    sensor_ids = Enum.map(sensors, fn sensor -> sensor.id end)
    actuator_ids = Enum.map(actuators, fn actuator -> actuator.id end)

    cortex = %{cortex | agent_id: agent.id, sensor_ids: sensor_ids, actuator_ids: actuator_ids}

    # genotype = save(%__MODULE__{cortex: cortex, sensors: sensors, neurons: all_neurons, actuators: actuators})
    # agent = %{agent | genotype: genotype}
    # Repo.save(agent)
    # agent
    genotype = %__MODULE__{cortex: cortex, sensors: sensors, neurons: all_neurons, actuators: actuators}
    %{agent | genotype: genotype}
  end

  def save(%__MODULE__{cortex: cortex, sensors: sensors, neurons: neurons, actuators: actuators} = genotype) do
    Repo.save(cortex)
    Enum.each(sensors, &Repo.save(&1))
    Enum.each(neurons, &Repo.save(&1))
    Enum.each(actuators, &Repo.save(&1))
    genotype
  end

  def clone(agent) do
    %__MODULE__{cortex: cortex, sensors: sensors, neurons: neurons, actuators: actuators} = agent.genotype
    new_sensors = Enum.map(sensors, &Repo.create(%{&1 | scape_id: agent.id}))
    sensor_id_map = Enum.zip(Enum.map(sensors, & &1.id), Enum.map(new_sensors, & &1.id))

    new_neurons = Enum.map(neurons, &Repo.create(&1))
    neuron_id_map = Enum.zip(Enum.map(neurons, & &1.id), Enum.map(new_neurons, & &1.id))
    
    new_actuators = Enum.map(actuators, &Repo.create(%{&1 | scape_id: agent.id}))
    actuator_id_map = Enum.zip(Enum.map(actuators, & &1.id), Enum.map(new_actuators, & &1.id))

    all_id_map = sensor_id_map ++ neuron_id_map ++ actuator_id_map

    cloned_sensors = Enum.map(new_sensors, fn new_sensor -> %{new_sensor | outbound_nodes: update_id_in_nodes(new_sensor.outbound_nodes, all_id_map)} end)
    cloned_neurons = Enum.map(new_neurons, fn new_neuron -> %{new_neuron | inbound_nodes: update_id_in_map(new_neuron.inbound_nodes, all_id_map), outbound_nodes: update_id_in_nodes(new_neuron.outbound_nodes, all_id_map)} end)
    cloned_actuators = Enum.map(new_actuators, fn new_actuator -> %{new_actuator | inbound_nodes: update_id_in_map(new_actuator.inbound_nodes, all_id_map)} end)

    sensor_ids = Enum.map(cloned_sensors, & &1.id)
    actuator_ids = Enum.map(cloned_actuators, & &1.id)
    cloned_cortex = %{cortex | agent_id: agent.id, sensor_ids: sensor_ids, actuator_ids: actuator_ids} |> Repo.create

    updated_cloned_actuators =
      Enum.map(cloned_actuators, fn actuator -> %{actuator | cortex_id: cloned_cortex.id} end)
      

    %{agent.genotype | cortex: cloned_cortex, sensors: cloned_sensors, neurons: cloned_neurons, actuators: updated_cloned_actuators}
  end

  def create_agent(specie_id, scape) do
    %Agent{
      scape: scape,
      specie_id: specie_id,
      generation: 0,
      evolution_history: []
    }
    |> Repo.create()
  end

  def clone_agent(agent) do
    cloned_agent = Repo.create(agent)
    %{cloned_agent | genotype: clone(cloned_agent)}
  end

  defp create_neuron(activation_fun, inbound_ids, outbound_nodes) do
    %Neuron{
      inbound_nodes: Enum.map(inbound_ids, & %{id: &1, weight: Neuron.random_weight(), value: nil}),
      outbound_nodes: outbound_nodes,
      activation_fun: activation_fun,
      bias: Neuron.random_weight()
    }
    |> Repo.create()
  end

  defp select_random_activation_fun([]), do: :tanh
  defp select_random_activation_fun(activation_funs) do
    with {fun, _} <- List.pop_at(activation_funs, :rand.uniform(length(activation_funs))), do: fun
  end

  defp update_id_in_nodes(nodes, []), do: nodes
  defp update_id_in_nodes(nodes, [{old_id, new_id} | id_map_tail]) do
    updated_nodes =
      Enum.map(nodes, fn {node, id} ->
        case id == old_id do
          true ->
            {node, new_id}

          false ->
            {node, id}
        end
      end)
    update_id_in_nodes(updated_nodes, id_map_tail)
  end

  defp update_id_in_map(nodes, []), do: nodes
  defp update_id_in_map(nodes, [{old_id, new_id} | id_map_tail]) do
    updated_nodes =
      Enum.map(nodes, fn item -> 
        case item.id == old_id do
          true ->
            Map.update!(item, :id, fn _ -> new_id end)

          false ->
            item
        end
      end)
    update_id_in_map(updated_nodes, id_map_tail)
  end

  def print(genotype) do
    IO.puts("*** Genotype Details ***")
    IO.puts("Sensors: #{length(genotype.sensors)}")
    IO.puts("Neurons: #{length(genotype.neurons)}")
    IO.puts("Actuators: #{length(genotype.actuators)}")
  end
end
