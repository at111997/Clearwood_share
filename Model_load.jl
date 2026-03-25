using Flux
using JLD2

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

all_parameters = load("model_AT_08_09/parameters.jld2")["parameters"]
baseline_params = filter(p -> p["exclude_parameter_i"] == 0, all_parameters)

models = map(baseline_params) do p
    k = p["k_fold"]
    prefix = p["savename_prefix"]
    path = "model_AT_08_09/$(prefix)_exclude_parameter_i=0_k_fold=$(k)_seed=$(p["seed"]).jld2"
    result = load(path)["result"]
    ds = p["ds"]
    model = setup_model(Val(get(p, "model_type", :A)), ds; rel_layer_size=4, exclude_parameter_i=0)
    Flux.loadmodel!(model, result.model)
    model
end

combi_model(x) = sum(m(x) for m in models) / length(models)

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


# test

x = make_input(
    0.75, 1.0, 1.0, 150.0,   # EW cell geometry
    0.65, 1.0, 1.0, 150.0,   # LW cell geometry
    0.5,  0.8, 0.05,         # Clearwood density
    0.17, 10.7,              # Ray properties
    0.8,  12.0                 # Fibre properties
)

combi_model(x)