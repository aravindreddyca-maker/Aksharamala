import { readFileSync } from 'node:fs';

const readme = readFileSync('README.md', 'utf8');
const headings = ['## Run', '## Implemented vertical slice', '## Architecture', '## Curriculum expansion path', '## Tests', '## Privacy'];
const commands = ['flutter analyze', 'flutter test', 'flutter build apk --debug'];
const missing = [...headings, ...commands].filter((item) => !readme.includes(item));
if (missing.length) {
  console.error(`README is missing: ${missing.join(', ')}`);
  process.exit(1);
}
if (!readme.includes('not a complete multi-year content library')) {
  console.error('README must state the vertical slice boundary honestly.');
  process.exit(1);
}
console.log('documentation verification passed');

