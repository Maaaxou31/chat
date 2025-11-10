local Locale = Locales['fr']
local isUIOpen = false
local currentAccount = nil
local currentTransactions = {}
local currentSavings = {}

-- Initialisation ESX
ESX = exports["es_extended"]:getSharedObject()

-- Créer les blips pour les banques
CreateThread(function()
    for _, bank in pairs(Config.Banks) do
        if bank.blip then
            local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipColour(blip, Config.BlipColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(bank.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Thread pour afficher les markers et gérer l'interaction
CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, bank in pairs(Config.Banks) do
            local distance = #(playerCoords - bank.coords)

            if distance < Config.MarkerDistance then
                wait = 0
                DrawMarker(
                    Config.MarkerType,
                    bank.coords.x,
                    bank.coords.y,
                    bank.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.MarkerSize.x,
                    Config.MarkerSize.y,
                    Config.MarkerSize.z,
                    Config.MarkerColor.r,
                    Config.MarkerColor.g,
                    Config.MarkerColor.b,
                    100,
                    false, true, 2, false, nil, nil, false
                )

                if distance < 1.5 then
                    ESX.ShowHelpNotification(Locale['press_to_access'])

                    if IsControlJustReleased(0, 38) then -- E key
                        OpenBankUI()
                    end
                end
            end
        end

        Wait(wait)
    end
end)

-- Ouvrir l'interface de la banque
function OpenBankUI()
    if isUIOpen then return end

    ESX.TriggerServerCallback('nc_bank:getAccountInfo', function(data)
        if data then
            currentAccount = data

            ESX.TriggerServerCallback('nc_bank:getTransactions', function(transactions)
                currentTransactions = transactions

                ESX.TriggerServerCallback('nc_bank:getSavingsAccounts', function(savings)
                    currentSavings = savings

                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = 'openBank',
                        data = {
                            account = currentAccount,
                            transactions = currentTransactions,
                            savings = currentSavings
                        }
                    })
                    isUIOpen = true
                end)
            end)
        end
    end)
end

-- Event pour ouvrir l'UI depuis le serveur
RegisterNetEvent('nc_bank:openUI', function()
    OpenBankUI()
end)

-- Event pour mettre à jour le solde
RegisterNetEvent('nc_bank:updateBalance', function(bankBalance, cash)
    if currentAccount then
        currentAccount.balance = bankBalance
        currentAccount.cash = cash

        if isUIOpen then
            SendNUIMessage({
                action = 'updateBalance',
                balance = bankBalance,
                cash = cash
            })
        end
    end
end)

-- Event pour rafraîchir les comptes d'épargne
RegisterNetEvent('nc_bank:refreshSavings', function()
    ESX.TriggerServerCallback('nc_bank:getSavingsAccounts', function(savings)
        currentSavings = savings

        if isUIOpen then
            SendNUIMessage({
                action = 'updateSavings',
                savings = currentSavings
            })
        end
    end)
end)

-- Callbacks NUI
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    local amount = tonumber(data.amount)
    if amount and amount > 0 then
        TriggerServerEvent('nc_bank:deposit', amount)
    end
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    local amount = tonumber(data.amount)
    if amount and amount > 0 then
        TriggerServerEvent('nc_bank:withdraw', amount)
    end
    cb('ok')
end)

RegisterNUICallback('transfer', function(data, cb)
    local amount = tonumber(data.amount)
    local target = tonumber(data.target)

    if amount and amount > 0 and target then
        TriggerServerEvent('nc_bank:transfer', target, amount)
    end
    cb('ok')
end)

RegisterNUICallback('getOnlinePlayers', function(data, cb)
    ESX.TriggerServerCallback('nc_bank:getOnlinePlayers', function(players)
        cb(players)
    end)
end)

RegisterNUICallback('createSavingsAccount', function(data, cb)
    TriggerServerEvent('nc_bank:createSavingsAccount', data.name)
    cb('ok')
end)

RegisterNUICallback('savingsDeposit', function(data, cb)
    local amount = tonumber(data.amount)
    local accountId = tonumber(data.accountId)

    if amount and amount > 0 and accountId then
        TriggerServerEvent('nc_bank:savingsDeposit', accountId, amount)
    end
    cb('ok')
end)

RegisterNUICallback('savingsWithdraw', function(data, cb)
    local amount = tonumber(data.amount)
    local accountId = tonumber(data.accountId)

    if amount and amount > 0 and accountId then
        TriggerServerEvent('nc_bank:savingsWithdraw', accountId, amount)
    end
    cb('ok')
end)

RegisterNUICallback('deleteSavingsAccount', function(data, cb)
    local accountId = tonumber(data.accountId)

    if accountId then
        TriggerServerEvent('nc_bank:deleteSavingsAccount', accountId)
    end
    cb('ok')
end)

RegisterNUICallback('refreshTransactions', function(data, cb)
    ESX.TriggerServerCallback('nc_bank:getTransactions', function(transactions)
        cb(transactions)
    end)
end)

-- Animation de dépôt/retrait
function PlayBankAnimation()
    local playerPed = PlayerPedId()
    RequestAnimDict(Config.DepositAnimation.dict)
    while not HasAnimDictLoaded(Config.DepositAnimation.dict) do
        Wait(100)
    end
    TaskPlayAnim(playerPed, Config.DepositAnimation.dict, Config.DepositAnimation.anim, 8.0, -8.0, 3000, 0, 0, false, false, false)
end

-- Exports pour d'autres ressources
exports('OpenBank', OpenBankUI)
exports('IsUIOpen', function() return isUIOpen end)
