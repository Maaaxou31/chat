# 🏦 NorthCounty Bank - Système Bancaire FiveM

Système bancaire complet pour serveur FiveM GTA RP avec intégration ESX.

## ✨ Fonctionnalités

- ✅ **Système de compte bancaire** avec intégration ESX
- 💰 **Dépôt/retrait d'argent** aux banques et ATM
- 💸 **Virements entre joueurs** avec frais de transaction
- 🏦 **Comptes d'épargne** avec taux d'intérêt élevés
- 📊 **Historique des transactions** détaillé
- 💵 **ATM (distributeurs)** automatiquement détectés dans le jeu
- 📈 **Intérêts bancaires** automatiques
- 🎨 **Interface UI (NUI)** moderne et élégante
- 📱 **Intégration téléphone** (optionnel)
- 🗺️ **Blips sur la carte** pour localiser les banques

## 📋 Prérequis

- **ESX Legacy** (ou ESX 1.2+)
- **oxmysql** (ou mysql-async)
- Serveur FiveM à jour

## 🔧 Installation

### 1. Télécharger et placer le script

Placez le dossier `nc_bank` dans votre dossier `resources`.

### 2. Importer la base de données

Importez le fichier `nc_bank.sql` dans votre base de données MySQL.

```sql
mysql -u admin -p northcountydev < nc_bank.sql
```

Ou via phpMyAdmin : Importez le fichier `nc_bank.sql`.

### 3. Configuration

Éditez le fichier `config.lua` selon vos besoins :

```lua
Config.ServerName = "NorthCounty RP"  -- Nom de votre serveur
Config.MaxTransferAmount = 50000      -- Montant max de virement
Config.TransferFee = 0.02             -- Frais de virement (2%)
Config.EnableInterests = true         -- Activer les intérêts
Config.InterestCycle = 60             -- Cycle d'intérêts en minutes
```

### 4. Ajouter au server.cfg

Ajoutez cette ligne dans votre `server.cfg` :

```cfg
ensure nc_bank
```

### 5. Redémarrer le serveur

```
restart nc_bank
```

## 🎮 Utilisation

### Pour les joueurs

#### Banques
- Rendez-vous dans une banque (marqueur vert sur la carte)
- Appuyez sur **E** pour ouvrir l'interface
- Effectuez vos opérations bancaires

#### ATM (Distributeurs)
- Approchez-vous d'un distributeur automatique
- Appuyez sur **E** pour accéder au menu ATM
- Déposez ou retirez de l'argent (limites réduites)

#### Virements
- Ouvrez l'interface de la banque
- Allez dans la section "Virements"
- Sélectionnez un joueur en ligne
- Entrez le montant et validez
- Des frais de 2% s'appliquent

#### Comptes d'épargne
- Créez jusqu'à 3 comptes d'épargne
- Déposez de l'argent pour bénéficier d'intérêts élevés (10%)
- Les intérêts sont calculés automatiquement

### Commandes

```lua
/bank  -- Ouvrir la banque (en test)
```

## 🔌 Exports

Le script expose des exports pour d'autres ressources :

```lua
-- Ouvrir la banque depuis une autre ressource
exports['nc_bank']:OpenBank()

-- Vérifier si l'UI est ouverte
local isOpen = exports['nc_bank']:IsUIOpen()

-- Ouvrir le menu ATM
exports['nc_bank']:OpenATM()
```

## 📱 Intégration Téléphone

Le script supporte l'intégration avec les systèmes de téléphone courants :
- gcphone
- d-phone
- lb-phone
- qs-phone

### Exemple d'intégration pour gcphone

Ajoutez cette application dans votre téléphone :

```lua
-- Dans gcphone/config.lua ou votre fichier d'apps
{
    name = "bank",
    label = "Banque",
    icon = "bank",
    backgroundColor = "#1e3c72",
    job = nil,
    blockedJobs = {},
    event = "nc_bank:openUI"
}
```

Pour d'autres téléphones, consultez le fichier `PHONE_INTEGRATION.md`.

## 🗺️ Emplacements des banques

Les banques par défaut sont :
- Pacific Standard Bank (Downtown)
- Legion Square Bank
- Great Ocean Highway Bank
- Route 68 Bank
- Paleto Bay Bank
- Del Perro Bank

Vous pouvez ajouter ou modifier les emplacements dans `config.lua`.

## ⚙️ Configuration avancée

### Modifier les taux d'intérêt

```lua
Config.InterestRate = 0.05           -- 5% pour compte courant
Config.SavingsInterestRate = 0.10    -- 10% pour épargne
Config.InterestCycle = 60            -- Tous les 60 minutes
```

### Modifier les limites

```lua
Config.MaxWithdrawal = 20000         -- Retrait max banque
Config.ATMWithdrawLimit = 5000       -- Retrait max ATM
Config.MaxTransferAmount = 50000     -- Virement max
```

### Modifier les frais

```lua
Config.TransferFee = 0.02            -- 2% de frais
Config.MinTransferFee = 10           -- Minimum 10$
Config.MaxTransferFee = 500          -- Maximum 500$
```

## 🐛 Dépannage

### L'interface ne s'ouvre pas
- Vérifiez que ESX est bien démarré
- Vérifiez les erreurs dans la console F8
- Assurez-vous que jQuery est chargé

### Les transactions ne fonctionnent pas
- Vérifiez que les tables SQL sont bien créées
- Vérifiez la connexion MySQL dans server.cfg
- Regardez les logs serveur

### Les ATM ne sont pas détectés
- Les modèles d'ATM sont dans `config.lua`
- Vérifiez que vous êtes bien proche d'un ATM
- Certains objets peuvent ne pas être des ATM valides

## 📝 Structure des fichiers

```
nc_bank/
├── fxmanifest.lua
├── config.lua
├── nc_bank.sql
├── README.md
├── client/
│   ├── main.lua
│   └── atm.lua
├── server/
│   └── main.lua
├── html/
│   ├── index.html
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── app.js
│   └── img/
└── locales/
    └── fr.lua
```

## 📄 License

Ce script est fourni tel quel pour usage sur le serveur NorthCounty RP.

## 🆘 Support

Pour toute question ou problème, contactez l'équipe de développement NorthCounty.

## 🎨 Captures d'écran

L'interface moderne présente :
- Design bleu/gradient élégant
- Navigation intuitive par onglets
- Affichage en temps réel des soldes
- Historique des transactions détaillé
- Gestion des comptes d'épargne

---

Développé avec ❤️ pour NorthCounty RP
