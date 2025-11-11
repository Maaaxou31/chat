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
        if Config.ATMModels then
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
        end

        -- Vérifier les ATM personnalisés (si configurés)
        if Config.CustomATMs then
            for _, atm in pairs(Config.CustomATMs) do
                local distance = #(playerCoords - atm.coords)

                if distance < closestDistance then
                    closestDistance = distance
                    nearestATM = atm
                    wait = 0
                end
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
            ESX.ShowHelpNotification(Locale['press_to_access_atm'])

            if IsControlJustReleased(0, 38) and not isAtATM then -- E key
                isAtATM = true
                OpenBankUI() -- Ouvre la même interface que les banques
                Wait(500)
                isAtATM = false
            end
        end

        Wait(wait)
    end
end)

-- Export
exports('OpenATM', function()
    OpenBankUI()
end)
