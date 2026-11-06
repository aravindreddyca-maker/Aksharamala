import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../exam/exam_controller.dart';

/// What a PIN dialog is asking for.
enum PinPurpose { unlock, set, change, clear }

/// Asks for a 4-digit PIN. Returns true when the action succeeded (the PIN
/// was right, or was saved / cleared).
Future<bool> showPinDialog(
  BuildContext context, {
  required ExamController controller,
  required String childId,
  required PinPurpose purpose,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinDialog(
      controller: controller,
      childId: childId,
      purpose: purpose,
    ),
  );
  return ok ?? false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.controller,
    required this.childId,
    required this.purpose,
  });

  final ExamController controller;
  final String childId;
  final PinPurpose purpose;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  String? _error;
  bool _busy = false;

  bool get _needsCurrent =>
      widget.purpose == PinPurpose.unlock ||
      widget.purpose == PinPurpose.change ||
      widget.purpose == PinPurpose.clear;
  bool get _needsNew =>
      widget.purpose == PinPurpose.set || widget.purpose == PinPurpose.change;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  String get _title => switch (widget.purpose) {
        PinPurpose.unlock => 'Enter the exam PIN',
        PinPurpose.set => 'Set an exam PIN',
        PinPurpose.change => 'Change the exam PIN',
        PinPurpose.clear => 'Remove the exam PIN',
      };

  Future<void> _submit() async {
    final c = widget.controller;
    final id = widget.childId;
    setState(() => _busy = true);
    bool ok;
    String? error;
    switch (widget.purpose) {
      case PinPurpose.unlock:
        ok = c.verifyPin(id, _current.text);
        error = ok ? null : 'That PIN is not right.';
      case PinPurpose.set:
        ok = await c.setPin(id, _next.text);
        error = ok ? null : 'Use exactly four digits.';
      case PinPurpose.change:
        if (!c.verifyPin(id, _current.text)) {
          ok = false;
          error = 'The current PIN is not right.';
        } else {
          ok = await c.setPin(id, _next.text, currentPin: _current.text);
          error = ok ? null : 'The new PIN must be exactly four digits.';
        }
      case PinPurpose.clear:
        ok = await c.clearPin(id, _current.text);
        error = ok ? null : 'That PIN is not right.';
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  Widget _field(String key, String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          key: Key(key),
          controller: c,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, counterText: ''),
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(_title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.purpose == PinPurpose.unlock)
                const Text('A grown-up set a PIN for this child.'),
              if (_needsCurrent)
                _field(
                  'pin_current',
                  widget.purpose == PinPurpose.unlock ? 'PIN' : 'Current PIN',
                  _current,
                ),
              if (_needsNew) _field('pin_new', 'New 4-digit PIN', _next),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    key: const Key('pin_error'),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('pin_cancel'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('pin_ok'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: _busy ? null : _submit,
            child: const Text('OK'),
          ),
        ],
      );
}
