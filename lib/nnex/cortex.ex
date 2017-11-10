defmodule NNex.Cortex do
  use GenServer

  alias NNex.{Sensor, Agent}

  defstruct [:id, :agent_id, :sensor_ids, :actuator_ids, :total_fitness]

  def start_link(%__MODULE__{} = cortex) do
    GenServer.start_link(__MODULE__, cortex, name: {:global, {__MODULE__, cortex.id}})
  end

  def trigger(id), do: trigger(id, :continue, 0.0, [])
  def trigger(id, life_cycle, fitness_score, results), do: GenServer.cast({:global, {__MODULE__, id}}, {:trigger, life_cycle, fitness_score, results})

  def handle_cast({:trigger, life_cycle, fitness_score, results}, %__MODULE__{agent_id: agent_id, sensor_ids: sensor_ids} = cortex) do
    case life_cycle do
      :continue ->
        Enum.each(sensor_ids, &Sensor.sense(&1))

      :stop ->
        Agent.session_finished(agent_id, fitness_score, results)
    end

    {:noreply, %{cortex | total_fitness: fitness_score}}
  end
end
