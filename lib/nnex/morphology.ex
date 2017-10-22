defmodule NNex.Morphology do
  def sensor_types(:xor) do
    [:left, :right]
  end

  def actuator_types(:xor) do
    [:result]
  end
end
