-- Runs once force_policerepair knows the framework is "qb" (Config.Framework, or detected by the server).
-- Keep your code inside this function.
RegisterFramework("qb", function()
  local QBCore
  local resource = GetFrameworkResource() or "qb-core"
  -- Loaded again when qb-core restarts: the old core object points at the stopped resource
  LoadFrameworkObject(resource, function()
    return exports[resource]:GetCoreObject()
  end, function(obj)
    QBCore = obj
  end)

  --- @param source number
  --- @return table|nil { name, grade, onDuty }
  function GetPlayerJob(source)
    local player = QBCore and QBCore.Functions.GetPlayer(source)
    local job = player and player.PlayerData and player.PlayerData.job
    if type(job) ~= "table" or type(job.name) ~= "string" then return nil end
    local grade = type(job.grade) == "table" and job.grade.level or job.grade
    return { name = job.name, grade = tonumber(grade) or 0, onDuty = job.onduty ~= false }
  end
end)
