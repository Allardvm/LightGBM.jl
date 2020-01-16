__precompile__()

module LightGBM
using Libdl
using Dates
import StatsBase

function __init__()
    if !haskey(ENV, "LIGHTGBM_PATH")
        error("Environment variable LIGHTGBM_PATH not found. ",
            "Set this variable to point to the LightGBM directory prior to loading LightGBM.jl ",
            "(e.g. `ENV[\"LIGHTGBM_PATH\"] = \"../LightGBM\"`).")
    else
        if isfile(LGBM_library)
            include(joinpath(@__DIR__,"deps/build.jl"))
        end

        if Sys.islinux()
            prefix=joinpath(@__DIR__, "usr/lib/lib_lightgbm.so")
        elseif Sys.iswindows()
            prefix=joinpath(@__DIR__, "usr/lib/lib_lightgbm.dll")
        elseif Sys.ismacos()
            prefix=joinpath(@__DIR__, "usr/lib/lib_lightgbm.dylib")
        else
            prefix=""
        end

        if isfile(prefix)
            ENV["LIGHTGBM_PATH"] = prefix
        end

        global LGBM_library = Libdl.find_library(["lib_lightgbm.so", "lib_lightgbm.dll",
            "lib_lightgbm.dylib"], [ENV["LIGHTGBM_PATH"]])

        if LGBM_library == ""
            error("Could not open the LightGBM library at $(ENV["LIGHTGBM_PATH"]). ",
                  "Set this variable to point to the LightGBM directory prior to loading LightGBM.jl ",
                  "(e.g. `ENV[\"LIGHTGBM_PATH\"] = \"../LightGBM\"`).")
        end
    end
end

const LGBM_library = find_library(["lib_lightgbm.so", "lib_lightgbm.dll", "lib_lightgbm.dylib"], [ENV["LIGHTGBM_PATH"]])

include("wrapper.jl")
include("estimators.jl")
include("utils.jl")
include("fit.jl")
include("predict.jl")
include("cv.jl")
include("search_cv.jl")
include("LightGBM-util2.jl")

export fit, predict, cv, search_cv, savemodel, loadmodel
export LGBMEstimator, LGBMRegression, LGBMBinary, LGBMMulticlass
export metaformattedclassresult, metaformattedclassresult, formattedclassfit, predict2

end # module LightGBM