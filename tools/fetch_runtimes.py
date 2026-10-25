#!/usr/bin/env python3
"""Download the language runtimes that ship with Commit to Me.

Players shouldn't have to install Python, Node, a JDK or a C++ compiler, so the
game carries its own copies in runtimes/<platform>/. They're too big for git,
so this script downloads them instead.

Usage (from the project folder):

    python3 tools/fetch_runtimes.py                 # this computer only
    python3 tools/fetch_runtimes.py --platform windows-x86_64
    python3 tools/fetch_runtimes.py --all           # every platform
    python3 tools/fetch_runtimes.py --only python,node
    python3 tools/fetch_runtimes.py --dest path/to/exported/game/runtimes

Versions are pinned in tools/runtimes.json. Every download is checked against
the checksum its publisher posts next to it. Runs on Windows, macOS and Linux
with only the Python standard library (Python 3.9+).

What ends up in runtimes/<platform>/:
    python/   CPython from python-build-standalone
    node/     Node.js (runs JavaScript, and TypeScript by stripping the types)
    jdk/      Eclipse Temurin JDK (javac + java), trimmed down
    zig/      Zig, used as a C++ compiler ("zig c++"), works on every OS
"""

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "tools" / "runtimes.json"
DEFAULT_DEST = ROOT / "runtimes"
COMPONENTS = ["python", "node", "java", "zig"]

# platform -> (os, arch) plus the names each publisher uses for it.
PLATFORMS = {
    "windows-x86_64": {
        "os": "windows", "python": "x86_64-pc-windows-msvc", "node": "win-x64",
        "java": ("x64", "windows"), "zig": "x86_64-windows",
    },
    "macos-arm64": {
        "os": "macos", "python": "aarch64-apple-darwin", "node": "darwin-arm64",
        "java": ("aarch64", "mac"), "zig": "aarch64-macos",
    },
    "macos-x86_64": {
        "os": "macos", "python": "x86_64-apple-darwin", "node": "darwin-x64",
        "java": ("x64", "mac"), "zig": "x86_64-macos",
    },
    "linux-x86_64": {
        "os": "linux", "python": "x86_64-unknown-linux-gnu", "node": "linux-x64",
        "java": ("x64", "linux"), "zig": "x86_64-linux",
    },
    "linux-arm64": {
        "os": "linux", "python": "aarch64-unknown-linux-gnu", "node": "linux-arm64",
        "java": ("aarch64", "linux"), "zig": "aarch64-linux",
    },
}

# Java modules to keep when trimming the JDK with jlink. java.se is the whole
# standard library a student might reach for; jdk.compiler is javac itself.
JAVA_MODULES = "java.se,jdk.compiler,jdk.zipfs,jdk.unsupported"

USER_AGENT = "commit-to-me-fetch-runtimes/1"


# --- Small helpers -----------------------------------------------------------

def log(msg):
    print(msg, flush=True)


def host_platform():
    system = platform.system()
    machine = platform.machine().lower()
    arch = "arm64" if machine in ("arm64", "aarch64") else "x86_64"
    os_name = {"Windows": "windows", "Darwin": "macos"}.get(system, "linux")
    return "%s-%s" % (os_name, arch)


def http_get(url, retries=4):
    """Returns the body of a URL as bytes (for small files like checksums)."""
    for attempt in range(retries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.read()
        except Exception as e:  # noqa: BLE001 - retry anything network-ish
            if attempt == retries:
                raise RuntimeError("Couldn't download %s: %s" % (url, e))
            time.sleep(2 ** (attempt + 1))


def download(url, dest, sha256, retries=4):
    """Downloads url to dest (cached) and checks its SHA-256."""
    if dest.exists() and file_sha256(dest) == sha256:
        log("    cached  %s" % dest.name)
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_name(dest.name + ".part")
    for attempt in range(retries + 1):
        try:
            log("    get     %s" % url)
            req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=120) as resp, open(tmp, "wb") as out:
                shutil.copyfileobj(resp, out, 1024 * 1024)
            break
        except Exception as e:  # noqa: BLE001
            if attempt == retries:
                raise RuntimeError("Couldn't download %s: %s" % (url, e))
            time.sleep(2 ** (attempt + 1))
    actual = file_sha256(tmp)
    if actual != sha256:
        tmp.unlink()
        raise RuntimeError("Checksum mismatch for %s\n  expected %s\n  got      %s" % (url, sha256, actual))
    tmp.replace(dest)
    return dest


