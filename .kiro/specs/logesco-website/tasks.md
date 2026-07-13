# Plan d'Implémentation : Site Web Marketing Logesco

## Vue d'ensemble

Implémentation d'un site vitrine Next.js 14+ avec App Router, TypeScript strict, Tailwind CSS, next-intl (FR/EN/ES), documentation Markdown SSG, formulaire de contact validé par zod, et SEO complet.

## Tâches

- [ ] 1. Initialisation du projet et configuration de base
  - Créer le projet Next.js 14+ avec App Router et TypeScript strict (`next.config.ts`, `tsconfig.json`)
  - Configurer Tailwind CSS avec les design tokens (`tailwind.config.ts`) : couleurs brand, typographies Inter/Lexend, breakpoints
  - Installer et configurer next-intl : `i18n.ts`, `middleware.ts` pour le routing par locale (`/fr`, `/en`, `/es`)
  - Créer les fichiers de traductions vides (`messages/fr.json`, `messages/en.json`, `messages/es.json`)
  - Créer le fichier des types partagés (`types/index.ts`) : `Locale`, `PricingPlan`, `DocGuide`, `AppVersion`, `PlatformDownload`, `SoftwareModule`, `HowItWorksStep`, `Testimonial`, `ProcessStep`, `SoftwareApplicationSchema`
  - Créer la structure de dossiers : `app/[locale]/`, `components/`, `lib/`, `content/`, `public/`
  - _Exigences : 1.1, 8.1, 8.4_

- [ ] 2. Composants UI de base
  - [ ] 2.1 Implémenter les composants UI primitifs
    - Créer `components/ui/Button.tsx` : variantes primary/secondary/ghost, tailles sm/md/lg, states hover/focus/disabled
    - Créer `components/ui/Badge.tsx` : variante recommandé (ambre), info (bleu)
    - Créer `components/ui/Card.tsx` : conteneur avec shadow et border-radius cohérents
    - Créer `components/ui/SectionHeader.tsx` : titre H2 + sous-titre optionnel centrés
    - _Exigences : 2.1, 2.2, 4.2, 7.6_

  - [ ]* 2.2 Écrire les tests unitaires pour les composants UI
    - Tester `Button` : rendu correct pour chaque variante, état disabled, attribut `aria-disabled`
    - Tester `Badge` : rendu correct selon la variante
    - _Exigences : 7.5, 7.6_

- [ ] 3. Layout principal : Navbar, MobileMenu, Footer
  - [ ] 3.1 Implémenter `components/layout/Navbar.tsx`
    - Sticky (`position: fixed`, `top: 0`, `z-50`) avec logo SVG Logesco lié à `/[locale]`
    - 7 entrées de navigation : Accueil, Fonctionnalités, Tarifs, Téléchargement, Documentation, Services, Contact
    - CTA "Télécharger gratuitement" (bouton primaire)
    - Sélecteur de langue FR/EN/ES avec `usePathname` + `useRouter` de next-intl
    - Affiche `MobileMenu` sous le breakpoint `md`
    - _Exigences : 1.1, 1.2, 1.4, 1.5_

  - [ ] 3.2 Implémenter `components/layout/MobileMenu.tsx`
    - Menu hamburger avec animation slide-down
    - Mêmes 7 liens de navigation + CTA
    - Fermeture au clic en dehors ou sur un lien
    - _Exigences : 1.4_

  - [ ] 3.3 Implémenter `components/layout/Footer.tsx`
    - 4 colonnes : Navigation, Documentation, Légal, Contact
    - Liens légaux (Mentions légales, Politique de confidentialité), email, WhatsApp/téléphone
    - Copyright avec année dynamique
    - _Exigences : 1.3_

  - [ ]* 3.4 Écrire les tests unitaires pour Navbar et Footer
    - Tester `Navbar` : présence des 7 entrées de navigation, présence du CTA "Télécharger gratuitement"
    - Tester `Footer` : présence des liens légaux et des coordonnées de contact
    - _Exigences : 1.1, 1.3, 1.5_

  - [ ] 3.5 Créer le layout racine `app/[locale]/layout.tsx`
    - Intégrer `Navbar` + `Footer`, fournisseur next-intl (`NextIntlClientProvider`), chargement polices `next/font`
    - _Exigences : 1.1, 7.3_

