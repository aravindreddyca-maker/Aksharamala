# Gates: Aksharamala Phase 1–2 landscape upgrade

OWNS: **

Scope: audit and upgrade the existing app through Phase 2 while preserving profiles, progress, curriculum, routes and offline Android behavior.

- [x] G0: the gate ledger is structurally valid
  CHECK: node C:\Users\aravi\.codex\skills\unlazy\scripts\gate-lint.mjs GATES.md
  EXPECT: LINT OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=468bdf5b38d113c68b662a567f8d3e1a0fa780f32613da2bc80fffe5d1033d2f; exit=0; EXPECT=matched; output-sha256=48630b7361dd44ee870917b12c3d19b9d7bdea738aaca16bb04d4cab83b772d2; output-bytes=8; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=186326ec9ac8/33 entries

- [x] G1: product source still contains all preserved vertical-slice capabilities
  CHECK: node tool/verify_product.mjs
  EXPECT: product source verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=463aca5965d0cb0c6ff588cba714314ecede24067e74c808a70e808afc9911ed; exit=0; EXPECT=matched; output-sha256=1dfd7474ef4966ac81648aad1fa0e4af865d97e288b32dd9060d26744b2f5945; output-bytes=81; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=186326ec9ac8/33 entries

- [x] G2: Phase 1–2 source, compatibility, artwork and viewport requirements are present
  CHECK: node tool/verify_phase12.mjs
  EXPECT: phase 1 and 2 source verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=788e7f54db6a53af148455d77a917c22cbc9c76aaa00c70f4cd0b17f7b392734; exit=0; EXPECT=matched; output-sha256=7d6b7ddb7fcaa0593fc08cd2071bec09d6ee6b342068413524885e27e8922c0d; output-bytes=41; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=186326ec9ac8/33 entries

- [x] G3: Flutter static analysis reports no issues
  CHECK: "C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel\.tooling\flutter\bin\flutter.bat" analyze
  EXPECT: No issues found!
  EVIDENCE: automatic-evidence=v1; definition-sha256=ca8cf6db183c613ce97cde76d5023fc68ede678081831bbdd8728d8b13fa2bc6; exit=0; EXPECT=matched; output-sha256=8973505768760e1550f5dac94ff77af0f8bd16eaae848138be633abb279686ca; output-bytes=519; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=186326ec9ac8/33 entries

- [x] G4: the complete Flutter automated test suite passes
  CHECK: "C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel\.tooling\flutter\bin\flutter.bat" test
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=4cb0d0a526a823712981a6abbe795838580f32f407147421b634593e6e4a8519; exit=0; EXPECT=matched; output-sha256=70f34199f485b7cc805d7b7c29f6289d50a65956baeaeba38ee6e32d8cbbb6c0; output-bytes=2712; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=186326ec9ac8/33 entries

- [x] G5: every implemented screen and lesson is overflow-free at the required landscape sizes and enlarged text
  CHECK: "C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel\.tooling\flutter\bin\flutter.bat" test test/overflow_test.dart
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=891f9a9901bc97a1f12f4aa709b0aae90caa87f4de227055c503a8bd31e68050; exit=0; EXPECT=matched; output-sha256=1a517d8e05295acef7ffca8579358b547011aae38e04821e5c40c3d6818094d6; output-bytes=582; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=186326ec9ac8/33 entries

- [x] G6: documentation states the implemented scope and honest later-phase boundary
  CHECK: node tool/verify_docs.mjs
  EXPECT: documentation verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=0db7a67e696f5324c51461c2cb48ffce7df809c410ae7e44f51bef27cbf4dc40; exit=0; EXPECT=matched; output-sha256=5fdf546167baf5bdc4f619c1af10c1e37213d323a8196b34f4125c38449975d3; output-bytes=34; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=186326ec9ac8/33 entries

- [x] G7: Android debug APK builds with the available SDK
  CHECK: "C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel\.tooling\flutter\bin\flutter.bat" build apk --debug
  EXPECT: Built build\app\outputs\flutter-apk\app-debug.apk
  EVIDENCE: automatic-evidence=v1; definition-sha256=ea7bd0c38f581f091a0f64701065db69b5adc79379c8e1a3706073549772ecfe; exit=0; EXPECT=matched; output-sha256=f1b1ff94cd0a2b3891241140236b4776f33ac07d77f9bcf9fe272767525ad283; output-bytes=550; shell=C:\Windows\system32\cmd.exe; cwd=E:\Aksharamala; path=186326ec9ac8/33 entries
