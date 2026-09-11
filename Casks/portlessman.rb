cask "portlessman" do
  version "1.0.0"
  sha256 "b33b4b47323e9f5fd39aed2b5c1084b0b934ff6f38320473d0dd2e9675aaf50f"

  url "https://github.com/inakiabt/portlessman/releases/download/v#{version}/Portlessman-#{version}.zip"
  name "Portlessman"
  desc "Native macOS menu bar app for administering and monitoring Portless"
  homepage "https://github.com/inakiabt/portlessman"

  depends_on macos: ">= :sonoma"

  app "Portlessman.app"

  zap trash: [
    "~/.portless",
    "~/Library/Preferences/sh.portlessman.app.plist",
  ]
end
