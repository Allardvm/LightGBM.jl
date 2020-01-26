__precompile__()

module LightGBM
using Libdl
using Dates
import StatsBase

# if LIGHTGBM_PATH is difined, automatical define LIGHTGBM_PATH
function lgbm_librarysetup()
    try
        println("ENV[\"LIGHTGBM_PATH\"] is　",ENV["LIGHTGBM_PATH"])
        return ENV["LIGHTGBM_PATH"]
    catch
        println("LightGBM library setup start...")
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
            println("Instaling library")
            include(joinpath(abspath(joinpath(dirname(Base.find_package("LightGBM")), "..")),"deps/build.jl"))
        end

        if isfile(prefix)
            println("Set library path:",ligthgbmpath)
            return ligthgbmpath
        else
            println("Not find LightGBM library")
        end
    end
end

# pre initialization
ENV["LIGHTGBM_PATH"] = lgbm_librarysetup()

function __init__()
    println("Start __init__")
    ENV["LIGHTGBM_PATH"] = lgbm_librarysetup()

    if !haskey(ENV, "LIGHTGBM_PATH")
        error("Environment variable LIGHTGBM_PATH not found. ",
            "Set this variable to point to the LightGBM directory prior to loading LightGBM.jl ",
            "(e.g. `ENV[\"LIGHTGBM_PATH\"] = \"../LightGBM\"`).")
    else
        try
            println("LIGHTGBM_PATH setup1...")
            global LGBM_library = Libdl.find_library(["lib_lightgbm.so", "lib_lightgbm.dll",
                "lib_lightgbm.dylib"], [ENV["LIGHTGBM_PATH"]])
        catch
            println("LGBM_library is null. step2...")
            global LGBM_library = Libdl.find_library(["lib_lightgbm.so", "lib_lightgbm.dll",
            "lib_lightgbm.dylib"], [lgbm_librarysetup()])

            if LGBM_library == ""
                println("LGBM_library is null. step3...")
                global LGBM_library = prefix
            end

            if LGBM_library == ""
                error("Could not open the LightGBM library at $(ENV["LIGHTGBM_PATH"]). ",
                    "Set this variable to point to the LightGBM directory prior to loading LightGBM.jl ",
                    "(e.g. `ENV[\"LIGHTGBM_PATH\"] = \"../LightGBM\"`).")
            end
        end
    end
    println("Finished __init__()")
end

println("ENV[\"LIGHTGBM_PATH\"] is ",ENV["LIGHTGBM_PATH"])
#const LGBM_library = find_library(["lib_lightgbm.so", "lib_lightgbm.dll", "lib_lightgbm.dylib"], [lgbm_librarysetup()])
const LGBM_library = find_library(["lib_lightgbm.so", "lib_lightgbm.dll", "lib_lightgbm.dylib"], [ENV["LIGHTGBM_PATH"]])
println("LGBM_library is ",LGBM_library)

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