cask "inkwell" do
  version "1.0.9"
  sha256 "98e7f2d994be9eb1312dcdd2c6642b2c9567c052232b7eaea117a5bb8d051463"

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
