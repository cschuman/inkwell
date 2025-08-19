#pragma once

#define MDVIEWER_VERSION_MAJOR 0
#define MDVIEWER_VERSION_MINOR 2
#define MDVIEWER_VERSION_PATCH 0
#define MDVIEWER_BUILD_NUMBER 2

// Build timestamp - will be updated by build script
#define MDVIEWER_BUILD_DATE __DATE__
#define MDVIEWER_BUILD_TIME __TIME__

// Version string
#define MDVIEWER_VERSION_STRING "0.2.0"

// Feature flags for this build
#define FEATURE_COMMAND_PALETTE 1
#define FEATURE_KEYBOARD_SHORTCUTS 1
#define FEATURE_METAL_RENDERING 1
#define FEATURE_VIRTUAL_DOM 1

// Git commit hash (will be set by build script)
#ifndef GIT_COMMIT_HASH
#define GIT_COMMIT_HASH "d54418e"
#endif

namespace mdviewer {
    constexpr const char* getVersionString() {
        return MDVIEWER_VERSION_STRING;
    }
    
    constexpr int getBuildNumber() {
        return MDVIEWER_BUILD_NUMBER;
    }
    
    constexpr const char* getBuildDate() {
        return MDVIEWER_BUILD_DATE " " MDVIEWER_BUILD_TIME;
    }
}