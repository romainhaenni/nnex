defmodule NNex.GenotypeMutator do
    @moduledoc """
    During training phase mutations can apply to the genotype:
    * Mutate/reset bias
    * Mutate/reset weight
    * Mutate/reset activation_fun
    * ? Add/remove bias
    * ? Add/remove sensor
    * Add/remove neuron
    * ? Add/remove actuator
    * Add/remove link between neurons
    * ? Splice/Desplice link
  """

  alias NNex.{Neuron, Repo}

  @available_mutation_funs ~w(mutate_bias mutate_activation_fun mutate_weights add_neuron add_link remove_link)a

  def mutate(agent), do: mutate(agent, @available_mutation_funs, :math.pow(length(agent.genotype.neurons), 0.5) |> round() |> :rand.uniform())

  def mutate(agent, _, count) when count <= 0, do: agent

  def mutate(agent, mutation_funs, count) do
    with {mutation_fun, _} <- List.pop_at(mutation_funs, :rand.uniform(length(mutation_funs)) - 1),
      {result, mutated_agent} = apply(__MODULE__, mutation_fun, List.wrap(agent)) do
        case result do
          :ok ->
            mutate(mutated_agent, mutation_funs, count - 1)

          :not_mutated ->
            mutate(mutated_agent, mutation_funs, count)
        end
    end
  end

  # def add_bias do
    
  # end

  # def remove_bias do
    
  # end

  # def add_sensor do
    
  # end

  # def remove_sensor do
    
  # end

  def add_neuron(agent) do
    genotype = agent.genotype
    {{neuronA, indexA}, {neuronB, indexB}} = random_neuron_pair(genotype)

    new_neuron = 
      %Neuron{
        inbound_nodes: List.wrap(%{id: neuronA.id, weight: Neuron.random_weight(), value: nil}),
        outbound_nodes: List.wrap({Neuron, neuronB.id}),
        activation_fun: neuronA.activation_fun,
        bias: Neuron.random_weight()
      }
      |> Repo.new()

    updated_neuronA = %{neuronA | outbound_nodes: [{Neuron, new_neuron.id} | neuronA.outbound_nodes]}
    updated_neuronB = %{neuronB | inbound_nodes: [%{id: new_neuron.id, weight: Neuron.random_weight(), value: nil} | neuronB.inbound_nodes]}

    updated_neurons = 
      genotype.neurons
      |> List.replace_at(indexA, updated_neuronA)
      |> List.replace_at(indexB, updated_neuronB)
      |> List.insert_at(-1, new_neuron)

    updated_genotype = %{genotype | neurons: updated_neurons}
    new_evolution_history = [{:add_neuron, nil} | agent.evolution_history]
    {:ok, %{agent | genotype: updated_genotype, evolution_history: new_evolution_history}}
  end

  def remove_neuron(agent) do
    genotype = agent.genotype
    {neuron_to_remove, _index} = random_neuron(genotype)

    case :rand.uniform() < perturb_probability(neuron_to_remove) do
      true ->
        updated_neurons =
          genotype.neurons
          |> Enum.map(fn neuron ->
            cond do
              neuron.id == neuron_to_remove.id ->
                []

              Enum.any?(neuron.outbound_nodes, fn {_, node_id} -> node_id == neuron_to_remove.id end) ->
                %{neuron | outbound_nodes: List.delete(neuron.outbound_nodes, {Neuron, neuron_to_remove.id})}

              Enum.any?(neuron.inbound_nodes, fn %{id: node_id} -> node_id == neuron_to_remove.id end) ->
                new_inbound_nodes = 
                  neuron.inbound_nodes
                  |> Enum.map(fn node -> 
                    case node.id == neuron_to_remove.id do
                      true -> []
                      false -> node
                    end
                  end)
                  |> List.flatten

                %{neuron | inbound_nodes: new_inbound_nodes}
              
              true -> neuron
            end
          end)
          |> List.flatten

        updated_sensors =
          genotype.sensors
          |> Enum.map(fn sensor ->
            cond do
              Enum.any?(sensor.outbound_nodes, fn {_, node_id} -> node_id == neuron_to_remove.id end) ->
                %{sensor | outbound_nodes: List.delete(sensor.outbound_nodes, {Neuron, neuron_to_remove.id})}
              
              true -> sensor
            end
          end)

        updated_actuators =
          genotype.actuators
          |> Enum.map(fn actuator ->
            cond do
              Enum.any?(actuator.inbound_nodes, fn %{id: node_id} -> node_id == neuron_to_remove.id end) ->
                updated_inbound_nodes = 
                  actuator.inbound_nodes
                  |> Enum.map(fn node -> 
                    case node.id == neuron_to_remove.id do
                      true -> []
                      false -> node
                    end
                  end)
                  |> List.flatten

                %{actuator | inbound_nodes: updated_inbound_nodes}
              
              true -> actuator
            end
          end)

        updated_genotype = %{genotype | sensors: updated_sensors, neurons: updated_neurons, actuators: updated_actuators}
        new_evolution_history = [{:remove_neuron, nil} | agent.evolution_history]
        {:ok, %{agent | genotype: updated_genotype, evolution_history: new_evolution_history}}

      false ->
        {:not_mutated, agent}
    end
  end

  # def add_actuator do
    
  # end

  # def remove_actuator do
    
  # end

  def add_link(agent) do
    genotype = agent.genotype
    {{neuronA, indexA}, {neuronB, indexB}} = random_neuron_pair(genotype)
    
    case Enum.any?(neuronA.outbound_nodes, fn {_, node_id} -> node_id == neuronB.id end) do
      true ->
        {:not_mutated, agent}

      false ->
        updated_neuronA = %{neuronA | outbound_nodes: [{Neuron, neuronB.id} | neuronA.outbound_nodes]}
        updated_neuronB = %{neuronB | inbound_nodes: [%{id: neuronA.id, weight: Neuron.random_weight(), value: nil} | neuronB.inbound_nodes]}

        updated_neurons = 
          genotype.neurons
          |> List.replace_at(indexA, updated_neuronA)
          |> List.replace_at(indexB, updated_neuronB)

        updated_genotype = %{genotype | neurons: updated_neurons}
        new_evolution_history = [{:add_link, nil} | agent.evolution_history]
        {:ok, %{agent | genotype: updated_genotype, evolution_history: new_evolution_history}}
    end
  end

  def remove_link(agent) do
    genotype = agent.genotype
    {random_neuron, _index} = random_neuron(genotype)

    case length(random_neuron.outbound_nodes) > 1 do
    # case :rand.uniform() < perturb_probability(random_neuron) do
      true ->
        {{_, random_outbound_id}, _} = List.pop_at(random_neuron.outbound_nodes, :rand.uniform(length(random_neuron.outbound_nodes)) - 1)

        updated_neurons =
          genotype.neurons
          |> Enum.map(fn other_neuron -> 
            cond do
              other_neuron.id == random_neuron.id -> 
                updated_outbound_nodes = List.delete(other_neuron.outbound_nodes, {Neuron, random_outbound_id})
                %{other_neuron | outbound_nodes: updated_outbound_nodes}
              
              other_neuron.id == random_outbound_id ->
                updated_inbound_nodes =
                  other_neuron.inbound_nodes
                  |> Enum.map(fn node ->
                    case node.id == random_outbound_id do
                      true ->
                        []

                      false ->
                        node

                    end
                  end)
                  |> List.flatten

                %{other_neuron | inbound_nodes: updated_inbound_nodes}

              true -> 
                other_neuron
            end
          end)

        updated_genotype = %{genotype | neurons: updated_neurons}
        new_evolution_history = [{:remove_link, nil} | agent.evolution_history]
        {:ok, %{agent | genotype: updated_genotype, evolution_history: new_evolution_history}}

      false ->
        {:not_mutated, agent}
    end
  end

  # def splice_link do
    
  # end

  def mutate_bias(agent) do
    genotype = agent.genotype
    {neuron, index} = random_neuron(genotype)

    case :rand.uniform() < perturb_probability(neuron) do
      true -> 
        updated_bias = (neuron.bias + Neuron.random_weight()) |> limit_saturation()

        neuron = %{neuron | bias: updated_bias}
        neurons = List.replace_at(genotype.neurons, index, neuron)
        updated_genotype = %{genotype | neurons: neurons}
        new_evolution_history = [{:mutate_bias, neuron.bias} | agent.evolution_history]
        {:ok, %{agent | genotype: updated_genotype, evolution_history: new_evolution_history}}

      false -> 
        {:not_mutated, agent}
    end
  end

  def mutate_activation_fun(agent) do
    genotype = agent.genotype
    {neuron, index} = random_neuron(genotype)

    case :rand.uniform() < perturb_probability(neuron) do
      true -> 
        %{activation_funs: activation_funs} = agent.scape.morphology()
        new_activation_fun = select_random_activation_fun(activation_funs)
        neuron = %{neuron | activation_fun: new_activation_fun}
        neurons = List.replace_at(genotype.neurons, index, neuron)
        updated_genotype = %{genotype | neurons: neurons}
        new_evolution_history = [{:mutate_activation_fun, new_activation_fun} | agent.evolution_history]
        {:ok, %{agent | genotype: updated_genotype, evolution_history: new_evolution_history}}

      false -> 
        {:not_mutated, agent}
    end
  end

  def mutate_weights(agent) do
    genotype = agent.genotype
    {neuron, index} = random_neuron(genotype)

    updated_inbound_nodes =
      Enum.map(neuron.inbound_nodes, fn node ->
        case :rand.uniform() < perturb_probability(neuron) do
          true -> %{node | weight: (node.weight + Neuron.random_weight()) |> limit_saturation()}
          false -> node
        end
      end)

    case neuron.inbound_nodes == updated_inbound_nodes do
      true ->
        {:not_mutated, agent}

      false ->
        neuron = %{neuron | inbound_nodes: updated_inbound_nodes}
        neurons = List.replace_at(genotype.neurons, index, neuron)
        updated_genotype = %{genotype | neurons: neurons}
        new_evolution_history = [{:mutate_weights, nil} | agent.evolution_history]
        {:ok, %{agent | genotype: updated_genotype, evolution_history: new_evolution_history}}
    end
  end

  defp limit_saturation(value) do
    upper_limit = :math.pi() * 2
    lower_limit = -:math.pi() * 2

    value |> max(lower_limit) |> min(upper_limit)
  end

  defp select_random_activation_fun([]), do: :tanh
  defp select_random_activation_fun(activation_funs) do
    with {fun, _} <- List.pop_at(activation_funs, :rand.uniform(length(activation_funs))-1), do: fun
  end

  defp perturb_probability(neuron) do
    case length(neuron.inbound_nodes) == 0 do
      true -> 0
      false -> (1 / :math.sqrt(length(neuron.inbound_nodes)))
    end
  end

  defp random_neuron(genotype) do 
    with index <- :rand.uniform(length(genotype.neurons)) - 1,
      {neuron, _} <- List.pop_at(genotype.neurons, index), do: {neuron, index}
  end

  defp random_neuron_pair(genotype) do
    {neuronA, indexA} = random_neuron(genotype)
    {neuronB, indexB} = random_neuron(%{genotype | neurons: List.delete_at(genotype.neurons, indexA)})

    indexB =
      cond do
        indexA <= indexB -> indexB + 1
        true -> indexB
      end

    {{neuronA, indexA}, {neuronB, indexB}}
  end
end
