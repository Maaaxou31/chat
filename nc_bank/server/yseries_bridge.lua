-- ============================================
-- NC Bank - Bridge pour yseries
-- Remplace les callbacks bancaires de yseries
-- ============================================

-- Si ox_lib est disponible pour yseries
if GetResourceState('ox_lib') == 'started' then
    local lib = exports.ox_lib

    -- Callback: Récupérer le solde
    lib:callback('yseries:server:banking:get-balance', function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return 0 end

        local accounts = GetPlayerAccounts(xPlayer.identifier)
        local personalAccount = nil

        for _, account in pairs(accounts) do
            if account.account_type == 'personal' then
                personalAccount = account
                break
            end
        end

        return personalAccount and personalAccount.balance or 0
    end)

    -- Callback: Dépôt (désactivé - utiliser nc_bank à la place)
    lib:callback('yseries:server:banking:deposit', function(source, amount)
        return false, 'Utilisez l\'application NC Bank pour les dépôts'
    end)

    -- Callback: Retrait (désactivé - utiliser nc_bank à la place)
    lib:callback('yseries:server:banking:withdraw', function(source, amount)
        return false, 'Utilisez l\'application NC Bank pour les retraits'
    end)

    print('^2[NC_BANK]^7 Bridge yseries chargé avec succès!')
else
    print('^3[NC_BANK]^7 ox_lib non trouvé - bridge yseries non chargé')
end
