using Test
using Clearwood_stiffness_model

models = load_models()
config_path = joinpath(@__DIR__, "test_config.json")

@testset "model input" begin
    # Direct input (without config file)
    x_direct = make_input(
        0.75, 1.0, 1.0, 150.0,   # EW cell geometry
        0.65, 1.0, 1.0, 150.0,   # LW cell geometry
        0.5,  0.8, 0.05,         # Clearwood density
        0.17, 10.7,              # Ray properties
        0.8,  12.0               # Fibre properties
    )
    # Input from config file (should match direct input)
    x_config = make_input_from_json(config_path)

    @test x_direct == x_config
end

@testset "model output" begin
    x_config = make_input_from_json(config_path)
    res = combi_model(x_config, models)
    expected = [
        1.3080398997555913,
        0.5240623527767148,
        9.80720717009264,
        0.5049344048324912,
        0.6462152467197331,
        0.09657656964119295,
        0.60525544419996,
        0.028778536832594265,
        0.01709531604271003,
        0.24452307562872563,
        0.21380021770896254,
        0.3208442252775903,
    ]

    @test res ≈ expected atol=1e-6
end
