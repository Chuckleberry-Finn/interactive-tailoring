"""
generateNonTintedValues.py
==========================
Generates a Lua table mapping Item_* texture names to their average
RGB color, for clothing items where m_AllowRandomTint = false.

Changes from original:
  - Auto-detects the Project Zomboid install (or prompts the user).
  - Auto-detects the mod root (or prompts the user).
  - Reads UI*.pack files directly instead of requiring an unpacked folder.
"""

import os
import re
import sys
from collections import defaultdict
from pathlib import Path
from PIL import Image


# ──────────────────────────────────────────────────────────────────────────────
# 1.  PATH AUTO-DETECTION
# ──────────────────────────────────────────────────────────────────────────────

def _find_steam_libraries() -> list[str]:
    """Return a list of '<library>/steamapps' paths from the local Steam install."""
    steam_root = None

    if sys.platform == "win32":
        # Prefer the registry; fall back to common drive locations.
        try:
            import winreg
            for hive, key_path in [
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Valve\Steam"),
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Valve\Steam"),
                (winreg.HKEY_CURRENT_USER,  r"SOFTWARE\Valve\Steam"),
            ]:
                try:
                    key = winreg.OpenKey(hive, key_path)
                    steam_root, _ = winreg.QueryValueEx(key, "InstallPath")
                    winreg.CloseKey(key)
                    break
                except OSError:
                    pass
        except ImportError:
            pass

        if not steam_root:
            for drive in "CDEFGH":
                for suffix in (
                    "\\Steam",
                    "\\Program Files\\Steam",
                    "\\Program Files (x86)\\Steam",
                    "\\SteamLibrary",          # rare but some people put Steam itself here
                ):
                    candidate = f"{drive}:{suffix}"
                    if os.path.isdir(os.path.join(candidate, "steamapps")):
                        steam_root = candidate
                        break
                if steam_root:
                    break
    else:
        home = Path.home()
        for candidate in [
            home / ".steam" / "steam",
            home / ".local" / "share" / "Steam",
            Path("/usr/local/games"),
        ]:
            if candidate.is_dir():
                steam_root = str(candidate)
                break

    if not steam_root:
        return []

    libraries: list[str] = [os.path.join(steam_root, "steamapps")]

    # Parse libraryfolders.vdf to pick up extra library drives.
    vdf = os.path.join(steam_root, "steamapps", "libraryfolders.vdf")
    if os.path.exists(vdf):
        with open(vdf, encoding="utf-8", errors="ignore") as fh:
            content = fh.read()
        for m in re.finditer(r'"path"\s+"([^"]+)"', content):
            lib = os.path.join(m.group(1), "steamapps")
            if os.path.isdir(lib) and lib not in libraries:
                libraries.append(lib)

    return libraries


def _find_pz_install() -> str | None:
    """Search known Steam library paths for the ProjectZomboid folder."""
    for steamapps in _find_steam_libraries():
        pz = os.path.join(steamapps, "common", "ProjectZomboid")
        if os.path.isdir(pz) and os.path.isdir(os.path.join(pz, "media")):
            return pz
    return None


def get_pz_root() -> str:
    pz = _find_pz_install()
    if pz:
        print(f"[AUTO] Project Zomboid found at: {pz}")
        return pz
    print("[WARN] Could not auto-detect Project Zomboid installation.")
    while True:
        raw = input("Enter the full path to your ProjectZomboid folder: ").strip().strip('"')
        if os.path.isdir(raw) and os.path.isdir(os.path.join(raw, "media")):
            return raw
        print("  Path not found or missing 'media' subfolder — please try again.")


def get_mod_root() -> str:
    """
    Derive the mod root from the script's own location first.

    Expected layout:
        <mod_root>/py/generateNonTintedValues.py   ← this file
        <mod_root>/Contents/mods/...               ← Lua output lives here

    Falls back to common Zomboid Workshop paths, then an interactive prompt.
    """
    # ── Primary: script-relative detection ───────────────────────────────────
    script_dir = os.path.dirname(os.path.abspath(__file__))   # .../py/
    candidate  = os.path.dirname(script_dir)                  # .../interactive-tailoring/

    # Sanity-check: the mod root should contain a 'Contents' folder.
    if os.path.isdir(os.path.join(candidate, "Contents")):
        print(f"[AUTO] Mod root derived from script location: {candidate}")
        return candidate

    # ── Fallback: search common Zomboid Workshop locations ────────────────────
    search_candidates: list[str] = []

    if sys.platform == "win32":
        appdata  = os.environ.get("APPDATA", "")
        username = os.environ.get("USERNAME", "")
        search_candidates.append(
            os.path.join(appdata, "Zomboid", "Workshop", "interactive-tailoring")
        )
        for drive in "CDEFG":
            search_candidates.append(
                f"{drive}:\\Users\\{username}\\Zomboid\\Workshop\\interactive-tailoring"
            )
    else:
        home = Path.home()
        search_candidates.append(str(home / "Zomboid" / "Workshop" / "interactive-tailoring"))

    for path in search_candidates:
        if os.path.isdir(path):
            print(f"[AUTO] Mod root found at: {path}")
            return path

    # ── Last resort: ask the user ─────────────────────────────────────────────
    print("[WARN] Could not auto-detect mod root (interactive-tailoring).")
    while True:
        raw = input("Enter the full path to your mod root folder: ").strip().strip('"')
        if os.path.isdir(raw):
            return raw
        print("  Path not found — please try again.")


