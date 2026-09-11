cask "portlessman" do
  version "1.0.1"
  sha256 "7adbd2422bb4d801903e06b04a6e8c857724a1479689c0d472731d246a3270e2"

  url "https://github.com/inakiabt/portlessman/releases/download/v#{version}/Portlessman-#{version}.zip"
  name "Portlessman"
  desc "Menu bar app for administering and monitoring Portless"
  homepage "https://github.com/inakiabt/portlessman"

  depends_on macos: :sonoma

  app "Portlessman.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Portlessman.app"],
                   sudo: false
  end

  zap trash: [
    "~/.portless",
    "~/Library/Preferences/sh.portlessman.app.plist",
  ]
end
