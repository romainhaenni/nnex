defmodule NeuralNetwork.Trainer do
  use GenServer

  alias NeuralNetwork.{Genotype, Exoself, Neuron}

  defstruct [
    :attempt_count, 
    :max_attempts,
    :target_fitness_score,
    :evaluation_count,
    :evaluation_limit,
    :best_genotype
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :trainer)
  end

  def init(trainer) do
    {:ok, %{trainer | evaluation_count: 0, attempt_count: 0}}
  end

  def next_genotype(%Genotype{} = latest_genotype) do
    GenServer.call(:trainer, {:next_genotype, latest_genotype})
  end

  def training_finished?() do
    GenServer.call(:trainer, :training_finished?)
  end

  def best_genotype() do
    GenServer.call(:trainer, :best_genotype)
  end

  def start() do
    GenServer.cast(:trainer, :start)
  end

  def handle_call({:next_genotype, %Genotype{} = genotype_to_test}, _from, trainer) do
    current_best_genotype = trainer.best_genotype || Genotype.random_start_network()
    genotype_to_test_has_higher_fitness = genotype_to_test.fitness_score > current_best_genotype.fitness_score

    best_genotype =
      cond do
        genotype_to_test_has_higher_fitness ->
          genotype_to_test

        true ->
          current_best_genotype
      end

    new_attempt_count =
      cond do
        genotype_to_test_has_higher_fitness ->
          trainer.attempt_count

        true ->
          trainer.attempt_count + 1
      end

    updated_neurons = Enum.map(best_genotype.neurons, & Neuron.perturb_neuron_weights/1)
    next_genotype = %{best_genotype | neurons: updated_neurons, fitness_score: 0, outcome: []}

    {:reply, next_genotype, %{trainer | best_genotype: best_genotype, evaluation_count: trainer.evaluation_count + 1, attempt_count: new_attempt_count}}
  end

  def handle_call(:training_finished?, _from, trainer) do
    target_achieved =
      cond do
        trainer.attempt_count >= trainer.max_attempts -> true
        trainer.best_genotype.fitness_score >= trainer.target_fitness_score -> true
        trainer.evaluation_count >= trainer.evaluation_limit -> true
        true -> false
      end

    {:reply, {target_achieved, trainer.evaluation_count}, trainer}
  end

  def handle_call(:best_genotype, _from, trainer) do
    {:reply, trainer.best_genotype, trainer}
  end

  def handle_cast(:start, trainer) do
    Exoself.start(Genotype.random_start_network())

    {:noreply, %{trainer | attempt_count: 0, evaluation_count: 0, best_genotype: nil}}
  end
end
