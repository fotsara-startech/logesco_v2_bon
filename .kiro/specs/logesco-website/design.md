# Document de Conception Technique — Site Web Marketing Logesco

## Vue d'Ensemble

Le site web marketing Logesco est un site vitrine Next.js 14+ conçu pour présenter le logiciel de gestion commerciale Logesco à des prospects, maximiser les conversions (téléchargements, demandes de contact), et servir de centre de documentation technique. Il cible trois audiences : les prospects souhaitant évaluer Logesco, les clients existants cherchant de la documentation, et les entreprises ayant des besoins de développement sur mesure.

### Objectifs techniques

- Score Lighthouse ≥ 90 sur toutes les pages (Performance, SEO, Accessibilité)
- Core Web Vitals dans les seuils "Good" Google (LCP ≤ 2,5s, CLS ≤ 0,1, FID ≤ 100ms)
- Support i18n FR/EN/ES avec routing localisé via next-intl
- Pages de documentation générées en SSG depuis les fichiers Markdown du dossier `docs/`
- Conformité RGPD pour le tracking analytique

### Stack technique

- **Framework** : Next.js 14+ avec App Router
- **Langage** : TypeScript strict
- **Style** : Tailwind CSS avec design tokens personnalisés
- **i18n** : next-intl
- **Documentation Markdown** : gray-matter + remark/rehype
- **Formulaires** : react-hook-form + zod
- **Analytique** : Google Analytics 4 ou Plausible (configurable)
- **Tests propriétés** : fast-check (property-based testing)
- **Tests unitaires** : Jest + React Testing Library

---

## Architecture

### Structure des dossiers

```
logesco-website/
├── app/
│   └── [locale]/                    # Routing i18n — locale = fr | en | es
│       ├── layout.tsx               # Layout racine avec Navbar + Footer
│       ├── page.tsx                 # Page d'Accueil
│       ├── fonctionnalites/
│       │   └── page.tsx
│       ├── tarifs/
│       │   └── page.tsx
│       ├── telechargement/
│       │   └── page.tsx
│       ├── documentation/
│       │   ├── page.tsx             # Index de la documentation
│       │   └── [slug]/
│       │       └── page.tsx         # Page individuelle d'un guide
│       ├── services/
│       │   └── page.tsx
│       └── contact/
│           └── page.tsx
├── components/
│   ├── layout/
│   │   ├── Navbar.tsx
│   │   ├── MobileMenu.tsx
│   │   └── Footer.tsx
│   ├── home/
│   │   ├── HeroSection.tsx
│   │   ├── ModulesGrid.tsx
│   │   ├── HowItWorks.tsx
│   │   ├── SocialProof.tsx
│   │   └── CtaSection.tsx
│   ├── features/
│   │   ├── FeatureCard.tsx
│   │   └── FeatureSection.tsx
│   ├── pricing/
│   │   ├── PricingCard.tsx
│   │   ├── PricingGrid.tsx
│   │   └── PricingFaq.tsx
│   ├── download/
│   │   ├── DownloadButton.tsx
│   │   └── ChangelogSection.tsx
│   ├── documentation/
│   │   ├── DocSidebar.tsx
│   │   ├── DocContent.tsx
│   │   └── DocSearch.tsx
│   ├── contact/
│   │   └── ContactForm.tsx
│   ├── services/
│   │   ├── ServicesHero.tsx
│   │   └── ProcessSteps.tsx
│   └── ui/
│       ├── Button.tsx
│       ├── Badge.tsx
│       ├── Card.tsx
│       └── SectionHeader.tsx
├── lib/
│   ├── docs.ts                      # Parsing Markdown + gray-matter
│   ├── search.ts                    # Recherche full-text documentation
│   ├── metadata.ts                  # Helpers generateMetadata
│   └── analytics.ts                 # Wrappers GA4 / Plausible
├── messages/
│   ├── fr.json                      # Traductions françaises
│   ├── en.json                      # Traductions anglaises
│   └── es.json                      # Traductions espagnoles
├── content/
│   └── download.ts                  # Données statiques version + changelog
├── types/
│   └── index.ts                     # Types TypeScript partagés
├── public/
│   ├── images/
│   ├── screenshots/
│   └── downloads/                   # Fichiers .exe et .apk
├── i18n.ts                          # Configuration next-intl
├── middleware.ts                    # Redirection locale par défaut
├── next.config.ts
└── tailwind.config.ts
```

