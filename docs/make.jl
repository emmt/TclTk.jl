using Documenter

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..", "src")))

using TclTk

DEPLOYDOCS = (get(ENV, "CI", nothing) == "true")

makedocs(
    sitename = "a Julia interface to Tcl/Tk",
    format = Documenter.HTML(
        edit_link = "main",
        prettyurls = DEPLOYDOCS,
    ),
    authors = "Éric Thiébaut and contributors",
    pages = [
        "index.md",
        "objects.md",
        "lists.md",
        "interpreters.md",
        "variables.md",
        "callbacks.md",
        "widgets.md",
        "dialogs.md",
        "public.md",
        "develop.md",
    ]
)

if DEPLOYDOCS
    deploydocs(
        repo = "https://github.com/JuliaInterop/TclTk.jl.git",
    )
end
