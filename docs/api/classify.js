// Analyze the actual type of each item in the search response.
// Each itemSectionRenderer contains a single musicResponsiveListItemRenderer
// that needs to be classified client-side as artist/song/album/playlist.

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

function classifyItem(item) {
  if (!item) return 'null';
  // flexColumns[1] typically has the type: "Song", "Artist", "Album", "Video", etc.
  const col1 = nav(item, 'flexColumns', 1, 'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs', 0, 'text');
  // Title from flexColumns[0]
  const col0 = nav(item, 'flexColumns', 0, 'musicResponsiveListItemFlexColumnRenderer', 'text', 'runs', 0, 'text');
  // navigationEndpoint tells us the type of page it links to
  const navType = nav(item, 'navigationEndpoint', 'watchEndpoint') ? 'WATCH (song/video)' :
                  nav(item, 'navigationEndpoint', 'browseEndpoint', 'browseEndpointContextSupportedConfigs', 'browseEndpointContextMusicConfig', 'pageType') || null;
  return `${col1 || '(no col1)'} | title="${(col0 || '').toString().substring(0, 30)}" | pageType=${navType || 'none'}`;
}

console.log('Top result (musicCardShelfRenderer):');
const topResult = contents[0].musicCardShelfRenderer;
console.log(`  title: ${nav(topResult, 'title', 'runs', 0, 'text')}`);
console.log(`  subtitle: ${nav(topResult, 'subtitle', 'runs', 0, 'text')}`);
console.log();

console.log('24 items in itemSectionRenderer:');
for (let i = 1; i < contents.length; i++) {
  const isr = contents[i].itemSectionRenderer;
  if (!isr || !Array.isArray(isr.contents)) continue;
  const item = isr.contents[0]?.musicResponsiveListItemRenderer;
  if (!item) {
    console.log(`[${i}] no musicResponsiveListItemRenderer`);
    continue;
  }
  console.log(`[${i}] ${classifyItem(item)}`);
}
