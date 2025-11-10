local Locale = Locales['fr']

-- Initialisation ESX
ESX = exports["es_extended"]:getSharedObject()

-- Fonction pour ajouter une transaction à l'historique
local function AddTransaction(identifier, transactionType, amount, balanceBefore, balanceAfter, receiver, sender, description)
    MySQL.insert('INSERT INTO nc_bank_transactions (identifier, transaction_type, amount, balance_before, balance_after, receiver, sender, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        identifier,
        transactionType,
        amount,
        balanceBefore,
        balanceAfter,
        receiver,
        sender,
        description
    })

    -- Limiter l'historique
    MySQL.query('DELETE FROM nc_bank_transactions WHERE identifier = ? AND id NOT IN (SELECT id FROM (SELECT id FROM nc_bank_transactions WHERE identifier = ? ORDER BY created_at DESC LIMIT ?) AS temp)', {
        identifier,
        identifier,
        Config.MaxTransactionHistory
    })
end

-- Récupérer les informations du compte
ESX.RegisterServerCallback('nc_bank:getAccountInfo', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local data = {
        playerName = xPlayer.getName(),
        balance = xPlayer.getAccount('bank').money,
        cash = xPlayer.getMoney(),
        serverName = Config.ServerName
    }

    cb(data)
end)

-- Récupérer l'historique des transactions
ESX.RegisterServerCallback('nc_bank:getTransactions', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    local transactions = MySQL.query.await('SELECT * FROM nc_bank_transactions WHERE identifier = ? ORDER BY created_at DESC LIMIT ?', {
        xPlayer.identifier,
        Config.MaxTransactionHistory
    })

    cb(transactions or {})
end)

-- Dépôt d'argent
RegisterNetEvent('nc_bank:deposit', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    local playerMoney = xPlayer.getMoney()

    if playerMoney < amount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money'])
        return
    end

    if amount > Config.MaxDeposit then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_too_high']:format(Config.MaxDeposit))
        return
    end

    local balanceBefore = xPlayer.getAccount('bank').money

    xPlayer.removeMoney(amount)
    xPlayer.addAccountMoney('bank', amount)

    local balanceAfter = xPlayer.getAccount('bank').money

    AddTransaction(xPlayer.identifier, 'deposit', amount, balanceBefore, balanceAfter, nil, nil, 'Dépôt en espèces')

    TriggerClientEvent('esx:showNotification', source, Locale['deposit_success']:format(ESX.Math.GroupDigits(amount)))
    TriggerClientEvent('nc_bank:updateBalance', source, balanceAfter, xPlayer.getMoney())
end)

-- Retrait d'argent
RegisterNetEvent('nc_bank:withdraw', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    local bankMoney = xPlayer.getAccount('bank').money

    if bankMoney < amount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money_bank'])
        return
    end

    if amount > Config.MaxWithdrawal then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_too_high']:format(Config.MaxWithdrawal))
        return
    end

    local balanceBefore = xPlayer.getAccount('bank').money

    xPlayer.removeAccountMoney('bank', amount)
    xPlayer.addMoney(amount)

    local balanceAfter = xPlayer.getAccount('bank').money

    AddTransaction(xPlayer.identifier, 'withdraw', amount, balanceBefore, balanceAfter, nil, nil, 'Retrait en espèces')

    TriggerClientEvent('esx:showNotification', source, Locale['withdraw_success']:format(ESX.Math.GroupDigits(amount)))
    TriggerClientEvent('nc_bank:updateBalance', source, balanceAfter, xPlayer.getMoney())
end)

