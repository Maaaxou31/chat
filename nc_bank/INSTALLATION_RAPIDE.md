# Installation rapide NC Bank avec yseries

## 📱 Remplacer l'app Banking de yseries

### Étape 1: Copier le fichier banking.lua

**Sur votre serveur FiveM**, copiez le fichier:

```bash
# DEPUIS:
resources/[banking]/nc_bank/phone/banking.lua

# VERS:
resources/yseries-apps/banking.lua
```

**OU** si `yseries-apps` n'existe pas, créez le dossier à côté de `yseries`:

```
resources/
  ├── yseries/
  └── yseries-apps/      <-- Créez ce dossier
      └── banking.lua    <-- Copiez le fichier ici
```

### Étape 2: Redémarrer les ressources

Dans la console serveur:
```
restart yseries
restart nc_bank
```

### Étape 3: Tester

**En jeu:**
- Ouvrez le téléphone (Flèche Haut)
- Cliquez sur l'app "Banking" ou "Banque"
- L'interface NC Bank devrait s'ouvrir

**Ou utilisez la commande:**
```
/banque
```

---

## ✅ Ce qui devrait fonctionner

- ✅ L'app "Banking" dans yseries ouvre NC Bank
- ✅ Commande `/banque` pour ouvrir directement
- ✅ Affichage du solde et IBAN
- ✅ Virement par numéro de téléphone
- ✅ 5 dernières transactions
- ✅ Bouton fermer (✕) en haut à droite

---

## ❌ Résolution des problèmes

### Erreur: "L'application bancaire a besoin d'une conf supplémentaire"

**Cause:** yseries cherche ses propres callbacks bancaires

**Solution:** Vérifiez que le fichier `server/yseries_bridge.lua` est bien chargé:
```
restart nc_bank
```

Dans les logs, vous devriez voir:
```
[NC_BANK] Bridge yseries chargé avec succès!
```

### Erreur: "Commande invalide - /banque"

**Cause:** nc_bank n'est pas démarré ou mal configuré

**Solution:**
```
restart nc_bank
```

### L'app Banking n'apparaît pas dans le téléphone

**Cause:** Le fichier `banking.lua` n'est pas au bon endroit

**Solution:** Vérifiez que le fichier est bien dans `yseries-apps/banking.lua` avec l'ID "banking" (pas "nc_bank")

### Table 'yphone_banking_transactions' doesn't exist

**Cette erreur est normale!** C'est yseries qui cherche sa propre table bancaire. Ignorez cette erreur - nc_bank utilise ses propres tables (`nc_bank_accounts`, `nc_bank_transactions`).

---

## 📊 Base de données

### Tables utilisées par nc_bank:

- `nc_bank_accounts` - Comptes bancaires
- `nc_bank_transactions` - Transactions
- `nc_bank_business_accounts` - Comptes entreprise
- `nc_bank_business_employees` - Employés

### Virement par numéro de téléphone:

Le système cherche les numéros dans `users.phone_number`. Si votre yseries utilise une autre table, modifiez la ligne 966 de `server/main.lua`:

```lua
-- ACTUEL (ligne 966):
local result = MySQL.query.await('SELECT identifier FROM users WHERE phone_number = ? LIMIT 1', {phoneNumber})

-- Si yseries utilise une autre table, changez en:
local result = MySQL.query.await('SELECT identifier FROM yphone_users WHERE phone = ? LIMIT 1', {phoneNumber})
```

---

## 🆘 Besoin d'aide?

Si ça ne fonctionne toujours pas, envoyez-moi:

1. Le contenu de `yseries-apps/banking.lua`
2. Les logs serveur après `restart nc_bank`
3. L'erreur exacte affichée en jeu

---

## 📝 Récapitulatif

1. ✅ Copier `nc_bank/phone/banking.lua` dans `yseries-apps/banking.lua`
2. ✅ Vérifier que `server/yseries_bridge.lua` est chargé
3. ✅ Redémarrer: `restart yseries` et `restart nc_bank`
4. ✅ Tester avec `/banque` ou dans le téléphone
