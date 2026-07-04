-- Migration: add image_url to produits table
ALTER TABLE "produits" ADD COLUMN "image_url" TEXT;
