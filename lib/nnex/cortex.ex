defmodule NNex.Cortex do
  use GenServer

  alias NNex.{Sensor, Exoself}

  defstruct [:id, :agent_id, :sensor_ids, :actuator_ids, :total_fitness]

  def start_link(%__MODULE__{} = cortex) do
    GenServer.start_link(__MODULE__, cortex, name: :cortex)
  end

  def trigger(life_cycle, fitness_score, outcome), do: GenServer.cast(:cortex, {:trigger, life_cycle, fitness_score, outcome})

  def start(), do: GenServer.cast(:cortex, :start)

  def handle_cast({:trigger, life_cycle, fitness_score, outcome}, %__MODULE__{sensor_ids: sensors} = cortex) do
    case life_cycle do
      :continue ->
        Enum.each(sensors, fn(sensor) -> Sensor.sense(sensor.id) end)

      :stop ->
        Exoself.evaluate_current_phenotype(fitness_score, outcome)
    end

    {:noreply, %{cortex | total_fitness: fitness_score}}
  end

  def handle_cast(:start, %__MODULE__{sensor_ids: sensors} = cortex) do
    Enum.each(sensors, fn(sensor) -> Sensor.sense(sensor.id) end)

    {:noreply, %{cortex | total_fitness: 0.0}}
  end
end
