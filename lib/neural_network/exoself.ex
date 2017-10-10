defmodule NeuralNetwork.Exoself do
  use GenServer

  alias NeuralNetwork.{Trainer, Cortex, Genotype, Sensor, Neuron, Actuator, Scape}

  def start_link(defaults) do
    GenServer.start_link(__MODULE__, defaults, name: :exoself)
  end

  def start(%Genotype{} = genotype) do
    GenServer.cast(:exoself, {:start, genotype})
  end

  def evaluate_current_phenotype(fitness_score, outcome) do
    GenServer.cast(:exoself, {:evaluate_current_phenotype, fitness_score, outcome})
  end

  def handle_cast({:start, %Genotype{} = new_genotype}, _genotype) do
    start_neural_network(new_genotype)
    Scape.reset()
    Cortex.start()

    {:noreply, new_genotype}
  end

  def handle_cast({:evaluate_current_phenotype, fitness_score, outcome}, genotype) do
    next_genotype = Trainer.next_genotype(%{genotype | fitness_score: fitness_score, outcome: outcome})
    {finished, evaluation_count} = Trainer.training_finished?()
    best_genotype = Trainer.best_genotype()

    if finished do
      # IO.puts("Best genotype: #{inspect(best_genotype)}")
      IO.puts("Achieved fitness score: #{best_genotype.fitness_score} with #{inspect(best_genotype.outcome)}")
      IO.puts("Evaluations: #{evaluation_count}")
    else
      IO.puts("Current best fitness score: #{best_genotype.fitness_score}")
      restart_neural_network(next_genotype)
    end
   
    {:noreply, next_genotype}
  end

  defp restart_neural_network(%Genotype{} = genotype) do
    Enum.map(genotype.neurons, fn neuron ->
      Neuron.reset(neuron.id, neuron)
    end)
    Scape.reset()
    Cortex.start()
  end

  defp start_neural_network(%Genotype{} = genotype) do
    children = [
        Enum.map(genotype.sensors, fn sensor -> Supervisor.child_spec({Sensor, sensor}, id: sensor.id) end),
        Enum.map(genotype.neurons, fn neuron -> Supervisor.child_spec({Neuron, neuron}, id: neuron.id) end),
        Enum.map(genotype.actuators, fn actuator -> Supervisor.child_spec({Actuator, actuator}, id: actuator.id) end),
        {Cortex, genotype.cortex},
        {Scape, []}
      ] |> List.flatten
      
    Supervisor.start_link(children, [strategy: :one_for_one, name: __MODULE__])
  end
end
