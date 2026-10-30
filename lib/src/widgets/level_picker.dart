import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Four levels side by side. Anyone may pick any of them, at any time: a level
/// is a starting point for what the child sees, never a lock.
class LevelPicker extends StatelessWidget {
  const LevelPicker({
    required this.selected,
    required this.onChanged,
    super.key,
    this.dense = false,
  });

  /// 1 to 4.
  final int selected;
  final ValueChanged<int> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final stage in ExperienceStage.values) ...[
            if (stage != ExperienceStage.explorer) const SizedBox(width: 8),
            Expanded(
              child: _LevelTile(
                stage: stage,
                selected: stage.level == selected,
                dense: dense,
                onTap: () => onChanged(stage.level),
              ),
            ),
          ],
        ],
      );
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.stage,
    required this.selected,
    required this.dense,
    required this.onTap,
  });

  final ExperienceStage stage;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  static const _ring = Color(0xFF4B3DBA);

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '${stage.levelLabel}, ${stage.ageLabel.toLowerCase()}',
        excludeSemantics: true,
        child: Material(
          color: selected ? const Color(0xFFEDE9FF) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? _ring : const Color(0xFFCFC8E6),
              width: selected ? 3 : 1.5,
            ),
          ),
          child: InkWell(
            key: Key('level_${stage.level}'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: dense ? GameTokens.minTouch : 60,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 4, vertical: dense ? 3 : 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected)
                            const Padding(
                              padding: EdgeInsets.only(right: 3),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: _ring,
                              ),
                            ),
                          Text(
                            stage.levelLabel,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: GameTokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        stage.ageLabel,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: GameTokens.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Opens the level choice. Anyone can change the level; it only changes which
/// quests are shown, never what has been earned.
Future<void> showLevelDialog(
  BuildContext context, {
  required int current,
  required ValueChanged<int> onPicked,
}) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose a level'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LevelPicker(
                selected: current,
                onChanged: (level) {
                  onPicked(level);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Any level can be chosen at any time. Stars and finished '
                'quests are always kept.',
                style: TextStyle(fontSize: 13, height: 1.3),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
