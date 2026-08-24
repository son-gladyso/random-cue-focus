cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Temporary runner target definition. The original runner/CMakeLists.txt has
# a malformed add_executable line and is currently not writable in this
# workspace, so this file references the same sources from a clean CMake target.
set(RUNNER_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../runner")

add_executable(${BINARY_NAME} WIN32
  "${RUNNER_SOURCE_DIR}/app_flutter_window.cpp"
  "${RUNNER_SOURCE_DIR}/flutter_window.cpp"
  "${RUNNER_SOURCE_DIR}/main.cpp"
  "${RUNNER_SOURCE_DIR}/utils.cpp"
  "${RUNNER_SOURCE_DIR}/win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "${RUNNER_SOURCE_DIR}/Runner.rc"
  "${RUNNER_SOURCE_DIR}/runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
  "${RUNNER_SOURCE_DIR}"
)

add_dependencies(${BINARY_NAME} flutter_assemble)
