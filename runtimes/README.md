# Bundled language runtimes

Players shouldn't have to install Python, Node, a JDK or a C++ compiler to play.
The plan is to ship those runtimes **inside the game download**. This folder is
where they go.

> **Status:** not done yet. For now, when you run the game from the Godot editor
> it uses whatever is installed on your computer (`python3`, `node`, `javac`/`java`,
> `g++`). Exported builds only look here, so they can't run code until this is set up.

## Layout

One folder per platform, with the paths that `data/languages.json` expects:

```
runtimes/
  windows/
    python/python.exe          # Python "embeddable package" zip, unzipped
    node/node.exe              # Node.js Windows zip, unzipped
    jdk/bin/javac.exe, java.exe
    mingw/bin/g++.exe          # e.g. a MinGW-w64 / WinLibs build
  macos/
    python/bin/python3         # e.g. python-build-standalone
    node/bin/node
    jdk/Contents/Home/bin/javac, java
    clang/bin/clang++
  linux/
    python/bin/python3
    node/bin/node
    jdk/bin/javac, java
    clang/bin/clang++
```

If you change a path, change it in `data/languages.json` too (the `bundled` entries).

These folders are **git-ignored** because they're hundreds of MB. We'll add a
script that downloads them (and CI that packages them) later.

## Candidate downloads

| Language   | Where to get a portable build | Rough size |
|------------|-------------------------------|------------|
| Python     | [python-build-standalone](https://github.com/astral-sh/python-build-standalone) (all OSes) or the official Windows embeddable zip | ~30-60 MB |
| JS / TS    | Official Node.js zip/tar.gz from nodejs.org (Node 23.6+ runs `.ts` files directly) | ~30-50 MB |
| Java       | A JDK from [Adoptium](https://adoptium.net/) (needs `javac`, so a JDK, not a JRE). Can be slimmed with `jlink`. | ~50-200 MB |
| C++        | Windows: WinLibs/MinGW-w64. Linux: a portable clang/LLVM. macOS: hardest, since compiling needs Apple's SDK headers; we may need to ask players to run `xcode-select --install` | 100+ MB |

Check each license before redistributing (all of the above allow it, but some
want the license file shipped alongside).

## Exporting

When exporting the game, copy `runtimes/<platform>/` next to the exported
executable, so the game finds it at `<game folder>/runtimes/<platform>/`.
(On macOS that's next to the `.app`, until we decide to put it inside the bundle.)
