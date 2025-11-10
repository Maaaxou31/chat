# 📱 Intégration Téléphone - NorthCounty Bank

Ce guide vous explique comment intégrer l'application bancaire à différents systèmes de téléphone FiveM.

## 🔧 Configuration générale

Dans `nc_bank/config.lua`, configurez le nom de votre ressource téléphone :

```lua
Config.PhoneResource = "gcphone"  -- Changer selon votre téléphone
Config.EnablePhoneApp = true
```

## 📱 GCPhone

### 1. Ajouter l'application

Dans `gcphone/config.lua`, ajoutez :

```lua
{
    app = "bank",
    display = true,
    color = "#1e3c72",
    icon = "fa fa-university",
    label = "Banque",
    job = nil,
    blockedJobs = {},
}
```

### 2. Créer le fichier d'application

Créez `gcphone/html/static/app/bank.html` :

```html
<div id="bank-app" class="app">
    <iframe src="nui://nc_bank/html/index.html" style="width:100%;height:100%;border:none;"></iframe>
</div>
```

### 3. Event handler

Dans `gcphone/client.lua`, ajoutez :

```lua
RegisterNUICallback('openBank', function(data, cb)
    TriggerEvent('nc_bank:openUI')
    cb('ok')
end)
```

## 📱 QS-Phone (Quasar Phone)

### 1. Configuration

Dans `qs-smartphone/shared/config.lua`, ajoutez dans `Config.CustomApps` :

```lua
['bank'] = {
    app = "bank",
    icon = "fas fa-university",
    label = "Banque",
    color = "#1e3c72",
    job = false,
    blockedJobs = {},
    timeout = 0,
    creator = "NorthCounty",
    isGame = false,
    description = "Gérez vos finances",
}
```

### 2. Créer le fichier app

Créez `qs-smartphone/html/apps/bank.html` :

```html
<div class="bank-wrapper">
    <iframe src="nui://nc_bank/html/index.html" frameborder="0"></iframe>
</div>
```

### 3. Style

Dans `qs-smartphone/html/css/apps.css`, ajoutez :

```css
.bank-wrapper iframe {
    width: 100%;
    height: 100%;
}
```

## 📱 D-Phone

### 1. Configuration

Dans `d-phone/config.lua`, ajoutez :

```lua
Config.Apps["bank"] = {
    app = "bank",
    display = true,
    icon = "bank",
    color = "#1e3c72",
    label = "Banque",
    job = false,
}
```

### 2. Event

Dans `d-phone/client/apps/bank.lua`, créez :

```lua
RegisterNUICallback('openBankApp', function(data, cb)
    SetNuiFocus(false, false)
    TriggerEvent('nc_bank:openUI')
    cb('ok')
end)
```

## 📱 LB-Phone (Lation Phone)

### 1. Ajouter dans les apps

Dans `lb-phone/config.lua` :

```lua
{
    identifier = 'bank',
    label = 'Banque',
    icon = 'university',
    color = '#1e3c72',
    job = nil,
    blockedJobs = {},
}
```

### 2. Créer l'app

Créez `lb-phone/ui/src/apps/Bank.vue` :

```vue
<template>
  <div class="bank-container">
    <iframe src="nui://nc_bank/html/index.html" />
  </div>
</template>

<script>
export default {
  name: 'Bank',
  mounted() {
    // App loaded
  }
}
</script>

<style scoped>
.bank-container {
  width: 100%;
  height: 100%;
}

iframe {
  width: 100%;
  height: 100%;
  border: none;
}
</style>
```

## 📱 Intégration Custom

Si vous avez un système de téléphone personnalisé, voici l'approche générale :

### 1. Ajouter un bouton/icône dans le téléphone

```html
<button onclick="openBankApp()">
    <i class="fas fa-university"></i>
    Banque
</button>
```

### 2. JavaScript pour ouvrir l'app

```javascript
function openBankApp() {
    // Fermer le téléphone
    closePhone();

    // Ouvrir la banque
    fetch('https://nc_bank/openBankFromPhone', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}
```

### 3. Côté serveur (client.lua de nc_bank)

Ajoutez dans `nc_bank/client/main.lua` :

```lua
RegisterNUICallback('openBankFromPhone', function(data, cb)
    OpenBankUI()
    cb('ok')
end)
```

## 🎯 Alternative : Iframe dans le téléphone

