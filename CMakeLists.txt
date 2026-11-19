# CMake build of asc-for-mac (see doc/architecture.md and doc/buildAndTest.md).
#
# Builds the ASC core from thirdparty/asc/ with the libraries provided by vcpkg (vcpkg.json).
# Configure and build with scripts/build-core.sh, which uses the preset "macos" from
# CMakePresets.json.

cmake_minimum_required(VERSION 3.25)

project(asc-for-mac VERSION 2.6.99.0 LANGUAGES C CXX)

if(NOT APPLE)
  message(FATAL_ERROR "asc-for-mac is built for macOS only (see doc/architecture.md)")
endif()

# QA measure S2 (doc/qameasures.md): build everything of this project with AddressSanitizer
# and UndefinedBehaviorSanitizer (preset "macos-sanitizers"). Every finding aborts the program.
# The libraries from vcpkg are not instrumented.
option(ASC_SANITIZERS "Build with AddressSanitizer and UndefinedBehaviorSanitizer" OFF)
# For diagnosis only: report UndefinedBehaviorSanitizer findings without aborting, to see all
# findings of a run at once (e.g. cmake --preset macos-sanitizers -DASC_SANITIZER_RECOVER=ON).
option(ASC_SANITIZER_RECOVER "Do not abort on UndefinedBehaviorSanitizer findings" OFF)
if(ASC_SANITIZERS)
  if(ASC_SANITIZER_RECOVER)
    set(ASC_SANITIZER_RECOVER_FLAG -fsanitize-recover=undefined)
  else()
    set(ASC_SANITIZER_RECOVER_FLAG -fno-sanitize-recover=all)
  endif()
  add_compile_options(-fsanitize=address,undefined ${ASC_SANITIZER_RECOVER_FLAG}
    -fno-omit-frame-pointer -O1 -g)
  add_link_options(-fsanitize=address,undefined)
endif()

# QA measure S7 (doc/qameasures.md): compile the facade with Clang's coverage instrumentation
# (preset "macos-coverage"), so that Xcode's coverage report of the Swift tests includes it.
# The ASC core is not instrumented. Used in facade/CMakeLists.txt.
option(ASC_COVERAGE "Compile the facade with code coverage instrumentation" OFF)

add_subdirectory(core)
add_subdirectory(facade)
