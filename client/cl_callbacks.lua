RegisterNUICallback("NuiToggle", function(state)
    SetNuiFocus(state, state)
end)

RegisterNUICallback("RepairVehicle", function()
    Funcs.RepairVehicle()
end)

RegisterNUICallback("CheckEngine", function()
    Funcs.CheckEngine()
end)