# Project-level configuration.
cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

# Use the C++ standard defined by the Flutter project.
set(CMAKE_CXX_STANDARD 17)

# Define the application name. This must match the value used in the
# `linux/CMakeLists.txt` file.
set(APPLICATION_NAME "trashtalk_records")

# Define the Flutter project directory.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../")

# Application-specific CMake files.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Use the Flutter tooling utilities.
include(FlutterUtilities)

# Define the Flutter build mode.
set(FLUTTER_BUILD_MODE "debug")

# Flutter library and tooling.
add_subdirectory(${FLUTTER_MANAGED_DIR} ${CMAKE_CURRENT_BINARY_DIR}/flutter)

# Application code.
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/main)
