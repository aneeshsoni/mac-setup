const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { createHash } = require('node:crypto');
const root = path.resolve(__dirname, '..');

function fixture(t) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'mac-setup-test-'));
  t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
  const repo = path.join(temp, 'repo');
  const home = path.join(temp, 'home');
  const bin = path.join(temp, 'bin');
  for (const dir of [repo, home, bin]) fs.mkdirSync(dir);
  for (const file of ['install.sh', 'Brewfile', 'shell', 'iterm2', 'vscode', 'scripts', 'fonts']) {
    fs.cpSync(path.join(root, file), path.join(repo, file), { recursive: true });
  }
  function mock(name, source) {
    fs.writeFileSync(path.join(bin, name), '#!/bin/bash\n' + source, { mode: 0o755 });
  }
  mock('uname', 'echo Darwin\n');
  mock('brew', 'echo "$*" >> "$TEST_LOG"\nexit "${BREW_RESULT:-0}"\n');
  mock('code', 'echo "$*" >> "$TEST_LOG"\ncase "$*" in *anthropic*) exit "${EXTENSION_RESULT:-0}";; esac\n');
  mock('curl', [
    'echo "download" >> "$TEST_LOG"',
    'if [[ "${DOWNLOAD_RESULT:-0}" != 0 ]]; then exit "$DOWNLOAD_RESULT"; fi',
    'while [[ $# -gt 0 ]]; do',
    '  if [[ "$1" == -o ]]; then shift; printf "%s" "${FONT_CONTENT:-test-font}" > "$1"; exit 0; fi',
    '  shift',
    'done',
    'exit 1',
  ].join('\n'));
  const hash = createHash('sha256').update('test-font').digest('hex');
  fs.writeFileSync(path.join(repo, 'fonts/manifest.txt'), [1, 2].map(i => `${hash}|Font ${i}.ttf|https://example.invalid/${i}\n`).join(''));
  const log = path.join(temp, 'log');
  const env = { ...process.env, HOME: home, PATH: `${bin}:/usr/bin:/bin:/usr/sbin:/sbin`, TEST_LOG: log };
  const user = path.join(home, 'Library/Application Support/Code/User');
  const profiles = path.join(home, 'Library/Application Support/iTerm2/DynamicProfiles/public-mac-setup.json');
  function write(file, content) { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, content); }
  function run(overrides = {}) {
    const result = spawnSync('/bin/bash', [path.join(repo, 'install.sh')], { env: { ...env, ...overrides }, encoding: 'utf8' });
    assert.ifError(result.error);
    return result;
  }
  return { temp, repo, home, bin, log, user, profiles, write, run, mock };
}

test('fresh install applies shell, profiles, fonts, JSONC and every extension', t => {
  const f = fixture(t);
  const result = f.run();
  assert.equal(result.status, 0, result.stderr);
  assert.equal(fs.readFileSync(path.join(f.home, '.zshrc'), 'utf8'), fs.readFileSync(path.join(root, 'shell/.zshrc'), 'utf8'));
  assert.deepEqual(JSON.parse(fs.readFileSync(f.profiles)), JSON.parse(fs.readFileSync(path.join(root, 'iterm2/profiles.json'))));
  const exportData = JSON.parse(fs.readFileSync(path.join(root, 'vscode/setup.code-profile')));
  for (const key of ['settings', 'keybindings']) {
    assert.equal(fs.readFileSync(path.join(f.user, `${key}.json`), 'utf8'), JSON.parse(exportData[key])[key]);
  }
  const log = fs.readFileSync(f.log, 'utf8');
  for (const extension of JSON.parse(exportData.extensions)) {
    assert.ok(log.includes(`--profile Default --install-extension ${extension.identifier.id}`));
  }
  assert.equal(fs.readFileSync(path.join(f.home, 'Library/Fonts/Font 1.ttf'), 'utf8'), 'test-font');
});

test('existing files are backed up; unchanged reruns skip downloads and backups; new changes get numbered backups', t => {
  const f = fixture(t);
  const shell = path.join(f.home, '.zshrc');
  f.write(shell, 'original shell');
  f.write(f.profiles, 'original profiles');
  f.write(path.join(f.user, 'settings.json'), 'original settings');
  f.write(path.join(f.user, 'keybindings.json'), 'original keys');
  f.write(path.join(f.home, '.zshrc.local'), 'private config');
  assert.equal(f.run().status, 0);
  assert.equal(fs.readFileSync(`${shell}_old_backup`, 'utf8'), 'original shell');
  assert.equal(fs.readFileSync(path.join(f.user, 'settings.json_old_backup'), 'utf8'), 'original settings');
  assert.equal(fs.readFileSync(path.join(f.user, 'keybindings.json_old_backup'), 'utf8'), 'original keys');
  assert.equal(fs.readFileSync(path.join(f.home, 'Library/Application Support/mac-setup/backups/iterm2-profiles.json_old_backup'), 'utf8'), 'original profiles');
  assert.deepEqual(fs.readdirSync(path.dirname(f.profiles)), ['public-mac-setup.json']);
  fs.writeFileSync(f.log, '');
  assert.equal(f.run().status, 0);
  assert.ok(!fs.existsSync(`${shell}_old_backup.1`));
  assert.ok(!fs.readFileSync(f.log, 'utf8').includes('download'));
  f.write(shell, 'new edits');
  assert.equal(f.run().status, 0);
  assert.equal(fs.readFileSync(`${shell}_old_backup.1`, 'utf8'), 'new edits');
  assert.equal(fs.readFileSync(`${shell}_old_backup`, 'utf8'), 'original shell');
  assert.equal(fs.readFileSync(path.join(f.home, '.zshrc.local'), 'utf8'), 'private config');
});

