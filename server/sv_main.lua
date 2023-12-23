local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('tac-vending:server:givemoney', function()
    local money = math.random(Config.VendingJob.Cash[1], Config.VendingJob.Cash[2])
	local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.AddMoney("bank", money)
end)