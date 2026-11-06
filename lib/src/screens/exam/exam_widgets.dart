import 'package:flutter/material.dart';

import '../../app.dart';
import '../../exam/models.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatDateTime(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${formatDate(d)}, $h:$m';
}

String formatPercent(double p) =>
    p == p.roundToDouble() ? '${p.round()}%' : '${p.toStringAsFixed(1)}%';

String formatClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final m = (s ~/ 60).toString();
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}

String examTypeLabel(ExamType t) => switch (t) {
      ExamType.chapter => 'Chapter Test',
      ExamType.subject => 'Subject Examination',
      ExamType.finalLevel => 'Final Level Examination',
    };

/// The world's display name for a world id (falls back to the id).
String worldNameOf(BuildContext context, String worldId) {
  for (final w in AppScope.of(context).allWorlds) {
    if (w.id == worldId) return w.name;
  }
  return worldId;
}

/// Keeps wide screens readable and lets narrow ones use the full width.
class PageBody extends StatelessWidget {
  const PageBody({required this.child, super.key, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// A titled card used by every Examination Centre section.
class ExamCard extends StatelessWidget {
  const ExamCard({
    required this.children,
    super.key,
    this.title,
    this.color,
  });

  final String? title;
  final Color? color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        color: color,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(title!, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
              ],
              ...children,
            ],
          ),
        ),
      );
}

/// A label with minus / plus buttons (each at least 48 dp).
class CountStepper extends StatelessWidget {
  const CountStepper({
    required this.label,
    required this.value,
    required this.keyPrefix,
    required this.onChanged,
    super.key,
    this.min = 1,
    this.max = 100,
    this.step = 1,
    this.unit = '',
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final String keyPrefix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: '$label $value $unit',
        child: Row(
          children: [
            Expanded(child: ExcludeSemantics(child: Text(label))),
            IconButton(
              key: Key('${keyPrefix}_minus'),
              tooltip: 'Fewer: $label',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed:
                  value - step < min ? null : () => onChanged(value - step),
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Flexible(
              child: Text(
                '$value$unit',
                key: Key('${keyPrefix}_value'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              key: Key('${keyPrefix}_plus'),
              tooltip: 'More: $label',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed:
                  value + step > max ? null : () => onChanged(value + step),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Yes',
  String cancelLabel = 'Cancel',
  Key? confirmKey,
  Key? cancelKey,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          key: cancelKey,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: confirmKey,
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A short coloured notice (warning, information).
class Notice extends StatelessWidget {
  const Notice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.color = const Color(0xFFEDE8FF),
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
