/*
  Warnings:

  - Made the column `userId` on table `Customer` required. This step will fail if there are existing NULL values in that column.
  - Made the column `userId` on table `Firm` required. This step will fail if there are existing NULL values in that column.
  - Made the column `userId` on table `Invoice` required. This step will fail if there are existing NULL values in that column.
  - Made the column `userId` on table `Profile` required. This step will fail if there are existing NULL values in that column.
  - Made the column `userId` on table `Vehicle` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "Customer" ALTER COLUMN "userId" SET NOT NULL;

-- AlterTable
ALTER TABLE "Firm" ALTER COLUMN "userId" SET NOT NULL;

-- AlterTable
ALTER TABLE "Invoice" ALTER COLUMN "userId" SET NOT NULL;

-- AlterTable
ALTER TABLE "Profile" ALTER COLUMN "userId" SET NOT NULL;

-- AlterTable
ALTER TABLE "Vehicle" ALTER COLUMN "userId" SET NOT NULL;

-- CreateTable
CREATE TABLE "api_audit_logs" (
    "id" TEXT NOT NULL,
    "apiKeyId" TEXT,
    "userId" TEXT,
    "method" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "query" JSONB,
    "statusCode" INTEGER NOT NULL,
    "ip" TEXT,
    "userAgent" TEXT,
    "durationMs" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "api_audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "api_audit_logs_apiKeyId_createdAt_idx" ON "api_audit_logs"("apiKeyId", "createdAt");

-- CreateIndex
CREATE INDEX "api_audit_logs_userId_createdAt_idx" ON "api_audit_logs"("userId", "createdAt");
