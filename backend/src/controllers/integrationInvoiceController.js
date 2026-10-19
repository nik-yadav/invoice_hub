import { prisma } from '../config/prisma.js';

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;
const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;

class BadRequest extends Error {}

// Rejects repeated params (?status=a&status=b), which Express parses into arrays.
const getString = (query, name) => {
  const value = query[name];
  if (value === undefined || value === '') return undefined;
  if (typeof value !== 'string') throw new BadRequest(`${name} must be a single value`);
  return value.trim();
};

// Date-only `to` values cover the whole day (UTC).
const parseDate = (value, name, endOfDay = false) => {
  if (value === undefined) return undefined;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw new BadRequest(`${name} must be an ISO date (YYYY-MM-DD or full ISO timestamp)`);
  if (endOfDay && DATE_ONLY.test(value)) date.setUTCHours(23, 59, 59, 999);
  return date;
};

const parseLimit = value => {
  if (value === undefined) return DEFAULT_LIMIT;
  const limit = Number(value);
  if (!Number.isInteger(limit) || limit < 1 || limit > MAX_LIMIT) {
    throw new BadRequest(`limit must be an integer between 1 and ${MAX_LIMIT}`);
  }
  return limit;
};

const parseJsonField = value => {
  try {
    return JSON.parse(value || '{}');
  } catch {
    return {};
  }
};

const invoiceInclude = {
  firm: { select: { businessName: true } },
  customer: { select: { customerName: true, city: true, state: true } },
  vehicle: { select: { vehicleNumber: true, type: true } },
};

// Responses are built from an explicit allowlist. Never spread a raw Prisma row here:
// it would leak userId, internal ids, addresses, PINs and anything added to the schema later.
const toInvoiceSummary = invoice => ({
  id: invoice.id,
  invoiceNumber: invoice.invoiceNumber,
  invoiceDate: invoice.invoiceDate,
  customer: invoice.customer?.customerName ?? null,
  firm: invoice.firm?.businessName ?? null,
  route: { from: invoice.sourceCity || null, to: invoice.destCity || null },
  totalAmount: invoice.totalAmount,
  paymentStatus: invoice.paymentStatus,
});

const toInvoiceDetail = invoice => ({
  id: invoice.id,
  invoiceNumber: invoice.invoiceNumber,
  invoiceDate: invoice.invoiceDate,
  tripDate: invoice.tripDate,
  firm: invoice.firm?.businessName ?? null,
  customer: invoice.customer
    ? { name: invoice.customer.customerName, city: invoice.customer.city, state: invoice.customer.state }
    : null,
  vehicle: invoice.vehicle ? { number: invoice.vehicle.vehicleNumber, type: invoice.vehicle.type } : null,
  source: { city: invoice.sourceCity || null, district: invoice.sourceDistrict || null, state: invoice.sourceState || null },
  destination: { city: invoice.destCity || null, district: invoice.destDistrict || null, state: invoice.destState || null },
  materialDescription: invoice.materialDescription || null,
  weight: invoice.weight,
  transportationCharge: invoice.transportationCharge,
  charges: parseJsonField(invoice.customChargesFields),
  totalAmount: invoice.totalAmount,
  paymentMethod: invoice.paymentMethod,
  paymentStatus: invoice.paymentStatus,
  remarks: invoice.remarks || null,
});

const handleError = (error, res, next) => {
  if (error instanceof BadRequest) {
    return res.status(400).json({ success: false, message: error.message });
  }
  next(error);
};

/**
 * GET /api/v1/integrations/invoices
 * Query: status, from, to, customer, limit, cursor
 */
export const listInvoices = async (req, res, next) => {
  try {
    const status = getString(req.query, 'status');
    const customer = getString(req.query, 'customer');
    const cursor = getString(req.query, 'cursor');
    const from = parseDate(getString(req.query, 'from'), 'from');
    const to = parseDate(getString(req.query, 'to'), 'to', true);
    const limit = parseLimit(getString(req.query, 'limit'));

    if (from && to && from > to) throw new BadRequest('from must be before to');

    const where = { userId: req.user.id, isActive: true };
    if (status) where.paymentStatus = status.toLowerCase();
    if (from || to) where.invoiceDate = { ...(from && { gte: from }), ...(to && { lte: to }) };
    if (customer) where.customer = { customerName: { contains: customer, mode: 'insensitive' } };

    // Fetch one extra row to know whether there is a next page.
    const invoices = await prisma.invoice.findMany({
      where,
      include: invoiceInclude,
      orderBy: [{ invoiceDate: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    });

    const hasMore = invoices.length > limit;
    const page = hasMore ? invoices.slice(0, limit) : invoices;

    return res.status(200).json({
      success: true,
      count: page.length,
      nextCursor: hasMore ? page[page.length - 1].id : null,
      data: page.map(toInvoiceSummary),
    });
  } catch (error) {
    handleError(error, res, next);
  }
};

/**
 * GET /api/v1/integrations/invoices/:id
 * :id may be the invoice id or its invoice number.
 */
export const getInvoice = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Scoped to the key's owner: another user's invoice is a 404, so its existence is not revealed.
    const invoice = await prisma.invoice.findFirst({
      where: { userId: req.user.id, isActive: true, OR: [{ id }, { invoiceNumber: id }] },
      include: invoiceInclude,
    });

    if (!invoice) {
      return res.status(404).json({ success: false, message: 'Invoice not found' });
    }

    return res.status(200).json({ success: true, data: toInvoiceDetail(invoice) });
  } catch (error) {
    handleError(error, res, next);
  }
};
