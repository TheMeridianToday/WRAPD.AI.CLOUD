cmake_minimum_required(VERSION 3.14)
project(scribe_ai LANGUAGES CXX)

set(BINARY_NAME "scribe_ai")
set(APPLICATION_ID "com.scribeai.scribe_ai")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# ── Flutter CMake Toolchain ────────────────────────────────
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# ── Application Source ─────────────────────────────────────
add_subdirectory("runner")

# ── Generated plugin registrant (created by flutter build) ─
set(PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:flutter_wrapper_plugin>)

install(
  FILES "${CMAKE_INSTALL_PREFIX}/$<TARGET_FILE_NAME:scribe_ai>"
  DESTINATION "${CMAKE_INSTALL_PREFIX}"
)
