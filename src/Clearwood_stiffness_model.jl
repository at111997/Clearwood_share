module Clearwood_stiffness_model

using Flux
using JLD2
using JSON

export combi_model, make_input, DATA, load_models, make_input_from_json

struct DATA
    x_raw::Vector{Vector{Float64}}
    X::Vector{Vector{Float64}}
    Y::Vector{Vector{Float64}}
end

get_N_params(ds::DATA) = length(first(ds.x_raw))
get_N_output(ds::DATA) = length(first(ds.Y))

function setup_model(::Val{:A}, ds::DATA; rel_layer_size::Int=4, exclude_parameter_i::Int=0)
    N_inp = exclude_parameter_i > 0 ? get_N_params(ds) - 1 : get_N_params(ds)
    N_out = get_N_output(ds)
    return Chain(
        Dense(N_inp => rel_layer_size*N_inp, sigmoid),
        Dense(rel_layer_size*N_inp => rel_layer_size*N_inp, sigmoid),
        Dense(rel_layer_size*N_inp => N_out)
    ) |> f64
end


# model loading

function load_models(base_path::String=joinpath(@__DIR__, "model_AT_08_09"))
    path = joinpath(base_path, "parameters.jld2")
    all_parameters = load(path)["parameters"]
    baseline_params = filter(p -> p["exclude_parameter_i"] == 0, all_parameters)

    models = map(baseline_params) do p
        k = p["k_fold"]
        prefix = p["savename_prefix"]
        path = joinpath(base_path, "$(prefix)_exclude_parameter_i=0_k_fold=$(k)_seed=$(p["seed"]).jld2")
        result = load(path)["result"]
        ds = p["ds"]
        model = setup_model(Val(get(p, "model_type", :A)), ds; rel_layer_size=4, exclude_parameter_i=0)
        Flux.loadmodel!(model, result.model)
        model
    end

    return models
end

combi_model(x, models) = sum(m(x) for m in models) / length(models)

# input loading

function load_config(path::String)
    if endswith(path, ".json")
        return JSON.parse(read(path, String))
    else
        error("Unsupported file format. Please use .json")
    end
end

# input funciton 

const PARAM_BOUNDS = [
    #  name            min     max
    # EW cell geometry
    ("EW τ",           0.50,   0.99),
    ("EW αlumen",      0.9,    1.5),
    ("EW χ",           0.0,    0.3), #model trained on old layer offset logic where 0 is full offset
    ("EW θ",           150.0,  180.0),
    # LW cell geometry
    ("LW τ",           0.30,   0.99),
    ("LW αlumen",      0.6,    1.1),
    ("LW χ",           0.0,    0.3), #model trained on old layer offset logic where 0 is full offset
    ("LW θ",           150.0,  180.0),
    # Clearwood density
    ("ρEW",            0.30,   0.50),
    ("ρLW",            0.60,   1.00),
    ("fLW",            0.05,   0.5),
    # Ray properties
    ("fray",           0.04,   0.17),
    ("αray",           1.0,    29.0),
    # Fibre properties
    ("ϑratio",         0.3,    1.2),
    ("ϑEW",            8.0,    30.0),
]

"""
    make_input(EW_τ, EW_αlumen, EW_χ, EW_θ,
               LW_τ, LW_αlumen, LW_χ, LW_θ,
               ρEW, ρLW, fLW,
               fray, αray,
               ϑratio, ϑEW)

Normalises physical parameter values to [0,1] using the sensitivity study bounds
from Table 3 and returns a vector ready for `combi_model`.

offset conversion is done by 1 - χ because the model was trained on the old layer offset logic where 0 is full offset and 1 is no offset, but the new logic is the opposite.
#
"""
function make_input(EW_τ, EW_αlumen, EW_χ, EW_θ,
                    LW_τ, LW_αlumen, LW_χ, LW_θ,
                    ρEW, ρLW, fLW,
                    fray, αray,
                    ϑratio, ϑEW)

    raw = [EW_τ, EW_αlumen, 1-EW_χ, EW_θ,
           LW_τ, LW_αlumen, 1-LW_χ, LW_θ,
           ρEW, ρLW, fLW,
           fray, αray,
           ϑratio, ϑEW]

    return [(raw[i] - PARAM_BOUNDS[i][2]) / (PARAM_BOUNDS[i][3] - PARAM_BOUNDS[i][2])
            for i in 1:15]
end

"""
    make_input_from_json(file_path::String)

Loads parameter values from a JSON config file, normalises them using `make_input`, and returns a vector ready for `combi_model`.
The JSON file should have the following structure:
```json
{
    "ew_cell": [EW_τ, EW_αlumen, EW_χ, EW_θ],
    "lw_cell": [LW_τ, LW_αlumen, LW_χ, LW_θ],
    "density": [ρEW, ρLW, fLW],
    "ray_props": [fray, αray],
    "fibre_props": [ϑratio, ϑEW]
}
```
"""
function make_input_from_json(file_path::String)

    config = load_config(file_path)
    return make_input(
        config.ew_cell...,
        config.lw_cell...,
        config.density...,
        config.ray_props...,
        config.fibre_props...
    )
end

end # module