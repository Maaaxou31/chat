local Locale = Locales['fr']
local isUIOpen = false

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

    ESX.TriggerServerCallback('nc_bank:getFullAccountInfo', function(data)
        if data then
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openBank',
                data = data
            })
            isUIOpen = true
        end
    end)
end

-- Event pour ouvrir l'UI depuis le serveur
RegisterNetEvent('nc_bank:openUI', function()
    OpenBankUI()
end)

-- Event pour rafraîchir l'UI
RegisterNetEvent('nc_bank:refreshUI', function()
    if isUIOpen then
        SendNUIMessage({
            action = 'refreshUI'
        })
    end
end)

-- ============================================
-- NUI CALLBACKS
-- ============================================

-- Fermer l'interface
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    cb('ok')
end)

-- Récupérer les informations complètes (pour refresh)
RegisterNUICallback('getFullAccountInfo', function(data, cb)
    ESX.TriggerServerCallback('nc_bank:getFullAccountInfo', function(accountData)
        cb(accountData)
    end)
end)

-- Dépôt
RegisterNUICallback('deposit', function(data, cb)
    local amount = tonumber(data.amount)
    local accountId = tonumber(data.accountId)

    if amount and amount > 0 and accountId then
        TriggerServerEvent('nc_bank:deposit', accountId, amount)
    end
    cb('ok')
end)

-- Retrait
RegisterNUICallback('withdraw', function(data, cb)
    local amount = tonumber(data.amount)
    local accountId = tonumber(data.accountId)

    if amount and amount > 0 and accountId then
        TriggerServerEvent('nc_bank:withdraw', accountId, amount)
    end
    cb('ok')
end)

-- Virement
RegisterNUICallback('transfer', function(data, cb)
    local amount = tonumber(data.amount)
    local accountId = tonumber(data.accountId)
    local targetIban = data.targetIban

    if amount and amount > 0 and accountId and targetIban then
        TriggerServerEvent('nc_bank:transfer', accountId, targetIban, amount)
    end
    cb('ok')
end)

-- Changer le code PIN
RegisterNUICallback('changePIN', function(data, cb)
    local accountId = tonumber(data.accountId)
    local oldPIN = data.oldPIN
    local newPIN = data.newPIN

    if accountId and oldPIN and newPIN then
        TriggerServerEvent('nc_bank:changePIN', accountId, oldPIN, newPIN)
    end
    cb('ok')
end)

-- Synchroniser les employés
RegisterNUICallback('syncEmployees', function(data, cb)
    local accountId = tonumber(data.accountId)

    if accountId then
        TriggerServerEvent('nc_bank:syncBusinessEmployees', accountId)
    end
    cb('ok')
end)

-- Payer un salaire
RegisterNUICallback('paySalary', function(data, cb)
    local accountId = tonumber(data.accountId)
    local employeeId = tonumber(data.employeeId)

    if accountId and employeeId then
        TriggerServerEvent('nc_bank:paySalary', accountId, employeeId)
    end
    cb('ok')
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
