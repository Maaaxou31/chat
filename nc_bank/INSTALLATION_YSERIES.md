# Installation de NC Bank dans yseries

## 📱 Intégration avec le téléphone yseries

### Étape 1: Enregistrer l'application

Il y a **2 méthodes** pour enregistrer l'app dans yseries:

---

### **MÉTHODE 1: Via le dossier yseries-apps (RECOMMANDÉ)**

1. **Copiez le fichier** `nc_bank/phone/bank_app.lua` dans le dossier `yseries-apps/`

   ```bash
   # Depuis le dossier resources/
   cp nc_bank/phone/bank_app.lua yseries-apps/nc_bank.lua
   ```

2. **Redémarrez yseries**
   ```
   restart yseries
   restart nc_bank
   ```

L'app devrait maintenant apparaître dans le téléphone! 📱

---

### **MÉTHODE 2: Via la configuration yseries**

Si yseries utilise un fichier de configuration pour les apps:

1. **Ouvrez** `yseries/config.lua` ou `yseries/apps.lua`

2. **Ajoutez** cette configuration:

```lua
-- Dans la liste des applications
{
    id = "nc_bank",
    name = "NC Bank",
    icon = "https://cdn-icons-png.flaticon.com/512/2830/2830284.png",
    ui = "nc_bank/phone/index.html",

    open = function()
        TriggerEvent('nc_bank:openPhoneApp')
    end,

    close = function()
        -- Cleanup
    end
}
```

3. **Dans `nc_bank/client/main.lua`**, l'event `nc_bank:openPhoneApp` existe déjà aux lignes 291-295

---

## 🔧 Configuration des numéros de téléphone

**IMPORTANT:** D'après vos logs, yseries utilise ses propres tables pour les numéros de téléphone.

### Vérifier où yseries stocke les numéros

Exécutez cette requête SQL pour trouver la table:

```sql
-- Lister toutes les tables liées au téléphone
SHOW TABLES LIKE '%phone%';
```

Résultats possibles:
- `yphone_users` ✅
- `yseries_contacts` ✅
- `phone_users` ✅
- `users.phone_number` ✅

### Adapter la requête SQL

Une fois que vous savez où yseries stocke les numéros, modifiez **`nc_bank/server/main.lua` ligne 966**:

**Option 1: Si yseries utilise `yphone_users`**
```lua
-- Ligne 966
local result = MySQL.query.await('SELECT identifier FROM yphone_users WHERE phone_number = ? LIMIT 1', {phoneNumber})
```

**Option 2: Si yseries stocke les numéros dans une colonne spécifique**
```lua
-- Ligne 966
local result = MySQL.query.await('SELECT identifier FROM users WHERE phone = ? LIMIT 1', {phoneNumber})
```

**Option 3: Utiliser l'export yseries (si disponible)**
```lua
-- Remplacer les lignes 959-982
local targetIdentifier = exports['yseries']:GetIdentifierFromPhone(phoneNumber)

if not targetIdentifier then
    TriggerClientEvent('esx:showNotification', source, 'Numéro de téléphone introuvable')
    return
end
```

---

## 📊 Base de données

### 1. Exécuter le script SQL

```sql
source nc_bank/phone_number_column.sql
```

Ou si vous utilisez les tables yseries, **vérifiez d'abord**:

```sql
-- Vérifier la structure de la table utilisée par yseries
DESCRIBE yphone_users;
-- OU
DESCRIBE users;
```

### 2. Colonnes nécessaires

Yseries devrait déjà avoir:
- Un identifiant joueur (`identifier`, `citizenid`, etc.)
- Un numéro de téléphone (`phone_number`, `phone`, `phoneNumber`, etc.)

**Notez le nom exact** et adaptez la requête SQL dans `server/main.lua` ligne 966.

---

## 🧪 Test de l'installation

1. **Démarrer le serveur**
   ```
   start nc_bank
   start yseries
   ```

2. **En jeu:**
   - Ouvrir le téléphone (généralement: Flèche Haut)
   - Chercher l'app "NC Bank" ou "Bank"
   - Ouvrir l'app

3. **Tester un virement:**
   - Entrer un numéro de téléphone valide
   - Entrer un montant
   - Cliquer sur "Envoyer"

---

## ❌ Dépannage

### L'app n'apparaît pas dans yseries

**Solution 1:** Vérifier que le fichier est au bon endroit
```bash
ls yseries-apps/nc_bank.lua
# OU
ls yseries/apps/nc_bank.lua
```

**Solution 2:** Vérifier les logs serveur
```
restart yseries
restart nc_bank
```
Regardez F8 pour voir les erreurs

**Solution 3:** Vérifier la structure de yseries
Certaines versions de yseries utilisent:
- `yseries-apps/` (dossier séparé)
- `yseries/apps/` (sous-dossier)
- `yseries/config.lua` (fichier config)

### Le virement ne fonctionne pas

**Erreur: "Numéro de téléphone introuvable"**

1. Vérifiez quelle table utilise yseries:
   ```sql
   SELECT * FROM yphone_users LIMIT 1;
   -- OU
   SELECT phone_number FROM users LIMIT 1;
   ```

2. Modifiez la ligne 966 de `server/main.lua` avec le bon nom de table/colonne

3. Vérifiez qu'un joueur a bien un numéro:
   ```sql
   SELECT identifier, phone_number FROM users WHERE phone_number IS NOT NULL LIMIT 5;
   ```

---

## 📝 Récapitulatif

1. ✅ Copier `bank_app.lua` dans `yseries-apps/`
2. ✅ Redémarrer yseries et nc_bank
3. ✅ Vérifier la table des numéros de téléphone
4. ✅ Adapter la requête SQL ligne 966 si nécessaire
5. ✅ Tester en jeu

---

## 🆘 Besoin d'aide?

Si vous ne savez pas quelle table yseries utilise, exécutez:

```sql
SHOW TABLES LIKE '%phone%';
SHOW TABLES LIKE '%yseries%';
```

Et envoyez-moi le résultat pour que je puisse vous dire exactement quelle requête SQL utiliser.
