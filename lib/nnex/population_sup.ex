defmodule NNex.PopulationSup do
  @moduledoc """
    The population_monitor process will have to perform:
    * keeping track of an entire population of species
    * Add/remove species
  """

  use Supervisor

  alias NNex.{Population}

  def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  def init(_args) do
    Supervisor.init([
      {Population, []}
    ], strategy: :one_for_one)
  end
end