- [ ] 4. Checkpoint — S'assurer que tous les tests passent, poser des questions si nécessaire.

- [ ] 5. Composants de la page d'Accueil
  - [ ] 5.1 Implémenter `components/home/HeroSection.tsx`
    - Disposition texte (H1 + sous-titre + 2 CTA) à gauche, screenshot à droite sur desktop ; empilé sur mobile
    - Screenshot via `next/image` avec `priority`
    - Props : `HeroSectionProps` (`title`, `subtitle`, `ctaPrimary`, `ctaSecondary`, `screenshot`)
    - _Exigences : 2.1, 2.2, 2.3, 2.4_

  - [ ]* 5.2 Écrire le test de propriété pour HeroSection (Propriété 1)
    - **Propriété 1 : Le titre H1 de la section Hero est concis (< 12 mots)**
    - **Valide : Exigence 2.1**
    - `// Feature: logesco-website, Property 1`

  - [ ]* 5.3 Écrire les tests unitaires pour HeroSection
    - Tester : rendu des 2 CTA, présence de l'image avec attribut `alt` non vide
    - _Exigences : 2.3, 6.10_

  - [ ] 5.4 Implémenter `components/home/ModulesGrid.tsx`
    - Grille de 6 cartes visuelles : Ventes, Stock, Caisse, Clients, Fournisseurs, Rapports
    - Chaque carte affiche icône + titre + courte description
    - _Exigences : 2.6_

  - [ ]* 5.5 Écrire les tests unitaires pour ModulesGrid
    - Tester : rendu de exactement 6 cartes
    - _Exigence : 2.6_

  - [ ] 5.6 Implémenter `components/home/HowItWorks.tsx`
    - Section "Comment ça marche" avec 3 à 4 étapes illustrées (`HowItWorksStep[]`)
    - _Exigences : 2.7_

  - [ ]* 5.7 Écrire le test de propriété pour HowItWorks (Propriété 2)
    - **Propriété 2 : La section "Comment ça marche" contient entre 3 et 4 étapes**
    - **Valide : Exigence 2.7**
    - `// Feature: logesco-website, Property 2`

  - [ ] 5.8 Implémenter `components/home/SocialProof.tsx`
    - Section preuve sociale : avis clients (`Testimonial[]`), nombre d'utilisateurs
    - _Exigences : 2.5_

  - [ ] 5.9 Implémenter `components/home/CtaSection.tsx`
    - Section CTA finale : "Télécharger" + lien vers Contact
    - _Exigences : 2.8_

  - [ ] 5.10 Assembler la page d'Accueil `app/[locale]/page.tsx`
    - Composer HeroSection + ModulesGrid + HowItWorks + SocialProof + CtaSection
    - Exporter `generateMetadata` avec title, description, Open Graph, hreflang × 3 locales
    - Injecter le Schema JSON-LD `SoftwareApplication` via `<SchemaMarkup>`
    - Rendu SSG
    - _Exigences : 2.1–2.8, 6.1, 6.2, 6.3, 6.8, 8.3_

  - [ ]* 5.11 Écrire le test de propriété pour les métadonnées (Propriété 7 — page Accueil)
    - **Propriété 7 : generateMetadata retourne title et description non vides**
    - **Valide : Exigences 6.1, 11.7**
    - `// Feature: logesco-website, Property 7`

  - [ ]* 5.12 Écrire le test de propriété pour le H1 unique (Propriété 8 — page Accueil)
    - **Propriété 8 : Chaque page rendue contient exactement un H1**
    - **Valide : Exigence 6.8**
    - `// Feature: logesco-website, Property 8`

