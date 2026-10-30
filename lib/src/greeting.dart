/// The greetings on the home screen. Tapping the banner moves on to the next
/// one, so saying hello is something to play with, not a fixed word.
library;

/// A friendly set of lines for [name], starting with the time of day.
List<String> greetingLines({
  required String name,
  required int stars,
  required DateTime now,
}) {
  final hello = now.hour < 12
      ? 'Good morning'
      : now.hour < 17
          ? 'Good afternoon'
          : 'Good evening';
  return [
    '$hello, $name!',
    "Hi $name! Let's play!",
    'Hello $name! Ready for an adventure?',
    stars > 0
        ? 'Wow, $name! You have $stars ${stars == 1 ? 'star' : 'stars'}!'
        : "Let's win your first star, $name!",
    'Tap me again for a new hello!',
  ];
}
