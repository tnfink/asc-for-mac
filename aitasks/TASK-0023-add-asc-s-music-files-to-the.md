# TASK-0023: Add ASC's music files to the distribution

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0023 |
| **Short description** | Add ASC's music files to the distribution |
| **Status**        | done <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0013, TASK-0024, TASK-0025 |

## Motivation

The app built in TASK-0013 plays without music: ASC's music files are not part of the ASC
repository (see `doc/thirdparty.md` and the section *Running the game* in
`doc/buildAndTest.md`). Players of the Mac version should hear the same music as players of ASC
on other systems, so ASC's music files are to be added to the distribution.

## Task description

Add ASC's music files to the distribution of the app.

Known facts from the ASC sources (`thirdparty/asc/`):

- `data/music/Makefile.am` installs the three files `frontiers.ogg`, `time_to_strike.ogg` and
  `machine_wars.ogg`; `configure.ac` checks for them in `data/music/`.
- `getmusic.in` downloads them from `http://www.asc-hq.org/music/` (`frontiers.ogg`,
  `time_to_strike.ogg`, `machine_wars.ogg`).
- The playlist `data/music1.asctxt` ("Track 1 by Michael Kievernagel") plays
  `music/*.mp3 music/*.mid music/*.ogg`, relative to ASC's search paths.
- The core is built with `SOUND_SUPPORTS_OGG` and links SDL2_mixer (`core/CMakeLists.txt`).
- `source/music.cpp` resolves the playlist's tracks with `tfindfile`, i.e. through ASC's search
  paths. Music is switched on and off with the check box "Enable Music" in ASC's dialog
  "Sound Settings" (`source/dialogs/soundsettings.cpp`).

To do:

1. Find out where the music files can be obtained today and under which license; record the
   source and the license in `doc/thirdparty.md`. If the license does not allow distributing
   the files with the app, stop and ask the user.
2. Decide with the user how the files get into the build, e.g. committed to the repository
   (they are about the size of normal audio files) or downloaded by a script in `scripts/`
   with a checksum check. Use only the tools from `doc/developerInfrastructure.md`. Files
   placed in `thirdparty/asc/` (e.g. `data/music/`, where ASC's `configure.ac` expects them)
   are a change of the subtree and must be listed in `doc/thirdparty.md`.
3. Copy the music files into the app bundle so that ASC finds them via its search paths
   (`Contents/Resources/music/`, matching `music/*.ogg` in the playlist), e.g. via the build
   phase "Copy ASC game data" in `ASCforMac.xcodeproj` (including its input and output paths).
4. Add the music as a component to the SBOM and the licence information, as described in
   `doc/buildAndTest.md` ("SBOM", "Licence information") and `doc/thirdparty.md`: an entry in
   `scripts/sbom-components.json`, `doc/sbom.spdx.json` regenerated with
   `scripts/create-sbom.sh`, and an entry with copyright notice and licence text in
   `scripts/licenses.json`, so that the app's Licenses window lists the music.
5. Update the documentation that says the app has no music (`doc/thirdparty.md`,
   `doc/buildAndTest.md`).

Out of scope: new or changed music, changes to ASC's music code.

## Acceptance criteria

- [x] The source and license of the music files are recorded in `doc/thirdparty.md`, and the
      license allows distributing them with the app.
- [x] After a build, the app bundle contains `frontiers.ogg`, `time_to_strike.ogg` and
      `machine_wars.ogg` in `Contents/Resources/music/` (checked with `ls`).
- [x] When the game runs, music is played (checked by the user), and ASC's log
      (`~/Library/Application Support/asc-for-mac/log.txt`) shows no errors about the music.
- [x] Unchecking "Enable Music" in ASC's dialog "Sound Settings" stops the music (checked by
      the user).
- [x] `doc/sbom.spdx.json` contains a package for the music files with their licence;
      `scripts/create-sbom.sh --check` and `scripts/create-licenses.sh` pass, and the app's
      Licenses window lists the music (checked by inspection or the user).
- [x] `doc/thirdparty.md` and `doc/buildAndTest.md` no longer say that the app has no music.
- [x] If a download script is used, it checks the files' checksums and is tested in
      `scripts/test.sh`.

## History

<!--
  Log of all status changes, oldest first. Add a row for every change of the Status field.
  Timestamp format: ISO 8601 with time zone offset, e.g. 2026-11-11T14:30+0100
  (get it with: date +%Y-%m-%dT%H:%M%z).
  Comment: optional, but required for "waiting" and "aborted" (state the reason).
-->

| Timestamp                | Status | Comment       |
|--------------------------|--------|---------------|
| 2026-11-20T11:22+0100 | open   | Task created  |
| 2026-11-22T15:12+0100 | in-work | Implementation started |
| 2026-11-22T20:19+0100 | waiting | Waiting for the user to check music, Enable Music and the Licenses window |
| 2026-11-22T20:22+0100 | done | All acceptance criteria and the Definition of Done are fulfilled |
