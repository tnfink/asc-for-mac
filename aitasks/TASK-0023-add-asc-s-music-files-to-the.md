# TASK-0023: Add ASC's music files to the distribution

| Field             | Value                                                         |
|-------------------|---------------------------------------------------------------|
| **ID**            | TASK-0023 |
| **Short description** | Add ASC's music files to the distribution |
| **Status**        | open <!-- One of: open, in-work, waiting, done, aborted -->   |
| **External link** | none |
| **Dependencies**  | TASK-0013 |

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

To do:

1. Find out where the music files can be obtained today and under which license; record the
   source and the license in `doc/thirdparty.md`. If the license does not allow distributing
   the files with the app, stop and ask the user.
2. Decide with the user how the files get into the build, e.g. committed to the repository
   (they are about the size of normal audio files) or downloaded by a script in `scripts/`
   with a checksum check. Use only the tools from `doc/developerInfrastructure.md`.
3. Copy the music files into the app bundle so that ASC finds them via its search paths
   (`Contents/Resources/music/`, matching `music/*.ogg` in the playlist), e.g. via the build
   phase "Copy ASC game data" in `ASCforMac.xcodeproj`.
4. Update the documentation that says the app has no music (`doc/thirdparty.md`,
   `doc/buildAndTest.md`).

Out of scope: new or changed music, changes to ASC's music code.

## Acceptance criteria

- [ ] The source and license of the music files are recorded in `doc/thirdparty.md`, and the
      license allows distributing them with the app.
- [ ] After a build, the app bundle contains `frontiers.ogg`, `time_to_strike.ogg` and
      `machine_wars.ogg` in `Contents/Resources/music/` (checked with `ls`).
- [ ] When the game runs, music is played (checked by the user), and ASC's log
      (`~/Library/Application Support/asc-for-mac/log.txt`) shows no errors about the music.
- [ ] Muting music in ASC's options stops the music (checked by the user).
- [ ] If a download script is used, it is tested in `scripts/test.sh`.

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
