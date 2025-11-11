-- ============================================
-- NC Bank - Remplacement de l'app Banking yseries
-- Placez ce fichier dans: yseries-apps/banking.lua
-- ============================================

return {
    id = "banking",
    name = "Banque",
    icon = "https://cdn-icons-png.flaticon.com/512/2830/2830284.png",
    ui = "nc_bank/phone/index.html",

    open = function(source)
        -- Déclencher l'ouverture de l'app nc_bank
        TriggerClientEvent('nc_bank:openPhoneApp', source)
    end,

    close = function(source)
        -- Cleanup si nécessaire
    end
}
