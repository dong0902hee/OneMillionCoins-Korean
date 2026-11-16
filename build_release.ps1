# 배포용 zip 만들기: powershell -ExecutionPolicy Bypass -File build_release.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = Join-Path $root 'dist'
$stage = Join-Path $out 'stage'
$zip = Join-Path $out 'OneMillionCoins_KoreanPatch.zip'

if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force (Join-Path $stage 'patch\Translation\locales') | Out-Null

Copy-Item (Join-Path $root 'installer\*.bat') $stage
Copy-Item (Join-Path $root 'installer\읽어주세요.txt') $stage
Copy-Item (Join-Path $root 'installer\install.ps1') (Join-Path $stage 'patch')
Copy-Item (Join-Path $root 'doorstop_config.ini') (Join-Path $stage 'patch')
Copy-Item (Join-Path $root 'bin\winhttp.dll') (Join-Path $stage 'patch')
Copy-Item (Join-Path $root 'bin\0Harmony.dll'), (Join-Path $root 'bin\TranslationLoader.dll') (Join-Path $stage 'patch\Translation')
Copy-Item (Join-Path $root 'Translation\fonts') (Join-Path $stage 'patch\Translation') -Recurse
Copy-Item (Join-Path $root 'Translation\locales\*') (Join-Path $stage 'patch\Translation\locales')
Copy-Item (Join-Path $root 'licenses') $stage -Recurse
Copy-Item (Join-Path $root 'LICENSE'), (Join-Path $root 'THIRD_PARTY_NOTICES.md') $stage

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip
Remove-Item $stage -Recurse -Force
Write-Host "만들었습니다: $zip"