### Stratégie de rendu par page

| Page | Stratégie | Justification |
|---|---|---|
| Accueil | SSG | Contenu statique, critique pour le SEO |
| Fonctionnalités | SSG | Contenu statique, critique pour le SEO |
| Tarifs | SSG | Contenu statique, critique pour le SEO |
| Téléchargement | ISR (revalidate: 3600) | Peut évoluer avec les versions |
| Documentation (index) | SSG | Liste de guides statiques |
| Documentation (guide) | SSG avec generateStaticParams | 1 page/guide générée au build |
| Services | SSG | Contenu statique |
| Contact | SSG + client-side form | Formulaire géré côté client |

### Flux de navigation i18n

```
/ → redirect → /fr (middleware détecte la locale navigateur)
/fr → Page d'Accueil (FR)
/en → Home Page (EN)
/es → Página de Inicio (ES)

/fr/fonctionnalites
/en/features
/es/funcionalidades

/fr/documentation/guide-utilisateur
/en/documentation/user-guide
/es/documentation/guia-usuario
```

Le middleware Next.js intercepte toutes les requêtes racines et redirige vers `/[locale]` selon la préférence navigateur (`Accept-Language`), avec le français comme fallback.

---

## Composants et Interfaces

### Navbar

```typescript
interface NavbarProps {
  locale: Locale;
}
```

- Sticky (`position: fixed`, `top: 0`, z-index 50)
- Liens : Accueil, Fonctionnalités, Tarifs, Téléchargement, Documentation, Services, Contact
- CTA "Télécharger gratuitement" — bouton primaire
- Sélecteur de langue (FR | EN | ES) avec `usePathname` + `useRouter` de next-intl
- Au breakpoint `md` : menu hamburger via `MobileMenu` avec animation slide-down
- Logo Logesco (SVG) avec lien vers `/[locale]`

### Footer

```typescript
interface FooterLink {
  label: string;
  href: string;
}
interface FooterProps {
  locale: Locale;
}
```

- Colonnes : Navigation, Documentation, Légal, Contact
- Liens légaux : Mentions légales, Politique de confidentialité
- Coordonnées : email, WhatsApp/téléphone
- Copyright + année dynamique

### HeroSection

```typescript
interface HeroSectionProps {
  title: string;        // H1, < 12 mots
  subtitle: string;     // 1–2 phrases bénéfices
  ctaPrimary: CtaLink;  // "Télécharger gratuitement"
  ctaSecondary: CtaLink; // "Voir les fonctionnalités"
  screenshot: ImageData;
}

interface CtaLink {
  label: string;
  href: string;
}

interface ImageData {
  src: string;
  alt: string;
  width: number;
  height: number;
}
```

- Screenshot rendu via `next/image` avec priorité de chargement
- Disposition : texte à gauche, image à droite sur desktop ; empilé sur mobile

### FeatureCard

```typescript
interface FeatureCardProps {
  icon: React.ReactNode;
  title: string;
  description: string;      // 2–4 phrases
  screenshotSrc?: string;
  ctaLabel: string;
  ctaHref: string;
}
```

### PricingCard

```typescript
interface PricingCardProps {
  plan: PricingPlan;
  isRecommended?: boolean;
  ctaLabel: string;
  ctaHref: string;
}
```

### DownloadButton

```typescript
interface DownloadButtonProps {
  platform: 'windows' | 'android';
  fileUrl: string;
  available: boolean;
  label: string;
  icon: React.ReactNode;
}
```

- Si `available === false` : affiche un message d'indisponibilité et un lien de contact

### DocSidebar

```typescript
interface DocSidebarProps {
  guides: DocGuide[];
  currentSlug: string;
  locale: Locale;
}
```

