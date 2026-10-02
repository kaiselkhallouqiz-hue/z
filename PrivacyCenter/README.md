# Privacy Center V1

Projet SwiftUI de base pour une app iOS orientée confidentialité.

## Fonctionnalités V1

- Dashboard de sécurité
- Mode Panic local
- Coffre-fort chiffré AES-GCM
- Clé du coffre stockée dans le Keychain
- Authentification Face ID
- Import/gestion de fichiers du coffre (base à compléter avec PhotosPicker)
- Analyse des éléments Photos par période
- Accès aux réglages système
- Centre Privacy Scan
- Paramètre de verrouillage automatique
- Interface sombre type iOS

## Limites importantes d'iOS

Une IPA classique ne peut pas :

- modifier directement le code de déverrouillage de l'iPhone ;
- changer le code de l'iPhone à distance ;
- cacher arbitrairement Snapchat, TikTok, Instagram ou une autre app ;
- administrer secrètement tout l'iPhone ;
- effacer arbitrairement les données d'une autre application.

Pour le contrôle d'autres apps, les API Screen Time / FamilyControls peuvent être étudiées, mais elles nécessitent les autorisations et capacités Apple appropriées.

## Compilation

La compilation/signature iOS nécessite Xcode sur macOS.

1. Créer un nouveau projet iOS SwiftUI nommé `PrivacyCenter`.
2. Remplacer les fichiers Swift par ceux de ce dossier.
3. Ajouter les clés Info.plist indiquées.
4. Activer Face ID / capacités nécessaires.
5. Sélectionner une Team Apple dans Signing & Capabilities.
6. Build sur un iPhone ou Archive.
7. Exporter/signature selon le compte Apple utilisé.

## Important

Le fichier PhotoManager contient volontairement une action d'analyse et non une suppression/masquage arbitraire de la photothèque. Les opérations Photos réelles doivent être implémentées avec les API autorisées par la version d'iOS ciblée et avec une confirmation explicite avant toute modification.
