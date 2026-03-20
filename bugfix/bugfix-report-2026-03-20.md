# Bug Fix Report — 2026-03-20

## Summary

Multiple issues prevented the `pp` command from launching Claude Code on a Windows system
with a Cyrillic project path (`C:\Users\andre\OneDrive\Рабочий стол\test`).

---

## Issue 1: PowerShell profile — Cyrillic path corrupted

**File:** `C:\Users\andre\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

**Symptom:**
```
Set-Location : Cannot find path 'C:\Users\andre\OneDrive\??????? ????\test'
```

**Root cause:**
`setup.ps1` used `Add-Content` to write the `pp` function to the PowerShell profile.
In PowerShell 5.1, `Add-Content` defaults to the system's ANSI encoding (Windows-1251 on
Russian Windows), which corrupts Cyrillic characters. PowerShell 5.1 requires UTF-8 **with
BOM** to correctly read non-ASCII characters in profile scripts.

**Fix applied in `setup.ps1` (line ~675):**

Before:
```powershell
Add-Content $psProfile $cmdBlock
```

After:
```powershell
$existingContent = if (Test-Path $psProfile) {
    [System.IO.File]::ReadAllText($psProfile, [System.Text.Encoding]::UTF8)
} else { "" }
$newContent = $existingContent + $cmdBlock
[System.IO.File]::WriteAllText($psProfile, $newContent, [System.Text.Encoding]::UTF8)
```

Same fix applied to the "update existing profile" path (line ~666):
```powershell
# Before:
$profileContent | Set-Content $psProfile -Encoding UTF8
# After:
[System.IO.File]::WriteAllText($psProfile, $profileContent, [System.Text.Encoding]::UTF8)
```

**Additional fix — `fix-profile.ps1` helper script:**

A helper script was created at `scripts/fix-profile.ps1` that writes the profile using
string concatenation (avoiding here-string `@"..."@` escaping issues) with UTF-8 BOM:

```powershell
$line2 = 'function pp { Set-Location "' + $ProjectDir + '"; & ".\scripts\start.ps1" @args }'
# ...
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($psProfile, $content, $utf8bom)
```

**Lesson:** Never use `Set-Content` or `Add-Content` for files containing non-ASCII text
in PowerShell 5.1. Always use `[System.IO.File]::WriteAllText()` with explicit
`UTF8Encoding($true)` (the `$true` parameter adds the BOM).

---

## Issue 2: WSL cannot access Cyrillic paths via `wslpath`

**File:** `scripts/start.ps1`

**Symptom:**
```
[X] WSL cannot access project path: /mnt/c/Users/andre/OneDrive/╨á╨░╨▒╨╛╤ç╨╕╨╣ ╤ü╤é╨╛╨╗/test
```

**Root cause:**
`start.ps1` passed the Windows path through `wsl bash -c "wslpath -u '$ProjectDir'"`.
When the path contains Cyrillic characters, the encoding is mangled as it crosses the
PowerShell → WSL → bash boundary. Every `Invoke-WSL` call that includes Cyrillic text
in arguments suffers the same problem.

**Fix applied in `start.ps1`:**

**Part A — Replace `wslpath` with PowerShell-side conversion (line ~93):**

Before:
```powershell
$wslPath = (Invoke-WSL "wslpath -u '$ProjectDir'")
```

After:
```powershell
$wslPath = $ProjectDir -replace '\\', '/'
if ($wslPath -match '^([A-Za-z]):(.*)') {
    $drive = $Matches[1].ToLower()
    $rest = $Matches[2]
    $wslPath = "/mnt/$drive$rest"
}
```

**Part B — Create a Windows junction for non-ASCII paths (line ~116):**

Even after converting the path in PowerShell, the Cyrillic characters still get corrupted
when passed to `wsl bash -c "cd '$wslPath'"`. The solution: create a NTFS junction
(directory symlink) with an ASCII-only path.

```powershell
if ($wslPath -match '[^\x00-\x7F]') {
    $linkName = "claude-project-" + $SessionName
    $linkTarget = "$env:TEMP\$linkName"
    cmd /c mklink /J "$linkTarget" "$ProjectDir" 2>$null | Out-Null
    if (Test-Path $linkTarget) {
        $wslPath = "/mnt/c" + ($linkTarget.Substring(2) -replace '\\', '/')
    }
}
```

This creates e.g. `%TEMP%\claude-project-test` → `C:\Users\andre\OneDrive\Рабочий стол\test`,
and WSL accesses the project through the ASCII junction path.

**Lesson:** WSL's `bash -c` mangles non-ASCII arguments. For Cyrillic (or any Unicode) paths,
always use an ASCII-only junction/symlink as an intermediary.

---

## Issue 3: `--dangerously-skip-permissions` fails with root

**File:** `scripts/start.ps1`

**Symptom:**
```
--dangerously-skip-permissions cannot be used with root/sudo privileges for security reasons
```

**Root cause:**
Claude CLI was installed in WSL via `sudo npm install -g`, and the tmux session launched
Claude with `--dangerously-skip-permissions`. Claude refuses this flag when running as root.

**Fix applied in `start.ps1` (line ~131):**

Before:
```powershell
'claude --dangerously-skip-permissions; echo; echo \"[Claude exited. Press Enter to close.]\"; read'
```

After:
```powershell
'claude; echo; echo \"[Claude exited. Press Enter to close.]\"; read'
```

**Lesson:** Don't use `--dangerously-skip-permissions` in automated scripts, especially when
the execution context may be root. Claude will prompt for permissions as needed.

---

## Issue 4: WSL locale not configured

**Symptom:**
```
bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
```

**Root cause:**
`start.ps1` sets `export LC_ALL=en_US.UTF-8` but the locale was not installed in WSL.

**Fix (manual):**
```bash
wsl bash -c "sudo apt-get update && sudo apt-get install -y locales && sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"
wsl --shutdown
```

**Note:** `setup.ps1` already has an `Ensure-WSLLocale` function that does this, but it
only runs during setup. If WSL was reinstalled or reset, the locale needs to be
reconfigured.

---

## Files Modified

| File | Changes |
|------|---------|
| `scripts/setup.ps1` | Fixed profile writing to use `[System.IO.File]::WriteAllText()` with UTF-8 BOM |
| `scripts/start.ps1` | Replaced `wslpath` with PowerShell path conversion; added junction for Cyrillic paths; removed `--dangerously-skip-permissions` |
| `scripts/fix-profile.ps1` | New helper script to rewrite PowerShell profile with correct encoding |
| PowerShell profile | Rewritten with correct Cyrillic path via `fix-profile.ps1` |

---

## Recommendations

1. **Avoid Cyrillic in project paths.** The simplest long-term fix is to move the project
   to an ASCII path like `C:\projects\test`. Windows, WSL, and many tools have encoding
   issues with non-ASCII paths.

2. **Always use `[System.IO.File]::WriteAllText()` with `UTF8Encoding($true)`** when
   writing files that may contain non-ASCII text from PowerShell 5.1.

3. **Use NTFS junctions** when passing paths with non-ASCII characters to WSL or other
   tools that don't handle Unicode well.

4. **Don't use `--dangerously-skip-permissions`** in scripts — it's a security risk and
   fails under root.
