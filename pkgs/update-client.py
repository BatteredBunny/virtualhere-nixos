#!/usr/bin/env python3
import argparse
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from urllib.request import urlopen

CLIENT_PAGE = "https://www.virtualhere.com/usb_client_software"
UPSTREAM_BASE = "https://www.virtualhere.com/sites/default/files/usbclient/"
BINARIES = {
    "cli": ("vhclientx86_64", "vhclientarm64"),
    "gui": ("vhuit64", "vhuitarm64"),
}
VERSION = re.compile(r'(?m)^(\s*version\s*=\s*)"([^"]+)";')


class UpdateError(Exception):
    pass


# The download page includes the latest version number
def latest_version():
    with urlopen(CLIENT_PAGE, timeout=60) as response:
        page = response.read().decode("utf-8")
    versions = re.findall(
        r"<strong>\s*Version\s+([0-9]+\.[0-9]+\.[0-9]+)\s*</strong>",
        page,
        flags=re.IGNORECASE,
    )
    if len(set(versions)) != 1:
        raise UpdateError("Can't find version number")

    return versions[0]


def prefetch_hash(url):
    output = subprocess.check_output(
        ["nix", "store", "prefetch-file", "--refresh", url, "--json"], text=True
    )
    result = json.loads(output)
    if not isinstance(result, dict):
        raise UpdateError(f"Invalid metadata for {url}")
    value = result.get("hash")
    if not isinstance(value, str) or not re.fullmatch(
        r"sha256-[A-Za-z0-9+/]{43}=", value
    ):
        raise UpdateError(f"Invalid SHA-256 hash for {url}")
    return value


def archive_url(upstream_url):
    with urlopen(
        f"https://web.archive.org/save/{upstream_url}", timeout=120
    ) as response:
        saved_url = response.geturl()
    match = re.fullmatch(
        r"https://web\.archive\.org/web/([0-9]{14})(?:id_)?/(.+)", saved_url
    )
    if match is None:
        raise UpdateError(f"archive.org save did not return a snapshot: {saved_url}")
    timestamp, source = match.groups()
    if source != upstream_url:
        raise UpdateError(f"archive.org returned a different source: {saved_url}")
    return f"https://web.archive.org/web/{timestamp}id_/{upstream_url}"


def attribute(body, name):
    pattern = re.compile(rf'\b{re.escape(name)}\s*=\s*"([^"]+)";')
    matches = list(pattern.finditer(body))
    if len(matches) != 1:
        raise UpdateError(f"expected exactly one {name} in the source definition")
    return matches[0]


def replace_attribute(body, name, value):
    match = attribute(body, name)
    start, end = match.span(1)
    return body[:start] + value + body[end:]


def update_binary(contents, binary):
    pattern = re.compile(rf"(?ms)^\s*{re.escape(binary)}\s*=\s*\{{(.*?)^\s*\}};")
    matches = list(pattern.finditer(contents))
    if len(matches) != 1:
        raise UpdateError(f"expected exactly one source definition for {binary}")
    match = matches[0]
    body = match.group(1)
    current_url = attribute(body, "url").group(1)
    current_hash = attribute(body, "hash").group(1)
    upstream_url = UPSTREAM_BASE + binary

    print(f"{binary}: checking upstream...", flush=True)
    upstream_hash = prefetch_hash(upstream_url)
    final_url = current_url
    archive_hash = None
    if current_url.startswith("https://web.archive.org/web/"):
        print(f"{binary}: verifying current archive.org URL...", flush=True)
        archive_hash = prefetch_hash(current_url)

    if archive_hash != upstream_hash:
        print(f"{binary}: saving to archive.org...", flush=True)
        final_url = archive_url(upstream_url)
        archive_hash = prefetch_hash(final_url)
        if archive_hash != upstream_hash:
            raise UpdateError(
                f"{binary}: saved archive does not match upstream; retry later "
                f"(archive: {archive_hash}, upstream: {upstream_hash})"
            )
        print(f"{binary}: archived at {final_url}", flush=True)
    elif current_hash == archive_hash:
        print(f"{binary}: already up-to-date ({archive_hash})", flush=True)
    else:
        print(f"{binary}: repaired recorded hash ({archive_hash})", flush=True)

    body = replace_attribute(body, "url", final_url)
    body = replace_attribute(body, "hash", archive_hash)
    start, end = match.span(1)
    return contents[:start] + body + contents[end:]


def update(package, force=False, commit=False):
    package_name = f"virtualhere-client-{package}"
    package_dir = Path(__file__).resolve().parent / package_name
    original = package_dir / "default.nix"
    contents = original.read_text()
    version_matches = list(VERSION.finditer(contents))
    if len(version_matches) != 1:
        raise UpdateError("expected exactly one package version")
    old_version = version_matches[0].group(2)
    version = latest_version()
    if old_version == version and not force:
        print(f"{package_name}: already at {version} (use --force to verify sources)")
        return

    with tempfile.TemporaryDirectory(
        dir=package_dir, prefix=".virtualhere-update-"
    ) as work_dir:
        staged_file = Path(work_dir) / "default.nix"
        shutil.copy2(original, staged_file)
        for binary in BINARIES[package]:
            contents = update_binary(contents, binary)
        contents = VERSION.sub(lambda match: f'{match.group(1)}"{version}";', contents)
        staged_file.write_text(contents)
        subprocess.run(["nixfmt", str(staged_file)], check=True)

        if staged_file.read_bytes() == original.read_bytes():
            print(f"{package_name}: no changes")
            return

        staged_file.replace(original)
        print(f"{package_name}: updated to {version}")

    if commit:
        if old_version == version:
            message = f"{package_name}: update sources"
        else:
            message = f"{package_name} {old_version} -> {version}"
        subprocess.run(
            ["git", "commit", "--message", message, "--", str(original)],
            cwd=package_dir,
            check=True,
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", choices=BINARIES)
    parser.add_argument(
        "--force",
        action="store_true",
        help="verify sources even if the version matches",
    )
    parser.add_argument(
        "--commit",
        action="store_true",
        help="commit the updated package to git",
    )
    args = parser.parse_args()
    try:
        update(args.package, args.force, args.commit)
    except (
        UpdateError,
        OSError,
        ValueError,
        subprocess.CalledProcessError,
    ) as error:
        parser.exit(1, f"virtualhere-client-{args.package}: ERROR - {error}\n")


if __name__ == "__main__":
    main()
