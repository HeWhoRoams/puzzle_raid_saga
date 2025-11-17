pip install -r requirements-dev.txt | Out-Host
python -m gdlint autoload scripts | Out-Host
python -m gdformat --check autoload scripts | Out-Host

$godotCmd = Get-Command godot -ErrorAction SilentlyContinue
if ($godotCmd) {
    godot --headless --script tests/run_smoke_tests.gd | Out-Host
    godot --headless --script tests/unit/test_turn_resolver.gd | Out-Host
    godot --headless --script tests/unit/test_board_service.gd | Out-Host
    godot --headless --script tests/unit/test_persistence.gd | Out-Host
} else {
    Write-Host "Godot CLI not found on PATH; skipping smoke tests."
}

python scripts/tools/validate_resources.py | Out-Host
