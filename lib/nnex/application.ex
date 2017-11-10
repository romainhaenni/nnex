defmodule NNex.Application do
  use Application

  alias NNex.{Polis}

  def start(_type, _args) do
    :observer.start()
    Supervisor.start_link([{Polis, []}], [strategy: :one_for_one])
  end
end
