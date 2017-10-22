defmodule NNex.Exoself do
  use GenServer

  alias NNex.{Cortex, Genotype, Sensor, Neuron, Actuator, Scape}

  def start_link(defaults) do
    GenServer.start_link(__MODULE__, defaults, name: :exoself)
  end

  def start(%Genotype{} = genotype, morphology) do
    GenServer.cast(:exoself, {:start, genotype, morphology})
  end

  def evaluate_current_phenotype(fitness_score, outcome) do
    GenServer.cast(:exoself, {:evaluate_current_phenotype, fitness_score, outcome})
  end

  def restart_neural_network(genotype) do
    GenServer.cast(:exoself, {:restart_neural_network, genotype})
  end

  def handle_cast({:start, %Genotype{} = new_genotype, morphology}, _genotype) do
    start_neural_network(new_genotype, morphology)
    Cortex.start()

    {:noreply, new_genotype}
  end

  def handle_cast({:evaluate_current_phenotype, fitness_score, outcome}, genotype) do
    updated_genotype = %{genotype | fitness_score: fitness_score, outcome: outcome}

    # Trainer.evaluate(updated_genotype)
   
    {:noreply, updated_genotype}
  end

  def handle_cast({:restart_neural_network, %Genotype{neurons: neurons} = next_genotype}, _genotype) do
    Enum.map(neurons, fn neuron ->
      Neuron.reset(neuron.id, neuron)
    end)
    Scape.reset()
    Cortex.start()

    {:noreply, next_genotype}
  end

  defp start_neural_network(%Genotype{} = genotype, morphology) do
    scape =
      case morphology do
        :xor ->
          Scape.Xor
      end

    children = [
        Enum.map(genotype.sensors, fn sensor -> Supervisor.child_spec({Sensor, sensor}, id: sensor.id) end),
        Enum.map(genotype.neurons, fn neuron -> Supervisor.child_spec({Neuron, neuron}, id: neuron.id) end),
        Enum.map(genotype.actuators, fn actuator -> Supervisor.child_spec({Actuator, actuator}, id: actuator.id) end),
        {Cortex, genotype.cortex},
        {scape, %{}}
      ] |> List.flatten
      
    Supervisor.start_link(children, [strategy: :one_for_one, name: __MODULE__])
  end
end
