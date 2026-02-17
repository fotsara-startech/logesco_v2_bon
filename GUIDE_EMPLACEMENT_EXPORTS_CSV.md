# 📁 Guide - Emplacement des fichiers Excel exportés

## 🎯 **Résumé**
Le module gestion de stock utilise maintenant **exactement la même approche** que le module gestion de produits pour sauvegarder les fichiers exportés au **format Excel (.xlsx)**.

## 📍 **Emplacements de stockage**

### **🌐 Web (Navigateur)**
```
📁 Dossier de téléchargements par défaut du navigateur
Windows: C:\Users\[Utilisateur]\Downloads\
macOS: /Users/[Utilisateur]/Downloads/
Linux: /home/[utilisateur]/Downloads/
```

### **📱 Mobile & 💻 Desktop**

#### **Sauvegarde automatique dans Documents**
```
📁 Dossier Documents de l'utilisateur
Windows: C:\Users\[Utilisateur]\Documents\
macOS: /Users/[Utilisateur]/Documents/
Android: /storage/emulated/0/Documents/
iOS: /var/mobile/Containers/Data/Application/[ID]/Documents/
```

## 📋 **Noms des fichiers générés**

### **Format des noms de fichiers**
```
stocks_export_[timestamp].xlsx
mouvements_stock_export_[timestamp].xlsx
```

### **Exemple concret**
```
stocks_export_1734048000000.xlsx
mouvements_stock_export_1734048000000.xlsx
```

Le timestamp est en millisecondes depuis l'époque Unix, garantissant l'unicité des noms de fichiers.

## 🔄 **Processus d'export Excel**

### **1. Récupération des données**
- Le backend génère les données au format CSV
- L'application Flutter récupère ces données via l'API

### **2. Conversion CSV → Excel**
- Le service ExportService parse les données CSV
- Création d'un fichier Excel (.xlsx) avec formatage
- En-têtes colorés et colonnes ajustées automatiquement

### **3. Sauvegarde locale**
- Le fichier Excel est sauvegardé dans le dossier Documents
- Un nom unique est généré avec timestamp

### **4. Dialog de confirmation**
- L'utilisateur voit un message de succès
- Option pour partager le fichier Excel immédiatement

### **5. Partage (optionnel)**
- Utilise le système de partage natif
- L'utilisateur peut choisir où envoyer/sauvegarder le fichier Excel

## 🔍 **Comment retrouver vos fichiers**

### **Windows**
1. Ouvrir l'Explorateur de fichiers
2. Aller dans `Ce PC > Documents`
3. Chercher les fichiers `*_export_*.xlsx`
4. Double-cliquer pour ouvrir avec Excel

### **macOS**
1. Ouvrir le Finder
2. Aller dans `Documents`
3. Chercher les fichiers `*_export_*.xlsx`
4. Double-cliquer pour ouvrir avec Excel ou Numbers

### **Android**
1. Ouvrir l'application Fichiers
2. Aller dans `Documents`
3. Chercher les fichiers `*_export_*.xlsx`
4. Ouvrir avec Excel, Google Sheets ou WPS Office

### **iOS**
1. Ouvrir l'application Fichiers
2. Aller dans `Sur mon iPhone > LOGESCO` (si disponible)
3. Ou utiliser la fonction de partage pour sauvegarder ailleurs
4. Ouvrir avec Excel, Numbers ou Google Sheets

## 🛠️ **Fonctionnalités disponibles**

### **Export des stocks (Excel)**
- ✅ Référence produit, nom, quantités
- ✅ Seuils minimum, prix (unitaire/achat)
- ✅ Valeurs de stock (vente/achat)
- ✅ Statut (Normal/Alerte/Rupture)
- ✅ Dernière mise à jour
- ✅ **Formatage Excel** : En-têtes colorés, colonnes ajustées
- ✅ **Compatible Excel** : Ouverture directe dans Excel/LibreOffice

### **Export des mouvements (Excel)**
- ✅ Date et heure du mouvement
- ✅ Informations produit (référence, nom)
- ✅ Type de mouvement (vente, achat, ajustement, etc.)
- ✅ Changement de quantité
- ✅ Références liées (vente, commande, etc.)
- ✅ Notes explicatives
- ✅ **Formatage Excel** : En-têtes colorés, colonnes ajustées
- ✅ **Compatible Excel** : Ouverture directe dans Excel/LibreOffice

## 🎉 **Avantages du format Excel**

1. **Cohérence** : Même comportement que le module produits
2. **Fiabilité** : Fichiers sauvegardés localement
3. **Flexibilité** : Option de partage immédiat
4. **Simplicité** : Un seul clic pour exporter
5. **Traçabilité** : Noms de fichiers uniques avec timestamp
6. **🆕 Formatage professionnel** : En-têtes colorés et mise en forme
7. **🆕 Compatibilité universelle** : Ouverture dans Excel, LibreOffice, Google Sheets
8. **🆕 Manipulation avancée** : Tri, filtres, formules Excel disponibles

## 📞 **Support**

Si vous ne trouvez pas vos fichiers exportés :
1. Vérifiez le dossier Documents de votre système
2. Utilisez la fonction de recherche avec `*export*.xlsx`
3. Lors de l'export, notez le nom du fichier affiché dans le dialog
4. Utilisez l'option "Partager" pour sauvegarder dans un autre emplacement
5. **Nouveau** : Double-cliquez sur le fichier .xlsx pour l'ouvrir directement dans Excel

---

**Note** : Cette implémentation garantit que vos exports Excel sont toujours sauvegardés localement avec un formatage professionnel, même si vous choisissez de ne pas les partager immédiatement.