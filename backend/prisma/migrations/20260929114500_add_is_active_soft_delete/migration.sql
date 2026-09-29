-- AlterTable User: Add isActive and ensure legacy/previous users are verified
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;
UPDATE "User" SET "isVerified" = true WHERE "verificationToken" IS NULL;

-- AlterTable Session: Add isActive
ALTER TABLE "Session" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable Profile: Add isActive
ALTER TABLE "Profile" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable Firm: Add isActive
ALTER TABLE "Firm" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable Customer: Add isActive
ALTER TABLE "Customer" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable Vehicle: Add isActive
ALTER TABLE "Vehicle" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable Invoice: Add isActive
ALTER TABLE "Invoice" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true;
