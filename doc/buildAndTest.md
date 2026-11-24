# Build and Test

This document describes how to build and test asc-for-mac. The architecture of the build is
decided in `doc/architecture.md` (section *Build tool, test framework and static quality
check*); the required tools are listed in `doc/developerInfrastructure.md`.

The **Xcode project `ASCforMac.xcodeproj` is the main build**. Its external build target
`AscCore` runs the CMake build (`scripts/build-core.sh`), which builds the ASC core, the facade
and the libraries from vcpkg; then Xcode builds the Swift app.

## Commands

| What | Command |
|------|---------|
| Build everything (Debug) | `scripts/build.sh` (`--release` for Release) |
| Run all automated tests | `scripts/test-app.sh` |
| Run the UI test (takes over mouse and keyboard) | `scripts/test-ui.sh` |
| Run the long-game test (AI against AI, takes minutes) | `scripts/test-long-game.sh` |
| Build, sign, notarize and package the app as `.dmg` for a release | `scripts/create-dmg.sh` |
| Create the archive of the library sources for a release | `scripts/create-source-archive.sh` |
| Publish a release on GitHub | see *Release on GitHub* |
| Run all automated tests with AddressSanitizer and UndefinedBehaviorSanitizer | `scripts/test-sanitizers.sh` |
| Measure the code coverage and check it against the baseline | `scripts/test-coverage.sh` (`--update-baseline` writes a new baseline) |
| Run the static quality check | `scripts/check.sh` |
| Create the SBOM `doc/sbom.spdx.json` after updating ASC or a library | `scripts/create-sbom.sh` (`--check` only checks it) |
| Create the licence information for the app (also done by every build) | `scripts/create-licenses.sh` |
| Start the app (the game) | `scripts/run.sh` (`--build` builds it first) |
| Start the app without the game | `build/xcode/Build/Products/Debug/ASCforMac.app/Contents/MacOS/ASCforMac --no-game` |
| Run the tests of the scripts in `scripts/` | `scripts/test.sh` |
| Render the app icon as `.icns` (used for the `.dmg` volume icon) | `scripts/create-icns.sh app/ASCforMac/AppIcon.icon OUTPUT.icns` |

In Xcode, open `ASCforMac.xcodeproj` and use the scheme `ASCforMac`: Cmd+B builds, Cmd+U
tests, Cmd+R runs. Xcode asks once to trust the SwiftLint plugin ("Trust & Enable"); the
scripts pass `-skipPackagePluginValidation` instead.

## The app (Xcode)

- **Project:** `ASCforMac.xcodeproj`, shared schemes `ASCforMac` and `ASCforMacUITests` (only the
  UI test, see below); build output of the scripts in
  `build/xcode` (Xcode's DerivedData for this project).
- **Targets:**
  - `AscCore`: external build target, runs `scripts/build-core.sh`.
  - `ASCforMac`: the Swift app (`app/ASCforMac/`), Swift 6.4 in the Swift 6 language mode,
    arm64, macOS 27. It depends on `AscCore`, imports the facade as Clang module `AscFacade`
    (`facade/include/module.modulemap`, Swift/C++ interoperability) and links
    `$(ASC_CORE_BUILD_DIR)/libasc_all.a`. The build setting `ASC_CORE_BUILD_DIR` is
    `build/core`; `ASC_CORE_BUILD_ARGS` (empty) is passed to `scripts/build-core.sh`. The
    sanitizer run and the coverage run override both (see *Sanitizer run* and *Code coverage*).
    The build phase "Copy ASC game data" copies `main.ascdat`, `asc2_dlg.zip` and `pbp.ascdat`
    from `$(ASC_CORE_BUILD_DIR)/game-data/` into `Contents/Resources`; the build phase "Copy
    licence information" copies `$(ASC_CORE_BUILD_DIR)/licenses/Licenses.json` there (see
    *Licence information*). The build phase "Resources" compiles the app icon (see *App icon*).
    Debug builds are signed ad hoc ("Sign to Run Locally"); Release
    builds are signed with the Developer ID and the hardened runtime (see *Release package*).
  - `ASCforMacTests`: Swift Testing tests (`app/ASCforMacTests/`), hosted in the app.
