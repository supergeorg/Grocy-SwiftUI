#!/usr/bin/env python3
"""Prints the UDID of an iPhone simulator whose iOS runtime meets the app's deployment target.

The CI runner image can lag behind the deployment target (IPHONEOS_DEPLOYMENT_TARGET in the project).
In that case the newest iOS runtime is downloaded with `xcodebuild -downloadPlatform iOS`, and an
iPhone simulator is created on it if there is none yet.
"""

import json
import re
import subprocess
import sys

PROJECT = "Grocy Mobile.xcodeproj/project.pbxproj"


def version(text):
    return tuple(int(n) for n in re.findall(r"\d+", text))


def simctl_json(*args):
    return json.loads(subprocess.run(["xcrun", "simctl", "list", *args, "--json"], check=True, capture_output=True, text=True).stdout)


def ios_runtimes(required):
    runtimes = [r for r in simctl_json("runtimes", "available")["runtimes"] if r.get("platform") == "iOS" and r.get("isAvailable", True)]
    return sorted((r for r in runtimes if version(r["version"]) >= required), key=lambda r: version(r["version"]), reverse=True)


def find_iphone(runtimes):
    devices = simctl_json("devices", "available")["devices"]
    for runtime in runtimes:
        for device in devices.get(runtime["identifier"], []):
            if device["name"].startswith("iPhone"):
                return runtime, device["udid"]
    return None


def main():
    with open(PROJECT, encoding="utf-8") as project:
        required = version(re.search(r"IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);", project.read()).group(1))
    print(f"Deployment target: iOS {'.'.join(map(str, required))}", file=sys.stderr)

    runtimes = ios_runtimes(required)
    if not runtimes:
        print("No installed iOS runtime meets the deployment target. Downloading the newest one.", file=sys.stderr)
        subprocess.run(["xcodebuild", "-downloadPlatform", "iOS"], check=True, stdout=sys.stderr)
        runtimes = ios_runtimes(required)
    if not runtimes:
        sys.exit("error: no iOS runtime meets the deployment target, even after downloading.")

    found = find_iphone(runtimes)
    if found is None:
        runtime = runtimes[0]
        device_type = next(
            (t for t in reversed(runtime.get("supportedDeviceTypes", [])) if t["name"].startswith("iPhone")),
            None,
        )
        if device_type is None:
            sys.exit(f"error: {runtime['name']} supports no iPhone.")
        print(f"Creating a {device_type['name']} on {runtime['name']}.", file=sys.stderr)
        udid = subprocess.run(
            ["xcrun", "simctl", "create", f"CI {device_type['name']}", device_type["identifier"], runtime["identifier"]],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        found = (runtime, udid)

    runtime, udid = found
    print(f"Using {udid} on {runtime['name']}.", file=sys.stderr)
    print(udid)


if __name__ == "__main__":
    main()
