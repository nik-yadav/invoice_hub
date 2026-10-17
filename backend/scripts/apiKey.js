// CLI for issuing and revoking API keys.
//
//   node scripts/apiKey.js create <email> [--name <label>] [--expires-days <n>]
//   node scripts/apiKey.js list <email>
//   node scripts/apiKey.js revoke <keyId>

import 'dotenv/config';
import { prisma } from '../src/config/prisma.js';
import { generateApiKey, hashApiKey } from '../src/services/apiKeyService.js';

const usage = () => {
  console.log(`Usage:
  node scripts/apiKey.js create <email> [--name <label>] [--expires-days <n>]
  node scripts/apiKey.js list <email>
  node scripts/apiKey.js revoke <keyId>`);
  process.exit(1);
};

const getFlag = (args, flag) => {
  const i = args.indexOf(flag);
  return i === -1 ? undefined : args[i + 1];
};

const findUser = async email => {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !user.isActive) throw new Error(`No active user with email ${email}`);
  return user;
};

const create = async args => {
  const [email] = args;
  if (!email) usage();

  const expiresDays = getFlag(args, '--expires-days');
  if (expiresDays !== undefined && !(Number(expiresDays) > 0)) {
    throw new Error('--expires-days must be a positive number');
  }

  const user = await findUser(email);
  const key = generateApiKey();

  const apiKey = await prisma.apiKey.create({
    data: {
      keyHash: hashApiKey(key),
      name: getFlag(args, '--name'),
      userId: user.id,
      expiresAt: expiresDays ? new Date(Date.now() + Number(expiresDays) * 86400000) : null,
    },
  });

  console.log(`Created key ${apiKey.id} for ${email}`);
  console.log(`Scopes:  ${apiKey.scopes.join(', ')}`);
  console.log(`Expires: ${apiKey.expiresAt ? apiKey.expiresAt.toISOString() : 'never'}`);
  console.log(`\n  ${key}\n`);
  console.log('Store this key now. It cannot be shown again.');
};

const list = async args => {
  const [email] = args;
  if (!email) usage();

  const user = await findUser(email);
  const keys = await prisma.apiKey.findMany({
    where: { userId: user.id },
    orderBy: { createdAt: 'desc' },
    select: { id: true, name: true, scopes: true, isActive: true, expiresAt: true, lastUsedAt: true, createdAt: true },
  });

  if (!keys.length) return console.log(`No keys for ${email}`);
  console.table(keys);
};

const revoke = async args => {
  const [id] = args;
  if (!id) usage();

  const { count } = await prisma.apiKey.updateMany({
    where: { id, isActive: true },
    data: { isActive: false },
  });
  if (!count) throw new Error(`No active key with id ${id}`);
  console.log(`Revoked key ${id}`);
};

const commands = { create, list, revoke };

const main = async () => {
  const [command, ...args] = process.argv.slice(2);
  if (!commands[command]) usage();
  await commands[command](args);
};

main()
  .catch(err => {
    console.error(`Error: ${err.message}`);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