- [ ] 6. Composants et page Fonctionnalités
  - [ ] 6.1 Implémenter `components/features/FeatureCard.tsx`
    - Affiche icône (non vide) + titre (non vide) + description (2–4 phrases) + screenshot optionnel + CTA
    - Props : `FeatureCardProps`
    - _Exigences : 3.2, 3.3_

  - [ ]* 6.2 Écrire le test de propriété pour FeatureCard (Propriété 3)
    - **Propriété 3 : Chaque FeatureCard affiche une icône, un titre et une description**
    - **Valide : Exigence 3.2**
    - `// Feature: logesco-website, Property 3`

  - [ ] 6.3 Implémenter `components/features/FeatureSection.tsx`
    - Section par module avec `FeatureCard` + CTA "Télécharger et essayer gratuitement"
    - _Exigences : 3.1, 3.4_

  - [ ] 6.4 Assembler la page Fonctionnalités `app/[locale]/fonctionnalites/page.tsx`
    - 11 sections de modules : Ventes, Stock, Approvisionnements, Caisse, Clients, Fournisseurs, Inventaires, Rapports, Multi-boutiques, Synchronisation, Internationalisation
    - Mention compatibilité multi-plateforme (Windows, Android, Web)
    - `generateMetadata` avec hreflang × 3, SSG
    - _Exigences : 3.1–3.5, 6.1, 6.8, 8.3_

- [ ] 7. Composants et page Tarifs
  - [ ] 7.1 Implémenter `components/pricing/PricingCard.tsx`
    - Affiche nom du plan, prix, liste des fonctionnalités incluses, CTA "Télécharger et activer"
    - Met en avant visuellement le plan recommandé (`isRecommended`) via `Badge` ambre
    - Mention activation par clé de licence sans compte
    - Props : `PricingCardProps`
    - _Exigences : 4.2, 4.5, 4.6_

  - [ ]* 7.2 Écrire le test de propriété pour PricingCard — plans recommandés (Propriété 4)
    - **Propriété 4 : Exactement un plan tarifaire est marqué comme recommandé**
    - **Valide : Exigence 4.2**
    - `// Feature: logesco-website, Property 4`

  - [ ]* 7.3 Écrire le test de propriété pour PricingCard — fonctionnalités (Propriété 5)
    - **Propriété 5 : Chaque PricingPlan liste au moins une fonctionnalité incluse**
    - **Valide : Exigence 4.3**
    - `// Feature: logesco-website, Property 5`

  - [ ] 7.4 Implémenter `components/pricing/PricingGrid.tsx`
    - Grille de 4 plans tarifaires : Essai (7 jours), Mensuel, Annuel, À vie
    - _Exigences : 4.1, 4.3_

  - [ ]* 7.5 Écrire les tests unitaires pour PricingGrid
    - Tester : rendu de exactement 4 plans
    - _Exigence : 4.1_

  - [ ] 7.6 Implémenter `components/pricing/PricingFaq.tsx`
    - FAQ : renouvellement, activation par clé, fonctionnement offline
    - _Exigences : 4.4, 4.6_

  - [ ]* 7.7 Écrire les tests unitaires pour PricingFaq
    - Tester : présence de la mention "activation par clé de licence"
    - _Exigence : 4.6_

  - [ ] 7.8 Assembler la page Tarifs `app/[locale]/tarifs/page.tsx`
    - Composer PricingGrid + PricingFaq, `generateMetadata` avec hreflang × 3, SSG
    - _Exigences : 4.1–4.6, 6.1, 6.8, 8.3_

- [ ] 8. Checkpoint — S'assurer que tous les tests passent, poser des questions si nécessaire.

