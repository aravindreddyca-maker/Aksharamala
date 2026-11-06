import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models.dart';
import '../../widgets/common.dart';
import 'certificates_tab.dart';
import 'conduct_tab.dart';
import 'exam_scope.dart';
import 'exam_widgets.dart';
import 'history_tab.dart';
import 'pin_dialogs.dart';
import 'results_tab.dart';
import 'settings_tab.dart';

/// The only way in: Home, Parents (arithmetic gate), Parent dashboard, then
/// this. If the active child has a PIN it is asked for first. A child using
/// the normal app has no route here.
Future<void> openExaminationCentre(BuildContext context) async {
  final exams = ExamScope.maybeOf(context);
  final profile = AppScope.of(context).activeProfile;
  final navigator = Navigator.of(context);
  if (exams == null) return;
  if (profile != null && exams.hasPin(profile.id)) {
    final ok = await showPinDialog(
      context,
      controller: exams,
      childId: profile.id,
      purpose: PinPurpose.unlock,
    );
    if (!ok) return;
  }
  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => ExaminationCentre(initialChildId: profile?.id),
    ),
  );
}

class ExaminationCentre extends StatefulWidget {
  const ExaminationCentre({super.key, this.initialChildId});

  final String? initialChildId;

  @override
  State<ExaminationCentre> createState() => _ExaminationCentreState();
}

class _ExaminationCentreState extends State<ExaminationCentre> {
  String? _childId;
  final Set<String> _unlocked = {};

  @override
  void initState() {
    super.initState();
    _childId = widget.initialChildId;
    if (_childId != null) _unlocked.add(_childId!);
  }

  Future<void> _choose(String id) async {
    final exams = ExamScope.of(context);
    if (!_unlocked.contains(id) && exams.hasPin(id)) {
      final ok = await showPinDialog(
        context,
        controller: exams,
        childId: id,
        purpose: PinPurpose.unlock,
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      _unlocked.add(id);
      _childId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profiles = AppScope.of(context).profiles;
    ChildProfile? child;
    for (final p in profiles) {
      if (p.id == _childId) child = p;
    }
    child ??= profiles.isEmpty ? null : profiles.first;
    if (child != null &&
        !_unlocked.contains(child.id) &&
        ExamScope.of(context).hasPin(child.id)) {
      child = null; // never show a locked child's data
    }
    final selected = child;
    return DefaultTabController(
      length: 5,
      child: GradientScaffold(
        appBar: AppBar(
          title: const Text('Examination Centre'),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(key: Key('tab_conduct'), text: 'Conduct Exam'),
              Tab(key: Key('tab_results'), text: 'Results'),
              Tab(key: Key('tab_history'), text: 'History'),
              Tab(key: Key('tab_certificates'), text: 'Certificates'),
              Tab(key: Key('tab_settings'), text: 'Bank & Settings'),
            ],
          ),
        ),
        child: profiles.isEmpty
            ? const PageBody(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Notice(
                      'Add a child profile first. Exams are taken by a child.'),
                ),
              )
            : Column(
                children: [
                  _ChildPicker(
                    profiles: profiles,
                    selectedId: selected?.id,
                    onChanged: _choose,
                  ),
                  Expanded(
                    child: selected == null
                        ? const PageBody(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Notice('Choose a child to continue.'),
                            ),
                          )
                        : TabBarView(
                            // Swiping tabs must not fight scrolling lists.
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              ConductTab(
                                  key: ValueKey(selected.id), child: selected),
                              ResultsTab(child: selected),
                              HistoryTab(child: selected),
                              CertificatesTab(child: selected),
                              SettingsTab(child: selected),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ChildPicker extends StatelessWidget {
  const _ChildPicker({
    required this.profiles,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ChildProfile> profiles;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => PageBody(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Child',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('exam_child'),
                value: selectedId,
                isExpanded: true,
                itemHeight: null,
                items: [
                  for (final p in profiles)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.name} (Level ${p.level})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
      );
}
