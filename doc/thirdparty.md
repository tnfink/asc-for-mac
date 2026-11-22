# 3rd Party Artifacts

This document lists the 3rd party artifacts asc-for-mac uses. How they are integrated is decided
in `doc/architecture.md` (sections *Integration of the 3rd party systems* and *Location of the
3rd party artifacts*):

- The **ASC source code and game data** are part of this repository, in `thirdparty/asc/`,
  added with `git subtree` including ASC's full history.
- **ASC's music** is part of this repository, in `thirdparty/asc-music/` (see *ASC music*).
- The **libraries** are provided by vcpkg at build time and are not part of this repository.
- **Licence texts** that are neither in vcpkg's files nor in `thirdparty/asc/` are kept in
  `thirdparty/licenses/` (see *Licence information*).

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
| triangul       | statement in `source/libs/triangul/README` (public domain) |
| ParaGUI (heavily patched), Loki 0.1.6, getopt, rand, revel, sdlmm | no separate license file; see `source/libs/readme.txt` and the headers of the source files |

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
| `source/libs/paragui/src/core/pgapplication.cpp` | On macOS (`#ifdef __APPLE__`), `PG_Application::InitScreen` creates a resizable window of the size of the screen and puts it into macOS full screen (`toggleFullScreen:`) instead of creating an `SDL_WINDOW_FULLSCREEN_DESKTOP` window. | SDL 2 hides the menu bar of `SDL_WINDOW_FULLSCREEN_DESKTOP` windows completely, so About, Licenses… and Quit could not be reached in full screen. In macOS full screen, the menu bar appears at the top edge of the screen; ASC's scaling is unchanged (see `doc/buildAndTest.md`, *Running the game*). | TASK-0027 |

The ASC core is compiled with `-fwrapv` (`core/CMakeLists.txt`), because the code relies on
signed integer overflow wrapping around (e.g. `bestDistance_p*3` in `source/ai/service.cpp`,
found by UndefinedBehaviorSanitizer). This keeps the AI's behavior identical to ASC on other
systems without changing the code (TASK-0016).

**Offered to ASC:** the changes are prepared as pull requests for ASC in
`thirdparty/upstream-patches/` (patches relative to the root of the ASC repository, without the
`asc-for-mac:` markers): the fixes in `source/ai/base.cpp` and `source/astar2.h` in
`asc-0001-fix-undefined-behavior-found-by-sanitizers.patch`, the full screen of
`pgapplication.cpp` in `asc-0002-macos-full-screen-with-reachable-menu-bar.patch`. Delivering
them is TASK-0022.

ASC's main program (`source/sg.cpp`) is used unchanged: `core/CMakeLists.txt` compiles it with
the definition `main=asc_game_main`, so the facade can call it (TASK-0013). The music files
listed in `data/music/Makefile.am` are not part of the ASC repository; they are kept outside
the subtree in `thirdparty/asc-music/` (see *ASC music*).

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

## ASC music (`thirdparty/asc-music/`)