test('symlinked and dangling shell configs are backed up without changing their targets', t => {
  const f = fixture(t);
  const shell = path.join(f.home, '.zshrc');
  f.write(path.join(f.home, 'dotfiles/zshrc'), 'linked config');
  fs.symlinkSync('dotfiles/zshrc', shell);
  assert.equal(f.run().status, 0);
  assert.equal(fs.readlinkSync(`${shell}_old_backup`), 'dotfiles/zshrc');
  assert.equal(fs.readFileSync(path.join(f.home, 'dotfiles/zshrc'), 'utf8'), 'linked config');
  fs.unlinkSync(shell);
  fs.symlinkSync('missing', shell);
  assert.equal(f.run().status, 0);
  assert.equal(fs.readlinkSync(`${shell}_old_backup.1`), 'missing');
});

test('brew, download and extension failures still apply configs and try later extensions', t => {
  const f = fixture(t);
  const result = f.run({ BREW_RESULT: '1', DOWNLOAD_RESULT: '22', EXTENSION_RESULT: '1' });
  assert.equal(result.status, 1);
  assert.ok(fs.existsSync(f.profiles));
  assert.ok(fs.existsSync(path.join(f.user, 'settings.json')));
  const log = fs.readFileSync(f.log, 'utf8');
  assert.equal((log.match(/download/g) || []).length, 2);
  assert.ok(log.includes('--install-extension charliermarsh.ruff'));
  assert.match(result.stdout, /Some steps need attention/);
  assert.match(result.stderr, /Some Homebrew packages failed/);
});

test('a bad font checksum preserves existing fonts and still configures VS Code', t => {
  const f = fixture(t);
  const font = path.join(f.home, 'Library/Fonts/Font 1.ttf');
  f.write(font, 'existing font');
  const result = f.run({ FONT_CONTENT: 'corrupt' });
  assert.equal(result.status, 1);
  assert.equal(fs.readFileSync(font, 'utf8'), 'existing font');
  assert.match(result.stderr, /Checksum mismatch/);
  assert.ok(fs.existsSync(path.join(f.user, 'settings.json')));
});

test('a config copy failure leaves the original intact and does not prevent later configs', t => {
  const f = fixture(t);
  f.write(path.join(f.home, '.zshrc'), 'original');
  f.mock('cp', 'case "$1" in */shell/.zshrc) exit 1;; esac\nexec /bin/cp "$@"\n');
  assert.equal(f.run().status, 1);
  assert.equal(fs.readFileSync(path.join(f.home, '.zshrc'), 'utf8'), 'original');
  assert.ok(fs.existsSync(f.profiles));
  assert.ok(fs.existsSync(path.join(f.user, 'settings.json')));
});

test('missing Homebrew still installs fonts and configs and reports the missing prerequisite', t => {
  const f = fixture(t);
  fs.unlinkSync(path.join(f.bin, 'brew'));
  const result = f.run();
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Homebrew is missing/);
  assert.ok(fs.existsSync(f.profiles));
  assert.ok(fs.existsSync(path.join(f.user, 'settings.json')));
  assert.ok(fs.existsSync(path.join(f.home, 'Library/Fonts/Font 1.ttf')));
});

test('failed replacement restores the original config after backing it up', t => {
  const f = fixture(t);
  const shell = path.join(f.home, '.zshrc');
  f.write(shell, 'original');
  f.mock('mv', [
    'if [[ "$1" == */.mac-setup.* && "$2" == */.zshrc ]]; then exit 1; fi',
    'exec /bin/mv "$@"',
  ].join('\n'));
  const result = f.run();
  assert.equal(result.status, 1);
  assert.equal(fs.readFileSync(shell, 'utf8'), 'original');
  assert.ok(fs.existsSync(f.profiles));
  assert.ok(fs.existsSync(path.join(f.user, 'settings.json')));
});

test('Brewfile excludes existing apps in either Applications folder and keeps missing apps', () => {
  const script = `
    require 'json'
    class File
      def self.directory?(path)
        ['/Applications/iTerm.app', File.expand_path('~/Applications/Rectangle.app')].include?(path)
      end
    end
    $casks = []
    def cask(name); $casks << name; end
    def brew(name); end
    def tap(name); end
    load ARGV.fetch(0)
    puts JSON.generate($casks)
  `;
  const result = spawnSync('/usr/bin/ruby', ['-e', script, path.join(root, 'Brewfile')], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  const casks = JSON.parse(result.stdout);
  assert.ok(!casks.includes('iterm2'));
  assert.ok(!casks.includes('rectangle'));
  assert.ok(casks.includes('visual-studio-code'));
  assert.ok(casks.includes('theboredteam/boring-notch/boring-notch'));
});

test('profiles have distinct visual names, stable IDs, and identical editing shortcuts', () => {
  const profiles = JSON.parse(fs.readFileSync(path.join(root, 'iterm2/profiles.json'))).Profiles;
  assert.equal(new Set(profiles.map(p => p.Name)).size, 4);
  assert.equal(new Set(profiles.map(p => p.Guid)).size, 4);
  for (const profile of profiles) {
    assert.match(profile.Name, /^Mac Setup - /);
    assert.deepEqual(profile['Keyboard Map'], profiles[0]['Keyboard Map']);
    assert.equal(profile['Option Key Sends'], 2);
    assert.equal(profile['Right Option Key Sends'], 2);
    assert.deepEqual(profile['Keyboard Map']['0xf702-0x240000'], { Text: 'b', Action: 10 });
    assert.deepEqual(profile['Keyboard Map']['0xf703-0x240000'], { Text: 'f', Action: 10 });
    assert.equal(profile.Shortcut, '');
  }
});
