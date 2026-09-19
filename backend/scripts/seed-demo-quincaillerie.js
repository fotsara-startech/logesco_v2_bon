#!/usr/bin/env node
/**
 * ==========================================================================
 *  JEU DE DONNÉES DE DÉMONSTRATION — QUINCAILLERIE
 *  Destiné aux captures d'écran du site web et aux démos commerciales.
 * ==========================================================================
 *
 *  Secteur      : quincaillerie / matériaux de construction (gamme cohérente)
 *  Boutiques    : 2 (magasin principal + agence)
 *  Historique   : 6 mois (mars → août 2026)
 *  Entreprise   : 100 % fictive — aucune donnée réelle de client ou fournisseur
 *
 *  ⚠️  DESTRUCTIF : efface toutes les données métier de la base ciblée par
 *      DATABASE_URL avant de régénérer. À n'exécuter que sur une base de démo.
 *
 *  Usage :
 *      set DATABASE_URL=file:C:/.../logesco.db
 *      node scripts/seed-demo-quincaillerie.js
 *
 *  Le générateur est déterministe (graine fixe) : deux exécutions produisent
 *  exactement le même jeu de données, donc les mêmes chiffres sur les captures.
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

// ═══════════════════════════════════════════════════════════════════════════
//  PARAMÈTRES
// ═══════════════════════════════════════════════════════════════════════════

const AUJOURDHUI = new Date(2026, 7, 10);  // 10 août 2026 — jour de référence
const DEBUT_HISTORIQUE = new Date(2026, 2, 1); // 1er mars 2026
const DATE_STOCK_INITIAL = new Date(2026, 1, 24); // 24 février 2026
const TAUX_TVA = 19.25;
const MOT_DE_PASSE_DEMO = 'Demo2026!';
const FOND_DE_CAISSE = 100000;

// Coefficient mensuel : légère croissance, l'activité monte en saison sèche.
const COEFF_MOIS = { 2: 0.90, 3: 0.96, 4: 1.00, 5: 1.07, 6: 1.14, 7: 1.18 };

// ═══════════════════════════════════════════════════════════════════════════
//  ALÉATOIRE DÉTERMINISTE
// ═══════════════════════════════════════════════════════════════════════════

function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rnd = mulberry32(20260806);
const ri = (a, b) => Math.floor(rnd() * (b - a + 1)) + a;      // entier [a,b]
const rf = (a, b) => rnd() * (b - a) + a;                       // flottant
const pick = (arr) => arr[Math.floor(rnd() * arr.length)];
const chance = (p) => rnd() < p;
const round = (n, pas = 25) => Math.round(n / pas) * pas;

const jour = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const addJours = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
const at = (d, h, m, s = 0) => new Date(d.getFullYear(), d.getMonth(), d.getDate(), h, m, s);

// ═══════════════════════════════════════════════════════════════════════════
//  CATALOGUE PRODUITS
//  [référence, désignation, prix de vente HT, prix d'achat, seuil d'alerte]
// ═══════════════════════════════════════════════════════════════════════════

const CATALOGUE = {
  'Ciment & agrégats': [
    ['CIM-001', 'Ciment CPJ 35 — sac de 50 kg', 4900, 4480, 60],
    ['CIM-002', 'Ciment CPJ 42.5R — sac de 50 kg', 5450, 5000, 60],
    ['CIM-003', 'Ciment blanc — sac de 50 kg', 12500, 11300, 10],
    ['CIM-004', 'Chaux hydratée — sac de 25 kg', 4200, 3700, 15],
    ['CIM-005', 'Colle à carrelage grise — sac de 25 kg', 5800, 5050, 20],
    ['CIM-006', 'Colle à carrelage blanche — sac de 25 kg', 7200, 6300, 12],
    ['CIM-007', 'Enduit de lissage intérieur — sac de 25 kg', 6500, 5650, 12],
    ['CIM-008', 'Mortier de jointoiement — sac de 5 kg', 3200, 2700, 20],
    ['CIM-009', 'Sable fin lavé — sac de 50 kg', 1500, 1100, 40],
    ['CIM-010', 'Gravier 5/15 — sac de 50 kg', 1800, 1350, 40],
    ['CIM-011', 'Parpaing creux 15 — pièce', 450, 360, 200],
    ['CIM-012', 'Parpaing creux 20 — pièce', 600, 480, 150],
    ['CIM-013', 'Hourdis 15 — pièce', 850, 690, 100],
    ['CIM-014', 'Adjuvant plastifiant — bidon 5 L', 9500, 8200, 8],
    ['CIM-015', 'Hydrofuge de masse — bidon 5 L', 11000, 9500, 8],
    ['CIM-016', 'Résine d\'accrochage — bidon 5 L', 13500, 11700, 6],
  ],
  'Fer & profilés': [
    ['FER-006', 'Fer à béton HA 6 mm — barre de 12 m', 2950, 2680, 50],
    ['FER-008', 'Fer à béton HA 8 mm — barre de 12 m', 4650, 4230, 50],
    ['FER-010', 'Fer à béton HA 10 mm — barre de 12 m', 7200, 6560, 40],
    ['FER-012', 'Fer à béton HA 12 mm — barre de 12 m', 10400, 9480, 40],
    ['FER-014', 'Fer à béton HA 14 mm — barre de 12 m', 14200, 12950, 20],
    ['FER-016', 'Fer à béton HA 16 mm — barre de 12 m', 18500, 16900, 15],
    ['FER-020', 'Fer à béton HA 20 mm — barre de 12 m', 28500, 26100, 10],
    ['FER-030', 'Fil de fer recuit — rouleau de 5 kg', 6400, 5550, 15],
    ['FER-031', 'Treillis soudé ST25 — panneau 2 × 1 m', 12500, 11000, 12],
    ['FER-040', 'Cornière 30 × 30 × 3 — barre de 6 m', 8900, 7900, 10],
    ['FER-041', 'Cornière 40 × 40 × 4 — barre de 6 m', 13200, 11800, 8],
    ['FER-042', 'Fer plat 30 × 4 — barre de 6 m', 6800, 6000, 10],
    ['FER-043', 'Fer plat 40 × 5 — barre de 6 m', 9600, 8500, 8],
    ['FER-050', 'Tube carré 30 × 30 — barre de 6 m', 8700, 7700, 10],
    ['FER-051', 'Tube carré 40 × 40 — barre de 6 m', 11500, 10200, 10],
    ['FER-052', 'Tube rectangulaire 60 × 40 — barre de 6 m', 16800, 15000, 6],
    ['FER-060', 'Tube rond galvanisé 1/2" — barre de 6 m', 9800, 8700, 12],
    ['FER-061', 'Tube rond galvanisé 3/4" — barre de 6 m', 12900, 11500, 10],
    ['FER-062', 'Tube rond galvanisé 1" — barre de 6 m', 16500, 14700, 8],
    ['FER-070', 'Tôle noire 2 mm — feuille 1 × 2 m', 22000, 19800, 6],
    ['FER-071', 'Tôle noire 3 mm — feuille 1 × 2 m', 32500, 29300, 4],
    ['FER-080', 'Électrode de soudure 2.5 mm — paquet de 5 kg', 8500, 7350, 12],
  ],
  'Plomberie & PVC': [
    ['PVC-032', 'Tube PVC évacuation Ø 32 — barre de 3 m', 2100, 1750, 20],
    ['PVC-040', 'Tube PVC évacuation Ø 40 — barre de 3 m', 2750, 2300, 20],
    ['PVC-050', 'Tube PVC évacuation Ø 50 — barre de 3 m', 3600, 3020, 20],
    ['PVC-063', 'Tube PVC évacuation Ø 63 — barre de 3 m', 5200, 4380, 15],
    ['PVC-075', 'Tube PVC évacuation Ø 75 — barre de 3 m', 6800, 5720, 15],
    ['PVC-090', 'Tube PVC évacuation Ø 90 — barre de 3 m', 9200, 7750, 12],
    ['PVC-110', 'Tube PVC évacuation Ø 110 — barre de 3 m', 13500, 11400, 10],
    ['PVC-160', 'Tube PVC évacuation Ø 160 — barre de 3 m', 27000, 23000, 5],
    ['PPR-020', 'Tube PPR eau chaude Ø 20 — barre de 4 m', 3400, 2850, 15],
    ['PPR-025', 'Tube PPR eau chaude Ø 25 — barre de 4 m', 4600, 3870, 15],
    ['PPR-032', 'Tube PPR eau chaude Ø 32 — barre de 4 m', 6900, 5800, 10],
    ['RAC-001', 'Coude PVC 90° Ø 40', 350, 260, 60],
    ['RAC-002', 'Coude PVC 90° Ø 63', 650, 480, 50],
    ['RAC-003', 'Coude PVC 90° Ø 110', 1450, 1080, 30],
    ['RAC-004', 'Té PVC Ø 63', 950, 710, 30],
    ['RAC-005', 'Té PVC Ø 110', 2100, 1570, 25],
    ['RAC-006', 'Manchon PVC Ø 110', 900, 670, 30],
    ['RAC-007', 'Réduction PVC 110/63', 1100, 820, 25],
    ['RAC-008', 'Siphon de sol PVC 110 × 110', 3800, 3150, 15],
    ['RAC-010', 'Colle PVC — pot de 250 g', 2400, 1980, 25],
    ['RAC-011', 'Colle PVC — pot de 1 kg', 7200, 6100, 10],
    ['RAC-012', 'Téflon PTFE — rouleau 12 m', 250, 165, 100],
    ['RAC-013', 'Filasse de plomberie — sachet 50 g', 400, 280, 60],
    ['RAC-020', 'Raccord laiton 1/2" mâle-femelle', 1200, 940, 30],
    ['RAC-021', 'Raccord laiton 3/4" mâle-femelle', 1650, 1290, 25],
    ['RAC-030', 'Tuyau d\'arrosage renforcé Ø 20 — au mètre', 750, 590, 60],
    ['RAC-031', 'Collier de serrage inox 20-32 mm', 450, 320, 60],
    ['RAC-040', 'Vanne à bille laiton 1/2"', 3200, 2650, 20],
  ],
  'Électricité': [
    ['ELE-001', 'Câble souple 2 × 1.5 mm² — rouleau 100 m', 28500, 24800, 10],
    ['ELE-002', 'Câble souple 2 × 2.5 mm² — rouleau 100 m', 42000, 36600, 10],
    ['ELE-003', 'Câble souple 3 × 2.5 mm² — rouleau 100 m', 61000, 53200, 6],
    ['ELE-004', 'Fil rigide H07V-U 1.5 mm² — rouleau 100 m', 14500, 12500, 15],
    ['ELE-005', 'Fil rigide H07V-U 2.5 mm² — rouleau 100 m', 22500, 19400, 15],
    ['ELE-006', 'Fil rigide H07V-U 6 mm² — rouleau 100 m', 52000, 45200, 5],
    ['ELE-010', 'Gaine ICTA Ø 16 — couronne 50 m', 8500, 7100, 15],
    ['ELE-011', 'Gaine ICTA Ø 20 — couronne 50 m', 11200, 9400, 15],
    ['ELE-012', 'Goulotte PVC 40 × 25 — barre de 2 m', 2600, 2100, 30],
    ['ELE-020', 'Interrupteur simple allumage encastré', 1450, 1080, 40],
    ['ELE-021', 'Interrupteur va-et-vient encastré', 1750, 1310, 35],
    ['ELE-022', 'Prise 2P+T 16 A encastrée', 1950, 1460, 40],
    ['ELE-023', 'Boîte d\'encastrement Ø 67', 350, 240, 100],
    ['ELE-024', 'Boîte de dérivation étanche 100 × 100', 1600, 1220, 30],
    ['ELE-030', 'Disjoncteur divisionnaire 10 A', 3400, 2780, 25],
    ['ELE-031', 'Disjoncteur divisionnaire 16 A', 3600, 2950, 25],
    ['ELE-032', 'Disjoncteur divisionnaire 20 A', 3900, 3200, 20],
    ['ELE-033', 'Disjoncteur différentiel 30 mA — 40 A', 18500, 15900, 10],
    ['ELE-034', 'Coffret électrique 12 modules', 12500, 10600, 8],
    ['ELE-040', 'Ampoule LED 9 W E27', 1200, 880, 60],
    ['ELE-041', 'Ampoule LED 12 W E27', 1550, 1140, 50],
    ['ELE-042', 'Réglette LED 36 W — 1.20 m', 7500, 6300, 20],
    ['ELE-043', 'Projecteur LED 50 W étanche', 13500, 11500, 12],
    ['ELE-044', 'Douille E27 porcelaine', 650, 460, 50],
    ['ELE-050', 'Rallonge électrique 4 prises — 5 m', 6800, 5600, 15],
    ['ELE-051', 'Parafoudre monophasé', 34000, 29500, 4],
  ],
  'Peinture & finitions': [
    ['PEI-001', 'Peinture à eau blanche — seau de 20 L', 28500, 24500, 12],
    ['PEI-002', 'Peinture à eau blanche — seau de 5 L', 8500, 7200, 20],
    ['PEI-003', 'Peinture à eau teintée — seau de 20 L', 34000, 29200, 8],
    ['PEI-004', 'Peinture glycéro brillante — pot de 5 L', 16500, 14100, 12],
    ['PEI-005', 'Peinture antirouille — pot de 5 L', 15500, 13200, 10],
    ['PEI-006', 'Peinture antirouille — pot de 1 L', 3800, 3200, 25],
    ['PEI-007', 'Vernis bois incolore — pot de 5 L', 19500, 16700, 8],
    ['PEI-008', 'Lasure bois teinte chêne — pot de 5 L', 21500, 18400, 6],
    ['PEI-010', 'Enduit de rebouchage — pot de 5 kg', 5200, 4300, 15],
    ['PEI-011', 'Sous-couche universelle — seau de 20 L', 24000, 20500, 8],
    ['PEI-012', 'Diluant synthétique — bidon de 5 L', 7500, 6300, 15],
    ['PEI-013', 'White spirit — bidon de 1 L', 1800, 1420, 30],
    ['PEI-020', 'Rouleau à peindre 180 mm + manchon', 2400, 1850, 30],
    ['PEI-021', 'Manchon de rechange 180 mm', 1100, 800, 40],
    ['PEI-022', 'Rouleau à peindre 250 mm anti-goutte', 3600, 2850, 20],
    ['PEI-023', 'Pinceau plat 50 mm', 950, 690, 40],
    ['PEI-024', 'Pinceau plat 100 mm', 1600, 1180, 30],
    ['PEI-025', 'Bac à peinture 25 cm', 1400, 1050, 25],
    ['PEI-026', 'Ruban de masquage 48 mm × 40 m', 1250, 920, 40],
    ['PEI-027', 'Bâche de protection 4 × 5 m', 3400, 2700, 20],
    ['PEI-028', 'Papier abrasif grain 120 — feuille', 300, 195, 100],
    ['PEI-029', 'Couteau à enduire 250 mm', 2200, 1700, 20],
  ],
  'Outillage à main': [
    ['OUT-001', 'Marteau de charpentier 500 g', 4200, 3350, 20],
    ['OUT-002', 'Massette 1250 g manche bois', 6500, 5300, 12],
    ['OUT-003', 'Masse 5 kg manche bois', 13500, 11400, 8],
    ['OUT-004', 'Truelle langue de chat 200 mm', 3200, 2500, 25],
    ['OUT-005', 'Truelle carrée 200 mm', 3400, 2650, 25],
    ['OUT-006', 'Taloche plastique 280 × 140', 2600, 2000, 25],
    ['OUT-007', 'Règle de maçon aluminium 2 m', 9500, 8000, 10],
    ['OUT-008', 'Niveau à bulle 60 cm', 5800, 4700, 15],
    ['OUT-009', 'Niveau à bulle 120 cm', 11500, 9700, 10],
    ['OUT-010', 'Fil à plomb 250 g', 2400, 1850, 20],
    ['OUT-011', 'Mètre ruban 5 m', 2200, 1650, 40],
    ['OUT-012', 'Mètre ruban 8 m', 3600, 2800, 25],
    ['OUT-013', 'Équerre de menuisier 300 mm', 3800, 3000, 15],
    ['OUT-020', 'Scie égoïne 500 mm', 5200, 4200, 15],
    ['OUT-021', 'Scie à métaux + lame', 4600, 3700, 15],
    ['OUT-022', 'Lame de scie à métaux — lot de 10', 3200, 2500, 20],
    ['OUT-023', 'Ciseau à brique 250 mm', 4800, 3900, 12],
    ['OUT-030', 'Pince universelle 180 mm', 4400, 3550, 20],
    ['OUT-031', 'Pince coupante 160 mm', 4100, 3300, 20],
    ['OUT-032', 'Jeu de tournevis 6 pièces', 6800, 5500, 15],
    ['OUT-033', 'Clé à molette 250 mm', 5600, 4550, 15],
    ['OUT-034', 'Jeu de clés mixtes 8-22 mm — 12 pièces', 16500, 13800, 8],
    ['OUT-035', 'Pince multiprise 250 mm', 6200, 5000, 12],
    ['OUT-036', 'Cutter à lame sécable 18 mm', 1500, 1100, 35],
  ],
  'Outillage électroportatif': [
    ['ELP-001', 'Perceuse à percussion 750 W', 42000, 35500, 8],
    ['ELP-002', 'Perceuse-visseuse sans fil 18 V + 2 batteries', 78000, 66000, 5],
    ['ELP-003', 'Perforateur SDS-Plus 900 W', 96000, 82000, 4],
    ['ELP-004', 'Meuleuse d\'angle 125 mm — 900 W', 38500, 32500, 8],
    ['ELP-005', 'Meuleuse d\'angle 230 mm — 2200 W', 74000, 63000, 5],
    ['ELP-006', 'Scie circulaire 185 mm — 1400 W', 82000, 70000, 4],
    ['ELP-007', 'Ponceuse orbitale 300 W', 34000, 28500, 6],
    ['ELP-008', 'Poste à souder inverter 200 A', 135000, 116000, 3],
    ['ELP-010', 'Disque à tronçonner métal 125 mm', 850, 620, 60],
    ['ELP-011', 'Disque à tronçonner métal 230 mm', 1800, 1350, 40],
    ['ELP-012', 'Disque diamant 125 mm', 6500, 5300, 20],
    ['ELP-013', 'Disque diamant 230 mm', 14500, 12300, 10],
    ['ELP-014', 'Jeu de forets béton 5 pièces', 5400, 4350, 20],
    ['ELP-015', 'Jeu de forets métal HSS 13 pièces', 8900, 7300, 15],
  ],
  'Quincaillerie & fixation': [
    ['QUI-001', 'Pointe 40 mm — au kilo', 950, 730, 40],
    ['QUI-002', 'Pointe 60 mm — au kilo', 900, 690, 40],
    ['QUI-003', 'Pointe 80 mm — au kilo', 880, 670, 40],
    ['QUI-004', 'Pointe 100 mm — au kilo', 870, 660, 30],
    ['QUI-005', 'Pointe à tôle galvanisée — au kilo', 1450, 1140, 25],
    ['QUI-010', 'Vis à bois 4 × 40 — boîte de 200', 2400, 1850, 30],
    ['QUI-011', 'Vis à bois 5 × 60 — boîte de 200', 3200, 2500, 25],
    ['QUI-012', 'Vis autoperceuse 4.2 × 25 — boîte de 500', 4800, 3900, 20],
    ['QUI-013', 'Vis placo 3.5 × 35 — boîte de 500', 3600, 2850, 25],
    ['QUI-020', 'Cheville nylon Ø 8 — sachet de 100', 1800, 1350, 40],
    ['QUI-021', 'Cheville nylon Ø 10 — sachet de 100', 2500, 1900, 30],
    ['QUI-022', 'Cheville à frapper 6 × 40 — sachet de 100', 3400, 2700, 25],
    ['QUI-023', 'Tige filetée M10 — barre de 1 m', 2200, 1700, 30],
    ['QUI-024', 'Écrou M10 — sachet de 100', 3800, 3000, 20],
    ['QUI-025', 'Rondelle plate M10 — sachet de 100', 2100, 1600, 25],
    ['QUI-030', 'Charnière 100 mm — la paire', 2600, 2000, 25],
    ['QUI-031', 'Paumelle à souder 120 mm — la paire', 3400, 2700, 20],
    ['QUI-032', 'Serrure encastrable à cylindre', 12500, 10400, 12],
    ['QUI-033', 'Serrure de porte à bouton', 8500, 6900, 15],
    ['QUI-034', 'Cadenas 50 mm laiton', 4200, 3350, 25],
    ['QUI-035', 'Verrou de sûreté 100 mm', 3600, 2850, 20],
    ['QUI-036', 'Poignée de porte inox — la paire', 9500, 7900, 12],
    ['QUI-040', 'Cadenas antivol 70 mm', 8500, 7000, 10],
    ['QUI-041', 'Chaîne galvanisée Ø 6 — au mètre', 1800, 1400, 30],
    ['QUI-042', 'Câble acier Ø 6 — au mètre', 1200, 920, 40],
    ['QUI-043', 'Serre-câble Ø 6 — pièce', 550, 400, 50],
  ],
  'Menuiserie & bois': [
    ['BOI-001', 'Chevron sapin 6 × 8 — 4 m', 5800, 4900, 30],
    ['BOI-002', 'Chevron sapin 8 × 8 — 4 m', 7600, 6400, 25],
    ['BOI-003', 'Planche coffrage 15 × 200 — 4 m', 4200, 3550, 40],
    ['BOI-004', 'Bastaing 6 × 15 — 4 m', 9800, 8300, 15],
    ['BOI-005', 'Contreplaqué 5 mm — panneau 1.22 × 2.44 m', 12500, 10600, 15],
    ['BOI-006', 'Contreplaqué 10 mm — panneau 1.22 × 2.44 m', 21500, 18400, 10],
    ['BOI-007', 'Contreplaqué 18 mm — panneau 1.22 × 2.44 m', 36500, 31300, 6],
    ['BOI-008', 'Panneau MDF 16 mm — 1.22 × 2.44 m', 27500, 23600, 6],
    ['BOI-009', 'Lambris PVC blanc — barre de 3 m', 3200, 2600, 30],
    ['BOI-010', 'Plinthe MDF 70 mm — barre de 2.40 m', 2400, 1900, 30],
    ['BOI-011', 'Porte isoplane 70 × 200 nue', 28500, 24200, 8],
    ['BOI-012', 'Porte isoplane 80 × 200 nue', 31500, 26800, 8],
    ['BOI-013', 'Bloc-porte prêt à poser 80 × 200', 62000, 53000, 4],
    ['BOI-014', 'Colle à bois vinylique — pot de 1 kg', 3600, 2900, 20],
  ],
  'Toiture & étanchéité': [
    ['TOI-001', 'Tôle bac aluzinc 30/100 — 3 m', 11500, 9900, 25],
    ['TOI-002', 'Tôle bac aluzinc 30/100 — 4 m', 15200, 13100, 20],
    ['TOI-003', 'Tôle bac aluzinc 40/100 — 3 m', 14800, 12700, 15],
    ['TOI-004', 'Tôle ondulée galvanisée 28/100 — 3 m', 9800, 8400, 25],
    ['TOI-005', 'Faîtière aluzinc — 2 m', 8500, 7250, 15],
    ['TOI-006', 'Rive de toiture aluzinc — 2 m', 7200, 6150, 12],
    ['TOI-007', 'Tire-fond de toiture 8 × 80 — boîte de 100', 6800, 5600, 15],
    ['TOI-008', 'Rondelle d\'étanchéité EPDM — sachet de 100', 2800, 2200, 20],
    ['TOI-010', 'Gouttière PVC — barre de 4 m', 9500, 8100, 12],
    ['TOI-011', 'Descente de gouttière PVC Ø 80 — 3 m', 6500, 5500, 12],
    ['TOI-012', 'Bitume d\'étanchéité — bidon de 20 L', 34000, 29200, 6],
    ['TOI-013', 'Membrane bitumineuse — rouleau 10 m²', 27500, 23500, 6],
    ['TOI-014', 'Mastic d\'étanchéité polyuréthane — cartouche', 4200, 3400, 25],
    ['TOI-015', 'Mousse expansive PU — bombe 750 ml', 4800, 3900, 20],
  ],
  'Sanitaire & robinetterie': [
    ['SAN-001', 'WC à poser complet avec réservoir', 68000, 58000, 6],
    ['SAN-002', 'Lavabo sur colonne 55 cm', 42000, 35800, 6],
    ['SAN-003', 'Lave-mains 40 cm', 24000, 20400, 8],
    ['SAN-004', 'Receveur de douche 80 × 80', 46000, 39200, 4],
    ['SAN-005', 'Évier inox 1 bac + égouttoir', 38500, 32800, 6],
    ['SAN-006', 'Baignoire acrylique 170 cm', 165000, 142000, 2],
    ['SAN-010', 'Mitigeur lavabo chromé', 16500, 13900, 12],
    ['SAN-011', 'Mitigeur évier col de cygne', 21500, 18200, 10],
    ['SAN-012', 'Mitigeur douche + flexible', 24500, 20800, 10],
    ['SAN-013', 'Robinet simple 1/2" chromé', 4800, 3900, 25],
    ['SAN-014', 'Robinet de puisage laiton 1/2"', 3600, 2900, 30],
    ['SAN-015', 'Flexible de douche inox 1.50 m', 4200, 3400, 25],
    ['SAN-016', 'Pommeau de douche 3 jets', 5500, 4450, 20],
    ['SAN-020', 'Mécanisme de chasse complet', 9500, 7900, 15],
    ['SAN-021', 'Abattant WC thermodur', 12500, 10500, 12],
    ['SAN-022', 'Siphon de lavabo PVC', 2400, 1850, 25],
    ['SAN-023', 'Chauffe-eau électrique 50 L', 118000, 101000, 3],
    ['SAN-024', 'Chauffe-eau électrique 100 L', 165000, 142000, 2],
  ],
  'Sécurité & EPI': [
    ['EPI-001', 'Casque de chantier blanc', 4500, 3600, 20],
    ['EPI-002', 'Casque de chantier jaune', 4500, 3600, 20],
    ['EPI-003', 'Gants de manutention — la paire', 1200, 880, 60],
    ['EPI-004', 'Gants anti-coupure — la paire', 3200, 2550, 25],
    ['EPI-005', 'Lunettes de protection incolores', 2400, 1850, 30],
    ['EPI-006', 'Masque anti-poussière FFP2 — boîte de 20', 6500, 5300, 15],
    ['EPI-007', 'Bouchons d\'oreille — lot de 10 paires', 2200, 1700, 20],
    ['EPI-008', 'Chaussures de sécurité S3 — pointure 41', 28500, 24200, 8],
    ['EPI-009', 'Chaussures de sécurité S3 — pointure 43', 28500, 24200, 8],
    ['EPI-010', 'Bottes de chantier PVC — pointure 42', 9500, 7900, 12],
    ['EPI-011', 'Gilet haute visibilité', 3400, 2700, 25],
    ['EPI-012', 'Harnais antichute 2 points', 42000, 35800, 4],
  ],
};

// Prestations facturées (sans stock)
const SERVICES = [
  ['SRV-001', 'Découpe de fer sur mesure — la coupe', 500, 0],
  ['SRV-002', 'Livraison sur chantier — zone urbaine', 12000, 0],
  ['SRV-003', 'Livraison sur chantier — hors ville', 28000, 0],
  ['SRV-004', 'Location bétonnière 350 L — la journée', 18000, 0],
  ['SRV-005', 'Location échafaudage — le module / jour', 4500, 0],
];

// ═══════════════════════════════════════════════════════════════════════════
//  TIERS
// ═══════════════════════════════════════════════════════════════════════════

const FOURNISSEURS = [
  ['SOCIMAT DISTRIBUTION SARL', 'M. Bekolo Aristide', '+237 233 40 12 08', 'commercial@socimat-demo.cm', 'Zone industrielle Bassa, Douala'],
  ['ETS FER & ACIER DU LITTORAL', 'M. Njoya Salifou', '+237 233 42 55 17', 'ventes@feracier-demo.cm', 'Akwa Nord, Douala'],
  ['CAMPLAST INDUSTRIE SARL', 'Mme Tchoumi Berthe', '+237 233 39 71 44', 'contact@camplast-demo.cm', 'Bonabéri, Douala'],
  ['ELECTRO-SUPPLY CAMEROUN', 'M. Fouda Serge', '+237 222 21 63 90', 'achats@electrosupply-demo.cm', 'Rue de Nachtigal, Yaoundé'],
  ['COLORAMA PEINTURES SARL', 'Mme Ngo Bayiha Clarisse', '+237 233 43 28 61', 'info@colorama-demo.cm', 'Deïdo, Douala'],
  ['OUTILPRO IMPORT SARL', 'M. Kamdem Rodrigue', '+237 222 20 84 32', 'outilpro.demo@mail.cm', 'Mvog-Mbi, Yaoundé'],
  ['TOLERIE MODERNE DU WOURI', 'M. Ekwalla Dieudonné', '+237 233 37 19 05', 'tolerie.demo@mail.cm', 'Ndokotti, Douala'],
  ['SANITEC CAMEROUN SARL', 'Mme Abanda Prisca', '+237 222 23 47 76', 'commercial@sanitec-demo.cm', 'Mvan, Yaoundé'],
];

// Clients professionnels : facturés avec TVA, achètent souvent à crédit.
const CLIENTS_PRO = [
  ['ETS BATIR PLUS SARL', null, '+237 677 41 22 09', 'contact@batirplus-demo.cm', 'Nkolbisson, Yaoundé', 'M051812345678K', 'RC/YAO/2018/B/1247'],
  ['ENTREPRISE SOGEBAT SARL', null, '+237 699 05 73 18', 'sogebat.demo@mail.cm', 'Nsam, Yaoundé', 'M071915224417P', 'RC/YAO/2019/B/0882'],
  ['CONSTRUCTIONS MEKONGO & FILS', null, '+237 677 88 34 51', 'mekongo.demo@mail.cm', 'Odza, Yaoundé', 'M041711983320B', 'RC/YAO/2017/B/2016'],
  ['STPM TRAVAUX PUBLICS SARL', null, '+237 233 22 91 40', 'stpm.demo@mail.cm', 'Ekounou, Yaoundé', 'M092016447729L', 'RC/YAO/2020/B/0431'],
  ['MENUISERIE MODERNE DU CENTRE', null, '+237 694 12 60 77', 'mmc.demo@mail.cm', 'Mvog-Ada, Yaoundé', 'M031614772205R', 'RC/YAO/2016/B/1533'],
  ['ETS NDONGO CONSTRUCTION', null, '+237 677 03 55 82', 'ndongo.btp.demo@mail.cm', 'Emana, Yaoundé', 'M052118330964T', 'RC/YAO/2021/B/0709'],
  ['IMMOBILIERE LA COLLINE SARL', null, '+237 699 74 18 26', 'lacolline.demo@mail.cm', 'Bastos, Yaoundé', 'M081917552108C', 'RC/YAO/2019/B/1198'],
  ['GENIE CIVIL ESSOMBA SARL', null, '+237 677 29 40 63', 'gce.demo@mail.cm', 'Mendong, Yaoundé', 'M062015889041F', 'RC/YAO/2020/B/1654'],
  ['PLOMBERIE SERVICE PLUS', null, '+237 694 66 21 39', 'psp.demo@mail.cm', 'Biyem-Assi, Yaoundé', 'M022213004576N', 'RC/YAO/2022/B/0355'],
  ['ELECTRO-BAT INSTALLATIONS SARL', null, '+237 699 31 87 04', 'electrobat.demo@mail.cm', 'Etoa-Meki, Yaoundé', 'M112118667203S', 'RC/YAO/2021/B/1902'],
  ['COMPLEXE SCOLAIRE LA SEMENCE', null, '+237 222 31 05 68', 'intendance.demo@mail.cm', 'Nkolndongo, Yaoundé', 'M011512446780D', 'RC/YAO/2015/B/0244'],
  ['HOTEL LE MANGUIER SARL', null, '+237 233 20 77 15', 'technique.demo@mail.cm', 'Warda, Yaoundé', 'M101816205933G', 'RC/YAO/2018/B/1476'],
  ['AGRO-FERME DE LA LEKIE SARL', null, '+237 677 55 92 40', 'lekie.demo@mail.cm', 'Monatélé, Lékié', 'M072017119844M', 'RC/YAO/2020/B/0968'],
  ['ETS TCHINDA MATERIAUX', null, '+237 694 08 46 71', 'tchinda.demo@mail.cm', 'Mokolo, Yaoundé', 'M041813557092V', 'RC/YAO/2018/B/2288'],
];

// Clients particuliers : noms fictifs, achats au comptant pour l'essentiel.
const CLIENTS_PART = [
  ['Ateba', 'Jean-Claude', '+237 677 12 45 88'],
  ['Ngo Bikai', 'Solange', '+237 699 63 21 07'],
  ['Owona', 'Célestin', '+237 677 84 33 19'],
  ['Mbarga', 'Félicité', '+237 694 27 60 45'],
  ['Tchana', 'Bertrand', '+237 699 15 74 92'],
  ['Eyenga', 'Marie-Josée', '+237 677 50 08 63'],
  ['Nkoulou', 'Armand', '+237 694 71 39 26'],
  ['Bassong', 'Édith', '+237 699 42 85 10'],
  ['Fotso', 'Guy-Roger', '+237 677 96 24 57'],
  ['Manga', 'Pauline', '+237 694 33 17 80'],
  ['Onana', 'Sylvain', '+237 699 08 52 41'],
  ['Ndzana', 'Régine', '+237 677 65 90 23'],
  ['Kouam', 'Hervé', '+237 694 49 06 78'],
  ['Abena', 'Christiane', '+237 699 27 63 15'],
  ['Belinga', 'Théodore', '+237 677 31 48 92'],
  ['Ngono', 'Antoinette', '+237 694 82 15 30'],
  ['Zambo', 'Patrick', '+237 699 56 71 04'],
  ['Etoundi', 'Bernadette', '+237 677 19 37 66'],
  ['Djoumessi', 'Landry', '+237 694 60 24 89'],
  ['Amougou', 'Véronique', '+237 699 73 41 52'],
  ['Nyobe', 'Emmanuel', '+237 677 45 82 17'],
  ['Tsala', 'Georgette', '+237 694 11 58 43'],
  ['Bikoi', 'Alphonse', '+237 699 34 07 96'],
  ['Menye', 'Julienne', '+237 677 78 29 51'],
  ['Ondoa', 'Cyrille', '+237 694 95 63 20'],
  ['Mekongo', 'Adeline', '+237 699 21 46 87'],
  ['Bilounga', 'Franck', '+237 677 62 15 34'],
  ['Ateba Ze', 'Micheline', '+237 694 38 71 05'],
  ['Ndoumbe', 'Serge', '+237 699 84 26 19'],
];

// ═══════════════════════════════════════════════════════════════════════════
//  PURGE
// ═══════════════════════════════════════════════════════════════════════════

async function purger() {
  console.log('🧹 Purge des données existantes...');
  const ordre = [
    'movementAttachment', 'financialMovement', 'movementCategory',
    'reimpressionRecu', 'historiqueRecu',
    'detailVenteProforma', 'venteProforma',
    'inventoryItem', 'stockInventory',
    'transactionCompte',
    'detailVente', 'vente',
    'cashMovement', 'cashSession', 'cashRegister',
    'detailCommandeApprovisionnement', 'commandeApprovisionnement',
    'mouvementStock', 'transfertStock', 'datePeremption',
    'historiquePrixAchat', 'stockBoutique', 'stock',
    'produit', 'category',
    'compteClient', 'client', 'compteFournisseur', 'fournisseur',
    'userBoutiqueAssignment', 'utilisateur', 'userRole', 'boutique',
    'parametresEntreprise',
    'operationLog', 'deletedRecord',
  ];
  for (const modele of ordre) {
    try { await prisma[modele].deleteMany({}); }
    catch (e) { console.warn(`   ⚠️  ${modele}: ${e.message.split('\n')[0]}`); }
  }
  console.log('   ✅ Base vidée\n');
}

// ═══════════════════════════════════════════════════════════════════════════
//  SEED
// ═══════════════════════════════════════════════════════════════════════════

async function main() {
  console.log('\n╔══════════════════════════════════════════════════════════╗');
  console.log('║  JEU DE DONNÉES DÉMO — QUINCAILLERIE LE BÂTISSEUR SARL   ║');
  console.log('╚══════════════════════════════════════════════════════════╝\n');

  await purger();

  // ── 1. Rôles ────────────────────────────────────────────────────────────
  console.log('[1/14] Rôles...');
  const privilegesComplets = {
    users: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    roles: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    products: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    categories: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    sales: ['CREATE', 'READ', 'UPDATE', 'DELETE', 'BACKDATE'],
    inventory: ['CREATE', 'READ', 'UPDATE', 'DELETE', 'ADJUST'],
    stock_inventory: ['CREATE', 'READ', 'UPDATE', 'DELETE', 'COUNT'],
    customers: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    suppliers: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    accounts: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    procurement: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    reports: ['READ', 'EXPORT'],
    dashboard: ['READ', 'STATS'],
    company_settings: ['READ', 'UPDATE'],
    cash_registers: ['CREATE', 'READ', 'UPDATE', 'DELETE', 'OPEN', 'CLOSE'],
    financial_movements: ['CREATE', 'READ', 'UPDATE', 'DELETE', 'REPORTS'],
    boutiques: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
    proformas: ['CREATE', 'READ', 'UPDATE', 'DELETE'],
  };

  const privilegesCaissier = {
    products: ['READ'],
    categories: ['READ'],
    sales: ['CREATE', 'READ'],
    inventory: ['READ'],
    customers: ['CREATE', 'READ', 'UPDATE'],
    accounts: ['READ'],
    dashboard: ['READ'],
    cash_registers: ['READ', 'OPEN', 'CLOSE'],
    proformas: ['CREATE', 'READ'],
  };

  const privilegesMagasinier = {
    products: ['CREATE', 'READ', 'UPDATE'],
    categories: ['READ'],
    inventory: ['CREATE', 'READ', 'UPDATE', 'ADJUST'],
    stock_inventory: ['CREATE', 'READ', 'UPDATE', 'COUNT'],
    suppliers: ['READ'],
    procurement: ['CREATE', 'READ', 'UPDATE'],
    dashboard: ['READ'],
  };

  // Le rôle « admin » doit exister : l'application le recrée au démarrage s'il
  // est absent (AdminService.ensureAdminExists), ce qui réintroduirait un
  // compte « admin » visible sur les captures.
  await prisma.userRole.create({
    data: { id: 1, nom: 'admin', displayName: 'Administrateur', isAdmin: true, privileges: JSON.stringify(privilegesComplets) },
  });
  await prisma.userRole.create({
    data: { id: 2, nom: 'gerant', displayName: 'Gérant', isAdmin: true, privileges: JSON.stringify(privilegesComplets) },
  });
  await prisma.userRole.create({
    data: { id: 3, nom: 'caissier', displayName: 'Caissier', isAdmin: false, privileges: JSON.stringify(privilegesCaissier) },
  });
  await prisma.userRole.create({
    data: { id: 4, nom: 'magasinier', displayName: 'Magasinier', isAdmin: false, privileges: JSON.stringify(privilegesMagasinier) },
  });
  console.log('   ✅ 4 rôles\n');

  // ── 2. Utilisateurs ─────────────────────────────────────────────────────
  console.log('[2/14] Utilisateurs...');
  const hash = await bcrypt.hash(MOT_DE_PASSE_DEMO, 10);
  const hashAdmin = await bcrypt.hash('Adm1n-D3mo-2026', 10);

  // Compte technique désactivé, uniquement là pour empêcher la recréation
  // automatique d'un utilisateur « admin » par l'application.
  await prisma.utilisateur.create({
    data: {
      id: 1, nomUtilisateur: 'admin', email: null, motDePasseHash: hashAdmin,
      roleId: 1, isActive: false, dateCreation: DATE_STOCK_INITIAL,
    },
  });

  const UTILISATEURS = [
    [2, 'Thierry Nkoulou', 't.nkoulou@lebatisseur-demo.cm', 2],   // gérant
    [3, 'Alice Mballa', 'a.mballa@lebatisseur-demo.cm', 3],       // caissière B1
    [4, 'Patrick Essomba', 'p.essomba@lebatisseur-demo.cm', 3],   // caissier B1
    [5, 'Sandrine Ngo Bell', 's.ngobell@lebatisseur-demo.cm', 3], // caissière B2
    [6, 'Rodrigue Ekani', 'r.ekani@lebatisseur-demo.cm', 4],      // magasinier
  ];
  for (const [id, nom, email, roleId] of UTILISATEURS) {
    await prisma.utilisateur.create({
      data: {
        id, nomUtilisateur: nom, email, motDePasseHash: hash, roleId,
        isActive: true, dateCreation: DATE_STOCK_INITIAL,
        dateDerniereConnexion: at(AUJOURDHUI, 7, ri(30, 55)),
      },
    });
  }
  const GERANT = 2, CAISSIER_B1 = [3, 4], CAISSIER_B2 = 5, MAGASINIER = 6;
  console.log('   ✅ 5 comptes réels + 1 compte technique désactivé\n');

  // ── 3. Boutiques ────────────────────────────────────────────────────────
  console.log('[3/14] Boutiques...');
  await prisma.boutique.create({
    data: {
      id: 1, nom: 'Magasin Central — Nkoldongo', adresse: 'Rue 1.842, Nkoldongo, Yaoundé',
      telephone: '+237 222 31 40 55', email: 'nkoldongo@lebatisseur-demo.cm',
      description: 'Magasin principal et dépôt', estPrincipale: true, isActive: true,
      dateCreation: DATE_STOCK_INITIAL,
    },
  });
  await prisma.boutique.create({
    data: {
      id: 2, nom: 'Agence Mvan', adresse: 'Carrefour Mvan, face station, Yaoundé',
      telephone: '+237 222 31 40 56', email: 'mvan@lebatisseur-demo.cm',
      description: 'Point de vente secondaire', estPrincipale: false, isActive: true,
      dateCreation: DATE_STOCK_INITIAL,
    },
  });

  const AFFECTATIONS = [
    [GERANT, 1, 2], [GERANT, 2, 2],
    [3, 1, 3], [4, 1, 3], [5, 2, 3], [MAGASINIER, 1, 4],
  ];
  let idAff = 1;
  for (const [u, b, r] of AFFECTATIONS) {
    await prisma.userBoutiqueAssignment.create({
      data: { id: idAff++, utilisateurId: u, boutiqueId: b, roleId: r, isActive: true, dateCreation: DATE_STOCK_INITIAL },
    });
  }
  console.log('   ✅ 2 boutiques, 6 affectations\n');

  // ── 4. Paramètres entreprise ────────────────────────────────────────────
  console.log('[4/14] Paramètres entreprise...');
  await prisma.parametresEntreprise.create({
    data: {
      id: 1,
      nomEntreprise: 'QUINCAILLERIE LE BÂTISSEUR SARL',
      adresse: 'Rue 1.842, Nkoldongo — BP 4187 Yaoundé',
      localisation: 'Yaoundé, Cameroun',
      telephone: '+237 222 31 40 55 / +237 677 40 12 90',
      email: 'contact@lebatisseur-demo.cm',
      nuiRccm: 'NUI M041814772093X — RCCM RC/YAO/2018/B/1042',
      slogan: 'Tout pour bâtir, au juste prix',
      langueFacture: 'fr',
      tauxTva: TAUX_TVA,
      dateCreation: DATE_STOCK_INITIAL,
    },
  });
  console.log('   ✅ Entreprise fictive configurée\n');

  // ── 5. Catégories & produits ────────────────────────────────────────────
  console.log('[5/14] Catégories et produits...');
  const categories = [];
  let idCat = 1;
  for (const nom of Object.keys(CATALOGUE)) {
    categories.push(await prisma.category.create({
      data: { id: idCat++, nom, description: `Rayon ${nom.toLowerCase()}`, dateCreation: DATE_STOCK_INITIAL },
    }));
  }
  const catServices = await prisma.category.create({
    data: { id: idCat++, nom: 'Prestations & services', description: 'Prestations facturées sans stock', dateCreation: DATE_STOCK_INITIAL },
  });

  const produits = [];   // { id, ref, nom, pv, pa, seuil, catId, service }
  let idProd = 1;
  const lignesProduits = [];
  Object.entries(CATALOGUE).forEach(([nomCat, items], iCat) => {
    for (const [ref, nom, pv, pa, seuil] of items) {
      const p = { id: idProd++, ref, nom, pv, pa, seuil, catId: iCat + 1, service: false };
      produits.push(p);
      lignesProduits.push({
        id: p.id, reference: ref, nom, prixUnitaire: pv, prixAchat: pa, cump: pa,
        codeBarre: `61${String(2000000 + p.id * 37).padStart(11, '0')}`.slice(0, 13),
        categorieId: p.catId, seuilStockMinimum: seuil, estActif: true, estService: false,
        remiseMaxAutorisee: 10, gestionPeremption: false, dateCreation: DATE_STOCK_INITIAL,
      });
    }
  });
  for (const [ref, nom, pv] of SERVICES) {
    const p = { id: idProd++, ref, nom, pv, pa: 0, seuil: 0, catId: catServices.id, service: true };
    produits.push(p);
    lignesProduits.push({
      id: p.id, reference: ref, nom, prixUnitaire: pv, prixAchat: 0, cump: 0,
      codeBarre: null, categorieId: catServices.id, seuilStockMinimum: 0,
      estActif: true, estService: true, remiseMaxAutorisee: 0, gestionPeremption: false,
      dateCreation: DATE_STOCK_INITIAL,
    });
  }
  await prisma.produit.createMany({ data: lignesProduits });
  const produitsStock = produits.filter((p) => !p.service);
  console.log(`   ✅ ${categories.length + 1} catégories, ${produits.length} produits (dont ${SERVICES.length} prestations)\n`);

  // ── 6. Fournisseurs & clients ───────────────────────────────────────────
  console.log('[6/14] Fournisseurs et clients...');
  let idF = 1;
  for (const [nom, contact, tel, email, adr] of FOURNISSEURS) {
    await prisma.fournisseur.create({
      data: { id: idF, nom, personneContact: contact, telephone: tel, email, adresse: adr, dateCreation: DATE_STOCK_INITIAL },
    });
    await prisma.compteFournisseur.create({
      data: { id: idF, fournisseurId: idF, soldeActuel: 0, limiteCredit: 5000000 },
    });
    idF++;
  }

  const clients = [];  // { id, nom, pro }
  let idC = 1;
  for (const [nom, prenom, tel, email, adr, nui, rccm] of CLIENTS_PRO) {
    await prisma.client.create({
      data: {
        id: idC, nom, prenom, telephone: tel, email, adresse: adr, nui, rccm,
        dateCreation: addJours(DATE_STOCK_INITIAL, -ri(30, 700)),
      },
    });
    clients.push({ id: idC, nom, pro: true });
    idC++;
  }
  for (const [nom, prenom, tel] of CLIENTS_PART) {
    await prisma.client.create({
      data: {
        id: idC, nom, prenom, telephone: tel, adresse: pick(['Nkoldongo', 'Mvan', 'Odza', 'Biyem-Assi', 'Emana', 'Mendong', 'Nsam', 'Ekounou']) + ', Yaoundé',
        dateCreation: addJours(DATE_STOCK_INITIAL, -ri(10, 500)),
      },
    });
    clients.push({ id: idC, nom, pro: false });
    idC++;
  }
  const clientsPro = clients.filter((c) => c.pro);
  console.log(`   ✅ ${FOURNISSEURS.length} fournisseurs, ${clients.length} clients (${clientsPro.length} professionnels)\n`);

  // ── 7. Caisses & catégories de dépenses ─────────────────────────────────
  console.log('[7/14] Caisses et catégories de dépenses...');
  await prisma.cashRegister.create({
    data: {
      id: 1, nom: 'Caisse Principale', description: 'Caisse du magasin central',
      soldeInitial: FOND_DE_CAISSE, soldeActuel: FOND_DE_CAISSE, isActive: true,
      boutiqueId: 1, dateCreation: DATE_STOCK_INITIAL,
    },
  });
  await prisma.cashRegister.create({
    data: {
      id: 2, nom: 'Caisse Agence Mvan', description: 'Caisse du point de vente Mvan',
      soldeInitial: 50000, soldeActuel: 50000, isActive: true,
      boutiqueId: 2, dateCreation: DATE_STOCK_INITIAL,
    },
  });

  const CATEGORIES_DEPENSES = [
    [1, 'achats', 'Achats de marchandises', '#EF4444', 'shopping_cart'],
    [2, 'charges', 'Charges et frais', '#F59E0B', 'receipt_long'],
    [3, 'salaires', 'Salaires du personnel', '#10B981', 'people'],
    [4, 'maintenance', 'Maintenance et réparations', '#8B5CF6', 'build'],
    [5, 'transport', 'Transport et livraison', '#06B6D4', 'local_shipping'],
    [6, 'autres', 'Autres dépenses', '#6B7280', 'more_horiz'],
  ];
  for (const [id, nom, displayName, color, icon] of CATEGORIES_DEPENSES) {
    await prisma.movementCategory.create({
      data: { id, nom, displayName, color, icon, isDefault: true, isActive: true, dateCreation: DATE_STOCK_INITIAL },
    });
  }
  console.log('   ✅ 2 caisses, 6 catégories de dépenses\n');

  // ── 8. Stock initial (approvisionnement de départ) ───────────────────────
  console.log('[8/14] Stock initial...');
  // stock[boutiqueId][produitId] = quantité
  const stock = { 1: {}, 2: {} };
  const mouvementsStock = [];
  let idMvt = 1;

  const ajouterMouvement = (boutiqueId, produitId, type, delta, date, typeRef, refId, notes) => {
    const avant = stock[boutiqueId][produitId] || 0;
    const apres = avant + delta;
    stock[boutiqueId][produitId] = apres;
    mouvementsStock.push({
      id: idMvt++, produitId, boutiqueId, typeMouvement: type, changementQuantite: delta,
      stockInitial: avant, stockFinal: apres, referenceId: refId || null,
      typeReference: typeRef || null, dateMouvement: date, notes: notes || null,
    });
    return apres;
  };

  for (const p of produitsStock) {
    // Le magasin central porte l'essentiel du stock, l'agence un stock tampon.
    const base = Math.max(4, Math.round(p.seuil * rf(3.2, 5.5)));
    ajouterMouvement(1, p.id, 'entree', base, at(DATE_STOCK_INITIAL, 8, 30), 'initialisation', null, 'Stock initial à l\'ouverture du logiciel');
    const baseB2 = Math.max(2, Math.round(p.seuil * rf(0.8, 1.6)));
    ajouterMouvement(2, p.id, 'entree', baseB2, at(DATE_STOCK_INITIAL, 9, 15), 'initialisation', null, 'Stock initial à l\'ouverture du logiciel');
  }
  console.log(`   ✅ Stock initial posé sur ${produitsStock.length} références × 2 boutiques\n`);

  // ── 9. Simulation des ventes ────────────────────────────────────────────
  console.log('[9/14] Simulation des ventes sur 6 mois...');

  const ventes = [], detailsVentes = [], sessions = [], mouvementsCaisse = [];
  const transactions = [];
  let idVente = 1, idDetail = 1, idSession = 1, idMvtCaisse = 1, idTx = 1;

  // Solde courant des comptes clients (négatif = dette)
  const soldeClient = {};
  clients.forEach((c) => { soldeClient[c.id] = 0; });

  // Poids de tirage : les consommables partent plus vite que le gros matériel.
  const poids = produitsStock.map((p) => {
    let w = 1;
    if (p.pv < 1500) w = 5;
    else if (p.pv < 6000) w = 4;
    else if (p.pv < 20000) w = 2.5;
    else if (p.pv < 60000) w = 1.2;
    else w = 0.5;
    return w;
  });
  const poidsTotal = poids.reduce((a, b) => a + b, 0);
  const tirerProduit = () => {
    let r = rnd() * poidsTotal;
    for (let i = 0; i < produitsStock.length; i++) {
      r -= poids[i];
      if (r <= 0) return produitsStock[i];
    }
    return produitsStock[produitsStock.length - 1];
  };

  const quantitePour = (p) => {
    if (p.pv < 1000) return ri(3, 30);
    if (p.pv < 3000) return ri(2, 14);
    if (p.pv < 8000) return ri(1, 9);
    if (p.pv < 20000) return ri(1, 5);
    if (p.pv < 60000) return ri(1, 3);
    return 1;
  };

  const CONFIG_BOUTIQUES = [
    { id: 1, caisseId: 1, caissiers: CAISSIER_B1, fond: FOND_DE_CAISSE, ventesMin: 3, ventesMax: 6 },
    { id: 2, caisseId: 2, caissiers: [CAISSIER_B2], fond: 50000, ventesMin: 1, ventesMax: 3 },
  ];

  let sessionOuverteId = null;   // session encore ouverte aujourd'hui (capture caisse)

  // Deux bons de commande de chantier, encaissés ce matin au magasin central.
  // Ce sont eux qui alimenteront la capture « facture ».
  const PANIERS_VITRINE = [
    // Gros œuvre — dalle et chaînage
    [['FER-010', 25], ['FER-008', 40], ['FER-031', 12], ['FER-030', 6], ['CIM-013', 80], ['SRV-002', 1]],
    // Installation électrique d'un logement
    [['ELE-005', 6], ['ELE-011', 10], ['ELE-022', 40], ['ELE-021', 25], ['ELE-030', 20], ['ELE-034', 3]],
  ];
  const CLIENTS_VITRINE = ['ENTREPRISE SOGEBAT SARL', 'ELECTRO-BAT INSTALLATIONS SARL'];

  // ── Réapprovisionnement, intégré au fil des jours ────────────────────────
  // Les commandes doivent être passées et reçues AU FUR ET À MESURE, sinon le
  // stock ne fait que décroître pendant six mois et les ventes s'arrêtent.
  const commandes = [], detailsCommandes = [];
  const receptionsEnAttente = [];
  let idCmd = 1, idDetCmd = 1, seqCmd = 0;
  const prochaineCommande = { 1: addJours(DEBUT_HISTORIQUE, 2), 2: addJours(DEBUT_HISTORIQUE, 4) };

  const passerCommande = (d, boutiqueId) => {
    // On commande ce qui est descendu sous trois fois le seuil d'alerte.
    const candidats = produitsStock
      .filter((p) => (stock[boutiqueId][p.id] || 0) < p.seuil * 3)
      .sort((a, b) => (stock[boutiqueId][a.id] || 0) / a.seuil - (stock[boutiqueId][b.id] || 0) / b.seuil)
      .slice(0, ri(14, 28));
    if (candidats.length === 0) return;

    const cid = idCmd++;
    seqCmd++;
    const numero = `CMD${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}${String(seqCmd % 1000).padStart(3, '0')}`;
    const dateCommande = at(d, 9, ri(0, 59));
    // Les camions sont dechargés avant l'ouverture : la reception precede
    // donc toujours les ventes du jour, ce qui garde la chaine de mouvements
    // de stock strictement chronologique.
    const dateReception = at(addJours(d, ri(1, 3)), 7, ri(0, 25));
    const fournisseurId = ri(1, FOURNISSEURS.length);

    let montantTotal = 0;
    const lignes = [];
    for (const p of candidats) {
      const manque = Math.max(0, Math.round(p.seuil * rf(4.5, 7)) - (stock[boutiqueId][p.id] || 0));
      const q = Math.max(p.seuil, manque);
      montantTotal += q * p.pa;
      lignes.push({ p, q });
    }

    const recue = dateReception <= at(AUJOURDHUI, 8, 0);
    const modePaiement = chance(0.6) ? 'comptant' : 'credit';
    const montantPaye = modePaiement === 'comptant' ? montantTotal : round(montantTotal * rf(0.3, 0.6), 1000);

    commandes.push({
      id: cid, numeroCommande: numero, fournisseurId, boutiqueId,
      statut: recue ? 'recue' : 'en_attente',
      dateCommande, dateLivraisonPrevue: dateReception,
      montantTotal, montantPaye, montantRestant: montantTotal - montantPaye,
      modePaiement,
      notes: recue ? 'Livraison conforme au bon de commande' : 'Livraison attendue',
    });
    for (const { p, q } of lignes) {
      detailsCommandes.push({
        id: idDetCmd++, commandeId: cid, produitId: p.id,
        quantiteCommandee: q, quantiteRecue: recue ? q : 0, coutUnitaire: p.pa,
      });
    }
    if (recue) receptionsEnAttente.push({ dateReception, boutiqueId, lignes, cid, numero });
  };

  const encaisserReceptions = (limite) => {
    for (let k = receptionsEnAttente.length - 1; k >= 0; k--) {
      const r = receptionsEnAttente[k];
      if (r.dateReception > limite) continue;
      for (const { p, q } of r.lignes) {
        ajouterMouvement(r.boutiqueId, p.id, 'entree', q, r.dateReception, 'commande', r.cid, `Réception commande ${r.numero}`);
      }
      receptionsEnAttente.splice(k, 1);
    }
  };

  for (let d = new Date(DEBUT_HISTORIQUE); d <= AUJOURDHUI; d = addJours(d, 1)) {
    const jourSemaine = d.getDay();          // 0 = dimanche

    // Réceptions fournisseurs du jour, puis nouvelles commandes.
    encaisserReceptions(at(d, 8, 0));
    for (const bid of [1, 2]) {
      if (d >= prochaineCommande[bid] && jourSemaine !== 0) {
        passerCommande(d, bid);
        prochaineCommande[bid] = addJours(d, ri(3, 5));
      }
    }

    if (jourSemaine === 0) continue;          // magasin fermé le dimanche
    const coeff = COEFF_MOIS[d.getMonth()] ?? 1;
    const coeffJour = jourSemaine === 6 ? 1.35 : (jourSemaine === 1 ? 1.1 : 1);
    const estAujourdhui = d.getTime() === AUJOURDHUI.getTime();

    for (const bt of CONFIG_BOUTIQUES) {
      // La session encore ouverte aujourd'hui sert à la capture « caisse » :
      // on y fixe la caissière pour que la documentation reste exacte.
      const caissier = (estAujourdhui && bt.id === 1)
        ? CAISSIER_B1[0]
        : (bt.caissiers.length === 1
          ? bt.caissiers[0]
          : bt.caissiers[(Math.floor(d.getDate() / 3) + bt.id) % bt.caissiers.length]);

      const sid = idSession++;
      const heureOuverture = at(d, 7, ri(35, 55));
      let soldeAttendu = bt.fond;

      // Nombre de ventes du jour
      let n = Math.round(ri(bt.ventesMin, bt.ventesMax) * coeff * coeffJour);
      if (estAujourdhui) n = bt.id === 1 ? 7 : 3;   // journée en cours, matinée écoulée

      const ventesDuJour = [];
      for (let i = 0; i < n; i++) {
        // Heure de la vente
        const hMax = estAujourdhui ? 12 : 18;
        const h = ri(8, hMax);
        const dateVente = at(d, h, ri(0, 59), ri(0, 59));

        // Les premières ventes du jour au magasin central sont des dossiers
        // « vitrine » : plusieurs lignes, client professionnel, TVA facturée.
        // C'est de là que sortiront les captures facture et devis.
        const vitrine = estAujourdhui && bt.id === 1 && i < 2;

        // Profil du panier
        const r = rnd();
        let nbLignes, facteur;
        if (vitrine) { nbLignes = i === 0 ? 6 : 5; facteur = 'gros'; }
        else if (r < 0.58) { nbLignes = ri(1, 3); facteur = 'petit'; }
        else if (r < 0.88) { nbLignes = ri(2, 4); facteur = 'moyen'; }
        else { nbLignes = ri(4, 7); facteur = 'gros'; }

        // Client : les gros paniers sont majoritairement professionnels
        let client = null;
        if (vitrine) client = clients.find((c) => c.nom === CLIENTS_VITRINE[i]);
        else if (facteur === 'gros') client = chance(0.85) ? pick(clientsPro) : pick(clients);
        else if (facteur === 'moyen') client = chance(0.5) ? pick(clients) : null;
        else client = chance(0.2) ? pick(clients) : null;

        // Lignes — on retire un produit distinct et effectivement en stock
        const lignes = [];
        const dejaPris = new Set();

        // Les paniers vitrine sont composés à la main : un vrai bon de commande
        // de chantier se lit mieux qu'un tirage aléatoire sur la capture.
        if (vitrine) {
          for (const [ref, q] of PANIERS_VITRINE[i]) {
            const pr = produits.find((x) => x.ref === ref);
            if (!pr) continue;
            const dispo = pr.service ? q : (stock[bt.id][pr.id] || 0);
            if (dispo <= 0) continue;
            lignes.push({ p: pr, q: Math.min(q, dispo), prixUnitaire: pr.pv, prixAffiche: pr.pv, remise: 0 });
            dejaPris.add(pr.id);
          }
        }

        let essais = 0;
        while (!vitrine && lignes.length < nbLignes && essais < nbLignes * 12) {
          essais++;
          const p = tirerProduit();
          if (dejaPris.has(p.id)) continue;
          const dispo = stock[bt.id][p.id] || 0;
          if (dispo <= 0) continue;
          dejaPris.add(p.id);

          let q = quantitePour(p);
          if (facteur === 'gros') q = Math.ceil(q * rf(1.3, 2.2));
          if (facteur === 'petit') q = Math.max(1, Math.ceil(q * 0.45));
          if (q > dispo) q = dispo;

          const remise = chance(0.12) ? round(p.pv * rf(0.02, 0.08), 25) : 0;
          const prixUnitaire = p.pv - remise;
          lignes.push({ p, q, prixUnitaire, prixAffiche: p.pv, remise });
        }
        // Prestation de livraison sur les gros paniers
        if (!vitrine && facteur === 'gros' && chance(0.45)) {
          const refSrv = chance(0.25) ? 'SRV-003' : 'SRV-002';
          const srv = produits.find((x) => x.ref === refSrv);
          lignes.push({ p: srv, q: 1, prixUnitaire: srv.pv, prixAffiche: srv.pv, remise: 0 });
        }
        if (lignes.length === 0) continue;

        // sousTotal = somme des lignes au prix déjà remisé (DetailVente.prixUnitaire).
        // montantRemise est une remise GLOBALE supplémentaire, distincte des
        // remises de ligne : la déduire ici aussi fausserait le total de la facture.
        const sousTotal = lignes.reduce((s, l) => s + l.prixUnitaire * l.q, 0);
        const montantRemise = (!vitrine && facteur !== 'petit' && chance(0.15))
          ? round(sousTotal * rf(0.02, 0.05), 500) : 0;

        // TVA : facturée aux professionnels (facture normalisée), pas au détail.
        const avecTva = vitrine || (!!(client && client.pro) && chance(0.85));
        const montantTva = avecTva ? Math.round(sousTotal * TAUX_TVA / 100) : 0;
        const montantTotal = sousTotal - montantRemise + montantTva;

        // Paiement : crédit réservé aux professionnels
        let modePaiement = 'comptant';
        let montantPaye = montantTotal;
        if (!vitrine && client && client.pro && chance(0.42)) {
          modePaiement = 'credit';
          montantPaye = chance(0.55) ? round(montantTotal * rf(0.3, 0.7), 500) : 0;
        }
        const montantRestant = montantTotal - montantPaye;

        const vid = idVente++;
        const numero = `VTE-${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}-${String(dateVente.getHours()).padStart(2, '0')}${String(dateVente.getMinutes()).padStart(2, '0')}${String(dateVente.getSeconds()).padStart(2, '0')}${bt.id === 2 ? 'M' : ''}${vid % 10}`;

        ventes.push({
          id: vid, numeroVente: numero, clientId: client ? client.id : null,
          vendeurId: caissier, sessionId: sid, boutiqueId: bt.id, dateVente,
          sousTotal, montantRemise, montantTva, tauxTva: avecTva ? TAUX_TVA : null,
          montantTotal, statut: 'terminee', modePaiement, montantPaye, montantRestant,
        });

        for (const l of lignes) {
          detailsVentes.push({
            id: idDetail++, venteId: vid, produitId: l.p.id, quantite: l.q,
            prixUnitaire: l.prixUnitaire, prixAffiche: l.prixAffiche,
            remiseAppliquee: l.remise, prixTotal: l.prixUnitaire * l.q,
            justificationRemise: l.remise > 0 ? 'Remise commerciale accordée' : null,
          });
          if (!l.p.service) {
            ajouterMouvement(bt.id, l.p.id, 'sortie', -l.q, dateVente, 'vente', vid, `Vente ${numero}`);
          }
        }

        // Encaissement en caisse
        if (montantPaye > 0) {
          mouvementsCaisse.push({
            id: idMvtCaisse++, caisseId: bt.caisseId, sessionId: sid, boutiqueId: bt.id,
            type: 'vente', montant: montantPaye,
            description: `Vente ${numero}${client ? ` - Client: ${client.nom}` : ''}`,
            utilisateurId: caissier, dateCreation: dateVente,
            metadata: JSON.stringify({ categorie: 'vente', referenceType: 'vente', referenceId: vid, venteReference: numero, montantTotal, montantVerse: montantPaye }),
          });
          soldeAttendu += montantPaye;
        }

        // Compte client
        if (client) {
          const soldeAvant = soldeClient[client.id];
          const nouveauSolde = soldeAvant + montantPaye - montantTotal;
          soldeClient[client.id] = nouveauSolde;
          transactions.push({
            id: idTx++, typeCompte: 'client', compteId: client.id,
            typeTransaction: 'achat_credit',
            typeTransactionDetail: montantRestant > 0 ? 'achat_credit' : 'achat_comptant',
            montant: montantTotal,
            description: `Achat ${montantRestant > 0 ? 'à crédit' : 'comptant'} - Vente ${numero}`,
            referenceType: 'vente', referenceId: vid, venteId: vid, venteReference: numero,
            boutiqueId: bt.id, dateTransaction: dateVente, soldeApres: nouveauSolde,
          });
          if (montantPaye > 0) {
            transactions.push({
              id: idTx++, typeCompte: 'client', compteId: client.id,
              typeTransaction: 'paiement', typeTransactionDetail: 'paiement_vente',
              montant: montantPaye,
              description: `Paiement de ${montantPaye} FCFA pour vente ${numero}`,
              referenceType: 'vente', referenceId: vid, venteId: vid, venteReference: numero,
              boutiqueId: bt.id, dateTransaction: at(dateVente, dateVente.getHours(), dateVente.getMinutes(), Math.min(59, dateVente.getSeconds() + 1)),
              soldeApres: nouveauSolde,
            });
          }
        }

        ventesDuJour.push({ vid, numero, dateVente });
      }

      // Règlements de créances : un professionnel passe régulièrement solder.
      if (!estAujourdhui && bt.id === 1 && chance(0.55)) {
        const endettes = clientsPro.filter((c) => soldeClient[c.id] < -20000);
        if (endettes.length) {
          const c = pick(endettes);
          const dette = -soldeClient[c.id];
          const versement = round(Math.min(dette, dette * rf(0.4, 1.0)), 500);
          if (versement > 0) {
            const dateReg = at(d, ri(10, 16), ri(0, 59));
            soldeClient[c.id] += versement;
            transactions.push({
              id: idTx++, typeCompte: 'client', compteId: c.id,
              typeTransaction: 'paiement', typeTransactionDetail: 'paiement_dette',
              montant: versement,
              description: `Règlement de créance — ${c.nom}`,
              referenceType: 'reglement', referenceId: null, boutiqueId: bt.id,
              dateTransaction: dateReg, soldeApres: soldeClient[c.id],
            });
            mouvementsCaisse.push({
              id: idMvtCaisse++, caisseId: bt.caisseId, sessionId: sid, boutiqueId: bt.id,
              type: 'paiement_dette', montant: versement,
              description: `Règlement créance - ${c.nom}`,
              utilisateurId: caissier, dateCreation: dateReg,
              metadata: JSON.stringify({ categorie: 'paiement_dette', clientId: c.id, clientNom: c.nom }),
            });
            soldeAttendu += versement;
          }
        }
      }

      // Clôture : versement à la banque, on laisse le fond de caisse.
      if (!estAujourdhui || bt.id === 2) {
        const aVerser = Math.max(0, round(soldeAttendu - bt.fond, 500));
        if (aVerser > 0) {
          const dateVersement = at(d, 18, ri(5, 25));
          mouvementsCaisse.push({
            id: idMvtCaisse++, caisseId: bt.caisseId, sessionId: sid, boutiqueId: bt.id,
            type: 'sortie', montant: aVerser,
            description: 'Versement bancaire de fin de journée',
            utilisateurId: caissier, dateCreation: dateVersement,
            metadata: JSON.stringify({ categorie: 'versement_banque' }),
          });
          soldeAttendu -= aVerser;
        }
        // Petit écart de caisse de temps en temps : le logiciel le met en évidence.
        const ecart = chance(0.06) ? pick([-500, -1000, 500, -250]) : 0;
        const soldeFermeture = Math.max(0, soldeAttendu + ecart);
        sessions.push({
          id: sid, caisseId: bt.caisseId, utilisateurId: caissier, boutiqueId: bt.id,
          soldeOuverture: bt.fond, soldeFermeture, soldeAttendu,
          ecart: soldeFermeture - soldeAttendu,
          dateOuverture: heureOuverture, dateFermeture: at(d, 18, ri(30, 50)),
          isActive: false,
        });
      } else {
        // Session du jour, toujours ouverte → capture « caisse en session »
        sessionOuverteId = sid;
        sessions.push({
          id: sid, caisseId: bt.caisseId, utilisateurId: caissier, boutiqueId: bt.id,
          soldeOuverture: bt.fond, soldeFermeture: null, soldeAttendu, ecart: null,
          dateOuverture: heureOuverture, dateFermeture: null, isActive: true,
        });
        await prisma.cashRegister.update({
          where: { id: bt.caisseId },
          data: { soldeActuel: soldeAttendu, utilisateurId: caissier, dateOuverture: heureOuverture, dateFermeture: null },
        });
      }
    }
  }

  console.log(`   • ${ventes.length} ventes générées, écriture en base...`);
  await prisma.cashSession.createMany({ data: sessions });
  for (let i = 0; i < ventes.length; i += 500) await prisma.vente.createMany({ data: ventes.slice(i, i + 500) });
  for (let i = 0; i < detailsVentes.length; i += 500) await prisma.detailVente.createMany({ data: detailsVentes.slice(i, i + 500) });
  for (let i = 0; i < mouvementsCaisse.length; i += 500) await prisma.cashMovement.createMany({ data: mouvementsCaisse.slice(i, i + 500) });
  for (let i = 0; i < transactions.length; i += 500) await prisma.transactionCompte.createMany({ data: transactions.slice(i, i + 500) });

  const caTotal = ventes.reduce((s, v) => s + v.montantTotal, 0);
  console.log(`   ✅ ${ventes.length} ventes · ${detailsVentes.length} lignes · CA ${Math.round(caTotal).toLocaleString('fr-FR')} FCFA\n`);

  // ── 10. Comptes clients ─────────────────────────────────────────────────
  console.log('[10/14] Comptes clients...');
  let idCompte = 1;
  for (const c of clients) {
    await prisma.compteClient.create({
      data: {
        id: idCompte++, clientId: c.id, soldeActuel: Math.round(soldeClient[c.id]),
        limiteCredit: c.pro ? pick([500000, 1000000, 1500000, 2000000]) : 0,
      },
    });
  }
  const endettes = clients.filter((c) => soldeClient[c.id] < -1000);
  const totalCreances = endettes.reduce((s, c) => s - soldeClient[c.id], 0);
  console.log(`   ✅ ${clients.length} comptes · ${endettes.length} clients débiteurs · ${Math.round(totalCreances).toLocaleString('fr-FR')} FCFA de créances\n`);

  // ── 11. Réapprovisionnements ────────────────────────────────────────────
  console.log('[11/14] Commandes d\'approvisionnement...');
  // Les commandes ont été générées au fil de la simulation (étape 9) ; il reste
  // à créer deux commandes en cours de livraison pour que l'écran « Approvi-
  // sionnement » ne montre pas que des lignes soldées.
  for (const bid of [1, 2]) {
    const d = addJours(AUJOURDHUI, -1);
    passerCommande(d, bid);
    const derniere = commandes[commandes.length - 1];
    if (derniere && derniere.boutiqueId === bid) {
      derniere.statut = 'en_attente';
      derniere.dateLivraisonPrevue = addJours(AUJOURDHUI, ri(1, 3));
      derniere.notes = 'Livraison attendue';
      detailsCommandes.filter((x) => x.commandeId === derniere.id).forEach((x) => { x.quantiteRecue = 0; });
      const idx = receptionsEnAttente.findIndex((r) => r.cid === derniere.id);
      if (idx >= 0) receptionsEnAttente.splice(idx, 1);
    }
  }

  for (let i = 0; i < commandes.length; i += 500) {
    await prisma.commandeApprovisionnement.createMany({ data: commandes.slice(i, i + 500) });
  }
  for (let i = 0; i < detailsCommandes.length; i += 500) {
    await prisma.detailCommandeApprovisionnement.createMany({ data: detailsCommandes.slice(i, i + 500) });
  }
  // Soldes fournisseurs (montants restant dus)
  for (let f = 1; f <= FOURNISSEURS.length; f++) {
    const du = commandes.filter((c) => c.fournisseurId === f).reduce((s, c) => s + c.montantRestant, 0);
    await prisma.compteFournisseur.update({ where: { fournisseurId: f }, data: { soldeActuel: Math.round(du) } });
  }
  console.log(`   ✅ ${commandes.length} commandes · ${detailsCommandes.length} lignes\n`);

  // ── 12. Alertes de rupture (inventaire tournant du 3 août) ──────────────
  console.log('[12/14] Inventaire tournant et alertes de rupture...');
  // Références volontairement placées sous le seuil pour la capture « stock ».
  const REFS_ALERTE = [
    ['CIM-002', 0.00],  // rupture totale — le best-seller
    ['FER-012', 0.00],  // rupture totale
    ['ELE-002', 0.35],
    ['PEI-001', 0.42],
    ['TOI-001', 0.28],
    ['CIM-001', 0.55],
    ['QUI-002', 0.60],
    ['SAN-010', 0.50],
    ['ELP-004', 0.38],
    ['PVC-110', 0.45],
  ];
  const dateInventaire = AUJOURDHUI;   // comptage du jour, cloture a 13h15
  const itemsInventaire = [];
  let idItem = 1;

  for (const [ref, ratio] of REFS_ALERTE) {
    const p = produitsStock.find((x) => x.ref === ref);
    if (!p) continue;
    const cible = Math.floor(p.seuil * ratio);
    const actuel = stock[1][p.id] || 0;
    const delta = cible - actuel;
    if (delta !== 0) {
      ajouterMouvement(1, p.id, delta > 0 ? 'entree' : 'sortie', delta,
        at(AUJOURDHUI, 13, 15), 'inventaire', 1,
        'Régularisation après inventaire tournant du 06/08/2026');
    }
    itemsInventaire.push({
      id: idItem++, inventaireId: 1, produitId: p.id,
      quantiteSysteme: actuel, quantiteComptee: cible, ecart: delta,
      prixUnitaire: p.pv, prixAchat: p.pa,
      commentaire: delta < 0 ? 'Écart constaté — sorties non saisies' : 'Écart positif',
      dateComptage: at(dateInventaire, ri(9, 12), ri(0, 59)),
      utilisateurComptageId: MAGASINIER,
    });
  }
  // Quelques références conformes pour que l'inventaire soit crédible
  const conformes = produitsStock.filter((p) => !REFS_ALERTE.some(([r]) => r === p.ref)).slice(0, 22);
  for (const p of conformes) {
    const q = stock[1][p.id] || 0;
    itemsInventaire.push({
      id: idItem++, inventaireId: 1, produitId: p.id,
      quantiteSysteme: q, quantiteComptee: q, ecart: 0,
      prixUnitaire: p.pv, prixAchat: p.pa, commentaire: null,
      dateComptage: at(dateInventaire, ri(9, 12), ri(0, 59)),
      utilisateurComptageId: MAGASINIER,
    });
  }

  await prisma.stockInventory.create({
    data: {
      id: 1, nom: 'Inventaire tournant — août 2026',
      description: 'Comptage des références à forte rotation, magasin central',
      type: 'PARTIEL', status: 'VALIDE', boutiqueId: 1, utilisateurId: MAGASINIER,
      dateCreation: at(dateInventaire, 8, 30),
      dateDebut: at(dateInventaire, 9, 0), dateFin: at(dateInventaire, 13, 15),
    },
  });
  await prisma.inventoryItem.createMany({ data: itemsInventaire });
  console.log(`   ✅ 1 inventaire (${itemsInventaire.length} références) · ${REFS_ALERTE.length} produits en alerte\n`);

  // ── 13. Écriture du stock final ─────────────────────────────────────────
  console.log('[13/14] Écriture du stock...');
  // La chaine stockInitial -> stockFinal est recalculee apres tri chronologique :
  // c'est elle qui fait foi, et le stock ecrit en base en decoule. Sans cela, un
  // mouvement enregistre hors ordre laisserait un historique incoherent.
  mouvementsStock.sort((a, b) => (a.dateMouvement - b.dateMouvement) || (a.id - b.id));
  const courant = {};
  for (const m of mouvementsStock) {
    const cle = `${m.boutiqueId}:${m.produitId}`;
    const avant = courant[cle] || 0;
    m.stockInitial = avant;
    m.stockFinal = avant + m.changementQuantite;
    courant[cle] = m.stockFinal;
  }
  const negatifs = mouvementsStock.filter((m) => m.stockFinal < 0).length;
  if (negatifs) console.warn(`   ⚠️  ${negatifs} mouvements laissent un stock negatif`);

  const lignesStockBoutique = [], lignesStock = [];
  let idSB = 1;
  for (const p of produitsStock) {
    const q1 = Math.max(0, courant[`1:${p.id}`] || 0);
    const q2 = Math.max(0, courant[`2:${p.id}`] || 0);
    lignesStockBoutique.push({ id: idSB++, boutiqueId: 1, produitId: p.id, quantiteDisponible: q1, quantiteReservee: 0 });
    lignesStockBoutique.push({ id: idSB++, boutiqueId: 2, produitId: p.id, quantiteDisponible: q2, quantiteReservee: 0 });
    lignesStock.push({ id: p.id, produitId: p.id, quantiteDisponible: q1 + q2, quantiteReservee: 0 });
  }
  for (let i = 0; i < lignesStockBoutique.length; i += 500) {
    await prisma.stockBoutique.createMany({ data: lignesStockBoutique.slice(i, i + 500) });
  }
  for (let i = 0; i < lignesStock.length; i += 500) {
    await prisma.stock.createMany({ data: lignesStock.slice(i, i + 500) });
  }
  for (let i = 0; i < mouvementsStock.length; i += 500) {
    await prisma.mouvementStock.createMany({ data: mouvementsStock.slice(i, i + 500) });
  }
  console.log(`   ✅ ${lignesStockBoutique.length} lignes de stock · ${mouvementsStock.length} mouvements\n`);

  // ── 14. Dépenses, devis ─────────────────────────────────────────────────
  console.log('[14/14] Dépenses et devis...');
  const depenses = [];
  let idDep = 1;
  const refDep = () => `MF-${String(idDep).padStart(6, '0')}`;

  const ajouterDepense = (date, montant, categorieId, description, notes) => {
    if (date > AUJOURDHUI) return;   // on n'enregistre pas une dépense future
    depenses.push({
      id: idDep, reference: refDep(), boutiqueId: 1, montant, categorieId,
      description, date, utilisateurId: GERANT, dateCreation: date,
      notes: notes || null, statut: 'actif',
    });
    idDep++;
  };

  for (let m = 2; m <= 7; m++) {
    const nbJours = new Date(2026, m + 1, 0).getDate();
    const mois = new Date(2026, m, 1).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });

    // Charges fixes — payées en fin de mois
    ajouterDepense(new Date(2026, m, Math.min(28, nbJours)), 350000, 2, `Loyer du magasin central — ${mois}`);
    ajouterDepense(new Date(2026, m, Math.min(28, nbJours)), 120000, 2, `Loyer agence Mvan — ${mois}`);
    ajouterDepense(new Date(2026, m, Math.min(30, nbJours)), 645000, 3, `Salaires du personnel — ${mois}`, '6 employés');
    ajouterDepense(new Date(2026, m, 15), round(rf(58000, 82000), 500), 2, `Facture d'électricité ENEO — ${mois}`);
    ajouterDepense(new Date(2026, m, 15), round(rf(14000, 22000), 500), 2, `Facture d'eau CAMWATER — ${mois}`);
    ajouterDepense(new Date(2026, m, 5), 30000, 2, `Internet et téléphonie — ${mois}`);

    // Charges variables
    for (let k = 0; k < ri(5, 9); k++) {
      ajouterDepense(new Date(2026, m, ri(1, nbJours)), round(rf(8000, 25000), 500), 5, pick([
        'Carburant camionnette de livraison',
        'Transport de marchandises depuis Douala',
        'Location véhicule pour livraison chantier',
        'Frais de manutention et déchargement',
      ]));
    }
    for (let k = 0; k < ri(1, 3); k++) {
      ajouterDepense(new Date(2026, m, ri(1, nbJours)), round(rf(15000, 65000), 500), 4, pick([
        'Entretien de la camionnette',
        'Réparation du rideau métallique',
        'Maintenance groupe électrogène',
        'Réparation chariot élévateur manuel',
      ]));
    }
    ajouterDepense(new Date(2026, m, ri(3, 20)), round(rf(12000, 35000), 500), 6, pick([
      'Fournitures de bureau et consommables',
      'Frais bancaires et commissions',
      'Publicité — banderoles et flyers',
      'Frais de nettoyage du magasin',
    ]));
    if (m % 3 === 2) {
      ajouterDepense(new Date(2026, m, 20), 90000, 2, 'Patente et taxes communales — trimestre');
    }
  }
  await prisma.financialMovement.createMany({ data: depenses });
  const totalDepenses = depenses.reduce((s, x) => s + x.montant, 0);
  console.log(`   • ${depenses.length} dépenses · ${totalDepenses.toLocaleString('fr-FR')} FCFA`);

  // Devis (proformas)
  const proformas = [], detailsProformas = [];
  let idPrf = 1, idDetPrf = 1;
  const MODELES_DEVIS = [
    { client: 'ETS BATIR PLUS SARL', jours: 1, statut: 'envoye', refs: ['CIM-002', 'FER-012', 'FER-010', 'FER-030', 'CIM-010', 'CIM-009'], qtes: [120, 45, 60, 8, 40, 60] },
    { client: 'ENTREPRISE SOGEBAT SARL', jours: 4, statut: 'accepte', refs: ['TOI-002', 'TOI-005', 'TOI-007', 'BOI-002', 'QUI-005'], qtes: [85, 14, 6, 40, 12] },
    { client: 'COMPLEXE SCOLAIRE LA SEMENCE', jours: 9, statut: 'envoye', refs: ['PEI-001', 'PEI-011', 'PEI-020', 'PEI-023', 'PEI-026', 'SRV-002'], qtes: [24, 12, 15, 20, 18, 1] },
    { client: 'HOTEL LE MANGUIER SARL', jours: 16, statut: 'accepte', refs: ['SAN-010', 'SAN-012', 'SAN-021', 'SAN-023', 'RAC-012'], qtes: [18, 12, 18, 4, 30] },
    { client: 'ELECTRO-BAT INSTALLATIONS SARL', jours: 23, statut: 'brouillon', refs: ['ELE-002', 'ELE-005', 'ELE-011', 'ELE-030', 'ELE-033', 'ELE-034'], qtes: [6, 8, 10, 24, 6, 4] },
  ];
  for (const m of MODELES_DEVIS) {
    const client = clients.find((c) => c.nom === m.client);
    const dateCreation = at(addJours(AUJOURDHUI, -m.jours), ri(9, 16), ri(0, 59));
    const pid = idPrf++;
    let sousTotal = 0;
    const lignes = [];
    m.refs.forEach((ref, i) => {
      const p = produits.find((x) => x.ref === ref);
      if (!p) return;
      const q = m.qtes[i];
      sousTotal += p.pv * q;
      lignes.push({ p, q });
    });
    const montantTva = Math.round(sousTotal * TAUX_TVA / 100);
    proformas.push({
      id: pid,
      numeroProforma: `PRF-${dateCreation.getFullYear()}${String(dateCreation.getMonth() + 1).padStart(2, '0')}-${String(pid).padStart(4, '0')}`,
      clientId: client.id, vendeurId: GERANT, boutiqueId: 1,
      dateVente: dateCreation, sousTotal, montantRemise: 0, montantTva, tauxTva: TAUX_TVA,
      montantTotal: sousTotal + montantTva, statut: m.statut, modePaiement: 'comptant',
      dateCreation,
    });
    for (const { p, q } of lignes) {
      detailsProformas.push({
        id: idDetPrf++, proformaId: pid, produitId: p.id, quantite: q,
        prixUnitaire: p.pv, prixAffiche: p.pv, remiseAppliquee: 0, prixTotal: p.pv * q,
      });
    }
  }
  await prisma.venteProforma.createMany({ data: proformas });
  await prisma.detailVenteProforma.createMany({ data: detailsProformas });
  console.log(`   • ${proformas.length} devis proforma\n`);

  // ── Récapitulatif ───────────────────────────────────────────────────────
  const debutMois = new Date(2026, 7, 1);
  const ventesMois = ventes.filter((v) => v.dateVente >= debutMois);
  const caMois = ventesMois.reduce((s, v) => s + v.montantTotal, 0);
  const juillet = ventes.filter((v) => v.dateVente >= new Date(2026, 6, 1) && v.dateVente < debutMois);
  const caJuillet = juillet.reduce((s, v) => s + v.montantTotal, 0);
  const cogsJuillet = juillet.reduce((s, v) => {
    return s + detailsVentes.filter((d) => d.venteId === v.id)
      .reduce((t, d) => t + (produits.find((p) => p.id === d.produitId)?.pa || 0) * d.quantite, 0);
  }, 0);
  const depJuillet = depenses.filter((x) => x.date >= new Date(2026, 6, 1) && x.date < debutMois)
    .reduce((s, x) => s + x.montant, 0);
  const enAlerte = produitsStock.filter((p) => (stock[1][p.id] || 0) <= p.seuil).length;

  const fmt = (n) => Math.round(n).toLocaleString('fr-FR') + ' FCFA';
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  RÉCAPITULATIF                                           ║');
  console.log('╚══════════════════════════════════════════════════════════╝');
  console.log(`  Produits actifs .............. ${produits.length}`);
  console.log(`  Clients ...................... ${clients.length} (dont ${clientsPro.length} professionnels)`);
  console.log(`  Ventes (6 mois) .............. ${ventes.length}`);
  console.log(`  CA cumulé .................... ${fmt(caTotal)}`);
  console.log(`  ─────────────────────────────────────────────`);
  console.log(`  Juillet 2026 — ventes ........ ${juillet.length}`);
  console.log(`  Juillet 2026 — CA ............ ${fmt(caJuillet)}`);
  console.log(`  Juillet 2026 — marge brute ... ${fmt(caJuillet - cogsJuillet)}`);
  console.log(`  Juillet 2026 — dépenses ...... ${fmt(depJuillet)}`);
  console.log(`  Juillet 2026 — bénéfice net .. ${fmt(caJuillet - cogsJuillet - depJuillet)}`);
  console.log(`  ─────────────────────────────────────────────`);
  console.log(`  Août (au ${AUJOURDHUI.getDate()}) — ventes ..... ${ventesMois.length}`);
  console.log(`  Août (au ${AUJOURDHUI.getDate()}) — CA ......... ${fmt(caMois)}`);
  console.log(`  ─────────────────────────────────────────────`);
  console.log(`  Créances clients ............. ${fmt(totalCreances)} sur ${endettes.length} comptes`);
  console.log(`  Produits sous le seuil (B1) .. ${enAlerte}`);
  console.log(`  Session de caisse ouverte .... #${sessionOuverteId} (Alice Mballa)`);
  console.log('');
  console.log('  🔑 Connexion pour les captures :');
  console.log(`     Utilisateur : Thierry Nkoulou   (Gérant, accès complet)`);
  console.log(`     Mot de passe : ${MOT_DE_PASSE_DEMO}`);
  console.log(`     Caissière    : Alice Mballa      (même mot de passe)`);
  console.log('');
}

main()
  .catch((e) => { console.error('\n❌ Erreur :', e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });
