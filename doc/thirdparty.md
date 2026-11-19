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
| Version      | 2.8.6.5 (CMake project version) |
| Added        | 2026-11-19, with `git subtree add` (full history, no `--squash`) |
| License      | GNU GPL version 2 (`thirdparty/asc/COPYING`) |

The subtree contains the ASC source code (`source/`), its bundled libraries (`source/libs/`),
its game data (`data/`, `extra-data/`) and its build files.

### Bundled libraries in `thirdparty/asc/source/libs/`

These libraries are part of the ASC source code and are covered by the subtree. Their own license
files, where present, are kept next to them:

| Library        | License file |
|----------------|--------------|
| SDL_sound 2.0.4 | `source/libs/SDL_sound-2.0.4/LICENSE.txt` |
| bzlib          | `source/libs/bzlib/LICENSE` |
| ParaGUI (heavily patched), Loki 0.1.6, getopt, rand, revel, sdlmm, triangul | no separate license file; see `source/libs/readme.txt` and the headers of the source files |

### Updating the subtree

Changes inside `thirdparty/asc/` are kept to the minimum and marked (see `doc/architecture.md`).
To merge updates from upstream, with the full history (no `--squash`):

```bash
git subtree pull --prefix=thirdparty/asc https://github.com/ValHaris/asc-hq.git master
```

The working tree must be clean before. `git subtree pull` creates a merge commit. Afterwards,
update the commit, date and version in the table above.

## Libraries provided by vcpkg

These libraries are downloaded and built by vcpkg at build time (see `doc/architecture.md`) and
linked statically into the app. The list follows ASC's `thirdparty/asc/vcpkg.json`. The license
of each library as installed is in vcpkg's `share/<port>/copyright` file.

| vcpkg port   | Library      | License |
|--------------|--------------|---------|
| `sdl2`       | SDL2         | zlib |
| `sdl2-image` | SDL2_image (with libjpeg-turbo) | zlib (libjpeg-turbo: IJG and BSD-3-Clause) |
| `sdl2-mixer` | SDL2_mixer (with mpg123) | zlib (mpg123: LGPL-2.1) |
| `lua`        | Lua          | MIT |
| `libsigcpp`  | libsigc++ 2.10 | LGPL-2.1 |
| `freetype`   | FreeType     | FreeType License (FTL) or GPL-2.0 |
| `boost`      | Boost (regex, filesystem, system) | BSL-1.0 |
| `expat`      | Expat        | MIT |
| `libpng`     | libpng       | libpng License v2 |
| `physfs`     | PhysFS       | zlib |
| `fmt`        | fmt          | MIT |

bzip2 (license: bzip2-1.0.6) is also used by the build (`find_package(BZip2)` in ASC's
`CMakeLists.txt`); vcpkg provides it as a dependency of the libraries above.
