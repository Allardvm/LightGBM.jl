using BinaryProvider 

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
#const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

global ligthgbmpath=joinpath(abspath(joinpath(dirname(Base.find_package("LightGBM")), "..")),"deps/usr/lib")
if Sys.islinux()
    global prefix=joinpath(ligthgbmpath,"lib_lightgbm.so")
elseif Sys.iswindows()
    global prefix=joinpath(ligthgbmpath,"lib_lightgbm.dll")
elseif Sys.isapple()
    global prefix=joinpath(ligthgbmpath,"lib_lightgbm.dylib")
else
    error("not matching OS")
end

products = [
    LibraryProduct(prefix, ["lib_lightgbm"], :lib_lightgbm),
]

bin_prefix ="https://github.com/microsoft/LightGBM/releases/download/v2.3.1"
download_info = Dict(
    MacOS(:x86_64) => ("$bin_prefix/lib_lightgbm.dylib", "f55a5811b9ecdcc6356aaf7788582e74a246c44d75510ce21e1166bc33c0b752"),
    Linux(:x86_64) => ("$bin_prefix/lib_lightgbm.so", "07abb99ff02d67f0899d4393e8e2e9932c610156fcb35aca86fb01a615b6783e"),
    Windows(:x86_64) => ("$bin_prefix/lib_lightgbm.dll", "40d4b62c8bf7d583f511e3ae226f3e8179a6ae9f2bef8b34b3a6e02f71156b9b"),
    )

# First, check 
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# download
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    mkpath(ligthgbmpath)
    download(dl_info[1],prefix)
    println("installed library:",prefix)
end