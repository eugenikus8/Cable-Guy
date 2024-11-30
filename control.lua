-- Define constants
local CHECK_INTERVAL = 600

-- Storage for tracked entities
local tracked_entities = {}

-- Convert string settings to tables for white/black lists
local function parse_list(setting)
    local values = {}
    for value in setting:gmatch("([^,]+)") do
        values[value:match("^%s*(.-)%s*$")] = true
    end
    return values
end

-- Function to check if entity is within electric pole range
local function is_within_pole_range(entity)
    local poles = entity.surface.find_entities_filtered{
        area = {{entity.position.x - 10, entity.position.y - 10}, {entity.position.x + 10, entity.position.y + 10}},
        type = "electric-pole"
    }
    for _, pole in pairs(poles) do
        if pole.valid and pole.electric_network_id == entity.electric_network_id then
            return true
        end
    end
    return false
end

-- Check the entity and add alerts if necessary
local function check_entity(entity, player, settings)
    if not entity.valid then return end

    local energy_source = entity.prototype and entity.prototype.electric_energy_source_prototype
    local is_blacklisted = settings.blacklist_types[entity.type] or settings.blacklist_names[entity.name]

    if energy_source then
        -- Low-power alert
        if settings.alerts_all_consume_prototypes and not is_blacklisted then
            if (energy_source.usage_priority == "primary-input" or 
                energy_source.usage_priority == "secondary-input" or 
                energy_source.usage_priority == "lamp") and 
                entity.energy == 0 then
                player.add_custom_alert(entity, {type = "entity", name = entity.name}, {"alerts.low-power"}, true)
            end
        end

        -- Not-connected alert
        if settings.alerts_all_generic_prototypes and not is_blacklisted then
            if not is_within_pole_range(entity) and 
               (energy_source.usage_priority == "primary-output" or 
                energy_source.usage_priority == "secondary-output" or 
                energy_source.usage_priority == "tertiary" or 
                energy_source.usage_priority == "solar" or 
                entity.type == "accumulator") then
                player.add_custom_alert(entity, {type = "entity", name = entity.name}, {"alerts.not-connected", {"entity-name." .. entity.name}}, true)
            end
        end
    end
end

-- Event handlers for entity tracking
local function on_built_entity(event)
    local entity = event.created_entity or event.entity
    if entity and entity.valid then
        tracked_entities[entity.unit_number] = entity
    end
end

local function on_entity_removed(event)
    local entity = event.entity
    if entity and entity.valid then
        tracked_entities[entity.unit_number] = nil
    end
end

-- Periodic check of tracked entities
local function on_tick_check_entities()
    for _, player in pairs(game.connected_players) do
        local settings = {
            alerts_all_consume_prototypes = settings.get_player_settings(player)["alerts-all-consume-prototypes"].value,
            alerts_all_generic_prototypes = settings.get_player_settings(player)["alerts-all-generic-prototypes"].value,
            blacklist_types = parse_list(settings.get_player_settings(player)["alerts-blacklist-types"].value),
            blacklist_names = parse_list(settings.get_player_settings(player)["alerts-blacklist-name"].value)
        }

        for _, entity in pairs(tracked_entities) do
            check_entity(entity, player, settings)
        end
    end
end

-- Register events
script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_robot_built_entity, on_built_entity)
script.on_event(defines.events.on_entity_died, on_entity_removed)
script.on_event(defines.events.on_player_mined_entity, on_entity_removed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed)

-- Optional periodic check (reduces `on_tick` usage to once every 600 ticks)
script.on_event(defines.events.on_tick, function(event)
    if event.tick % CHECK_INTERVAL == 0 then
        on_tick_check_entities()
    end
end)