- [ ] 9. Composants et page Téléchargement
  - [ ] 9.1 Créer les données statiques de version (`content/download.ts`)
    - Exporter un objet `AppVersion` avec version, date, changelog, et `PlatformDownload[]` pour Windows et Android
    - _Exigences : 5.1, 5.2, 5.4, 5.5_

  - [ ] 9.2 Implémenter `components/download/DownloadButton.tsx`
    - Si `available === true` : lien `<a href={fileUrl} download>` avec icône plateforme et label
    - Si `available === false` : encart d'indisponibilité avec lien vers `/[locale]/contact`
    - Props : `DownloadButtonProps`
    - _Exigences : 5.2, 5.3, 5.6_

  - [ ]* 9.3 Écrire le test de propriété pour DownloadButton (Propriété 6)
    - **Propriété 6 : Le bouton de téléchargement est correct selon la disponibilité**
    - **Valide : Exigences 5.3, 5.6**
    - `// Feature: logesco-website, Property 6`

  - [ ] 9.4 Implémenter `components/download/ChangelogSection.tsx`
    - Affiche le résumé des nouveautés (`ChangelogEntry[]`) avec badges par type (new/fix/improvement)
    - _Exigences : 5.4_

  - [ ] 9.5 Assembler la page Téléchargement `app/[locale]/telechargement/page.tsx`
    - Affiche version courante + date, boutons Windows/Android, prérequis techniques, ChangelogSection, lien vers documentation
    - Injecter Schema JSON-LD `SoftwareApplication`
    - `generateMetadata` avec hreflang × 3, ISR (`revalidate: 3600`)
    - _Exigences : 5.1–5.7, 6.1, 6.3, 6.8, 8.3_

  - [ ]* 9.6 Écrire les tests unitaires pour la page Téléchargement
    - Tester : affichage de la version et de la date, présence des boutons Windows et Android, présence du schema JSON-LD
    - _Exigences : 5.1, 5.2, 6.3_

- [ ] 10. Formulaire de contact et page Contact
  - [ ] 10.1 Implémenter le schéma de validation zod pour le formulaire de contact
    - Schéma zod pour `ContactFormData` : name (requis), email (format email), subject (requis), message (requis)
    - _Exigences : 9.1, 9.2, 9.3_

  - [ ] 10.2 Implémenter `components/contact/ContactForm.tsx`
    - Formulaire react-hook-form avec les 4 champs : Nom, Email, Sujet, Message
    - Validation côté client via résolveur zod ; messages d'erreur par champ avec `aria-describedby`
    - État de succès : message de confirmation + réinitialisation
    - Prop `defaultSubject?: string` pour pré-remplissage depuis `/services`
    - _Exigences : 9.1, 9.2, 9.3, 9.4, 12.6_

  - [ ]* 10.3 Écrire le test de propriété pour ContactForm (Propriété 12)
    - **Propriété 12 : Le formulaire rejette les entrées invalides avec des messages d'erreur par champ**
    - **Valide : Exigences 9.2, 9.3**
    - `// Feature: logesco-website, Property 12`

  - [ ]* 10.4 Écrire les tests unitaires pour ContactForm
    - Tester : soumission réussie → message de confirmation + réinitialisation, pré-remplissage du sujet depuis `/services`
    - _Exigences : 9.4, 12.6_

  - [ ] 10.5 Assembler la page Contact `app/[locale]/contact/page.tsx`
    - Composer ContactForm + coordonnées directes (email, WhatsApp/téléphone)
    - `generateMetadata` avec hreflang × 3, SSG + rendu formulaire côté client
    - _Exigences : 9.1–9.5, 6.1, 8.3_

- [ ] 11. Page Services sur mesure
  - [ ] 11.1 Implémenter `components/services/ServicesHero.tsx`
    - Présentation de l'offre de développement sur mesure (applications métier, logiciels personnalisés, intégrations, solutions web)
    - Message de réassurance + CTA "Discuter de mon projet" → `/[locale]/contact?subject=Services+sur+mesure`
    - _Exigences : 12.1, 12.2, 12.4, 12.5_

  - [ ] 11.2 Implémenter `components/services/ProcessSteps.tsx`
    - 3 à 5 étapes illustrées du processus de collaboration (`ProcessStep[]`) : analyse, conception, développement, livraison, support
    - _Exigences : 12.3_

  - [ ] 11.3 Assembler la page Services `app/[locale]/services/page.tsx`
    - Composer ServicesHero + ProcessSteps, CTA vers Contact avec paramètre sujet pré-rempli
    - `generateMetadata` optimisées pour développement logiciel sur mesure, hreflang × 3, SSG
    - _Exigences : 12.1–12.8, 6.1, 8.3_

