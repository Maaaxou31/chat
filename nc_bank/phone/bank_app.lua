-- ============================================
-- NorthCounty Bank - Application Téléphone
-- Pour yseries
-- ============================================

return {
    id = "nc_bank",
    name = "Bank",
    icon = "https://cdn-icons-png.flaticon.com/512/2830/2830284.png",
    ui = GetCurrentResourceName() .. "/phone/index.html",

    -- Fonction appelée lors de l'ouverture de l'app
    open = function()
        -- Récupérer les informations du compte
        ESX.TriggerServerCallback('nc_bank:getPhoneAccountInfo', function(data)
            if data then
                SendNUIMessage({
                    app = "nc_bank",
                    action = "openPhoneBank",
                    data = data
                })
            end
        end)
    end,

    -- Fonction appelée lors de la fermeture de l'app
    close = function()
        SendNUIMessage({
            app = "nc_bank",
            action = "closePhoneBank"
        })
    end
}
