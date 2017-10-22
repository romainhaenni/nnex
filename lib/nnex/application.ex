defmodule NNex.Application do
  # starts Polis
  use Application

  alias NNex.{Polis}

  def start(_type, _args) do
    Supervisor.start_link([{Polis, []}], [strategy: :one_for_one])
  end
end