- **Result:** `build/xcode/Build/Products/Debug/ASCforMac.app` (Release: `.../Release/`).

## App icon

The app icon (TASK-0030) is the Icon Composer document `app/ASCforMac/AppIcon.icon`: `icon.json`
(background gradient, the layer groups "Unit" and "Hex field" with their Liquid Glass settings)
and the layers as SVG in `Assets/` (`jet.svg`, `hex.svg`, drawn for a 1024x1024 canvas). The
motif and its origin are described in `doc/thirdparty.md` (*App icon*).

- **Editing:** open `AppIcon.icon` with Icon Composer (comes with Xcode, *Xcode › Open Developer
  Tool › Icon Composer*), or edit `icon.json` and the SVG files as text. Follow Apple's Human
  Interface Guidelines for app icons
  (<https://developer.apple.com/design/human-interface-guidelines/app-icons>): square, unmasked
  layers (the system rounds the corners), content centred, a simple motif without text, no
  self-made highlights or shadows, recognisable in all appearances (default, dark, clear,
  tinted).
- **Preview:** Icon Composer shows all appearances; on the command line, Icon Composer's
  `ictool` renders them, e.g.
  `"$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool" app/ASCforMac/AppIcon.icon --export-image --output-file icon.png --platform macOS --rendition Dark --width 1024 --height 1024 --scale 1`
  (renditions: `Default`, `Dark`, `ClearLight`, `ClearDark`, `TintedLight`, `TintedDark`).
- **Build:** `AppIcon.icon` is in the build phase "Resources" of the target `ASCforMac`, and
  the build setting `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` makes it the app icon. Xcode
  (`actool`) compiles it into `Contents/Resources/Assets.car` (all sizes from 16x16 to 512x512
  points, each also @2x, and the layers for the appearances) and `AppIcon.icns` (for older
  systems), and sets `CFBundleIconName` and `CFBundleIconFile` in `Info.plist`. Nothing is
  generated into the repository.
- **About window:** shows the icon of the running app (`NSApplication.applicationIconImage`).
- **`.dmg` volume icon:** `scripts/create-dmg.sh` renders the icon with
  `scripts/create-icns.sh` (ictool, default appearance, all `.icns` sizes up to 1024x1024
  pixels) as `.VolumeIcon.icns` at the root of the volume and sets the Finder's custom-icon
  flag on it (see *Release package*).
- **Tests:** `AppTests` checks the icon in the bundle and the About window, `MenuBarUITests`
  the icon in the About window, `scripts/test.sh` the `.icns` and the volume icon of the `.dmg`.
- If the Finder still shows the generic icon for an app built before the icon existed, it
  shows a cached icon; `touch build/xcode/Build/Products/Debug/ASCforMac.app` refreshes it.

## Release package

`scripts/create-dmg.sh` builds the signed and notarized `.dmg` for a release (TASK-0014):

1. It builds the Release configuration (`scripts/build.sh --release`). Xcode signs the app with
   the "Developer ID Application" certificate of the Team ID `KYSS6YD767` (see
   `doc/context.md`), with the hardened runtime and a secure timestamp (build settings of the
   Release configuration: `CODE_SIGN_IDENTITY`, `DEVELOPMENT_TEAM`, `ENABLE_HARDENED_RUNTIME`,
   `OTHER_CODE_SIGN_FLAGS = --timestamp`). The app needs no entitlements;
   `CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO` keeps Xcode from adding the debugging entitlement
   `com.apple.security.get-task-allow`, which notarization rejects (the script checks this).
2. It checks the signature, notarizes the app with `xcrun notarytool` and staples the ticket
   (`xcrun stapler`).
3. It creates `build/release/ASC-for-Mac-<release version>.dmg` (`diskutil image create`,
   APFS, compressed) with the app, a link to the Applications folder and the app icon as volume
   icon (see *App icon*), signs it with the same certificate, notarizes and staples it.
4. It checks the app and the `.dmg` with Gatekeeper (`spctl --assess`).

- **Release version:** the app's version (`MARKETING_VERSION`, ASC's version, e.g. `2.6.99.0`)
  plus `-mac` and the build number (`CURRENT_PROJECT_VERSION`, the counter of the Mac port's
  releases for the same ASC version), e.g. `2.6.99.0-mac1` (user decision in TASK-0014).
  macOS allows only digits and periods in the app's version, so the suffix is used only for
  the release tag, the release name and the `.dmg` file name; About shows "App version
  2.6.99.0 (build 1)". For a new release of the same ASC version, increase
  `CURRENT_PROJECT_VERSION` in both configurations of the project (and the expected values in
  `AppTests` and `MenuBarUITests`).
