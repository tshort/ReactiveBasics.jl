makedocs(
    modules = [ReactiveBasics],
    clean = false,
    format = :html,
    sitename = "ReactiveBasics.jl",
    authors = "Tom Short",
    # linkcheck = !("skiplinks" in ARGS),
    pages = Any[ # Compat: `Any` for 0.4 compat
        "Home" => "index.md",
        "API" => "api.md",
    ]
)


deploydocs(
    repo = "github.com/tshort/ReactiveBasics.jl.git",
    target = "build",
    julia = "0.5",
    deps = nothing,
    make = nothing,
)

