# Clearwood Unit Cell NN

This repository contains a neural network model for clearwood unit cell analysis.

## Project Structure
* `model_AT_08_09/`: Contains the trained model data/weights.
* `Clearwood_share.jl`: The main script to load the model and run simulations.
* `Project.toml` & `Manifest.toml`: Julia environment configuration.

## Install

To set up the environment, run the following commands in Julia:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

or install it in your current environment with:

```julia
using Pkg
Pkg.add(path=".")
```

## Usage

To use the model, run the `Clearwood_share.jl` script:

```julia
using Clearwood_share

# Load the model
models = load_model()
# Generate the input data
x = make_input(
    0.75, 1.0, 1.0, 150.0,   # EW cell geometry
    0.65, 1.0, 1.0, 150.0,   # LW cell geometry
    0.5,  0.8, 0.05,         # Clearwood density
    0.17, 10.7,              # Ray properties
    0.8,  12.0               # Fibre properties
)
# Run the model to get predictions
res = combi_model(x, models)

```