# ──────────────────────────────────────────────────────────────────────────────
# 2.  TEXTURE INDEX  (media/textures + unpacked UI* folders)
# ──────────────────────────────────────────────────────────────────────────────

def _find_ui_texture_dirs(pz_root: str) -> list[str]:
    """
    Return all UI* sub-folders inside media/texturepacks/ (the folders you get
    after unpacking UI*.pack files with an external tool).

    If none are found, the user is prompted to supply a folder path directly.
    """
    texturepacks_dir = os.path.join(pz_root, "media", "texturepacks")
    ui_dirs: list[str] = []

    if os.path.isdir(texturepacks_dir):
        ui_dirs = sorted(
            os.path.join(texturepacks_dir, name)
            for name in os.listdir(texturepacks_dir)
            if name.upper().startswith("UI")
            and os.path.isdir(os.path.join(texturepacks_dir, name))
        )

    if ui_dirs:
        return ui_dirs

    # ── Fallback: ask the user ───────────────────────────────────────────────
    print("[WARN] No UI* unpacked texture folders found in:")
    print(f"  {texturepacks_dir}")
    print("Unpack your UI*.pack files first (e.g. with ProjectZomboidPackManager),")
    print("then enter the folder that contains the resulting PNG files.")
    while True:
        raw = input("Path to unpacked textures folder: ").strip().strip('"\'"')
        if os.path.isdir(raw):
            return [raw]
        print("  Path not found — please try again.")


def build_texture_index(pz_root: str) -> dict[str, str]:
    """
    Return a case-insensitive filename → absolute-path mapping for every PNG
    texture the script might need.

    Sources (checked in this order, later entries do NOT overwrite earlier ones):
      1. media/textures/          — loose PNGs shipped with the game
      2. media/texturepacks/UI*/  — folders produced by unpacking UI*.pack files
         Falls back to a user-supplied folder if none exist.
    """
    index: dict[str, str] = {}

    # ── 1. media/textures ────────────────────────────────────────────────────
    textures_dir = os.path.join(pz_root, "media", "textures")
    if os.path.isdir(textures_dir):
        for root, _, files in os.walk(textures_dir):
            for fname in files:
                if fname.lower().endswith(".png"):
                    index.setdefault(fname.lower(), os.path.join(root, fname))

    # ── 2. UI* unpacked folders ───────────────────────────────────────────────
    ui_dirs = _find_ui_texture_dirs(pz_root)
    print(f"[INFO] Scanning {len(ui_dirs)} UI texture folder(s)…")
    for ui_dir in ui_dirs:
        before = len(index)
        for root, _, files in os.walk(ui_dir):
            for fname in files:
                if fname.lower().endswith(".png"):
                    index.setdefault(fname.lower(), os.path.join(root, fname))
        print(f"  {os.path.basename(ui_dir)}/: {len(index) - before} new texture(s)")

    print(f"[INFO] Texture index complete: {len(index)} unique filenames.")
    return index


# ──────────────────────────────────────────────────────────────────────────────
# 4.  COLOR EXTRACTION
# ──────────────────────────────────────────────────────────────────────────────

def get_avg_color(path: str) -> dict | None:
    """
    Compute the average RGB of fully-opaque (alpha=255) pixels.
    Returns {'r': float, 'g': float, 'b': float} normalised to [0,1],
    or None if the image has no opaque pixels or cannot be opened.
    """
    try:
        with Image.open(path).convert("RGBA") as img:
            r_total = g_total = b_total = count = 0
            for r, g, b, a in img.getdata():
                if a == 255:
                    r_total += r
                    g_total += g
                    b_total += b
                    count += 1

        if count == 0:
            return None
        return {
            "r": round(r_total / count / 255, 3),
            "g": round(g_total / count / 255, 3),
            "b": round(b_total / count / 255, 3),
        }
    except Exception as exc:
        print(f"  [ERROR] Could not read image: {exc}")
        return None


# ──────────────────────────────────────────────────────────────────────────────
# 5.  MAIN PIPELINE
# ──────────────────────────────────────────────────────────────────────────────

