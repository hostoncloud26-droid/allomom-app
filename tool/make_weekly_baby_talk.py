"""Builds lib/seeds/weekly_baby_talk.json from the Baby Talk audio-script sheet.

    python3 tool/make_weekly_baby_talk.py

The sheet (lib/seeds/Baby_Talk_1000_Days_142W_Audio_Scripts.xlsx) is the
source of truth: rerun this after editing it. Weeks 1-40 are pregnancy from the
LMP, 41 is birth, and from 42 the baby is (week - 41) weeks old.
"""

import json
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "lib/seeds/Baby_Talk_1000_Days_142W_Audio_Scripts.xlsx"
TARGET = ROOT / "lib/seeds/weekly_baby_talk.json"

# sheet column -> (voice, language code as AppLanguage stores it)
COLUMNS = {
    "mom_english_audio": ("mom", "en"),
    "mom_tamil_audio": ("mom", "ta"),
    "mom_hindi_audio": ("mom", "hi"),
    "dad_english_audio": ("dad", "en"),
    "dad_tamil_audio": ("dad", "ta"),
    "dad_hindi_audio": ("dad", "hi"),
}


def main() -> None:
    sheet = openpyxl.load_workbook(SOURCE, read_only=True)["Audio_Scripts_142W"]
    rows = sheet.iter_rows(values_only=True)
    header = [str(h).strip() for h in next(rows)]

    weeks = {}
    for row in rows:
        record = dict(zip(header, row))
        if record.get("week") is None:
            continue
        week = int(record["week"])
        entry = {"mom": {}, "dad": {}}
        for column, (voice, lang) in COLUMNS.items():
            text = (record.get(column) or "").strip()
            if text:
                entry[voice][lang] = text
        weeks[str(week)] = entry

    TARGET.write_text(json.dumps(weeks, ensure_ascii=False, indent=1) + "\n")
    print(f"wrote {len(weeks)} weeks to {TARGET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