- **Prerequisites (once per Mac):** the "Developer ID Application" certificate with its
  private key in the login keychain (`security find-identity -v -p codesigning` lists it), and
  the notarization credentials in the keychain profile `asc-for-mac-notary`. Create the
  profile in a Terminal with
  `xcrun notarytool store-credentials asc-for-mac-notary --apple-id <Apple ID> --team-id KYSS6YD767`;
  it asks for an app-specific password (created at <https://account.apple.com>, *Sign-In and
  Security* › *App-Specific Passwords*). `--profile NAME` uses another profile. The certificate,
  the private key and the password are never stored in the repository.
- When `codesign` first uses the private key, macOS may ask for access to it; allow it.
  Notarization needs a network connection and usually takes a few minutes per submission (the
  app and the `.dmg`). If Apple rejects a file, the script stops and names the command that
  shows Apple's log.
- **Checked by the user** (TASK-0014): the app from the notarized `.dmg`, marked as downloaded,
  starts the game. macOS asks once whether to open an app downloaded from the internet (the
  normal question for every notarized app); there is no warning about an unidentified
  developer or malware, and later starts ask nothing.
- `--no-notarization` only builds, signs and packages (e.g. to check the `.dmg`); such a
  `.dmg` shows a security warning on other Macs and must not be published.
- `--package-only APP DMG` only packages an existing app as `.dmg` with the volume icon,
  without building, signing and notarizing; `scripts/test.sh` uses it to test the packaging.
- The `.dmg` is build output in `build/release/` and is not committed. It is published as a
  GitHub Release (see *Release on GitHub*).

## Release on GitHub

Releases are published on <https://github.com/tnfink/asc-for-mac/releases> (git remote
`origin`), as a GitHub Release per release version (TASK-0029). Each release contains the
signed and notarized `.dmg` and the archive of the library sources, because the GPL and LGPL
require the complete source code from the same place as the app (`doc/thirdparty.md`,
*Licence analysis*): the tag holds the own code and ASC, the archive the libraries from vcpkg.
Publishing needs the GitHub CLI `gh`, logged in by the developer (see
`doc/developerInfrastructure.md`), and the prerequisites of *Release package*.

1. **Version:** the release version is `<MARKETING_VERSION>-mac<CURRENT_PROJECT_VERSION>`, e.g.
   `2.6.99.0-mac1` (see *Release package*). For a new release, set it in the project (both
   configurations) and in the expected values of `AppTests` and `MenuBarUITests`, in
   `scripts/sbom-components.json` (entries `app` and `own-code`) and in `vcpkg.json`
   (`version-string`), then run `scripts/create-sbom.sh`.
2. **Checks:** `scripts/test.sh`, `scripts/test-app.sh`, `scripts/check.sh` and the long-game
   test `scripts/test-long-game.sh` (QA measure S3, for every release) must pass.
3. **Commit** all changes; the working tree must be clean (`git status --porcelain` prints
   nothing), so that the release is built exactly from the tagged commit.
4. **Build:** `scripts/create-dmg.sh` (creates `build/release/ASC-for-Mac-<release>.dmg`) and
   `scripts/create-source-archive.sh` (creates
   `build/release/ASC-for-Mac-<release>-vcpkg-sources.tar.gz`: the sources vcpkg downloads for
   all libraries at the vcpkg baseline, vcpkg's port files with their patches, and a
   `README.txt`; it takes a few minutes and needs a network connection).
5. **Tag and push:** `git tag -a <release> -m "ASC for Mac <release>"` and
   `git push origin main <release>`.
6. **Draft release:**
   `gh release create <release> build/release/ASC-for-Mac-<release>.dmg build/release/ASC-for-Mac-<release>-vcpkg-sources.tar.gz --draft --verify-tag --title "ASC for Mac <release>" --notes-file <notes>`.
   The release notes name the system requirements (macOS 27 on Apple Silicon) and how to
   install (see `README.md`), refer to the source code (the tag `<release>`, the archive of the
   library sources) and to the licence information in the app (*ASC for Mac › Licenses…*).
