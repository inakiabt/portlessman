cask "portlessman" do
  version "1.0.0"
  sha256 "dfbbe271e4661829c084025c697549657cf2ec5a0822cd91e99248c309791d17"

  url "https://github.com/inakiabt/portlessman/releases/download/v#{version}/Portlessman-#{version}.zip"
  name "Portlessman"
  desc "Menu bar app for administering and monitoring Portless"
  homepage "https://github.com/inakiabt/portlessman"

  depends_on macos: :sonoma

  app "Portlessman.app"

  zap trash: [
    "~/.portless",
    "~/Library/Preferences/sh.portlessman.app.plist",
  ]
end
