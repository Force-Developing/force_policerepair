-- Runs once force_policerepair knows the framework is "qb" (decided by the server). Keep your code inside this function.
RegisterFramework("qb", function()
  local QBCore
  local resource = GetFrameworkResource() or "qb-core"
  -- Loaded again when qb-core restarts: the old core object points at the stopped resource
  LoadFrameworkObject(resource, function()
    return exports[resource]:GetCoreObject()
  end, function(obj)
    QBCore = obj
  end)

  --- Only used to show or hide repair options; the server checks the job again.
  --- @return table|nil { name, grade, onDuty }
  function GetPlayerJob()
    local data = QBCore and QBCore.Functions.GetPlayerData()
    local job = data and data.job
    if type(job) ~= "table" or type(job.name) ~= "string" then return nil end
    local grade = type(job.grade) == "table" and job.grade.level or job.grade
    return { name = job.name, grade = tonumber(grade) or 0, onDuty = job.onduty ~= false }
  end
end)
