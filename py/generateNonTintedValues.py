import os
import re
from collections import defaultdict, Counter
from PIL import Image

# === CONFIGURATION ===
PZ_ROOT = r"E:\SteamLibrary\steamapps\common\ProjectZomboid"
SCRIPT_DIR = os.path.join(PZ_ROOT, "media", "scripts", "clothing")
XML_DIR = os.path.join(PZ_ROOT, "media", "clothing", "clothingItems")

MOD_ROOT = r"C:\Users\Chaden\Desktop\ChucksStuff\ZomboidDEBUG\Workshop\interactive-tailoring"
LUA_OUTPUT_PATH = os.path.join(
    MOD_ROOT,
    "Contents", "mods", "InteractiveTailoring", "42", "media", "lua", "client",
    "interactiveTailoring_generatedItemColor.lua"
)

TEXTURE_PATHS = [
    os.path.join(PZ_ROOT, "media", "textures"),
    os.path.join(PZ_ROOT, "media", "texturepacks", "unpacked"),
]

missing_textures = []
output = {}

# === STEP 1: PARSE SCRIPTS AND MAP XMLs TO ICONS ===
xml_to_icons = defaultdict(set)

for filename in os.listdir(SCRIPT_DIR):
    if not filename.endswith(".txt"):
        continue
    with open(os.path.join(SCRIPT_DIR, filename), encoding='utf-8') as f:
        content = f.read()
        blocks = re.findall(r"item\s+\w+[^{]*{([^}]*)}", content, re.DOTALL)

        for block in blocks:
            if "BloodLocation" not in block:
                continue  # Skip non-wearable or invisible items

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

# === STEP 2: FILTER ICONS BASED ON XML <m_AllowRandomTint>false</m_AllowRandomTint> ===
final_icons = set()

for xml_name, icons in xml_to_icons.items():
    xml_path = os.path.join(XML_DIR, f"{xml_name}.xml")
    if not os.path.exists(xml_path):
        continue
    with open(xml_path, encoding='utf-8') as f:
        if "<m_AllowRandomTint>false</m_AllowRandomTint>" in f.read():
            final_icons.update(icons)

# === STEP 3: FIND TEXTURE (case-insensitive, subfolders) ===
def extract_texture_path(icon_name):
    target = f"Item_{icon_name}.png".lower()
    for base in TEXTURE_PATHS:
        for root, _, files in os.walk(base):
            for file in files:
                if file.lower() == target:
                    return os.path.join(root, file)
    missing_textures.append(f"Item_{icon_name}.png")
    return None

# === STEP 4: GET DOMINANT COLOR ===
def get_avg_color(path):
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
                "b": round(b_total / count / 255, 3)
            }
    except Exception as e:
        print(f"[ERROR avg_color] {path}: {e}")
        return None

# === STEP 5: PROCESS EACH ICON ===
for icon_name in final_icons:
    tex_path = extract_texture_path(icon_name)
    if tex_path:
        color = get_avg_color(tex_path)
        if color:
            output[icon_name] = color

# === STEP 6: WRITE LUA FILE ===
os.makedirs(os.path.dirname(LUA_OUTPUT_PATH), exist_ok=True)
with open(LUA_OUTPUT_PATH, "w", encoding="utf-8") as f:
    f.write("local generated = {\n")
    for icon_name, color in sorted(output.items()):
        f.write(f'    ["{icon_name}"] = {{ r = {color["r"]}, g = {color["g"]}, b = {color["b"]} }},\n')
    f.write("}\n\nreturn generated\n")

# === STEP 7: SUMMARY LOG ===
print("\n--- Summary ---")
if missing_textures:
    print("Missing textures:")
    for tex in missing_textures:
        print(f"  - {tex}")
else:
    print("All textures found successfully.")
print(f"\nDone. {len(output)} icons written to:\n{LUA_OUTPUT_PATH}")
