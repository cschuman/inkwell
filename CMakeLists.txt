cmake_minimum_required(VERSION 3.20)
project(Inkwell VERSION 1.0.0 LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# macOS specific settings
set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")

# Find packages
find_package(fmt CONFIG REQUIRED)
# find_package(folly CONFIG REQUIRED)
find_package(GTest CONFIG REQUIRED)
find_package(benchmark CONFIG REQUIRED)

# Find system frameworks
find_library(COCOA_FRAMEWORK Cocoa)
find_library(METAL_FRAMEWORK Metal)
find_library(METALKIT_FRAMEWORK MetalKit)
find_library(CORETEXT_FRAMEWORK CoreText)
find_library(QUARTZ_FRAMEWORK Quartz)
find_library(QUARTZCORE_FRAMEWORK QuartzCore)
find_library(WEBKIT_FRAMEWORK WebKit)

# md4c library (will be added as external project)
include(FetchContent)
set(BUILD_SHARED_LIBS OFF)  # Force static linking
FetchContent_Declare(
    md4c
    GIT_REPOSITORY https://github.com/mity/md4c.git
    GIT_TAG release-0.5.2
)
FetchContent_MakeAvailable(md4c)

# Core library
add_library(mdviewer_core STATIC
    src/core/markdown_parser.cpp
    src/core/virtual_dom.cpp
    src/core/document.cpp
    src/core/toc_generator.cpp
    src/utils/memory_pool.cpp
    src/utils/string_utils.cpp
    src/utils/file_utils.cpp
)

target_include_directories(mdviewer_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${md4c_SOURCE_DIR}/src
)

target_link_libraries(mdviewer_core PUBLIC
    md4c
    fmt::fmt
    # Folly::folly
)

# Platform-specific library (Objective-C++)
add_library(mdviewer_platform STATIC
    src/platform/macos/cocoa_bridge.mm
    src/platform/macos/file_watcher.mm
    src/platform/macos/quick_look_plugin.mm
    src/platform/macos/app_delegate.mm
)

target_link_libraries(mdviewer_platform PUBLIC
    mdviewer_core
    ${COCOA_FRAMEWORK}
    ${CORETEXT_FRAMEWORK}
    ${QUARTZ_FRAMEWORK}
)

# UI Design System library
add_library(mdviewer_ui STATIC
    src/ui/design_system.cpp
    src/ui/platform_effects.mm
    src/ui/enhanced_window.mm
    src/ui/smooth_scroll.mm
    src/ui/simple_command_palette.mm
)

target_link_libraries(mdviewer_ui PUBLIC
    mdviewer_core
    ${COCOA_FRAMEWORK}
    ${QUARTZCORE_FRAMEWORK}
)

# Rendering library
add_library(mdviewer_rendering STATIC
    src/rendering/metal_renderer.mm
    src/rendering/text_layout.cpp
    src/rendering/glyph_atlas.mm
    src/rendering/render_engine.mm
    src/rendering/markdown_renderer.mm
    src/rendering/mermaid_renderer.mm
)

target_link_libraries(mdviewer_rendering PUBLIC
    mdviewer_core
    mdviewer_ui
    ${METAL_FRAMEWORK}
    ${METALKIT_FRAMEWORK}
    ${CORETEXT_FRAMEWORK}
    ${COCOA_FRAMEWORK}
)

# Main application
add_executable(Inkwell
    src/main.mm
    src/platform/macos/main_window.mm
    src/ui/command_palette.mm
    resources/Info.plist
)

target_link_libraries(Inkwell PRIVATE
    mdviewer_core
    mdviewer_platform
    mdviewer_rendering
    mdviewer_ui
    ${WEBKIT_FRAMEWORK}
)

set_target_properties(Inkwell PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/resources/Info.plist
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.coreymd.inkwell"
)

# Metal shaders
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/shaders.metallib
    COMMAND xcrun -sdk macosx metal -c ${CMAKE_CURRENT_SOURCE_DIR}/shaders/text_render.metal -o ${CMAKE_CURRENT_BINARY_DIR}/text_render.air
    COMMAND xcrun -sdk macosx metal -c ${CMAKE_CURRENT_SOURCE_DIR}/shaders/enhanced_render.metal -o ${CMAKE_CURRENT_BINARY_DIR}/enhanced_render.air
    COMMAND xcrun -sdk macosx metallib ${CMAKE_CURRENT_BINARY_DIR}/text_render.air ${CMAKE_CURRENT_BINARY_DIR}/enhanced_render.air -o ${CMAKE_CURRENT_BINARY_DIR}/shaders.metallib
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/shaders/text_render.metal ${CMAKE_CURRENT_SOURCE_DIR}/shaders/enhanced_render.metal
)

add_custom_target(shaders ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/shaders.metallib)
add_dependencies(Inkwell shaders)

# Tests
enable_testing()

add_executable(mdviewer_tests
    tests/test_parser.cpp
    tests/test_virtual_dom.cpp
    tests/test_memory_pool.cpp
    tests/test_toc_generator.cpp
)

target_link_libraries(mdviewer_tests PRIVATE
    mdviewer_core
    GTest::gtest_main
)

add_test(NAME mdviewer_tests COMMAND mdviewer_tests)

# Benchmarks
add_executable(mdviewer_benchmarks
    tests/bench_parser.cpp
    tests/bench_rendering.cpp
)

target_link_libraries(mdviewer_benchmarks PRIVATE
    mdviewer_core
    mdviewer_rendering
    benchmark::benchmark_main
)

# Installation
install(TARGETS Inkwell
    BUNDLE DESTINATION /Applications
)