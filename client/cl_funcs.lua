Funcs = {};

Funcs.Text3D = function(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    
    SetTextScale(0.38, 0.38)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 200)
    SetTextEntry("STRING")
    SetTextCentre(1)

    AddTextComponentString(text)
    DrawText(_x, _y)

    local factor = string.len(text) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

Funcs.RepairVehicle = function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)

    SetVehicleDoorOpen(vehicle, 4, false, true)

    SetEntityCoords(vehicle, Config.MarkerPos)
    SetEntityHeading(vehicle, Config.MarkerHeading)

    TaskGoStraightToCoord(bussinessPed, Config.PedRepairPos, 1.0, 1.0, Config.PedRepairHeading, 1.0)
    FreezeEntityPosition(bussinessPed, false)

    TaskLeaveVehicle(player, vehicle, 0)
    SetVehicleDoorsLocked(vehicle, 2)
    FreezeEntityPosition(vehicle, true)

    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do
        Citizen.Wait(0)
    end

    Wait(3000)

    exports["btrp_progressbar"]:StartDelayedFunction({
        ["text"] = "Lagar fordon...",
        ["delay"] = 20000
    })

    SetEntityCoords(bussinessPed, Config.PedRepairPos)
    SetEntityHeading(bussinessPed, Config.PedRepairHeading)

    TaskPlayAnim(bussinessPed, "mini@repair" ,"fixing_a_ped" ,8.0, -8.0, -1, 1, 0, false, false, false )
    FreezeEntityPosition(bussinessPed, true)

    Wait(20000)

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle,  true,  true)
    FreezeEntityPosition(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)

    FreezeEntityPosition(bussinessPed, false)
    TaskGoStraightToCoord(bussinessPed, Config.PedPos, 1.0, 1.0, Config.PedHeading, 1.0)

    Wait(3000)

    FreezeEntityPosition(bussinessPed, true)
    SetEntityCoords(bussinessPed, Config.PedPos)
    SetEntityHeading(bussinessPed, Config.PedHeading)
end

Funcs.CheckEngine = function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)

    SendNUIMessage({
        action = "GetEngineHealth",
        data = {
            EngineHealth = math.floor(GetVehicleEngineHealth(vehicle) / 10) .. "%"
        }
    })
end