7. **Publish:** check the draft on GitHub (download the `.dmg`, open it, start the app), then
   publish it there or with `gh release edit <release> --draft=false --latest`.

The licence information in the app names <https://github.com/tnfink/asc-for-mac> and its
Releases page as source code location (`scripts/licenses.json`).

## Running the game

`scripts/run.sh` opens the app, which starts the game (TASK-0013):

- The app sets up its AppKit menu bar and then calls the facade function `runGame`, which runs
  ASC's unchanged main program (`asc_game_main`, see *ASC core*) on the main thread. ASC creates
  the game window with SDL2 (in full screen by default; `ForceWindowedMode = true` in `asc2rc`
  starts it in a window) and shows its startup map (`asc001.map`) with ASC's own menu bar; a new
  game is started through ASC's menu **Game**. SDL uses the app's `NSApplication` and
  menu bar, so About and Quit work while the game runs. When the game ends, the app quits.
- **Full screen and the menu bar** (TASK-0027): in full screen, the menu bar (About,
  Licenses…, Quit) appears when the pointer is moved to the top edge of the screen, as in other
  Mac apps in full screen. At the start, the window briefly animates into full screen. ASC's map
  scrolling at the screen edges is unchanged, so reaching the menu bar also scrolls the map up
  (the user's decision). macOS treats the full-screen game as a game: it turns on Game Mode and
  may show a notice about the game overlay.
  - *Cause of the hidden menu bar:* ASC's full screen created the window with SDL's
    `SDL_WINDOW_FULLSCREEN_DESKTOP` (`PG_Application::InitScreen` in ParaGUI). For such windows,
    SDL 2 hides the menu bar on purpose (`src/video/cocoa/SDL_cocoawindow.m` of SDL 2.32.10): its
    window delegate requests `.hideMenuBar` (`window:willUseFullScreenPresentationOptions:`), and
    it calls `[NSMenu setMenuBarVisible:NO]` when the window enters full screen and whenever it
    becomes the key window. Setting the app's presentation options from Swift has no effect
    against this (tried and checked in the running game).
  - *Solution:* on macOS, `PG_Application::InitScreen` creates a normal resizable window and
    puts it into macOS full screen, as the green window button does (`toggleFullScreen:`
    through the Objective-C runtime). SDL leaves the menu bar alone for such windows. ASC's
    logical screen size and scaling are unchanged. This is a marked change in
    `thirdparty/asc/` (see `doc/thirdparty.md`), offered to ASC as a pull request.
- **Switching full screen at runtime** (TASK-0028): the green window button, the menu
  *View › Enter Full Screen* / *Exit Full Screen* and Ctrl+Cmd+F switch the game between full
  screen and a window while it runs, after a full-screen start and after a windowed start. ASC's
  screen size is fixed at the start (full screen: screen size divided by the display scaling;
  window: 90 % of that at 100 %), so the game is scaled to the window (also when the window is
  resized, with black bars if the aspect ratio differs); leaving full screen after a full-screen
  start gives a window of 90 % of the screen. Map scrolling at the screen edges works only in
  full screen, as in ASC, and follows the current mode. The *View* menu item works on the key
  window, so it is disabled without the game window (e.g. with `--no-game`).
- **Data:** the game data is read from the app bundle (`Contents/Resources`). User data is in
  `~/Library/Application Support/asc-for-mac/`: ASC's configuration file `asc2rc`, save games,
  maps and `log.txt`. Before each start, the facade writes the two search paths into `asc2rc`
  (first the user data directory, then the bundle's resources, because the bundle may move) and
  starts ASC as `asc -c <that file>`; ASC's other settings in the file are kept. `~/.asc/` is not
  used.
- **Quit (Cmd+Q):** sends SDL's quit event, so ASC ends the game through its own quit handling.
  ASC ignores the event while one of its dialogs is open (e.g. the tip shown at the start); then
  the app asks after one second whether to quit anyway (user decision in TASK-0013). The game
  is started and the question is scheduled with run loop timers (`perform(_:with:afterDelay:)`),
  not with the main dispatch queue: while the game runs, it blocks the main queue.
- **Tests:** the test target is hosted in the app; while it hosts the tests (environment variable
  `XCTestConfigurationFilePath`), the app does not start the game.
- **Agreement at the first start** (TASK-0026): before the game starts for the first time, the
  app shows a short agreement referring to the GPL (text in `doc/architecture.md`, *Licence
  agreement at the first start*). "Accept" stores the acceptance and starts the game,
  "Decline" or closing the window quits the app, and "Show Licence" opens the Licenses window
  with the GPL. The acceptance is stored in the app's `UserDefaults`; to see the agreement
  again (e.g. for testing), reset it with
  `defaults delete de.tofimusrom.ASCforMac LicenseAgreementAccepted`. The launch argument
  `--show-agreement` shows the agreement regardless of the stored acceptance and does not store
  an acceptance; the UI test uses it together with `--no-game`. The unit tests use a
  `UserDefaults` suite of their own, so no test depends on or changes the stored acceptance.
- **Without the game:** started with the launch argument `--no-game`, the app does not start the
  game; only the menu bar and the app's own windows (About, Licenses) are available, and Cmd+Q ends the
  app immediately. The UI test uses it (TASK-0019).
- **Music:** ASC's music files (`data/music/Makefile.am`) are not part of the ASC repository;
  they are kept in `thirdparty/asc-music/` (see `doc/thirdparty.md`) and copied by the build
  phase "Copy ASC game data" into `Contents/Resources/music/`. Music is switched on and off in
  ASC's dialog "Sound Settings" ("Enable Music").

## Facade

The facade (`facade/`) is built by the CMake build as static library: `asc_facade` (C++20,
warnings as errors; `facade/include/AscFacade.h` is the only header the Swift app sees) and
`asc_facade_adapter` (C++11; the only file that includes ASC's headers, which cannot be
compiled with C++20). The CMake target `asc_all` combines the facade, the ASC core and the
needed libraries from vcpkg into `build/core/libasc_all.a`, which the Xcode project links.

## Tests

`scripts/test-app.sh` runs `xcodebuild test`:

- `FacadeTests`: tests of the facade, e.g. that the ASC version comes from the ASC core.
- `AppTests`: tests of the app's parts that run without the game window (versions, user data
  directory, no game start while hosting tests or with `--no-game`). Starting, playing and
  quitting the game are checked manually.
- `LicenseInfoTests`: the licence information in the app bundle lists the same packages as
  the SBOM (ID, name, version, licence), every package has a copyright notice and licence
  texts and, for GPL and LGPL, a source code location; the menu item "Licenses…" opens the
  window.
- `PerformanceTests`: the performance smoke test (QA measure S5, TASK-0018). Through the
  facade, without a window, it loads the standard maps `asc001.map`, `railstations2.map` and
  `asc014.map` and lets ASC's AI play one round on each; it fails if a load time or the average
  AI turn exceeds its limit (see `doc/qameasures.md`) and prints the measured times
  ("Performance smoke test: …" in the output). It takes about 10 s. The same suite has quick
  tests of saving and loading a game through the facade (TASK-0017).
- `LongGameTests`: the long-game test, skipped here; see *Long-game test* below.
- `UnittesterTests`: runs ASC's `unittester` like `scripts/test-core.sh` (see below) and fails
  if it reports an error. It runs the `unittester` in `build/core`, or in the directory given by
  the environment variable `ASC_CORE_BUILD_DIR`.

## Long-game test

`scripts/test-long-game.sh` runs only `LongGameTests` (`app/ASCforMacTests/LongGameTests.swift`,
QA measure S3, TASK-0017). Through the facade, without a window, ASC's AI plays all players of
the standard maps `asc001.map`, `railstations2.map` and `asc014.map` for 100 rounds each; the
game is saved and loaded after every 10 rounds and must continue with the same turn, player
and number of players. The test fails if the game crashes, ASC reports an error or saving or
loading fails. A game that ends earlier (fewer than two players left) passes. For each map it
prints the result ("Long-game test: …" in the output).

- It takes about 2 minutes (Debug build, Apple M2 Max; plus the build if needed), so `scripts/test-app.sh`,
  `scripts/test-sanitizers.sh` and `scripts/test-coverage.sh` skip it: the test runs only if the
  environment variable `ASC_LONG_GAME` is `1`, which the script passes to the tests through
  xcodebuild (`TEST_RUNNER_ASC_LONG_GAME=1`).
- The maps, the number of rounds, the save interval and the handling of an early end are
  user decisions, see `doc/qameasures.md` (S3).

## UI test

`scripts/test-ui.sh` runs the UI test target `ASCforMacUITests` (`app/ASCforMacUITests/`,
XCTest UI testing) with its own scheme `ASCforMacUITests` (QA measure S6). It starts the app
with `--no-game` and checks that the app menu has About and Quit, that About opens a window
showing the ASC core version and the app version with its build number, that "Licenses…" opens the licence window, which lists ASC with
its licence, and that Cmd+Q ends the app. Quitting while the game runs (the
question "Quit anyway?") is checked manually.

- The UI test takes over mouse and keyboard while it runs (about half a minute); do not use the
  computer meanwhile. Therefore it is not part of `scripts/test-app.sh`,
  `scripts/test-sanitizers.sh` or `scripts/test-coverage.sh`, which use the scheme `ASCforMac`.
- macOS asks once for the permission for UI automation, see
  `doc/developerInfrastructure.md`.
- In Xcode, select the scheme `ASCforMacUITests` and press Cmd+U.

## Sanitizer run

`scripts/test-sanitizers.sh` runs all automated tests with AddressSanitizer (memory errors)
and UndefinedBehaviorSanitizer (undefined behavior), QA measure S2 (`doc/qameasures.md`):

1. `scripts/build-core.sh --sanitizers` builds the ASC core, the facade and `unittester` with
   the CMake preset `macos-sanitizers` into `build/core-sanitizers` (CMake option
   `ASC_SANITIZERS`: `-fsanitize=address,undefined -fno-sanitize-recover=all
   -fno-omit-frame-pointer -O1 -g`). The libraries from vcpkg are not instrumented.
2. `scripts/test-core.sh --sanitizers` runs this `unittester`.
3. `xcodebuild test` with `-enableAddressSanitizer YES -enableUndefinedBehaviorSanitizer YES`
   and `ASC_CORE_BUILD_DIR=build/core-sanitizers`, `ASC_CORE_BUILD_ARGS=--sanitizers` (output
   in `build/xcode-sanitizers`); the unittester test gets the directory via
   `TEST_RUNNER_ASC_CORE_BUILD_DIR`. In Swift code, only AddressSanitizer applies.

Every finding aborts the program with a report (`ERROR: AddressSanitizer: ...` or
`runtime error: ...`, with the source location) and makes the script fail. The normal build
(`build/core`, `build/xcode`) is not touched.

**Diagnosis:** to list all UndefinedBehaviorSanitizer findings of one run instead of stopping
at the first one, configure a separate build directory with the CMake option
`ASC_SANITIZER_RECOVER`:

```bash
VCPKG_ROOT=build/vcpkg cmake --preset macos-sanitizers -B build/core-san-recover -DASC_SANITIZER_RECOVER=ON
cmake --build build/core-san-recover --parallel
cd build/core-san-recover/unittest-run && ../unittester -c asc2rc 2>&1 | grep "runtime error"
```

## Code coverage

`scripts/test-coverage.sh` measures the line coverage of the project's own code, QA measure S7
(`doc/qameasures.md`):

1. `scripts/build-core.sh --coverage` builds with the CMake preset `macos-coverage` into
   `build/core-coverage`; the CMake option `ASC_COVERAGE` compiles the facade
   (`asc_facade`, `asc_facade_adapter`) with `-fprofile-instr-generate -fcoverage-mapping`. The
   ASC core is not instrumented.
2. `xcodebuild test -enableCodeCoverage YES` with `ASC_CORE_BUILD_DIR=build/core-coverage`,
   `ASC_CORE_BUILD_ARGS=--coverage` (output in `build/xcode-coverage`). Xcode instruments the
   Swift app and links the profile runtime.
3. `xcrun llvm-cov export` reads Xcode's coverage data (`build/xcode-coverage/Build/ProfileData`)
   and the app binary. Xcode's own report (`xcrun xccov`) does not show the facade, because
   Xcode did not compile it. The script prints the line coverage per file and in total for
   `app/ASCforMac/` and `facade/`; `thirdparty/asc/` (including ASC headers inlined into the
   adapter) and the test target are not counted.
4. The values are compared with the baseline in `scripts/coverage-baseline.txt` (covered lines,
   total lines, file; last line `TOTAL`). The script fails if the total or any file's coverage
   is lower than in the baseline (no tolerance; the measurement is deterministic), or if files
   were added or removed since the baseline was written.

When the coverage rises, or a drop or a new file is intended, write a new baseline with
`scripts/test-coverage.sh --update-baseline` and commit `scripts/coverage-baseline.txt`. The
normal build (`build/core`, `build/xcode`) is not instrumented.

## Static quality check

`scripts/check.sh` checks only the project's own code (`app/`, `facade/`), not
`thirdparty/asc/`, and fails on any finding:

1. `swift format lint --strict` (included in Xcode), configured in `.swift-format`,
2. clang-tidy for the facade, configured in `facade/.clang-tidy`; the script finds it via
   `brew --prefix llvm`, or via the environment variable `CLANG_TIDY`; it parses template
   bodies only when they are used (`-fdelayed-template-parsing`), because some of ASC's
   headers contain templates that Homebrew's newer clang rejects (TASK-0018),
3. the Clang Static Analyzer (`clang++ --analyze`, included in Xcode) for the facade,
4. the Xcode build, in which SwiftLint runs as package plugin (configured in `.swiftlint.yml`,
   `strict: true`) and compiler warnings are errors for the Swift app and the facade,
5. that the SBOM `doc/sbom.spdx.json` is up to date (`scripts/create-sbom.sh --check`, see
   *SBOM*).

## SBOM

`doc/sbom.spdx.json` is the Software Bill of Materials of the app in SPDX 2.3 JSON (decision in
`doc/architecture.md`, section *SBOM*). `scripts/create-sbom.sh` creates it from:

- the SPDX files vcpkg writes for every installed port
  (`build/core/vcpkg_installed/arm64-osx-asc/share/<port>/vcpkg.spdx.json`; the list of ports
  comes from `build/core/vcpkg_installed/vcpkg/info/`), so `scripts/build-core.sh` must have
  run before;
- `scripts/sbom-components.json`: the components vcpkg does not know (ASC, the libraries
  bundled in ASC's source code, the game data, the project's own code), vcpkg's helper ports
  that are left out, corrections of vcpkg's data (e.g. libsigc++'s licence) and the texts of
  licences without SPDX identifier (`LicenseRef-...`).

