# Build of the ASC core, ASC's tool asc_mount, the data archives and ASC's unittester.
#
# The source lists follow thirdparty/asc/CMakeLists.txt (target "asc") and, for unittester
# and asc_mount, the autotools build (thirdparty/asc/source/unix/asc/Makefile.am,
# source/unittests/Makefile.am, source/tools/linux/Makefile.am), which ASC's CMake build
# does not cover. thirdparty/asc/ itself is not changed (see doc/thirdparty.md).

set(ASC_DIR ${PROJECT_SOURCE_DIR}/thirdparty/asc)
set(ASC_SRC_DIR ${ASC_DIR}/source)

# The ASC core keeps the C++ standard of the original (doc/architecture.md).
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# --- Libraries from vcpkg ---------------------------------------------------------

find_package(SDL2 CONFIG REQUIRED)
find_package(SDL2_image CONFIG REQUIRED)
find_package(SDL2_mixer CONFIG REQUIRED)
find_package(Lua REQUIRED)
find_package(Freetype REQUIRED)
find_package(Boost CONFIG REQUIRED COMPONENTS regex filesystem system)
find_package(EXPAT REQUIRED)
find_package(BZip2 REQUIRED)
find_package(PNG REQUIRED)
find_package(PhysFS CONFIG REQUIRED)
find_package(PkgConfig QUIET)
find_library(SIGC_LIBRARY NAMES sigc-2.0 REQUIRED)
find_path(SIGC_CONFIG_INCLUDE_DIR sigc++config.h PATH_SUFFIXES lib/sigc++-2.0/include sigc++-2.0/include REQUIRED)
find_path(SIGC_INCLUDE_DIR sigc++/sigc++.h PATH_SUFFIXES sigc++-2.0 REQUIRED)

if(TARGET EXPAT::EXPAT)
  set(ASC_EXPAT_TARGET EXPAT::EXPAT)
else()
  set(ASC_EXPAT_TARGET expat::expat)
endif()
if(TARGET PhysFS::PhysFS-static)
  set(ASC_PHYSFS_TARGET PhysFS::PhysFS-static)
else()
  set(ASC_PHYSFS_TARGET PhysFS::PhysFS)
endif()

# --- Generated config.h (as in thirdparty/asc/CMakeLists.txt) ------------------------

set(PROJECT_NAME ASC)
set(PROJECT_VERSION 2.8.6.5)
set(GAME_DATADIR "${CMAKE_INSTALL_PREFIX}/share/games/ASC")
configure_file(${ASC_DIR}/config.h.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/config.h @ONLY)
set(PROJECT_NAME asc-for-mac)

# --- Common settings for all ASC targets -------------------------------------------

add_library(asc_settings INTERFACE)
target_include_directories(asc_settings INTERFACE
  ${CMAKE_CURRENT_BINARY_DIR}
  ${ASC_SRC_DIR}
  ${ASC_SRC_DIR}/libs/paragui/include
  ${ASC_SRC_DIR}/libs/loki-0.1.6/include
  ${ASC_SRC_DIR}/libs/getopt
  ${ASC_SRC_DIR}/libs/SDL_sound-2.0.4/src
  ${SIGC_INCLUDE_DIR}
  ${SIGC_CONFIG_INCLUDE_DIR}
  ${LUA_INCLUDE_DIR}
)
# Defines that ASC's autotools build gets from configure (thirdparty/asc/configure.ac), with
# the values for macOS. On macOS (LP64), size_t is not the same type as int.
target_compile_definitions(asc_settings INTERFACE
  _UNIX_ _SDL_
  HAVE_DIRENT_H=1 HAVE_EXCEPTION=1 HAVE_LIMITS=1 HAVE_SYS_TIME_H=1 TIME_WITH_SYS_TIME=1
  HAVE_SELECT=1 SIZE_T_not_identical_to_INT=1)
# The original code is compiled as it is; its warnings are not fixed in this project.
target_compile_options(asc_settings INTERFACE -w
  # Loki 0.1.6 (source/libs/loki-0.1.6) uses "template" without an argument list, which
  # Clang 21 rejects by default.
  $<$<COMPILE_LANGUAGE:CXX>:-Wno-missing-template-arg-list-after-template-kw>)
