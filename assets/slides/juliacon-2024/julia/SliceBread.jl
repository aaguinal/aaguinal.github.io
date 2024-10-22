include("AlgebraicPlanning.jl")
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
  h::Hom(Countertop, Thing)  # is-a
  l::Hom(Stool, Thing)  # is-a

  ## Relations
  InOn::Ob
  inOn_l::Hom(InOn, Thing)
  inOn_r::Hom(InOn, Thing)
end

# Create a C-set type based on ontology
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
  # f::Hom(BreadSlice, BreadLoaf)
  f(slice0) == naturesOwn  # is part of
  f(slice1) == naturesOwn  # is part of
  f(slice2) == naturesOwn  # is part of

  # Breadloaf is on countertop (relation)
  thing_on_thing::InOn
  inOn_l(thing_on_thing) == naturesOwn
  inOn_r(thing_on_thing) == myCountertop

  # Breadloaf, counterop, and stool are things
  # g::Hom(BreadLoaf, Thing)
  # h::Hom(Countertop, Thing)
  # l::Hom(Stool, Thing)
  (thing1, thing2, thing3)::Thing
  g(naturesOwn) == thing1
  h(myCountertop) == thing2
  l(myStool) == thing3

end

# Make rule
d = DRule(@migration(SchRule, OntBreadOnly, begin
  L => @join begin
    (thing1, thing2)::Thing
    breadloaf::BreadLoaf
    countertop::Countertop
    stool::Stool

    g(breadloaf) == thing1
    h(countertop) == thing2

    thing_on_thing::InOn
    inOn_l(thing_on_thing) == breadloaf
    inOn_r(thing_on_thing) == countertop
  end
  K => @join begin
    thing::Thing
    breadloaf::BreadLoaf
    countertop::Countertop
    stool::Stool
  end
  R => @join begin
    (thing1, thing2)::Thing
    breadloaf::BreadLoaf
    countertop::Countertop
    stool::Stool

    g(breadloaf) == thing1
    h(stool) == thing2

    thing_on_thing::InOn
    inOn_l(thing_on_thing) == breadloaf
    inOn_r(thing_on_thing) == stool
  end
  l => begin
    thing => thing1
    breadloaf => breadloaf
    countertop => countertop
    stool => stool
  end
  r => begin
    thing => thing1
    breadloaf => breadloaf
    countertop => countertop
    stool => stool
  end
end))

move_bread_action = make_rule(d.diag, yBreadOnly)

new_state = apply_rule(move_bread_action, state)

