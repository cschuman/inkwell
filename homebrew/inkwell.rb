cask "inkwell" do
  version "1.0.7"
  sha256 "3c6a8b4781ce1d7a69167ea19095a72c07780fb9b3fa066d42909ebb6a3d1a65"

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
