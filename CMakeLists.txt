# CMake build of asc-for-mac (see doc/architecture.md and doc/buildAndTest.md).
#
# Builds the ASC core from thirdparty/asc/ with the libraries provided by vcpkg (vcpkg.json).
# Configure and build with scripts/build-core.sh, which uses the preset "macos" from
# CMakePresets.json.

cmake_minimum_required(VERSION 3.25)

project(asc-for-mac VERSION 2.8.6.5 LANGUAGES C CXX)

if(NOT APPLE)
  message(FATAL_ERROR "asc-for-mac is built for macOS only (see doc/architecture.md)")
endif()

add_subdirectory(core)
