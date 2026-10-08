Config = {}

-- Prints extra info to the F8 / server console. Setup errors are always printed.
Config.Debug = false

-- "en", "sv" or "auto" (follows the replicated ox:locale convar: setr ox:locale "sv")
Config.Locale = "en"

-- "auto" (detected by the server: qbx_core, es_extended, qb-core), "esx", "qb", "qbx" or "custom"
Config.Framework = "auto"

-- "auto" (ox_target, then qb-target, else [E] + text UI), "ox_target", "qb-target" or "none" ([E] + text UI).
-- The repair menu is used from the driver seat. If your target resource can't be used in a vehicle
-- (qb-target with Config.DisableInVehicle = true), set this to "none".
Config.Target = "auto"

-- Draw a ground marker at the repair bays
Config.DrawMarkers = true

-- QBCore / QBox: the player must be on duty to use a repair bay. ESX has no duty state and ignores this.
Config.RequireDuty = false

-- How long a repair takes, in seconds
Config.RepairDuration = 20

-- Seconds after a finished repair before the same player can start the next one
Config.Cooldown = 30

-- Move the vehicle onto the bay's coords and heading when the repair starts (lines it up with the mechanic)
Config.SnapVehicle = true

--[[
  Repair bays. Each key is the bay id.
  label    = menu title
  jobs     = { [job name] = minimum grade }. Only these jobs can use the bay.
  coords   = vec4 where the vehicle stands during the repair (x, y, z, heading)
  radius   = how close (meters) the vehicle has to be to coords (checked on the server)
  vehicles = optional list of model names that can be repaired here, e.g. { "police", "police2" }.
             Leave it out to allow every vehicle.
  ped      = optional mechanic: { model, coords = vec4 (his post), workCoords = vec4 (where he works on the
             vehicle, optional) }, or false for none
]]
Config.Points = {
    mrpd = {
        label = "Police Repair",
        jobs = { police = 0 },
        coords = vec4(462.45, -1019.23, 28.10, 90.0),
        radius = 3.0,
        ped = {
            model = "s_m_y_xmech_01",
            coords = vec4(458.77, -1017.13, 27.20, 90.0),
            workCoords = vec4(459.62, -1019.36, 27.09, 267.0),
        },
    },
}
