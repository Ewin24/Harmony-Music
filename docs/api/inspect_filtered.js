// Inspect a search response to see what the items look like and what
// pageType / flexColumns[1] / other signals are available.
const fs = require('fs');
const path = process.argv[2];
const content = fs.readFileSync(path, 'utf-8');
const bodyStart = content.indexOf('--- BODY ---');
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

for (let idx = 0; idx < Math.min(contents.length, 3); idx++) {
  const el = contents[idx];
  if (typeof el !== 'object' || el === null) continue;
  const rendererKey = Object.keys(el)[0];
  const body = el[rendererKey];
  console.log(`[${idx}] ${rendererKey}`);
  if (body && body.title) {
    console.log(`    title: ${nav(body, 'title', 'runs', 0, 'text')}`);
  }
  if (body && Array.isArray(body.contents)) {
    console.log(`    contents: ${body.contents.length} items`);
    for (let i = 0; i < Math.min(body.contents.length, 2); i++) {
      const item = body.contents[i];
      if (!item) continue;
      // The actual item renderer varies; look for the common ones.
      const itemKey = Object.keys(item)[0];
      const itemBody = item[itemKey];
      console.log(`    item[${i}] keys=${JSON.stringify(Object.keys(item))}`);
      console.log(`      itemBody type: ${itemKey}`);

      // For musicResponsiveListItemRenderer, show flexColumns.
      if (itemKey === 'musicResponsiveListItemRenderer' && itemBody) {
        const fc0 = nav(itemBody, 'flexColumns', 0, 'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs');
        const fc1 = nav(itemBody, 'flexColumns', 1, 'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs');
        console.log(`      flexColumns[0].runs: ${JSON.stringify(fc0)}`);
        console.log(`      flexColumns[1].runs: ${JSON.stringify(fc1)}`);
        // Show the navigationEndpoint type
        const navType = nav(itemBody, 'navigationEndpoint', 'watchEndpoint') ? 'WATCH' :
                        nav(itemBody, 'navigationEndpoint', 'browseEndpoint', 'browseEndpointContextSupportedConfigs', 'browseEndpointContextMusicConfig', 'pageType') || null;
        console.log(`      pageType: ${navType}`);
        // Show badges if any (this is where "Community playlist" / "Featured" lives)
        const badges = itemBody.badges;
        if (badges) {
          console.log(`      badges: ${JSON.stringify(badges)}`);
        }
        // Also show overlay (sometimes has the source label)
        const overlay = nav(itemBody, 'overlay', 'musicItemThumbnailOverlayRenderer', 'content');
        if (overlay) {
          console.log(`      overlay: ${JSON.stringify(overlay)}`);
        }
      } else {
        // Unknown shape: dump the first 300 chars of the body.
        const s = JSON.stringify(itemBody).substring(0, 300);
        console.log(`      body preview: ${s}...`);
      }
    }
  }
  console.log();
}
