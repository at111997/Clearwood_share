# Clearwood Unit Cell NN

This repository contains a neural network model for clearwood unit cell analysis.

## Project Structure
* `model_AT_08_09/`: Contains the trained model data/weights.
* `Clearwood_stiffness_model.jl`: The main script to load the model and run simulations.
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

To use the model, run the `Clearwood_stiffness_model.jl` script:

```julia
using Clearwood_stiffness_model

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

or loading the parameters from a JSON file:

```julia
using Clearwood_stiffness_model

# Load the model
models = load_model()
# Load parameters from JSON file
x = make_input_from_json(path)
# Run the model to get predictions
res = combi_model(x, models)
```

## Input Parameters

The model expects a configuration input (or JSON file) defined by the following parameters:

### Earlywood (EW) Wood Cell Geometry 
* **Tension :** Governs the transition from smooth, rounded cell corners at vanishing $\tau$ to increasingly sharp, kink-like features (Typical range: $0.5$ – $0.99$).
* **Lumen Aspect Ratio:** The ratio of the lumen radius ($r_R/r_T$) in the radial direction $r_R$ to that in the tangential direction $r_T$ (Typical range: $0.9$ – $1.5$).
* **Tangential Offset:** Quantifies the continuity of the tangential webs. An offset of **1** corresponds to a standard softwood structure (every second row shifted by half a cell), whereas an offset of **0** results in continuous tangential webs (Typical range: $0.7$ – $1.0$).
* **Interior Angle:** Defines the obtuse angle between the radial webs; cell walls become more continuous as the angle approaches $180°$ (Typical range: $150°$ – $180°$).

### Latewood (LW) Wood Cell Geometry
* **Tension:** Governs the transition from smooth, rounded cell corners to sharp features (Typical range: $0.3$ – $0.99$). 
* **Lumen Aspect Ratio:** Ratio of radial radius to tangential radius ($r_R/r_T$) (Typical range: $0.6$ – $1.1$).
* **Tangential Offset:** Continuity of tangential webs ($1$ for standard softwood, $0$ for continuous) (Typical range: $0.7$ – $1.0$).
* **Interior Angle:** Defines the obtuse angle between radial webs (Typical range: $150°$ – $180°$).

### Clearwood Density 
* **EW Density:** Earlywood density in $\frac{g}{cm^3}$ (Typical range: $0.3$ – $0.5$).
* **LW Density:** Latewood density in $\frac{g}{cm^3}$ (Typical range: $0.6$ – $1.0$).
* **LW Volume Fraction:** Relative amount of the LW phase in clearwood (Typical range: $0.05$ – $0.5$).

### Ray Properties
* **Ray Volume Fraction:** The relative volume occupied by wood rays (Typical range: $0.04$ – $0.17$).
* **Ray Aspect Ratio:** The ratio of ray height to width (Typical range: $1.0$ – $29.0$).

### Cellulose Microfibril Properties 
* **EW to LW Microfibril Ratio:** The ratio (LW/EW) of MFA between the two phases (Typical range: $0.3$ – $1.2$).
* **EW Microfibril Angle (MFA):** The orientation of cellulose microfibrils in the EW cell wall (Typical range: $8.0$ – $30.0$). 

Full details see: https://doi.org/10.1007/s00226-026-01789-0

Typical Norway Spruce values

```json
{
    "EW_cell": [
        0.7,
        1.1,
        1.0,
        170.0
    ],
    "lw_cell": [
        0.6,
        0.9,
        1.0,
        170.0
    ],
    "density": [
        0.3,
        0.6,
        0.25
    ],
    "ray_props": [
        0.047,
        10.7
    ],
    "fibre_props": [
        0.64,
        10.0
    ]
}

```







