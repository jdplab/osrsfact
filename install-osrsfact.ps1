<#
.SYNOPSIS
    Installs the 'osrsfact' PowerShell function to the user's PowerShell profile.

.DESCRIPTION
    This script adds a function called 'osrsfact' to your PowerShell profile, allowing you to fetch a random
    fact from the Old School RuneScape wiki using their public API.

.NOTES
    Author: jdplabs
    Version: 1.0
    License: MIT
#>

[CmdletBinding()]
param()

function Write-Header {
    Write-Host "=== OSRS Fact Installer ===" -ForegroundColor Cyan
}

function Ensure-Profile {
    if (-not (Test-Path -Path $PROFILE)) {
        Write-Verbose "Creating PowerShell profile at: $PROFILE"
        try {
            $parentDir = Split-Path -Parent $PROFILE
            if (-not (Test-Path -Path $parentDir)) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
            }
            New-Item -Path $PROFILE -ItemType File -Force | Out-Null
        } catch {
            Write-Error "Failed to create PowerShell profile: $($_.Exception.Message)"
            exit 1
        }
    }
}

function Function-Already-Exists {
    $profileContent = Get-Content -Path $PROFILE -Raw
    return $profileContent -match "function\s+osrsfact"
}

function Add-Function-To-Profile {
    $functionCode = @'
function osrsfact {
    [CmdletBinding()]
    param ()

    try {
        # Step 1: Get a random page title from the OSRS wiki
        $random = Invoke-RestMethod -Uri "https://oldschool.runescape.wiki/api.php?action=query&format=json&list=random&rnnamespace=0&rnlimit=1"
        $title = $random.query.random[0].title
        $encodedTitle = [uri]::EscapeDataString($title)

        # Step 2: Fetch the parsed HTML content of the page
        $parsed = Invoke-RestMethod -Uri "https://oldschool.runescape.wiki/api.php?action=parse&format=json&page=$encodedTitle&prop=text"
        $html = $parsed.parse.text."*"

        # Step 3: Extract the first paragraph using regex
        if ($html -match '(?s)<p>(.*?)</p>') {
            # Remove HTML tags and decode HTML entities
            $rawText = $matches[1] -replace '<.*?>', '' -replace '&nbsp;', ' ' -replace '&amp;', '&'
            $decodedText = [System.Net.WebUtility]::HtmlDecode($rawText)

            # Truncate to 600 characters if necessary
            if ($decodedText.Length -gt 600) {
                $decodedText = $decodedText.Substring(0, 600) + "..."
            }

            # Format output with title, text, and URL
            return @"
**$title**

$decodedText

https://oldschool.runescape.wiki/w/$($encodedTitle -replace '%20','_')
"@
        }
        else {
            Write-Warning "No <p> tag found in page HTML."
            return "Could not fetch a usable OSRS fact."
        }
    }
    catch {
        Write-Warning "Failed to fetch OSRS fact: $_"
        return "Could not fetch a usable OSRS fact."
    }
}
'@

    try {
        Add-Content -Path $PROFILE -Value "`n# OSRS Fact Function`n$functionCode"
        Write-Host "✅ 'osrsfact' function added to your profile at $PROFILE" -ForegroundColor Green
    } catch {
        Write-Error "Failed to update profile: $($_.Exception.Message)"
        exit 1
    }
}

function main {
    Write-Header
    Ensure-Profile

    if (Function-Already-Exists) {
        Write-Host "ℹ️ The 'osrsfact' function already exists in your profile. No changes made." -ForegroundColor Yellow
    } else {
        Add-Function-To-Profile
    }

    Write-Host "`n➡️  Please restart PowerShell or run '. $PROFILE' to use the 'osrsfact' command." -ForegroundColor Cyan
}

main