- [ ] 12. Bibliothèque de documentation et page Documentation
  - [ ] 12.1 Implémenter `lib/docs.ts`
    - Mapping `DOC_GUIDES` : 9 guides (slug → filename + order)
    - `getAllGuides(locale)` : lit les fichiers Markdown depuis `docs/` avec `fs`, parse avec gray-matter, retourne `DocGuide[]` triés
    - `getGuideBySlug(slug, locale)` : retourne le contenu HTML rendu (remark → remark-html, rehype-slug, rehype-autolink-headings) ou `null`
    - `buildSearchIndex(guides)` : construit un index de recherche full-text (`SearchIndexEntry[]`)
    - _Exigences : 11.1, 11.2, 11.8_

  - [ ] 12.2 Implémenter `lib/search.ts`
    - Fonction `searchDocs(query, index)` : filtre sur l'index, retourne `SearchResult[]` avec `guideSlug`, `guideTitle`, `excerpt`, `matchedHeading?`
    - _Exigences : 11.5, 11.6_

  - [ ]* 12.3 Écrire le test de propriété pour la recherche documentaire (Propriété 13)
    - **Propriété 13 : La recherche retourne un titre et un extrait non vides pour tout mot-clé existant**
    - **Valide : Exigences 11.5, 11.6**
    - `// Feature: logesco-website, Property 13`

  - [ ] 12.4 Implémenter `components/documentation/DocSidebar.tsx`
    - Liste de tous les guides avec liens `<Link>` Next.js (navigation sans rechargement)
    - Highlight du guide actif via `currentSlug`
    - Props : `DocSidebarProps`
    - _Exigences : 11.3, 11.4_

  - [ ] 12.5 Implémenter `components/documentation/DocContent.tsx`
    - Zone d'affichage du contenu HTML rendu depuis Markdown
    - Typographie prose (Tailwind `@tailwindcss/typography`)
    - _Exigences : 11.2, 11.4_

  - [ ] 12.6 Implémenter `components/documentation/DocSearch.tsx`
    - Barre de recherche client-side avec `searchDocs`, affiche les résultats avec titre du guide source + extrait
    - Props : `DocSearchProps`
    - _Exigences : 11.5, 11.6_

  - [ ] 12.7 Assembler la page index Documentation `app/[locale]/documentation/page.tsx`
    - SSG avec `getAllGuides`, composer DocSidebar + DocSearch + liste des guides
    - `generateMetadata`, hreflang × 3
    - _Exigences : 11.1, 11.3, 6.1, 8.3_

  - [ ] 12.8 Assembler la page guide individuel `app/[locale]/documentation/[slug]/page.tsx`
    - `generateStaticParams` pour générer 1 page/guide au build
    - `getGuideBySlug` → `notFound()` si null
    - Composer DocSidebar + DocSearch + DocContent
    - `generateMetadata` unique par guide avec hreflang × 3
    - _Exigences : 11.2, 11.4, 11.7, 11.8, 6.1, 8.3_

- [ ] 13. Checkpoint — S'assurer que tous les tests passent, poser des questions si nécessaire.

