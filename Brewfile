# Keep manually installed apps. Homebrew only installs what's missing.
def app_present?(name)
  ["/Applications", File.expand_path("~/Applications")].any? do |directory|
    File.directory?(File.join(directory, "#{name}.app"))
  end
end

brew "uv"

cask "iterm2" unless app_present?("iTerm")
cask "visual-studio-code" unless app_present?("Visual Studio Code")
cask "raycast" unless app_present?("Raycast")
cask "monitorcontrol" unless app_present?("MonitorControl")
cask "rectangle" unless app_present?("Rectangle")
tap "theboredteam/boring-notch"
cask "theboredteam/boring-notch/boring-notch" unless app_present?("boringNotch")

# Optional free replacement for keyboard remapping:
# cask "karabiner-elements" unless app_present?("Karabiner-Elements")

# Optional if you use tmux:
# brew "tmux"
