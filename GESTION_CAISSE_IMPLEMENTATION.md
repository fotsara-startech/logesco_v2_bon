# Implémentation de la gestion de caisse améliorée

## Modifications effectuées

### 1. Modèles Flutter créés ✅

#### `cash_session_model.dart`
- Modèle `CashSession` avec toutes les informations nécessaires
- Propriétés : soldeOuverture, soldeFermeture, soldeAttendu, écart, durée
- Enum `SessionPeriodFilter` pour filtrer l'historique (Aujourd'hui, Hier, Cette semaine, etc.)
- Classe `DateRange` pour gérer les périodes personnalisées

### 2. Services Flutter créés ✅

#### `cash_session_service.dart`
- `getActiveSession()` : Récupérer la session active
- `getAvailableCashRegisters()` : Lister les caisses disponibles
- `connectToCashRegister()` : Ouvrir une session
- `disconnectFromCashRegister()` : Clôturer une session
- `getSessionHistory()` : Historique avec filtres de période
- `getSessionStats()` : Statistiques des sessions
- `checkCashRegisterAvailability()` : Vérifier disponibilité

### 3. Contrôleur Flutter créé ✅

#### `cash_session_controller.dart`
- Gestion de la session active
- Connexion/Déconnexion de caisse
- Chargement de l'historique avec filtres
- Affichage du résumé après clôture
- Vérification des permissions (admin uniquement pour voir le solde)

### 4. Widgets Flutter créés ✅

#### `close_cash_session_dialog.dart`
- Dialog de clôture simplifié
- **Caissière** : Ne voit PAS le montant attendu, saisit uniquement ce qu'elle a
- **Admin** : Voit le montant attendu et l'écart prévisionnel
- Calcul automatique de l'écart après clôture
- Instructions claires pour le comptage

#### `cash_session_history_view.dart`
- Page d'historique complète (Admin uniquement)
- Filtres de période : Aujourd'hui, Hier, Cette semaine, etc.
- Période personnalisée avec sélecteur de dates
- Affichage des sessions avec toutes les infos (écart, durée, montants)
- Dialog de détails pour chaque session

## Modifications backend nécessaires

### 1. Impact des dépenses sur la caisse active

Modifier `backend/src/services/financial-movement.js` :

```javascript
async createMovement(data) {
  // ... code existant ...
  
  // Créer le mouvement
  const movement = await this.prisma.financialMovement.create({
    data: {
      // ... données existantes ...
    }
  });
  
  // NOUVEAU : Impacter la caisse active
  await this.updateActiveCashRegister(movement.montant, movement.utilisateurId);
  
  return movement;
}

// NOUVELLE MÉTHODE
async updateActiveCashRegister(montant, utilisateurId) {
  try {
    // Trouver la session active de l'utilisateur
    const activeSession = await this.prisma.cashSession.findFirst({
      where: {
        utilisateurId: utilisateurId,
        dateFermeture: null,
        isActive: true
      },
      include: {
        caisse: true
      }
    });
    
    if (!activeSession) {
      console.log('⚠️ Aucune session active trouvée pour l\'utilisateur');
      return;
    }
    
    // Créer un mouvement de caisse pour tracer la dépense
    await this.prisma.cashMovement.create({
      data: {
        caisseId: activeSession.caisseId,
        type: 'depense',
        montant: -montant, // Négatif car c'est une sortie
        description: 'Dépense enregistrée',
        utilisateurId: utilisateurId,
        dateCreation: new Date()
      }
    });
    
    // Mettre à jour le solde de la caisse
    await this.prisma.cashRegister.update({
      where: { id: activeSession.caisseId },
      data: {
        soldeActuel: {
          decrement: montant // Réduire le solde
        }
      }
    });
    
    console.log(`✅ Caisse ${activeSession.caisse.nom} mise à jour: -${montant} FCFA`);
  } catch (error) {
    console.error('❌ Erreur mise à jour caisse:', error);
    // Ne pas bloquer la création du mouvement si la mise à jour de la caisse échoue
  }
}
```

### 2. Calcul du solde attendu lors de la clôture

Modifier `backend/src/routes/cash-sessions.js` dans la route `/disconnect` :

