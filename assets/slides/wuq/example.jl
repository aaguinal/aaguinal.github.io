using Pkg
cd("/Users/aguinam1/Documents/Git/ai2thor-cset-experiments/julia/Ai2thorCsetProject")  # use this environment to avoid `constructor` error
Pkg.activate(".")

using Catlab
using AlgebraicRewriting

include("./AlgebraicPlanning.jl")

using Catlab
using AlgebraicRewriting

@present OntBreadOnly(FreeSchema) begin
  ## Objects
  Thing::Ob
  BreadLoaf::Ob
  BreadSlice::Ob
  Countertop::Ob
  Stool::Ob

  ## Morphisms
  f::Hom(BreadSlice, BreadLoaf)  # is part of
  g::Hom(BreadLoaf, Thing)  # is-a
  # h::Hom(BreadSlice, Thing)  # is-a
  h::Hom(Countertop, Thing)  # is-a
  l::Hom(Stool, Thing)  # is-a

  ## Relations
  InOn::Ob
  inOn_l::Hom(InOn, Thing)
  inOn_r::Hom(InOn, Thing)
end

# create dynamic acset object
const BreadOnly = DynamicACSet("BreadOnly", OntBreadOnly)

function make_cache(type, schema)
  cache_dir = mkpath(joinpath(@__DIR__, "cache"))
  cache = Dict(Iterators.map(ob -> begin
      name = nameof(ob)
      path = joinpath(cache_dir, "$name.json")
      if isfile(path)
        @info "Reading representables from $path"
        rep = read_json_acset(type, path)
      else
        @info "Computing representable $name"
        rep = representable(type, schema, name)
        write_json_acset(rep, path)
      end
      name => (rep, 1)
    end, generators(schema, :Ob)))
end

# compute representables 
cache = make_cache(BreadOnly, OntBreadOnly)
yBreadOnly = yoneda(BreadOnly; cache=cache)

state = @acset_colim yBreadOnly begin
  # Items in the scene
  myCountertop::Countertop
  myStool::Stool
  naturesOwn::BreadLoaf
  (slice0, slice1, slice2)::BreadSlice

  # Nature's Own Breadloaf has three slices
  f(slice0) == naturesOwn  # is part of
  f(slice1) == naturesOwn  # is part of
  f(slice2) == naturesOwn  # is part of

  # Breadloaf is on countertop (relation)
  bread_on_countertop::InOn
  inOn_l(bread_on_countertop) == naturesOwn  # thing
  inOn_r(bread_on_countertop) == myCountertop  # thing on top of

  # Breadloaf, counterop, and stool are things
  (null, thing1, thing2, thing3)::Thing
  g(naturesOwn) == thing1  # is-a
  h(myCountertop) == thing2  # is-a
  l(myStool) == thing3  # is-a
end

