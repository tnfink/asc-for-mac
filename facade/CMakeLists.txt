# The facade between the Swift app and the ASC core (see doc/architecture.md), and the
# combined static library libasc_all.a that the Xcode project links.

# The adapter is the only part of the facade that includes ASC's headers. They cannot be
# compiled with C++20, so the adapter uses C++11 like the ASC core (see src/AscCoreAdapter.h).
add_library(asc_facade_adapter STATIC src/AscCoreAdapter.cpp)
target_link_libraries(asc_facade_adapter PUBLIC asc_game)
set_target_properties(asc_facade_adapter PROPERTIES CXX_STANDARD 11)

# The facade itself uses C++20; its warnings are treated as errors (doc/architecture.md).
add_library(asc_facade STATIC src/AscFacade.cpp)
target_include_directories(asc_facade PUBLIC include)
target_link_libraries(asc_facade PRIVATE asc_facade_adapter)
set_target_properties(asc_facade PROPERTIES CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON CXX_EXTENSIONS OFF)
target_compile_options(asc_facade PRIVATE -Wall -Wextra -Werror)

# Code coverage of the facade (option ASC_COVERAGE, QA measure S7). The profile runtime is
# linked by Xcode, which runs the tests with code coverage enabled (scripts/test-coverage.sh).
if(ASC_COVERAGE)
  foreach(target asc_facade asc_facade_adapter)
    target_compile_options(${target} PRIVATE -fprofile-instr-generate -fcoverage-mapping)
  endforeach()
endif()

# libasc_all.a: the facade, the ASC core and all static libraries they need (from vcpkg), in
# one archive, so the Xcode project links a single library. The list of vcpkg libraries
# follows the link line of unittester.
set(VCPKG_LIB_DIR ${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib)
set(ASC_VCPKG_LIBS
  SDL2_image SDL2_mixer SDL2 sigc-2.0 freetype lua boost_filesystem boost_atomic expat png16
  physfs bz2 jpeg mpg123 vorbisfile vorbis ogg wavpack brotlidec brotlicommon z)
set(ASC_VCPKG_LIB_FILES)
foreach(lib ${ASC_VCPKG_LIBS})
  list(APPEND ASC_VCPKG_LIB_FILES ${VCPKG_LIB_DIR}/lib${lib}.a)
endforeach()

add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/libasc_all.a
  COMMAND xcrun libtool -static -no_warning_for_no_symbols -o ${CMAKE_BINARY_DIR}/libasc_all.a
    $<TARGET_FILE:asc_facade> $<TARGET_FILE:asc_facade_adapter> $<TARGET_FILE:asc_game> $<TARGET_FILE:asc_core> $<TARGET_FILE:asc_sdlsound>
    ${ASC_VCPKG_LIB_FILES}
  DEPENDS asc_facade asc_facade_adapter asc_game asc_core asc_sdlsound ${ASC_VCPKG_LIB_FILES}
  COMMENT "Creating libasc_all.a"
  VERBATIM
)
add_custom_target(asc_all ALL DEPENDS ${CMAKE_BINARY_DIR}/libasc_all.a)