def file_sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def extract_single_folder(archive, dest):
    """Unpacks an archive that holds one top-level folder, and puts that
    folder's contents at dest (replacing whatever was there)."""
    work = Path(tempfile.mkdtemp(prefix="ctm_", dir=dest.parent))
    try:
        if archive.name.endswith(".zip"):
            with zipfile.ZipFile(archive) as z:
                for member in z.namelist():
                    target = (work / member).resolve()
                    if not str(target).startswith(str(work.resolve())):
                        raise RuntimeError("Unsafe path in %s: %s" % (archive.name, member))
                z.extractall(work)
                _restore_zip_permissions(z, work)
        else:
            with tarfile.open(archive) as t:
                if hasattr(tarfile, "data_filter"):
                    t.extractall(work, filter="data")
                else:  # Python < 3.9.17: check paths by hand
                    for m in t.getmembers():
                        if m.name.startswith("/") or ".." in Path(m.name).parts:
                            raise RuntimeError("Unsafe path in %s: %s" % (archive.name, m.name))
                    t.extractall(work)
        entries = [p for p in work.iterdir() if p.name not in ("__MACOSX",)]
        if len(entries) != 1 or not entries[0].is_dir():
            raise RuntimeError("Expected one folder inside %s, found %s" % (archive.name, [e.name for e in entries]))
        remove_tree(dest)
        shutil.move(str(entries[0]), str(dest))
    finally:
        remove_tree(work)


def _restore_zip_permissions(z, root):
    # zipfile drops the executable bit; put it back where the zip recorded one.
    for info in z.infolist():
        mode = (info.external_attr >> 16) & 0o777
        if mode:
            try:
                os.chmod(root / info.filename, mode)
            except OSError:
                pass


def remove_tree(path):
    if not os.path.lexists(path):
        return
    if path.is_symlink() or path.is_file():
        path.unlink()
        return

    def on_error(func, p, _exc):  # read-only files on Windows
        os.chmod(p, stat.S_IWRITE)
        func(p)

    shutil.rmtree(path, onerror=on_error)


def remove_paths(base, patterns):
    """Deletes files/folders under base matching glob patterns (to save space)."""
    for pattern in patterns:
        for p in base.glob(pattern):
            remove_tree(p)


def folder_size_mb(path):
    total = 0
    for dirpath, _dirs, files in os.walk(path):
        for f in files:
            fp = os.path.join(dirpath, f)
            if not os.path.islink(fp):
                total += os.path.getsize(fp)
    return total / (1024 * 1024)


# --- One function per language ----------------------------------------------
# Each returns (url, sha256, file name) for its archive, then a post-processing
# step trims what the game doesn't need.

def resolve_python(cfg, plat):
    release = cfg["pbs_release"]
    base = "https://github.com/astral-sh/python-build-standalone/releases/download/%s/" % release
    sums = http_get(base + "SHA256SUMS").decode()
    pattern = re.compile(r"^([0-9a-f]{64})\s+\*?(cpython-%s\.\d+\+%s-%s-install_only_stripped\.tar\.gz)$" % (
        re.escape(cfg["version"]), release, re.escape(PLATFORMS[plat]["python"])))
    for line in sums.splitlines():
        m = pattern.match(line.strip())
        if m:
            return base + m.group(2), m.group(1), m.group(2)
    raise RuntimeError("No Python %s build for %s in python-build-standalone %s" % (cfg["version"], plat, release))


def trim_python(folder, plat):
    lib = folder / "Lib" if PLATFORMS[plat]["os"] == "windows" else next((folder / "lib").glob("python3.*"))
    remove_paths(lib, ["test", "idlelib", "turtledemo", "ensurepip", "lib2to3", "site-packages/pip", "site-packages/pip-*"])
    remove_paths(folder, ["share", "include", "Scripts/pip*", "bin/pip*", "bin/idle*", "bin/pydoc*"])


