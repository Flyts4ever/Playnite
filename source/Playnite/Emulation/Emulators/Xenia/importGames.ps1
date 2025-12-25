param(
    $ImportArgs
)

if (-not [System.IO.Directory]::Exists($ImportArgs.ScanDirectory)) {
    return
}

# --- 1. Extracted XEX games (default.xex) ---
$xexGames = Get-ChildItem -LiteralPath $ImportArgs.ScanDirectory -Recurse |
    Where-Object { $_.Name -ieq "default.xex" }

# --- 2. ISO games ---
$isoGames = Get-ChildItem -LiteralPath $ImportArgs.ScanDirectory -Recurse |
    Where-Object { $_.Extension -ieq ".iso" }

# --- 3. XBLA games ---
# XBLA = file inside 000D0000 with NO extension
$xblaGames = Get-ChildItem -LiteralPath $ImportArgs.ScanDirectory -Recurse |
    Where-Object {
        $_.DirectoryName -match "000D0000" -and
        $_.Extension -eq "" -and
        $_.Name -ne "default.xex"
    }

# Combine all game entries
$allGames = @()

# Add XEX games
foreach ($game in $xexGames) {
    $allGames += [PSCustomObject]@{
        Path = $game.FullName
        Name = Split-Path $game.DirectoryName -Leaf
    }
}

# Add ISO games
foreach ($iso in $isoGames) {
    $allGames += [PSCustomObject]@{
        Path = $iso.FullName
        Name = [System.IO.Path]::GetFileNameWithoutExtension($iso.Name)
    }
}

# Add XBLA games
foreach ($file in $xblaGames) {
    $allGames += [PSCustomObject]@{
        Path = $file.FullName
        Name = $file.Name
    }
}

# Output to Playnite
foreach ($entry in $allGames) {

    # Skip already imported files
    $anyFunc = [Func[string,bool]]{ param($a) $a.Equals($entry.Path, 'OrdinalIgnoreCase') }
    if ([System.Linq.Enumerable]::Any($ImportArgs.ImportedFiles, $anyFunc)) {
        continue
    }

    $scannedGame = New-Object "Playnite.Emulators.ScriptScannedGame"
    $scannedGame.Path   = $entry.Path
    $scannedGame.Name   = $entry.Name
    $scannedGame.Serial = $entry.Name

    $scannedGame
}
