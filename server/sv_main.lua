ESX = nil 

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj  
end)  

ESX.RegisterServerCallback("force_policerepair:GetPlayerInfo", function(source, cb)
    local player = ESX.GetPlayerFromId(source)

    MySQL.Async.fetchAll("SELECT * FROM characters WHERE id = @id", {
        ['@id'] = player.characterId
    }, function(response)
        if response[1] then
            cb(response[1])
        else
            cb(false)
        end
    end)
end)