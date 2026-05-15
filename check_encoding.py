import os

files = [
    r'd:\GameDev\类幸存者eve同人\scripts\settings_manager.gd',
    r'd:\GameDev\类幸存者eve同人\scripts\main_menu.gd',
    r'd:\GameDev\类幸存者eve同人\scripts\pause_menu.gd',
    r'd:\GameDev\类幸存者eve同人\scripts\sound_manager.gd',
    r'd:\GameDev\类幸存者eve同人\scripts\game_manager.gd',
]

for f in files:
    if os.path.exists(f):
        size = os.path.getsize(f)
        with open(f, 'rb') as fh:
            raw = fh.read()
        # Check for BOM
        has_utf8_bom = raw[:3] == b'\xef\xbb\xbf'
        has_utf16_le = raw[:2] == b'\xff\xfe'
        has_utf16_be = raw[:2] == b'\xfe\xff'
        # Check for zero-width or control chars
        has_zero = b'\x00' in raw
        # Check last bytes
        last_bytes = raw[-8:].hex()
        print(f'{os.path.basename(f)}: size={size} bom={has_utf8_bom} utf16le={has_utf16_le} utf16be={has_utf16_be} zero={has_zero} last8bytes={last_bytes}')
    else:
        print(f'{os.path.basename(f)}: FILE NOT FOUND')
