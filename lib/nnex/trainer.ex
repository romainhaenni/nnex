# defmodule NNex.Trainer do
#   use GenServer

#   alias NNex.{Genotype, Exoself, Neuron, Benchmarker}

#   defstruct [
#     :run_count,
#     :total_runs,
#     :attempt_count, 
#     :max_attempts,
#     :target_fitness_score,
#     :evaluation_count,
#     :evaluation_limit,
#     :best_genotype,
#     :morphology
#   ]

#   def start_link(opts) do
#     GenServer.start_link(__MODULE__, opts, name: :trainer)
#   end

#   def init(_opts) do
#     {:ok, reset(%__MODULE__{})}
#   end

#   def training_finished?(trainer) do
#     fitness_score =
#       case trainer.best_genotype do
#         nil -> 0
#         _ -> trainer.best_genotype.fitness_score
#       end

#     cond do
#       trainer.attempt_count >= trainer.max_attempts -> true
#       fitness_score >= trainer.target_fitness_score -> true
#       trainer.evaluation_count >= trainer.evaluation_limit -> true
#       true -> false
#     end
#   end

#   def evaluate(genotype) do
#     GenServer.cast(:trainer, {:evaluate, genotype})
#   end

#   def start(trainer) do
#     GenServer.cast(:trainer, {:start, trainer})
#   end

#   def next_genotype(trainer, %Genotype{} = genotype_to_test) do
#     current_best_genotype = trainer.best_genotype || Genotype.random_start_network()
#     genotype_to_test_has_higher_fitness = genotype_to_test.fitness_score > current_best_genotype.fitness_score

#     best_genotype =
#       cond do
#         genotype_to_test_has_higher_fitness ->
#           genotype_to_test

#         true ->
#           current_best_genotype
#       end

#     new_attempt_count =
#       cond do
#         genotype_to_test_has_higher_fitness ->
#           trainer.attempt_count

#         true ->
#           trainer.attempt_count + 1
#       end

#     updated_neurons = Enum.map(best_genotype.neurons, & Neuron.perturb_neuron_weights/1)
#     next_genotype = %{best_genotype | neurons: updated_neurons, fitness_score: 0, outcome: []}

#     {next_genotype, best_genotype, new_attempt_count}
#   end

#   def handle_cast({:start, %__MODULE__{} = new_trainer}, _trainer) do
#     Exoself.start(Genotype.random_start_network(), new_trainer.morphology)

#     {:noreply, reset(new_trainer)
#     }
#   end

#   def handle_cast({:evaluate, genotype}, trainer) do
#     updated_trainer =
#       case training_finished?(trainer) do
#         true ->
#           IO.puts("Achieved fitness score: #{trainer.best_genotype.fitness_score} with #{inspect(trainer.best_genotype.outcome)}")
          
#           Benchmarker.add_result(%{attempts: trainer.attempt_count, evaluations: trainer.evaluation_count, fitness_score: genotype.fitness_score})

#           new_run_count = trainer.run_count + 1

#           case new_run_count < trainer.total_runs do
#             true ->
#               Exoself.restart_neural_network(Genotype.random_start_network())

#             false ->
#               Benchmarker.report()
#           end

#           %{reset(trainer) | run_count: new_run_count}
        
#         false ->
#           {next_genotype, best_genotype, new_attempt_count} = next_genotype(trainer, genotype)
#           Exoself.restart_neural_network(next_genotype)

#           %{trainer | best_genotype: best_genotype, 
#             evaluation_count: trainer.evaluation_count + 1, 
#             attempt_count: new_attempt_count}
#       end

#     {:noreply, updated_trainer}
#   end

#   defp reset(trainer), do: %{trainer | attempt_count: 0, 
#         evaluation_count: 0,
#         run_count: 0,
#         best_genotype: nil
#       }
# end
