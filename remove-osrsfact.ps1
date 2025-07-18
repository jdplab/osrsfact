<#
.SYNOPSIS
    Removes the 'osrsfact' function from the user's PowerShell profile.

.DESCRIPTION
    This script deletes the function definition for 'osrsfact' from the PowerShell profile file.

.NOTES
    Author: jdplabs
    Version: 1.0
#>

[CmdletBinding()]
param()

function Write-Header {
    Write-Host "=== OSRS Fact Uninstaller ===" -ForegroundColor Cyan
}

function Remove-Function-From-Profile {
    if (-not (Test-Path $PROFILE)) {
        Write-Warning "PowerShell profile not found. Nothing to uninstall."
        return
    }

    $profileContent = Get-Content $PROFILE -Raw

    # Match the function block
    $pattern = '(?ms)^# OSRS Fact Function\s*function osrsfact\s*{.*?^\}.*?$'

    if ($profileContent -match $pattern) {
        $newContent = [regex]::Replace($profileContent, $pattern, '').Trim()

        try {
            Set-Content -Path $PROFILE -Value $newContent -Encoding UTF8
            Write-Host "Successfully removed 'osrsfact' from your PowerShell profile." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to update PowerShell profile: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "'osrsfact' function not found in profile."
    }
}

function main {
    Write-Header
    Remove-Function-From-Profile
    Write-Host "`n Please restart PowerShell to refresh your session." -ForegroundColor Cyan
}

main
