import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
html_path = ROOT / "www.bnr.nl" / "podcasts.html"
output_dir = ROOT / "assets"
output_dir.mkdir(parents=True, exist_ok=True)
output_path = output_dir / "podcasts.json"

html = html_path.read_text(errors="ignore")
# Find all anchors linking to podcast pages
anchors = re.findall(r"<a[^>]+href=\"(podcast/[^\"]+)\"[^>]*>(.*?)</a>", html, flags=re.DOTALL | re.IGNORECASE)
entries = {}
for href, inner in anchors:
    title_match = re.search(r"<h2[^>]*>([^<]+)</h2>", inner, flags=re.IGNORECASE)
    title = title_match.group(1).strip() if title_match else None
    desc_match = re.search(r"<span[^>]*class=\"[^\"]*VerticalCard2_description[^\"]*\"[^>]*>([^<]+)</span>", inner, flags=re.IGNORECASE)
    if not desc_match:
        desc_match = re.search(r"<span[^>]*>([^<]+)</span>", inner, flags=re.IGNORECASE)
    description = desc_match.group(1).strip() if desc_match else None
    img_match = re.search(r"<img[^>]*src=\"([^\"]+)\"", inner, flags=re.IGNORECASE)
    image = img_match.group(1).strip() if img_match else None
    if not title:
        continue
    if href not in entries:
        entries[href] = {
            "title": title,
            "href": href,
            "absolute_url": f"https://www.bnr.nl/{href}",
            "description": description,
            "image": image,
        }

podcasts = list(entries.values())
podcasts.sort(key=lambda x: x.get("title", ""))

output_path.write_text(json.dumps({"podcasts": podcasts}, ensure_ascii=False, indent=2))
