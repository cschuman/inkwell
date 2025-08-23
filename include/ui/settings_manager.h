#pragma once

#include <string>
#include <functional>

namespace mdviewer::ui {

enum class ThemeMode {
    Light,
    Dark,
    System  // Follow system appearance
};

class SettingsManager {
public:
    static SettingsManager& getInstance();
    
    // Theme settings
    ThemeMode getThemeMode() const;
    void setThemeMode(ThemeMode mode);
    bool shouldUseDarkMode() const;  // Resolves actual theme based on mode and system
    
    // Callbacks
    using ThemeChangeCallback = std::function<void(bool isDarkMode)>;
    void setThemeChangeCallback(ThemeChangeCallback callback);
    
    // Persistence
    void loadSettings();
    void saveSettings();
    
private:
    SettingsManager() = default;
    ~SettingsManager() = default;
    SettingsManager(const SettingsManager&) = delete;
    SettingsManager& operator=(const SettingsManager&) = delete;
    
    ThemeMode themeMode_ = ThemeMode::System;
    ThemeChangeCallback themeChangeCallback_;
    
    bool getSystemDarkMode() const;
    void notifyThemeChange();
};

}  // namespace mdviewer::ui