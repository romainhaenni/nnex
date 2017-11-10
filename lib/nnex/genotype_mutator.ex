defmodule NNex.GenotypeMutator do
    @moduledoc """
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

  alias NNex.{Neuron}

  def mutate(agent), do: mutate(agent, ~w(mutate_bias mutate_activation_fun mutate_weights)a, :math.pow(length(agent.genotype.neurons), 0.5) |> round() |> :rand.uniform())

  def mutate(agent, _, count) when count <= 0, do: agent

  def mutate(agent, mutation_funs, count) do
    with {mutation_fun, _} <- List.pop_at(mutation_funs, :rand.uniform(length(mutation_funs)) - 1),
      mutated_agent = apply(__MODULE__, mutation_fun, List.wrap(agent)) do
        mutate(mutated_agent, mutation_funs, count - 1)
    end
  end

  def add_bias do
    
  end

  def remove_bias do
    
  end

  def add_sensor do
    
  end

  def remove_sensor do
    
  end

  def add_neuron do
    
  end

  def remove_neuron do
    
  end

  def add_actuator do
    
  end

  def remove_actuator do
    
  end

  def add_link do
    
  end

  def remove_link do
    
  end

  def splice_link do
    
  end

  def mutate_bias(agent) do
    genotype = agent.genotype
    {neuron, index} = random_neuron(genotype)

    updated_bias =
      case :rand.uniform() < perturb_probability(neuron) do
        true -> (neuron.bias + Neuron.random_weight()) |> limit_saturation()
        false -> neuron.bias
      end

    neuron = %{neuron | bias: updated_bias}
    neurons = List.replace_at(genotype.neurons, index, neuron)
    genotype = %{genotype | neurons: neurons}
    %{agent | genotype: genotype}
  end

  def mutate_activation_fun(agent) do
    genotype = agent.genotype
    {neuron, index} = random_neuron(genotype)

    %{activation_funs: activation_funs} = agent.scape.morphology()

    new_activation_fun =
      case :rand.uniform() < perturb_probability(neuron) do
        true -> select_random_activation_fun(activation_funs)
        false -> neuron.activation_fun
      end

    neuron = %{neuron | activation_fun: new_activation_fun}
    neurons = List.replace_at(genotype.neurons, index, neuron)
    genotype = %{genotype | neurons: neurons}
    %{agent | genotype: genotype}
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

    neuron = %{neuron | inbound_nodes: updated_inbound_nodes}
    neurons = List.replace_at(genotype.neurons, index, neuron)
    genotype = %{genotype | neurons: neurons}
    %{agent | genotype: genotype}
  end

  defp limit_saturation(value) do
    upper_limit = :math.pi() * 2
    lower_limit = -:math.pi() * 2

    value |> max(lower_limit) |> min(upper_limit)
  end

  defp select_random_activation_fun([]), do: :tanh
  defp select_random_activation_fun(activation_funs) do
    with {fun, _} <- List.pop_at(activation_funs, :rand.uniform(length(activation_funs))), do: fun
  end

  defp perturb_probability(neuron) do
    (1 / :math.sqrt(length(neuron.inbound_nodes)))
  end

  defp random_neuron(genotype) do 
    with index <- :rand.uniform(length(genotype.neurons)) - 1,
      {neuron, _} <- List.pop_at(genotype.neurons, index), do: {neuron, index}
  end
end
