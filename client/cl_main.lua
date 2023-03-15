ESX              = nil
local PlayerData = {}

Citizen.CreateThread(function()
    while ESX == nil do
      TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
      Citizen.Wait(0)
    end
    Citizen.Wait(500)
  
    PlayerData = ESX.GetPlayerData()
  end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)


Citizen.CreateThread(function()
    while true do
		local sleepThread = 850
		local player = PlayerPedId()
		local pCoords = GetEntityCoords(player)
		local dst = #(pCoords - Config.MarkerPos)

		if dst <= 50.0 then
			RequestModel(Config.PedModel) while not HasModelLoaded(Config.PedModel) do Wait(7) end
			if not DoesEntityExist(bussinessPed) then
				bussinessPed = CreatePed(4, Config.PedModel, Config.PedPos, Config.PedHeading, false, true)
				FreezeEntityPosition(bussinessPed, true)
				SetBlockingOfNonTemporaryEvents(bussinessPed, true)
				SetEntityInvincible(bussinessPed, true)
                SetPedCanRagdoll(bussinessPed, false)
			end
		end

        if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
            if dst >= 1.5 and dst <= 6.0 then
                sleepThread = 5
                Funcs.Text3D(Config.MarkerPos, "Reparation")
                DrawMarker(6, Config.MarkerPos.x, Config.MarkerPos.y, Config.MarkerPos.z - 0.985, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 5.0, 5.0, 5.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
            end

            if dst <= 1.5 then
                sleepThread = 5
                Funcs.Text3D(Config.MarkerPos, "[~p~E~s~] Reparation")
                DrawMarker(6, Config.MarkerPos.x, Config.MarkerPos.y, Config.MarkerPos.z - 0.985, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 5.0, 5.0, 5.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)

                if IsControlJustPressed(1, 38) then
                    if IsPedInAnyVehicle(player, false) then
                        ESX.TriggerServerCallback("force_policerepair:GetPlayerInfo", function(response)
                            SendNUIMessage({
                                action = "OpenRepairMenu",
                                data = {
                                    playerName = response.firstname .. " " .. response.lastname
                                }
                            })
                        end)
                    else
                        ESX.ShowNotification("Du måste sitta i en polis bil!")
                    end
                end
            end
        end

		Wait(sleepThread)
	end
end)

