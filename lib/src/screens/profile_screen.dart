import 'package:flutter/material.dart';

import '../app.dart';
import '../app_controller.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/level_picker.dart';
import 'home_screen.dart';

/// Below this usable width (portrait phones) the two panels stack. Landscape
/// phones stay side by side even after a notch takes 48 dp from each end of a
/// 640 dp screen (544 dp left).
const _stackBelowWidth = 480.0;

/// Narrow landscape widths trim padding so six avatars still get big targets.
const _denseBelowWidth = 640.0;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.allowSkip = false});
  final bool allowSkip;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  int _level = 1;
  String _avatar = 'lion';
  bool _adding = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      await showInfoDialog(
        context,
        title: 'What is your name?',
        message: 'Enter a name so your stars and adventures can be saved.',
      );
      return;
    }
    setState(() => _adding = true);
    await AppScope.of(context).addProfile(
      _name.text,
      stageForLevel(_level).representativeAge,
      _avatar,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return GradientScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < _stackBelowWidth;
          final dense = constraints.maxWidth < _denseBelowWidth;
          final pad = constraints.maxWidth < 760 ? 14.0 : 24.0;
          final learners = _LearnerPanel(
            controller: controller,
            scrollable: !stacked,
            dense: dense,
            onSelected: (profile) {
              controller.selectProfile(profile);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
              );
            },
          );
          final creator = _ProfileForm(
            name: _name,
            level: _level,
            avatar: _avatar,
            adding: _adding,
            scrollable: !stacked,
            dense: dense,
            onLevelChanged: (value) => setState(() => _level = value),
            onAvatarChanged: (value) => setState(() => _avatar = value),
            onCreate: _create,
          );
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 6, pad, 2),
                child: Row(
                  children: [
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Who is learning today?',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (widget.allowSkip && controller.activeProfile != null)
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const HomeScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Continue'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: stacked
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(pad, 4, pad, 16),
                        children: [
                          learners,
                          const SizedBox(height: 12),
                          creator,
                        ],
                      )
                    : Padding(
                        padding: EdgeInsets.fromLTRB(pad, 4, pad, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 4, child: learners),
                            SizedBox(width: pad < 24 ? 12 : 18),
                            Expanded(flex: 6, child: creator),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LearnerPanel extends StatelessWidget {
  const _LearnerPanel({
    required this.controller,
    required this.onSelected,
    required this.scrollable,
    required this.dense,
  });
  final AppController controller;
  final ValueChanged<ChildProfile> onSelected;
  final bool dense;

  /// True when the panel has a bounded height (side-by-side layout).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const Text(
        'Learner crew',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      const Text(
        'Pick a saved explorer. Progress stays on this device.',
        style: TextStyle(color: Color(0xFFD5DDF0)),
      ),
      const SizedBox(height: 10),
      if (controller.profiles.isEmpty)
        const SizedBox(
          height: 92,
          child: Center(
            child: Icon(
              Icons.group_add_rounded,
              color: Color(0xFFFFD85C),
              size: 64,
            ),
          ),
        )
      else
        for (var i = 0; i < controller.profiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _LearnerTile(profile: controller.profiles[i], onTap: onSelected),
        ],
    ];
    return Card(
      color: const Color(0xFF28385A),
      child: Padding(
        padding: EdgeInsets.all(dense ? 10 : 14),
        // The whole panel (heading included) scrolls when the screen is short
        // or the text is large, so nothing inside it can overflow.
        child: scrollable
            ? ListView(padding: EdgeInsets.zero, children: children)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
      ),
    );
  }
}

/// One saved learner. The description wraps instead of being cut off.
class _LearnerTile extends StatelessWidget {
  const _LearnerTile({required this.profile, required this.onTap});
  final ChildProfile profile;
  final ValueChanged<ChildProfile> onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('profile_${profile.id}'),
          onTap: () => onTap(profile),
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GameAvatar(value: profile.avatar, size: 48),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.play_circle_fill_rounded, size: 30),
                    ],
                  ),
                  // Full tile width, so the age and stage are never cut off.
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${profile.stage.levelLabel} • ${profile.stage.label}',
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13, height: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.name,
    required this.level,
    required this.avatar,
    required this.adding,
    required this.scrollable,
    required this.dense,
    required this.onLevelChanged,
    required this.onAvatarChanged,
    required this.onCreate,
  });
  final bool dense;
  final TextEditingController name;
  final int level;
  final String avatar;
  final bool adding;

  /// True when the card has a bounded height: the fields scroll if they must,
  /// and Create & Play stays pinned and visible underneath them.
  final bool scrollable;
  final ValueChanged<int> onLevelChanged;
  final ValueChanged<String> onAvatarChanged;
  final VoidCallback onCreate;

  /// Below this card height (a 360 dp landscape phone) the name and the age
  /// share one row so everything fits above the pinned button.
  static const _shortHeight = 380.0;

  @override
  Widget build(BuildContext context) {
    final stage = stageForLevel(level);
    final nameField = TextField(
      key: const Key('profile_name'),
      controller: name,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Child’s name',
        prefixIcon: Icon(Icons.person_rounded),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
    final hint = Text(
      '${stage.levelLabel} • ${stage.ageLabel} • ${stage.focus}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, height: 1.2),
    );
    final button = FilledButton.icon(
      key: const Key('create_profile'),
      onPressed: adding ? null : onCreate,
      icon: const Icon(Icons.auto_awesome),
      label: Text(adding ? 'Saving…' : 'Create & Play'),
    );
    Widget fields({required bool short}) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The screen already asks who is learning; on a short screen the
            // card's own heading is dropped to leave room for the level tiles.
            if (!short) ...[
              Text(
                'Create a child profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: short ? 18 : 20),
              ),
              SizedBox(height: short ? 4 : 8),
            ],
            _AvatarPicker(selected: avatar, onChanged: onAvatarChanged),
            SizedBox(height: short ? 6 : 8),
            nameField,
            SizedBox(height: short ? 4 : 6),
            LevelPicker(
              selected: level,
              onChanged: onLevelChanged,
              dense: true,
            ),
            // On a short screen the tiles already show the level and ages, so
            // the extra line is dropped to keep everything above Create & Play.
            if (!short) ...[const SizedBox(height: 0), hint],
          ],
        );
    return Card(
      child: Padding(
        padding: EdgeInsets.all(dense ? 10 : 14),
        child: scrollable
            ? LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: fields(
                          short: constraints.maxHeight < _shortHeight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    button,
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fields(short: false),
                  const SizedBox(height: 10),
                  button,
                ],
              ),
      ),
    );
  }
}

/// All six avatars on one row. Each fills an equal share of the width, so the
/// tap targets grow with the screen (never below 48 dp) and none wrap away.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final count = GameAvatar.options.length;
          final cell = (constraints.maxWidth / count).clamp(44.0, 84.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final value in GameAvatar.options)
                _AvatarChoice(
                  value: value,
                  size: cell,
                  selected: selected == value,
                  onTap: () => onChanged(value),
                ),
            ],
          );
        },
      );
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.value,
    required this.size,
    required this.selected,
    required this.onTap,
  });
  final String value;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  static const _ring = Color(0xFF4B3DBA);

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '$value avatar',
        child: InkWell(
          key: Key('avatar_$value'),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // A fixed-width border (transparent when unselected) keeps the
                // artwork from jumping when the selection changes.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: size - 2,
                  height: size - 2,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? const Color(0xFFEDE9FF) : null,
                    border: Border.all(
                      color: selected ? _ring : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: GameAvatar(value: value, size: size - 10),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _ring,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
