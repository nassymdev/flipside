-- we need a mod name to set it as the  global 
sxeif = sxeif or {}

assert(SMODS.load_file("src/atlas.lua"))()
assert(SMODS.load_file("src/consumeables.lua"))()
assert(SMODS.load_file("src/decks.lua"))()
assert(SMODS.load_file("src/general_ui.lua"))()
assert(SMODS.load_file("src/funcs.lua"))()
assert(SMODS.load_file("src/shaders.lua"))()
assert(SMODS.load_file("src/editions.lua"))()
assert(SMODS.load_file("src/drawsteps.lua"))()
assert(SMODS.load_file("src/enhancements.lua"))()
assert(SMODS.load_file("src/jokers.lua"))()