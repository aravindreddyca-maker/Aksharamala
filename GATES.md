# Gates: Aksharamala vertical slice

OWNS: **

Scope: A landscape-first offline Flutter Android adventure with five illustrated worlds, responsive two-panel lessons, preserved progress/navigation, tests, and documentation.

- [x] G0: this ledger states outcomes with meaningful automated checks
  CHECK: node C:\Users\aravi\.codex\skills\unlazy\scripts\gate-lint.mjs GATES.md
  EXPECT: LINT OK
  EVIDENCE: automatic-evidence=v1; definition-sha256=468bdf5b38d113c68b662a567f8d3e1a0fa780f32613da2bc80fffe5d1033d2f; exit=0; EXPECT=matched; output-sha256=5743e8e6c87d2aa4807a0df4aec254494b036c38f3459b0e0f3e359be7f8f54d; output-bytes=340; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G1: source inspection confirms all requested product surfaces and five-world curriculum data exist
  CHECK: node tool/verify_product.mjs
  EXPECT: product source verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=463aca5965d0cb0c6ff588cba714314ecede24067e74c808a70e808afc9911ed; exit=0; EXPECT=matched; output-sha256=1dfd7474ef4966ac81648aad1fa0e4af865d97e288b32dd9060d26744b2f5945; output-bytes=81; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G2: Flutter static analysis reports no issues
  CHECK: flutter analyze
  EXPECT: No issues found!
  EVIDENCE: automatic-evidence=v1; definition-sha256=def4733d44e1b7c2406874433590e3d5501747f52462a5c0701134d34ced6732; exit=0; EXPECT=matched; output-sha256=a6638b9be1a9511c7bdcb9ebf7123634b87366acbf7f21fb65051406926fc6b0; output-bytes=519; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G3: Flutter automated tests pass
  CHECK: flutter test
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=b0c5c7eac1cebd97a444c8321c184da087193670732e19682190d1f059dae84e; exit=0; EXPECT=matched; output-sha256=647b8de9dcbf961bfde005e34e3b6dfcac64fb3f336b27a0d6cafa3b43999992; output-bytes=3405; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G4: Android debug APK is produced when the Android SDK is available
  CHECK: flutter build apk --debug
  EXPECT: Built build\app\outputs\flutter-apk\app-debug.apk
  EVIDENCE: automatic-evidence=v1; definition-sha256=b29bd79b84c14f1af84e58c2a93cfaf4ed5e8728d71cd6b27090b0f9da52370b; exit=0; EXPECT=matched; output-sha256=5216c17a652f2c7ee5264589e1513012710405729846a412701a37206ea7db01; output-bytes=550; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G5: documentation accurately identifies implemented flows, architecture, testing, and incremental expansion points
  CHECK: node tool/verify_docs.mjs
  EXPECT: documentation verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=0db7a67e696f5324c51461c2cb48ffce7df809c410ae7e44f51bef27cbf4dc40; exit=0; EXPECT=matched; output-sha256=5fdf546167baf5bdc4f619c1af10c1e37213d323a8196b34f4125c38449975d3; output-bytes=34; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G10: home redesign includes five bundled raster artworks and preserves functional world navigation
  CHECK: node tool/verify_home_redesign.mjs
  EXPECT: home redesign verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=4e27fb4fd0cbc76bff87f0f60a8b1b697f4e57c75b2f942e6404a387c8319824; exit=0; EXPECT=matched; output-sha256=95939227beba30ae11bc18bd63bef1bc0cfeaafa4917125c17cd1efd4dc90150; output-bytes=34; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G11: home and lesson screens render without layout exceptions at 640x360, 800x360, 960x540 and tablet landscape sizes with enlarged text
  CHECK: flutter test test/home_responsive_test.dart
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=16467915849d2a8c03d900b193eb732dd0aeab5daec77f7a2c053180cc62677f; exit=0; EXPECT=matched; output-sha256=be9806e1c6676ed726a1a84cecce3a31918f0020ed43f3fbb704b4c90bad1f62; output-bytes=1160; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G6: no screen overflows (home, profile, rewards, parents, five world maps, every lesson) at 360x640, 411x914, 768x1024 and 914x411 with text scaled 1.0 and 1.3
  CHECK: .tooling\flutter\bin\flutter.bat test test\overflow_test.dart
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=84d37b8c50d847c008474f1cab9943511f690b4f4eabe98eb380d3cecf9d28dd; exit=0; EXPECT=matched; output-sha256=25264703b3c6f06b5c7d8e7fe2b41097e50da026a0ede039fd4ceb752307c059; output-bytes=615; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G7: every world card paints a gradient dark enough for its white text (contrast at least 4.5:1 measured from rendered pixels, not from colour constants)
  CHECK: .tooling\flutter\bin\flutter.bat test test\card_paint_test.dart
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=58876759106fb71f59e93cf00d93ed66223c4c27a259803948fc3c8a498d73d0; exit=0; EXPECT=matched; output-sha256=07d7a2558e391d71ee0d729efc88722cd3f682f507666ef77e8f5daeefc29d5a; output-bytes=631; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G8: both gradient stops of every world meet 4.5:1 against white text
  CHECK: .tooling\flutter\bin\flutter.bat test test\contrast_test.dart
  EXPECT: All tests passed!
  EVIDENCE: automatic-evidence=v1; definition-sha256=98ed14e574ae559b6c75dda66a2c26ff93941205a4c94b21d91ad28022ae8510; exit=0; EXPECT=matched; output-sha256=1ff83682f8318ea74d861b84ec48905dc0442e429e286fbe779f0db8c65d6985; output-bytes=617; shell=C:\Windows\system32\cmd.exe; cwd=C:\Users\aravi\OneDrive\Documents\ChatGPT\Excel; path=62414b0f71da/34 entries

- [x] G9: the installed API 36 build launches full-width in landscape without overflow and preserves profile navigation
  EVIDENCE: API 36 emulator launch and profile navigation visually verified at 2400x1080; screenshots saved as outputs/aksharamala-emulator.png and outputs/aksharamala-profile.png. Automated G6-G8 and G11 cover every world, lesson kind, parent/reward screen, requested landscape viewport and text scaling.
