import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

function filesUnder(path) {
  return readdirSync(path).flatMap((name) => {
    const full = join(path, name);
    return statSync(full).isDirectory() ? filesUnder(full) : [full];
  });
}

const dartFiles = filesUnder('lib').filter((path) => path.endsWith('.dart'));
const dart = dartFiles.map((path) => readFileSync(path, 'utf8')).join('\n');
const kotlin = readFileSync('android/app/src/main/kotlin/app/aksharamala/MainActivity.kt', 'utf8');
const pubspec = readFileSync('pubspec.yaml', 'utf8');

const requirements = [
  ['five world ids', ['english', 'telugu', 'hindi', 'tamil', 'numbers'].every((id) => dart.includes(`id: '${id}'`))],
  ['five world names', ['English Forest', 'Telugu Kingdom', 'Hindi Valley', 'Tamil Garden', 'Number Galaxy'].every((name) => dart.includes(name))],
  ['age stages', ['explorer', 'creator', 'scholar', 'champion'].every((stage) => dart.includes(`ExperienceStage.${stage}`))],
  ['lesson kinds', ['alphabet', 'words', 'numbers', 'story', 'tracing', 'game'].every((kind) => dart.includes(`LessonKind.${kind}`))],
  ['language locales', ['en-US', 'te-IN', 'hi-IN', 'ta-IN'].every((locale) => dart.includes(locale))],
  ['number names', /10:\s*\{'en':\s*'Ten',\s*'te':\s*'పది',\s*'hi':\s*'दस',\s*'ta':\s*'பத்து'\}/.test(dart)],
  ['persistence', dart.includes('progress.json') && dart.includes('jsonEncode') && dart.includes('jsonDecode')],
  ['adaptive engine', dart.includes('recommendedLesson') && dart.includes('accuracyFor')],
  ['rewards', dart.includes('four-world-hero') && dart.includes('earnedBadges')],
  ['parent dashboard', dart.includes('class ParentDashboard')],
  ['finger tracing', dart.includes('class _TracePainter') && dart.includes('onPanUpdate')],
  ['native Android speech', kotlin.includes('TextToSpeech') && kotlin.includes('Locale.forLanguageTag')],
  ['offline dependency set', !pubspec.includes('http:') && !pubspec.includes('firebase')],
];

const missing = requirements.filter(([, passed]) => !passed).map(([name]) => name);
if (missing.length) {
  console.error(`Missing product evidence: ${missing.join(', ')}`);
  process.exit(1);
}

const lessonIds = [...dart.matchAll(/Lesson\(id:\s*'([^']+)'/g)].map((match) => match[1]);
if (lessonIds.length < 20 || new Set(lessonIds).size !== lessonIds.length) {
  console.error(`Expected at least 20 unique lessons, found ${lessonIds.length}/${new Set(lessonIds).size} unique`);
  process.exit(1);
}

console.log(`Verified ${dartFiles.length} Dart files and ${lessonIds.length} unique lessons.`);
console.log('product source verification passed');