```javascript
// POST /api/v1/cash-sessions/disconnect
router.post('/disconnect', async (req, res) => {
  try {
    const { soldeFermeture } = req.body;
    const userId = 1; // TODO: Récupérer depuis le token
    
    // Récupérer la session active
    const activeSession = await prisma.cashSession.findFirst({
      where: {
        utilisateurId: userId,
        dateFermeture: null,
        isActive: true
      },
      include: {
        caisse: true,
        utilisateur: true
      }
    });
    
    if (!activeSession) {
      return res.status(404).json({
        success: false,
        error: {
          message: 'Aucune session active trouvée',
          code: 'NO_ACTIVE_SESSION'
        }
      });
    }
    
    // NOUVEAU : Calculer le solde attendu (solde actuel de la caisse)
    const soldeAttendu = activeSession.caisse.soldeActuel;
    const ecart = parseFloat(soldeFermeture) - soldeAttendu;
    
    // Fermer la session avec les calculs
    const closedSession = await prisma.cashSession.update({
      where: { id: activeSession.id },
      data: {
        dateFermeture: new Date(),
        soldeFermeture: parseFloat(soldeFermeture),
        soldeAttendu: soldeAttendu,
        ecart: ecart,
        isActive: false
      },
      include: {
        caisse: true,
        utilisateur: true
      }
    });
    
    // Créer un mouvement de fermeture
    await prisma.cashMovement.create({
      data: {
        caisseId: activeSession.caisseId,
        type: 'fermeture_session',
        montant: parseFloat(soldeFermeture),
        description: `Clôture session - Écart: ${ecart} FCFA`,
        utilisateurId: userId,
        dateCreation: new Date(),
        metadata: {
          soldeAttendu: soldeAttendu,
          soldeFermeture: parseFloat(soldeFermeture),
          ecart: ecart
        }
      }
    });
    
    // Mettre à jour la caisse
    await prisma.cashRegister.update({
      where: { id: activeSession.caisseId },
      data: {
        dateFermeture: new Date(),
        soldeActuel: parseFloat(soldeFermeture) // Mettre le solde déclaré
      }
    });
    
    // Formater la réponse
    const formattedSession = {
      id: closedSession.id,
      caisseId: closedSession.caisseId,
      nomCaisse: closedSession.caisse.nom,
      utilisateurId: closedSession.utilisateurId,
      nomUtilisateur: closedSession.utilisateur.nomUtilisateur,
      soldeOuverture: closedSession.soldeOuverture,
      soldeFermeture: closedSession.soldeFermeture,
      soldeAttendu: closedSession.soldeAttendu,
      ecart: closedSession.ecart,
      dateOuverture: closedSession.dateOuverture,
      dateFermeture: closedSession.dateFermeture,
      isActive: closedSession.isActive
    };
    
    res.json({
      success: true,
      data: formattedSession,
      message: 'Session clôturée avec succès'
    });
    
  } catch (error) {
    console.error('Erreur déconnexion caisse:', error);
    res.status(500).json({
      success: false,
      error: {
        message: 'Erreur serveur',
        code: 'CASH_SESSION_DISCONNECT_ERROR'
      }
    });
  }
});
```

### 3. Affichage du solde pour admin uniquement

Créer un widget pour afficher le solde de la caisse sur le dashboard (admin uniquement) :

```dart
// Dans le dashboard
Obx(() {
  final sessionController = Get.find<CashSessionController>();
  final authController = Get.find<AuthController>();
  
  if (!authController.isAdmin || !sessionController.hasActiveSession) {
    return const SizedBox.shrink();
  }
  
  final balance = sessionController.currentCashBalance ?? 0.0;
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green[600]!, Colors.green[700]!],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solde caisse',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
            Text(
              '${balance.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
})
```

## Flux utilisateur complet

### Ouverture de session
1. Caissière se connecte à l'application
2. Sélectionne une caisse disponible
3. Saisit le solde d'ouverture (argent dans la caisse)
4. Session créée, caisse active

### Pendant la journée
1. **Ventes** : Augmentent automatiquement le solde de la caisse
2. **Dépenses** : Réduisent automatiquement le solde de la caisse
3. **Admin** : Peut voir le solde en temps réel sur le dashboard
4. **Caissière** : Ne voit pas le solde, travaille normalement

### Clôture de session
1. Caissière clique sur "Clôturer la caisse"
2. Dialog s'ouvre :
   - **Caissière** : Voit uniquement le solde d'ouverture et la durée
   - **Admin** : Voit aussi le solde attendu et l'écart prévisionnel
3. Caissière compte l'argent et saisit le montant total
4. Confirmation
5. Backend calcule l'écart automatiquement
6. Dialog de résumé s'affiche avec l'écart
7. Session fermée

### Historique (Admin uniquement)
1. Admin accède à "Historique des sessions"
2. Peut filtrer par période (Aujourd'hui, Cette semaine, etc.)
3. Voit toutes les sessions avec :
   - Solde d'ouverture
   - Solde attendu
   - Solde déclaré
   - Écart (positif ou négatif)
   - Durée de la session
   - Utilisateur
4. Peut cliquer sur une session pour voir les détails complets

## Avantages de cette approche

1. **Transparence** : Toutes les transactions impactent la caisse en temps réel
2. **Traçabilité** : Chaque mouvement est enregistré
3. **Contrôle** : L'admin voit le solde attendu, la caissière ne le voit pas
4. **Simplicité** : La caissière compte juste ce qu'elle a
5. **Automatisation** : Les écarts sont calculés automatiquement
6. **Historique** : Toutes les sessions sont archivées avec détails
7. **Filtrage** : Recherche facile par période

## Prochaines étapes

1. ✅ Créer les modèles, services et contrôleurs Flutter
2. ✅ Créer les widgets de clôture et d'historique
3. ⏳ Modifier le backend pour impacter la caisse lors des dépenses
4. ⏳ Modifier la route de clôture pour calculer l'écart
5. ⏳ Ajouter le widget de solde sur le dashboard (admin uniquement)
6. ⏳ Tester le flux complet
7. ⏳ Ajouter les permissions pour l'historique (admin uniquement)
