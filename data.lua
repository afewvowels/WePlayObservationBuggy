local NAME = "wp-observation-buggy"
local GFX = "__WePlayObservationBuggy__/graphics/"

-- Sprite sheets: 64 directions, 8 per row, rendered at 64 px per tile.
-- Frames were cropped by tools/pack_sheets.py; it prints these numbers.
local body = {
  filename = GFX .. NAME .. ".png",
  width = 336,
  height = 364,
  shift = {0, -1.15625},
  scale = 0.5,
  frame_count = 1,
  direction_count = 64,
  line_length = 8,
  max_advance = 0.2
}

-- Player-colour layer: grayscale paint, tinted at runtime. Same crop as body.
local mask = {
  filename = GFX .. NAME .. "-mask.png",
  width = 336,
  height = 364,
  shift = {0, -1.15625},
  scale = 0.5,
  frame_count = 1,
  direction_count = 64,
  line_length = 8,
  max_advance = 0.2,
  apply_runtime_tint = true
}

local shadow = {
  filename = GFX .. NAME .. "-shadow.png",
  width = 411,
  height = 240,
  shift = {0.789062, -0.03125},
  scale = 0.5,
  frame_count = 1,
  direction_count = 64,
  line_length = 8,
  max_advance = 0.2,
  draw_as_shadow = true
}

-- Entity: start from the vanilla car so sounds, physics and effects carry over.
local buggy = table.deepcopy(data.raw["car"]["car"])
buggy.name = NAME
buggy.icon = GFX .. NAME .. "-icon.png"
buggy.icon_size = 64
buggy.icons = nil
buggy.minable = {mining_time = 0.4, result = NAME}
buggy.animation = {layers = {body, mask, shadow}}

-- These all use the vanilla car's art, so drop them.
buggy.turret_animation = nil
buggy.light_animation = nil
buggy.water_reflection = nil
buggy.guns = nil

-- Wheel dust: see data-final-fixes.lua.

-- Exhaust smoke: the vanilla car puffs it out just behind its own small body.
-- Smoke draws above everything, so when the buggy faces away from the camera
-- it lands on top of the sphere. Dropped.
if buggy.energy_source then buggy.energy_source.smoke = nil end

-- Sounds --------------------------------------------------------------------
local SFX = "__WePlayObservationBuggy__/sounds/"

buggy.working_sound = {
  sound            = {filename = SFX .. "wp-observation-buggy-engine-loop.ogg",  volume = 0.3},
  activate_sound   = {filename = SFX .. "wp-observation-buggy-engine-start.ogg", volume = 0.35},
  deactivate_sound = {filename = SFX .. "wp-observation-buggy-engine-stop.ogg",  volume = 0.35},
  match_speed_to_activity = true
}
buggy.open_sound  = {filename = SFX .. "wp-observation-buggy-hatch-open.ogg",  volume = 0.9}
buggy.close_sound = {filename = SFX .. "wp-observation-buggy-hatch-close.ogg", volume = 0.9}
buggy.stop_trigger = {{
  type = "play-sound",
  sound = {{filename = SFX .. "wp-observation-buggy-brake.ogg", volume = 0.45}}
}}

-- Radar ping, played to occupants from control.lua.
local ping = {
  type = "sound",
  name = NAME .. "-ping",
  filename = SFX .. "wp-observation-buggy-ping.ogg",
  volume = 0.5
}

-- About 3.7 tiles wheel to wheel. Kept a bit smaller than the sprite so it
-- doesn't snag on every tree.
buggy.collision_box = {{-1.3, -1.3}, {1.3, 1.3}}
buggy.selection_box = {{-1.7, -1.7}, {1.7, 1.7}}
buggy.drawing_box_vertical_extension = 2.5

buggy.max_health = 600
buggy.inventory_size = 40
buggy.equipment_grid = NAME .. "-grid"

-- Item
local item = table.deepcopy(data.raw["item-with-entity-data"]["car"])
item.name = NAME
item.icon = GFX .. NAME .. "-icon.png"
item.icon_size = 64
item.icons = nil
item.place_result = NAME
item.order = "b[personal-transport]-a[car]-b[observation-buggy]"

-- Recipe
local recipe = {
  type = "recipe",
  name = NAME,
  enabled = false,
  energy_required = 3,
  ingredients = {
    {type = "item", name = "engine-unit", amount = 8},
    {type = "item", name = "steel-plate", amount = 10},
    {type = "item", name = "electronic-circuit", amount = 10},
    {type = "item", name = "radar", amount = 1}
  },
  results = {{type = "item", name = NAME, amount = 1}}
}

-- Equipment grid: 4x4, takes normal armor equipment. Power comes from a
-- hidden 1 MW alternator in control.lua, so every cell is free.
local grid = {
  type = "equipment-grid",
  name = NAME .. "-grid",
  width = 4,
  height = 4,
  equipment_categories = {"armor"}
}

data:extend({buggy, item, recipe, grid, ping})

-- Unlock alongside the car.
local tech = data.raw["technology"]["automobilism"]
if tech then
  tech.effects = tech.effects or {}
  table.insert(tech.effects, {type = "unlock-recipe", recipe = NAME})
end