Run `scripts/create-sbom.sh` and commit `doc/sbom.spdx.json` whenever a library, ASC or a
component changes (e.g. after a subtree pull, a change of `vcpkg.json`, or new game data such
as the music); update `scripts/sbom-components.json` first if a component is added or removed
outside vcpkg. The file only changes when the components change: the document namespace is
derived from the content, and the creation time is kept as long as the content is the same.
The script prints the packages with an unclear licence (`NOASSERTION`).

## Licence information

The app shows the licences of all its components in the window *ASC for Mac › Licenses…*
(list of the components on the left, the selected component's licence information on the
right). The window reads `Contents/Resources/Licenses.json`, which `scripts/create-licenses.sh`
creates from the SBOM, `scripts/licenses.json`, vcpkg's licence files and the licence texts in
the repository (details and the licence analysis in `doc/thirdparty.md`, sections *Licence
analysis* and *Licence information*). For every package of the SBOM it contains name, version,
licence, copyright notice, source code location and the full licence texts (texts used by
several packages are stored once), plus general notes such as the GPL notice of the app.

- `scripts/build-core.sh` calls `scripts/create-licenses.sh` after the CMake build and writes
  `build/core/licenses/Licenses.json` (or into the sanitizer or coverage build directory); the
  build phase "Copy licence information" copies it into the app bundle. It is not committed.
