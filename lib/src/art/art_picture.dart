import 'package:flutter/material.dart';

import '../theme.dart';
import 'art_registry.dart';

/// A bundled picture. If the file loads it is shown; otherwise a clearly
/// labelled temporary tile appears (never a broken-image icon).
class ArtPicture extends StatelessWidget {
  const ArtPicture({
    required this.asset,
    super.key,
    this.fit = BoxFit.contain,
    this.conceptLabel,
    this.hideConcept = false,
    this.registry = artRegistry,
    this.semanticLabel,
  });

  final String asset;
  final BoxFit fit;

  /// Label for the placeholder when the registry has no entry (e.g. a caption).
  final String? conceptLabel;

  /// Question pictures must not name the answer: the placeholder then says
  /// only "Artwork coming soon".
  final bool hideConcept;
  final Map<String, ArtAssetSpec> registry;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = hideConcept
        ? null
        : (registry[asset]?.concept ??
            (conceptLabel != null && conceptLabel!.isNotEmpty
                ? conceptLabel
                : null));
    return Image.asset(
      asset,
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (_, __, ___) => _Placeholder(label: label),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.label});
  final String? label;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('art_placeholder'),
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEAF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8A7FB8), width: 2),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_outlined,
                    color: Color(0xFF5B4F8F), size: 28),
                const SizedBox(height: 4),
                const Text(
                  'Artwork coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameTokens.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (label != null)
                  // A long concept (a sentence) wraps instead of becoming one
                  // tiny line; short labels are unaffected.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      label!,
                      textAlign: TextAlign.center,
                      style: scriptStyle(
                        label!,
                        const TextStyle(color: GameTokens.ink, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
