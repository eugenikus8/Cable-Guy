-- Define constants
local CHECK_INTERVAL = 600

-- Convert string settings to tables for white/black lists
local function parse_list(setting)
   local values = {}
   for value in setting:gmatch("([^,]+)") do
      values[value:match("^%s*(.-)%s*$")] = true
   end
   return values
end

-- Main alert checking function
local function on_tick(event)
   if event.tick % CHECK_INTERVAL ~= 0 then return end

   for _, player in pairs(game.connected_players) do
        -- Initialize settings for each player
      local globsettings = {
         alerts_all_consume_prototypes = settings.get_player_settings(player)["alerts-all-consume-prototypes"].value,
         alerts_all_generic_prototypes = settings.get_player_settings(player)["alerts-all-generic-prototypes"].value,
         alerts_whitelist_types = settings.get_player_settings(player)["alerts-whitelist-types"].value,
         alerts_whitelist_name = settings.get_player_settings(player)["alerts-whitelist-name"].value,
         alerts_blacklist_types = settings.get_player_settings(player)["alerts-blacklist-types"].value,
         alerts_blacklist_name = settings.get_player_settings(player)["alerts-blacklist-name"].value,
         alerts_surface = settings.get_player_settings(player)["alerts-surface"].value
         }

      -- Parse whitelist and blacklist settings
      local whitelist_types = parse_list(globsettings.alerts_whitelist_types)
      local whitelist_names = parse_list(globsettings.alerts_whitelist_name)
      local blacklist_types = parse_list(globsettings.alerts_blacklist_types)
      local blacklist_names = parse_list(globsettings.alerts_blacklist_name)

      local alerts = {["alerts.low-power"] = {}, ["alerts.not-connected"] = {}}

        -- Determine surfaces to check
      local surfaces_to_check
      if globsettings.alerts_surface == "alerts-surface-all-surfaces" then
         surfaces_to_check = game.surfaces
      else
         surfaces_to_check = {player.surface}
      end

      -- Iterate through specified surfaces
      for _, surface in pairs(surfaces_to_check) do
         for _, entity in pairs(surface.find_entities_filtered({force = player.force})) do
            local energy_source = entity.prototype and entity.prototype.electric_energy_source_prototype
            local is_entity_in_blacklist = blacklist_types[entity.type] or blacklist_names[entity.name]

            local status = entity.status

            local full = entity.status.defines.entity_status.fully_charged
            local normal = entity.status.defines.entity_status.normal

                -- Alert for consuming prototypes (low power)
               if globsettings.alerts_all_consume_prototypes
               and not is_entity_in_blacklist then
                  if energy_source
                     and (energy_source.usage_priority == "primary-input"
                        or energy_source.usage_priority == "secondary-input"
                        or energy_source.usage_priority == "lamp")
                     and status == defines.entity_status.no_power
                     then
                        table.insert(alerts["alerts.low-power"], {entity = entity, message = {"alerts.low-power"}})
                  end

                  else if (whitelist_types[entity.type] or whitelist_names[entity.name])
                  and not is_entity_in_blacklist then
                  if energy_source
                     and (energy_source.usage_priority == "primary-input"
                        or energy_source.usage_priority == "secondary-input"
                        or energy_source.usage_priority == "lamp")
                     and status == defines.entity_status.no_power
                     then
                        table.insert(alerts["alerts.low-power"], {entity = entity, message = {"alerts.low-power"}})
                     end
                  end
               end

                -- Alert for generating prototypes
               if globsettings.alerts_all_generic_prototypes
               and not is_entity_in_blacklist then
                  if energy_source
                     and (energy_source.usage_priority == "primary-output"
                        or energy_source.usage_priority == "secondary-output"
                        or energy_source.usage_priority == "tertiary"
                        or energy_source.usage_priority == "solar"
                        or entity.type == "accumulator"
                        or entity.type == "generator"
                        or entity.type == "electric-energy-interface")
                     and (status == defines.entity_status.not_plugged_in_electric_network
                        or status == defines.entity_status.no_input_fluid
                        or status == defines.entity_status.no_power
                        or status == defines.entity_status.low_power)
                     then
                        table.insert(alerts["alerts.not-connected"], {entity = entity, message = {"alerts.not-connected", {"entity-name." .. entity.name}}})
                  end

                  else if (whitelist_types[entity.type] or whitelist_names[entity.name])
                  and not is_entity_in_blacklist then
                  if energy_source
                     and (energy_source.usage_priority == "primary-output"
                        or energy_source.usage_priority == "secondary-output"
                        or energy_source.usage_priority == "tertiary"
                        or energy_source.usage_priority == "solar"
                        or entity.type == "accumulator"
                        or entity.type == "generator"
                        or entity.type == "electric-energy-interface")
                     and (status == defines.entity_status.not_plugged_in_electric_network
                        or status == defines.entity_status.no_input_fluid
                        or status == defines.entity_status.no_power
                        or status == defines.entity_status.low_power)
                     then
                        table.insert(alerts["alerts.not-connected"], {entity = entity, message = {"alerts.not-connected", {"entity-name." .. entity.name}}})
                     end
                  end
               end
            end
         end

        -- Display alerts for the player
        for status, alerts_list in pairs(alerts) do
            for _, alert in pairs(alerts_list) do
                player.add_custom_alert(alert.entity, {type = "entity", name = alert.entity.name}, alert.message, true)
            end
        end
    end
end

script.on_event(defines.events.on_tick, on_tick)
