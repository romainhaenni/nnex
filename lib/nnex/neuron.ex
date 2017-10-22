defmodule NNex.Neuron do
  use GenServer

  # inbound_ids: [%{id: atom, value: float, weight: float}]
  # outbound_ids: [id: atom]
  # bias: integer
  defstruct [:id, :activation_fun, :inbound_ids, :outbound_ids, :bias]

  def start_link(%__MODULE__{} = neuron) do
    GenServer.start_link(__MODULE__, neuron, name: neuron.id)
  end

  def inbound_signal(node_name, input_id, input_value) do
    GenServer.cast(node_name, {:inbound_signal, input_id, input_value})
  end

  def reset(node_name, %__MODULE__{} = neuron), do: GenServer.cast(node_name, {:reset, neuron})

  def handle_cast({:inbound_signal, input_id, input_value}, neuron) do
    match_input_id_fun = &match?(%{id: ^input_id}, &1)
    
    updated_inbound_node =
      neuron.inbound_ids
      |> Enum.find(match_input_id_fun)
      |> Map.replace(:value, input_value)

    updated_inbound_ids = List.replace_at(neuron.inbound_ids, Enum.find_index(neuron.inbound_ids, match_input_id_fun), updated_inbound_node)

    updated_neuron = %{neuron | inbound_ids: updated_inbound_ids}

    if !Enum.any?(updated_inbound_ids, &match?(%{value: nil}, &1)) do
      with {:ok, sent_neuron} <- send_outbound(updated_neuron), do: {:noreply, sent_neuron}
    else
      {:noreply, updated_neuron}
    end
  end

  def handle_cast({:reset, new_neuron}, _neuron) do
    {:noreply, new_neuron}
  end

  defp send_outbound(%__MODULE__{} = neuron) do
    calculated_value =
      neuron.inbound_ids
        |> Enum.reduce(neuron.bias, fn (%{id: _, value: value, weight: weight}, acc) -> value * weight + acc end)
        |> activate()

    Enum.each(neuron.outbound_ids, fn node_name -> inbound_signal(node_name, neuron.id, calculated_value) end)

    {:ok, %{neuron | inbound_ids: reset_nodes(neuron.inbound_ids)}}
  end

  defp activate(value), do: :math.tanh(value)

  defp reset_nodes(nodes), do: Enum.map(nodes, & %{&1 | value: nil})

  def perturb_neuron_weights(%__MODULE__{inbound_ids: inbound_ids, bias: bias} = neuron) do
    perturb_probability = 1 / :math.sqrt(length(inbound_ids))

    updated_inbound_ids =
      Enum.map(inbound_ids, fn node ->
        case :rand.uniform() < perturb_probability do
          true -> %{node | weight: (node.weight + random_weight()) |> limit_saturation()}
          false -> node
        end
      end)

    updated_bias =
      case :rand.uniform() < perturb_probability do
        true -> (bias + random_weight()) |> limit_saturation()
        false -> bias
      end

    %{neuron | inbound_ids: updated_inbound_ids, bias: updated_bias}
  end

  def random_weight(), do: (:rand.uniform() - 0.5) * :math.pi() * 2

  defp limit_saturation(value) do
    upper_limit = :math.pi() * 2
    lower_limit = -:math.pi() * 2

    value |> max(lower_limit) |> min(upper_limit)
  end

  def add_outbound_id(neuron, outbound_id) do
    %{neuron | outbound_ids: [outbound_id | neuron.outbound_ids] }
  end

  def add_inbound_id(neuron, inbound_id) do
    %{neuron | inbound_ids: [inbound_id | neuron.inbound_ids] }
  end

  # defp dot(value, weight, acc) when is_float(value), do: value * weight + acc
  # defp dot([value | []], weight, acc), do: value * weight + acc
  # defp dot([value | tail], weight, acc), do: dot(tail, weight, value * weight + acc)
end
