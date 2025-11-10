Config = {}

-- Langue
Config.Locale = 'fr'

-- Nom du serveur (affiché dans l'interface)
Config.ServerName = "NorthCounty RP"

-- Configuration des comptes
Config.StartingMoney = 5000 -- Argent de départ sur le compte bancaire
Config.MaxSavingsAccounts = 3 -- Nombre maximum de comptes d'épargne par joueur

-- Configuration des intérêts
Config.EnableInterests = true
Config.InterestRate = 0.05 -- 5% d'intérêt par cycle
Config.InterestCycle = 60 -- En minutes (60 = 1 heure)
Config.SavingsInterestRate = 0.10 -- 10% pour les comptes d'épargne

-- Limites de transaction
Config.MaxTransferAmount = 50000 -- Montant maximum par virement
Config.MaxWithdrawal = 20000 -- Retrait maximum par transaction
Config.MaxDeposit = 50000 -- Dépôt maximum par transaction

-- Frais bancaires
Config.TransferFee = 0.02 -- 2% de frais sur les virements
Config.MinTransferFee = 10 -- Frais minimum
Config.MaxTransferFee = 500 -- Frais maximum

-- Configuration ATM
Config.EnableATM = true
Config.ATMWithdrawLimit = 5000 -- Limite de retrait aux ATM
Config.ATMDepositLimit = 10000 -- Limite de dépôt aux ATM

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

-- Positions des ATM automatiques (les ATM du jeu sont détectés automatiquement)
Config.CustomATMs = {
    -- Vous pouvez ajouter des ATM personnalisés ici
    -- {coords = vector3(x, y, z)}
}

-- Blips sur la carte
Config.BlipSprite = 108 -- Icône de banque
Config.BlipColor = 2 -- Couleur verte
Config.BlipScale = 0.8

-- Marker
Config.MarkerType = 1
Config.MarkerSize = {x = 1.5, y = 1.5, z = 1.0}
Config.MarkerColor = {r = 0, g = 255, b = 0}
Config.MarkerDistance = 15.0 -- Distance d'affichage du marker

-- Historique des transactions
Config.MaxTransactionHistory = 50 -- Nombre maximum de transactions gardées en historique

-- Notifications
Config.UseESXNotifications = true -- Utiliser les notifications ESX

-- Animation
Config.DepositAnimation = {
    dict = "mp_common",
    anim = "givetake1_a"
}

Config.WithdrawAnimation = {
    dict = "mp_common",
    anim = "givetake2_a"
}

-- Intégration téléphone (mettre le nom de votre ressource de téléphone)
Config.PhoneResource = "gcphone" -- Peut être "gcphone", "d-phone", "lb-phone", "qs-phone", etc.
Config.EnablePhoneApp = true

-- Modèles d'ATM dans le jeu
Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}

-- Debug
Config.Debug = false
