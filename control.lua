-- Constants
local CHECK_INTERVAL = 600 -- 10 seconds

-- Helpers
local function parse_list(setting)
   local values = {}
   if not setting or setting == "" then return values end
   for value in setting:gmatch("([^,]+)") do
      values[value:match("^%s*(.-)%s*$")] = true
   end
   return values
end

-- Global init
local function init_globals()
   global = global or {}
   global.alerts_state = global.alerts_state or { surface_index = 1 }
end

script.on_init(init_globals)
script.on_configuration_changed(init_globals)

-- Main tick handler
local function on_tick(event)
   if event.tick % CHECK_INTERVAL ~= 0 then return end

   for _, player in pairs(game.connected_players) do
      local psettings = settings.get_player_settings(player)
      -- Initialize settings for each player
      local globsettings = {
         alerts_all_consume_prototypes = psettings["alerts-all-consume-prototypes"].value,
         alerts_all_generic_prototypes = psettings["alerts-all-generic-prototypes"].value,
         alerts_whitelist_types        = psettings["alerts-whitelist-types"].value,
         alerts_whitelist_name         = psettings["alerts-whitelist-name"].value,
         alerts_blacklist_types        = psettings["alerts-blacklist-types"].value,
         alerts_blacklist_name         = psettings["alerts-blacklist-name"].value,
         alerts_surface                = psettings["alerts-surface"].value
   }

      -- Determine surfaces to check
      local surfaces_to_check = {}
      if globsettings.alerts_surface == "alerts-surface-all-surfaces" then
         surfaces_to_check = game.surfaces
      else
         surfaces_to_check = { player.surface }
      end

      -- Parse whitelist and blacklist settings
      local whitelist_types = parse_list(globsettings.alerts_whitelist_types)
      local whitelist_names = parse_list(globsettings.alerts_whitelist_name)
      local blacklist_types = parse_list(globsettings.alerts_blacklist_types)
      local blacklist_names = parse_list(globsettings.alerts_blacklist_name)

      local whitelist_active =
         next(whitelist_types) ~= nil or next(whitelist_names) ~= nil

      local blacklist_active =
         not whitelist_active and
         (next(blacklist_types) ~= nil or next(blacklist_names) ~= nil)

      local function is_allowed(etype, ename)
         if whitelist_active then
            return whitelist_types[etype] or whitelist_names[ename]
         elseif blacklist_active then
            return not (blacklist_types[etype] or blacklist_names[ename])
         end
         return true
      end

      local alerts = {
         ["alerts.low-power"] = {},
         ["alerts.not-connected"] = {}
      }

      -- Iterate through specified surfaces
      for _, surface in pairs(surfaces_to_check) do
         for _, entity in pairs(surface.find_entities_filtered { force = player.force }) do
         local proto = entity.prototype
         local energy = proto and proto.electric_energy_source_prototype
         if not energy then goto continue_entity end
         if entity.is_connected_to_electric_network() then goto continue_entity end

         local etype = entity.type
         local ename = entity.name
         if not is_allowed(etype, ename) then goto continue_entity end

         -- Consumers
         local is_consumer =
            energy.usage_priority == "primary-input" or
            energy.usage_priority == "secondary-input" or
            energy.usage_priority == "lamp"

         if is_consumer then
            if globsettings.alerts_all_consume_prototypes or whitelist_active then
               table.insert(alerts["alerts.low-power"], {
               entity = entity,
               message = {"alerts.low-power"}
               })
            end
         goto continue_entity
         end

         -- Producers
         local is_producer =
            energy.usage_priority == "primary-output" or
            energy.usage_priority == "secondary-output" or
            energy.usage_priority == "tertiary" or
            energy.usage_priority == "solar" or
            etype == "accumulator" or
            etype == "generator" or
            etype == "burner-generator" or
            etype == "electric-energy-interface"

         if is_producer then
            if globsettings.alerts_all_generic_prototypes or whitelist_active then
               table.insert(alerts["alerts.not-connected"], {
               entity = entity,
               message = {"alerts.not-connected", {"entity-name." .. ename}}
               })
            end
         end

         ::continue_entity::
         end
      end

      -- Display alerts for the player
      for _, list in pairs(alerts) do
         for _, alert in pairs(list) do
         player.add_custom_alert(
            alert.entity,
            { type = "entity", name = alert.entity.name },
            alert.message,
            true
         )
         end
      end
   end
end

script.on_event(defines.events.on_tick, on_tick)
