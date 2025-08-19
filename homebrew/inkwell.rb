cask "inkwell" do
  version "0.2.0"
  sha256 "574fe1627e605179c2d47205aaaddcab13f9c739e3554503df17c72af9953c27"

  url "https://github.com/cschuman/inkwell/releases/download/v#{version}/Inkwell-#{version}.dmg"
  name "Inkwell"
  desc "Native macOS markdown viewer with high performance"
  homepage "https://github.com/cschuman/inkwell"

  app "Inkwell.app"

  zap trash: [
    "~/Library/Preferences/com.inkwell.markdown.plist",
    "~/Library/Saved Application State/com.inkwell.markdown.savedState",
  ]
end