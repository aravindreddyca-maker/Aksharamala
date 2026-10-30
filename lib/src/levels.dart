/// The five learning levels. A child chooses a level; nothing is chosen by age.
///
/// Level 1 is foundational learning and Level 5 is higher-level learning and
/// application. Any child may open any level at any time, and each level keeps
/// its own progress (lessons finished are tracked per lesson id, and answer
/// statistics per level and world).
library;

const int firstLevel = 1;
const int lastLevel = 5;

/// 1, 2, 3, 4, 5.
const List<int> allLevels = [1, 2, 3, 4, 5];

class LevelInfo {
  const LevelInfo(this.number, this.tagline);

  final int number;

  /// A short phrase for the level, shown under its number.
  final String tagline;

  String get label => 'Level $number';
}

const List<LevelInfo> levelInfos = [
  LevelInfo(1, 'Foundations'),
  LevelInfo(2, 'Early skills'),
  LevelInfo(3, 'Intermediate'),
  LevelInfo(4, 'Advanced'),
  LevelInfo(5, 'Higher level'),
];

/// The level's name and tagline; a number outside 1-5 is held to the nearest.
LevelInfo levelInfo(int level) => levelInfos[clampLevel(level) - 1];

int clampLevel(int level) => level < firstLevel
    ? firstLevel
    : level > lastLevel
        ? lastLevel
        : level;

/// Where a save from before levels were stored lands. Older saves kept only an
/// age; the four old age bands become Levels 1 to 4 so nobody moves.
int levelForLegacyAge(int age) {
  if (age <= 4) return 1;
  if (age <= 6) return 2;
  if (age <= 9) return 3;
  return 4;
}

/// A key for statistics kept per level and world.
String levelWorldKey(int level, String worldId) => '$level|$worldId';
