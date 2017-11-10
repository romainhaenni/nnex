defmodule NNex.Polis do
  @moduledoc """
    Supervises support systems:
    * Repo
    * Public Scape
    * Benchmarker
    * ...
  """

  use Supervisor

  alias NNex.{Repo, PopulationSup}

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    Supervisor.init([
      {Repo, []},
      {PopulationSup, []}
    ], strategy: :one_for_one)
  end
end
