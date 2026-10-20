# The four checks, for Windows PowerShell. Everything must pass before Studio sees the code.
# Run from the project folder:  powershell -ExecutionPolicy Bypass -File scripts\check.ps1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

foreach ($tool in "rojo", "lune", "selene", "stylua") {
	if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
		Write-Host "Can't find '$tool'. Run 'rokit install' in this folder, then open a new terminal." -ForegroundColor Red
		exit 1
	}
}

function Step($label, [scriptblock]$command) {
	Write-Host "== $label"
	& $command
	if ($LASTEXITCODE -ne 0) {
		Write-Host "FAILED: $label" -ForegroundColor Red
		exit $LASTEXITCODE
	}
}

New-Item -ItemType Directory -Force -Path build | Out-Null
Step "1/4 rojo build" { rojo build default.project.json -o build/game.rbxl }
Step "2/4 tests" { lune run tests/run.luau }
Step "3/4 selene (game code)" { selene src }
Step "3/4 selene (tests)" { Push-Location tests; selene .; $code = $LASTEXITCODE; Pop-Location; $global:LASTEXITCODE = $code }
Step "4/4 stylua" { stylua --check src tests }
Write-Host "All four checks passed." -ForegroundColor Green
