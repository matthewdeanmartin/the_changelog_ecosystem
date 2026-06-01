from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urldefrag, urljoin, urlparse

import requests
import requests_cache


SKIPPED_SCHEMES = {"data", "mailto", "tel", "javascript", "sms"}


@dataclass(frozen=True)
class Link:
    source: Path
    tag: str
    attr: str
    url: str


class LinkParser(HTMLParser):
    def __init__(self, source: Path) -> None:
        super().__init__(convert_charrefs=True)
        self.source = source
        self.links: list[Link] = []
        self.anchors: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr = {name.lower(): value or "" for name, value in attrs}
        for id_attr in ("id", "name"):
            if attr.get(id_attr):
                self.anchors.add(attr[id_attr])

        for link_attr in ("href", "src"):
            value = attr.get(link_attr, "").strip()
            if value:
                self.links.append(Link(self.source, tag.lower(), link_attr, value))


def parse_site(site_dir: Path) -> tuple[dict[Path, LinkParser], list[Link]]:
    documents: dict[Path, LinkParser] = {}
    links: list[Link] = []
    for html_file in sorted(site_dir.rglob("*.html")):
        parser = LinkParser(html_file)
        parser.feed(html_file.read_text(encoding="utf-8"))
        documents[html_file.resolve()] = parser
        links.extend(parser.links)
    return documents, links


def local_target(site_dir: Path, source: Path, url: str) -> tuple[Path, str]:
    path_part, fragment = urldefrag(url)
    parsed = urlparse(path_part)

    if parsed.path.startswith("/"):
        target = site_dir / unquote(parsed.path.lstrip("/"))
    elif parsed.path:
        target = source.parent / unquote(parsed.path)
    else:
        target = source

    if parsed.path.endswith("/") or not target.suffix:
        target = target / "index.html"

    return target.resolve(), fragment


def check_local_link(site_dir: Path, documents: dict[Path, LinkParser], link: Link) -> str | None:
    target, fragment = local_target(site_dir, link.source, link.url)
    rel_source = link.source.relative_to(site_dir)

    if not target.exists():
        return f"{rel_source}: {link.url} -> missing local target {target}"
    if target.is_dir():
        return f"{rel_source}: {link.url} -> points to a directory, not a file"

    if fragment:
        target_parser = documents.get(target)
        if target_parser and fragment not in target_parser.anchors:
            return f"{rel_source}: {link.url} -> missing fragment #{fragment}"

    return None


def check_external_link(
    session: requests.Session,
    site_dir: Path,
    link: Link,
    timeout: float,
    allowed_statuses: set[int],
) -> str | None:
    url, _fragment = urldefrag(link.url)
    headers = {"User-Agent": "the-changelog-ecosystem-linkcheck/1.0"}
    response: requests.Response | None = None
    rel_source = link.source.relative_to(site_dir)

    try:
        response = session.head(url, allow_redirects=True, timeout=timeout, headers=headers)
        if response.status_code in allowed_statuses:
            return None
        if response.status_code >= 400:
            response.close()
            response = session.get(url, allow_redirects=True, timeout=timeout, headers=headers, stream=True)
        if response.status_code in allowed_statuses:
            return None
        if response.status_code >= 400:
            return f"{rel_source}: {link.url} -> HTTP {response.status_code}"
    except requests.RequestException as exc:
        return f"{rel_source}: {link.url} -> {exc.__class__.__name__}: {exc}"
    finally:
        if response is not None:
            response.close()

    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Check generated site links, with cached external requests.")
    parser.add_argument("--site-dir", default="output", type=Path)
    parser.add_argument("--cache", default=".cache/linkcheck.sqlite", type=Path)
    parser.add_argument("--timeout", default=12.0, type=float)
    parser.add_argument("--expire-after", default=604800, type=int, help="external cache TTL in seconds")
    parser.add_argument("--internal-only", action="store_true", help="skip external HTTP(S) links")
    parser.add_argument(
        "--allow-status",
        action="append",
        type=int,
        default=[403],
        help="HTTP status to treat as inconclusive rather than broken; repeatable",
    )
    args = parser.parse_args()

    site_dir = args.site_dir.resolve()
    if not site_dir.exists():
        print(f"{site_dir}: site output directory does not exist; run make html first")
        return 1

    documents, links = parse_site(site_dir)
    if not documents:
        print(f"{site_dir}: no HTML files found")
        return 1

    args.cache.parent.mkdir(parents=True, exist_ok=True)
    session = requests_cache.CachedSession(
        str(args.cache),
        allowable_methods=("GET", "HEAD"),
        expire_after=args.expire_after,
        stale_if_error=True,
    )

    errors: list[str] = []
    checked_external: set[str] = set()
    external_count = 0
    internal_count = 0

    for link in links:
        parsed = urlparse(link.url)
        if parsed.scheme in SKIPPED_SCHEMES or link.url.startswith("#"):
            continue

        if parsed.scheme in {"http", "https"}:
            if args.internal_only:
                continue
            absolute_url = urldefrag(link.url)[0]
            if absolute_url in checked_external:
                continue
            checked_external.add(absolute_url)
            external_count += 1
            error = check_external_link(session, site_dir, link, args.timeout, set(args.allow_status))
            if error:
                errors.append(error)
            continue

        if parsed.scheme:
            continue

        internal_count += 1
        error = check_local_link(site_dir, documents, link)
        if error:
            errors.append(error)

    if errors:
        print("Link check failed:")
        for error in errors:
            print(f"  - {error}")
        return 1

    cache_note = "external links skipped" if args.internal_only else f"{external_count} external links checked"
    print(f"Link check passed ({internal_count} internal links checked, {cache_note}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
