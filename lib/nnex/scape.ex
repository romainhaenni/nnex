defmodule NNex.Scape do
  defmacro __using__(_) do
    quote do
      use GenServer
      # outcome: {signal, step_fitness_score}
      defstruct [:id, :training_data, :training_index, :outcome, :sensor_types, :actuator_types, :activation_funs]

      def start_link(id) do
        GenServer.start_link(__MODULE__, new_scape(id), name: {:global, {NNex.Scape, id}})
      end
    end
  end

  def sense(id, sensor_type), do: GenServer.call({:global, {__MODULE__, id}}, {:sense, sensor_type})

  def act(id, signal), do: GenServer.call({:global, {__MODULE__, id}}, {:act, signal})

  def reset(id), do: GenServer.cast({:global, {__MODULE__, id}}, :reset)
end
