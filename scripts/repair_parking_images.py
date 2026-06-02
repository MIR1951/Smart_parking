#!/usr/bin/env python3
"""
Repair Smart Parking image URLs by copying valid existing images into Supabase Storage.

Dry-run can use the app's Info.plist anon key for read-only auditing:
    python3 scripts/repair_parking_images.py --dry-run

Live repair requires:
    SUPABASE_URL=https://<project-ref>.supabase.co
    SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
    python3 scripts/repair_parking_images.py --apply
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import plistlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INFO_PLIST = PROJECT_ROOT / "Smart-parking-Info.plist"
BUCKET = "parking-images"
MIN_IMAGES = 3
HTTP_TIMEOUT = 25
USER_AGENT = "SmartParkingImageRepair/1.0"


@dataclass(frozen=True)
class ImageCheck:
    url: str
    ok: bool
    content_type: str = ""
    error: str = ""


@dataclass(frozen=True)
class DownloadedImage:
    data: bytes
    content_type: str
    extension: str


class SupabaseClient:
    def __init__(self, url: str, key: str) -> None:
        self.url = url.rstrip("/")
        self.key = key

    @property
    def headers(self) -> dict[str, str]:
        return {
            "apikey": self.key,
            "Authorization": f"Bearer {self.key}",
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        }

    def fetch_parkings(self) -> list[dict[str, Any]]:
        select = "id,name,city,thumbnail_url,images"
        endpoint = (
            f"{self.url}/rest/v1/parkings"
            f"?select={urllib.parse.quote(select)}&order=city.asc,name.asc"
        )
        request = urllib.request.Request(endpoint, headers=self.headers)
        with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT) as response:
            return json.load(response)

    def upload_storage_object(self, path: str, image: DownloadedImage) -> str:
        quoted_path = quote_storage_path(path)
        endpoint = f"{self.url}/storage/v1/object/{BUCKET}/{quoted_path}"
        headers = {
            **self.headers,
            "Content-Type": image.content_type,
            "Content-Length": str(len(image.data)),
            "x-upsert": "true",
        }
        request = urllib.request.Request(endpoint, data=image.data, headers=headers, method="POST")
        with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT) as response:
            if response.status not in (200, 201):
                raise RuntimeError(f"upload failed for {path}: HTTP {response.status}")
        return f"{self.url}/storage/v1/object/public/{BUCKET}/{quoted_path}"

    def update_parking_images(self, parking_id: str, thumbnail_url: str, images: list[str]) -> None:
        endpoint = f"{self.url}/rest/v1/parkings?id=eq.{urllib.parse.quote(parking_id)}"
        payload = json.dumps({"thumbnail_url": thumbnail_url, "images": images}).encode("utf-8")
        headers = {
            **self.headers,
            "Content-Type": "application/json",
            "Prefer": "return=minimal",
        }
        request = urllib.request.Request(endpoint, data=payload, headers=headers, method="PATCH")
        with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT) as response:
            if response.status not in (200, 204):
                raise RuntimeError(f"update failed for {parking_id}: HTTP {response.status}")


def main() -> int:
    args = parse_args()
    env = load_environment()

    if args.apply and not env.get("SUPABASE_SERVICE_ROLE_KEY"):
        print("ERROR: --apply requires SUPABASE_SERVICE_ROLE_KEY.", file=sys.stderr)
        return 2

    key = env.get("SUPABASE_SERVICE_ROLE_KEY") or env.get("SUPABASE_ANON_KEY")
    url = env.get("SUPABASE_URL")
    if not url or not key:
        print("ERROR: SUPABASE_URL and a Supabase key are required.", file=sys.stderr)
        return 2

    client = SupabaseClient(url, key)
    parkings = client.fetch_parkings()
    checks = build_url_checks(parkings)
    plans = build_repair_plans(parkings, checks)

    print_audit(parkings, checks, plans)

    broken_after_plan = [plan for plan in plans if not plan["sources"] or len(plan["sources"]) < MIN_IMAGES]
    if broken_after_plan:
        print("\nERROR: not enough valid source images to repair every parking.", file=sys.stderr)
        return 1

    if not args.apply:
        print("\nDry run only. Re-run with --apply and SUPABASE_SERVICE_ROLE_KEY to upload and update rows.")
        return 0

    failures: list[str] = []
    for index, plan in enumerate(plans, start=1):
        try:
            print(f"[{index}/{len(plans)}] repairing {plan['city']} | {plan['name']}")
            uploaded_urls = upload_plan_images(client, plan)
            client.update_parking_images(plan["id"], uploaded_urls[0], uploaded_urls)
            time.sleep(args.pause)
        except Exception as error:  # noqa: BLE001 - print all row failures and continue.
            failures.append(f"{plan['name']} ({plan['id']}): {error}")
            print(f"  ERROR: {error}", file=sys.stderr)

    if failures:
        print("\nRepair finished with failures:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("\nRepair completed successfully.")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Repair Smart Parking image URLs.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Audit and plan without uploading.")
    mode.add_argument("--apply", action="store_true", help="Upload images and update parkings rows.")
    parser.add_argument("--pause", type=float, default=0.15, help="Delay between row updates in seconds.")
    args = parser.parse_args()
    if not args.apply:
        args.dry_run = True
    return args


def load_environment() -> dict[str, str]:
    env = {
        "SUPABASE_URL": os.environ.get("SUPABASE_URL", ""),
        "SUPABASE_SERVICE_ROLE_KEY": os.environ.get("SUPABASE_SERVICE_ROLE_KEY", ""),
        "SUPABASE_ANON_KEY": os.environ.get("SUPABASE_ANON_KEY", ""),
    }

    if INFO_PLIST.exists():
        with INFO_PLIST.open("rb") as file:
            plist = plistlib.load(file)
        env["SUPABASE_URL"] = env["SUPABASE_URL"] or plist.get("SUPABASE_URL", "")
        env["SUPABASE_ANON_KEY"] = env["SUPABASE_ANON_KEY"] or plist.get("SUPABASE_ANON_KEY", "")

    return env


def build_url_checks(parkings: list[dict[str, Any]]) -> dict[str, ImageCheck]:
    urls: list[str] = []
    for parking in parkings:
        urls.extend(parking_urls(parking))

    checks: dict[str, ImageCheck] = {}
    for url in unique(urls):
        checks[url] = check_image_url(url)
    return checks


def build_repair_plans(
    parkings: list[dict[str, Any]],
    checks: dict[str, ImageCheck],
) -> list[dict[str, Any]]:
    valid_by_city: dict[str, list[str]] = {}
    global_valid: list[str] = []

    for parking in parkings:
        city = normalized_city(parking)
        valid = [url for url in parking_urls(parking) if checks.get(url, ImageCheck(url, False)).ok]
        valid_by_city.setdefault(city, []).extend(valid)
        global_valid.extend(valid)

    valid_by_city = {city: unique(urls) for city, urls in valid_by_city.items()}
    global_valid = unique(global_valid)

    plans: list[dict[str, Any]] = []
    for parking in parkings:
        city = normalized_city(parking)
        current_valid = [url for url in parking_urls(parking) if checks.get(url, ImageCheck(url, False)).ok]
        source_candidates = unique(current_valid + valid_by_city.get(city, []) + global_valid)
        selected_sources = source_candidates[: max(MIN_IMAGES, 1)]

        plans.append(
            {
                "id": parking["id"],
                "name": parking["name"],
                "city": city,
                "slug": slugify(parking["name"]),
                "sources": selected_sources,
                "needs_repair": parking_needs_repair(parking, checks),
            }
        )

    return plans


def print_audit(
    parkings: list[dict[str, Any]],
    checks: dict[str, ImageCheck],
    plans: list[dict[str, Any]],
) -> None:
    missing_thumbnail = [p for p in parkings if not clean_url(p.get("thumbnail_url"))]
    missing_gallery = [p for p in parkings if not clean_urls(p.get("images"))]
    bad_urls = [check for check in checks.values() if not check.ok]
    planned_repairs = [plan for plan in plans if plan["needs_repair"]]

    print(f"parkings={len(parkings)}")
    print(f"unique_urls={len(checks)}")
    print(f"missing_thumbnail={len(missing_thumbnail)}")
    print(f"missing_gallery={len(missing_gallery)}")
    print(f"invalid_urls={len(bad_urls)}")
    print(f"planned_repairs={len(planned_repairs)}")

    if bad_urls:
        print("\nInvalid URLs:")
        for check in bad_urls:
            print(f"- {check.error}: {check.url}")

    if planned_repairs:
        print("\nRepair plan:")
        for plan in planned_repairs:
            print(f"- {plan['city']} | {plan['name']} -> {len(plan['sources'])} storage images")


def upload_plan_images(client: SupabaseClient, plan: dict[str, Any]) -> list[str]:
    uploaded_urls: list[str] = []
    for index, source_url in enumerate(plan["sources"], start=1):
        image = download_image(source_url)
        filename = "cover" if index == 1 else str(index - 1)
        path = f"{slugify(plan['city'])}/{plan['slug']}/{filename}.{image.extension}"
        uploaded_urls.append(client.upload_storage_object(path, image))
    return uploaded_urls


def parking_needs_repair(parking: dict[str, Any], checks: dict[str, ImageCheck]) -> bool:
    thumbnail = clean_url(parking.get("thumbnail_url"))
    images = clean_urls(parking.get("images"))
    if not thumbnail or len(images) < MIN_IMAGES:
        return True
    return any(not checks.get(url, ImageCheck(url, False)).ok for url in [thumbnail, *images])


def parking_urls(parking: dict[str, Any]) -> list[str]:
    return unique([clean_url(parking.get("thumbnail_url")), *clean_urls(parking.get("images"))])


def check_image_url(url: str) -> ImageCheck:
    if not url:
        return ImageCheck(url, False, error="empty")

    for method in ("HEAD", "GET"):
        try:
            headers = {"User-Agent": USER_AGENT}
            if method == "GET":
                headers["Range"] = "bytes=0-0"
            request = urllib.request.Request(url, headers=headers, method=method)
            with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT) as response:
                content_type = response.headers.get("content-type", "")
                if response.status >= 400:
                    return ImageCheck(url, False, content_type, f"HTTP {response.status}")
                if "image" not in content_type.lower():
                    return ImageCheck(url, False, content_type, f"non-image {content_type}")
                return ImageCheck(url, True, content_type)
        except urllib.error.HTTPError as error:
            if method == "HEAD" and error.code in (405, 403):
                continue
            return ImageCheck(url, False, error=str(error))
        except Exception as error:  # noqa: BLE001
            if method == "HEAD":
                continue
            return ImageCheck(url, False, error=str(error))

    return ImageCheck(url, False, error="unreachable")


def download_image(url: str) -> DownloadedImage:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT) as response:
        data = response.read()
        content_type = response.headers.get("content-type", "image/jpeg").split(";")[0].strip()
        if "image" not in content_type.lower():
            raise RuntimeError(f"not an image: {url} ({content_type})")
        extension = extension_for(content_type, url)
        return DownloadedImage(data=data, content_type=content_type, extension=extension)


def extension_for(content_type: str, url: str) -> str:
    guessed = mimetypes.guess_extension(content_type.split(";")[0].strip()) or ""
    if guessed:
        return guessed.lstrip(".").replace("jpeg", "jpg")
    path_extension = Path(urllib.parse.urlparse(url).path).suffix.lstrip(".")
    return path_extension or "jpg"


def quote_storage_path(path: str) -> str:
    return "/".join(urllib.parse.quote(part) for part in path.split("/"))


def clean_url(value: Any) -> str:
    return value.strip() if isinstance(value, str) else ""


def clean_urls(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [url.strip() for url in value if isinstance(url, str) and url.strip()]


def unique(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        if value and value not in seen:
            seen.add(value)
            result.append(value)
    return result


def normalized_city(parking: dict[str, Any]) -> str:
    city = clean_url(parking.get("city"))
    return city or "unknown"


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower())
    slug = re.sub(r"-+", "-", slug).strip("-")
    return slug or "parking"


if __name__ == "__main__":
    raise SystemExit(main())
