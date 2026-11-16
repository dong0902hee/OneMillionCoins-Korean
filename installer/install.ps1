param([switch]$DetectOnly, [switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$AppId   = '5258340'
$ExeName = 'One Million Coins.exe'
$Here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Files   = @('winhttp.dll', 'doorstop_config.ini', 'Translation')

function Test-GameDir($p) { $p -and (Test-Path -LiteralPath (Join-Path $p $ExeName)) }

function Find-GameDir {
    $steamRoots = @()
    foreach ($key in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
        try {
            $v = Get-ItemProperty -Path $key -ErrorAction Stop
            foreach ($n in 'SteamPath', 'InstallPath') { if ($v.$n) { $steamRoots += ($v.$n -replace '/', '\') } }
        } catch { }
    }
    $steamRoots += "${env:ProgramFiles(x86)}\Steam"
    $libs = @()
    foreach ($root in ($steamRoots | Select-Object -Unique)) {
        $libs += $root
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libs += ($m.Groups[1].Value -replace '\\\\', '\')
            }
        }
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $manifest = Join-Path $lib "steamapps\appmanifest_$AppId.acf"
        if (Test-Path -LiteralPath $manifest) {
            $m = [regex]::Match((Get-Content -LiteralPath $manifest -Raw), '"installdir"\s+"([^"]+)"')
            if ($m.Success) {
                $dir = Join-Path $lib ("steamapps\common\" + $m.Groups[1].Value)
                if (Test-GameDir $dir) { return $dir }
            }
        }
        $dir = Join-Path $lib 'steamapps\common\One Million Coins'
        if (Test-GameDir $dir) { return $dir }
    }
    return $null
}

function Select-GameDir {
    Add-Type -AssemblyName System.Windows.Forms
    while ($true) {
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = "One Million Coins가 설치된 폴더를 선택하세요 ('$ExeName'이 있는 폴더)"
        $dlg.ShowNewFolderButton = $false
        if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
        if (Test-GameDir $dlg.SelectedPath) { return $dlg.SelectedPath }
        [System.Windows.Forms.MessageBox]::Show("이 폴더에는 '$ExeName'이 없습니다. 다시 선택해 주세요.", 'One Million Coins 한글 패치') | Out-Null
    }
}

$game = Find-GameDir
if ($DetectOnly) { if ($game) { "FOUND: $game" } else { 'NOT FOUND' }; return }

if ($game) {
    Write-Host "게임 폴더를 찾았습니다: $game"
} else {
    Write-Host '게임 폴더를 자동으로 찾지 못했습니다. 폴더 선택 창을 엽니다...'
    $game = Select-GameDir
    if (-not $game) { Write-Host '취소했습니다. 아무것도 바꾸지 않았습니다.'; return }
}

if (Get-Process -Name 'One Million Coins' -ErrorAction SilentlyContinue) {
    Write-Host ''
    Write-Host '게임이 실행 중입니다. 게임을 완전히 종료한 뒤 다시 실행해 주세요.' -ForegroundColor Yellow
    return
}

if ($Uninstall) {
    foreach ($f in $Files) {
        $t = Join-Path $game $f
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Recurse -Force; Write-Host "삭제: $f" }
    }
    Write-Host ''
    Write-Host '한글 패치를 제거했습니다. 게임이 원래 상태로 돌아갑니다.' -ForegroundColor Green
    return
}

# 기존 번역 폴더가 있으면 백업
$existing = Join-Path $game 'Translation'
if (Test-Path -LiteralPath $existing) {
    $bak = Join-Path $game ('Translation_backup_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    Move-Item -LiteralPath $existing -Destination $bak
    Write-Host "기존 Translation 폴더를 백업했습니다: $(Split-Path -Leaf $bak)"
}

foreach ($f in $Files) {
    $src = Join-Path $Here $f
    if (-not (Test-Path -LiteralPath $src)) { throw "패치 파일이 없습니다: $f (압축을 모두 푼 뒤 실행해 주세요)" }
    Copy-Item -LiteralPath $src -Destination $game -Recurse -Force
    Write-Host "복사: $f"
}

Write-Host ''
Write-Host '한글 패치 설치가 끝났습니다!' -ForegroundColor Green
Write-Host 'Steam에서 게임을 실행하고, 설정의 언어가 "한국어"(원래 ENGLISH)로 되어 있는지 확인하세요.'
