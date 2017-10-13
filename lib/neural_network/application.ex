defmodule NNex.Application do
  use Application

  alias NNex.{Exoself, Trainer, Benchmarker}

  def start(_type, _args) do
    :observer.start
    
    children = [
      {Exoself, %{}},
      {Trainer, %{}},
      {Benchmarker, %{}}
    ]

    opts = [strategy: :one_for_one, name: NNex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
