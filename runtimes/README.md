# Bundled language runtimes

Players shouldn't have to install Python, Node, a JDK or a C++ compiler to play,
so the game ships its own copies. They live in this folder, one subfolder per
platform. They're hundreds of MB, so they're **not in git**: a script downloads
them.

## Getting them

From the project folder:

```sh
python3 tools/fetch_runtimes.py                          # this computer
python3 tools/fetch_runtimes.py --platform windows-x86_64  # another platform
python3 tools/fetch_runtimes.py --all                    # every platform
python3 tools/fetch_runtimes.py --only python,node       # just some languages
```

(`python` instead of `python3` on Windows.) Re-running is quick: it skips
anything already installed at the pinned version, and keeps downloaded archives
in `runtimes/.downloads/`.

## What's in each platform folder

Platforms: `windows-x86_64`, `macos-arm64` (Apple Silicon), `macos-x86_64`
(Intel Mac), `linux-x86_64`, `linux-arm64`.

| Folder | Language | Where it comes from | Size on disk |
|---|---|---|---|
| `python/` | Python 3.14 | [python-build-standalone](https://github.com/astral-sh/python-build-standalone) (the portable builds `uv` uses), minus tests, IDLE and pip | ~60-80 MB |
| `node/` | JavaScript and TypeScript | Official [Node.js](https://nodejs.org/) 24 LTS, just the `node` program (no npm). TypeScript runs directly: Node strips the types. | ~90-120 MB |
| `jdk/` | Java | [Eclipse Temurin](https://adoptium.net/) JDK 21, trimmed with `jlink` to the standard library plus `javac` | ~70 MB (~190 MB if trimmed on another OS, see below) |
| `zig/` | C++ | [Zig](https://ziglang.org/), used as a C++ compiler (`zig c++`). It brings its own C++ standard library and headers for every OS, so it works on Windows and on Macs without Xcode. | ~250-350 MB |
| `VERSIONS.json` | | What was installed, from which URL, with its checksum and license | |

Versions are pinned in [`tools/runtimes.json`](../tools/runtimes.json). To
upgrade one, change its version there and re-run the script. Every download is
checked against the SHA-256 checksum its publisher posts.

The paths the game looks for are the `bundled` entries in
[`data/languages.json`](../data/languages.json). If you change a folder
layout, change it there too.

### TypeScript notes

Node runs `.ts` files by removing the type annotations
(`--experimental-transform-types`, which also handles `enum`). It does **not**
type-check, so a type error won't stop the code from running. If we want
challenges about type errors later, we can add the TypeScript compiler (`tsc`,
~20 MB) to the bundle.

### C++ notes

The very first C++ compile on a computer is slow (about 1 minute on Mac/Linux and 2-3 minutes on Windows in our CI)
because Zig builds the C++ standard library once and caches it. To hide that,
the game starts a small practice compile in the background when the main menu
opens (`GameData.warm_up_runtimes()`), and C++ gets a longer compile time limit
(`compile_timeout_ms` in `languages.json`).

### Java notes

`jlink` can only trim the JDK on the same kind of computer it's for, so
`--platform windows-x86_64` run on a Mac keeps a bigger (~190 MB) JDK. Release
builds should run the script on each OS (GitHub Actions does this already).

## How the game finds them

`ProcessCodeRunner` (`scripts/code_runner/process_code_runner.gd`) looks in:

- **Editor:** `<project>/runtimes/<platform>/`
- **Exported game:** `<game folder>/runtimes/<platform>/`. On macOS it also
  checks `MyGame.app/Contents/Resources/runtimes/<platform>/` and the folder
  next to the `.app`.

If a runtime isn't there, the editor falls back to whatever is installed on
your computer (handy while developing). Exported games never do.

The `.gdignore` file here stops Godot from importing the thousands of files
inside the runtimes.

## Exporting a build

1. Export the game from Godot as usual.
2. Put the runtimes next to it:
   ```sh
   python3 tools/fetch_runtimes.py --platform windows-x86_64 --dest path/to/export/runtimes
   ```
   so you end up with `MyGame.exe` and `runtimes/windows-x86_64/` side by side.
3. Zip the whole folder. Compressed, the runtimes add roughly 300-350 MB per
   platform.

Still to do before a public release:

- **macOS signing.** Downloaded apps get blocked by Gatekeeper unless every
  program inside (python, node, java, zig) is code-signed and the app is
  notarized, which needs an Apple Developer account ($99/year). Until then,
  Mac players have to right-click → Open, or run `xattr -cr` on the game.
- **Automate packaging** in GitHub Actions (export + runtimes + zip per OS).

## Licenses

All four can be redistributed with the game. Keep the license files that come
inside each folder (`python/`, `node/LICENSE`, `jdk/legal/`, `zig/LICENSE`).

| Runtime | License |
|---|---|
| Python | PSF License |
| Node.js | MIT |
| Temurin JDK | GPLv2 with Classpath Exception |
| Zig (and the libc++/LLVM parts it ships) | MIT, Apache 2.0 with LLVM exception |
