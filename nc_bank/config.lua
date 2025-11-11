Config = {}

-- Langue
Config.Locale = 'fr'

-- Nom du serveur (affiché dans l'interface)
Config.ServerName = "NorthCounty RP"

-- ============================================
-- CONFIGURATION DES COMPTES
-- ============================================

-- Argent de départ sur le compte personnel
Config.StartingMoney = 5000

-- Format IBAN (NC = NorthCounty)
Config.IBANPrefix = "NC"
Config.IBANLength = 26

-- Code PIN par défaut (changeable par le joueur)
Config.DefaultPIN = "1234"

-- Types de comptes
Config.AccountTypes = {
    personal = "Compte Personnel",
    business = "Compte Entreprise"
}

-- ============================================
-- CONFIGURATION DES TRANSACTIONS
-- ============================================

-- Limites de transaction
Config.MaxTransferAmount = 100000
Config.MaxWithdrawal = 50000
Config.MaxDeposit = 100000

-- Frais bancaires
Config.TransferFee = 0.01 -- 1% de frais sur les virements
Config.MinTransferFee = 5
Config.MaxTransferFee = 250

-- ============================================
-- CONFIGURATION ATM
-- ============================================

Config.EnableATM = true
Config.ATMWithdrawLimit = 5000
Config.ATMDepositLimit = 10000
Config.ATMOnlyPersonal = true -- ATM uniquement pour comptes personnels

-- Modèles d'ATM dans le jeu
Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}

-- ATM personnalisés (optionnel - ajoutez vos propres coordonnées)
Config.CustomATMs = {
    -- Exemple:
    -- { coords = vector3(0.0, 0.0, 0.0) },
}

-- ============================================
-- CONFIGURATION DES BANQUES
-- ============================================

-- Positions des banques (Markers)
Config.Banks = {
    {
        name = "Banque Pacific Standard",
        coords = vector3(241.72, 227.19, 106.29),
        blip = true
    },
    {
        name = "Banque Legion Square",
        coords = vector3(149.46, -1040.53, 29.37),
        blip = true
    },
    {
        name = "Banque Great Ocean Highway",
        coords = vector3(-1212.98, -330.95, 37.79),
        blip = true
    },
    {
        name = "Banque Route 68",
        coords = vector3(-111.07, 6469.01, 31.63),
        blip = true
    },
    {
        name = "Banque Paleto Bay",
        coords = vector3(-112.64, 6470.24, 31.63),
        blip = true
    },
    {
        name = "Banque Del Perro",
        coords = vector3(-2962.71, 482.93, 15.70),
        blip = true
    }
}

-- Blips sur la carte
Config.BlipSprite = 108
Config.BlipColor = 2
Config.BlipScale = 0.8

-- Marker
Config.MarkerType = 1
Config.MarkerSize = {x = 1.5, y = 1.5, z = 1.0}
Config.MarkerColor = {r = 0, g = 255, b = 0}
Config.MarkerDistance = 15.0

-- ============================================
-- CONFIGURATION DES SALAIRES (ENTREPRISE)
-- ============================================

-- Intervalle minimum entre deux paiements de salaire (en heures)
Config.MinSalaryInterval = 24

-- Paiement automatique des salaires
Config.AutoPaySalaries = false

-- Jour de paiement automatique (1 = Lundi, 7 = Dimanche)
Config.SalaryPayDay = 1 -- Lundi

-- ============================================
-- CONFIGURATION DES CARTES BANCAIRES
-- ============================================

-- Durée de validité des cartes (en mois)
Config.CardValidityMonths = 48

-- Types de cartes
Config.CardTypes = {
    debit = "Carte de Débit",
    credit = "Carte de Crédit"
}

-- ============================================
-- CONFIGURATION DES INTÉRÊTS
-- ============================================

Config.EnableInterests = true
Config.InterestRate = 0.02 -- 2% d'intérêt par cycle
Config.InterestCycle = 168 -- En heures (168h = 1 semaine)
Config.SavingsInterestRate = 0.05 -- 5% pour les comptes d'épargne

-- ============================================
-- CONFIGURATION DE L'HISTORIQUE
-- ============================================

-- Nombre de transactions à afficher
Config.MaxTransactionHistory = 100
Config.RecentTransactionsCount = 5

-- ============================================
-- ANIMATIONS
-- ============================================

Config.DepositAnimation = {
    dict = "mp_common",
    anim = "givetake1_a"
}

Config.WithdrawAnimation = {
    dict = "mp_common",
    anim = "givetake2_a"
}

-- ============================================
-- NOTIFICATIONS
-- ============================================

Config.UseESXNotifications = true

-- ============================================
-- INTÉGRATION TÉLÉPHONE
-- ============================================

Config.PhoneResource = "gcphone"
Config.EnablePhoneApp = false -- Désactivé pour l'instant

-- ============================================
-- JOBS AVEC COMPTES ENTREPRISE
-- ============================================

-- Jobs qui peuvent avoir un compte entreprise
Config.BusinessJobs = {
    'police',
    'ambulance',
    'mechanic',
    'taxi',
    'cardealer',
    'realestate',
    'lawyer',
    'gang',
    'mafia'
}

-- ============================================
-- DEBUG
-- ============================================

Config.Debug = false
