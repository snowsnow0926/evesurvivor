@echo off
for %%F in (
    "scripts\settings_manager.gd"
    "scripts\main_menu.gd"
    "scripts\pause_menu.gd"
) do (
    echo === %%~nxF ===
    powershell -Command "Get-Content '%%~fF' -Encoding Byte -TotalCount 512 | ForEach-Object { if ($_ -eq 13) { write-output 'CR' } elseif ($_ -eq 10) { write-output 'LF' } else { write-output ('%02X' -f $_) } } | Select-Object -First 20"
)
