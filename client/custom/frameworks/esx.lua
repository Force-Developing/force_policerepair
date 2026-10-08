-- Runs once force_policerepair knows the framework is "esx" (decided by the server). Keep your code inside this function.
RegisterFramework("esx", function()
  local ESX
  local resource = GetFrameworkResource() or "es_extended"
  -- Loaded again when es_extended restarts: the old shared object points at the stopped resource
  LoadFrameworkObject(resource, function()
    return exports[resource]:getSharedObject()
  end, function(obj)
    ESX = obj
  end)

  --- Only used to show or hide repair options; the server checks the job again.
  --- @return table|nil { name, grade, onDuty }
  function GetPlayerJob()
    local data = ESX and ESX.GetPlayerData()
    local job = data and data.job
    if type(job) ~= "table" or type(job.name) ~= "string" then return nil end
    return { name = job.name, grade = tonumber(job.grade) or 0, onDuty = job.onDuty ~= false }
  end
end)
