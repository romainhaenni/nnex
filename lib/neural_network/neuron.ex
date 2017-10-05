defmodule NeuralNetwork.Neuron do
  use GenServer

  # inbound_nodes: [%{id: atom, value: float, weight: float}]
  # outbound_nodes: [id: atom]
  # bias: integer
  defstruct [:id, :inbound_nodes, :outbound_nodes, :bias]

  def start_link(%__MODULE__{} = neuron) do
    GenServer.start_link(__MODULE__, neuron, name: neuron.id)
  end

  def inbound_signal(node_name, input_id, input_value) do
    GenServer.cast(node_name, {:inbound_signal, input_id, input_value})
  end

  def handle_cast({:inbound_signal, input_id, input_value}, neuron) do
    match_input_id_fun = &match?(%{id: ^input_id}, &1)

    updated_inbound_node =
      neuron.inbound_nodes
      |> Enum.find(match_input_id_fun)
      |> Map.replace(:value, input_value)

    updated_inbound_nodes = List.replace_at(neuron.inbound_nodes, Enum.find_index(neuron.inbound_nodes, match_input_id_fun), updated_inbound_node)

    updated_neuron = %{neuron | inbound_nodes: updated_inbound_nodes}

    if !Enum.any?(updated_inbound_nodes, &match?(%{value: nil}, &1)) do
      with {:ok, sent_neuron} <- send_outbound(updated_neuron), do: {:noreply, sent_neuron}
    else
      {:noreply, updated_neuron}
    end
  end

  defp send_outbound(%__MODULE__{} = neuron) do
    calculated_value =
      neuron.inbound_nodes
        |> Enum.reduce(neuron.bias, fn (%{id: _, value: value, weight: weight}, acc) -> value * weight + acc end)
        |> activate()

    Enum.each(neuron.outbound_nodes, fn node_name -> inbound_signal(node_name, neuron.id, calculated_value) end)

    {:ok, %{neuron | inbound_nodes: reset_nodes(neuron.inbound_nodes)}}
  end

  defp activate(value), do: :math.tanh(value)

  defp reset_nodes(nodes), do: Enum.map(nodes, & %{&1 | value: nil})
end
