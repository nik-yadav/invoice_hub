// Copies only the listed keys that are present in `source`. Use this instead of passing
// req.body straight to Prisma, so clients cannot set fields like id, userId or isActive.
export const pickFields = (source, fields) =>
  Object.fromEntries(fields.filter(field => source[field] !== undefined).map(field => [field, source[field]]));