- The script fails if a package of the SBOM has no entry in `scripts/licenses.json` (or an
  entry has no package), if a licence text is missing, if a licence is `NOASSERTION`, or if a
  GPL or LGPL package has no source code location. So after changing the SBOM (see above),
  add or update the package's entry in `scripts/licenses.json`: its copyright notice (from the
  licence file or the source file headers) and, if the licence text is not in vcpkg's
  `copyright` file, where it is (`file:...` in the repository, e.g. `thirdparty/licenses/`, or
  `spdx:LicenseRef-...`).
- The `.dmg` (TASK-0014) and the release notes (TASK-0029) can refer to the window and to
  `doc/thirdparty.md`.

## ASC core

| What | Command |
|------|---------|
| Build the ASC core, `asc_mount`, the data archives and `unittester` | `scripts/build-core.sh` |
| Build again from scratch (keeps vcpkg and its libraries) | `scripts/build-core.sh --clean` |
| Run ASC's `unittester` | `scripts/test-core.sh` |
| Build and run with sanitizers (in `build/core-sanitizers`) | `scripts/build-core.sh --sanitizers`, `scripts/test-core.sh --sanitizers` |
| Build with code coverage of the facade (in `build/core-coverage`) | `scripts/build-core.sh --coverage` |

The first build fetches vcpkg and builds all libraries, which takes a while; later builds use
vcpkg's binary cache and only rebuild what changed.