- Liste de tous les guides avec liens actifs
- Navigation sans rechargement (liens Next.js `<Link>`)
- Highlight du guide actif

### DocSearch

```typescript
interface DocSearchProps {
  guides: DocGuide[];
  locale: Locale;
}

interface SearchResult {
  guideSlug: string;
  guideTitle: string;
  excerpt: string;
  matchedHeading?: string;
}
```

- Recherche client-side full-text sur contenu pré-indexé (généré au build)
- Retourne : titre du guide source + extrait avec contexte

### ContactForm

```typescript
interface ContactFormData {
  name: string;
  email: string;
  subject: string;
  message: string;
}

interface ContactFormProps {
  defaultSubject?: string;  // Pré-rempli depuis /services
}
```

- Validation côté client via zod + react-hook-form
- Affichage des erreurs par champ (`aria-describedby` pour l'accessibilité)
- État de succès : message de confirmation + réinitialisation du formulaire

---

## Modèles de Données

### Types TypeScript partagés (`types/index.ts`)

```typescript
// Locales supportées
export type Locale = 'fr' | 'en' | 'es';

// Plans tarifaires
export interface PricingPlan {
  id: 'trial' | 'monthly' | 'annual' | 'lifetime';
  name: string;
  price: number | null;       // null = gratuit
  currency: string;
  billingPeriod: 'once' | 'month' | 'year' | 'trial';
  trialDays?: number;         // 7 pour le plan Essai
  features: string[];
  isRecommended: boolean;
  activationMethod: 'license-key';  // Toujours par clé de licence
}

// Guide de documentation
export interface DocGuide {
  slug: string;
  title: string;
  description: string;
  filename: string;             // ex: GUIDE_UTILISATEUR.md
  order: number;
  content?: string;             // Contenu HTML rendu (optionnel pour la liste)
  headings?: DocHeading[];
  lastModified?: string;
}

export interface DocHeading {
  id: string;
  text: string;
  level: 1 | 2 | 3;
}

// Informations de version pour la page Téléchargement
export interface AppVersion {
  version: string;              // ex: "2.5.1"
  releaseDate: string;          // ISO 8601
  changelog: ChangelogEntry[];
  downloads: PlatformDownload[];
}

export interface PlatformDownload {
  platform: 'windows' | 'android';
  label: string;
  fileUrl: string;
  fileSize: string;
  available: boolean;
  requirements: SystemRequirements;
}

export interface SystemRequirements {
  os: string;
  ram: string;
  storage: string;
  other?: string;
}

export interface ChangelogEntry {
  type: 'new' | 'fix' | 'improvement';
  description: string;
}

// Module fonctionnel du logiciel
export interface SoftwareModule {
  id: string;
  icon: string;                 // Nom d'icône (ex: lucide-react)
  title: string;
  description: string;
  features: string[];
  screenshotSrc?: string;
  screenshotAlt?: string;
}

// Étape "Comment ça marche"
export interface HowItWorksStep {
  number: number;
  title: string;
  description: string;
  iconSrc?: string;
}

// Témoignage / preuve sociale
export interface Testimonial {
  author: string;
  role?: string;
  company?: string;
  content: string;
  rating?: 1 | 2 | 3 | 4 | 5;
}

// Étape du processus (Page Services)
export interface ProcessStep {
  number: number;
  title: string;
  description: string;
  icon?: string;
}

// SEO Schema markup
export interface SoftwareApplicationSchema {
  '@context': 'https://schema.org';
  '@type': 'SoftwareApplication';
  name: string;
  description: string;
  applicationCategory: string;
  operatingSystem: string;
  offers: {
    '@type': 'Offer';
    price: string;
    priceCurrency: string;
    description: string;
  };
  url: string;
}
```

### Données de documentation (`lib/docs.ts`)

La bibliothèque `docs.ts` lit les fichiers Markdown depuis `docs/` au moment du build via `fs` (Node.js) et expose :

```typescript
// Mapping slug → fichier Markdown
export const DOC_GUIDES: Record<string, { filename: string; order: number }> = {
  'guide-utilisateur': { filename: 'GUIDE_UTILISATEUR.md', order: 1 },
  'guide-installation': { filename: 'GUIDE_INSTALLATION.md', order: 2 },
  'guide-formation': { filename: 'GUIDE_FORMATION.md', order: 3 },
  'guide-maintenance': { filename: 'GUIDE_MAINTENANCE.md', order: 4 },
  'guide-depannage': { filename: 'GUIDE_DEPANNAGE_COMPLET.md', order: 5 },
  'documentation-complete': { filename: 'DOCUMENTATION_COMPLETE.md', order: 6 },
  'documentation-technique': { filename: 'DOCUMENTATION_TECHNIQUE.md', order: 7 },
  'carte-reference': { filename: 'CARTE_REFERENCE_RAPIDE.md', order: 8 },
  'scripts-videos': { filename: 'SCRIPTS_VIDEOS_FORMATION.md', order: 9 },
};

export async function getAllGuides(locale: Locale): Promise<DocGuide[]>
export async function getGuideBySlug(slug: string, locale: Locale): Promise<DocGuide | null>
export function buildSearchIndex(guides: DocGuide[]): SearchIndexEntry[]
```

Le rendu Markdown utilise :
- `gray-matter` pour extraire le frontmatter
- `remark` + `remark-html` pour convertir en HTML
- `rehype-slug` pour ajouter des `id` aux titres (ancres)
- `rehype-autolink-headings` pour les liens d'ancres

---

## Architecture SEO

### generateMetadata par page

Chaque page exporte une fonction `generateMetadata` conforme au type `Metadata` de Next.js :

```typescript
// Exemple pour la page Téléchargement
export async function generateMetadata({ params }: { params: { locale: Locale } }): Promise<Metadata> {
  const t = await getTranslations({ locale: params.locale, namespace: 'download' });
  return {
    title: t('meta.title'),
    description: t('meta.description'),
    openGraph: {
      title: t('meta.title'),
      description: t('meta.description'),
      images: [{ url: '/og/telechargement.jpg', width: 1200, height: 630 }],
    },
    twitter: { card: 'summary_large_image' },
    alternates: {
      canonical: `https://logesco.com/${params.locale}/telechargement`,
      languages: {
        fr: 'https://logesco.com/fr/telechargement',
        en: 'https://logesco.com/en/download',
        es: 'https://logesco.com/es/descarga',
      },
    },
  };
}
```

Les balises `hreflang` sont générées via `alternates.languages` dans chaque `generateMetadata`. Next.js les injecte automatiquement dans le `<head>`.

### Schema JSON-LD

Un composant `<SchemaMarkup>` injecte les données structurées via une balise `<script type="application/ld+json">` :

```typescript
// Utilisé sur la page d'Accueil et Téléchargement
const softwareSchema: SoftwareApplicationSchema = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'Logesco',
  description: 'Logiciel de gestion commerciale multi-plateforme',
  applicationCategory: 'BusinessApplication',
  operatingSystem: 'Windows, Android',
  offers: {
    '@type': 'Offer',
    price: '0',
    priceCurrency: 'EUR',
    description: 'Essai gratuit 7 jours',
  },
  url: 'https://logesco.com',
};
```

### Sitemap et robots.txt

- `app/sitemap.ts` : génère dynamiquement le sitemap incluant toutes les routes localisées et les pages de documentation
- `app/robots.ts` : autorise `/` et bloque les routes `/api/`, `/admin/`

```typescript
// app/sitemap.ts
export default function sitemap(): MetadataRoute.Sitemap {
  const locales: Locale[] = ['fr', 'en', 'es'];
  const staticRoutes = ['', '/fonctionnalites', '/tarifs', '/telechargement', '/services', '/contact'];
  const docSlugs = Object.keys(DOC_GUIDES);
  // Génère toutes les combinaisons locale × route
}
```

---

## Système de Design (Tailwind)

### Tokens de couleur (`tailwind.config.ts`)

```typescript
colors: {
  brand: {
    primary:   '#1E40AF', // Bleu profond — CTA, liens actifs
    secondary: '#3B82F6', // Bleu moyen — hover, accents
    accent:    '#F59E0B', // Ambre — badges "Recommandé", highlights
    dark:      '#0F172A', // Texte principal
    light:     '#F8FAFC', // Fond clair
  },
  neutral: {
    50:  '#F8FAFC',
    100: '#F1F5F9',
    200: '#E2E8F0',
    700: '#334155',
    900: '#0F172A',
  }
}
```

### Typographie

```typescript
fontFamily: {
  sans: ['Inter', 'system-ui', 'sans-serif'],     // Corps du texte
  display: ['Lexend', 'Inter', 'sans-serif'],      // Titres et headings
}
```

- H1 : `font-display text-4xl md:text-5xl lg:text-6xl font-bold`
- H2 : `font-display text-2xl md:text-3xl font-semibold`
- H3 : `font-display text-xl font-semibold`
- Corps : `font-sans text-base text-neutral-700`

### Breakpoints responsifs

- `sm` : 640px (petits mobiles)
- `md` : 768px (tablettes, passage hamburger → nav horizontale)
- `lg` : 1024px (desktop compact)
- `xl` : 1280px (desktop large)
- `2xl` : 1536px (très grands écrans)

---

## Gestion des Erreurs

### Indisponibilité des fichiers de téléchargement

Le composant `DownloadButton` vérifie `available: boolean` depuis les données statiques. Si `false`, il affiche un encart d'indisponibilité avec lien vers `/[locale]/contact` plutôt que de déclencher le téléchargement.

### Erreurs de formulaire de contact

- Validation synchrone côté client via zod avant toute soumission
- Affichage d'un message d'erreur par champ invalide via `aria-describedby`
- En cas d'erreur serveur lors de l'envoi : message d'erreur générique + encouragement à contacter par email directement

### Pages 404 et erreurs

- `app/[locale]/not-found.tsx` : page 404 localisée avec lien retour à l'accueil
- `app/[locale]/error.tsx` : boundary d'erreur Next.js avec message et bouton de rechargement

### Guide de documentation introuvable

Si `getGuideBySlug` retourne `null`, la page redirige vers `notFound()` de Next.js, déclenchant la page 404 localisée.

### Bannière de consentement cookies (RGPD)

Un composant `CookieBanner` (client component) s'affiche lors de la première visite si des cookies tiers (GA4) sont utilisés. Il propose "Accepter" et "Refuser". Le script GA4 n'est chargé qu'après consentement explicite.

---


## Propriétés de Correction

*Une propriété est une caractéristique ou un comportement qui doit rester vrai pour toutes les exécutions valides d'un système — autrement dit, une déclaration formelle sur ce que le logiciel est censé faire. Les propriétés servent de pont entre les spécifications lisibles par les humains et les garanties de correction vérifiables automatiquement.*

### Propriété 1 : Le titre H1 de la section Hero est concis

*Pour toute* locale supportée (FR, EN, ES), le titre H1 rendu dans la `HeroSection` doit contenir strictement moins de 12 mots.

**Valide : Exigence 2.1**

---

### Propriété 2 : La section "Comment ça marche" contient entre 3 et 4 étapes

*Pour tout* tableau d'étapes passé au composant `HowItWorks`, le nombre d'étapes rendues doit être compris entre 3 et 4 inclus.

**Valide : Exigence 2.7**

---

### Propriété 3 : Chaque FeatureCard affiche une icône, un titre, et une description

*Pour tout* objet `SoftwareModule` valide, le composant `FeatureCard` correspondant doit rendre un élément icône non vide, un titre non vide, et une description non vide.

**Valide : Exigence 3.2**

---

### Propriété 4 : Exactement un plan tarifaire est marqué comme recommandé

*Pour tout* tableau de `PricingPlan` passé à la grille tarifaire, exactement un plan doit avoir `isRecommended === true`.

**Valide : Exigence 4.2**

---

### Propriété 5 : Chaque plan tarifaire liste au moins une fonctionnalité incluse

*Pour tout* `PricingPlan` valide, sa propriété `features` doit contenir au moins un élément, et le composant `PricingCard` doit rendre cette liste de fonctionnalités.

**Valide : Exigence 4.3**

---

### Propriété 6 : Le bouton de téléchargement est correct selon la disponibilité

*Pour tout* `PlatformDownload` avec `available === true`, le composant `DownloadButton` doit rendre un lien dont l'attribut `href` correspond à `fileUrl` et dont l'attribut `download` est présent.
*Pour tout* `PlatformDownload` avec `available === false`, le composant `DownloadButton` doit rendre un message d'indisponibilité et aucun lien de téléchargement.

**Valide : Exigences 5.3, 5.6**

---

### Propriété 7 : La génération de métadonnées produit un titre et une description non vides

*Pour toute* page du site et toute locale supportée, la fonction `generateMetadata` doit retourner un objet dont `title` et `description` sont des chaînes non vides et non nulles.

**Valide : Exigences 6.1, 11.7**

---

### Propriété 8 : Chaque page rendue contient exactement un H1

*Pour toute* page rendue du site, l'arbre DOM résultant doit contenir exactement un élément `<h1>`.

**Valide : Exigence 6.8**

---

### Propriété 9 : Toute image possède un attribut alt descriptif non vide

*Pour toute* image rendue sur le site (balise `<img>` ou composant `next/image`), l'attribut `alt` doit être une chaîne non vide.

**Valide : Exigence 6.10**

---

### Propriété 10 : Les métadonnées contiennent des balises hreflang pour les 3 locales

*Pour toute* page et toute locale active, les métadonnées générées par `generateMetadata` doivent contenir un objet `alternates.languages` avec des entrées valides pour les trois locales `fr`, `en` et `es`.

**Valide : Exigence 8.3**

---

### Propriété 11 : Toutes les routes sont préfixées par la locale

*Pour toute* combinaison (route, locale), l'URL résolue par le routeur next-intl doit commencer par `/[locale]/` où `locale` est l'un des trois codes supportés.

**Valide : Exigence 8.4**

---

### Propriété 12 : Le formulaire de contact rejette les entrées invalides avec des messages d'erreur par champ

*Pour toute* soumission du `ContactForm` contenant au moins un champ obligatoire vide ou un email mal formaté, la soumission doit être bloquée côté client, et chaque champ invalide doit afficher un message d'erreur descriptif associé via `aria-describedby`.

**Valide : Exigences 9.2, 9.3**

---

### Propriété 13 : La recherche documentaire retourne des résultats avec titre et extrait pour tout mot-clé existant

*Pour tout* mot-clé présent dans au moins un fichier Markdown de la documentation, la fonction de recherche doit retourner au moins un `SearchResult` contenant un `guideTitle` non vide et un `excerpt` non vide.

**Valide : Exigences 11.5, 11.6**

---

## Stratégie de Tests

### Approche duale (tests unitaires + tests de propriétés)

Les deux types de tests sont complémentaires et tous deux requis :

- **Tests unitaires** : vérifient des exemples spécifiques, les cas limites et les conditions d'erreur
- **Tests de propriétés** : vérifient les propriétés universelles sur un large éventail d'entrées générées aléatoirement

### Tests unitaires (Jest + React Testing Library)

Les tests unitaires se concentrent sur :

| Cas | Composant / Module | Exigence |
|---|---|---|
| Navbar contient les 7 entrées de navigation | `Navbar` | 1.1 |
| Navbar contient un CTA "Télécharger gratuitement" | `Navbar` | 1.5 |
| Footer contient les liens légaux et de contact | `Footer` | 1.3 |
| HeroSection rend 2 CTA | `HeroSection` | 2.3 |
| ModulesGrid rend exactement 6 cartes | `ModulesGrid` | 2.6 |
| PricingGrid rend exactement 4 plans | `PricingGrid` | 4.1 |
| Page Tarifs mentionne l'activation par clé de licence | `PricingFaq` | 4.6 |
| Page Téléchargement affiche version et date | page `telechargement` | 5.1 |
| Page Téléchargement propose boutons Windows et Android | page `telechargement` | 5.2 |
| Pages d'accueil et de téléchargement contiennent un schema JSON-LD SoftwareApplication | pages SSG | 6.3 |
| Soumission réussie du formulaire → message de confirmation + réinitialisation | `ContactForm` | 9.4 |
| ContactForm pré-remplit le sujet depuis `/services` | `ContactForm` | 12.6 |

### Tests de propriétés (fast-check)

**Bibliothèque** : `fast-check` (TypeScript, génération de données arbitraires)

**Configuration** : minimum 100 itérations par test (`{ numRuns: 100 }`)

**Format de tag** : chaque test propriété doit inclure un commentaire de référence :
`// Feature: logesco-website, Property {N}: {texte de la propriété}`

