defmodule NNex.Polis do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init([
      {NNex.Repo, []}
    ], strategy: :one_for_one)
  end

  # TODO: start/stop public scape function
  # TODO: start/stop supmodules function
  # TODO: start benchmarker
  # TODO: start repo
  # TODO: start error logger
end
