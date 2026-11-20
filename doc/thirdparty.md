# 3rd Party Artifacts

This document lists the 3rd party artifacts asc-for-mac uses. How they are integrated is decided
in `doc/architecture.md` (sections *Integration of the 3rd party systems* and *Location of the
3rd party artifacts*):

- The **ASC source code and game data** are part of this repository, in `thirdparty/asc/`,
  added with `git subtree` including ASC's full history.
- The **libraries** are provided by vcpkg at build time and are not part of this repository.

## ASC (git subtree in `thirdparty/asc/`)

| Field        | Value |
|--------------|-------|
| Origin       | <https://github.com/ValHaris/asc-hq> (website: <https://www.asc-hq.org>) |
| Branch       | `master` |
| Commit       | `074a6ef90fcec61bb72cf0102c1928ca6151f38d` (2026-11-06, "Fix resource mismatch when undoing resource consumption") |
| Version      | 2.6.99.0 (see *Version number* below) |
| Added        | 2026-11-19, with `git subtree add` (full history, no `--squash`) |
| License      | GNU GPL version 2 (`thirdparty/asc/COPYING`) |

The subtree contains the ASC source code (`source/`), its bundled libraries (`source/libs/`),
its game data (`data/`, `extra-data/`) and its build files.

### Version number

ASC carries two different version numbers:

- **2.6.99.0** is the version of the game itself: it is set in the code
  (`source/strtmesg.cpp`, `asc_release`) and in the autotools build (`configure.ac`). The game
  writes it into save games and PBEM files and compares it with the versions of the other
  players. asc-for-mac uses this version (app version, `vcpkg.json`, release versions such as
  `2.6.99.0-mac1`, see `doc/architecture.md`).
- **2.8.6.5** appears only as project version in ASC's newer `CMakeLists.txt` and is not used
  by the game. According to ASC's README, the branch `master` is the ASC 2.6 line; ASC 2.8 is
  developed on the branch `newattack`.

When the subtree is updated, take the version from `source/strtmesg.cpp`.

### Bundled libraries in `thirdparty/asc/source/libs/`

These libraries are part of the ASC source code and are covered by the subtree. Their own license
files, where present, are kept next to them:

| Library        | License file |
|----------------|--------------|
| SDL_sound 2.0.4 | `source/libs/SDL_sound-2.0.4/LICENSE.txt` |
| bzlib          | `source/libs/bzlib/LICENSE` |
| ParaGUI (heavily patched), Loki 0.1.6, getopt, rand, revel, sdlmm, triangul | no separate license file; see `source/libs/readme.txt` and the headers of the source files |

Compiled into the app (and listed in the SBOM, see below) are SDL_sound 2.0.4 (including its
Timidity and libmodplug parts), ParaGUI, Loki, getopt, rand (included by `source/gamemap.cpp`),
sdlmm and triangul. `bzlib` (ASC uses vcpkg's bzip2), `revel` (only used by the video
recorder, which is not built) and the old `sdl_sound` are not part of the app.

### Changes inside `thirdparty/asc/`

Each change is marked in the code with `asc-for-mac:` and listed here
(`git diff ce591bce9 -- thirdparty/asc` shows all of them).

| File | Change | Reason | Task |
|------|--------|--------|------|
| `source/loadbi3.cpp` | The in-memory table `TLIBFiles` is excluded from `#pragma pack(1)` (`#pragma pack(push, 8)` … `pop`). | The arm64 linker rejects the misaligned pointers the packing creates ("pointer not aligned"). The table is never read from or written to a file, so the change does not affect file formats. | TASK-0012 |
| `source/ai/base.cpp` | `AI::checkKeys()` uses the pointer `pgApp` instead of `&getPGApplication()`. | `getPGApplication()` dereferences a null pointer when there is no ParaGUI application (e.g. in `unittester`); the compiler may then remove the null check, so an AI turn without UI could crash. Found by UndefinedBehaviorSanitizer. | TASK-0016 |
| `source/astar2.h` | `hash_MapCoordinate3D` shifts as `unsigned` and converts the result back to `int`. | Left-shifting the negative coordinate -1 is undefined behavior. Found by UndefinedBehaviorSanitizer; the hash values stay the same. | TASK-0016 |

The ASC core is compiled with `-fwrapv` (`core/CMakeLists.txt`), because the code relies on
signed integer overflow wrapping around (e.g. `bestDistance_p*3` in `source/ai/service.cpp`,
found by UndefinedBehaviorSanitizer). This keeps the AI's behavior identical to ASC on other
systems without changing the code (TASK-0016).

**Offered to ASC:** the fixes in `source/ai/base.cpp` and `source/astar2.h` are prepared as a pull
request for ASC in `thirdparty/upstream-patches/` (patches relative to the root of the ASC
repository, without the `asc-for-mac:` markers); delivering it is TASK-0022.

