__precompile__()

module LightGBM
using Libdl
using Dates
import StatsBase

# if LIGHTGBM_PATH is difined, automatical define LIGHTGBM_PATH
function setup()
    try
        ENV["LIGHTGBM_PATH"]
    catch
        println("setup...")
        global ligthgbmpath=joinpath(abspath(joinpath(dirname(Base.find_package("LightGBM")), "..")),"deps/usr/lib")
        if Sys.islinux()
            global prefix=joinpath(ligthgbmpath,"lib_lightgbm.so")
        elseif Sys.iswindows()
            global prefix=joinpath(ligthgbmpath,"lib_lightgbm.dll")
        elseif Sys.isapple()
            global prefix=joinpath(ligthgbmpath,"lib_lightgbm.dylib")
        else
            global prefix=""
        end

        if !isfile(prefix)
            include(joinpath(abspath(joinpath(dirname(Base.find_package("LightGBM")), "..")),"deps/build.jl"))
        end

        if isfile(prefix)
            return global ENV["LIGHTGBM_PATH"] = ligthgbmpath
        end
    end
end

# pre initialization
setup()

function __init__()
    setup()

    if !haskey(ENV, "LIGHTGBM_PATH")
        error("Environment variable LIGHTGBM_PATH not found. ",
            "Set this variable to point to the LightGBM directory prior to loading LightGBM.jl ",
            "(e.g. `ENV[\"LIGHTGBM_PATH\"] = \"../LightGBM\"`).")
    else
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