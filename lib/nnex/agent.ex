defmodule NNex.Agent do
  @moduledoc """
    The agent element will store all the supporting information that the NN based system needs to keep track of the evolutionary history and other supplementary information not kept track of by the other elements. Neurons, Sensors, Actuators, and the Cortex elements keep track of only the data needed for their own specific functionality, whereas the agent element will maintain all the global NN data (general topology of the NN, constraints, specie id...). 
  """

  use GenServer

  alias NNex.{Specie, Repo, Genotype, Cortex}

  defstruct [
    :id, 
    :generation,
    :specie_id, 
    :genotype,
    :scape,
    :fingerprint,
    :evolution_history, 
    :fitness_score, 
    :innovation_factor,
    :results,
    :training_started_at
  ]

  @healthcheck_duration 100

  def start_link(%__MODULE__{id: id} = args), do: GenServer.start(__MODULE__, args, name: {:global, {__MODULE__, id}})

  def session_finished(id, fitness_score, results) do
    GenServer.cast({:global, {__MODULE__, id}}, {:session_finished, fitness_score, results})
  end

  def genotype(id) do
    GenServer.call({:global, {__MODULE__, id}}, :genotype)
  end

  def start_training(id), do: GenServer.cast({:global, {__MODULE__, id}}, :start_training)

  def reset(id, agent), do: GenServer.cast({:global, {__MODULE__, id}}, {:reset, agent})

  def handle_cast({:session_finished, fitness_score, results}, agent) do
    agent = %{agent | fitness_score: fitness_score, results: results}

    Repo.save(agent)
    Genotype.save(agent.genotype)

    Specie.session_finished(agent.specie_id, agent)

    {:noreply, agent}
  end

  def handle_cast(:start_training, agent) do
    updated_agent = %{agent | training_started_at: Time.utc_now()}

    Cortex.trigger(agent.genotype.cortex.id)
    Process.send_after(self(), :healthcheck, @healthcheck_duration)

    {:noreply, updated_agent}
  end

  def handle_info(:healthcheck, agent) do
    case agent.fitness_score == nil do
      true ->
        Specie.session_finished(agent.specie_id, %{agent | fitness_score: 0.0})

      false ->
        nil
    end

    {:noreply, agent}
  end

  def print(agent) do
    IO.puts("*** Agent Details ***")
    IO.puts("Generation: #{agent.generation}")
    IO.puts("Fitness Score: #{agent.fitness_score}")
    IO.puts("Results: #{inspect(agent.results)}")
    Genotype.print(agent.genotype)
  end
end
