cask "inkwell" do
  version "1.0.6"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/cschuman/inkwell/releases/download/v#{version}/Inkwell-#{version}.dmg"
  name "Inkwell"
  desc "Native macOS markdown viewer with beautiful typography"
  homepage "https://github.com/cschuman/inkwell"

  auto_updates true
  depends_on macos: ">= :big_sur"

  app "Inkwell.app"

  zap trash: [
    "~/Library/Preferences/com.coreymd.inkwell.plist",
    "~/Library/Saved Application State/com.coreymd.inkwell.savedState",
  ]
end