def resolve_node(cfg, plat):
    version = "v" + cfg["version"]
    base = "https://nodejs.org/dist/%s/" % version
    ext = "zip" if PLATFORMS[plat]["os"] == "windows" else "tar.xz" if PLATFORMS[plat]["os"] == "linux" else "tar.gz"
    name = "node-%s-%s.%s" % (version, PLATFORMS[plat]["node"], ext)
    for line in http_get(base + "SHASUMS256.txt").decode().splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[1] == name:
            return base + name, parts[0], name
    raise RuntimeError("No checksum for %s in Node's SHASUMS256.txt" % name)


def trim_node(folder, plat):
    # The game only needs the `node` program, not npm/npx/corepack.
    remove_paths(folder, [
        "lib/node_modules", "node_modules", "include", "share",
        "bin/npm", "bin/npx", "bin/corepack", "CHANGELOG.md", "npm*", "npx*", "corepack*", "install_tools.bat", "nodevars.bat",
    ])


def resolve_java(cfg, plat):
    version = cfg["version"]  # e.g. 21.0.13+9
    major = version.split(".")[0]
    arch, os_name = PLATFORMS[plat]["java"]
    ext = "zip" if os_name == "windows" else "tar.gz"
    name = "OpenJDK%sU-jdk_%s_%s_hotspot_%s.%s" % (major, arch, os_name, version.replace("+", "_"), ext)
    # Ask Adoptium's API first: it knows the exact file and checksum for each
    # OS (some platforms' files are named or published slightly differently).
    api = ("https://api.adoptium.net/v3/assets/release_name/eclipse/jdk-%s"
           "?architecture=%s&os=%s&image_type=jdk&jvm_impl=hotspot&heap_size=normal&project=jdk") % (
        version.replace("+", "%2B"), arch, os_name)
    try:
        release = json.loads(http_get(api, retries=2))
        for binary in release.get("binaries", []):
            pkg = binary.get("package", {})
            if pkg.get("link") and pkg.get("checksum"):
                return pkg["link"], pkg["checksum"], pkg["name"]
    except (RuntimeError, ValueError) as e:
        log("    note    Adoptium API didn't answer (%s), trying GitHub directly" % e)
    url = "https://github.com/adoptium/temurin%s-binaries/releases/download/jdk-%s/%s" % (
        major, version.replace("+", "%2B"), name)
    sha = http_get(url + ".sha256.txt").decode().split()[0]
    return url, sha, name


def trim_java(folder, plat):
    # macOS JDKs are packaged as jdk/Contents/Home/...; flatten so every
    # platform uses jdk/bin/javac.
    home = folder / "Contents" / "Home"
    if home.is_dir():
        flat = folder.with_name(folder.name + "_flat")
        shutil.move(str(home), str(flat))
        remove_tree(folder)
        flat.rename(folder)

    exe = ".exe" if PLATFORMS[plat]["os"] == "windows" else ""
    jlink = folder / "bin" / ("jlink" + exe)
    if plat == host_platform() and jlink.exists() and (folder / "jmods").is_dir():
        # jlink builds a much smaller JDK with just the modules we need.
        # It has to run on the same kind of computer, so only do it for this one.
        slim = folder.with_name(folder.name + "_slim")
        remove_tree(slim)
        log("    jlink   keeping %s" % JAVA_MODULES)
        subprocess.run([
            str(jlink), "--module-path", str(folder / "jmods"), "--add-modules", JAVA_MODULES,
            "--strip-debug", "--no-man-pages", "--no-header-files", "--compress=zip-6",
            "--output", str(slim),
        ], check=True)
        for keep in ["legal", "NOTICE", "release"]:
            src = folder / keep
            if src.exists() and not (slim / keep).exists():
                (shutil.copytree if src.is_dir() else shutil.copy2)(str(src), str(slim / keep))
        remove_tree(folder)
        slim.rename(folder)
    else:
        remove_paths(folder, ["jmods", "lib/src.zip", "lib/ct.sym", "man", "include", "demo", "sample", "Contents/MacOS"])


