local RESOURCE = GetCurrentResourceName()
local MENU_ID = RESOURCE .. ":menu"
local CALLBACK_TIMEOUT = 15000
local PED_DISTANCE = 60.0
local MARKER_DISTANCE = 15.0
local WALK_TIMEOUT = 6000
local KEY_E = 38
local HOOD = 4
local ANIM_DICT, ANIM_NAME = "mini@repair", "fixing_a_ped"

local peds = {}        -- [point id] = mechanic ped handle
local pedWanted = {}   -- [point id] = true while the player is near the ped
local points = {}      -- lib.points
local oxZones = {}     -- ox_target zone ids
local qbZones = {}     -- qb-target zone names
local shownText = nil  -- key of the text UI this resource shows
local repairing = nil  -- { point = table, vehicle = handle } while a repair runs
local lastKeyPress = 0

local function notify(message, notifyType)
  lib.notify({ description = message, type = notifyType or "inform" })
end

local function showText(key, text)
  if shownText == key then return end
  lib.showTextUI(text)
  shownText = key
end

local function hideText(key)
  if not shownText or (key and shownText ~= key) then return end
  lib.hideTextUI()
  shownText = nil
end

local function canUse(point)
  return CanUsePoint(point, GetPlayerJob())
end

--- The vehicle the player drives, or nil
local function driverVehicle()
  local vehicle = cache.vehicle
  if not vehicle or vehicle == 0 or cache.seat ~= -1 or not DoesEntityExist(vehicle) then return nil end
  return vehicle
end

local function inBay(point, vehicle)
  local c = point.coords
  return #(GetEntityCoords(vehicle) - vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0)) <= point.radius + 1.0
end

--- lib.callback with its own timeout (ox_lib waits 5 minutes and throws). Returns nil when the server didn't answer.
local function awaitServer(name, ...)
  local p = promise.new()
  local settled = false
  local function settle(value)
    if settled then return end
    settled = true
    p:resolve(value)
  end
  lib.callback(name, false, function(...)
    settle({ n = select("#", ...), ... })
  end, ...)
  SetTimeout(CALLBACK_TIMEOUT, function() settle(false) end)
  local result = Citizen.Await(p)
  if not result then return nil end
  return table.unpack(result, 1, result.n)
end

-------------------------------------------------------------------------------------------------------------------
-- Mechanic ped
-------------------------------------------------------------------------------------------------------------------

local function deletePed(id)
  local ped = peds[id]
  peds[id] = nil
  if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
end

local function spawnPed(point)
  local id = point.id
  if peds[id] and DoesEntityExist(peds[id]) then return end
  local model = joaat(point.ped.model)
  local ok, err = pcall(lib.requestModel, model, 10000)
  if not ok then
    Debug("error", "Repair point '%s': ped model '%s' could not be loaded: %s", id, tostring(point.ped.model), tostring(err))
    return
  end
  -- The player may have walked away while the model loaded
  if not pedWanted[id] or (peds[id] and DoesEntityExist(peds[id])) then
    SetModelAsNoLongerNeeded(model)
    return
  end
  local c = point.ped.coords
  local ped = CreatePed(4, model, c.x + 0.0, c.y + 0.0, c.z + 0.0, point.ped.heading, false, false)
  SetModelAsNoLongerNeeded(model)
  FreezeEntityPosition(ped, true)
  SetEntityInvincible(ped, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetPedCanRagdoll(ped, false)
  peds[id] = ped
end

--- Walks the ped to coords (gives up after WALK_TIMEOUT) and freezes it there
local function walkPed(ped, coords, heading, keepGoing)
  if not ped or not DoesEntityExist(ped) then return end
  ClearPedTasks(ped)
  FreezeEntityPosition(ped, false)
  TaskGoStraightToCoord(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, 1.0, WALK_TIMEOUT, heading, 0.2)
  local deadline = GetGameTimer() + WALK_TIMEOUT
  while DoesEntityExist(ped) and GetGameTimer() < deadline and keepGoing() do
    local pos = GetEntityCoords(ped)
    if math.abs(pos.x - coords.x) < 0.5 and math.abs(pos.y - coords.y) < 0.5 then break end
    Wait(100)
  end
  if not DoesEntityExist(ped) then return end
  SetEntityHeading(ped, heading)
  FreezeEntityPosition(ped, true)
end

local function pedStartWork(point, job)
  local ped = peds[point.id]
  local work = point.ped and point.ped.workCoords
  if not work or not ped then return end
  walkPed(ped, work, point.ped.workHeading, function() return repairing == job end)
  if repairing ~= job or not DoesEntityExist(ped) then return end
  local ok, err = pcall(lib.requestAnimDict, ANIM_DICT, 5000)
  if not ok then return Debug("error", "Repair animation could not be loaded: %s", tostring(err)) end
  TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 8.0, -8.0, -1, 1, 0, false, false, false)
  RemoveAnimDict(ANIM_DICT)
