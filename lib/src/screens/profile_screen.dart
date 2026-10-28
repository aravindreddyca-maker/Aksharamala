import 'package:flutter/material.dart';

import '../app.dart';
import '../app_controller.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.allowSkip = false});
  final bool allowSkip;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  int _age = 5;
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
    await AppScope.of(context).addProfile(_name.text, _age, _avatar);
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
          final compact =
              constraints.maxWidth < 760 || constraints.maxHeight < 390;
          final learners = _LearnerPanel(
            controller: controller,
            onSelected: (profile) {
              controller.selectProfile(profile);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
              );
            },
          );
          final creator = _ProfileForm(
            name: _name,
            age: _age,
            avatar: _avatar,
            adding: _adding,
            onAgeChanged: (value) => setState(() => _age = value),
            onAvatarChanged: (value) => setState(() => _avatar = value),
            onCreate: _create,
          );
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 24,
                  10,
                  compact ? 14 : 24,
                  4,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Who is learning today?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
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
                child: compact
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                        children: [
                          learners,
                          const SizedBox(height: 12),
                          creator,
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 4, child: learners),
                            const SizedBox(width: 18),
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
  const _LearnerPanel({required this.controller, required this.onSelected});
  final AppController controller;
  final ValueChanged<ChildProfile> onSelected;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF28385A),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learner crew',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pick a saved explorer. Progress stays on this device.',
                style: TextStyle(color: Color(0xFFD5DDF0)),
              ),
              const SizedBox(height: 12),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.profiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final profile = controller.profiles[index];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: ListTile(
                          minTileHeight: 64,
                          onTap: () => onSelected(profile),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          leading: GameAvatar(value: profile.avatar, size: 48),
                          title: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            'Age ${profile.age} • ${profile.stage.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.play_circle_fill_rounded),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.name,
    required this.age,
    required this.avatar,
    required this.adding,
    required this.onAgeChanged,
    required this.onAvatarChanged,
    required this.onCreate,
  });
  final TextEditingController name;
  final int age;
  final String avatar;
  final bool adding;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<String> onAvatarChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a child profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: GameAvatar.options
                    .map(
                      (value) => InkWell(
                        onTap: () => onAvatarChanged(value),
                        customBorder: const CircleBorder(),
                        child: GameAvatar(
                          value: value,
                          size: 54,
                          selected: avatar == value,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('profile_name'),
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Child’s name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Age $age',
                      style: Theme.of(context).textTheme.titleMedium),
                  Expanded(
                    child: Slider(
                      value: age.toDouble(),
                      min: 3,
                      max: 12,
                      divisions: 9,
                      label: '$age',
                      onChanged: (value) => onAgeChanged(value.round()),
                    ),
                  ),
                ],
              ),
              Text(
                '${stageForAge(age).ageLabel} • ${stageForAge(age).focus}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('create_profile'),
                onPressed: adding ? null : onCreate,
                icon: const Icon(Icons.auto_awesome),
                label: Text(adding ? 'Saving…' : 'Create & Play'),
              ),
            ],
          ),
        ),
      );
}
