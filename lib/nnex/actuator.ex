defmodule NNex.Actuator do
  use GenServer

  alias NNex.{Scape, Cortex}

  defstruct [:id, :type, :cortex_id, :scape_id, :inbound_nodes]

  def start_link(%__MODULE__{id: id} = actuator) do
    GenServer.start_link(__MODULE__, actuator, name: {:global, {__MODULE__, id}})
  end

  def inbound_signal(id, input_id, input_value) do
    GenServer.cast({:global, {__MODULE__, id}}, {:inbound_signal, input_id, input_value})
  end

  def handle_cast({:inbound_signal, input_id, input_value}, actuator) do
    match_input_id_fun = &match?(%{id: ^input_id}, &1)
    
    updated_inbound_node =
      actuator.inbound_nodes
      |> Enum.find(match_input_id_fun)
      |> Map.replace(:value, input_value)

    updated_inbound_nodes = List.replace_at(actuator.inbound_nodes, Enum.find_index(actuator.inbound_nodes, match_input_id_fun), updated_inbound_node)

    updated_actuator = %{actuator | inbound_nodes: updated_inbound_nodes}

    if not Enum.any?(updated_inbound_nodes, &match?(%{value: nil}, &1)) do
      with calculated_value <- Enum.sum(Enum.map(updated_actuator.inbound_nodes, fn %{id: _, value: value} -> value end)),
        {life_cycle, total_fitness, result} <- Scape.act(actuator.scape_id, calculated_value) do
        Cortex.trigger(actuator.cortex_id, life_cycle, total_fitness, result)

        {:noreply, %{updated_actuator | inbound_nodes: reset_nodes(updated_actuator.inbound_nodes)}}
      end
    else
      {:noreply, updated_actuator}
    end
  end

  defp reset_nodes(nodes), do: Enum.map(nodes, & %{&1 | value: nil})
end