def resolve_zig(cfg, plat):
    index = json.loads(http_get("https://ziglang.org/download/index.json"))
    entry = index.get(cfg["version"], {}).get(PLATFORMS[plat]["zig"])
    if not entry:
        raise RuntimeError("No Zig %s build for %s" % (cfg["version"], plat))
    url = entry["tarball"]
    return url, entry["shasum"], url.rsplit("/", 1)[1]


def trim_zig(folder, plat):
    remove_paths(folder, ["doc"])


RESOLVERS = {"python": resolve_python, "node": resolve_node, "java": resolve_java, "zig": resolve_zig}
TRIMMERS = {"python": trim_python, "node": trim_node, "java": trim_java, "zig": trim_zig}
FOLDERS = {"python": "python", "node": "node", "java": "jdk", "zig": "zig"}


# --- Main --------------------------------------------------------------------

def fetch_platform(plat, manifest, dest_root, only, force, cache_dir):
    dest = dest_root / plat
    dest.mkdir(parents=True, exist_ok=True)
    versions_path = dest / "VERSIONS.json"
    installed = json.loads(versions_path.read_text()) if versions_path.exists() else {}

    log("== %s -> %s" % (plat, dest))
    for comp in only:
        cfg = manifest[comp]
        want = {k: v for k, v in cfg.items() if k != "license"}
        folder = dest / FOLDERS[comp]
        if not force and folder.is_dir() and installed.get(comp, {}).get("pinned") == want:
            log("  %-7s up to date" % comp)
            continue
        log("  %-7s %s" % (comp, cfg["version"]))
        url, sha, name = RESOLVERS[comp](cfg, plat)
        archive = download(url, cache_dir / name, sha)
        extract_single_folder(archive, folder)
        TRIMMERS[comp](folder, plat)
        installed[comp] = {"pinned": want, "url": url, "sha256": sha, "license": cfg.get("license", "")}
        versions_path.write_text(json.dumps(installed, indent=2) + "\n")
        log("    done    %.0f MB on disk" % folder_size_mb(folder))
    log("  total   %.0f MB" % folder_size_mb(dest))


def main():
    parser = argparse.ArgumentParser(description="Download the language runtimes bundled with Commit to Me.")
    parser.add_argument("--platform", action="append", choices=sorted(PLATFORMS),
                        help="platform to download for (repeatable). Default: this computer (%s)" % host_platform())
    parser.add_argument("--all", action="store_true", help="download for every platform")
    parser.add_argument("--only", help="comma-separated subset of: " + ",".join(COMPONENTS))
    parser.add_argument("--dest", type=Path, default=DEFAULT_DEST, help="where to put runtimes (default: runtimes/)")
    parser.add_argument("--force", action="store_true", help="re-install even if already up to date")
    parser.add_argument("--list", action="store_true", help="print the pinned versions and exit")
    args = parser.parse_args()

    manifest = json.loads(MANIFEST.read_text())
    if args.list:
        for comp in COMPONENTS:
            print("%-7s %s" % (comp, manifest[comp]["version"]))
        return 0

    only = COMPONENTS
    if args.only:
        only = [c.strip() for c in args.only.split(",") if c.strip()]
        unknown = [c for c in only if c not in COMPONENTS]
        if unknown:
            parser.error("unknown component(s): %s" % ", ".join(unknown))

    platforms = sorted(PLATFORMS) if args.all else (args.platform or [host_platform()])
    for plat in platforms:
        if plat not in PLATFORMS:
            parser.error("unsupported platform %s" % plat)

    dest_root = args.dest.resolve()
    dest_root.mkdir(parents=True, exist_ok=True)
    # Downloads are cached in the project's runtimes/ folder so re-runs are fast.
    cache_dir = DEFAULT_DEST / ".downloads"
    try:
        for plat in platforms:
            fetch_platform(plat, manifest, dest_root, only, args.force, cache_dir)
    except (RuntimeError, subprocess.CalledProcessError) as e:
        print("\nERROR: %s" % e, file=sys.stderr)
        return 1
    log("\nAll set. The game will use these instead of anything installed on the computer.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