end

local function pedBackToPost(point)
  local ped = peds[point.id]
  if not point.ped or not ped or not DoesEntityExist(ped) then return end
  ClearPedTasks(ped)
  if not point.ped.workCoords then return end
  CreateThread(function()
    walkPed(ped, point.ped.coords, point.ped.heading, function() return repairing == nil end)
  end)
end

-------------------------------------------------------------------------------------------------------------------
-- Repair
-------------------------------------------------------------------------------------------------------------------

--- Lines the vehicle up in the bay, turns the engine off, freezes it and opens the hood
local function prepareVehicle(point, vehicle)
  if Config.SnapVehicle then
    local c = point.coords
    SetEntityCoords(vehicle, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false)
    if point.heading then SetEntityHeading(vehicle, point.heading) end
    SetVehicleOnGroundProperly(vehicle)
  end
  -- auto-start stays enabled, so throttle starts the engine again if the repair is cancelled
  SetVehicleEngineOn(vehicle, false, true, false)
  FreezeEntityPosition(vehicle, true)
  SetVehicleDoorOpen(vehicle, HOOD, false, false)
end

--- Undoes prepareVehicle and sends the mechanic back. Safe to call more than once.
local function exitRepair()
  local job = repairing
  if not job then return end
  repairing = nil
  local vehicle = job.vehicle
  if vehicle and DoesEntityExist(vehicle) then
    FreezeEntityPosition(vehicle, false)
    SetVehicleDoorShut(vehicle, HOOD, false)
  end
  pedBackToPost(job.point)
end

local function takeControl(vehicle)
  if NetworkHasControlOfEntity(vehicle) then return true end
  local deadline = GetGameTimer() + 2000
  while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < deadline do
    NetworkRequestControlOfEntity(vehicle)
    Wait(50)
  end
  return NetworkHasControlOfEntity(vehicle)
end

local function fixVehicle(vehicle)
  if not DoesEntityExist(vehicle) then return end
  if not takeControl(vehicle) then Debug("warn", "No network control of the vehicle, the repair may not sync") end
  SetVehicleFixed(vehicle)
  SetVehicleDeformationFixed(vehicle)
  SetVehicleEngineHealth(vehicle, 1000.0)
  SetVehicleBodyHealth(vehicle, 1000.0)
  SetVehiclePetrolTankHealth(vehicle, 1000.0)
  SetVehicleUndriveable(vehicle, false)
  SetVehicleEngineOn(vehicle, true, true, false)
end