### What the build does

1. `scripts/build-core.sh` fetches vcpkg into `build/vcpkg` at the commit pinned as
   `builtin-baseline` in `vcpkg.json` and bootstraps it.
2. CMake is configured with the preset `macos` (`CMakePresets.json`): vcpkg builds the
   libraries from `vcpkg.json` as static libraries with the triplet `arm64-osx-asc`
   (`cmake/triplets/`: arm64, macOS 27).
3. CMake builds, from `thirdparty/asc/` (`core/CMakeLists.txt`, source lists in
   `core/asc-sources.cmake`):
   - `build/core/core/libasc_core.a`: the ASC core as a static library (C++11, all of ASC's game
     code except its `main` program, including the bundled libraries such as ParaGUI),
   - `build/core/asc_mount`: ASC's tool that packs data files into an archive,
   - `build/core/unittest-run/unittest-data/main.ascdat` (created with `asc_mount` from
     `thirdparty/asc/data/`, file list `data/files.txt`) and `asc2_dlg.zip` (the dialog theme
     from `data/dialog/`),
   - `build/core/unittester`: ASC's test program,
   - `build/core/core/libasc_game.a`: ASC's main program `source/sg.cpp` and its start dialogs
     `source/gamedialog.cpp`, unchanged; a compile definition renames `main()` in `sg.cpp` to
     `asc_game_main()`, which the facade calls,
   - `build/core/game-data/`: the game data for the app bundle, as ASC's autotools build
     installs it: `main.ascdat` and `asc2_dlg.zip` (copied from `unittest-data`) and
     `pbp.ascdat` (created with `asc_mount` from `thirdparty/asc/extra-data/`, file list
     `files_pbp.txt`). `unittest-data` does not contain `pbp.ascdat`, so `unittester` sees only
     the data it was written for.

   The ASC core is compiled with `-fwrapv`: signed integer overflow wraps around, as ASC's
   code expects (e.g. in `source/ai/service.cpp`), so that the optimizer cannot change the
   AI's behavior compared to ASC on other systems (decided in TASK-0016).

4. `scripts/build-core.sh` creates the licence information `build/core/licenses/Licenses.json`
   with `scripts/create-licenses.sh` (see *Licence information*).

The ASC code and data are never downloaded; only vcpkg and its libraries are. All build output
is in `build/`, which is excluded in `.gitignore`.

### unittester

`scripts/test-core.sh` runs `unittester` in `build/core/unittest-run` with the configuration
file `asc2rc` (ASC's `unittester/asc2rc`, with the path to the test maps in
`thirdparty/asc/data/unittests/`). It prints `unittests completed successfully` and exits with
0 if all tests pass. The `libpng warning: bKGD: invalid color` lines come from images in ASC's
data and do not mean a failure.

### Checking the results

```bash
lipo -archs build/core/core/libasc_core.a   # arm64
lipo -archs build/core/unittester            # arm64
vtool -show-build build/core/unittester      # platform MACOS, minos 27.0
```

## Script tests

The scripts in `scripts/` are tested with `scripts/test.sh` (see `AGENTS.md`).
