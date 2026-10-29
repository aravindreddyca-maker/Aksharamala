# Handwriting Academy implementation specification

Modes: watch stroke animation; guided dotted tracing; free writing; delayed review. Use vector paths in normalized coordinates per glyph and per accepted letterform, not a generic font outline as stroke order.

Data per glyph: script, grapheme, variant, base consonant, sign, components, ordered stroke polylines, allowed direction, anchor points, tolerance, instructional audio, sample image, verified_by, verification_date. Store null for missing geometry.

Validation: require meaningful coverage of ordered strokes, shape similarity, pen-up transitions where appropriate, and adjustable tolerance. Permit motor-skill accessibility adaptations. Do not reject valid culturally accepted alternate stroke orders without educator review.

Compound Indic graphemes: distinguish character sequence, visual glyph and handwriting components; test Unicode normalization, shaping, font support and script-specific rendering. For Tamil uyirmei and Hindi matras, explicitly model signs appearing before/around the base consonant visually.

Numbers: 0–9 digit stroke paths; multi-digit numbers should be evaluated digit by digit and for order/spacing, not a single continuous stroke.

Do not grant mastery while stroke validation is disabled.