--- Repairs the vehicle the player drives at a bay. The server checks the job, seat, distance, time and cooldown.
--- @param pointId string
function RepairVehicle(pointId)
  local point = GetPoint(pointId)
  if not point then return end
  if repairing then return notify(locale("busy"), "error") end
  if not canUse(point) then return notify(locale("not_allowed"), "error") end
  local vehicle = driverVehicle()
  if not vehicle or not NetworkGetEntityIsNetworked(vehicle) then return notify(locale("no_vehicle"), "error") end
  if not inBay(point, vehicle) then return notify(locale("too_far"), "error") end

  local netId = VehToNet(vehicle)
  local job = { point = point, vehicle = vehicle }
  repairing = job
  local ok, success, result = pcall(awaitServer, RESOURCE .. ":server:start", point.id, netId)
  if not ok or success == nil then
    repairing = nil
    if not ok then Debug("error", "Starting a repair failed: %s", tostring(success)) end
    return notify(locale("server_no_response"), "error")
  end
  if not success then
    repairing = nil
    return notify(locale(type(result) == "string" and result or "repair_failed"), "error")
  end

  local finished = false
  local okRun, err = pcall(function()
    prepareVehicle(point, vehicle)
    CreateThread(function() pedStartWork(point, job) end)
    finished = lib.progressBar({
      duration = tonumber(result) or GetRepairDuration(),
      label = locale("repairing"),
      useWhileDead = false,
      canCancel = true,
      disable = { move = true, car = true, combat = true },
    })
  end)
  if not okRun then Debug("error", "Repair failed: %s", tostring(err)) end
  -- the resource was stopped, or something else ended the repair
  if repairing ~= job then return end

  if not finished then
    TriggerServerEvent(RESOURCE .. ":server:cancel")
    exitRepair()
    return notify(locale("cancelled"), "error")
  end

  local okFinish, done, reason = pcall(awaitServer, RESOURCE .. ":server:finish", netId)
  if okFinish and done then
    fixVehicle(vehicle)
    exitRepair()
    return notify(locale("repaired"), "success")
  end
  exitRepair()
  if not okFinish or done == nil then return notify(locale("server_no_response"), "error") end
  notify(locale(type(reason) == "string" and reason or "repair_failed"), "error")
end

local function showCondition(vehicle)
  if not vehicle or not DoesEntityExist(vehicle) then return notify(locale("no_vehicle"), "error") end
  local engine = math.max(0, math.floor((GetVehicleEngineHealth(vehicle) or 0) / 10))
  local body = math.max(0, math.floor((GetVehicleBodyHealth(vehicle) or 0) / 10))
  notify(locale("condition", engine, body))
end

--- Opens the repair menu of a bay (the player has to drive a vehicle inside it)
--- @param pointId string
function OpenRepairMenu(pointId)
  local point = GetPoint(pointId)
  if not point then return end
  if repairing then return notify(locale("busy"), "error") end
  if not canUse(point) then return notify(locale("not_allowed"), "error") end
  local vehicle = driverVehicle()
  if not vehicle then return notify(locale("no_vehicle"), "error") end
  if not inBay(point, vehicle) then return notify(locale("too_far"), "error") end

  lib.registerContext({
    id = MENU_ID,
    title = point.label,
    options = {
      {
        title = locale("menu_repair"),
        description = locale("menu_repair_description", math.floor(GetRepairDuration() / 1000)),
        icon = "wrench",
        -- its own thread: the repair awaits the server and a progress bar
        onSelect = function() CreateThread(function() RepairVehicle(pointId) end) end,
      },
      {
        title = locale("menu_condition"),
        description = locale("menu_condition_description"),
        icon = "gauge",
        onSelect = function() showCondition(driverVehicle()) end,
      },
    },
  })
  lib.showContext(MENU_ID)
end

-------------------------------------------------------------------------------------------------------------------
-- World: ped, markers, target zones / [E] points
-------------------------------------------------------------------------------------------------------------------

local function drawMarker(coords, size, r, g, b)
  DrawMarker(1, coords.x, coords.y, coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size, size, 0.6, r, g, b, 90,
    false, false, 2, false, nil, nil, false)
end

