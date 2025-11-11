-- Initialisation ESX
ESX = exports["es_extended"]:getSharedObject()

-- Messages serveur
local function _U(str, ...)
    if Locales and Locales[Config.Locale] and Locales[Config.Locale][str] then
        return string.format(Locales[Config.Locale][str], ...)
    else
        return str
    end
end

local Locale = setmetatable({}, {
    __index = function(t, k)
        return function(...)
            return _U(k, ...)
        end
    end
})

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

-- Générer un IBAN unique
local function GenerateIBAN()
    return MySQL.scalar.await('SELECT generate_iban()', {})
end

-- Vérifier si un IBAN existe
local function IBANExists(iban)
    local result = MySQL.scalar.await('SELECT COUNT(*) FROM nc_bank_accounts WHERE iban = ?', {iban})
    return result > 0
end

-- Récupérer un compte par IBAN
local function GetAccountByIBAN(iban)
    return MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE iban = ? LIMIT 1', {iban})
end

-- Récupérer les comptes d'un joueur
local function GetPlayerAccounts(identifier)
    return MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE identifier = ?', {identifier})
end

-- Fonction pour ajouter une transaction à l'historique
local function AddTransaction(accountId, transactionType, amount, balanceBefore, balanceAfter, targetIban, description)
    MySQL.insert('INSERT INTO nc_bank_transactions (account_id, transaction_type, amount, balance_before, balance_after, target_iban, description) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        accountId,
        transactionType,
        amount,
        balanceBefore,
        balanceAfter,
        targetIban,
        description
    })

    -- Limiter l'historique
    MySQL.query('DELETE FROM nc_bank_transactions WHERE account_id = ? AND id NOT IN (SELECT id FROM (SELECT id FROM nc_bank_transactions WHERE account_id = ? ORDER BY created_at DESC LIMIT ?) AS temp)', {
        accountId,
        accountId,
        Config.MaxTransactionHistory
    })
end

-- ============================================
-- GESTION DES COMPTES
-- ============================================

