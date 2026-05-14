<#
Simple cleanup script for the workspace. Run from project root in PowerShell.
Usage: Open PowerShell in project root and run:
  .\scripts\clean_workspace.ps1
#>

Write-Output "Removing build/ directory (if exists)..."
if (Test-Path -Path .\build) {
  Remove-Item -Recurse -Force .\build
  Write-Output "build/ removed"
} else {
  Write-Output "build/ not found"
}

# Remove common IDE files
$ideFiles = @('*.iml', '.idea')
foreach ($f in $ideFiles) {
  Get-ChildItem -Path . -Filter $f -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.PSIsContainer) { Remove-Item -Recurse -Force $_.FullName } else { Remove-Item -Force $_.FullName }
    Write-Output "Removed: $($_.FullName)"
  }
}

Write-Output "Cleanup complete."
