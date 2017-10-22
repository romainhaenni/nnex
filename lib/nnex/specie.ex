defmodule NNex.Specie do
  # has many neural networks / phenotypes
  defstruct [:id, :population, :fingerprint, :constraint, :agent, :champion, :avg_fitness_score, :innovation_factor]
end
