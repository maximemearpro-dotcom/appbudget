# Mon budget

Application web pour gérer son budget mensuel et savoir, chaque mois, si l'on peut épargner.
Chaque personne crée son compte et ne voit que ses propres données.

## Fonctions

- Budget du mois : revenus, charges fixes (avec jour de prélèvement), budgets variables, objectif d'épargne, marge de sécurité.
- Saisie rapide d'une dépense (montant, catégorie, date), saisie express en une phrase (« courses 23,50 carrefour »), dictée quand le navigateur la permet.
- Alerte immédiate en cas de dépassement d'un budget.
- Onglets Mois, Graphiques, Opérations et Bilan sur 12 mois.
- Échéancier des prélèvements et solde « vraiment disponible » après recalage avec le solde bancaire.
- Photos de fond personnelles (stockées dans un dossier privé) et illustrations de saison par défaut.
- Export CSV compatible Excel, suppression du compte et de toutes les données.

## Structure

| Fichier | Rôle |
|---|---|
| `index.html` | L'application complète |
| `config.js` | Adresse et clé publique du projet Supabase (à remplir) |
| `supabase/schema.sql` | Tables, règles de sécurité, stockage des photos, suppression de compte |
| `manifest.webmanifest`, `icons/` | Installation sur l'écran d'accueil |
| `vendor/supabase.js` | Bibliothèque supabase-js 2.118.0 (licence MIT, voir `vendor/LICENSE-supabase-js.txt`) |
| `photos/` | Illustrations de fond par saison |

## Mise en route

1. Créer un projet Supabase (région Europe), puis exécuter `supabase/schema.sql` dans *SQL Editor*.
2. Copier l'URL du projet et la clé *publishable* dans `config.js`. Ne jamais y mettre la clé secrète.
3. Dans Supabase, *Authentication > URL Configuration* : mettre l'adresse GitHub Pages de l'application dans *Site URL* et dans *Redirect URLs*.
4. Sur GitHub : *Settings > Pages > Deploy from a branch > main / (root)*.

## Crédits

- Illustrations de fond : images générées par IA, issues de la banque d'images libre de droits [smithable-images](https://github.com/smithable/smithable-images) (licence CC0). Ce ne sont pas de vraies photographies.
- Polices Fraunces et Manrope (Google Fonts, licence SIL Open Font).
- [supabase-js](https://github.com/supabase/supabase-js) (licence MIT).
