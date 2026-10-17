import { prisma } from '../config/prisma.js';

// Mount before apiKeyAuth so rejected requests (401/403/429) are logged too.
// Writes after the response is sent; never logs the Authorization header or response body.
const auditLog = (req, res, next) => {
  const startedAt = Date.now();

  res.on('finish', () => {
    prisma.apiAuditLog
      .create({
        data: {
          apiKeyId: req.apiKey?.id ?? null,
          userId: req.user?.id ?? null,
          method: req.method,
          path: req.originalUrl.split('?')[0],
          query: req.query,
          statusCode: res.statusCode,
          ip: req.ip,
          userAgent: req.get('user-agent')?.slice(0, 255) ?? null,
          durationMs: Date.now() - startedAt,
        },
      })
      .catch(err => console.error('Failed to write API audit log:', err.message));
  });

  next();
};

export default auditLog;
export { auditLog };
