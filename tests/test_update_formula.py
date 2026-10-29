import hashlib
import re
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from scripts.update_formula import FORMULA, TARGETS, release_assets, update_formula

PAYLOADS = {target: ("binary for " + target).encode() for target in TARGETS.values()}


def release(version="1.2.4"):
    assets = []
    for target, payload in PAYLOADS.items():
        name = f"nouli-{version}-{target}.tar.gz"
        assets += [
            {"name": name, "digest": "sha256:" + hashlib.sha256(payload).hexdigest()},
            {"name": name + ".sha256"},
        ]
    return {"tag_name": "v" + version, "draft": False, "prerelease": False,
            "published_at": "2026-10-29T12:00:00Z", "assets": assets}


def download(args, **kwargs):
    directory = Path(args[args.index("--dir") + 1])
    assert args[args.index("--repo") + 1] == "standing-desks/nouli"
    version = args[3][1:]
    for target, payload in PAYLOADS.items():
        name = f"nouli-{version}-{target}.tar.gz"
        (directory / name).write_bytes(payload)
        (directory / (name + ".sha256")).write_text(
            hashlib.sha256(payload).hexdigest() + "  " + name + "\n"
        )


class FormulaUpdateTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.formula = Path(self.directory.name) / "nouli.rb"
        self.source = re.sub(r'/v[0-9]+\.[0-9]+\.[0-9]+/nouli-[0-9]+\.[0-9]+\.[0-9]+-', '/v1.2.3/nouli-1.2.3-', FORMULA.read_text())
        self.formula.write_text(self.source)

    def test_requires_a_stable_published_complete_release(self):
        for change in ({"draft": True}, {"prerelease": True}, {"published_at": None},
                       {"tag_name": "v1.2.4-rc1"}, {"tag_name": "1.2.4"},
                       {"tag_name": "v01.2.4"}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                release_assets(release() | change)
        candidate = release()
        for missing in candidate["assets"]:
            with self.subTest(missing=missing["name"]), self.assertRaises(ValueError):
                release_assets(candidate | {"assets": [a for a in candidate["assets"] if a != missing]})
        with self.assertRaises(ValueError):
            release_assets(candidate | {"assets": candidate["assets"] + [candidate["assets"][0]]})

    def test_same_or_older_version_is_a_noop(self):
        with patch("scripts.update_formula.subprocess.run") as request:
            for version in ("1.2.3", "1.2.2", "1.1.9", "0.9.0"):
                self.assertEqual(update_formula(release(version), self.formula), ("1.2.3", False))
            request.assert_not_called()
        self.assertEqual(self.formula.read_text(), self.source)

    def test_updates_every_platform_after_verifying_every_download(self):
        for version in ("1.2.4", "1.3.0", "2.0.0", "10.0.0"):
            with self.subTest(version=version):
                self.formula.write_text(self.source)
                with patch("scripts.update_formula.subprocess.run", side_effect=download):
                    self.assertEqual(update_formula(release(version), self.formula), (version, True))
                contents = self.formula.read_text()
                self.assertEqual(contents.count(f'/v{version}/nouli-{version}-'), 3)
                self.assertNotIn('1.2.3', contents)
                self.assertIn('assert_equal "nouli #{version}"', contents)
                for payload in PAYLOADS.values():
                    self.assertIn(hashlib.sha256(payload).hexdigest(), contents)
                self.assertIn('depends_on arch: :arm64', contents)
                self.assertIn('bin.install "nouli"', contents)

    def test_tampered_second_download_keeps_entire_formula_unchanged(self):
        def tamper(args, **kwargs):
            download(args, **kwargs)
            directory = Path(args[args.index("--dir") + 1])
            for p in directory.glob('*linux*.tar.gz'):
                p.write_bytes(b"tampered")
        with patch("scripts.update_formula.subprocess.run", side_effect=tamper):
            with self.assertRaisesRegex(ValueError, "Checksum mismatch"):
                update_formula(release(), self.formula)
        self.assertEqual(self.formula.read_text(), self.source)

    def test_missing_duplicate_and_wrong_digest_checksums_are_rejected(self):
        def duplicate(args, **kwargs):
            download(args, **kwargs)
            directory = Path(args[args.index("--dir") + 1])
            for p in directory.glob('*.sha256'):
                p.write_text(p.read_text() * 2)
        with patch("scripts.update_formula.subprocess.run", side_effect=duplicate):
            with self.assertRaisesRegex(ValueError, "exactly one checksum"):
                update_formula(release(), self.formula)
        candidate = release()
        candidate["assets"][0]["digest"] = "sha256:" + "0" * 64
        with patch("scripts.update_formula.subprocess.run", side_effect=download):
            with self.assertRaisesRegex(ValueError, "digest disagrees"):
                update_formula(candidate, self.formula)
        self.assertEqual(self.formula.read_text(), self.source)

    def test_platform_urls_naming_different_releases_are_rejected(self):
        source = self.source.replace('/v1.2.3/nouli-1.2.3-x86_64', '/v1.2.2/nouli-1.2.2-x86_64')
        self.formula.write_text(source)
        with patch("scripts.update_formula.subprocess.run", side_effect=download):
            with self.assertRaisesRegex(ValueError, "matching formula version"):
                update_formula(release(), self.formula)
        self.assertEqual(self.formula.read_text(), source)

    def test_unexpected_formula_shape_is_not_partially_overwritten(self):
        source = self.source.replace('-x86_64-unknown-linux-gnu.tar.gz"\n', '-x86_64-unknown-linux-gnu.tar.gz" # unexpected edit\n')
        self.formula.write_text(source)
        with patch("scripts.update_formula.subprocess.run", side_effect=download):
            with self.assertRaisesRegex(ValueError, "linux-intel formula URL"):
                update_formula(release(), self.formula)
        self.assertEqual(self.formula.read_text(), source)


if __name__ == "__main__":
    unittest.main()
