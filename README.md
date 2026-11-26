# Mon budget

Application web pour gérer son budget mensuel et savoir, chaque mois, si l'on peut épargner.
Chaque personne crée son compte et ne voit que ses propres données.

## Fonctions

- Budget du mois : revenus, charges fixes (avec jour de prélèvement), budgets par poste, objectif d'épargne, marge de sécurité.
- Prélèvements automatiques (version 4) : le jour d'un prélèvement, d'un abonnement ou d'un revenu prévu, l'opération est proposée « À confirmer » sur l'Accueil (un toucher), ou créée toute seule en mode automatique.
- Saisie rapide d'une dépense (montant, catégorie, date), saisie express en une phrase (« courses 23,50 carrefour »), dictée quand le navigateur la permet.
- Photo d'un ticket de caisse lue directement sur le téléphone (version 4) : montant, date, enseigne et catégorie proposés. Aucune photo n'est envoyée.
- Code à 4 chiffres et Face ID / Touch ID à l'ouverture (version 4), propres à chaque appareil.
- Hors connexion (version 4) : l'application s'ouvre et se remplit sans réseau ; les saisies partent dès que la connexion revient.
- Sauvegarde complète téléchargeable et restaurable (version 4), en plus de l'export CSV des opérations.
- Page « Confidentialité et mentions légales » (version 4).
- Alerte immédiate en cas de dépassement d'un budget.
- Échéancier des prélèvements et solde « vraiment disponible » après recalage avec le solde bancaire.
- Projets d'épargne : objectif, date cible, montant conseillé par mois, versements et retraits.
- Abonnements : coût par mois et par an, prochains prélèvements, reprise du total dans le budget.
- Thème clair, sombre ou automatique ; écran de bienvenue ; photos du bandeau personnelles et illustrations de saison.
- Suppression du compte et de toutes les données.

## Structure

| Fichier | Rôle |
|---|---|
| `index.html` | L'application complète |
| `sw.js` | Service worker : copie de l'application sur le téléphone pour l'ouvrir sans réseau |
| `config.js` | Adresse et clé publique du projet Supabase (à remplir) |
| `supabase/schema.sql` | Installation complète : tables, règles de sécurité, stockage des photos, suppression de compte |
| `supabase/migration_v2.sql` | Mise à jour d'une base existante vers la version 2 (projets, abonnements) |
| `manifest.webmanifest`, `icons/` | Installation sur l'écran d'accueil |
| `vendor/supabase.js` | Bibliothèque supabase-js 2.118.0 (licence MIT) |
| `vendor/ocr/` | Lecture des tickets : Tesseract.js 7.0.0 et tesseract.js-core 7.0.0 (licence Apache 2.0), modèle français (voir les fichiers LICENSE) |
| `vendor/fonts/` | Police Manrope (licence SIL Open Font), hébergée avec l'application |
| `photos/` | Illustrations de fond par saison |

La version 4 ne demande aucune modification de la base de données.

## Réglage facultatif

Dans `config.js`, une ligne `region: "Union européenne (Paris)"` (à adapter) ajoute la région des serveurs Supabase dans les mentions légales.

## Mise en route

1. Créer un projet Supabase (région Europe), puis exécuter `supabase/schema.sql` dans *SQL Editor*.
2. Copier l'URL du projet et la clé *publishable* dans `config.js`. Ne jamais y mettre la clé secrète.
3. Dans Supabase, *Authentication > URL Configuration* : mettre l'adresse GitHub Pages de l'application dans *Site URL* et dans *Redirect URLs*.
4. Sur GitHub : *Settings > Pages > Deploy from a branch > main / (root)*.

## Crédits

- Illustrations de fond : images générées par IA, issues de la banque d'images libre de droits [smithable-images](https://github.com/smithable/smithable-images) (licence CC0). Ce ne sont pas de vraies photographies.
- Police Manrope (licence SIL Open Font), fichiers issus de Fontsource.
- [supabase-js](https://github.com/supabase/supabase-js) (licence MIT).
- [Tesseract.js](https://github.com/naptha/tesseract.js) et tesseract.js-core (licence Apache 2.0) ; modèle français issu de tessdata (Apache 2.0), paquet @tesseract.js-data/fra (MIT).
