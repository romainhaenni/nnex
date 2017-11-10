defmodule NNex.Neuron do
  use GenServer

  # inbound_nodes: [%{id: atom, value: float, weight: float}]
  # outbound_nodes: [id: atom]
  # bias: integer
  defstruct [:id, :activation_fun, :inbound_nodes, :outbound_nodes, :bias]

  def start_link(%__MODULE__{} = neuron) do
    # IO.puts("start neuron #{neuron.id}")
    GenServer.start_link(__MODULE__, neuron, name: {:global, {__MODULE__, neuron.id}})
  end

  def inbound_signal(id, input_id, input_value) do
    GenServer.call({:global, {__MODULE__, id}}, {:inbound_signal, input_id, input_value})
  end

  def reset(id, %__MODULE__{} = neuron), do: GenServer.cast({:global, {__MODULE__, id}}, {:reset, neuron})

  def handle_call({:inbound_signal, input_id, input_value}, _from, neuron) do
    # IO.puts("inbound_signal")
    match_input_id_fun = &match?(%{id: ^input_id}, &1)
    
    updated_inbound_node =
      neuron.inbound_nodes
      |> Enum.find(match_input_id_fun)
      |> Map.replace(:value, input_value)

    updated_inbound_nodes = List.replace_at(neuron.inbound_nodes, Enum.find_index(neuron.inbound_nodes, match_input_id_fun), updated_inbound_node)

    updated_neuron = %{neuron | inbound_nodes: updated_inbound_nodes}

    if !Enum.any?(updated_inbound_nodes, &match?(%{value: nil}, &1)) do
      with {:ok, sent_neuron} <- send_outbound(updated_neuron), do: {:reply, :ok, sent_neuron}
    else
      {:reply, :ok, updated_neuron}
    end
  end

  def handle_cast({:reset, new_neuron}, _neuron) do
    {:noreply, new_neuron}
  end

  defp send_outbound(%__MODULE__{} = neuron) do
    calculated_value =
      neuron.inbound_nodes
        |> Enum.reduce(neuron.bias, fn (%{id: _, value: value, weight: weight}, acc) -> value * weight + acc end)
        |> activate()

    Enum.each(neuron.outbound_nodes, fn {node, id} -> node.inbound_signal(id, neuron.id, calculated_value) end)

    {:ok, %{neuron | inbound_nodes: reset_nodes(neuron.inbound_nodes)}}
  end

  defp activate(value), do: :math.tanh(value)

  defp reset_nodes(nodes), do: Enum.map(nodes, & %{&1 | value: nil})

  def random_weight(), do: (:rand.uniform() - 0.5) * :math.pi() * 2

  def add_outbound_node(neuron, outbound_node) do
    %{neuron | outbound_nodes: [outbound_node | neuron.outbound_nodes] }
  end

  def add_inbound_id(neuron, inbound_id) do
    %{neuron | inbound_nodes: [inbound_id | neuron.inbound_nodes] }
  end
end
