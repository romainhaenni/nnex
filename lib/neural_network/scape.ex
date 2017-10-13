defmodule NeuralNetwork.Scape do
  defmacro __using__(_) do
    quote do
      use GenServer

      # outcome: {signal, step_fitness_score}
      defstruct [:training_data, :training_index, :outcome]

      def start_link(%{}), do: GenServer.start_link(__MODULE__, %{}, name: :scape)

      def init(%{}), do: {:ok, new_scape()}
    end
  end

  def sense(sensor_type), do: GenServer.call(:scape, {:sense, sensor_type})

  def act(signal), do: GenServer.call(:scape, {:act, signal})

  def reset(), do: GenServer.cast(:scape, :reset)
end
