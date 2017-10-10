defmodule NeuralNetwork.Application do
  use Application

  alias NeuralNetwork.{Exoself, Trainer}

  def start(_type, _args) do
    :observer.start
    children = [
      {Exoself, []},
      {Trainer, %Trainer{max_attempts: :infinite, target_fitness_score: 99999.0, evaluation_limit: :infinite}}
    ]

    opts = [strategy: :one_for_one, name: NeuralNetwork.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
