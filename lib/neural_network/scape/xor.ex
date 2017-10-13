defmodule NeuralNetwork.Scape.Xor do
  use NeuralNetwork.Scape

  def handle_call({:sense, sensor_type}, _from, %__MODULE__{training_data: training_data, training_index: training_index} = scape) do
    {{[left, right], _output}, _list} = List.pop_at(training_data, training_index)

    input =
      case sensor_type do
        :left -> left
        :right -> right
      end

    {:reply, input, scape}
  end

  def handle_call({:act, signal}, _from, %__MODULE__{training_data: training_data, training_index: training_index, outcome: outcome} = scape) do
    {{[left, right], expected_output}, _} = List.pop_at(training_data, training_index)
    new_outcome = [{left, right, expected_output, signal} | outcome]

    total_fitness = 
      cond do
        training_index >= 3 ->
          calculate_fitness(new_outcome)

        true ->
          0.0
      end

    life_cycle =
      cond do
        training_index >= 3 ->
          :stop

        true ->
          :continue
      end

    updated_training_index =
      cond do
        training_index >= 3 ->
          0

        true ->
          training_index + 1
      end

    {:reply, {life_cycle, total_fitness, new_outcome}, %{scape | training_index: updated_training_index, outcome: new_outcome}}
  end

  def handle_cast(:reset, _scape), do: {:noreply, new_scape()}

  defp calculate_fitness(outcome) do
    error =
      outcome
      |> Enum.map(fn {_left, _right, expected_output, signal} -> :math.pow(expected_output - signal, 2) end)
      |> Enum.sum()
      |> :math.sqrt()
  
    1 / (error + 1.0e-5)
  end

  defp new_scape() do
    data = [
      {[-1,-1], -1},
      {[1,-1], 1},
      {[-1,1], 1},
      {[1,1], -1}
    ]

    %__MODULE__{
      training_data: data,
      training_index: 0,
      outcome: []
    }
  end
end