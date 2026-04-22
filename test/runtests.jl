using JSON3
using Clearwood_stiffness_model

models = load_models()

# Direct input (without config file)
x_direct = make_input(
    0.75, 1.0, 1.0, 150.0,   # EW cell geometry
    0.65, 1.0, 1.0, 150.0,   # LW cell geometry
    0.5,  0.8, 0.05,         # Clearwood density
    0.17, 10.7,              # Ray properties
    0.8,  12.0                 # Fibre properties
)

res_direct = combi_model(x_direct, models)

# Input loading from config file
config = JSON3.read(read("test/test_config.json", String))

x_config = make_input(
    config.ew_cell...,
    config.lw_cell...,
    config.density...,
    config.ray_props...,
    config.fibre_props...
)

res_config = combi_model(x_config, models)