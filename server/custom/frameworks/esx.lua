-- Runs once force_policerepair knows the framework is "esx" (Config.Framework, or detected by the server).
-- Keep your code inside this function.
RegisterFramework("esx", function()
  local ESX
  local resource = GetFrameworkResource() or "es_extended"
  -- Loaded again when es_extended restarts: the old shared object points at the stopped resource
  LoadFrameworkObject(resource, function()
    return exports[resource]:getSharedObject()
  end, function(obj)
    ESX = obj
  end)

  --- @param source number
  --- @return table|nil { name, grade, onDuty }
  function GetPlayerJob(source)
    local xPlayer = ESX and ESX.GetPlayerFromId(source)
    local job = xPlayer and xPlayer.job
    if type(job) ~= "table" or type(job.name) ~= "string" then return nil end
    -- ESX has no duty state by default; newer versions with job.onDuty are respected
    return { name = job.name, grade = tonumber(job.grade) or 0, onDuty = job.onDuty ~= false }
  end
end)
