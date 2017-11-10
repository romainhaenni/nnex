defmodule NNex.Exoself do
  use Supervisor

  alias NNex.{Cortex, Genotype, Sensor, Neuron, Actuator}

  def start_link(agent) do
    Supervisor.start_link(__MODULE__, agent, name: {:global, {__MODULE__, agent.id}})
  end

  def init(agent) do
    %Genotype{cortex: cortex, sensors: sensors, neurons: neurons, actuators: actuators} = agent.genotype
    children = [
        Enum.map(sensors, fn sensor -> Supervisor.child_spec({Sensor, sensor}, id: {Sensor, sensor.id}) end),
        Enum.map(neurons, fn neuron -> Supervisor.child_spec({Neuron, neuron}, id: {Neuron, neuron.id}) end),
        Enum.map(actuators, fn actuator -> Supervisor.child_spec({Actuator, actuator}, id: {Actuator, actuator.id}) end),
        {Cortex, cortex}
      ] |> List.flatten
      
    Supervisor.init(children, [strategy: :one_for_all, restart: :transient])
  end
end
