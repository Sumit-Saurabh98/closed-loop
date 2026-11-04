#!/usr/bin/env node
// Reports which of Cartwheel's three planted bugs are present in a checkout.
// Usage: node scripts/check-bugs.mjs [path-to-cartwheel]   (default: ./cartwheel)
// Exit code = number of bugs still present (3 on a fresh demo, 0 after all loops close).
// Kept outside the cartwheel repo on purpose: the agents should not see the answers.

import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const root = resolve(process.argv[2] || new URL('../cartwheel', import.meta.url).pathname);
const { createApp } = await import(pathToFileURL(`${root}/src/app.js`).href);
const { resetStore } = await import(pathToFileURL(`${root}/src/store.js`).href);

resetStore();
const server = createApp().listen(0);
const base = `http://127.0.0.1:${server.address().port}`;
const call = async (method, path, body) => {
  const res = await fetch(base + path, {
    method,
    headers: { 'content-type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, body: await res.json() };
};
const cartWith = async (items, coupon) => {
  const { body: cart } = await call('POST', '/carts');
  for (const productId of items) await call('POST', `/carts/${cart.id}/items`, { productId });
  if (coupon) await call('POST', `/carts/${cart.id}/coupon`, { code: coupon });
  return (await call('GET', `/carts/${cart.id}/total`)).body;
};
const isCents = (x) => Math.round(x * 100) / 100 === x;

const results = [];

// BUG-1: SAVE10 on a 40.00 cart must take 4.00 off (10%), not 10.00.
{
  const t = await cartWith(['p_2'], 'SAVE10');
  results.push({ bug: 'BUG-1 coupon', present: t.discount !== 4, detail: `discount=${t.discount} (want 4)` });
}

// BUG-2: 19.99 + 9.99 + 4.50 = 34.48 -> tax 2.76, total 42.23, all exact cents.
{
  const t = await cartWith(['p_12', 'p_3', 'p_7']);
  const fields = ['subtotal', 'discount', 'tax', 'shipping', 'total'];
  const bad = fields.filter((f) => !isCents(t[f]));
  results.push({
    bug: 'BUG-2 rounding',
    present: bad.length > 0 || t.tax !== 2.76 || t.total !== 42.23,
    detail: `tax=${t.tax} total=${t.total} (want 2.76 / 42.23)`,
  });
}

// BUG-3: 12 products at limit 5 = 3 pages; page 3 holds the last 2.
{
  const first = await call('GET', '/products?limit=5');
  const last = await call('GET', '/products?page=3&limit=5');
  results.push({
    bug: 'BUG-3 pagination',
    present: first.body.totalPages !== 3 || last.status !== 200 || last.body.items?.length !== 2,
    detail: `totalPages=${first.body.totalPages} page3=${last.status} (want 3 / 200 with 2 items)`,
  });
}

server.close();
for (const r of results) console.log(`${r.present ? 'PRESENT' : 'fixed  '}  ${r.bug.padEnd(18)} ${r.detail}`);
const present = results.filter((r) => r.present).length;
console.log(`\n${present}/3 planted bugs present in ${root}`);
process.exit(present);
