import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../app.dart';
import '../art/art_picture.dart';
import '../rhymes/rhyme_models.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fit_content.dart';

/// How long to leave a line before the next one in Hear all. The phone's voice
/// does not tell the app when it has finished, so this is an estimate.
typedef RhymeLineDuration = Duration Function(RhymeLine line);

Duration estimateLineDuration(RhymeLine line) {
  final words = line.speech.trim().split(RegExp(r'\s+')).length;
  return Duration(milliseconds: 1300 + words * 480);
}

/// One rhyme: read it, tap a line to hear it, Hear all, then the missing-word
/// game (only after the child has heard it). Rhymes pay no stars.
class RhymeScreen extends StatefulWidget {
  const RhymeScreen({
    required this.rhyme,
    super.key,
    this.speech = const SpeechService(),
    this.lineDuration = estimateLineDuration,
    this.seed,
  });

  final Rhyme rhyme;
  final SpeechService speech;
  final RhymeLineDuration lineDuration;

  /// Fixes the option order (tests); otherwise it comes from the rhyme id.
  final int? seed;

  @override
  State<RhymeScreen> createState() => _RhymeScreenState();
}

enum _Stage { listen, tryIt }

class _RhymeScreenState extends State<RhymeScreen> {
  _Stage _stage = _Stage.listen;
  bool _heardHere = false;
  bool _playingAll = false;
  bool _voiceMissing = false;
  bool _voiceDialogShown = false;
  int? _current;
  int _run = 0;
  Timer? _timer;
  Completer<void>? _pause;

  // The game.
  int _item = 0;
  late final List<List<String>> _options = _buildOptions();
  final Set<String> _wrongTried = {};
  bool _solved = false;
  bool _wrongNow = false;

  Rhyme get rhyme => widget.rhyme;

  List<List<String>> _buildOptions() {
    final base =
        widget.seed ?? rhyme.id.codeUnits.fold<int>(7, (a, c) => a * 31 + c);
    return [
      for (var i = 0; i < rhyme.items.length; i++)
        _shuffled(rhyme.items[i].options, base + i, rhyme.items[i].answer),
    ];
  }

  /// Shuffled with a seed, and never left in the authoring order: the answer
  /// is written first in the content, so slot 0 must not hold it.
  List<String> _shuffled(List<String> options, int seed, String answer) {
    final random = Random(seed);
    final result = [...options];
    bool ok() {
      if (result.first == answer) return false;
      for (var i = 0; i < result.length; i++) {
        if (result[i] != options[i]) return true;
      }
      return false;
    }

    for (var attempt = 0; attempt < 20; attempt++) {
      result.shuffle(random);
      if (ok()) return result;
    }
    // Vanishingly unlikely: rotate the answer out of the first slot.
    final rest = [
      for (final o in options)
        if (o != answer) o
    ];
    return [...rest.take(1), answer, ...rest.skip(1)];
  }

  @override
  void dispose() {
    _run++;
    _timer?.cancel();
    final pause = _pause;
    if (pause != null && !pause.isCompleted) pause.complete();
    widget.speech.stop();
    super.dispose();
  }

  bool get _heard =>
      _heardHere || AppScope.of(context).rhymeProgressFor(rhyme.id).heard;

  void _markHeard() {
    _heardHere = true;
    AppScope.of(context).markRhymeHeard(rhyme.id);
  }

  Future<void> _noticeIfMissing(bool supported) async {
    if (supported) return;
    setState(() => _voiceMissing = true);
    if (_voiceDialogShown || !mounted) return;
    _voiceDialogShown = true;
    final language = rhymeLanguageLabels[rhyme.language] ?? rhyme.language;
    await showInfoDialog(
      context,
      title: 'Voice unavailable',
      message:
          'This phone does not have the $language voice installed. You can still read the rhyme and play the word game.',
    );
  }

  Future<void> _tapLine(int index) async {
    _stopPlayback(stopSpeech: false);
    final run = ++_run;
    setState(() {
      _current = index;
      _markHeard();
    });
    final supported =
        await widget.speech.speak(rhyme.lines[index].speech, rhyme.locale);
    if (!mounted || run != _run) return;
    await _noticeIfMissing(supported);
    if (!mounted || run != _run) return;
    // Keep the line lit for about as long as it takes to say it.
    await _wait(widget.lineDuration(rhyme.lines[index]));
    if (!mounted || run != _run) return;
    setState(() => _current = null);
  }

  Future<void> _hearAll() async {
    final run = ++_run;
    setState(() {
      _playingAll = true;
      _markHeard();
    });
    for (var i = 0; i < rhyme.lines.length; i++) {
      if (!mounted || run != _run) return;
      setState(() => _current = i);
      final supported =
          await widget.speech.speak(rhyme.lines[i].speech, rhyme.locale);
      if (!mounted || run != _run) return;
      if (!supported) {
        setState(() {
          _playingAll = false;
          _current = null;
        });
        await _noticeIfMissing(false);
        return;
      }
      await _wait(widget.lineDuration(rhyme.lines[i]));
    }
    if (!mounted || run != _run) return;
    setState(() {
      _playingAll = false;
      _current = null;
    });
  }

