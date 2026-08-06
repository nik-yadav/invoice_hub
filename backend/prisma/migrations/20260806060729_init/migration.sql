-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "fullName" TEXT,
    "companyName" TEXT,
    "phone" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Profile" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "fullName" TEXT NOT NULL DEFAULT 'Rajesh Sharma',
    "companyName" TEXT NOT NULL DEFAULT 'Sharma Freight & Logistics',
    "email" TEXT NOT NULL DEFAULT 'rajesh@sharmalogistics.com',
    "phone" TEXT NOT NULL DEFAULT '+91 98765 43210',
    "gstin" TEXT NOT NULL DEFAULT '27AAAAA0000A1Z5',
    "address" TEXT NOT NULL DEFAULT 'Plot 42, Transport Nagar, Nigdi, Pune, MH - 411044',
    "transportLicense" TEXT NOT NULL DEFAULT 'MH-TR-2024-88910',
    "subscriptionPlan" TEXT NOT NULL DEFAULT 'Enterprise Pro',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Profile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Firm" (
    "id" TEXT NOT NULL,
    "businessName" TEXT NOT NULL,
    "ownerName" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "gstin" TEXT,
    "pan" TEXT,
    "address" TEXT,
    "city" TEXT,
    "state" TEXT,
    "pin" TEXT,
    "logoPath" TEXT,
    "signaturePath" TEXT,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Firm_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Customer" (
    "id" TEXT NOT NULL,
    "customerName" TEXT NOT NULL,
    "phone" TEXT,
    "gstin" TEXT,
    "address" TEXT,
    "city" TEXT,
    "state" TEXT,
    "pin" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Vehicle" (
    "id" TEXT NOT NULL,
    "vehicleNumber" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'Open Truck',
    "capacity" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "driverName" TEXT,
    "driverPhone" TEXT,
    "insuranceNumber" TEXT,
    "fitnessExpiry" TEXT,
    "status" TEXT NOT NULL DEFAULT 'available',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Invoice" (
    "id" TEXT NOT NULL,
    "invoiceNumber" TEXT NOT NULL,
    "invoiceDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tripDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "firmId" TEXT,
    "customerId" TEXT,
    "vehicleId" TEXT,
    "sourcePin" TEXT,
    "sourceCity" TEXT,
    "sourceDistrict" TEXT,
    "sourceState" TEXT,
    "sourceAddress" TEXT,
    "destinationPin" TEXT,
    "destCity" TEXT,
    "destDistrict" TEXT,
    "destState" TEXT,
    "destAddress" TEXT,
    "materialDescription" TEXT,
    "weight" DOUBLE PRECISION,
    "transportationCharge" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "customPartiesFields" TEXT DEFAULT '{}',
    "customChargesFields" TEXT DEFAULT '{}',
    "totalAmount" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "paymentMethod" TEXT NOT NULL DEFAULT 'cash',
    "paymentStatus" TEXT NOT NULL DEFAULT 'pending',
    "remarks" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Invoice_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Profile_userId_key" ON "Profile"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_vehicleNumber_key" ON "Vehicle"("vehicleNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Invoice_invoiceNumber_key" ON "Invoice"("invoiceNumber");

-- AddForeignKey
ALTER TABLE "Profile" ADD CONSTRAINT "Profile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invoice" ADD CONSTRAINT "Invoice_firmId_fkey" FOREIGN KEY ("firmId") REFERENCES "Firm"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invoice" ADD CONSTRAINT "Invoice_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invoice" ADD CONSTRAINT "Invoice_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;
