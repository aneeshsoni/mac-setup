require 'json'

profile = JSON.parse(File.read(ARGV.fetch(0)))
output = ARGV.fetch(1)
# Validate all fields before writing any output. Preserve JSONC verbatim.
settings = JSON.parse(profile.fetch('settings')).fetch('settings')
keybindings = JSON.parse(profile.fetch('keybindings')).fetch('keybindings')
extensions = JSON.parse(profile.fetch('extensions')).map do |extension|
  id = extension.fetch('identifier').fetch('id')
  raise "Invalid extension ID: #{id}" unless /\A[a-z0-9-]+\.[a-z0-9._-]+\z/i.match?(id)
  id
end
raise 'Expected settings and keybindings text' unless settings.is_a?(String) && keybindings.is_a?(String)
File.write(File.join(output, 'settings.json'), settings)
File.write(File.join(output, 'keybindings.json'), keybindings)
File.write(File.join(output, 'extensions.txt'), extensions.join("\n") + "\n")
