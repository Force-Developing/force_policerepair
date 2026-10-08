-- Runs once force_policerepair knows the framework is "qbx" (decided by the server). Keep your code inside this function.
RegisterFramework("qbx", function()
  -- Kept up to date by qbx_core's events, so canInteract checks don't call an export every frame
  local playerData = {}

  local function refresh()
    if GetResourceState("qbx_core") ~= "started" then return end
    local ok, data = pcall(function() return exports.qbx_core:GetPlayerData() end)
    if ok and type(data) == "table" then playerData = data end
  end

  refresh()
  RegisterNetEvent("QBCore:Player:SetPlayerData", function(data)
    if type(data) == "table" then playerData = data end
  end)
  RegisterNetEvent("QBCore:Client:OnPlayerLoaded", refresh)
  RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
    if type(job) == "table" then playerData.job = job end
  end)
  RegisterNetEvent("QBCore:Client:OnPlayerUnload", function() playerData = {} end)
  AddEventHandler("onClientResourceStart", function(resource)
    if resource == "qbx_core" then refresh() end
  end)

  --- Only used to show or hide repair options; the server checks the job again.
  --- @return table|nil { name, grade, onDuty }
  function GetPlayerJob()
    local job = playerData.job
    if type(job) ~= "table" or type(job.name) ~= "string" then return nil end
    local grade = type(job.grade) == "table" and job.grade.level or job.grade
    return { name = job.name, grade = tonumber(grade) or 0, onDuty = job.onduty ~= false }
  end
end)