def main() -> None:
    # ── Resolve root paths ───────────────────────────────────────────────────
    PZ_ROOT  = get_pz_root()
    MOD_ROOT = get_mod_root()

    # Build 42+ uses a single generated file; older builds used a directory.
    SCRIPT_FILE_NEW = os.path.join(PZ_ROOT, "media", "scripts", "generated", "items", "clothing.txt")
    SCRIPT_DIR_OLD  = os.path.join(PZ_ROOT, "media", "scripts", "clothing")
    XML_DIR         = os.path.join(PZ_ROOT, "media", "clothing", "clothingItems")
    LUA_OUTPUT_PATH = os.path.join(
        MOD_ROOT,
        "Contents", "mods", "InteractiveTailoring", "42", "media", "lua", "client",
        "interactiveTailoring_generatedItemColor.lua",
    )

    missing_textures: list[str] = []
    output: dict[str, dict] = {}

    # ── Step 1: Parse clothing scripts → xml_name → set of icon names ────────
    print("\n[STEP 1] Parsing clothing scripts…")
    xml_to_icons: dict[str, set] = defaultdict(set)

    # Prefer the new single generated file; fall back to the legacy directory.
    if os.path.isfile(SCRIPT_FILE_NEW):
        print(f"  Using generated script: {SCRIPT_FILE_NEW}")
        script_files = [SCRIPT_FILE_NEW]
    elif os.path.isdir(SCRIPT_DIR_OLD):
        print(f"  Using legacy script directory: {SCRIPT_DIR_OLD}")
        script_files = [
            os.path.join(SCRIPT_DIR_OLD, f)
            for f in os.listdir(SCRIPT_DIR_OLD)
            if f.endswith(".txt")
        ]
    else:
        print("[ERROR] Could not find clothing scripts in either expected location:")
        print(f"  New: {SCRIPT_FILE_NEW}")
        print(f"  Old: {SCRIPT_DIR_OLD}")
        sys.exit(1)

    for filepath in script_files:
        with open(filepath, encoding="utf-8") as fh:
            content = fh.read()

        for block in re.findall(r"item\s+\w+[^{]*{([^}]*)}", content, re.DOTALL):
            if "BloodLocation" not in block:
                continue

            clothing_item = re.search(r"\bClothingItem\s*=\s*(\w+)", block)
            if not clothing_item:
                continue
            xml_name = clothing_item.group(1)

            icon = re.search(r"\bIcon\s*=\s*(\w+)", block)
            if icon:
                xml_to_icons[xml_name].add(icon.group(1))

            icons_for_texture = re.search(r"\bIconsForTexture\s*=\s*([^\n,}]+)", block)
            if icons_for_texture:
                for icon_name in icons_for_texture.group(1).split(";"):
                    icon_name = icon_name.strip()
                    if icon_name:
                        xml_to_icons[xml_name].add(icon_name)

    print(f"  {len(xml_to_icons)} clothing XML mappings found.")

    # ── Step 2: Filter by m_AllowRandomTint = false ───────────────────────────
    print("\n[STEP 2] Filtering by <m_AllowRandomTint>false…")
    final_icons: set[str] = set()

    for xml_name, icons in xml_to_icons.items():
        xml_path = os.path.join(XML_DIR, f"{xml_name}.xml")
        if not os.path.exists(xml_path):
            continue
        with open(xml_path, encoding="utf-8") as fh:
            if "<m_AllowRandomTint>false</m_AllowRandomTint>" in fh.read():
                final_icons.update(icons)

    print(f"  {len(final_icons)} icon(s) to process.")

    # ── Step 3: Build texture index from pack files ───────────────────────────
    print("\n[STEP 3] Building texture index…")
    texture_index = build_texture_index(PZ_ROOT)

    # ── Step 4: Compute average colour per icon ───────────────────────────────
    print("\n[STEP 4] Computing average colours…")
    for icon_name in sorted(final_icons):
        target = f"item_{icon_name}.png".lower()
        path = texture_index.get(target)
        if path is None:
            missing_textures.append(f"Item_{icon_name}.png")
            continue
        color = get_avg_color(path)
        if color:
            output[icon_name] = color

    # ── Step 5: Write Lua file ────────────────────────────────────────────────
    print("\n[STEP 5] Writing Lua output…")
    os.makedirs(os.path.dirname(LUA_OUTPUT_PATH), exist_ok=True)
    with open(LUA_OUTPUT_PATH, "w", encoding="utf-8") as fh:
        fh.write("local generated = {\n")
        for icon_name, color in sorted(output.items()):
            fh.write(
                f'    ["Item_{icon_name}"] = '
                f'{{ r = {color["r"]}, g = {color["g"]}, b = {color["b"]} }},\n'
            )
        fh.write("}\n\nreturn generated\n")

    # ── Summary ───────────────────────────────────────────────────────────────
    print("\n─── Summary ─────────────────────────────────────────────")
    if missing_textures:
        print(f"Missing textures ({len(missing_textures)}):")
        for tex in missing_textures:
            print(f"  - {tex}")
    else:
        print("All textures found successfully.")
    print(f"\nDone. {len(output)} icon(s) written to:\n  {LUA_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
