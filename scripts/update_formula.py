#!/usr/bin/env python3
"""Update the Nouli formula from published, checksummed release archives."""

import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

from scripts.update_cask import verified_checksum, version_tuple

UPSTREAM = "standing-desks/nouli"
FORMULA = Path(__file__).resolve().parents[1] / "Formula/nouli.rb"
TARGETS = {"macos": "aarch64-apple-darwin", "linux": "aarch64-unknown-linux-gnu"}


def release_assets(release):
    if release["draft"] or release["prerelease"] or not release["published_at"]:
        raise ValueError("Only published stable releases can update the formula")
    tag = release["tag_name"]
    if not tag.startswith("v"):
        raise ValueError("Expected a vMAJOR.MINOR.PATCH tag")
    version = tag[1:]
    version_tuple(version)
    assets = {}
    for platform, target in TARGETS.items():
        name = f"nouli-{version}-{target}.tar.gz"
        for filename in (name, name + ".sha256"):
            matches = [a for a in release["assets"] if a["name"] == filename]
            if len(matches) != 1:
                raise ValueError(f"Expected exactly one release asset: {filename}")
            assets[filename] = matches[0]
    return version, assets


def update_formula(release, formula=FORMULA):
    version, assets = release_assets(release)
    contents = formula.read_text()
    current = re.findall(r'/releases/download/v([0-9]+\.[0-9]+\.[0-9]+)/nouli-\1-aarch64-', contents)
    if len(current) != 2 or len(set(current)) != 1:
        raise ValueError("Expected matching formula versions in both platform URLs")
    if version_tuple(version) <= version_tuple(current[0]):
        print(f"Keeping Nouli {current[0]}; selected release is {version}")
        return current[0], False

    checksums = {}
    with tempfile.TemporaryDirectory(prefix="nouli-formula-") as directory:
        patterns = [value for name in assets for value in ("--pattern", name)]
        subprocess.run(
            ["gh", "release", "download", release["tag_name"], "--repo", UPSTREAM,
             *patterns, "--dir", directory], check=True,
        )
        for platform, target in TARGETS.items():
            name = f"nouli-{version}-{target}.tar.gz"
            checksums[platform] = verified_checksum(
                Path(directory) / name, Path(directory) / (name + ".sha256"), assets[name]
            )

    for platform, target in TARGETS.items():
        url = (f"https://github.com/{UPSTREAM}/releases/download/v{current[0]}/"
               f"nouli-{current[0]}-{target}.tar.gz")
        condition = "if OS.mac?" if platform == "macos" else "elsif OS.linux?"
        pattern = (rf'(  {re.escape(condition)}\n    url "{re.escape(url)}"\n'
                   rf'    sha256 ")[0-9a-f]{{64}}(")')
        new_url = url.replace(f"/v{current[0]}/nouli-{current[0]}-", f"/v{version}/nouli-{version}-")
        contents, count = re.subn(
            pattern, lambda match: match[1].replace(url, new_url) + checksums[platform] + match[2], contents
        )
        if count != 1:
            raise ValueError(f"Expected exactly one {platform} formula URL and checksum")
    temporary = formula.with_suffix(".rb.tmp")
    temporary.write_text(contents)
    temporary.replace(formula)
    print(f"Updated Nouli {current[0]} to {version}; both archive SHA-256 checksums verified")
    return version, True


def main():
    tag = os.environ.get("RELEASE_TAG", "")
    if tag:
        if not tag.startswith("v"):
            raise ValueError("RELEASE_TAG must be vMAJOR.MINOR.PATCH")
        version_tuple(tag[1:])
    endpoint = f"repos/{UPSTREAM}/releases/" + (f"tags/{tag}" if tag else "latest")
    response = subprocess.run(["gh", "api", endpoint], check=True, capture_output=True, text=True)
    version, changed = update_formula(json.loads(response.stdout))
    if output := os.environ.get("GITHUB_OUTPUT"):
        with Path(output).open("a") as stream:
            stream.write(f"version={version}\nchanged={str(changed).lower()}\n")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from error
