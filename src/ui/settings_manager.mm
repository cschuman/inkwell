#include "ui/settings_manager.h"
#include <Cocoa/Cocoa.h>

namespace mdviewer::ui {

SettingsManager& SettingsManager::getInstance() {
    static SettingsManager instance;
    return instance;
}

ThemeMode SettingsManager::getThemeMode() const {
    return themeMode_;
}

void SettingsManager::setThemeMode(ThemeMode mode) {
    if (themeMode_ != mode) {
        themeMode_ = mode;
        saveSettings();
        notifyThemeChange();
    }
}

bool SettingsManager::shouldUseDarkMode() const {
    switch (themeMode_) {
        case ThemeMode::Light:
            return false;
        case ThemeMode::Dark:
            return true;
        case ThemeMode::System:
            return getSystemDarkMode();
    }
    return false;
}

void SettingsManager::setThemeChangeCallback(ThemeChangeCallback callback) {
    themeChangeCallback_ = callback;
}

void SettingsManager::loadSettings() {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    // Load theme mode (default to System)
    NSInteger themeModeInt = [defaults integerForKey:@"ThemeMode"];
    if (themeModeInt >= 0 && themeModeInt <= 2) {
        themeMode_ = static_cast<ThemeMode>(themeModeInt);
    } else {
        themeMode_ = ThemeMode::System;
    }
}

void SettingsManager::saveSettings() {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:static_cast<NSInteger>(themeMode_) forKey:@"ThemeMode"];
    [defaults synchronize];
}

bool SettingsManager::getSystemDarkMode() const {
    if (@available(macOS 10.14, *)) {
        NSAppearance* appearance = [NSApp effectiveAppearance];
        NSAppearanceName appearanceName = [appearance bestMatchFromAppearancesWithNames:@[
            NSAppearanceNameAqua,
            NSAppearanceNameDarkAqua
        ]];
        return [appearanceName isEqualToString:NSAppearanceNameDarkAqua];
    }
    return false;
}

void SettingsManager::notifyThemeChange() {
    if (themeChangeCallback_) {
        themeChangeCallback_(shouldUseDarkMode());
    }
}

}  // namespace mdviewer::ui