Si votre téléphone supporte les iframes, vous pouvez directement intégrer l'interface :

```html
<iframe
    src="nui://nc_bank/html/index.html"
    style="width: 100%; height: 100%; border: none;"
    id="bank-iframe">
</iframe>
```

## 📞 Events disponibles

Depuis n'importe quel téléphone, vous pouvez utiliser ces events :

```lua
-- Ouvrir la banque
TriggerEvent('nc_bank:openUI')

-- Vérifier si ouverte
local isOpen = exports['nc_bank']:IsUIOpen()

-- Mettre à jour le solde
TriggerEvent('nc_bank:updateBalance', bankMoney, cashMoney)
```

## 🔄 Communication Téléphone <-> Banque

### Envoyer des données depuis le téléphone

```javascript
// Depuis votre téléphone
fetch('https://nc_bank/getAccountInfo', {
    method: 'POST',
    body: JSON.stringify({})
}).then(response => response.json())
  .then(data => {
      console.log('Solde:', data.balance);
  });
```

### Recevoir des notifications

```lua
-- Dans votre téléphone client.lua
RegisterNetEvent('nc_bank:updateBalance')
AddEventHandler('nc_bank:updateBalance', function(balance, cash)
    -- Mettre à jour l'affichage du téléphone
    SendNUIMessage({
        action = 'updateBankDisplay',
        balance = balance,
        cash = cash
    })
end)
```

## 🎨 Adapter le style au téléphone

Si vous voulez que l'interface s'adapte au style de votre téléphone, créez un CSS custom :

```css
/* phone-bank-style.css */
.bank-wrapper {
    /* Adapter au format du téléphone */
    max-width: 500px;
    max-height: 900px;
    border-radius: 30px;
}

.bank-header {
    /* Style adapté */
    padding: 10px 15px;
}
```

## 📝 Exemple complet : Mini-app pour téléphone

Créez un fichier `nc_bank/html/phone.html` pour une version téléphone simplifiée :

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Bank App</title>
    <style>
        body {
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            font-family: Arial, sans-serif;
            padding: 20px;
            color: white;
        }
        .balance {
            font-size: 48px;
            font-weight: bold;
            text-align: center;
            margin: 40px 0;
        }
        .quick-actions button {
            width: 100%;
            padding: 15px;
            margin: 10px 0;
            font-size: 18px;
            border: none;
            border-radius: 10px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <h1>💰 Ma Banque</h1>
    <div class="balance" id="balance">$0</div>
    <div class="quick-actions">
        <button onclick="quickDeposit()">Déposer 1000$</button>
        <button onclick="quickWithdraw()">Retirer 500$</button>
        <button onclick="openFullBank()">Ouvrir la banque</button>
    </div>

    <script>
        function quickDeposit() {
            fetch('https://nc_bank/deposit', {
                method: 'POST',
                body: JSON.stringify({ amount: 1000 })
            });
        }

        function quickWithdraw() {
            fetch('https://nc_bank/withdraw', {
                method: 'POST',
                body: JSON.stringify({ amount: 500 })
            });
        }

        function openFullBank() {
            fetch('https://nc_bank/openFullInterface', {
                method: 'POST',
                body: JSON.stringify({})
            });
        }
    </script>
</body>
</html>
```

## ✅ Checklist d'intégration

- [ ] Identifier votre système de téléphone
- [ ] Ajouter l'application dans la configuration du téléphone
- [ ] Créer les fichiers nécessaires (HTML/Vue/React selon le téléphone)
- [ ] Ajouter les events de communication
- [ ] Tester l'ouverture de l'app
- [ ] Tester les transactions
- [ ] Vérifier les notifications
- [ ] Adapter le style si nécessaire

## 🆘 Problèmes courants

### L'iframe ne se charge pas
- Vérifiez que l'URL est correcte : `nui://nc_bank/html/index.html`
- Assurez-vous que `ui_page` est défini dans `fxmanifest.lua`

### Les callbacks ne fonctionnent pas
- Vérifiez que les NUICallbacks sont bien enregistrés
- Utilisez la console F8 pour voir les erreurs

### Conflit de style
- Créez une version spécifique pour téléphone
- Utilisez des classes CSS spécifiques

---

**Besoin d'aide ?** Consultez la documentation de votre système de téléphone ou contactez le support NorthCounty.
