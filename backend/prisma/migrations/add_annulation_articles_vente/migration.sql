-- AlterTable
ALTER TABLE "details_ventes" ADD COLUMN "annule" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "details_ventes" ADD COLUMN "date_annulation" DATETIME;