-- Virement bancaire
RegisterNetEvent('nc_bank:transfer', function(target, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    target = tonumber(target)

    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    if target == source then
        TriggerClientEvent('esx:showNotification', source, Locale['cannot_transfer_self'])
        return
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then
        TriggerClientEvent('esx:showNotification', source, Locale['player_not_found'])
        return
    end

    if amount > Config.MaxTransferAmount then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_too_high']:format(Config.MaxTransferAmount))
        return
    end

    local bankMoney = xPlayer.getAccount('bank').money

    -- Calculer les frais
    local fee = math.floor(amount * Config.TransferFee)
    if fee < Config.MinTransferFee then fee = Config.MinTransferFee end
    if fee > Config.MaxTransferFee then fee = Config.MaxTransferFee end

    local totalAmount = amount + fee

    if bankMoney < totalAmount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money_bank'])
        return
    end

    local senderBalanceBefore = xPlayer.getAccount('bank').money
    local receiverBalanceBefore = xTarget.getAccount('bank').money

    -- Effectuer le virement
    xPlayer.removeAccountMoney('bank', totalAmount)
    xTarget.addAccountMoney('bank', amount)

    local senderBalanceAfter = xPlayer.getAccount('bank').money
    local receiverBalanceAfter = xTarget.getAccount('bank').money

    -- Enregistrer les transactions
    AddTransaction(xPlayer.identifier, 'transfer_sent', amount, senderBalanceBefore, senderBalanceAfter, xTarget.identifier, nil, 'Virement à ' .. xTarget.getName())
    AddTransaction(xTarget.identifier, 'transfer_received', amount, receiverBalanceBefore, receiverBalanceAfter, nil, xPlayer.identifier, 'Virement de ' .. xPlayer.getName())

    -- Notifications
    TriggerClientEvent('esx:showNotification', source, Locale['transfer_success'])
    TriggerClientEvent('esx:showNotification', source, Locale['transfer_fee']:format(ESX.Math.GroupDigits(fee)))
    TriggerClientEvent('esx:showNotification', target, Locale['transfer_received']:format(ESX.Math.GroupDigits(amount), xPlayer.getName()))

    TriggerClientEvent('nc_bank:updateBalance', source, senderBalanceAfter, xPlayer.getMoney())
    TriggerClientEvent('nc_bank:updateBalance', target, receiverBalanceAfter, xTarget.getMoney())
end)

-- Récupérer les comptes d'épargne
ESX.RegisterServerCallback('nc_bank:getSavingsAccounts', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    local accounts = MySQL.query.await('SELECT * FROM nc_savings_accounts WHERE identifier = ?', {
        xPlayer.identifier
    })

    cb(accounts or {})
end)

-- Créer un compte d'épargne
RegisterNetEvent('nc_bank:createSavingsAccount', function(accountName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    -- Vérifier le nombre de comptes
    local accounts = MySQL.query.await('SELECT COUNT(*) as count FROM nc_savings_accounts WHERE identifier = ?', {
        xPlayer.identifier
    })

    if accounts[1].count >= Config.MaxSavingsAccounts then
        TriggerClientEvent('esx:showNotification', source, Locale['max_savings_reached'])
        return
    end

    MySQL.insert('INSERT INTO nc_savings_accounts (identifier, account_name, balance) VALUES (?, ?, 0)', {
        xPlayer.identifier,
        accountName or 'Compte Épargne'
    })

    TriggerClientEvent('esx:showNotification', source, Locale['savings_created'])
    TriggerClientEvent('nc_bank:refreshSavings', source)
end)

-- Déposer sur un compte d'épargne
RegisterNetEvent('nc_bank:savingsDeposit', function(accountId, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    local bankMoney = xPlayer.getAccount('bank').money
    if bankMoney < amount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money_bank'])
        return
    end

    local balanceBefore = xPlayer.getAccount('bank').money

    xPlayer.removeAccountMoney('bank', amount)
    MySQL.update('UPDATE nc_savings_accounts SET balance = balance + ? WHERE id = ? AND identifier = ?', {
        amount,
        accountId,
        xPlayer.identifier
    })

    local balanceAfter = xPlayer.getAccount('bank').money

    AddTransaction(xPlayer.identifier, 'savings_deposit', amount, balanceBefore, balanceAfter, nil, nil, 'Dépôt sur compte épargne')

    TriggerClientEvent('esx:showNotification', source, Locale['deposit_success']:format(ESX.Math.GroupDigits(amount)))
    TriggerClientEvent('nc_bank:refreshSavings', source)
    TriggerClientEvent('nc_bank:updateBalance', source, balanceAfter, xPlayer.getMoney())
end)

-- Retirer d'un compte d'épargne
RegisterNetEvent('nc_bank:savingsWithdraw', function(accountId, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    local account = MySQL.query.await('SELECT balance FROM nc_savings_accounts WHERE id = ? AND identifier = ?', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] or account[1].balance < amount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money_bank'])
        return
    end

    local balanceBefore = xPlayer.getAccount('bank').money

    MySQL.update('UPDATE nc_savings_accounts SET balance = balance - ? WHERE id = ? AND identifier = ?', {
        amount,
        accountId,
        xPlayer.identifier
    })
    xPlayer.addAccountMoney('bank', amount)

    local balanceAfter = xPlayer.getAccount('bank').money

    AddTransaction(xPlayer.identifier, 'savings_withdraw', amount, balanceBefore, balanceAfter, nil, nil, 'Retrait du compte épargne')

    TriggerClientEvent('esx:showNotification', source, Locale['withdraw_success']:format(ESX.Math.GroupDigits(amount)))
    TriggerClientEvent('nc_bank:refreshSavings', source)
    TriggerClientEvent('nc_bank:updateBalance', source, balanceAfter, xPlayer.getMoney())
end)

-- Supprimer un compte d'épargne
RegisterNetEvent('nc_bank:deleteSavingsAccount', function(accountId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    -- Récupérer le solde et le transférer au compte principal
    local account = MySQL.query.await('SELECT balance FROM nc_savings_accounts WHERE id = ? AND identifier = ?', {
        accountId,
        xPlayer.identifier
    })

    if account[1] and account[1].balance > 0 then
        xPlayer.addAccountMoney('bank', account[1].balance)
    end

    MySQL.query('DELETE FROM nc_savings_accounts WHERE id = ? AND identifier = ?', {
        accountId,
        xPlayer.identifier
    })

    TriggerClientEvent('esx:showNotification', source, Locale['savings_deleted'])
    TriggerClientEvent('nc_bank:refreshSavings', source)
end)

-- Système d'intérêts (thread)
if Config.EnableInterests then
    CreateThread(function()
        while true do
            Wait(Config.InterestCycle * 60 * 1000) -- Convertir en millisecondes

            local xPlayers = ESX.GetExtendedPlayers()

            for _, xPlayer in pairs(xPlayers) do
                local bankMoney = xPlayer.getAccount('bank').money

                if bankMoney > 0 then
                    local interest = math.floor(bankMoney * Config.InterestRate)

                    if interest > 0 then
                        local balanceBefore = bankMoney
                        xPlayer.addAccountMoney('bank', interest)
                        local balanceAfter = xPlayer.getAccount('bank').money

                        AddTransaction(xPlayer.identifier, 'interest', interest, balanceBefore, balanceAfter, nil, nil, 'Intérêts bancaires')

                        TriggerClientEvent('esx:showNotification', xPlayer.source, Locale['interest_earned']:format(ESX.Math.GroupDigits(interest)))
                        TriggerClientEvent('nc_bank:updateBalance', xPlayer.source, balanceAfter, xPlayer.getMoney())
                    end
                end

                -- Intérêts sur les comptes d'épargne
                local savingsAccounts = MySQL.query.await('SELECT * FROM nc_savings_accounts WHERE identifier = ?', {
                    xPlayer.identifier
                })

                for _, account in pairs(savingsAccounts) do
                    if account.balance > 0 then
                        local savingsInterest = math.floor(account.balance * (Config.SavingsInterestRate / 100))

                        if savingsInterest > 0 then
                            MySQL.update('UPDATE nc_savings_accounts SET balance = balance + ?, last_interest = NOW() WHERE id = ?', {
                                savingsInterest,
                                account.id
                            })

                            TriggerClientEvent('esx:showNotification', xPlayer.source, Locale['interest_earned']:format(ESX.Math.GroupDigits(savingsInterest)) .. ' (Épargne)')
                        end
                    end
                end
            end

            if Config.Debug then
                print('[NC_BANK] Intérêts calculés et distribués')
            end
        end
    end)
end

-- Commande pour ouvrir la banque (désactivée)
-- RegisterCommand('bank', function(source)
--     TriggerClientEvent('nc_bank:openUI', source)
-- end)

-- Event pour ATM depuis le client
RegisterNetEvent('nc_bank:atmWithdraw', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    if amount > Config.ATMWithdrawLimit then
        TriggerClientEvent('esx:showNotification', source, Locale['atm_withdraw_limit']:format(Config.ATMWithdrawLimit))
        return
    end

    local bankMoney = xPlayer.getAccount('bank').money

    if bankMoney < amount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money_bank'])
        return
    end

    local balanceBefore = xPlayer.getAccount('bank').money

    xPlayer.removeAccountMoney('bank', amount)
    xPlayer.addMoney(amount)

    local balanceAfter = xPlayer.getAccount('bank').money

    AddTransaction(xPlayer.identifier, 'withdraw', amount, balanceBefore, balanceAfter, nil, nil, 'Retrait ATM')

    TriggerClientEvent('esx:showNotification', source, Locale['withdraw_success']:format(ESX.Math.GroupDigits(amount)))
    TriggerClientEvent('nc_bank:updateBalance', source, balanceAfter, xPlayer.getMoney())
end)

RegisterNetEvent('nc_bank:atmDeposit', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    if amount > Config.ATMDepositLimit then
        TriggerClientEvent('esx:showNotification', source, Locale['atm_deposit_limit']:format(Config.ATMDepositLimit))
        return
    end

    local playerMoney = xPlayer.getMoney()

    if playerMoney < amount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money'])
        return
    end

    local balanceBefore = xPlayer.getAccount('bank').money

    xPlayer.removeMoney(amount)
    xPlayer.addAccountMoney('bank', amount)

    local balanceAfter = xPlayer.getAccount('bank').money

    AddTransaction(xPlayer.identifier, 'deposit', amount, balanceBefore, balanceAfter, nil, nil, 'Dépôt ATM')

    TriggerClientEvent('esx:showNotification', source, Locale['deposit_success']:format(ESX.Math.GroupDigits(amount)))
    TriggerClientEvent('nc_bank:updateBalance', source, balanceAfter, xPlayer.getMoney())
end)

-- Récupérer les joueurs en ligne pour les virements
ESX.RegisterServerCallback('nc_bank:getOnlinePlayers', function(source, cb)
    local xPlayers = ESX.GetExtendedPlayers()
    local players = {}

    for _, xPlayer in pairs(xPlayers) do
        if xPlayer.source ~= source then
            table.insert(players, {
                id = xPlayer.source,
                name = xPlayer.getName(),
                identifier = xPlayer.identifier
            })
        end
    end

    cb(players)
end)

print('^2[NC_BANK]^7 NorthCounty Bank System chargé avec succès!')
