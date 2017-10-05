defmodule NeuralNetworkTest do
  use ExUnit.Case
  doctest NeuralNetwork

  test "greets the world" do
    assert NeuralNetwork.hello() == :world
  end
end
