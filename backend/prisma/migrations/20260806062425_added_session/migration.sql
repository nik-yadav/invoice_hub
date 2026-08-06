-- DropIndex
DROP INDEX "Vehicle_vehicleNumber_key";

-- AlterTable
ALTER TABLE "Customer" ADD COLUMN     "userId" TEXT;

-- AlterTable
ALTER TABLE "Firm" ADD COLUMN     "userId" TEXT;

-- AlterTable
ALTER TABLE "Invoice" ADD COLUMN     "userId" TEXT;

-- AlterTable
ALTER TABLE "Vehicle" ADD COLUMN     "userId" TEXT;

-- AddForeignKey
ALTER TABLE "Firm" ADD CONSTRAINT "Firm_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Customer" ADD CONSTRAINT "Customer_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vehicle" ADD CONSTRAINT "Vehicle_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invoice" ADD CONSTRAINT "Invoice_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
