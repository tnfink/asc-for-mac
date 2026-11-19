# vcpkg triplet for asc-for-mac: static libraries for Apple Silicon (arm64), minimum macOS 27.
# See doc/architecture.md (sections "Programming language and runtime" and
# "Integration of the 3rd party systems").
set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES arm64)
set(VCPKG_OSX_DEPLOYMENT_TARGET 27.0)
