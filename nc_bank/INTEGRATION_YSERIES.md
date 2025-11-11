# Intégration de NC Bank avec yseries

## Configuration requise

- yseries (téléphone)
- yseries-props
- inventory-items
- ESX Framework

## Étapes d'intégration

### 1. Configuration de la base de données

Vérifiez que la table `users` contient une colonne `phone_number`:

```sql
-- Si la colonne n'existe pas, ajoutez-la:
ALTER TABLE `users` ADD COLUMN `phone_number` VARCHAR(20) DEFAULT NULL;
```

**Note:** Si yseries utilise une table différente pour les numéros de téléphone, vous devrez modifier la requête SQL dans `/nc_bank/server/main.lua` à la ligne 966:

```lua
-- Ligne 966 - Adapter selon votre système
local result = MySQL.query.await('SELECT identifier FROM users WHERE phone_number = ? LIMIT 1', {phoneNumber})
```

### 2. Enregistrement de l'application dans yseries-props

Ajoutez l'application bancaire dans votre fichier de configuration `yseries-props`:

```lua
-- Dans yseries-props/config.lua ou apps.lua
{
    id = "nc_bank",
    name = "Bank",
    icon = "https://cdn-icons-png.flaticon.com/512/2830/2830284.png",
    ui = "nc_bank/phone/index.html",

    open = function()
        TriggerEvent('nc_bank:openPhoneApp')
    end,

    close = function()
        -- Cleanup si nécessaire
    end
}
```

### 3. Configuration dans fxmanifest.xml

Assurez-vous que le `fxmanifest.lua` de nc_bank inclut les fichiers du téléphone:

```lua
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/fonts/*.ttf',

    -- Fichiers pour l'app téléphone
    'phone/index.html',
    'phone/style.css',
    'phone/app.js'
}
```

### 4. Event d'ouverture de l'app téléphone

Dans votre `client/main.lua`, ajoutez un event pour ouvrir l'app depuis yseries:

```lua
-- Cet event devrait déjà être présent dans votre code
RegisterNetEvent('nc_bank:openPhoneApp', function()
    ESX.TriggerServerCallback('nc_bank:getPhoneAccountInfo', function(data)
        if data then
            SendNUIMessage({
                app = "nc_bank",
                action = "openPhoneBank",
                data = data
            })
        end
    end)
end)
```

### 5. Notifications yseries (optionnel)

Si vous souhaitez utiliser les notifications de yseries au lieu de ESX, modifiez les notifications dans:

**server/main.lua (lignes 933, 949, 955, 980, 996, 1007, 1024, 1027):**

Remplacez:
```lua
TriggerClientEvent('esx:showNotification', source, 'Message')
```

Par:
```lua
TriggerClientEvent('yseries:notification', source, {
    title = 'NC Bank',
    message = 'Message',
    type = 'success' -- ou 'error', 'warning', etc.
})
```

**phone/app.js (lignes 98, 103):**

Remplacez les commentaires par:
```javascript
// Notification via yseries
exports.yseries.notification({
    title: 'NC Bank',
    message: 'Message d\'erreur',
    type: 'error'
});
```

## Fonctionnalités de l'app téléphone

### Virement par numéro de téléphone

L'application permet d'effectuer des virements en utilisant le numéro de téléphone du destinataire au lieu de l'IBAN.

**Caractéristiques:**
- Format du numéro: Texte libre (ex: "555-1234")
- Frais de virement: 1% (minimum 5$, maximum 250$)
- Vérification du solde avant virement
- Notifications pour l'expéditeur et le destinataire
- Mise à jour automatique de l'interface

### Affichage du solde

- Solde actuel du compte personnel
- IBAN du compte
- 5 dernières transactions

### Transactions récentes

Affiche les 5 dernières transactions avec:
- Type de transaction (dépôt, retrait, virement)
- Montant avec signe (+ ou -)
- Date et heure
- Icône selon le type

## Test de l'intégration

1. **Démarrer le serveur** avec nc_bank et yseries
2. **Ouvrir le téléphone** en jeu
3. **Lancer l'app "Bank"** depuis le menu du téléphone
4. **Vérifier l'affichage** du solde et des transactions
5. **Tester un virement** en entrant un numéro de téléphone valide

## Dépannage

### L'app ne s'affiche pas dans yseries
- Vérifiez que l'app est bien enregistrée dans yseries-props
- Vérifiez que les fichiers phone/*.html, *.css, *.js sont bien dans le dossier nc_bank/phone/
- Redémarrez la ressource: `restart nc_bank`

### Le virement par numéro ne fonctionne pas
- Vérifiez que la colonne `phone_number` existe dans la table `users`
- Vérifiez les logs serveur pour voir les erreurs SQL
- Assurez-vous que le joueur cible a bien un numéro de téléphone enregistré

### Les transactions ne s'affichent pas
- Ouvrez la console F12 du téléphone pour voir les erreurs JavaScript
- Vérifiez que le callback `nc_bank:getPhoneAccountInfo` fonctionne
- Vérifiez que le joueur a bien un compte bancaire créé

## Support

Si vous rencontrez des problèmes, vérifiez:
1. Les logs serveur (F8)
2. La console navigateur (F12) dans le téléphone
3. Que tous les fichiers sont bien présents
4. Que la base de données est correctement configurée
