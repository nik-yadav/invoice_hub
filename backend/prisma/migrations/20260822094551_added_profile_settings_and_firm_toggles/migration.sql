-- AlterTable
ALTER TABLE "Firm" ADD COLUMN     "showEmailOnInvoice" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "showGstinOnInvoice" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "showPhoneOnInvoice" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "Profile" ADD COLUMN     "enablePostOfficeSelection" BOOLEAN NOT NULL DEFAULT false;