target_link_libraries(asc_settings INTERFACE
  SDL2::SDL2-static
  SDL2_image::SDL2_image-static
  SDL2_mixer::SDL2_mixer-static
  ${SIGC_LIBRARY}
  Freetype::Freetype
  ${LUA_LIBRARIES}
  Boost::regex
  Boost::filesystem
  Boost::system
  ${ASC_EXPAT_TARGET}
  PNG::PNG
  ${ASC_PHYSFS_TARGET}
  BZip2::BZip2
)

# --- Internal SDL_sound (as in thirdparty/asc/CMakeLists.txt) ------------------------

file(GLOB SDL_SOUND_INT_SRCS CONFIGURE_DEPENDS
  ${ASC_SRC_DIR}/libs/SDL_sound-2.0.4/src/*.c
  ${ASC_SRC_DIR}/libs/SDL_sound-2.0.4/src/timidity/*.c
  ${ASC_SRC_DIR}/libs/SDL_sound-2.0.4/src/libmodplug/*.c
)
list(REMOVE_ITEM SDL_SOUND_INT_SRCS ${ASC_SRC_DIR}/libs/SDL_sound-2.0.4/src/SDL_sound_skeleton.c)
add_library(asc_sdlsound STATIC ${SDL_SOUND_INT_SRCS})
target_compile_definitions(asc_sdlsound PRIVATE SOUND_SUPPORTS_OGG SOUND_SUPPORTS_WAV SOUND_SUPPORTS_MP3)
target_include_directories(asc_sdlsound PUBLIC ${ASC_SRC_DIR}/libs/SDL_sound-2.0.4
  PRIVATE ${ASC_SRC_DIR}/libs/SDL_sound-2.0.4/src)
target_compile_options(asc_sdlsound PRIVATE -w)
target_link_libraries(asc_sdlsound PUBLIC SDL2::SDL2-static)

# --- ASC core library ----------------------------------------------------------------

file(GLOB PARAGUI_SOURCES CONFIGURE_DEPENDS
  ${ASC_SRC_DIR}/libs/paragui/src/core/*.cpp
  ${ASC_SRC_DIR}/libs/paragui/src/draw/*.cpp
  ${ASC_SRC_DIR}/libs/paragui/src/font/*.cpp
  ${ASC_SRC_DIR}/libs/paragui/src/themes/*.cpp
  ${ASC_SRC_DIR}/libs/paragui/src/widgets/*.cpp
)

include(${CMAKE_CURRENT_SOURCE_DIR}/asc-sources.cmake)

add_library(asc_core STATIC
  ${COMMON_GAME_SOURCES}
  ${ASC_EXTRA_SOURCES}
  ${PARAGUI_SOURCES}
  ${COMMON_SOURCES}
  ${GAME_ONLY_SOURCES}
)
target_compile_definitions(asc_core PUBLIC sgmain SOUND_SUPPORTS_MP3 SOUND_SUPPORTS_OGG SOUND_SUPPORTS_WAV)
target_link_libraries(asc_core PUBLIC asc_settings asc_sdlsound)

# --- unittester (from the autotools build) -------------------------------------------

file(GLOB UNITTEST_SOURCES CONFIGURE_DEPENDS ${ASC_SRC_DIR}/unittests/*.cpp)
add_executable(unittester ${UNITTEST_SOURCES})
target_link_libraries(unittester PRIVATE asc_core)
target_link_options(unittester PRIVATE
  "LINKER:-framework,Cocoa" "LINKER:-framework,IOKit" "LINKER:-framework,CoreAudio"
  "LINKER:-framework,AudioToolbox" "LINKER:-framework,ForceFeedback" "LINKER:-framework,Carbon"
  "LINKER:-framework,CoreVideo" "LINKER:-framework,GameController" "LINKER:-framework,Metal"
  "LINKER:-framework,QuartzCore" "LINKER:-framework,CoreHaptics")
set_target_properties(unittester PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# --- asc_mount and the data archives -------------------------------------------------

add_executable(asc_mount
  ${ASC_SRC_DIR}/tools/mount.cpp
  ${ASC_SRC_DIR}/basestrm.cpp
  ${ASC_SRC_DIR}/simplestream.cpp
  ${ASC_SRC_DIR}/misc.cpp
  ${ASC_SRC_DIR}/ascstring.cpp
  ${ASC_SRC_DIR}/strtmesg.cpp
  ${ASC_SRC_DIR}/stringtokenizer.cpp
  ${ASC_SRC_DIR}/tools/lib/errorout.cpp
)
target_compile_definitions(asc_mount PRIVATE converter)
target_link_libraries(asc_mount PRIVATE asc_settings)
set_target_properties(asc_mount PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

set(UNITTEST_RUN_DIR ${CMAKE_BINARY_DIR}/unittest-run)
set(UNITTEST_DATA_DIR ${UNITTEST_RUN_DIR}/unittest-data)
file(GLOB_RECURSE ASC_DATA_FILES CONFIGURE_DEPENDS ${ASC_DIR}/data/*)
list(FILTER ASC_DATA_FILES EXCLUDE REGEX "/data/(dialog|unittests)/")
file(GLOB ASC_DIALOG_FILES CONFIGURE_DEPENDS
  ${ASC_DIR}/data/dialog/asc2_dlg.theme
  ${ASC_DIR}/data/dialog/asc/*.png
  ${ASC_DIR}/data/dialog/asc/*.bmp
  ${ASC_DIR}/data/dialog/asc/*.ttf
)

# main.ascdat: created from data/ with asc_mount and the file list data/files.txt
# (as in thirdparty/asc/data/Makefile.am).
add_custom_command(
  OUTPUT ${UNITTEST_DATA_DIR}/main.ascdat
  COMMAND ${CMAKE_COMMAND} -E make_directory ${UNITTEST_DATA_DIR}
  COMMAND $<TARGET_FILE:asc_mount> @files.txt ${UNITTEST_DATA_DIR}/main.ascdat
  WORKING_DIRECTORY ${ASC_DIR}/data
  DEPENDS asc_mount ${ASC_DATA_FILES}
  COMMENT "Creating main.ascdat with asc_mount"
  VERBATIM
)

# asc2_dlg.zip: the dialog theme (as in thirdparty/asc/data/dialog/Makefile.am), created
# with CMake itself instead of the zip tool.
set(ASC_DIALOG_RELATIVE asc2_dlg.theme)
foreach(f ${ASC_DIALOG_FILES})
  file(RELATIVE_PATH rel ${ASC_DIR}/data/dialog ${f})
  if(NOT rel STREQUAL "asc2_dlg.theme")
    list(APPEND ASC_DIALOG_RELATIVE ${rel})
  endif()
endforeach()
add_custom_command(
  OUTPUT ${UNITTEST_DATA_DIR}/asc2_dlg.zip
  COMMAND ${CMAKE_COMMAND} -E make_directory ${UNITTEST_DATA_DIR}
  COMMAND ${CMAKE_COMMAND} -E tar cf ${UNITTEST_DATA_DIR}/asc2_dlg.zip --format=zip ${ASC_DIALOG_RELATIVE}
  WORKING_DIRECTORY ${ASC_DIR}/data/dialog
  DEPENDS ${ASC_DIALOG_FILES}
  COMMENT "Creating asc2_dlg.zip"
  VERBATIM
)

# Configuration for unittester: ASC's unittester/asc2rc, with the search path for the
# test data pointing to thirdparty/asc/data/unittests/.
file(READ ${ASC_DIR}/unittester/asc2rc ASC_UNITTEST_RC)
string(REPLACE "SearchPath1 = ../data/unittests/" "SearchPath1 = ${ASC_DIR}/data/unittests/"
  ASC_UNITTEST_RC "${ASC_UNITTEST_RC}")
file(WRITE ${UNITTEST_RUN_DIR}/asc2rc "${ASC_UNITTEST_RC}")

add_custom_target(unittest_data ALL
  DEPENDS ${UNITTEST_DATA_DIR}/main.ascdat ${UNITTEST_DATA_DIR}/asc2_dlg.zip)
