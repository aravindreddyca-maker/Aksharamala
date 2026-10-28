import { existsSync, readFileSync, statSync } from 'node:fs';

const assets = [
  'assets/images/worlds/english_forest.png',
  'assets/images/worlds/telugu_kingdom.png',
  'assets/images/worlds/hindi_valley.png',
  'assets/images/worlds/tamil_garden.png',
  'assets/images/worlds/number_galaxy.png',
];
for (const asset of assets) {
  if (!existsSync(asset) || statSync(asset).size < 100000) {
    console.error(`Missing or undersized bundled artwork: ${asset}`);
    process.exit(1);
  }
  const signature = readFileSync(asset).subarray(0, 8).toString('hex');
  if (signature !== '89504e470d0a1a0a') {
    console.error(`Artwork is not a valid PNG: ${asset}`);
    process.exit(1);
  }
}

const home = readFileSync('lib/src/screens/home_screen.dart', 'utf8');
const lesson = readFileSync('lib/src/screens/lesson_screen.dart', 'utf8');
const main = readFileSync('lib/main.dart', 'utf8');
const pubspec = readFileSync('pubspec.yaml', 'utf8');
const manifest = readFileSync('android/app/src/main/AndroidManifest.xml', 'utf8');
const checks = [
  home.includes('AssetImage(world.assetPath)'),
  home.includes("Key('world_\${world.id}')"),
  home.includes('WorldMapScreen(world: world)'),
  home.includes('CustomScrollView'),
  home.includes('LinearProgressIndicator'),
  !home.includes('Text(world.emoji'),
  lesson.includes('Row(crossAxisAlignment: CrossAxisAlignment.stretch'),
  lesson.includes('SingleChildScrollView'),
  main.includes('DeviceOrientation.landscapeLeft'),
  main.includes('DeviceOrientation.landscapeRight'),
  pubspec.includes('assets/images/worlds/'),
  manifest.includes('android:screenOrientation="landscape"'),
];
if (checks.some((value) => !value)) {
  console.error('Landscape home or lesson implementation evidence is incomplete.');
  process.exit(1);
}
console.log('home redesign verification passed');