-- Créer le compte personnel d'un joueur
local function CreatePersonalAccount(identifier, playerName)
    local iban = GenerateIBAN()
    local pin = Config.DefaultPIN

    local accountId = MySQL.insert.await('INSERT INTO nc_bank_accounts (identifier, iban, pin_code, account_type, account_name, balance) VALUES (?, ?, ?, ?, ?, ?)', {
        identifier,
        iban,
        pin,
        'personal',
        playerName,
        Config.StartingMoney
    })

    -- Créer une carte bancaire pour ce compte
    local cardNumber = string.sub(iban:gsub('[^0-9]', ''), 1, 16) -- Extraire 16 chiffres de l'IBAN
    if #cardNumber < 16 then
        cardNumber = cardNumber .. string.rep('0', 16 - #cardNumber) -- Compléter avec des 0
    end
    local cvv = tostring(math.random(100, 999))
    local expiryDate = os.date('%m/%y', os.time() + (Config.CardValidityMonths * 30 * 24 * 60 * 60))

    MySQL.insert('INSERT INTO nc_bank_cards (account_id, card_number, cvv, expiry_date, card_type, is_active) VALUES (?, ?, ?, ?, ?, ?)', {
        accountId,
        cardNumber,
        cvv,
        expiryDate,
        'debit',
        1
    })

    return accountId, iban
end

-- Créer un compte entreprise pour un joueur
local function CreateBusinessAccount(identifier, playerName, jobName, jobLabel)
    local iban = GenerateIBAN()
    local pin = Config.DefaultPIN

    local accountId = MySQL.insert.await('INSERT INTO nc_bank_accounts (identifier, iban, pin_code, account_type, account_name, balance) VALUES (?, ?, ?, ?, ?, ?)', {
        identifier,
        iban,
        pin,
        'business',
        'Entreprise - ' .. jobLabel,
        0
    })

    -- Créer les détails du compte entreprise
    MySQL.insert('INSERT INTO nc_business_accounts (account_id, business_name, job_name, owner_identifier) VALUES (?, ?, ?, ?)', {
        accountId,
        jobLabel,
        jobName,
        identifier
    })

    -- Créer une carte bancaire pour ce compte
    local cardNumber = string.sub(iban:gsub('[^0-9]', ''), 1, 16) -- Extraire 16 chiffres de l'IBAN
    if #cardNumber < 16 then
        cardNumber = cardNumber .. string.rep('0', 16 - #cardNumber) -- Compléter avec des 0
    end
    local cvv = tostring(math.random(100, 999))
    local expiryDate = os.date('%m/%y', os.time() + (Config.CardValidityMonths * 30 * 24 * 60 * 60))

    MySQL.insert('INSERT INTO nc_bank_cards (account_id, card_number, cvv, expiry_date, card_type, is_active) VALUES (?, ?, ?, ?, ?, ?)', {
        accountId,
        cardNumber,
        cvv,
        expiryDate,
        'debit',
        1
    })

    return accountId, iban
end

-- Event: Joueur connecté (vérifier et créer le compte entreprise si nécessaire)
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local identifier = xPlayer.identifier
    local playerName = xPlayer.getName()

    -- Vérifier si le joueur a un compte entreprise
    local accounts = GetPlayerAccounts(identifier)
    local hasBusiness = false

    for _, account in pairs(accounts) do
        if account.account_type == 'business' then
            hasBusiness = true
        end
    end

    -- Créer le compte entreprise si le joueur a un job éligible
    if not hasBusiness then
        local job = xPlayer.getJob()
        if job and job.name then
            for _, businessJob in pairs(Config.BusinessJobs) do
                if job.name == businessJob then
                    local accountId, iban = CreateBusinessAccount(identifier, playerName, job.name, job.label)
                    if Config.Debug then
                        print('[NC_BANK] Compte entreprise créé pour ' .. playerName .. ' (' .. job.label .. ') - IBAN: ' .. iban)
                    end
                    break
                end
            end
        end
    end
end)

-- Event: Créer un compte personnel manuellement
RegisterNetEvent('nc_bank:createPersonalAccount', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local playerName = xPlayer.getName()

    -- Vérifier si le joueur a déjà un compte personnel
    local accounts = GetPlayerAccounts(identifier)
    for _, account in pairs(accounts) do
        if account.account_type == 'personal' then
            TriggerClientEvent('esx:showNotification', source, 'Vous avez déjà un compte personnel')
            return
        end
    end

    -- Créer le compte personnel
    local accountId, iban = CreatePersonalAccount(identifier, playerName)

    if Config.Debug then
        print('[NC_BANK] Compte personnel créé pour ' .. playerName .. ' - IBAN: ' .. iban)
    end

    TriggerClientEvent('esx:showNotification', source, 'Votre compte bancaire a été créé avec succès!')

    -- Ouvrir l'interface après la création
    Wait(1000)
    TriggerClientEvent('nc_bank:openUI', source)
end)

-- ============================================
-- CALLBACKS
-- ============================================

-- Récupérer toutes les informations du compte pour l'interface
ESX.RegisterServerCallback('nc_bank:getFullAccountInfo', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local accounts = GetPlayerAccounts(xPlayer.identifier)
    local personalAccount = nil
    local businessAccount = nil

    -- Séparer les comptes
    for _, account in pairs(accounts) do
        if account.account_type == 'personal' then
            personalAccount = account
        elseif account.account_type == 'business' then
            businessAccount = account
        end
    end

    -- Récupérer les cartes bancaires
    local cards = {}
    if personalAccount then
        local personalCards = MySQL.query.await('SELECT * FROM nc_bank_cards WHERE account_id = ?', {personalAccount.id})
        for _, card in pairs(personalCards) do
            card.account_type = 'personal'
            table.insert(cards, card)
        end
    end
    if businessAccount then
        local businessCards = MySQL.query.await('SELECT * FROM nc_bank_cards WHERE account_id = ?', {businessAccount.id})
        for _, card in pairs(businessCards) do
            card.account_type = 'business'
            table.insert(cards, card)
        end
    end

    -- Récupérer les transactions récentes (compte personnel)
    local recentTransactions = {}
    if personalAccount then
        recentTransactions = MySQL.query.await('SELECT * FROM nc_bank_transactions WHERE account_id = ? ORDER BY created_at DESC LIMIT ?', {
            personalAccount.id,
            Config.RecentTransactionsCount
        })
    end

    local data = {
        playerName = xPlayer.getName(),
        cash = xPlayer.getMoney(),
        serverName = Config.ServerName,
        personalAccount = personalAccount,
        businessAccount = businessAccount,
        cards = cards,
        recentTransactions = recentTransactions
    }

    cb(data)
end)

-- Vérifier le code PIN
ESX.RegisterServerCallback('nc_bank:verifyPIN', function(source, cb, pin)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, nil) end

    local accounts = GetPlayerAccounts(xPlayer.identifier)
    local personalAccount = nil

    -- Récupérer le compte personnel
    for _, account in pairs(accounts) do
        if account.account_type == 'personal' then
            personalAccount = account
            break
        end
    end

    if not personalAccount then
        return cb(false, nil)
    end

    -- Vérifier le PIN
    if personalAccount.pin_code == pin then
        -- PIN correct, récupérer toutes les données du compte
        local businessAccount = nil
        for _, account in pairs(accounts) do
            if account.account_type == 'business' then
                businessAccount = account
                break
            end
        end

        -- Récupérer les cartes bancaires
        local cards = {}
        local personalCards = MySQL.query.await('SELECT * FROM nc_bank_cards WHERE account_id = ?', {personalAccount.id})
        for _, card in pairs(personalCards) do
            card.account_type = 'personal'
            table.insert(cards, card)
        end
        if businessAccount then
            local businessCards = MySQL.query.await('SELECT * FROM nc_bank_cards WHERE account_id = ?', {businessAccount.id})
            for _, card in pairs(businessCards) do
                card.account_type = 'business'
                table.insert(cards, card)
            end
        end

        -- Récupérer les transactions récentes
        local recentTransactions = MySQL.query.await('SELECT * FROM nc_bank_transactions WHERE account_id = ? ORDER BY created_at DESC LIMIT ?', {
            personalAccount.id,
            Config.RecentTransactionsCount
        })

        local data = {
            playerName = xPlayer.getName(),
            cash = xPlayer.getMoney(),
            serverName = Config.ServerName,
            personalAccount = personalAccount,
            businessAccount = businessAccount,
            cards = cards,
            recentTransactions = recentTransactions
        }

        cb(true, data)
    else
        -- PIN incorrect
        cb(false, nil)
    end
end)

