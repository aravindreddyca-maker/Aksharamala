# Rhymes feature: UI hand-off (for ui-verifier)

Status: IMPLEMENTED, UNVERIFIED. Nothing was committed or pushed. No rendered screenshot was looked at; every layout claim below rests on widget tests only. Content is `rhymes_unverified` (see RHYMES_CONTENT_SPECS.md).

## What was built

| Area | File |
|---|---|
| Model, validation, loader | `lib/src/rhymes/rhyme_models.dart` |
| Rhymes list screen | `lib/src/screens/rhymes_list_screen.dart` |
| Rhyme screen (listen + game) | `lib/src/screens/rhyme_screen.dart` |
| Progress (additive) | `lib/src/models.dart` (`RhymeProgress`, `ProgressRecord.rhymes`, `withRhymes`), `lib/src/app_controller.dart` (`rhymeProgressFor`, `markRhymeHeard`, `markRhymeDone`; `recordResult` now carries `rhymes` forward) |
| Home entry | `lib/src/screens/home_screen.dart` |
| Asset registration | `pubspec.yaml` (`content/rhymes/`) |
| Tests | `test/rhymes/rhymes_test.dart` (85 tests) |

### Data
- `loadRhymeLibrary([RhymeLoader])` / `RhymeLibrary.parse(String)`; the loader is injectable (`RhymeLoader = Future<String> Function()`), default reads `content/rhymes/rhymes.json` from the asset bundle.
- Validation (invalid rhymes are skipped and listed in `library.issues`, printed with debugPrint using ids only, never rhyme text; nothing throws): unique non-empty id; language one of english/telugu/hindi/tamil; locale and title present; 2-6 non-empty lines (`speech` falls back to `text`); activity optional, but if present: kind `missing_word`, line_index in range, answer in options, 2+ distinct options, `blank_word` (if given) equal to the answer, answer word found in the indicated line (exact, else case-insensitive).
- Optional fields honoured (default false): `meaning_hidden_during_activity`, `hide_title_during_activity`.
- Generic: any number of activity items is supported (sequential, "Next word"); the content has one per rhyme.

### Home
- New `Rhymes` button (key `rhymes_button`, icon `music_note_rounded`, tooltip/label "Rhymes") between Level and Rewards, in both the wide row and the narrow header.
- Changes to existing home code, all needed to make room and keep 48dp targets (please review):
  1. Narrow header (width < 560): the button row was a `FittedBox` that would have shrunk 4 buttons below 48dp at 360 wide; it is now a `Wrap` (right aligned) so buttons keep full size. The star pill may drop to a second line on the narrowest phones.
  2. Labelled (text) action buttons now appear from width 1100 (was 900); with four labelled buttons 960 wide overflowed by 21px (caught by `test/overflow_test.dart`). 960-wide screens now get the icon-only buttons.
  3. Labelled action buttons are 48dp high (were 40-44 because of `VisualDensity.compact`).
  4. `_ActionButton` got a `super.key`.
- `ArtPicture` placeholder: the concept label is now wrapped in `ConstrainedBox(maxWidth: 220)` so a long picture_concept sentence wraps instead of shrinking to one tiny line (short labels unchanged).

### Rhymes list screen (`RhymesListScreen`)
Keys: `rhyme_filters`, `rhyme_filter_<language>` (english default), `rhymes_grid`, `rhyme_card_<rhyme id>`, `rhyme_done_mark` (check, finished), `rhyme_heard_mark` (ear icon, heard only), `rhymes_pager`, `rhymes_prev`, `rhymes_next`, `rhymes_empty`, `rhymes_loading`.
Cards share the screen in a computed grid (columns by width, rows by height and text scale) and page with prev/next buttons only if they do not all fit; no scrolling. Picture = `ArtPicture` (placeholder "Artwork coming soon" + picture_concept when the file is missing).

### Rhyme screen (`RhymeScreen`)
Keys: `rhyme_title` (`rhyme_title_hidden` replaces it), `rhyme_picture`, `rhyme_line_<i>`, `rhyme_hear_all` / `rhyme_stop`, `rhyme_voice_note`, `rhyme_voice_missing`, `rhyme_try_button`, `rhyme_try_hint`, game: `rhyme_game_title`, `rhyme_blank_line` (becomes `rhyme_revealed_line`), `rhyme_option_<i>`, `rhyme_feedback`, `rhyme_next_item`, `rhyme_finish`, `rhyme_back`.
- Layout wrapped in `FitContent` (scales to fit at normal text; scrolls at text above 1.3x). Wide landscape (width >= 640 and width > 1.3 x height): picture, Hear all and Now try it on the left, lines on the right. Otherwise one column.
- Tap a line: speaks `line.speech` with the rhyme locale, line highlighted for an estimated time. Hear all: lines in order, current one highlighted, button turns into Stop. Voice unavailable: info dialog ("Voice unavailable ... does not have the Hindi voice", language name, never rhyme text) once per visit, then a persistent inline notice.
- Note shown: "The phone's voice reads the words. It does not sing."
- Game (second page of the same screen): only the blanked line (`____`), options shuffled with a seed from the rhyme id (the answer is never in slot 0 and the order never equals the authoring order; verified for all 15), wrong answer = "Nice try! Have another go." (retry allowed, wrong word greyed, nothing revealed), right = full line revealed + "Well done". meaning_en is never displayed anywhere on the child screens; the picture concept is not shown during the game; the title is replaced by "Rhymes" when `hide_title_during_activity` is true (rhyme-te-002).
- No stars, no lesson completion, no exam involvement.

