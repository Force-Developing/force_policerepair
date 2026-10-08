local RESOURCE = GetCurrentResourceName()
-- Extra meters on top of a bay's radius (the vehicle's position on the server lags a little behind)
local DISTANCE_MARGIN = 2.0
-- A finish request may arrive this much before the repair time is up (network and frame timing)
local FINISH_EARLY_MS = 1500
-- A repair that was never finished or cancelled is forgotten after its duration plus this
local REPAIR_TTL_MS = 60000

local repairs = {}    -- [source] = { point = id, vehicle = entity, netId = number, startedAt = GetGameTimer() }
local lastRepair = {} -- [source] = GetGameTimer() of the last finished repair

local function toVector3(v)
  return vector3(v.x + 0.0, v.y + 0.0, v.z + 0.0)
end

--- @return boolean allowed, string reason
local function checkAccess(source, point)
  if not IsFrameworkReady() then return false, "not_ready" end
  local job = GetPlayerJob(source)
  if not job then return false, "not_allowed" end
  if CanUsePoint(point, job) then return true end
  if Config.RequireDuty and job.onDuty == false and point.jobs[job.name] ~= nil then return false, "not_on_duty" end
  return false, "not_allowed"
end

--- The vehicle behind netId, if the player sits in its driver seat
--- @return number|nil vehicle, string|nil reason
local function driverVehicle(source, netId)
  if type(netId) ~= "number" then return nil, "no_vehicle" end
  local ped = GetPlayerPed(source)
  if not ped or ped == 0 then return nil, "no_vehicle" end
  local vehicle = NetworkGetEntityFromNetworkId(netId)
  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
    return nil, "no_vehicle"
  end
  if GetVehiclePedIsIn(ped, false) ~= vehicle or GetPedInVehicleSeat(vehicle, -1) ~= ped then
    return nil, "no_vehicle"
  end
  return vehicle
end

--- Job, driver seat, vehicle model and distance to the bay
--- @return boolean ok, number|string vehicleOrReason
local function validate(source, point, netId)
  local allowed, reason = checkAccess(source, point)
  if not allowed then return false, reason end
  local vehicle, why = driverVehicle(source, netId)
  if not vehicle then return false, why end
  if point.models and not point.models[ModelKey(GetEntityModel(vehicle))] then return false, "wrong_vehicle" end
  if #(GetEntityCoords(vehicle) - toVector3(point.coords)) > point.radius + DISTANCE_MARGIN then
    return false, "too_far"
  end
  return true, vehicle
end

lib.callback.register(RESOURCE .. ":server:start", function(source, pointId, netId)
  local point = GetPoint(pointId)
  if not point then return false, "not_allowed" end

  local running = repairs[source]
  if running then
    if GetGameTimer() - running.startedAt < GetRepairDuration() + REPAIR_TTL_MS then return false, "busy" end
    repairs[source] = nil
  end
  local cooldown = (tonumber(Config.Cooldown) or 0) * 1000
  if lastRepair[source] and GetGameTimer() - lastRepair[source] < cooldown then return false, "cooldown" end

  local ok, result = validate(source, point, netId)
  if not ok then return false, result end

  repairs[source] = { point = point.id, vehicle = result, netId = netId, startedAt = GetGameTimer() }
  Debug("info", "%s started a repair at %s", GetPlayerName(source), point.id)
  return true, GetRepairDuration()
end)

lib.callback.register(RESOURCE .. ":server:finish", function(source, netId)
  local repair = repairs[source]
  if not repair then return false, "repair_failed" end
  -- One finish per start, whatever the outcome
  repairs[source] = nil

  local elapsed = GetGameTimer() - repair.startedAt
  if netId ~= repair.netId or elapsed < GetRepairDuration() - FINISH_EARLY_MS then return false, "repair_failed" end
  if elapsed > GetRepairDuration() + REPAIR_TTL_MS then return false, "repair_failed" end

  local point = GetPoint(repair.point)
  if not point then return false, "repair_failed" end
  local ok, result = validate(source, point, netId)
  if not ok then return false, result end
  if result ~= repair.vehicle then return false, "no_vehicle" end

  lastRepair[source] = GetGameTimer()
  Debug("info", "%s finished a repair at %s", GetPlayerName(source), point.id)
  return true
end)

RegisterNetEvent(RESOURCE .. ":server:cancel", function()
  local src = source
  repairs[src] = nil
end)

AddEventHandler("playerDropped", function()
  local src = source
  repairs[src] = nil
  lastRepair[src] = nil
end)