-- Récupérer l'historique complet des transactions d'un compte
ESX.RegisterServerCallback('nc_bank:getTransactions', function(source, cb, accountId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    -- Vérifier que le compte appartient au joueur
    local account = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE id = ? AND identifier = ? LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        return cb({})
    end

    local transactions = MySQL.query.await('SELECT * FROM nc_bank_transactions WHERE account_id = ? ORDER BY created_at DESC LIMIT ?', {
        accountId,
        Config.MaxTransactionHistory
    })

    cb(transactions or {})
end)

-- Rechercher des transactions par montant et/ou date
ESX.RegisterServerCallback('nc_bank:searchTransactions', function(source, cb, accountId, filters)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    -- Vérifier que le compte appartient au joueur
    local account = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE id = ? AND identifier = ? LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        return cb({})
    end

    local query = 'SELECT * FROM nc_bank_transactions WHERE account_id = ?'
    local params = {accountId}

    -- Filtrer par montant
    if filters.minAmount then
        query = query .. ' AND amount >= ?'
        table.insert(params, tonumber(filters.minAmount))
    end
    if filters.maxAmount then
        query = query .. ' AND amount <= ?'
        table.insert(params, tonumber(filters.maxAmount))
    end

    -- Filtrer par date
    if filters.startDate then
        query = query .. ' AND created_at >= ?'
        table.insert(params, filters.startDate)
    end
    if filters.endDate then
        query = query .. ' AND created_at <= ?'
        table.insert(params, filters.endDate)
    end

    query = query .. ' ORDER BY created_at DESC LIMIT ?'
    table.insert(params, Config.MaxTransactionHistory)

    local transactions = MySQL.query.await(query, params)
    cb(transactions or {})
end)

-- Récupérer les employés pour un compte entreprise
ESX.RegisterServerCallback('nc_bank:getBusinessEmployees', function(source, cb, accountId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    -- Vérifier que le compte appartient au joueur et est un compte entreprise
    local account = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE id = ? AND identifier = ? AND account_type = "business" LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        return cb({})
    end

    local employees = MySQL.query.await('SELECT * FROM nc_business_employees WHERE business_account_id = ? ORDER BY employee_name ASC', {
        accountId
    })

    cb(employees or {})
end)

-- ============================================
-- OPÉRATIONS BANCAIRES
-- ============================================

-- Dépôt d'argent
RegisterNetEvent('nc_bank:deposit', function(accountId, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    -- Vérifier que le compte appartient au joueur
    local account = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE id = ? AND identifier = ? LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        TriggerClientEvent('esx:showNotification', source, 'Compte non trouvé')
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

    local balanceBefore = account[1].balance

    xPlayer.removeMoney(amount)
    MySQL.update('UPDATE nc_bank_accounts SET balance = balance + ? WHERE id = ?', {
        amount,
        accountId
    })

    local balanceAfter = balanceBefore + amount

    AddTransaction(accountId, 'deposit', amount, balanceBefore, balanceAfter, nil, 'Dépôt en espèces')

    TriggerClientEvent('esx:showNotification', source, Locale['deposit_success']:format(ESX.Math.GroupDigits(amount)))
    TriggerClientEvent('nc_bank:refreshUI', source)
end)

-- Retrait d'argent
RegisterNetEvent('nc_bank:withdraw', function(accountId, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    -- Vérifier que le compte appartient au joueur
    local account = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE id = ? AND identifier = ? LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        TriggerClientEvent('esx:showNotification', source, 'Compte non trouvé')
        return
    end

    if account[1].balance < amount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money_bank'])
        return
    end

    if amount > Config.MaxWithdrawal then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_too_high']:format(Config.MaxWithdrawal))
        return
    end

    local balanceBefore = account[1].balance

    MySQL.update('UPDATE nc_bank_accounts SET balance = balance - ? WHERE id = ?', {
        amount,
        accountId
    })
    xPlayer.addMoney(amount)

    local balanceAfter = balanceBefore - amount

    AddTransaction(accountId, 'withdraw', amount, balanceBefore, balanceAfter, nil, 'Retrait en espèces')

    TriggerClientEvent('esx:showNotification', source, Locale['withdraw_success']:format(ESX.Math.GroupDigits(amount)))
    TriggerClientEvent('nc_bank:refreshUI', source)
end)

-- Virement bancaire via IBAN
RegisterNetEvent('nc_bank:transfer', function(accountId, targetIban, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    amount = tonumber(amount)

    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_invalid'])
        return
    end

    if not targetIban or targetIban == '' then
        TriggerClientEvent('esx:showNotification', source, 'IBAN invalide')
        return
    end

    -- Vérifier que le compte appartient au joueur
    local account = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE id = ? AND identifier = ? LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        TriggerClientEvent('esx:showNotification', source, 'Compte non trouvé')
        return
    end

    -- Vérifier qu'on ne transfère pas vers son propre compte
    if account[1].iban == targetIban then
        TriggerClientEvent('esx:showNotification', source, Locale['cannot_transfer_self'])
        return
    end

    -- Vérifier que le compte cible existe
    local targetAccount = GetAccountByIBAN(targetIban)
    if not targetAccount[1] then
        TriggerClientEvent('esx:showNotification', source, 'IBAN introuvable')
        return
    end

    if amount > Config.MaxTransferAmount then
        TriggerClientEvent('esx:showNotification', source, Locale['amount_too_high']:format(Config.MaxTransferAmount))
        return
    end

    -- Calculer les frais
    local fee = math.floor(amount * Config.TransferFee)
    if fee < Config.MinTransferFee then fee = Config.MinTransferFee end
    if fee > Config.MaxTransferFee then fee = Config.MaxTransferFee end

    local totalAmount = amount + fee

    if account[1].balance < totalAmount then
        TriggerClientEvent('esx:showNotification', source, Locale['not_enough_money_bank'])
        return
    end

    local senderBalanceBefore = account[1].balance
    local receiverBalanceBefore = targetAccount[1].balance

    -- Effectuer le virement
    MySQL.update('UPDATE nc_bank_accounts SET balance = balance - ? WHERE id = ?', {
        totalAmount,
        accountId
    })
    MySQL.update('UPDATE nc_bank_accounts SET balance = balance + ? WHERE id = ?', {
        amount,
        targetAccount[1].id
    })

    local senderBalanceAfter = senderBalanceBefore - totalAmount
    local receiverBalanceAfter = receiverBalanceBefore + amount

    -- Enregistrer les transactions
    AddTransaction(accountId, 'transfer_sent', amount, senderBalanceBefore, senderBalanceAfter, targetIban, 'Virement vers ' .. targetIban)
    AddTransaction(targetAccount[1].id, 'transfer_received', amount, receiverBalanceBefore, receiverBalanceAfter, account[1].iban, 'Virement reçu de ' .. account[1].iban)

    -- Notifications
    TriggerClientEvent('esx:showNotification', source, Locale['transfer_success'])
    TriggerClientEvent('esx:showNotification', source, Locale['transfer_fee']:format(ESX.Math.GroupDigits(fee)))
    TriggerClientEvent('nc_bank:refreshUI', source)

    -- Notifier le destinataire s'il est en ligne
    local xTarget = ESX.GetPlayerFromIdentifier(targetAccount[1].identifier)
    if xTarget then
        TriggerClientEvent('esx:showNotification', xTarget.source, 'Virement reçu: ' .. ESX.Math.GroupDigits(amount) .. '$ de ' .. account[1].iban)
        TriggerClientEvent('nc_bank:refreshUI', xTarget.source)
    end
end)

-- ============================================
-- GESTION DES SALAIRES (COMPTE ENTREPRISE)
-- ============================================

-- Synchroniser les employés d'une entreprise
RegisterNetEvent('nc_bank:syncBusinessEmployees', function(accountId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    -- Vérifier que le compte appartient au joueur et est un compte entreprise
    local account = MySQL.query.await('SELECT a.*, b.job_name FROM nc_bank_accounts a JOIN nc_business_accounts b ON a.id = b.account_id WHERE a.id = ? AND a.identifier = ? AND a.account_type = "business" LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        TriggerClientEvent('esx:showNotification', source, 'Compte entreprise non trouvé')
        return
    end

    local jobName = account[1].job_name

    -- Récupérer tous les joueurs avec ce job
    local xPlayers = ESX.GetExtendedPlayers('job', jobName)

    for _, xEmployee in pairs(xPlayers) do
        local job = xEmployee.getJob()

        -- Vérifier si l'employé existe déjà
        local existing = MySQL.query.await('SELECT id FROM nc_business_employees WHERE business_account_id = ? AND employee_identifier = ? LIMIT 1', {
            accountId,
            xEmployee.identifier
        })

        if not existing[1] then
            -- Ajouter l'employé
            MySQL.insert('INSERT INTO nc_business_employees (business_account_id, employee_identifier, employee_name, job_grade, job_grade_name, salary) VALUES (?, ?, ?, ?, ?, ?)', {
                accountId,
                xEmployee.identifier,
                xEmployee.getName(),
                job.grade,
                job.grade_label,
                job.grade_salary or 0
            })
        else
            -- Mettre à jour l'employé
            MySQL.update('UPDATE nc_business_employees SET employee_name = ?, job_grade = ?, job_grade_name = ?, salary = ? WHERE id = ?', {
                xEmployee.getName(),
                job.grade,
                job.grade_label,
                job.grade_salary or 0,
                existing[1].id
            })
        end
    end

    TriggerClientEvent('esx:showNotification', source, 'Employés synchronisés')
    TriggerClientEvent('nc_bank:refreshUI', source)
end)

-- Payer le salaire d'un employé
RegisterNetEvent('nc_bank:paySalary', function(accountId, employeeId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    -- Vérifier que le compte appartient au joueur et est un compte entreprise
    local account = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE id = ? AND identifier = ? AND account_type = "business" LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        TriggerClientEvent('esx:showNotification', source, 'Compte entreprise non trouvé')
        return
    end

    -- Récupérer l'employé
    local employee = MySQL.query.await('SELECT * FROM nc_business_employees WHERE id = ? AND business_account_id = ? LIMIT 1', {
        employeeId,
        accountId
    })

    if not employee[1] then
        TriggerClientEvent('esx:showNotification', source, 'Employé non trouvé')
        return
    end

    -- Vérifier l'intervalle de paiement
    if employee[1].last_payment then
        local lastPaymentTime = os.time({
            year = tonumber(string.sub(employee[1].last_payment, 1, 4)),
            month = tonumber(string.sub(employee[1].last_payment, 6, 7)),
            day = tonumber(string.sub(employee[1].last_payment, 9, 10)),
            hour = tonumber(string.sub(employee[1].last_payment, 12, 13)),
            min = tonumber(string.sub(employee[1].last_payment, 15, 16)),
            sec = tonumber(string.sub(employee[1].last_payment, 18, 19))
        })

        local timeSinceLastPayment = os.difftime(os.time(), lastPaymentTime) / 3600 -- en heures

        if timeSinceLastPayment < Config.MinSalaryInterval then
            TriggerClientEvent('esx:showNotification', source, 'Vous devez attendre ' .. math.floor(Config.MinSalaryInterval - timeSinceLastPayment) .. ' heures avant le prochain paiement')
            return
        end
    end

    local salary = employee[1].salary

    if salary <= 0 then
        TriggerClientEvent('esx:showNotification', source, 'Salaire invalide')
        return
    end

    if account[1].balance < salary then
        TriggerClientEvent('esx:showNotification', source, 'Fonds insuffisants sur le compte entreprise')
        return
    end

    -- Récupérer le compte personnel de l'employé
    local employeeAccount = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE identifier = ? AND account_type = "personal" LIMIT 1', {
        employee[1].employee_identifier
    })

    if not employeeAccount[1] then
        TriggerClientEvent('esx:showNotification', source, 'Compte personnel de l\'employé non trouvé')
        return
    end

    local businessBalanceBefore = account[1].balance
    local employeeBalanceBefore = employeeAccount[1].balance

    -- Effectuer le paiement
    MySQL.update('UPDATE nc_bank_accounts SET balance = balance - ? WHERE id = ?', {
        salary,
        accountId
    })
    MySQL.update('UPDATE nc_bank_accounts SET balance = balance + ? WHERE id = ?', {
        salary,
        employeeAccount[1].id
    })

    -- Mettre à jour la date de dernier paiement
    MySQL.update('UPDATE nc_business_employees SET last_payment = NOW() WHERE id = ?', {
        employeeId
    })

    local businessBalanceAfter = businessBalanceBefore - salary
    local employeeBalanceAfter = employeeBalanceBefore + salary

    -- Enregistrer les transactions
    AddTransaction(accountId, 'transfer_sent', salary, businessBalanceBefore, businessBalanceAfter, employeeAccount[1].iban, 'Salaire payé à ' .. employee[1].employee_name)
    AddTransaction(employeeAccount[1].id, 'transfer_received', salary, employeeBalanceBefore, employeeBalanceAfter, account[1].iban, 'Salaire reçu')

    -- Notifications
    TriggerClientEvent('esx:showNotification', source, 'Salaire payé: ' .. ESX.Math.GroupDigits(salary) .. '$ à ' .. employee[1].employee_name)
    TriggerClientEvent('nc_bank:refreshUI', source)

    -- Notifier l'employé s'il est en ligne
    local xEmployee = ESX.GetPlayerFromIdentifier(employee[1].employee_identifier)
    if xEmployee then
        TriggerClientEvent('esx:showNotification', xEmployee.source, 'Salaire reçu: ' .. ESX.Math.GroupDigits(salary) .. '$')
        TriggerClientEvent('nc_bank:refreshUI', xEmployee.source)
    end
end)

-- ============================================
-- GESTION DU CODE PIN
-- ============================================

-- Changer le code PIN
RegisterNetEvent('nc_bank:changePIN', function(accountId, oldPIN, newPIN)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    -- Vérifier que le compte appartient au joueur
    local account = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE id = ? AND identifier = ? LIMIT 1', {
        accountId,
        xPlayer.identifier
    })

    if not account[1] then
        TriggerClientEvent('esx:showNotification', source, 'Compte non trouvé')
        return
    end

    -- Vérifier l'ancien PIN
    if account[1].pin_code ~= oldPIN then
        TriggerClientEvent('esx:showNotification', source, 'Code PIN incorrect')
        return
    end

    -- Vérifier le format du nouveau PIN (4 chiffres)
    if not newPIN or string.len(newPIN) ~= 4 or not tonumber(newPIN) then
        TriggerClientEvent('esx:showNotification', source, 'Le nouveau PIN doit contenir 4 chiffres')
        return
    end

    -- Mettre à jour le PIN
    MySQL.update('UPDATE nc_bank_accounts SET pin_code = ? WHERE id = ?', {
        newPIN,
        accountId
    })

    TriggerClientEvent('esx:showNotification', source, 'Code PIN modifié avec succès')
    TriggerClientEvent('nc_bank:refreshUI', source)
end)

-- ============================================
-- SYSTÈME D'INTÉRÊTS
-- ============================================

if Config.EnableInterests then
    CreateThread(function()
        while true do
            Wait(Config.InterestCycle * 60 * 60 * 1000) -- Convertir en millisecondes

            -- Récupérer tous les comptes personnels
            local accounts = MySQL.query.await('SELECT * FROM nc_bank_accounts WHERE account_type = "personal" AND balance > 0', {})

            for _, account in pairs(accounts) do
                local interest = math.floor(account.balance * Config.InterestRate)

                if interest > 0 then
                    local balanceBefore = account.balance
                    MySQL.update('UPDATE nc_bank_accounts SET balance = balance + ? WHERE id = ?', {
                        interest,
                        account.id
                    })
                    local balanceAfter = balanceBefore + interest

                    AddTransaction(account.id, 'interest', interest, balanceBefore, balanceAfter, nil, 'Intérêts bancaires')

                    -- Notifier le joueur s'il est en ligne
                    local xPlayer = ESX.GetPlayerFromIdentifier(account.identifier)
                    if xPlayer then
                        TriggerClientEvent('esx:showNotification', xPlayer.source, 'Intérêts reçus: ' .. ESX.Math.GroupDigits(interest) .. '$')
                        TriggerClientEvent('nc_bank:refreshUI', xPlayer.source)
                    end
                end
            end

            if Config.Debug then
                print('[NC_BANK] Intérêts calculés et distribués')
            end
        end
    end)
end

-- ============================================
-- APP TÉLÉPHONE - CALLBACKS ET EVENTS
-- ============================================

-- Callback: Récupérer les infos du compte pour l'app téléphone
ESX.RegisterServerCallback('nc_bank:getPhoneAccountInfo', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local accounts = GetPlayerAccounts(xPlayer.identifier)
    local personalAccount = nil

    -- Récupérer le compte personnel
    for _, account in pairs(accounts) do
        if account.account_type == 'personal' then
            personalAccount = account
            break
        end
    end

    if not personalAccount then
        return cb(nil)
    end

    -- Récupérer les transactions récentes
    local recentTransactions = MySQL.query.await('SELECT * FROM nc_bank_transactions WHERE account_id = ? ORDER BY created_at DESC LIMIT ?', {
        personalAccount.id,
        5 -- Seulement 5 transactions pour le téléphone
    })

    local data = {
        balance = personalAccount.balance,
        iban = personalAccount.iban,
        accountId = personalAccount.id,
        recentTransactions = recentTransactions or {}
    }

    cb(data)
end)

-- Event: Virement par numéro de téléphone
RegisterNetEvent('nc_bank:phoneTransfer', function(phoneNumber, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    -- Vérifier le montant
    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, 'Montant invalide')
        return
    end

    -- Récupérer le compte personnel de l'expéditeur
    local accounts = GetPlayerAccounts(xPlayer.identifier)
    local senderAccount = nil

    for _, account in pairs(accounts) do
        if account.account_type == 'personal' then
            senderAccount = account
            break
        end
    end

    if not senderAccount then
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas de compte bancaire')
        return
    end

    -- Vérifier le solde
    if senderAccount.balance < amount then
        TriggerClientEvent('esx:showNotification', source, 'Solde insuffisant')
        return
    end

    -- Trouver le joueur cible par son numéro de téléphone
    -- Note: Vous devez adapter cette partie selon votre système de téléphone (yseries, gcphone, etc.)
    local targetPlayer = nil
    local targetIdentifier = nil

    -- Essayer de trouver le joueur via ESX (chercher dans les metadata ou une table de téléphones)
    -- Pour yseries, chercher dans la table phone_contacts ou similaire
    local result = MySQL.query.await('SELECT identifier FROM users WHERE phone_number = ? LIMIT 1', {phoneNumber})

    if result and result[1] then
        targetIdentifier = result[1].identifier

        -- Trouver le joueur en ligne
        for _, playerId in ipairs(GetPlayers()) do
            local target = ESX.GetPlayerFromId(playerId)
            if target and target.identifier == targetIdentifier then
                targetPlayer = target
                break
            end
        end
    else
        TriggerClientEvent('esx:showNotification', source, 'Numéro de téléphone introuvable')
        return
    end

    -- Récupérer le compte du destinataire
    local targetAccounts = GetPlayerAccounts(targetIdentifier)
    local targetAccount = nil

    for _, account in pairs(targetAccounts) do
        if account.account_type == 'personal' then
            targetAccount = account
            break
        end
    end

    if not targetAccount then
        TriggerClientEvent('esx:showNotification', source, 'Le destinataire n\'a pas de compte bancaire')
        return
    end

    -- Calculer les frais
    local feePercent = Config.TransferFee or 1
    local fee = math.max(5, math.min(250, math.floor(amount * (feePercent / 100))))
    local totalAmount = amount + fee

    -- Vérifier le solde avec frais
    if senderAccount.balance < totalAmount then
        TriggerClientEvent('esx:showNotification', source, 'Solde insuffisant (frais inclus: $' .. fee .. ')')
        return
    end

    -- Effectuer le virement
    local newSenderBalance = senderAccount.balance - totalAmount
    local newTargetBalance = targetAccount.balance + amount

    -- Mettre à jour les soldes
    MySQL.update('UPDATE nc_bank_accounts SET balance = ? WHERE id = ?', {newSenderBalance, senderAccount.id})
    MySQL.update('UPDATE nc_bank_accounts SET balance = ? WHERE id = ?', {newTargetBalance, targetAccount.id})

    -- Ajouter les transactions
    AddTransaction(senderAccount.id, 'transfer_sent', amount, senderAccount.balance, newSenderBalance, targetAccount.iban, 'Virement vers ' .. phoneNumber)
    AddTransaction(targetAccount.id, 'transfer_received', amount, targetAccount.balance, newTargetBalance, senderAccount.iban, 'Virement de ' .. xPlayer.getName())

    -- Notifications
    TriggerClientEvent('esx:showNotification', source, 'Virement effectué: ' .. ESX.Math.GroupDigits(amount) .. '$ (frais: ' .. fee .. '$)')

    if targetPlayer then
        TriggerClientEvent('esx:showNotification', targetPlayer.source, 'Virement reçu: ' .. ESX.Math.GroupDigits(amount) .. '$ de ' .. xPlayer.getName())
        TriggerClientEvent('nc_bank:refreshUI', targetPlayer.source)
    end

    -- Rafraîchir l'UI de l'expéditeur
    TriggerClientEvent('nc_bank:refreshUI', source)

    -- Log
    if Config.Debug then
        print(string.format('[NC_BANK] Virement téléphone: %s -> %s | Montant: %s$ | Frais: %s$',
            xPlayer.identifier, targetIdentifier, amount, fee))
    end
end)

print('^2[NC_BANK]^7 NorthCounty Bank System V2 chargé avec succès!')
