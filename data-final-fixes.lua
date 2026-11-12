-- Wheel dust -----------------------------------------------------------------
-- Runs in final-fixes, after every other mod, so the buggy picks up whatever
-- dust the vanilla car ends up with (including tiles added by mods such as
-- Alien Biomes, if they add dust to the car) and nothing can undo the change.
--
-- The particles stay exactly as the car has them, so each tile keeps its own
-- dust colour; only where they spawn changes. Offsets are in tiles from the
-- entity centre, for the buggy facing north; the game rotates them with the
-- vehicle (rotate_offsets). Only the strut-mounted pair is used: the other
-- pair sits behind the sphere, where dust would draw over the body.
local NAME = "wp-observation-buggy"
local WHEEL_OFFSETS = {{-1.55, 1.0}, {1.55, 1.0}}

local buggy = data.raw["car"][NAME]
local car = data.raw["car"]["car"]

-- Child tables are collected before a table is edited, because adding keys
-- to a table while pairs() is walking it is undefined in Lua.
local function children_of(t)
  local list = {}
  for _, v in pairs(t) do
    if type(v) == "table" then list[#list + 1] = v end
  end
  return list
end

local function move_to_wheels(t)
  if type(t) ~= "table" then return end
  local kids = children_of(t)
  if t.particle_name or t.smoke_name then
    t.offsets = table.deepcopy(WHEEL_OFFSETS)
  end
  for _, v in ipairs(kids) do move_to_wheels(v) end
end

-- Default dust ----------------------------------------------------------------
-- The car only makes dust on the tiles it lists, so any other ground (modded
-- tiles, paved floors) gives none. This adds one default entry for every
-- unlisted tile: plain light sand dust and grit.
--
-- Dust tinted to the tile (apply_tile_tint) matched the ground so closely it
-- vanished, so any effect that uses it gets a fixed light tan instead.
local DUST_TINT = {r = 0.95, g = 0.88, b = 0.74, a = 1}
local retinted = 0

local function untint(t)
  if type(t) ~= "table" then return end
  local kids = children_of(t)
  if t.apply_tile_tint then
    t.apply_tile_tint = nil
    t.tint = DUST_TINT
    retinted = retinted + 1
  end
  for _, v in ipairs(kids) do untint(v) end
end

local DEFAULT_DUST = "sand-1-dust-vehicle-particle"
local DEFAULT_GRIT = "sand-1-stone-vehicle-particle-tiny"
local particles = data.raw["optimized-particle"] or {}

local function has_default(list)
  for _, entry in pairs(list) do
    if entry.use_as_default then return true end
  end
  return false
end

local function default_entry()
  local actions = {}
  if particles[DEFAULT_DUST] then
    actions[#actions + 1] = {
      type = "create-particle",
      particle_name = DEFAULT_DUST,
      initial_height = 0.2,
      initial_vertical_speed = 0.02,
      initial_vertical_speed_deviation = 0.05,
      offset_deviation = {{-0.25, -0.25}, {0.25, 0.25}},
      probability = 0.5,
      repeat_count = 8,
      rotate_offsets = true,
      speed_from_center = 0.01
    }
  end
  if particles[DEFAULT_GRIT] then
    actions[#actions + 1] = {
      type = "create-particle",
      particle_name = DEFAULT_GRIT,
      frame_speed = 1,
      initial_height = 0.1,
      initial_vertical_speed = 0.02,
      initial_vertical_speed_deviation = 0.05,
      offset_deviation = {{-0.25, -0.25}, {0.25, 0.25}},
      probability = 0.02,
      repeat_count = 2,
      rotate_offsets = true,
      speed_from_center = 0.01
    }
  end
  if #actions == 0 then return nil end
  -- tiles is a required list; out-of-map can't be driven on, so it's a safe
  -- placeholder. use_as_default is what makes this entry cover other tiles.
  return {tiles = {"out-of-map"}, use_as_default = true, actions = actions}
end

if buggy then
  if car and car.track_particle_triggers then
    buggy.track_particle_triggers = table.deepcopy(car.track_particle_triggers)
  end
  buggy.track_particle_triggers = buggy.track_particle_triggers or {}
  local triggers = buggy.track_particle_triggers

  if not has_default(triggers) then
    local entry = default_entry()
    if entry then triggers[#triggers + 1] = entry end
  end

  untint(triggers)
  move_to_wheels(triggers)
  log("[WePlayObservationBuggy] wheel dust: " .. #triggers
    .. " tile entries, " .. retinted .. " tile-tinted effects set to fixed tan")
end
