local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('tac-vending:server:givemoney', function()
    local money = math.random(450, 600)
	local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.AddMoney("bank", money)
end)