| Field        | Value |
|--------------|-------|
| Origin       | <https://www.asc-hq.org/music/>, the files ASC's `getmusic` script downloads (`thirdparty/asc/getmusic.in`) |
| Author       | Michael Kievernagel (ASC's playlist `data/music1.asctxt`: "Track 1 by Michael Kievernagel") |
| Files        | `frontiers.ogg`, `time_to_strike.ogg`, `machine_wars.ogg` (Ogg Vorbis, 11.7 MB in total) |
| SHA-256      | `eabc9b07d1db07626fa817a30dad23b11aada059e32c08914d2d0cf1d58c7fff` frontiers.ogg, `0334a027b8a45a5df88e1e3e7db9cace2def02396fbcc794d157289e41c9ad05` time_to_strike.ogg, `bd7f330c06090d98e5ba0dac5a691af1804ba383b783b7b2f960bc2e53400a77` machine_wars.ogg |
| Added        | 2026-11-22, downloaded from the origin (TASK-0023) |
| License      | GNU GPL version 2 or later (`thirdparty/asc/COPYING`) |

asc-hq.org states no licence for the music, and the files carry no licence tags. The licence
and the copyright notice ("Copyright: 2002 Michael Kievernagel, License: GPL-2+") are taken from
Debian's package `asc-music`, which distributes the same three tracks (as MP3) in Debian's
`main` section (<https://sources.debian.org/src/asc-music/1.3-7/debian/copyright>); Mageia's
package `asc-music` also declares GPLv2+. The licence is the same as the app's, so the files may
be distributed with it (see *Licence analysis*).

The files are committed to the repository (user decision in TASK-0023), outside the subtree so
that `thirdparty/asc/` stays unchanged. The build phase "Copy ASC game data" in
`ASCforMac.xcodeproj` copies them into `Contents/Resources/music/`, where ASC finds them through
its search paths (playlist entry `music/*.ogg`). They are listed in the SBOM and in the licence
information as the package `asc-music`.

## SBOM

`doc/sbom.spdx.json` lists all components of the app with version, origin and licence (SPDX
2.3, created by `scripts/create-sbom.sh`, see `doc/buildAndTest.md`). The licences of the
components that do not come from vcpkg were determined in TASK-0024 from their licence files
and source file headers and are kept in `scripts/sbom-components.json`. Not listed are vcpkg's
helper ports `vcpkg-cmake`, `vcpkg-cmake-config`, `vcpkg-boost`, `boost-cmake` and
`boost-uninstall`, which contain only CMake files for building, and the bundled libraries that
are not compiled into the app (see above).

**Unclear licences:** the SBOM of TASK-0024 had four packages with `NOASSERTION`; TASK-0025
resolved them (see *Licence analysis* below): the game data is treated as GPL-2.0-or-later and
triangul as public domain (decisions of the user), the project's own code is GPL-2.0-or-later
(decision of the user), and so is the app as a whole.

vcpkg declares no licence for `libsigcpp`; the SBOM uses LGPL-2.1-or-later from the headers of
libsigc++ 2.10.0.

## Licence analysis

Result of TASK-0025: what the licences of the components in the SBOM require when the app is
distributed in binary form (as download of the app bundle), and whether they are compatible
with distributing the components together with ASC under GPL-2.0-or-later. This is the
requirement as stated in the licences, not legal advice.

**Licence of the app:** the project's own code (`app/`, `facade/`, `scripts/`, `core/`, `cmake/`)
is licensed under **GPL-2.0-or-later** (decision of the user; `LICENSE` at the repository root
contains the GPL version 2). The app combines it with ASC (GPL-2.0-or-later) and statically
linked libraries into one program, so **the app as a whole is distributed under
GPL-2.0-or-later**. All other licences below are compatible with that, with the choices noted.

| Licence (SBOM) | Components | Requirements for binary distribution | Compatible with GPL-2.0-or-later |
|----------------|------------|--------------------------------------|----------------------------------|
| GPL-2.0-or-later | own code, ASC, ASC game data, getopt, SDLmm, the app | Licence text with the binary (§1); the complete corresponding source code, offered from the same place as the binary (§3, last paragraph), including the build files; keep the copyright notices and the warranty disclaimer; modified files carry a notice of the change (§2a; ASC's changed files are marked `asc-for-mac:` and listed above) | yes (the same licence) |
| LGPL-2.0-or-later | ParaGUI | Licence text and copyright notice; the source code of the library; because it is linked statically, the object code or source code of the whole app must be available so that users can change the library and relink the app (§6a) | yes (§3 allows using the GPL instead) |
| LGPL-2.1-or-later | libsigc++, mpg123, rand_r | as LGPL-2.0 (§6a of LGPL 2.1); fulfilled by the published source code of the whole app with its build files, plus the sources of the libraries | yes (§3) |
| LGPL-2.1-only OR Artistic-1.0-Perl | TiMidity | asc-for-mac uses the **LGPL 2.1** (the Artistic License 1.0 is not compatible with the GPL); then as LGPL-2.1 | yes, with the LGPL 2.1 |
| FTL OR GPL-2.0-or-later | FreeType | asc-for-mac uses the **GPL-2.0-or-later** (the FTL is not compatible with the GPL version 2); then as GPL-2.0-or-later | yes, with the GPL |
| BSD-3-Clause, BSD-2-Clause | libjpeg-turbo, libogg, libvorbis, wavpack, libspng | Copyright notice, conditions and disclaimer in the documentation of the binary | yes |
| IJG | libjpeg-turbo | The documentation must state "this software is based in part on the work of the Independent JPEG Group" | yes |
| MIT | brotli, expat, fmt, Lua | Copyright notice and licence text in all copies (Lua asks for credit in the documentation) | yes |
| CC0-1.0 | expat (parts) | none | yes |
| Zlib | SDL2, SDL2_image, SDL2_mixer, PhysFS, zlib, SDL_sound | none for binaries (altered versions must be marked as such) | yes |
| libpng-2.0 | libpng, libspng (parts) | none for binaries | yes |
| bzip2-1.0.6 | bzip2 | none for binaries (an acknowledgement in the documentation is appreciated) | yes |
| BSL-1.0 | Boost (44 ports) | none for binaries (the notices are only required in source code) | yes |
| LicenseRef-Loki | Loki | Copyright and permission notice in the supporting documentation | yes |
| LicenseRef-PublicDomain-libmodplug, LicenseRef-PublicDomain-triangul | libmodplug, triangul | none | yes |

macOS's own frameworks and the Swift runtime, which the app uses but does not contain, are
system libraries in the sense of GPL-2.0 §3 and need no source code offer.

**How asc-for-mac fulfils the requirements:**

- **Licence texts, copyright notices, acknowledgements:** the app contains the licence
  information (`Licenses.json`, window *ASC for Mac › Licenses…*, see *Licence information*
  below) with every package's copyright notice and full licence texts, the GPL notice of the
  app and the IJG sentence.
- **Source code (GPL §3, LGPL §6a):** the repository at the release's tag contains the complete
  source code of the own code and of ASC with its bundled libraries, and the build files that
  link the libraries, so users can rebuild and relink the app with a changed library. The
  libraries vcpkg downloads are not in the repository; therefore each release must also offer
  their sources from the same place (decision of the user, step and criterion in TASK-0014).
  The licence information gives the upstream location of every component's source code.

**Decisions of the user** (TASK-0025):

- **Own code:** GPL-2.0-or-later.
- **ASC game data:** treated as **GPL-2.0-or-later**. The data has no licence statement of its
  own, but ASC's packaging declares the whole package as GPL (`asc.appdata.xml.in`:
  `project_license` GPL-2.0-or-later; `asc.spec.in`, `asc.suse.spec.in`: GPL), and Debian ships
  ASC with its data in *main* under `Files: *` / `License: GPL-2+`
  (<https://sources.debian.org/src/asc/2.6.1.0-9/debian/copyright/>).
- **triangul:** **public domain**. Its README (`source/libs/triangul/README`) says: "This code
  is in the public domain. Specifically, we give to the public domain all rights for future
  licensing of the source code, all resale rights, and all publishing rights." (Atul Narkhede,
  UNC-CH); Debian lists it the same way. TASK-0024 had overlooked this statement.
- **Library sources for releases:** added to TASK-0014.

**Further findings:** ParaGUI's `src/ystring/ystring.cpp` (GPL) and ASC's
`source/sdl/sdlstretch.cpp` (LGPL-2.0-or-later) are not compiled into the app
(`core/CMakeLists.txt`, `core/asc-sources.cmake`); both would be compatible anyway.

## Licence information

The licence information shown in the app (`Licenses.json` in `Contents/Resources/`) is created
from the SBOM by `scripts/create-licenses.sh` (called by `scripts/build-core.sh`, see
`doc/buildAndTest.md`). Its inputs:

- `doc/sbom.spdx.json`: the packages with name, version, licence and origin.
- `scripts/licenses.json`: for every package its copyright notice and where its licence texts
  are, the general notes (GPL notice, source code, IJG acknowledgement), the source code
  location of the own code and notes on licence choices (FreeType, TiMidity) and on ASC's
  changes.
- vcpkg's licence files `build/core/vcpkg_installed/arm64-osx-asc/share/<port>/copyright`.
- Licence texts in the repository: `LICENSE`, `thirdparty/asc/COPYING`, the licence files of
  ASC's bundled libraries, and in `thirdparty/licenses/` the texts that are neither in vcpkg's
  files nor in `thirdparty/asc/`:
  - `LGPL-2.0.txt`: the GNU Library General Public License version 2 (for ParaGUI), from
    <https://www.gnu.org/licenses/old-licenses/lgpl-2.0.txt>.
  - `libjpeg-turbo-README.ijg`: the IJG licence of libjpeg-turbo 3.2.0, to which vcpkg's
    copyright file only refers, from
    <https://github.com/libjpeg-turbo/libjpeg-turbo/blob/3.2.0/README.ijg>.

When a component is added or changed (new vcpkg port, update of the ASC subtree, the music of
TASK-0023), update the SBOM first; `scripts/create-licenses.sh` then fails until
`scripts/licenses.json` has an entry for every package of the SBOM (copyright notice and
licence texts). Check the licence against the table above and record new licences there.

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
