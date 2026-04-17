using Clearwood_share

models = load_models()

x = make_input(
    0.75, 1.0, 1.0, 150.0,   # EW cell geometry
    0.65, 1.0, 1.0, 150.0,   # LW cell geometry
    0.5,  0.8, 0.05,         # Clearwood density
    0.17, 10.7,              # Ray properties
    0.8,  12.0                 # Fibre properties
)

res = combi_model(x, models)
