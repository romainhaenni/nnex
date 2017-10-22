defmodule NNex.Agent do
  defstruct [
    :id, 
    :generation, 
    :population, 
    :specie_id, 
    :cortex_id, 
    :fingerprint, 
    :constraint, 
    :evolution_history, 
    :fitness_score, 
    :innovation_factor, 
    :pattern
  ]
end
