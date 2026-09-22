cask "portlessman" do
  version "1.0.2"
  sha256 "c32b1e6dcdfdf9fd2a8f0097fdbeedbcf7daa81096dabee6d04c23b32060546d"

  url "https://github.com/inakiabt/portlessman/releases/download/v#{version}/Portlessman-#{version}.zip"
  name "Portlessman"
  desc "Menu bar app for administering and monitoring Portless"
  homepage "https://github.com/inakiabt/portlessman"

  depends_on macos: :sonoma

  app "Portlessman.app"

  postflight_steps do
    run "/usr/bin/xattr",
        args: ["-cr", "{{appdir}}/Portlessman.app"]
  end

  zap trash: [
    "~/.portless",
    "~/Library/Preferences/sh.portlessman.app.plist",
  ]
end