  Future<void> _wait(Duration d) {
    final c = Completer<void>();
    _pause = c;
    _timer?.cancel();
    _timer = Timer(d, () {
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  void _stopPlayback({bool stopSpeech = true}) {
    _run++;
    _timer?.cancel();
    final pause = _pause;
    if (pause != null && !pause.isCompleted) pause.complete();
    if (stopSpeech) widget.speech.stop();
    if (mounted) {
      setState(() {
        _playingAll = false;
        _current = null;
      });
    }
  }

  void _openGame() {
    _stopPlayback();
    setState(() {
      _stage = _Stage.tryIt;
      _solved = false;
      _wrongNow = false;
      _wrongTried.clear();
    });
  }

  void _backToRhyme() => setState(() => _stage = _Stage.listen);

  void _answer(String option) {
    if (_solved) return;
    final item = rhyme.items[_item];
    if (option == item.answer) {
      HapticFeedback.lightImpact();
      setState(() {
        _solved = true;
        _wrongNow = false;
      });
      if (_item == rhyme.items.length - 1) {
        AppScope.of(context).markRhymeDone(rhyme.id);
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _wrongNow = true;
        _wrongTried.add(option);
      });
    }
  }

  void _nextItem() => setState(() {
        _item++;
        _solved = false;
        _wrongNow = false;
        _wrongTried.clear();
      });

  @override
  Widget build(BuildContext context) => GradientScaffold(
        appBar: AppBar(
          // A title that contains the answer is hidden while the game is open.
          title: _stage == _Stage.tryIt && rhyme.hideTitleDuringActivity
              ? const Text(
                  'Rhymes',
                  key: Key('rhyme_title_hidden'),
                  style: TextStyle(fontWeight: FontWeight.w800),
                )
              : Text(
                  rhyme.title,
                  key: const Key('rhyme_title'),
                  style: scriptStyle(
                    rhyme.title,
                    const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        child: LayoutBuilder(
          builder: (context, box) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: box.maxWidth < 420 ? 12 : 20,
              vertical: 6,
            ),
            child: FitContent(
              key: ValueKey(_stage),
              child: _stage == _Stage.listen
                  ? _listen(context, box)
                  : _game(context, box),
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------- listen

  Widget _picture(double height) => SizedBox(
        key: const Key('rhyme_picture'),
        height: height,
        child: ArtPicture(
          asset: rhyme.picture.isEmpty ? 'rhyme-no-picture' : rhyme.picture,
          conceptLabel: rhyme.pictureConcept,
          semanticLabel: rhyme.title,
        ),
      );

  Widget _lineTile(int i) {
    final line = rhyme.lines[i];
    final active = _current == i;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: line.text,
        hint: 'Tap to hear this line',
        excludeSemantics: true,
        child: Material(
          color: active ? const Color(0xFFFFE585) : Colors.white,
          borderRadius: BorderRadius.circular(GameTokens.radiusMd),
          child: InkWell(
            key: Key('rhyme_line_$i'),
            borderRadius: BorderRadius.circular(GameTokens.radiusMd),
            onTap: () => _tapLine(i),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameTokens.radiusMd),
                border: Border.all(
                  color: active
                      ? const Color(0xFFB07A00)
                      : const Color(0xFFD9D2EE),
                  width: active ? 3 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    active ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                    color: const Color(0xFF5B4F8F),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line.text,
                      style: scriptStyle(
                        line.text,
                        TextStyle(
                          fontSize: textScale > 1.3 ? 22 : 26,
                          fontWeight: FontWeight.w800,
                          color: GameTokens.ink,
                        ),
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

  Widget _hearButton() => _playingAll
      ? FilledButton.icon(
          key: const Key('rhyme_stop'),
          onPressed: _stopPlayback,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Stop'),
          style:
              FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
        )
      : FilledButton.icon(
          key: const Key('rhyme_hear_all'),
          onPressed: _hearAll,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Hear all'),
        );

  Widget _tryControls() {
    if (!rhyme.hasActivity) return const SizedBox.shrink();
    final heard = _heard;
    final done = AppScope.of(context).rhymeProgressFor(rhyme.id).done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('rhyme_try_button'),
          onPressed: heard ? _openGame : null,
          icon:
              Icon(done ? Icons.check_circle_rounded : Icons.extension_rounded),
          label: Text(done ? 'Play again' : 'Now try it'),
        ),
        if (!heard)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Listen first: tap a line or Hear all, then the game opens.',
              key: Key('rhyme_try_hint'),
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: GameTokens.ink, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _notes() => Column(
        children: [
          if (_voiceMissing)
            Container(
              key: const Key('rhyme_voice_missing'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0D6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFB07A00)),
              ),
              child: const Text(
                'The voice for this rhyme is not on this phone, so it cannot read it out. You can still read it and play the game.',
                style: TextStyle(
                    color: GameTokens.ink, fontWeight: FontWeight.w700),
              ),
            ),
          const Text(
            "The phone's voice reads the words. It does not sing.",
            key: Key('rhyme_voice_note'),
            textAlign: TextAlign.center,
            style: TextStyle(color: GameTokens.ink, fontSize: 14),
          ),
        ],
      );

  Widget _listen(BuildContext context, BoxConstraints box) {
    final wide = box.maxWidth >= 640 && box.maxWidth > box.maxHeight * 1.3;
    final lines = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (var i = 0; i < rhyme.lines.length; i++) _lineTile(i)],
    );
    if (wide) {
      final pictureHeight = (box.maxHeight * .34).clamp(90.0, 220.0);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: min(260, box.maxWidth * .32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _picture(pictureHeight),
                const SizedBox(height: 8),
                _hearButton(),
                const SizedBox(height: 8),
                _tryControls(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [lines, _notes()],
            ),
          ),
        ],
      );
    }
    final pictureHeight = (box.maxHeight * .2).clamp(90.0, 180.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _picture(pictureHeight),
        const SizedBox(height: 8),
        lines,
        _hearButton(),
        const SizedBox(height: 4),
        _notes(),
        const SizedBox(height: 8),
        _tryControls(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ------------------------------------------------------------------ game

  Widget _game(BuildContext context, BoxConstraints box) {
    final item = rhyme.items[_item];
    final options = _options[_item];
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final full = rhyme.lines[item.lineIndex].text;
    final blanked = rhyme.blankedLine(item);
    final shown = _solved ? full : blanked;
    final lastItem = _item == rhyme.items.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Now try it',
          key: const Key('rhyme_game_title'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'Which word is missing?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: GameTokens.ink),
        ),
        const SizedBox(height: 10),
        Semantics(
          container: true,
          label: _solved ? full : 'Missing word line: $blanked',
          excludeSemantics: true,
          child: Container(
            key: Key(_solved ? 'rhyme_revealed_line' : 'rhyme_blank_line'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _solved ? const Color(0xFFE2F6E4) : Colors.white,
              borderRadius: BorderRadius.circular(GameTokens.radiusMd),
              border: Border.all(
                color:
                    _solved ? const Color(0xFF2E7D32) : const Color(0xFFD9D2EE),
                width: 2,
              ),
            ),
            child: Text(
              shown,
              textAlign: TextAlign.center,
              style: scriptStyle(
                shown,
                TextStyle(
                  fontSize: textScale > 1.3 ? 24 : 30,
                  fontWeight: FontWeight.w800,
                  color: GameTokens.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < options.length; i++)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120),
                child: FilledButton(
                  key: Key('rhyme_option_$i'),
                  onPressed: _solved ? null : () => _answer(options[i]),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, GameTokens.minTouch),
                    backgroundColor: _solved && options[i] == item.answer
                        ? const Color(0xFF2E7D32)
                        : _wrongTried.contains(options[i])
                            ? const Color(0xFFB9B2D0)
                            : null,
                    foregroundColor:
                        _wrongTried.contains(options[i]) && !_solved
                            ? GameTokens.ink
                            : null,
                    disabledBackgroundColor:
                        _solved && options[i] == item.answer
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE3DFF0),
                    disabledForegroundColor:
                        _solved && options[i] == item.answer
                            ? Colors.white
                            : const Color(0xFF6B6785),
                  ),
                  child: Text(
                    options[i],
                    style: scriptStyle(
                      options[i],
                      const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_wrongNow)
          const Text(
            'Nice try! Have another go.',
            key: Key('rhyme_feedback'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GameTokens.ink),
          ),
        if (_solved)
          Text(
            lastItem ? 'You did it! Well done!' : 'Yes! Well done!',
            key: const Key('rhyme_feedback'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
            ),
          ),
        const SizedBox(height: 8),
        if (_solved && !lastItem)
          FilledButton(
            key: const Key('rhyme_next_item'),
            onPressed: _nextItem,
            child: const Text('Next word'),
          ),
        if (_solved && lastItem)
          FilledButton(
            key: const Key('rhyme_finish'),
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Back to rhymes'),
          ),
        TextButton.icon(
          key: const Key('rhyme_back'),
          onPressed: _backToRhyme,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to the rhyme'),
          style: TextButton.styleFrom(
              minimumSize: const Size(GameTokens.minTouch, 48)),
        ),
      ],
    );
  }
}