- [ ] 14. SEO global : sitemap, robots, hreflang et Schema
  - [ ] 14.1 Implémenter `lib/metadata.ts`
    - Helper `buildMetadata(params)` : génère `title`, `description`, Open Graph, Twitter Card, et `alternates.languages` avec les 3 URLs localisées
    - _Exigences : 6.1, 8.3_

  - [ ]* 14.2 Écrire le test de propriété pour generateMetadata — hreflang (Propriété 10)
    - **Propriété 10 : Les métadonnées contiennent des balises hreflang pour les 3 locales**
    - **Valide : Exigence 8.3**
    - `// Feature: logesco-website, Property 10`

  - [ ]* 14.3 Écrire le test de propriété pour les routes i18n (Propriété 11)
    - **Propriété 11 : Toutes les routes sont préfixées par la locale**
    - **Valide : Exigence 8.4**
    - `// Feature: logesco-website, Property 11`

  - [ ] 14.4 Implémenter le composant `SchemaMarkup` et les données JSON-LD
    - Composant `<SchemaMarkup schema={...}>` injectant `<script type="application/ld+json">`
    - Données `softwareSchema` (`SoftwareApplicationSchema`) pour les pages Accueil et Téléchargement
    - _Exigences : 6.3_

  - [ ] 14.5 Implémenter `app/sitemap.ts`
    - Génère toutes les combinaisons locale × route statique + locale × slug documentation
    - _Exigences : 6.4_

  - [ ] 14.6 Implémenter `app/robots.ts`
    - Autorise `/`, bloque `/api/`, `/admin/`
    - _Exigences : 6.5_

  - [ ]* 14.7 Écrire les tests unitaires pour sitemap et robots
    - Tester : toutes les routes statiques présentes dans le sitemap, règle de blocage `/api/` dans robots
    - _Exigences : 6.4, 6.5_

- [ ] 15. Analytique et bannière de consentement RGPD
  - [ ] 15.1 Implémenter `lib/analytics.ts`
    - Wrappers `trackEvent(name, props)` pour GA4 ou Plausible (configurable via env)
    - Chargement asynchrone du script (ne bloquer pas les Core Web Vitals)
    - _Exigences : 10.1, 10.2, 10.3_

  - [ ] 15.2 Implémenter le composant `CookieBanner`
    - Affichage au premier chargement si cookies tiers activés
    - Boutons "Accepter" / "Refuser" ; GA4 chargé seulement après consentement explicite
    - _Exigences : 10.4_

  - [ ] 15.3 Câbler les événements de conversion dans les composants
    - Déclencher `trackEvent` sur : clic CTA téléchargement (`DownloadButton`), soumission réussie du `ContactForm`, visite page Tarifs
    - _Exigences : 10.2_

- [ ] 16. Pages d'erreur et gestion des cas limites
  - [ ] 16.1 Implémenter `app/[locale]/not-found.tsx`
    - Page 404 localisée avec lien retour à l'accueil
    - _Exigences : 7.4_

  - [ ] 16.2 Implémenter `app/[locale]/error.tsx`
    - Boundary d'erreur Next.js avec message localisé et bouton de rechargement
    - _Exigences : 7.4_

- [ ] 17. Accessibilité et optimisation des images
  - [ ]* 17.1 Écrire le test de propriété pour les attributs alt des images (Propriété 9)
    - **Propriété 9 : Toute image possède un attribut alt descriptif non vide**
    - **Valide : Exigence 6.10**
    - `// Feature: logesco-website, Property 9`

  - [ ]* 17.2 Écrire les tests d'accessibilité avec jest-axe
    - Tester Navbar, ContactForm, DocSidebar avec `toHaveNoViolations()`
    - Vérifier les `aria-describedby` du formulaire, les indicateurs de focus
    - _Exigences : 7.5, 7.6, 7.7_

- [ ] 18. Checkpoint final — S'assurer que tous les tests passent, poser des questions si nécessaire.

## Notes

- Les tâches marquées `*` sont optionnelles et peuvent être ignorées pour un MVP rapide
- Chaque tâche référence les exigences spécifiques pour la traçabilité
- Les tests de propriétés (fast-check) valident les comportements universels ; les tests unitaires valident les exemples et cas limites
- Le tag `// Feature: logesco-website, Property N` est requis dans chaque test de propriété
- Toutes les pages utilisent `generateMetadata` avec `alternates.languages` pour les balises `hreflang` × 3 locales
