local Locale = Locales['fr']
local nearestATM = nil
local isAtATM = false

-- Thread pour détecter les ATM proches
CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        nearestATM = nil
        local closestDistance = 2.0

        -- Détecter les ATM du jeu
        for _, model in pairs(Config.ATMModels) do
            local atm = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 2.0, model, false, false, false)

            if DoesEntityExist(atm) then
                local atmCoords = GetEntityCoords(atm)
                local distance = #(playerCoords - atmCoords)

                if distance < closestDistance then
                    closestDistance = distance
                    nearestATM = atm
                    wait = 0
                end
            end
        end

        -- Vérifier les ATM personnalisés
        for _, atm in pairs(Config.CustomATMs) do
            local distance = #(playerCoords - atm.coords)

            if distance < closestDistance then
                closestDistance = distance
                nearestATM = atm
                wait = 0
            end
        end

        Wait(wait)
    end
end)

-- Thread pour l'interaction avec les ATM
CreateThread(function()
    while true do
        local wait = 1000

        if nearestATM then
            wait = 0
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            ESX.ShowHelpNotification(Locale['press_to_access_atm'])

            if IsControlJustReleased(0, 38) and not isAtATM then -- E key
                OpenATMMenu()
            end
        end

        Wait(wait)
    end
end)

-- Menu ATM
function OpenATMMenu()
    isAtATM = true

    ESX.TriggerServerCallback('nc_bank:getAccountInfo', function(data)
        if data then
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'atm_menu', {
                title = 'Distributeur Automatique',
                align = 'top-left',
                elements = {
                    {label = '💰 Solde: $' .. ESX.Math.GroupDigits(data.balance), value = 'balance'},
                    {label = '💵 Espèces: $' .. ESX.Math.GroupDigits(data.cash), value = 'cash'},
                    {label = '📥 Déposer', value = 'deposit'},
                    {label = '📤 Retirer', value = 'withdraw'},
                    {label = '🚪 Fermer', value = 'close'}
                }
            }, function(data2, menu)
                if data2.current.value == 'deposit' then
                    menu.close()
                    OpenATMDepositMenu()
                elseif data2.current.value == 'withdraw' then
                    menu.close()
                    OpenATMWithdrawMenu()
                elseif data2.current.value == 'close' then
                    menu.close()
                    isAtATM = false
                end
            end, function(data2, menu)
                menu.close()
                isAtATM = false
            end)
        else
            isAtATM = false
        end
    end)
end

-- Menu de dépôt ATM
function OpenATMDepositMenu()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'atm_deposit', {
        title = 'Montant à déposer (max: $' .. ESX.Math.GroupDigits(Config.ATMDepositLimit) .. ')'
    }, function(data, menu)
        local amount = tonumber(data.value)

        if amount == nil or amount <= 0 then
            ESX.ShowNotification(Locale['amount_invalid'])
        else
            menu.close()
            TriggerServerEvent('nc_bank:atmDeposit', amount)
            isAtATM = false
        end
    end, function(data, menu)
        menu.close()
        isAtATM = false
    end)
end

-- Menu de retrait ATM
function OpenATMWithdrawMenu()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'atm_withdraw', {
        title = 'Montant à retirer (max: $' .. ESX.Math.GroupDigits(Config.ATMWithdrawLimit) .. ')'
    }, function(data, menu)
        local amount = tonumber(data.value)

        if amount == nil or amount <= 0 then
            ESX.ShowNotification(Locale['amount_invalid'])
        else
            menu.close()
            TriggerServerEvent('nc_bank:atmWithdraw', amount)
            isAtATM = false
        end
    end, function(data, menu)
        menu.close()
        isAtATM = false
    end)
end

-- Export
exports('OpenATM', OpenATMMenu)
