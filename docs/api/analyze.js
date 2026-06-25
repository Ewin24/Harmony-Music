// Usage: node analyze.js <path-to-res.txt>
const fs = require('fs');
const path = process.argv[2];
const content = fs.readFileSync(path, 'utf-8');
const bodyStart = content.indexOf('--- BODY ---');
if (bodyStart === -1) {
  console.error('No --- BODY --- marker found');
  process.exit(1);
}
const body = content.slice(bodyStart + '--- BODY ---'.length).trim();
const data = JSON.parse(body);

function nav(obj, ...keys) {
  for (const k of keys) {
    if (obj == null) return null;
    obj = obj[k];
  }
  return obj;
}

const contents = nav(data, 'contents', 'tabbedSearchResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents');
if (!contents) {
  console.error('No sectionListRenderer.contents');
  process.exit(1);
}

console.log(`sectionListRenderer.contents has ${contents.length} elements\n`);

for (let i = 0; i < contents.length; i++) {
  const el = contents[i];
  if (typeof el !== 'object' || el === null) {
    console.log(`[${i}] not a Map: ${typeof el}`);
    continue;
  }
  const keys = Object.keys(el);
  console.log(`[${i}] keys=${JSON.stringify(keys)}`);

  if ('itemSectionRenderer' in el) {
    const isr = el.itemSectionRenderer;
    if (typeof isr === 'object' && isr !== null) {
      const innerKeys = Object.keys(isr);
      console.log(`    itemSectionRenderer keys: ${JSON.stringify(innerKeys)}`);
      if ('contents' in isr) {
        const inner = isr.contents;
        if (Array.isArray(inner)) {
          console.log(`    itemSectionRenderer.contents has ${inner.length} elements`);
          for (let j = 0; j < Math.min(inner.length, 3); j++) {
            const c = inner[j];
            if (typeof c === 'object' && c !== null) {
              console.log(`      [${j}] keys: ${JSON.stringify(Object.keys(c))}`);
              // Si tiene musicShelfRenderer, ver su título
              if (c.musicShelfRenderer) {
                const msr = c.musicShelfRenderer;
                if (msr.title) {
                  const titleText = nav(msr, 'title', 'runs', 0, 'text');
                  if (titleText) console.log(`           musicShelfRenderer.title = "${titleText}"`);
                }
                if (Array.isArray(msr.contents)) {
                  console.log(`           musicShelfRenderer.contents has ${msr.contents.length} items`);
                }
              }
            } else {
              console.log(`      [${j}] not a Map: ${typeof c}`);
            }
          }
          if (inner.length > 3) console.log(`      ... and ${inner.length - 3} more`);
        } else {
          console.log(`    itemSectionRenderer.contents is not a List: ${typeof inner}`);
        }
      }
    }
  }

  if ('musicCardShelfRenderer' in el) {
    const mcsr = el.musicCardShelfRenderer;
    if (typeof mcsr === 'object' && mcsr !== null) {
      const innerKeys = Object.keys(mcsr);
      console.log(`    musicCardShelfRenderer keys: ${JSON.stringify(innerKeys)}`);
      const titleText = nav(mcsr, 'title', 'runs', 0, 'text');
      if (titleText) console.log(`    musicCardShelfRenderer.title = "${titleText}"`);
    }
  }
}