ASC's main program (`source/sg.cpp`) is used unchanged: `core/CMakeLists.txt` compiles it with
the definition `main=asc_game_main`, so the facade can call it (TASK-0013). The music files
listed in `data/music/Makefile.am` are not part of the ASC repository; the app has no music.

Settings that ASC's autotools build gets from `configure` (e.g. `HAVE_DIRENT_H`,
`SIZE_T_not_identical_to_INT`) and compiler options for the original code are set in
`core/CMakeLists.txt`, not in `thirdparty/asc/`.

### Updating the subtree

Changes inside `thirdparty/asc/` are kept to the minimum and marked (see `doc/architecture.md`).
To merge updates from upstream, with the full history (no `--squash`):

```bash
git subtree pull --prefix=thirdparty/asc https://github.com/ValHaris/asc-hq.git master
```

The working tree must be clean before. `git subtree pull` creates a merge commit. Afterwards,
update the commit, date and version in the table above (the version from
`source/strtmesg.cpp`, see *Version number*), check that the changes listed above
are still in place, and update the source lists in `core/asc-sources.cmake` (copied from
`thirdparty/asc/CMakeLists.txt`).

## SBOM

`doc/sbom.spdx.json` lists all components of the app with version, origin and licence (SPDX
2.3, created by `scripts/create-sbom.sh`, see `doc/buildAndTest.md`). The licences of the
components that do not come from vcpkg were determined in TASK-0024 from their licence files
and source file headers and are kept in `scripts/sbom-components.json`. Not listed are vcpkg's
helper ports `vcpkg-cmake`, `vcpkg-cmake-config`, `vcpkg-boost`, `boost-cmake` and
`boost-uninstall`, which contain only CMake files for building, and the bundled libraries that
are not compiled into the app (see above).

**Unclear licences** (`NOASSERTION` in the SBOM, reported to the user in TASK-0024):

- **ASC game data** (`main.ascdat`, `asc2_dlg.zip`, `pbp.ascdat`): the data in
  `thirdparty/asc/data/` and `extra-data/` has no licence statement of its own; whether ASC's
  GPL covers it is unclear.
- **triangul** (`source/libs/triangul/`): the files contain no licence statement; the original
  source (reality.sgi.com) no longer exists.
- **The project's own code** (`app/`, `facade/`): its licence is decided in TASK-0025.

vcpkg declares no licence for `libsigcpp`; the SBOM uses LGPL-2.1-or-later from the headers of
libsigc++ 2.10.0.

## Libraries provided by vcpkg

These libraries are downloaded and built by vcpkg at build time (see `doc/architecture.md`) and
linked statically into the app. They are listed in `vcpkg.json` at the repository root, which
follows ASC's `thirdparty/asc/vcpkg.json`. The versions are pinned by the `builtin-baseline` in
`vcpkg.json`: vcpkg release **2026.10.16** (commit `9eec002df1cd109f8f104cd966a763daf9751489`).
The license of each library as installed is in vcpkg's `share/<port>/copyright` file.

| vcpkg port   | Library      | Version | License |
|--------------|--------------|---------|---------|
| `sdl2`       | SDL2         | 2.32.10 | zlib |
| `sdl2-image` | SDL2_image (with libjpeg-turbo) | 2.8.12 | zlib (libjpeg-turbo: IJG and BSD-3-Clause) |
| `sdl2-mixer` | SDL2_mixer (with mpg123) | 2.8.2 | zlib (mpg123: LGPL-2.1) |
| `lua`        | Lua          | 5.5.1 | MIT |
| `libsigcpp`  | libsigc++    | 2.10 (override `2.10-3`, as in ASC's `vcpkg.json`; the baseline has 3.x) | LGPL-2.1 |
| `freetype`   | FreeType     | 2.14.3 | FreeType License (FTL) or GPL-2.0 |
| `boost-*`    | Boost (algorithm, filesystem, heap, regex, smart-ptr, system, unordered) | 1.92.0 | BSL-1.0 |
| `expat`      | Expat        | 2.9.0 | MIT |
| `libpng`     | libpng       | 1.6.59 | libpng License v2 |
| `physfs`     | PhysFS       | 3.2.0 | zlib |
| `fmt`        | fmt          | 12.2.0 | MIT |
| `bzip2`      | bzip2        | 1.0.8 | bzip2-1.0.6 |

**Lua:** ASC's Linux build uses Lua 5.1; asc-for-mac uses the Lua version vcpkg provides
(5.5.1), as ASC's own Windows build does (its vcpkg baseline has Lua 5.5.0). The SWIG wrappers
in `thirdparty/asc/source/lua/` support both.

**Boost:** ASC's `vcpkg.json` uses the complete `boost` package; asc-for-mac lists only the
Boost libraries ASC includes, which keeps the build shorter.
