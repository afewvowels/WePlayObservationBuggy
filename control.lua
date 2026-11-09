local NAME = "wp-observation-buggy"

-- Hidden alternator: feeds this much power into each buggy's equipment grid.
local ALTERNATOR_WATTS = 1000000
local POWER_INTERVAL = 10  -- ticks between top-ups

-- storage.buggies[registration_number] = entity
local function init_storage()
  storage.buggies = storage.buggies or {}
end

local function track(entity)
  if not (entity and entity.valid and entity.name == NAME) then return end
  local id = script.register_on_object_destroyed(entity)
  storage.buggies[id] = entity
end

-- Pick up buggies that already exist (mod added to a save, or storage lost).
local function rescan()
  storage.buggies = {}
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered({name = NAME})) do
      track(entity)
    end
  end
end

-- Radar on wheels ----------------------------------------------------------
local function chart_all()
  local r = settings.global["wp-observation-buggy-chart-radius"].value
  for id, entity in pairs(storage.buggies) do
    if entity.valid then
      local force = entity.force
      if force then
        local p = entity.position
        force.chart(entity.surface, {{p.x - r, p.y - r}, {p.x + r, p.y + r}})
      end
    else
      storage.buggies[id] = nil
    end
  end
end

-- Hidden alternator --------------------------------------------------------
-- Tops up equipment buffers with up to 1 MW worth of energy. Shields, lasers,
-- roboports etc. are filled first; batteries get whatever is left.
local function give(equipment, budget)
  local need = equipment.max_energy - equipment.energy
  if need <= 0 then return budget end
  local amount = math.min(need, budget)
  equipment.energy = equipment.energy + amount
  return budget - amount
end

local function power_all()
  local budget_per_buggy = ALTERNATOR_WATTS * POWER_INTERVAL / 60  -- joules
  for _, entity in pairs(storage.buggies) do
    local grid = entity.valid and entity.grid
    if grid then
      local budget = budget_per_buggy
      local batteries = {}
      for _, equipment in pairs(grid.equipment) do
        if equipment.type == "battery-equipment" then
          batteries[#batteries + 1] = equipment
        elseif budget > 0 then
          budget = give(equipment, budget)
        end
      end
      for _, battery in pairs(batteries) do
        if budget <= 0 then break end
        budget = give(battery, budget)
      end
    end
  end
end

-- Tick handlers --------------------------------------------------------------
local function register_ticks()
  script.on_nth_tick(nil)
  local chart_interval = settings.global["wp-observation-buggy-chart-interval"].value
  if chart_interval == POWER_INTERVAL then
    -- on_nth_tick only keeps one handler per interval, so share it.
    script.on_nth_tick(POWER_INTERVAL, function()
      power_all()
      chart_all()
    end)
  else
    script.on_nth_tick(POWER_INTERVAL, power_all)
    script.on_nth_tick(chart_interval, chart_all)
  end
end

script.on_init(function()
  init_storage()
  rescan()
  register_ticks()
end)

script.on_load(register_ticks)

script.on_configuration_changed(function()
  init_storage()
  rescan()
  register_ticks()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "wp-observation-buggy-chart-interval" then
    register_ticks()
  end
end)

-- Tracking -------------------------------------------------------------------
local filter = {{filter = "name", name = NAME}}
local function on_built(event)
  track(event.entity)
end

script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)

script.on_event(defines.events.on_object_destroyed, function(event)
  if storage.buggies then
    storage.buggies[event.registration_number] = nil
  end
end)
