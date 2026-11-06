import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../art/art_picture.dart';
import '../rhymes/rhyme_models.dart';
import '../services/speech_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'rhyme_screen.dart';

/// The rhymes, one language at a time (English first). Cards share the screen
/// and page sideways, so the list never scrolls.
class RhymesListScreen extends StatefulWidget {
  const RhymesListScreen({
    super.key,
    this.loader = assetRhymeLoader,
    this.speech = const SpeechService(),
    this.lineDuration = estimateLineDuration,
  });

  final RhymeLoader loader;
  final SpeechService speech;
  final RhymeLineDuration lineDuration;

  @override
  State<RhymesListScreen> createState() => _RhymesListScreenState();
}

class _RhymesListScreenState extends State<RhymesListScreen> {
  RhymeLibrary? _library;
  String _language = 'english';
  int _page = 0;

  @override
  void initState() {
    super.initState();
    loadRhymeLibrary(widget.loader).then((library) {
      if (mounted) setState(() => _library = library);
    });
  }

  void _pickLanguage(String language) => setState(() {
        _language = language;
        _page = 0;
      });

  Future<void> _open(Rhyme rhyme) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RhymeScreen(
            rhyme: rhyme,
            speech: widget.speech,
            lineDuration: widget.lineDuration,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => GradientScaffold(
        appBar: AppBar(
          title: const Text(
            'Rhymes',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Wrap(
                key: const Key('rhyme_filters'),
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final language in rhymeLanguages)
                    ChoiceChip(
                      key: Key('rhyme_filter_$language'),
                      label: Text(
                        rhymeLanguageLabels[language]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      selected: _language == language,
                      onSelected: (_) => _pickLanguage(language),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      );

  Widget _body(BuildContext context) {
    final library = _library;
    if (library == null) {
      return const Center(
        key: Key('rhymes_loading'),
        child: CircularProgressIndicator(),
      );
    }
    final rhymes = library.forLanguage(_language);
    if (rhymes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            key: Key('rhymes_empty'),
            'Rhymes for this language are coming soon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: GameTokens.ink,
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 12.0;
        const pager = 56.0;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final minW = 150.0;
        final minH = 70.0 + 36 * scale;
        final width = box.maxWidth - 24;
        final cols = max(1, ((width + gap) / (minW + gap)).floor());
        int rowsFor(double h) => max(1, ((h + gap) / (minH + gap)).floor());
        var height = box.maxHeight - 8;
        var rows = rowsFor(height);
        if (rhymes.length > cols * rows) {
          height -= pager;
          rows = rowsFor(height);
        }
        final perPage = cols * rows;
        final pages = (rhymes.length / perPage).ceil();
        final page = min(_page, pages - 1);
        final shown = rhymes.skip(page * perPage).take(perPage).toList();
        final usedRows = (shown.length / cols).ceil();
        return Column(
          children: [
            Expanded(
              child: Padding(
                key: const Key('rhymes_grid'),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Column(
                  children: [
                    for (var r = 0; r < usedRows; r++) ...[
                      if (r > 0) const SizedBox(height: gap),
                      Expanded(
                        child: Row(
                          children: [
                            for (var c = 0; c < cols; c++) ...[
                              if (c > 0) const SizedBox(width: gap),
                              Expanded(
                                child: r * cols + c < shown.length
                                    ? _RhymeCard(
                                        rhyme: shown[r * cols + c],
                                        onTap: () => _open(shown[r * cols + c]),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    // Cards keep one size: unused rows stay empty.
                    if (usedRows < rows) Spacer(flex: rows - usedRows),
                  ],
                ),
              ),
            ),
            if (pages > 1)
              SizedBox(
                key: const Key('rhymes_pager'),
                height: pager,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      key: const Key('rhymes_prev'),
                      tooltip: 'Earlier rhymes',
                      onPressed: page > 0
                          ? () => setState(() => _page = page - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '${page + 1} / $pages',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: GameTokens.ink,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      key: const Key('rhymes_next'),
                      tooltip: 'More rhymes',
                      onPressed: page < pages - 1
                          ? () => setState(() => _page = page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RhymeCard extends StatelessWidget {
  const _RhymeCard({required this.rhyme, required this.onTap});
  final Rhyme rhyme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).rhymeProgressFor(rhyme.id);
    final status = progress.done
        ? 'finished'
        : progress.heard
            ? 'heard'
            : '';
    return Semantics(
      button: true,
      label: status.isEmpty ? rhyme.title : '${rhyme.title}, $status',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        child: InkWell(
          key: Key('rhyme_card_${rhyme.id}'),
          borderRadius: BorderRadius.circular(GameTokens.radiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GameTokens.radiusMd),
              border: Border.all(color: const Color(0xFFD9D2EE), width: 1.5),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ArtPicture(
                          asset: rhyme.picture.isEmpty
                              ? 'rhyme-no-picture'
                              : rhyme.picture,
                          conceptLabel: rhyme.pictureConcept,
                        ),
                      ),
                      if (progress.done)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.check_circle_rounded,
                            key: Key('rhyme_done_mark'),
                            color: Color(0xFF2E7D32),
                            size: 28,
                          ),
                        )
                      else if (progress.heard)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.hearing_rounded,
                            key: Key('rhyme_heard_mark'),
                            color: Color(0xFF5B4F8F),
                            size: 26,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rhyme.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: scriptStyle(
                    rhyme.title,
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: GameTokens.ink,
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
