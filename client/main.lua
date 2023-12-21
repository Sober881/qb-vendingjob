local QBCore = exports['qb-core']:GetCoreObject()
local Vehicle = nil
local VehicleBlip = nil
local WorkBlip = nil
local JobPed = nil
local JobStart = false
local StartLoading = false
local JobReset = false
local BlipSpawned = false
local LocationChoice = false
local Animation = false
local Location = 1

-- [ Functions ]

function AnimationLoop()
    Animation = true
    CreateThread(function()
        while true do
            Wait(1000)
            if Animation then
                ExecuteCommand('e box')
            end
        end
    end)
end

function SpawnPed()
    if not DoesEntityExist(JobPed) then
        RequestModel(GetHashKey("s_m_m_autoshop_01"))
        while not HasModelLoaded(GetHashKey("s_m_m_autoshop_01")) do
            Wait(0)
        end
        JobPed = CreatePed(4, GetHashKey("s_m_m_autoshop_01"), Config.VendingJob.StartJob, false, false)
        FreezeEntityPosition(JobPed, true)
        TaskSetBlockingOfNonTemporaryEvents(JobPed, true)
        SetEntityInvincible(JobPed, true)
        NPCBlip = AddBlipForCoord(Config.VendingJob.StartJob)
        SetBlipSprite (NPCBlip, 85)
        SetBlipDisplay(NPCBlip, 4)
        SetBlipScale  (NPCBlip, 0.75)
        SetBlipAsShortRange(NPCBlip, true)
        SetBlipColour(NPCBlip, 3)
        AddTextEntry('NPCBlips', Config.Notify.BLIPNAME)
        BeginTextCommandSetBlipName('NPCBlips')
        EndTextCommandSetBlipName(NPCBlip)
    end
end

-- [ Events ]

RegisterNetEvent('tac-vendingjob:client:startjob', function()
    if not JobStart then
        Wait(0)
        for i = #Config.VendingJob.Locations, #Config.VendingJob.Locations, -1 do
            Location = math.random(1, #Config.VendingJob.Locations)
        end

        JobStart = true
        StartLoading = true
        RequestModel(GetHashKey('rumpo'))
        while not HasModelLoaded(GetHashKey('rumpo')) do
            Wait(0)
        end
        Vehicle = CreateVehicle(GetHashKey('rumpo'), Config.VendingJob.VehicleSpawn, true, false)
        SetVehicleLivery(Vehicle, 1)
        SetVehicleDirtLevel(Vehicle, 0.0)
        exports['ps-fuel']:SetFuel(Vehicle, 100)
        local Plate = GetVehicleNumberPlateText(Vehicle)
        VehicleBlip = AddBlipForEntity(Vehicle)
        SetBlipSprite (VehicleBlip, 225)
        SetBlipDisplay(VehicleBlip, 4)
        SetBlipScale  (VehicleBlip, 0.80)
        SetBlipAsShortRange(VehicleBlip, true)
        SetBlipColour(VehicleBlip, 3)
        AddTextEntry('WorkVan', 'Ван')
        BeginTextCommandSetBlipName('WorkVan')
        EndTextCommandSetBlipName(VehicleBlip)
        TriggerEvent("vehiclekeys:client:SetOwner", Plate)
        QBCore.Functions.Notify(Config.Notify.startjob, 'success')
    end
end)

RegisterNetEvent('tac-vendingjob:client:stopjob', function()
    if JobStart then
        Wait(0)
        DeleteVehicle(Vehicle)
        RemoveBlip(WorkBlip)
        JobStart = false
        StartLoading = false
        BlipSpawned = false
        LocationChoice = false
        QBCore.Functions.Notify(Config.Notify.stopjob, 'error')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SpawnPed()
end)

-- [ Threads ]

CreateThread(function()
    while true do
        Wait(0)
        if JobStart then
            if StartLoading then
                if not LocationChoice then
                    LocationChoice = true
                    for i = #Config.VendingJob.Locations, #Config.VendingJob.Locations, -1 do
                        Location = math.random(1, #Config.VendingJob.Locations)
                    end
                end
                local dist = #(GetEntityCoords(PlayerPedId())-vector3(Config.VendingJob.Locations[Location]))

                if not BlipSpawned then
                    BlipSpawned = true
                    WorkBlip = AddBlipForCoord(Config.VendingJob.Locations[Location])
                    SetBlipSprite (WorkBlip, 1)
                    SetBlipDisplay(WorkBlip, 4)
                    SetBlipScale(WorkBlip, 0.80)
                    SetBlipAsShortRange(WorkBlip, true)
                    SetBlipColour(WorkBlip, 1)
                    SetBlipRoute(WorkBlip, true)
                    SetBlipRouteColour(WorkBlip, 1)
                    AddTextEntry('WorkBlips', 'Локация за доставка')
                    BeginTextCommandSetBlipName('WorkBlips')
                    EndTextCommandSetBlipName(WorkBlip)
                end

                if dist <= 0.5 then
                    if JobReset then
                        if GetVehiclePedIsIn(PlayerPedId()) >= 1 then
                            TaskLeaveAnyVehicle(PlayerPedId(), -1)
                            Wait(1500)
                        end
                        AnimationLoop()
                        StartLoading = false
                        JobReset = false
                        LocationChoice = false
                        QBCore.Functions.Progressbar("vendingjob-loading", 'ЗАРЕЖДАНЕ . . .', 10000, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {}, {}, {}, function() -- Done
                            Animation = false
                            ExecuteCommand('e c')
                            TriggerServerEvent('tac-vending:server:givemoney')
                            QBCore.Functions.Notify(Config.Notify.loadmachine, 'inform')
                            RemoveBlip(WorkBlip)
                            QBCore.Functions.Notify(Config.Notify.govan, 'inform')
                        end)
                    end
                end
            end
        end
    end
end)

CreateThread(function() -- Checks if the van is close if not the van disappears and I stop the work
    while true do
        Wait(2500)
        if JobStart then
            local dist2 = #(GetEntityCoords(Vehicle)-GetEntityCoords(PlayerPedId()))
            if dist2 >= 100.0 then
                DeleteVehicle(Vehicle)
                RemoveBlip(WorkBlip)
                JobStart = false
                StartLoading = false
                LocationChoice = false
                BlipSpawned = false
            end
        end
    end
end)

CreateThread(function() -- Checks if the ped got into a car
    while true do
        Wait(0)
        if JobStart then
            local CurrentVehicle = GetVehiclePedIsIn(PlayerPedId())
            if not JobReset then
                if CurrentVehicle == 0 then
                else
                    StartLoading = true
                    JobReset = true
                    BlipSpawned = false
                    RemoveBlip(WorkBlip)
                end
            end
        end
    end
end)

-- [ Exports ]

exports['qb-target']:AddBoxZone("VendingJob-target", vector3(Config.VendingJob.StartJob), 1.45, 1.35, {
	name = "VendingJob-targetNPC",
	heading = 271.37,
	debugPoly = false,
	minZ = Config.VendingJob.StartJob.z-1,
	maxZ = Config.VendingJob.StartJob.z+2,
}, {
	options = {
		{
            type = "client",
            event = "tac-vendingjob:client:startjob",
			icon = "fas fa-sign-in-alt",
			label = "Start Job",
			job = "all",
		},
        {
            type = "client",
            event = "tac-vendingjob:client:stopjob",
			icon = "fas fa-sign-in-alt",
			label = "Stop Job",
			job = "all",
		},
	},
	distance = 2.5
})