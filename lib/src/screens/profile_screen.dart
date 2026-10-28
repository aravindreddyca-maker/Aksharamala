import 'package:flutter/material.dart';

import '../app.dart';
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
  String _avatar = '🦁';
  bool _adding = false;

  static const avatars = ['🦁', '🐼', '🦄', '🐯', '🐸', '🤖'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      await showInfoDialog(context, title: 'What is your name?', message: 'Enter a name so your stars and adventures can be saved.');
      return;
    }
    setState(() => _adding = true);
    await AppScope.of(context).addProfile(_name.text, _age, _avatar);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return GradientScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Who is learning today?', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                if (controller.profiles.isNotEmpty) ...[
                  const SectionTitle('Choose a learner'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.profiles.map((profile) => InkWell(
                      onTap: () {
                        controller.selectProfile(profile);
                        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeScreen()));
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 130,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE1DDF8), width: 2)),
                        child: Column(children: [Text(profile.avatar, style: const TextStyle(fontSize: 44)), Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), Text('Age ${profile.age}')])),
                    )).toList(),
                  ),
                ],
                const SectionTitle('Create a child profile'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(spacing: 8, alignment: WrapAlignment.center, children: avatars.map((avatar) => ChoiceChip(label: Text(avatar, style: const TextStyle(fontSize: 26)), selected: _avatar == avatar, onSelected: (_) => setState(() => _avatar = avatar))).toList()),
                        const SizedBox(height: 18),
                        TextField(key: const Key('profile_name'), controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Child’s name', prefixIcon: Icon(Icons.person_rounded), border: OutlineInputBorder())),
                        const SizedBox(height: 18),
                        Text('Age: $_age', style: Theme.of(context).textTheme.titleMedium),
                        Slider(value: _age.toDouble(), min: 3, max: 12, divisions: 9, label: '$_age', onChanged: (value) => setState(() => _age = value.round())),
                        Text('${stageForAge(_age).ageLabel} • ${stageForAge(_age).focus}', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(key: const Key('create_profile'), onPressed: _adding ? null : _create, icon: const Icon(Icons.auto_awesome), label: Text(_adding ? 'Saving…' : 'Create & Play')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
