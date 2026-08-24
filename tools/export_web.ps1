param([string]$Godot = "godot")
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot ".."))
Set-Location $Root
if (Test-Path "web") { Remove-Item "web" -Recurse -Force }
New-Item -ItemType Directory -Path "web" | Out-Null
& $Godot --headless --path $Root --export-release Web "web/index.html"
if ($LASTEXITCODE -ne 0) { throw "Godot Web export failed." }
New-Item -ItemType File -Path "web/.nojekyll" -Force | Out-Null
$Zip = Join-Path $Root "Plakoro_Adventures_Web_itch_github.zip"
if (Test-Path $Zip) { Remove-Item $Zip -Force }
Compress-Archive -Path "web/*" -DestinationPath $Zip
Write-Host "Exported: $Root\web\index.html"
Write-Host "Upload ZIP: $Zip"
