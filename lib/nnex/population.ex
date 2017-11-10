defmodule NNex.Population do
  use GenServer

  alias NNex.{PopulationSup, SpecieSup, Specie}

  def start_link(args), do: GenServer.start(__MODULE__, args, name: __MODULE__)

  def start_training(scape) do
    specie = Specie.seed(%Specie{population_id: __MODULE__})
      
    Supervisor.start_child(PopulationSup, Supervisor.child_spec({SpecieSup, {specie, scape}}, id: specie.id))

    Specie.begin_session(specie.id)
  end
end
