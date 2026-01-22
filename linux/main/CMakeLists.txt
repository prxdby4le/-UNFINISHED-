cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "trashtalk_records")

# Define the application sources.
target_sources(${BINARY_NAME} PRIVATE
  "main.cc"
)

# Application-specific settings.
add_executable(${BINARY_NAME} "main.cc")

# Generated plugin build rules, which manage the platform-specific build
# rules for each plugin.
add_subdirectory(flutter)

# Link the application to the Flutter library.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)

# Run the Flutter tooling to generate any required build files.
flutter_assemble_bundle(
  TARGET ${BINARY_NAME}
  FLUTTER_TARGET ${CMAKE_CURRENT_SOURCE_DIR}/../..
  BUNDLE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bundle
  DEPENDENCIES_VAR DEPS
  SOURCES_VAR SOURCES
)