| Test de propriété | Propriété validée | Notes |
|---|---|---|
| H1 word count < 12 pour toutes les locales | Propriété 1 | Générateur : locale aléatoire |
| HowItWorks steps entre 3 et 4 | Propriété 2 | Générateur : tableau d'étapes aléatoires |
| FeatureCard rend icône + titre + description | Propriété 3 | Générateur : `SoftwareModule` aléatoire |
| Exactement 1 plan recommandé dans tout tableau | Propriété 4 | Générateur : tableaux de `PricingPlan` |
| Tout PricingPlan a ≥ 1 fonctionnalité | Propriété 5 | Générateur : `PricingPlan` aléatoire |
| DownloadButton correct selon `available` | Propriété 6 | Générateur : `PlatformDownload` aléatoire |
| generateMetadata → title + description non vides | Propriété 7 | Générateur : (page, locale) aléatoires |
| Exactement 1 H1 par page rendue | Propriété 8 | Générateur : locale × route aléatoires |
| Toute image a un alt non vide | Propriété 9 | Générateur : données de page aléatoires |
| Métadonnées contiennent hreflang × 3 locales | Propriété 10 | Générateur : (page, locale) aléatoires |
| Routes préfixées par locale | Propriété 11 | Générateur : (route, locale) aléatoires |
| Formulaire invalide → bloqué + erreurs par champ | Propriété 12 | Générateur : données de formulaire invalides |
| Recherche doc → titre + extrait pour mots existants | Propriété 13 | Générateur : mots-clés issus de l'index |

