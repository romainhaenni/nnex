defmodule NNex.Specie do
  @moduledoc """
    When the difference of two genotypes is greater than some threshold X, then those genotypes belong to two different species. It would be useful for us to track speciation of NNs, and how these new species are formed, because speciation implies innovation. Thus we should also be able to group the NNs into different species through the use of a specie data structure. Each population should be broken down into species, where the number of species and the size of each species, should be completely dynamic and depend on the NNs composing the population.

    * keeping track of all agents
    * selecting fit
    * removing the unfit
    * creating offspring from the fit agents through cloning and mutation
    * and then finally reapplying the new generation of agents to the problem or simulation set by the researcher.
  """

  use GenServer

  alias NNex.{Utils, GenotypeMutator, SpecieSup, AgentSup, Genotype, Agent, Exoself}

  defstruct [
    id: nil,
    population_id: nil,
    agents: [],
    champion: nil,
    # avg_fitness_score: 0,
    # innovation_factor: 0,
    selection_strategy: :competition,
    # survival_ratio: 0.5,
    population_limit: 20,
    init_population: 20,
    # operation_mode: :gt,
    generation_limit: 100,
    evaluation_limit: 10000,
    evaluation_count: 0,
    diversity_count_step: 500,
    champion_count_step: 500,
    champion_since: 0,
    fitness_goal: :infinite,
    efficiency_ratio: 0.05
  ]

  def start_link(specie) do
    GenServer.start(__MODULE__, specie, name: {:global, {__MODULE__, specie.id}})
  end

  def seed(%__MODULE__{} = specie) do
    %{ specie | id: Utils.create_unique_id() }
  end

  def begin_session(id), do: GenServer.cast({:global, {__MODULE__, id}}, :begin_session)

  def session_finished(id, agent) do
    with specie <- GenServer.call({:global, {__MODULE__, id}}, {:session_finished, agent}) do
      case evaluation_done?(specie) do
        true ->
          IO.puts("--> starts specie evaluation #{specie.evaluation_count}")
          Agent.print(specie.champion)

          case training_finished?(specie) do
            true ->
              Genotype.save(agent.genotype)

            false -> 
              GenServer.cast({:global, {__MODULE__, id}}, :select_next_generation)
              GenServer.cast({:global, {__MODULE__, id}}, :start_next_generation)

          end
        
        false -> nil
      end
    end
  end

  def handle_cast(:begin_session, specie) do
    Enum.each(specie.agents, fn agent -> Agent.start_training(agent.id) end)

    {:noreply, specie}
  end

  def handle_cast(:start_next_generation, specie) do
    # IO.puts("--> starts specie evaluation #{specie.evaluation_count}")

    Enum.each(specie.agents, fn agent ->
      Supervisor.start_child({:global, {SpecieSup, specie.id}}, Supervisor.child_spec({AgentSup, agent}, id: {AgentSup, agent.id}))
      Agent.start_training(agent.id)
    end)
    
    {:noreply, specie}
  end

  def handle_cast(:select_next_generation, specie) do

    Enum.each(specie.agents, fn agent -> 
      Enum.each(Supervisor.which_children({:global, {Exoself, agent.id}}), fn {id, _pid, _type, _module} -> 
        Supervisor.terminate_child({:global, {Exoself, agent.id}}, id)
        Supervisor.delete_child({:global, {Exoself, agent.id}}, id)
      end)
      Enum.each(Supervisor.which_children({:global, {AgentSup, agent.id}}), fn {id, _pid, _type, _module} -> 
        Supervisor.terminate_child({:global, {AgentSup, agent.id}}, id)
        Supervisor.delete_child({:global, {AgentSup, agent.id}}, id)
      end)
      Supervisor.terminate_child({:global, {SpecieSup, specie.id}}, {AgentSup, agent.id})
      Supervisor.delete_child({:global, {SpecieSup, specie.id}}, {AgentSup, agent.id})
    end)

    {new_generation, _low_agents} = selection_by(specie.selection_strategy, specie)

    {:noreply, %{specie | agents: new_generation}}
  end

  def handle_call({:session_finished, agent}, _from, specie) do
    # IO.puts("session finished agent #{agent.id} #{agent.fitness_score} #{agent.generation}")
    specie =
      cond do
        specie.champion == nil ->
          %{specie | champion: agent, champion_since: 0}

        specie.champion.fitness_score < agent.fitness_score ->
          %{specie | champion: agent, champion_since: 0}

        true ->
          %{specie | champion_since: specie.champion_since + 1}
      end

    updated_agents_list = 
      specie.agents
      |> List.replace_at(Enum.find_index(specie.agents, fn agent_in_list -> agent.id == agent_in_list.id end), agent)

    specie = %{specie | agents: updated_agents_list}

    evaluation_count =
      case evaluation_done?(specie) do
        true ->
          specie.evaluation_count + 1

        false ->
          specie.evaluation_count
      end

    specie = %{specie | evaluation_count: evaluation_count}

    {:reply, specie, specie}
  end

  defp selection_by(:competition, specie) do
    {top_agents, low_agents} =
      specie.agents
      |> Enum.sort(& efficiency_fitness(specie, &1) >= efficiency_fitness(specie, &2))
      |> Enum.split(div(length(specie.agents), 2))

    # Enum.each(top_agents, fn agent -> IO.puts("--> top_agent: #{agent.generation} #{inspect(agent.fitness_score)}") end)

    total_energy = Enum.reduce(top_agents, 0, fn agent, acc -> agent.fitness_score + acc end)
    total_neurons = Enum.reduce(top_agents, 0, fn agent, acc -> length(agent.genotype.neurons) + acc end)
    avg_neuron_energy = total_energy / total_neurons

    allotted_offsprings =
      Enum.map(top_agents, fn agent ->
        alloted_neurons = agent.fitness_score / avg_neuron_energy
        round(alloted_neurons / length(agent.genotype.neurons))
      end)

    population_normalizer = Enum.sum(allotted_offsprings)  / specie.population_limit

    new_generation =
      Enum.zip(top_agents, allotted_offsprings)
      |> Enum.map(fn {agent, allotted_offsprings} -> 
        agent = %{agent | fitness_score: nil}
        case round(allotted_offsprings / population_normalizer) do
          0 -> 
            []

          1 -> 
            Genotype.clone_agent(agent)

          n ->
            offsprings =
              for _ <- 1..(n-1) do
                cloned_agent = Genotype.clone_agent(agent) 
                %{cloned_agent | generation: cloned_agent.generation + 1} 
                |> GenotypeMutator.mutate()
              end
            
            [Genotype.clone_agent(agent) | offsprings]

        end
      end)
      |> List.flatten()

    {new_generation, low_agents}
  end

  defp efficiency_fitness(specie, agent) do
    agent.fitness_score / :math.pow(length(agent.genotype.neurons), specie.efficiency_ratio)
  end

  defp training_finished?(specie) do
    cond do
    # The best fitness of the population is not increased some X number of times.
      specie.champion_since >= specie.champion_count_step -> 
        IO.puts("--> training finished by champion since: #{specie.champion_since}")
        true
    # The goal fitness level is reached by one of the agents in the population.
      specie.champion.fitness_score >= specie.fitness_goal -> 
        IO.puts("--> training finished by max fitness score: #{specie.champion.fitness_score}")
        true
    # The preset maximum number of generations has passed.
      Enum.max_by(specie.agents, fn agent -> agent.generation end).generation >= specie.generation_limit -> 
        IO.puts("--> training finished by generation limit: #{specie.champion.generation}")
        true
    # The preset maximum number of evaluations has passed.
      specie.evaluation_count >= specie.evaluation_limit -> 
        IO.puts("--> training finished by evaluation count: #{specie.evaluation_count}")
        true
      true -> false
    end
  end

  defp evaluation_done?(specie) do
    Enum.all?(specie.agents, fn agent -> agent.fitness_score != nil end)
  end
end
