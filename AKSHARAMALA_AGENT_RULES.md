# Aksharamala four-agent orchestration

Use four separate agents in this order: content-creator → content-verifier → ui-creator → ui-verifier. Verification must be independent. A REVISE verdict returns to the corresponding creator. BLOCKED remains open until evidence or human review is available. No agent self-approves.

## Modes
- AUDIT ONLY (default): inspect existing work and report; no code changes.
- PILOT: after user approval, implement one lesson per world (five total), including a Number Galaxy interactive maths concept. Verify each stage.
- ROLLOUT: only after user approves pilot; use manageable batches and report each batch.

## Teaching gate
No lesson is COMPLETE solely because it has text, images and quiz questions. Require an introduction, stepwise teaching demonstration, guided activity, independent practice, mastery check and appropriate remediation. Do not use formal examinations as initial teaching.

## Progression
Mastery thresholds should be configurable, not hardcoded as pedagogical truth. Failed mastery should offer different examples and support, not endless identical questions. Preserve level switching and existing saved progress. Keep formal parent examinations separate.

## Evidence and reports
Generate audit/EXISTING_CONTENT_AUDIT.md, audit/TEACHING_CONTENT_GAPS.csv, audit/MATHS_LEARNING_PROGRESSION.md, audit/CONTENT_VERIFICATION_REPORT.md, audit/UI_VERIFICATION_REPORT.md, audit/PILOT_TEST_RESULTS.md, audit/REMAINING_WORK.md. Include ID, world, level, source file, issue, severity, evidence, proposal, status, reviewer. Do not invent passing test results or completed assets.

## Workbook
Use reference/Aksharamala_Consolidated_Curriculum_Levels_1_to_5.xlsx if present. Treat proposed entries as proposals, reconcile duplicates and conflicting counts against actual repository. Do not infer implementation from workbook inclusion.
