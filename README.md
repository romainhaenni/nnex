# nnex - Neural Network in Elixir

Elixir, resp. Erlang can be used perfectly for building neuroevolutionary networks and solving problems with related algorithms. G.I. Sher leads step-by-step through all details in his [Handbook of Neuroevolution Through Erlang](https://www.amazon.com/Handbook-Neuroevolution-Through-Erlang-Gene-ebook/dp/B00AKIFKJ8/ref=mt_kindle?_encoding=UTF8&me=). He outlines advanced theories from how to connect the neurons to fully distributed NNs, substrate encoded NNs, circuits, and NNs capable of learning within their lifetime through neural plasticity. Accompanied with complete code examples written in Erlang.

nnex is the translation of Sher's examples from Erlang to Elixir. Mixed with my own understanding of functional programming as well using Elixir's convenient features.

## Read the repo
This repo is primarly meant for reading Sher's Erlang examples in a much more understandable manner thanks to Elixir. However, the code is tagged so that you can checkout the step you are looking for, e.g. for following the sections in the book while reading it. Although not all implementation details which you find in the book have been taken over one-to-one.

### Tags
|Tag|Description|
|---|-----------|
|`basic_ff`|First setup of connected neurons in a feed forward network, incl. random weights and bias.|
|`SHC`|Stochastic Hill Climber algorithm, incl. auto adjusting neuron's weights and bias. Also there is a complete xor problem solution space which is represented by a scape and fitness calculation. A benchmarker module reports detail information about recent training iterations.|
|`simple_neuroevolutionary_platform`|A simple but complete neuro network controlled by supervisor trees. Incl. polis, population, species with agents (exoself, cortex, neurons, actuators, sensors). Champion species are being saved in a mnesia db after training.|

## Summary
The network is hierarchically setup with a supervisor tree: Polis -> Population -> Specie -> Agent -> [Exoself, Cortex, Private Scape] -> [Sensors, Neurons, Actuators]

The specie contains the most important settings, e.g. population size, generation limit, evaluation limit, fitness goal, ...

The network initializes itself according to the scape morphology. The xor example contains requires two sensors and one actuator. Therefore, the resulting start feed forward network contains: 2 sensors -> 2 neurons => 1 neuron -> 1 actuator. I.e. if you start off with 10 sensors and 2 actuators, the resutlting start network would look like: 10 sensors -> 10 neurons => 2 neuron -> 2 actuator

During training phase the genotype mutator can apply to the genotype:
* Mutate/reset bias
* Mutate/reset weight
* Mutate/reset activation_fun
* Add/remove neuron
* Add/remove link between neurons

## Usage
We use an easy xor scape. The simple neuroevolutionary platform will provide a much faster and more accurate solution than the basic ff and SHC network are able to. Jump right into iex and start a training session.
```
$ iex -S mix
iex(1)> NNex.Population.start_training(NNex.Scape.Xor)
```

Example output:
```
--> starts specie evaluation 1
...
--> starts specie evaluation 50
*** Agent Details ***
Generation: 24
Fitness Score: 99999.44748276072
Results: [{1, 1, -1, -0.9999999999952417}, {-1, 1, 1, 0.9999999999473907}, {1, -1, 1, 0.9999999999991567}, {-1, -1, -1, -0.9999999999838228}]
Evolution: [add_neuron: nil, mutate_weights: nil, mutate_weights: nil, mutate_weights: nil, mutate_weights: nil, mutate_weights: nil, mutate_weights: nil, mutate_bias: -0.6047821251798196, mutate_bias: -1.0613023134455948, add_neuron: nil, mutate_weights: nil, mutate_bias: 2.832575296976719, mutate_activation_fun: :sin,mutate_activation_fun: :sin, mutate_bias: -1.416122868933134, add_link: nil, add_neuron: nil, add_link: nil, add_neuron: nil, mutate_weights: nil, mutate_bias: 1.4697050151951023, add_neuron: nil, add_neuron: nil, mutate_bias: -4.616982267976635, mutate_activation_fun: :tanh, add_neuron: nil, mutate_bias: 0.4257405621343202, mutate_bias: -4.837974312574072, mutate_weights: nil, mutate_bias: -1.3390302981690834, mutate_activation_fun: :sin, mutate_bias: -4.479495773019965, mutate_weights: nil, mutate_weights: nil, mutate_weights: nil, mutate_weights: nil, mutate_bias: -0.17501920497008105, add_neuron: nil, mutate_weights: nil]
*** Genotype Details ***
Sensors: 2
Neurons: 11
Actuators: 1
...
--> starts specie evaluation 90
*** Agent Details ***
Generation: 17
Fitness Score: 99999.99999999999
Results: [{1, 1, -1, -1.0}, {-1, 1, 1, 1.0}, {1, -1, 1, 1.0}, {-1, -1, -1, -1.0}]
Evolution: [mutate_bias: 3.061974080097536, mutate_weights: nil, mutate_bias: -0.09667420736140614, mutate_activation_fun: :gaussian, mutate_weights: nil, mutate_bias: -3.245686976705701, mutate_activation_fun: :tanh, mutate_weights: nil, mutate_bias: 1.4646110542953847, mutate_bias: 1.7195861930952392, mutate_bias: -0.29756556246420485, mutate_weights: nil, mutate_bias: 0.05718953777188407, mutate_activation_fun: :tanh, mutate_activation_fun: :tanh, mutate_bias: -0.6850869186187882, add_link: nil, add_neuron: nil, mutate_activation_fun: :gaussian, mutate_bias: -1.1529651926729487, add_neuron: nil, add_neuron: nil, mutate_weights: nil,mutate_activation_fun: :sin, add_neuron: nil, mutate_weights: nil]
*** Genotype Details ***
Sensors: 2
Neurons: 7
Actuators: 1
--> training finished by champion since: 504
```
Start a new training again with the same function `NNex.Population.start_training/1`.

## Contribution
Feel free to contribute. I am open to any feedback and PR. Also, don't hesitate to contact me for a nice chat about the topic of neuroevolution.

## Thanks
All this was not possible without Gene I. Sher's `Handbook of Neuroevolution through Erlang` and Elixir.

## Disclaimer
Please keep in mind, I just started with Elixir development and as well Neuroevolution. So bear with me if I have not understood some important functional concepts. Also, this repository is under construction.