### Exemple d'implémentation d'un test de propriété

```typescript
import fc from 'fast-check';
import { render, screen } from '@testing-library/react';
import { HeroSection } from '@/components/home/HeroSection';

// Feature: logesco-website, Property 1: Le titre H1 de la section Hero contient moins de 12 mots
test('Property 1: Hero H1 contains fewer than 12 words for any locale', () => {
  const locales = ['fr', 'en', 'es'] as const;
  locales.forEach((locale) => {
    const title = getHeroTitle(locale); // Récupère le titre traduit
    const wordCount = title.trim().split(/\s+/).length;
    expect(wordCount).toBeLessThan(12);
  });
});

// Feature: logesco-website, Property 12: Formulaire invalide bloqué avec erreurs par champ
test('Property 12: Contact form rejects invalid inputs with per-field errors', () => {
  fc.assert(
    fc.property(
      fc.record({
        name: fc.constant(''),           // Champ obligatoire vide
        email: fc.constant('not-email'), // Email invalide
        subject: fc.string(),
        message: fc.constant(''),        // Champ obligatoire vide
      }),
      (invalidData) => {
        const { result } = renderHook(() => useContactForm());
        // Déclencher la validation sans soumission
        const errors = validateContactForm(invalidData);
        expect(errors.name).toBeDefined();
        expect(errors.email).toBeDefined();
        expect(errors.message).toBeDefined();
      }
    ),
    { numRuns: 100 }
  );
});
```

### Accessibilité et performance

- Les tests d'accessibilité WCAG AA sont validés via `jest-axe` sur les composants critiques (Navbar, formulaires, DocSidebar)
- Les scores Lighthouse sont vérifiés en CI via `lighthouse-ci` configuré avec des seuils stricts (≥ 90)
- Les Core Web Vitals sont mesurés en staging via Vercel Analytics ou PageSpeed Insights avant tout déploiement en production