### Progress
`ProgressRecord.rhymes: Map<String, RhymeProgress{heard, done}>`. Written to the save only when non-empty (key `rhymes`); saves without it load unchanged and re-save byte-identical for that part; `saveFormatVersion` stays 2; level switching and `recordResult` leave it alone (tested, incl. persistence through `LocalStore`). Per child, because it lives in each child's record.

## Decisions and limits (read these)
1. "Heard" is set when a line is tapped or Hear all is pressed, even if the phone has no voice for the language (otherwise a child on a phone without te-IN/ta-IN could never reach the game). So "heard" means "tried to listen". A fallback notice is shown in that case.
2. The native speech channel returns as soon as speech starts, not when it ends. Hear all and the line highlight therefore wait an ESTIMATED time per line (`estimateLineDuration`: 1.3 s + 0.48 s per word). On a real phone a line may be cut off by the next one (the native side uses QUEUE_FLUSH) or followed by a pause. Needs a device check; a real fix needs an utterance-done callback in `MainActivity.kt` (not done, native code untouched).
3. Heard/done are saved with the usual whole-file save; nothing else about storage changed.
4. Hear all is not tested against a real TTS engine; all speech in tests is a fake.

## Tests
`flutter test test/rhymes` : 85 passed. Covers: real JSON loads with 0 issues (15 rhymes, 4 languages); invalid rhymes skipped (duplicate id, 1 line, 7 lines, answer not in options, word not in line, bad index, non-object, broken file, failing loader); optional hiding fields read; options for ALL 15 rhymes shuffled with the answer never in slot 0, `meaning_en` and picture concept absent during the game, title hidden for te-002 only (and back after returning to the rhyme); list filters and default English, placeholders, done/heard marks, empty-language message; line tap speaks the right text and locale (te-IN checked); Hear all order, highlight, stop; gating before heard; right/wrong/retry; no full line in widget text or Semantics before answering; progress old-save compatibility, round trip, persistence on disk, no stars, level change; layouts without exception at 360x800, 390x844, 800x1280, 1024x768, 800x360 with text 1.0 and 1.6 (list for all four languages; en-006, te-001, hi-001 both stages; Hear all/Now try it on screen when text <= 1.3); home with the button at 360x800, 390x844, 640x360, 800x360, 960x540, 1280x800 at text 1.0 and 1.6 (48dp+, on screen, no overflow, other three actions present), and tap opens the list.

Existing tests: none edited. Existing tests that were affected by the home change and now pass: `test/overflow_test.dart` (failed first at 960x540 text 1.3 before the labelled-threshold fix), `test/home_responsive_test.dart`.

## Full-suite result (after the change)
- First full run (before the overflow fix): 1155 passed, 3 skipped, 3 failed: the two rollout_sweep tests below plus `test/overflow_test.dart` (my change: 4 labelled home buttons at 960x540 text 1.3 overflowed by 21px).
- Second full run (after the fix, whole suite): 1156 passed, 3 skipped, 2 failed:
  - `test/teaching_verify/rollout_sweep_test.dart: sweep phone landscape` and `sweep phone small` (both report `numbers-56-050: no end; stuck at [4 of 5 ...] [What is the name of this shape?]`: content ambiguity, unrelated to rhymes; the known 2 earlier failures).
- A true "before" run was not done (the working tree holds many uncommitted changes from earlier work and I did not stash them).
- `flutter analyze`: 42 issues (infos and warnings, all in files I did not create or touch, mostly tests); none in the rhymes files or the lines I changed.

## Not verified
- No screenshot of any new screen was viewed; no emulator or device run.
- Telugu/Hindi/Tamil shaping and fonts in the rhyme lines (tests run with the test font); only code paths (`scriptStyle`) are applied.
- Real TTS behaviour and timing; te-IN / ta-IN voice availability.
- Touch-target size of the list chips (Material padded target, not measured); cards measured >= 48dp high.
- Picture placeholders only: no rhyme pictures exist except two entries pointing at existing quiz images (en-005, te-003, ta-003), which were not checked visually.
