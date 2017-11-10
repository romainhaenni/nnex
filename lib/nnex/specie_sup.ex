defmodule NNex.SpecieSup do
  use Supervisor

  alias NNex.{Specie, AgentSup, Genotype}

  def start_link({specie, _scpae} = args), do: Supervisor.start_link(__MODULE__, args, name: {:global, {__MODULE__, specie.id}})

  def init({specie, scape_module}) do
    agents = for _ <- 1..specie.init_population, do: Genotype.create_agent(specie.id, scape_module) |> Genotype.seed()

    Supervisor.init([
      # {Specie, %{specie | agents: agents}},
      Supervisor.child_spec({Specie, %{specie | agents: agents}}, id: {Specie, specie.id}),
      Enum.map(agents, fn agent -> Supervisor.child_spec({AgentSup, agent}, id: {AgentSup, agent.id}) end)
    ] |> List.flatten, strategy: :one_for_one, restart: :transient)
  end
end
