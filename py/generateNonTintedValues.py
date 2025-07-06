import os
import sys
import re
import subprocess

# === Ensure Pillow is installed ===
try:
    from PIL import Image
except ImportError:
    print("Missing required module 'Pillow'. Run: pip install Pillow")
    exit(1)

# === CONFIGURATION ===
PZ_ROOT = r"E:\SteamLibrary\steamapps\common\ProjectZomboid"
SCRIPT_DIR = os.path.join(PZ_ROOT, "media", "scripts", "clothing")
XML_DIR = os.path.join(PZ_ROOT, "media", "clothing", "clothingItems")

# Output path for your mod
MOD_ROOT = r"C:\Users\Chaden\Desktop\ChucksStuff\ZomboidDEBUG\Workshop\interactive-tailoring"
LUA_OUTPUT_PATH = os.path.join(MOD_ROOT,"Contents","mods","InteractiveTailoring","42","media","lua","client","interactiveTailoring_generatedItemColor.lua")

# === TEXTURE SEARCH PATHS (ordered) ===
TEXTURE_PATHS = [
    os.path.join(PZ_ROOT, "media", "textures"),
    os.path.join(PZ_ROOT, "media", "texturepacks", "unpacked"),
    # Add more directories here if needed
]

# === DATA STRUCTURES ===
entries = {}           # { xml_name: { id, icon } }
valid_entries = {}     # Filtered by <m_AllowRandomTint>false</m_AllowRandomTint>
output = {}            # Final color values by item ID
missing_textures = []  # List of missing texture names

# === STEP 1: PARSE CLOTHING SCRIPTS ===
for filename in os.listdir(SCRIPT_DIR):
    if not filename.endswith(".txt"):
        continue
    with open(os.path.join(SCRIPT_DIR, filename), encoding='utf-8') as f:
        content = f.read()
        blocks = re.findall(r"item\s+(\w+)[^{]*{([^}]*)}", content, re.MULTILINE | re.DOTALL)
        for item_id, body in blocks:
            if "FabricType" not in body:
                continue  # Skip items that don't define FabricType
            clothing_item = re.search(r"ClothingItem\s*=\s*(\w+)", body)
            icon = re.search(r"Icon\s*=\s*(\w+)", body)
            if clothing_item and icon:
                entries[clothing_item.group(1)] = {
                    "id": item_id,
                    "icon": icon.group(1)
                }

# === STEP 2: FILTER XMLS WITH <m_AllowRandomTint>false</m_AllowRandomTint> ===
entries_lower = {k.lower(): v for k, v in entries.items()}

for xml_file in os.listdir(XML_DIR):
    if not xml_file.endswith(".xml"):
        continue
    xml_path = os.path.join(XML_DIR, xml_file)
    with open(xml_path, encoding='utf-8') as f:
        content = f.read()
        if "<m_AllowRandomTint>false</m_AllowRandomTint>" not in content:
            continue
        xml_name = os.path.splitext(xml_file)[0].lower()
        if xml_name in entries_lower:
            valid_entries[xml_name] = entries_lower[xml_name]


# === STEP 3: FIND TEXTURE IN MULTIPLE PATHS ===
def extract_texture_path(icon_name):
    target_name = f"Item_{icon_name}.png".lower()
    for base_dir in TEXTURE_PATHS:
        for root, _, files in os.walk(base_dir):
            for file in files:
                if file.lower() == target_name:
                    return os.path.join(root, file)
    # Not found
    missing_textures.append(f"Item_{icon_name}.png")
    return None

# === STEP 4: CALCULATE AVERAGE COLOR ===
def get_avg_color(path):
    try:
        with Image.open(path).convert("RGBA") as img:
            pixels = list(img.getdata())
            r_total = g_total = b_total = count = 0
            for r, g, b, a in pixels:
                if a < 64:  # Ignore mostly transparent
                    continue
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
        print(f"Error processing image {path}: {e}")
        return None

# === STEP 5: PROCESS VALID ENTRIES ===
for xml_name, info in valid_entries.items():
    tex_path = extract_texture_path(info["icon"])
    if tex_path:
        avg = get_avg_color(tex_path)
        if avg:
            output[info["id"]] = avg

# === STEP 6: WRITE LUA FILE ===
os.makedirs(os.path.dirname(LUA_OUTPUT_PATH), exist_ok=True)

with open(LUA_OUTPUT_PATH, "w", encoding="utf-8") as f:
    f.write("local generated = {\n")
    for item_id, color in output.items():
        f.write(f'    ["{item_id}"] = {{ r = {color["r"]}, g = {color["g"]}, b = {color["b"]} }},\n')
    f.write("}\n\nreturn generated\n")

# === STEP 7: SUMMARY LOG ===
print("\n--- Summary ---")
if missing_textures:
    print("Missing textures:")
    for m in missing_textures:
        print(f"  - {m}")
else:
    print("All textures found successfully.")

print(f"\nDone. {len(output)} entries written to {LUA_OUTPUT_PATH}")