from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOGS = {
    "localization/translations_en_fr.csv": ("en", "fr"),
    "localization/translations_it_de_es.csv": ("it", "de", "es"),
    "localization/translations_ja_ko_ru_zh_CN.csv": ("ja", "ko", "ru", "zh_CN"),
}
OUTPUT = ROOT / "localization/translations.csv"
LANGUAGES = ("pt_BR", "en", "fr", "it", "de", "es_ES", "ja", "ko", "ru", "zh_CN")
EXTRA = {
    "Idioma": {
        "pt_BR": "Idioma", "en": "Language", "fr": "Langue", "it": "Lingua",
        "de": "Sprache", "es_ES": "Idioma", "ja": "言語", "ko": "언어",
        "ru": "Язык", "zh_CN": "语言",
    },
}


def read_catalog(path: Path, expected: tuple[str, ...]) -> dict[str, dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if tuple(reader.fieldnames or ()) != ("keys", *expected):
            raise ValueError(f"{path.name}: expected columns keys,{','.join(expected)}")
        out: dict[str, dict[str, str]] = {}
        for row in reader:
            key = row["keys"]
            if not key:
                raise ValueError(f"{path.name}: empty source key")
            if key in out:
                raise ValueError(f"{path.name}: duplicate key {key!r}")
            out[key] = {lang: row[lang] for lang in expected}
            if any(not value for value in out[key].values()):
                raise ValueError(f"{path.name}: empty translation for {key!r}")
        return out


def main() -> None:
    catalogues: dict[str, dict[str, dict[str, str]]] = {}
    expected_keys: set[str] | None = None
    for rel_path, langs in CATALOGS.items():
        catalogue = read_catalog(ROOT / rel_path, langs)
        keys = set(catalogue)
        if expected_keys is None:
            expected_keys = keys
        elif keys != expected_keys:
            missing = sorted(expected_keys - keys)
            extra = sorted(keys - expected_keys)
            raise ValueError(f"{rel_path}: key set differs; missing={missing[:5]}, extra={extra[:5]}")
        catalogues[rel_path] = catalogue

    rows: dict[str, dict[str, str]] = {}
    for key in sorted(expected_keys or set()):
        row = {lang: "" for lang in LANGUAGES}
        row["keys"] = key
        row["pt_BR"] = key
        for path, languages in CATALOGS.items():
            for lang in languages:
                target = "es_ES" if lang == "es" else lang
                row[target] = catalogues[path][key][lang]
        rows[key] = row
    for key, values in EXTRA.items():
        row = {lang: "" for lang in LANGUAGES}
        row["keys"] = key
        row.update(values)
        rows[key] = row

    with OUTPUT.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=("keys", *LANGUAGES), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows[key] for key in sorted(rows))
    print(f"Wrote {len(rows)} localized keys to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
