cmake_minimum_required(VERSION 3.20)
project(Inkwell VERSION 1.0.2 LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# macOS specific settings
set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")

# Find packages
find_package(fmt CONFIG REQUIRED)
find_package(GTest CONFIG REQUIRED)

# Find system frameworks
find_library(COCOA_FRAMEWORK Cocoa)
find_library(CORETEXT_FRAMEWORK CoreText)
find_library(QUARTZ_FRAMEWORK Quartz)
find_library(QUARTZCORE_FRAMEWORK QuartzCore)
find_library(WEBKIT_FRAMEWORK WebKit)

# md4c library (will be added as external project)
include(FetchContent)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries" FORCE)  # Force static linking
set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)  # Honor normal variables in option()
FetchContent_Declare(
    md4c
    GIT_REPOSITORY https://github.com/mity/md4c.git
    GIT_TAG release-0.5.2
)
FetchContent_MakeAvailable(md4c)

# Core library
add_library(mdviewer_core STATIC
    src/core/markdown_parser.cpp
    src/core/document.cpp
    src/core/toc_generator.cpp
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
    src/rendering/text_layout.cpp
    src/rendering/markdown_renderer.mm
    src/rendering/mermaid_renderer.mm
)

target_link_libraries(mdviewer_rendering PUBLIC
    mdviewer_core
    mdviewer_ui
    ${CORETEXT_FRAMEWORK}
    ${COCOA_FRAMEWORK}
)

# Main application
add_executable(Inkwell
    src/main.mm
    src/platform/macos/main_window.mm
    src/ui/command_palette.mm
    src/effects/base_drag_effect.mm
    src/effects/effect_manager.mm
    src/effects/no_effect.mm
    src/effects/ripple_effect.mm
    src/effects/particle_effect.mm
    src/effects/effects_registry.mm
    src/effects/pass_through_view.mm
    src/effects/physics_world.mm
    src/effects/animation_orchestrator.mm
    src/effects/noise_generator.mm
    resources/Info.plist
)

# Ensure effects are linked
target_compile_options(Inkwell PRIVATE -ObjC)

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


# Tests - temporarily disabled during simplification
# enable_testing()
# add_executable(mdviewer_tests
#     tests/test_parser.cpp
#     tests/test_toc_generator.cpp
# )
# target_link_libraries(mdviewer_tests PRIVATE
#     mdviewer_core
#     GTest::gtest_main
# )
# add_test(NAME mdviewer_tests COMMAND mdviewer_tests)

# Installation
install(TARGETS Inkwell
    BUNDLE DESTINATION /Applications
)