local function addTarget(point)
  local target = GetTargetSystem()
  local name = ("%s:%s"):format(RESOURCE, point.id)
  local coords = vector3(point.coords.x + 0.0, point.coords.y + 0.0, point.coords.z + 0.0)
  local function canInteract() return not repairing and driverVehicle() ~= nil and canUse(point) end
  local function open() OpenRepairMenu(point.id) end

  if target == "ox_target" then
    oxZones[#oxZones + 1] = exports.ox_target:addSphereZone({
      coords = coords,
      radius = point.radius,
      options = { {
        name = name, icon = "fa-solid fa-wrench", label = locale("open_menu"), distance = point.radius + 2.0,
        canInteract = canInteract, onSelect = open,
      } },
    })
  elseif target == "qb-target" then
    exports["qb-target"]:AddCircleZone(name, coords, point.radius, { name = name, debugPoly = false, useZ = true }, {
      options = { { icon = "fas fa-wrench", label = locale("open_menu"), canInteract = canInteract, action = open } },
      distance = point.radius + 2.0,
    })
    qbZones[#qbZones + 1] = name
  end
end

local function addTargets()
  oxZones, qbZones = {}, {}
  for _, point in pairs(Config.Points) do
    local ok, err = pcall(addTarget, point)
    if not ok then Log("error", ("Repair point '%s': adding the target zone failed: %s"):format(point.id, tostring(err))) end
  end
end

local function setupPoint(point)
  local id = point.id

  if point.ped then
    points[#points + 1] = lib.points.new({
      coords = vector3(point.ped.coords.x + 0.0, point.ped.coords.y + 0.0, point.ped.coords.z + 0.0),
      distance = PED_DISTANCE,
      onEnter = function()
        pedWanted[id] = true
        -- loading the model yields; don't block the points loop
        CreateThread(function() spawnPed(point) end)
      end,
      onExit = function()
        pedWanted[id] = false
        deletePed(id)
      end,
    })
  end

  local hasTarget = GetTargetSystem() ~= "none"
  local textKey = "repair:" .. id
  points[#points + 1] = lib.points.new({
    coords = vector3(point.coords.x + 0.0, point.coords.y + 0.0, point.coords.z + 0.0),
    distance = math.max(point.radius, MARKER_DISTANCE),
    nearby = function(p)
      if repairing or lib.getOpenContextMenu() or not canUse(point) then return hideText(textKey) end
      local inside = p.currentDistance <= point.radius
      if Config.DrawMarkers then
        if inside then drawMarker(point.coords, point.radius * 2.0, 60, 200, 90)
        else drawMarker(point.coords, point.radius * 2.0, 40, 120, 255) end
      end
      if hasTarget then return end
      if not inside or not driverVehicle() then return hideText(textKey) end
      showText(textKey, locale("open_menu_textui"))
      if IsControlJustReleased(0, KEY_E) and GetGameTimer() - lastKeyPress > 500 then
        lastKeyPress = GetGameTimer()
        hideText(textKey)
        OpenRepairMenu(id)
      end
    end,
    onExit = function() hideText(textKey) end,
  })
end

exports("openRepairMenu", OpenRepairMenu)

local targetsAdded = false

OnEnvironmentReady(function()
  for _, point in pairs(Config.Points) do
    local ok, err = pcall(setupPoint, point)
    if not ok then Log("error", ("Repair point '%s' could not be set up: %s"):format(tostring(point.id), tostring(err))) end
  end

  local target = GetTargetSystem()
  if target == "none" then return end
  -- The client starts resources in server.cfg order: a target ensured after this resource isn't running here yet
  CreateThread(function()
    local nextWarning = GetGameTimer() + 10000
    while GetResourceState(target) ~= "started" do
      Wait(250)
      if GetGameTimer() >= nextWarning then
        Log("warn", ("Still waiting for %s to start on this client."):format(target))
        nextWarning = GetGameTimer() + 10000
      end
    end
    if targetsAdded then return end
    targetsAdded = true
    addTargets()
    Debug("info", "Repair target zones added (%s)", target)
  end)
end)

-- A restarted target resource has forgotten our zones
AddEventHandler("onClientResourceStart", function(resource)
  if not targetsAdded or resource ~= GetTargetSystem() then return end
  addTargets()
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= RESOURCE then return end
  hideText()
  if lib.getOpenContextMenu() == MENU_ID then lib.hideContext() end
  -- the progress bar runs in ox_lib and would keep the controls disabled
  if repairing then pcall(lib.cancelProgress) end
  exitRepair()
  for id in pairs(peds) do deletePed(id) end
  for _, point in ipairs(points) do point:remove() end
  -- the target resources may be stopped already; nothing to clean up then
  for _, zone in ipairs(oxZones) do pcall(function() exports.ox_target:removeZone(zone) end) end
  for _, name in ipairs(qbZones) do pcall(function() exports["qb-target"]:RemoveZone(name) end) end
end)
