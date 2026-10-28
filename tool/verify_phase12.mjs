import { readFileSync } from 'node:fs';

const read = (path) => readFileSync(path, 'utf8');
const screens = [
  'lib/src/screens/splash_screen.dart',
  'lib/src/screens/profile_screen.dart',
  'lib/src/screens/home_screen.dart',
  'lib/src/screens/world_map_screen.dart',
  'lib/src/screens/lesson_screen.dart',
  'lib/src/screens/achievements_screen.dart',
  'lib/src/screens/parent_dashboard.dart',
].map(read).join('\n');
const map = read('lib/src/screens/world_map_screen.dart');
const profile = read('lib/src/screens/profile_screen.dart');
const theme = read('lib/src/theme.dart');
const overflow = read('test/overflow_test.dart');
const manifest = read('android/app/src/main/AndroidManifest.xml');
const store = read('lib/src/services/local_store.dart');
const audit = read('AUDIT_PHASES_1_2.md');

const checks = [
  ['landscape Android activity', manifest.includes('android:screenOrientation="landscape"')],
  ['landscape quest trail', map.includes("Key('quest_trail')") && map.includes('AssetImage(world.assetPath)')],
  ['no world emoji rendering', !screens.includes('Text(world.emoji')],
  ['no profile emoji rendering', !screens.includes('Text(profile.avatar')],
  ['no pictographic emoji in screens', !/\p{Extended_Pictographic}/u.test(screens)],
  ['backward-compatible avatars', profile.includes('GameAvatar(value: profile.avatar')],
  ['multilingual font fallback', ['Noto Sans Telugu', 'Noto Sans Devanagari', 'Noto Sans Tamil'].every((font) => theme.includes(font))],
  ['local progress preserved', store.includes('progress.json') && store.includes("'version': 1")],
  ['required landscape matrix', ['Size(640, 360)', 'Size(800, 360)', 'Size(960, 540)', 'Size(1280, 800)'].every((size) => overflow.includes(size))],
  ['audit records phase boundary', audit.includes('Phase 3–9') && audit.includes('Pending')],
];

const failed = checks.filter(([, pass]) => !pass).map(([name]) => name);
if (failed.length) {
  console.error(`Phase 1–2 verification failed: ${failed.join(', ')}`);
  process.exit(1);
}
console.log('phase 1 and 2 source verification passed');
