defmodule NNex.AgentSup do
  use Supervisor

  alias NNex.{Agent, Exoself}

  def start_link(agent), do: Supervisor.start_link(__MODULE__, agent, name: {:global, {__MODULE__, agent.id}})

  def init(agent) do
    # IO.puts("Init agent #{agent.id}")
    Supervisor.init([
      {Agent, agent},
      {agent.scape, agent.id},
      {Exoself, agent}
    ], strategy: :one_for_all, restart: :transient)
  end
end
