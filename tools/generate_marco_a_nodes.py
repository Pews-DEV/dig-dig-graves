"""Regenerate the Marco A SkillNodeData resources from the GDD tables."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GDD = ROOT / "docs" / "01_GDD.md"
OUT = ROOT / "data" / "skill_nodes"

EFFECTS: dict[str, tuple[tuple[str, int, float], ...]] = {
    "E01": (("damage", 0, 1.0),),
    "E02": (("pulse_interval", 1, 0.95),),
    "E03": (("area_step", 0, 1.0),),
    "E04": (("crit_chance", 0, 0.04),),
    "E05": (("crit_mult", 0, 0.5),),
    "E06": (("area_step", 0, 1.0),),
    "E07": (("deep_mult", 1, 1.2),),
    "E08": (("damage", 0, 3.0),),
    "E09": (("pulse_interval", 1, 0.96),),
    "E10": (("stomp_enabled", 0, 1.0),),
    "E11": (("stomp_cd", 0, -1.0),),
    "E12a": (("stomp_ring", 0, 1.0),),
    "E12b": (("stomp_auto", 0, 1.0),),
    "E13": (("excess_carries", 0, 1.0),),
    "E14": (("area_step", 0, 1.0),),
    "EX": (("area_step", 0, 1.0), ("double_hit", 0, 1.0)),
    "L01": (("oil_max", 0, 2.0),),
    "L02": (("wisp_oil", 0, 0.5),),
    "L03": (("wisp_rate", 1, 1.12),),
    "L04": (("oil_per_grave", 0, 0.5), ("oil_grave_cap", 0, 1.0)),
    "L06": (("second_wind", 0, 1.0),),
    "L08": (("oil_max", 0, 3.0),),
    "L09": (("oil_burn", 1, 0.95),),
    "L10": (("wisp_life", 0, 1.0),),
    "LX": (("oil_max", 0, 8.0), ("constellation", 0, 1.0)),
    "S01": (("all_mult", 0, 0.05),),
    "S04": (("wanderers", 0, 1.0),),
    "S07": (("soul_mult", 0, 0.2),),
    "F01": (("copper_mult", 0, 0.08),),
    "F02": (("bone_chance", 0, 0.02),),
    "F04": (("grave_interest", 0, 0.01),),
    "F05": (("inheritance", 0, 0.05),),
    "F08": (("copper_mult", 1, 1.25),),
    "F09": (("gold_coin", 0, 1.0),),
    "F10": (("copper_mult", 0, 0.12),),
    "C01": (("field_size", 0, 1.0),),
    "C02": (("grave_count", 0, 1.0),),
    "C03": (("regen_time", 1, 0.9),),
    "C04": (("grave_reward", 0, 0.25),),
    "C06": (("candles", 0, 1.0),),
    "C08": (("ossuary_layer", 0, 1.0),),
    "C10": (("unrest_mult", 0, 0.1),),
}

FLAGS: dict[str, tuple[str, ...]] = {
    "N01": ("stat_sheet",),
    "E10": ("stomp",),
    "E12a": ("stomp_ring",),
    "E12b": ("stomp_auto",),
    "E13": ("excess_carries",),
    "EX": ("double_hit",),
    "L06": ("second_wind",),
    "LX": ("constellation",),
    "S04": ("wanderers",),
    "F09": ("gold_coin",),
    "C06": ("candles",),
    "C08": ("ossuary_layer",),
}

TRIGGERS = {"N01": "turn_2", "S01": "first_soul", "N03": "boss_1"}
EXCLUSIVE = {"E12a": "E12", "E12b": "E12", "C09a": "C09", "C09b": "C09"}
BRANCH = {"N": 0, "E": 1, "L": 2, "F": 3, "C": 4, "A": 5, "S": 6}
ICON_BASE = {
    "N00": (0, 0), "N01": (1, 0), "E01": (3, 0), "E02": (4, 0),
    "E03": (5, 0), "E04": (6, 0), "E05": (7, 0), "E10": (0, 1),
    "L01": (1, 1), "L02": (2, 1), "L03": (3, 1), "L04": (4, 1),
    "F01": (5, 1), "F02": (6, 1), "F04": (0, 2), "C01": (1, 2),
    "C02": (2, 2), "C03": (3, 2), "S01": (7, 2),
}


def clean(value: str) -> str:
    return re.sub(r"\*\*|`", "", value).strip()


def number(value: str, default: float = 0.0) -> float:
    value = clean(value).replace(" ", "")
    if not value or value in {"—", "-"}:
        return default
    if value == "grátis":
        return 0.0
    value = value.replace("×", "").replace("ⁿ", "")
    if "," in value:
        value = value.replace(".", "").replace(",", ".")
    else:
        value = value.replace(".", "")
    match = re.search(r"-?\d+(?:\.\d+)?", value)
    return float(match.group()) if match else default


def prerequisites(value: str) -> tuple[list[tuple[str, int]], list[str], str]:
    value = clean(value)
    trigger = ""
    for phrase, name in (("2º turno", "turn_2"), ("1ª Alma", "first_soul"), ("após o chefe 1", "boss_1")):
        if phrase in value:
            trigger = name
            value = value.replace("· " + phrase, "").replace(phrase, "")
    all_reqs: list[tuple[str, int]] = []
    any_reqs: list[str] = []
    for piece in re.split(r"\s*\+\s*", value):
        piece = piece.strip()
        if not piece:
            continue
        if " ou " in piece:
            any_reqs.extend(re.findall(r"\b[A-Z]{1,2}\d{1,2}[a-z]?\b", piece))
            continue
        match = re.search(r"\b([A-Z]{1,2}\d{1,2}[a-z]?)\b(?:\s+Nv(\d+))?", piece)
        if match:
            all_reqs.append((match.group(1), int(match.group(2) or 1)))
    return all_reqs, any_reqs, trigger


def parse_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for line in GDD.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = [clean(cell) for cell in line.strip().strip("|").split("|")]
        if len(cells) != 12 or cells[0] in {"Id", "---"} or cells[10] != "A":
            continue
        node_id = cells[0]
        if not re.fullmatch(r"(?:[A-Z]{1,2}\d{1,2}[a-z]?|[ELFSCA]X)", node_id):
            continue
        all_reqs, any_reqs, trigger = prerequisites(cells[8])
        grid_match = re.search(r"\((-?\d+),\s*(-?\d+)\)", cells[11])
        grid = (int(grid_match.group(1)), int(grid_match.group(2))) if grid_match else (0, 0)
        max_level = int(number(cells[4], 1))
        base_text = cells[6].split("×", 1)[0].strip()
        base_cost = number(base_text)
        growth = number(cells[7], 1.0)
        if "×3ⁿ" in cells[6]:
            growth = 3.0
        currency = {"Cobre": "copper", "Ossos": "bones", "Almas": "souls"}.get(cells[5], "copper")
        branch = BRANCH[node_id[0]]
        if node_id in {"EX", "LX", "FX", "CX", "AX", "SX", "N05"}:
            kind = "M" if node_id[-1] == "X" else "R"
        else:
            kind = {"—": "", "P": "P", "At": "At", "R": "R", "D": "D", "X": "X"}.get(cells[2], "P")
        rows.append({
            "id": node_id, "name": cells[1], "kind": kind, "description": cells[3],
            "max": max_level, "currency": currency, "cost": base_cost, "growth": growth,
            "requires": all_reqs, "requires_any": any_reqs, "trigger": trigger or TRIGGERS.get(node_id, ""),
            "grid": grid, "branch": branch, "exclusive": EXCLUSIVE.get(node_id, ""),
            "stage": int(number(cells[9], 1)), "starts_owned": node_id == "N00",
        })
    return rows


def emit(rows: list[dict[str, object]]) -> None:
    children: dict[str, list[str]] = {str(row["id"]): [] for row in rows}
    by_id = {str(row["id"]): row for row in rows}

    def depends_on(node_id: str, ancestor_id: str, seen: set[str] | None = None) -> bool:
        if node_id == ancestor_id:
            return True
        visited = set() if seen is None else seen
        if node_id in visited or node_id not in by_id:
            return False
        visited.add(node_id)
        row = by_id[node_id]
        parents = [req_id for req_id, _ in row["requires"]]  # type: ignore[union-attr]
        parents.extend(row["requires_any"])  # type: ignore[arg-type]
        return any(depends_on(parent, ancestor_id, visited) for parent in parents)

    for row in rows:
        parent_ids = [req_id for req_id, _ in row["requires"]]  # type: ignore[union-attr]
        parent_ids.extend(row["requires_any"])  # type: ignore[arg-type]
        # Não desenhar uma raiz redundante que atravesse outro requisito intermediário.
        for req_id in parent_ids:
            redundant = any(other != req_id and depends_on(other, req_id) for other in parent_ids)
            if req_id in children and not redundant:
                children[req_id].append(str(row["id"]))

    ext_script = '[ext_resource type="Script" path="res://data/types/skill_node_data.gd" id="1_node"]'
    mod_script = '[ext_resource type="Script" path="res://data/types/stat_modifier.gd" id="2_mod"]'
    for row in rows:
        node_id = str(row["id"])
        lines = ["[gd_resource type=\"Resource\" script_class=\"SkillNodeData\" format=3]", "", ext_script, mod_script]
        effects = EFFECTS.get(node_id, ())
        for index, _ in enumerate(effects):
            lines.extend(["", f"[sub_resource type=\"Resource\" id=\"StatModifier_{index}\"]", 'script = ExtResource("2_mod")'])
            stat, op, value = effects[index]
            lines.append(f'stat = &"{stat}"')
            if op:
                lines.append(f"op = {op}")
            lines.append(f"value = {value}")
        lines.extend(["", "[resource]", 'script = ExtResource("1_node")', f'id = &"{node_id}"', f'display_name = "{row["name"]}"', f'description = "{row["description"]}"', f'branch = {row["branch"]}', f'kind = &"{row["kind"]}"'])
        lines.extend([f'max_level = {row["max"]}', f'base_cost = {row["cost"]}', f'cost_growth = {row["growth"]}', f'currency = &"{row["currency"]}"'])
        if effects:
            refs = ", ".join(f'SubResource("StatModifier_{i}")' for i in range(len(effects)))
            lines.append(f'modifiers_per_level = Array[ExtResource("2_mod")]([{refs}])')
        child_ids = children[node_id]
        if child_ids:
            lines.append('children = Array[StringName]([' + ", ".join(f'&"{cid}"' for cid in child_ids) + '])')
        reqs = row["requires"]
        if reqs:
            entries = ", ".join('{"id": &"%s", "level": %d}' % (rid, level) for rid, level in reqs)  # type: ignore[union-attr]
            lines.append(f'requires = Array[Dictionary]([{entries}])')
        any_reqs = row["requires_any"]
        if any_reqs:
            lines.append('requires_any = Array[StringName]([' + ", ".join(f'&"{rid}"' for rid in any_reqs) + '])')
        if row["trigger"]:
            lines.append(f'reveal_trigger = &"{row["trigger"]}"')
        if row["exclusive"]:
            lines.append(f'exclusive_group = &"{row["exclusive"]}"')
        flags = FLAGS.get(node_id, ())
        if flags:
            lines.append('flags = Array[StringName]([' + ", ".join(f'&"{flag}"' for flag in flags) + '])')
        fallback_icons = {0: (0, 0), 1: (3, 0), 2: (1, 1), 3: (5, 1), 4: (1, 2), 5: (7, 2), 6: (7, 2)}
        icon_x, icon_y = ICON_BASE.get(node_id, fallback_icons[int(row["branch"])])
        lines.append(f'icon_cell = Vector2i({icon_x}, {icon_y})')
        grid_x, grid_y = row["grid"]  # type: ignore[misc]
        lines.extend([f'grid = Vector2i({grid_x}, {grid_y})', f'required_stage = {row["stage"]}', f'required_area = {row["stage"]}', f'tree_position = Vector2({968 + 88 * grid_x}, {240 + 64 * grid_y})', f'starts_owned = {str(bool(row["starts_owned"])).lower()}'])
        OUT.joinpath(node_id.lower() + ".tres").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    data = parse_rows()
    if len(data) != 44:
        raise SystemExit(f"Expected 44 Marco A nodes; parsed {len(data)}")
    emit(data)
    print(f"Wrote {len(data)} Marco A node resources to {OUT}")
