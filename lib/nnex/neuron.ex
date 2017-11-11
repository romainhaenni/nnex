defmodule NNex.Neuron do
  use GenServer

  # inbound_nodes: [%{id: atom, value: float, weight: float}]
  # outbound_nodes: [id: atom]
  # bias: integer
  defstruct [:id, :activation_fun, :inbound_nodes, :outbound_nodes, :bias]

  @e 2.71828183

  def start_link(%__MODULE__{} = neuron) do
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
        |> activate(neuron.activation_fun)

    Enum.each(neuron.outbound_nodes, fn {node, id} -> node.inbound_signal(id, neuron.id, calculated_value) end)

    {:ok, %{neuron | inbound_nodes: reset_nodes(neuron.inbound_nodes)}}
  end

  defp activate(value, nil), do: activate(value, :tanh)

  defp activate(value, :tanh), do: :math.tanh(value)

  defp activate(value, :sin), do: :math.sin(value)

  defp activate(value, :cos), do: :math.cos(value)

  defp activate(0, :sgn), do: 0
  defp activate(value, :sgn) when value > 0, do: 1
  defp activate(value, :sgn) when value < 0, do: -1

  defp activate(value, :binary) when value > 0, do: 1
  defp activate(value, :binary) when value <= 0, do: 0

  defp activate(value, :trinary) when value >= 0.33, do: 1
  defp activate(value, :trinary) when value > -0.33 and value < 0.33, do: 0
  defp activate(value, :trinary) when value <= -0.33, do: -1

  defp activate(value, :multiquadric), do: :math.pow(value * value + 0.01, 0.5)

  defp activate(value, :quadric), do: activate(value, :sgn) * value * value

  defp activate(value, :abs), do: abs(value)

  defp activate(value, :sqrt), do: activate(:sgn, value) * :math.sqrt(abs(value))

  defp activate(value, :log) when value == 0, do: 0
  defp activate(value, :log), do: activate(:sgn, value) * :math.log(abs(value))

  defp activate(value, :gaussian) when value > 10, do: gaussian(100)
  defp activate(value, :gaussian) when value < -10, do: gaussian(-100)
  defp activate(value, :gaussian), do: gaussian(value)

  defp activate(value, :sigmoid) when value > 10, do: sigmoid(10)
  defp activate(value, :sigmoid) when value < -10, do: sigmoid(-10)
  defp activate(value, :sigmoid), do: sigmoid(value)

  defp activate(value, :sigmoid_1), do: value / (1 + abs(value))

  defp activate(value, :linear), do: value

  defp reset_nodes(nodes), do: Enum.map(nodes, & %{&1 | value: nil})

  defp gaussian(value), do: :math.pow(@e, value)
  defp sigmoid(value), do: 2 / (1 + :math.pow(@e, value)) - 1

  def random_weight(), do: (:rand.uniform() - 0.5) * :math.pi() * 2

  def add_outbound_node(neuron, outbound_node) do
    %{neuron | outbound_nodes: [outbound_node | neuron.outbound_nodes] }
  end

  def add_inbound_id(neuron, inbound_id) do
    %{neuron | inbound_nodes: [inbound_id | neuron.inbound_nodes] }
  end
end
