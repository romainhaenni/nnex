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

## Usage
Let's say you want to have 5 training sessions. In each we start with a random set of weights and bias within a feed forward network representing a [2,2,1] shape. The only available problem to solve is xor, yet. Actually, you can only set the amount of training iterations. All other settings have been hardcoded in the initializers of each module.
```
$ iex -S mix
iex(1)> NNex.Benchmarker.start(:xor, 5)
```

Example output:
```
Achieved fitness score: 45624.200131771206 with [{1, 1, -1, -0.9999999785796826}, {-1, 1, 1, 0.9999938647437604}, {1, -1, 1, 0.9999938404094855}, {-1, -1, -1, -0.9999918476427577}]
Achieved fitness score: 11006.031209907529 with [{1, 1, -1, -0.9999480047330113}, {-1, 1, 1, 0.9999936971789458}, {1, -1, 1, 0.999992923352157}, {-1, -1, -1, -0.9999388043316404}]
Achieved fitness score: 0.7064830898809884 with [{1, 1, -1, 0.03523224746670333}, {-1, 1, 1, 0.999999994012389}, {1, -1, 1, 0.034748345322130385}, {-1, -1, -1, -0.9906227933898615}]
Achieved fitness score: 16251.214657594215 with [{1, 1, -1, -0.9999925563975224}, {-1, 1, 1, 0.9999928579560639}, {1, -1, 1, 0.9999928600623587}, {-1, -1, -1, -0.9999500165606103}]
Achieved fitness score: 14922.10335579571 with [{1, 1, -1, -0.999994263000968}, {-1, 1, 1, 0.9999612510931809}, {1, -1, 1, 0.9999599413541268}, {-1, -1, -1, -0.9999894364858347}]
benchmark report for xor
Fitness:
min: 0.5256343762415718
max: 2875.0720264102465
avg: 628.6143732786473
std: 1127.8879566720145
Evaluations:
min: 102
max: 1000
avg: 443.2
std: 324.86514125095044
Attempts:
min: 96
max: 990
avg: 432.2
std: 323.9570341881775
```
Start a new training again with the same function `NNex.Benchmarker.start/2`.

## Contribution
Feel free to contribute. I am open to any feedback and PR. Also, don't hesitate to contact me for a nice chat about the topic of neuroevolution.

## Thanks
All this was not possible without Gene I. Sher's `Handbook of Neuroevolution through Erlang` and Elixir.

## Disclaimer
Please keep in mind, I just started with Elixir development and as well Neuroevolution. So bear with me if I have not understood some important functional concepts. Also, this repository is under construction.
