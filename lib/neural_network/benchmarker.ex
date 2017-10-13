defmodule NNex.Benchmarker do
  use GenServer

  alias NNex.{Trainer}

  defstruct [
    :max_attempts,
    :target_fitness_score,
    :evaluation_limit,
    :total_runs,
    :morphology,
    :attempts,
    :evaluations,
    :fitness_scores
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :benchmarker)
  end

  def init(_opts) do
    benchmarker = 
      %__MODULE__{max_attempts: :infinite,
        target_fitness_score: 9999.0,
        evaluation_limit: 1000,
        total_runs: 10,
        morphology: :xor,
        attempts: [],
        evaluations: [],
        fitness_scores: [] }
    {:ok, benchmarker}
  end

  def start(morphology, total_runs), do: GenServer.cast(:benchmarker, {:start, morphology, total_runs})

  def add_result(results), do: GenServer.cast(:benchmarker, {:add_result, results})

  def report(), do: GenServer.cast(:benchmarker, :report)

  def handle_cast({:start, morphology, total_runs}, benchmarker) do
    Trainer.start(%Trainer{max_attempts: benchmarker.max_attempts, 
      target_fitness_score: benchmarker.target_fitness_score, 
      evaluation_limit: benchmarker.evaluation_limit, 
      total_runs: total_runs, 
      morphology: morphology}
    )

    {:noreply, %{benchmarker | total_runs: total_runs}}
  end

  def handle_cast({:add_result, %{attempts: attempts, evaluations: evaluations, fitness_score: fitness_score}}, benchmarker) do

    {:noreply, %{benchmarker | attempts: [attempts | benchmarker.attempts], 
      evaluations: [evaluations | benchmarker.evaluations], 
      fitness_scores: [fitness_score | benchmarker.fitness_scores]}
    }
  end

  def handle_cast(:report, benchmarker) do
    IO.puts("benchmark report for #{benchmarker.morphology}")
    print_benchmark_calculations("Fitness", benchmarker.fitness_scores)
    print_benchmark_calculations("Evaluations", benchmarker.evaluations)
    print_benchmark_calculations("Attempts", benchmarker.attempts)

    {:noreply, benchmarker}
  end

  defp print_benchmark_calculations(name, list) when is_list(list) do
    {minimum, maximum} = Enum.min_max(list)

    IO.puts("#{name}:")
    IO.puts("min: #{minimum}")
    IO.puts("max: #{maximum}")
    IO.puts("avg: #{avg(list)}")
    IO.puts("std: #{standard_deviation(list)}")
  end

  defp avg(list) when is_list(list), do: Enum.sum(list)/length(list)

  defp standard_deviation(list) when is_list(list) do
    list
    |> Enum.map(& :math.pow(avg(list) - &1, 2))
    |> Enum.sum()
    |> Kernel./(length(list))
    |> :math.sqrt()
  end
end
