function Write-Component {
    <#
        .SYNOPSIS
            Writes a CycloneDX component record for a built dependency.
        .DESCRIPTION
            Records name, version, source and patches into
            share/sesame-deps/components/<name>.json in the output tree, so the
            package carries the inventory that downstream SBOM generation and
            vulnerability scanning consume.
            Scope 'excluded' marks a build-time tool that is packaged but not part of the product at run time.
        .EXAMPLE
            Write-Component -Name 'zlib' -Version '1.3.1' -Uri $Uri -Hash $Hash -Cpe 'zlib:zlib'
    #>

    param(
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [string] $Version,
        [Parameter(Mandatory)]
        [string] $Uri,
        [string] $Hash,
        [string] $Cpe,
        [array] $Patches = @(),
        [ValidateSet('', 'required', 'optional', 'excluded')]
        [string] $Scope = ''
    )

    $CleanVersion = $Version -replace '^v(?=\d)', ''

    $Component = [ordered]@{
        type = 'library'
        name = $Name
        version = $CleanVersion
    }

    if ( $Scope -ne '' ) {
        $Component.scope = $Scope
    }

    # A git source is identified by its pinned commit; the display version can name something else (stb).
    $PurlVersion = if ( $Hash -match '^[0-9a-f]{40}$' ) { $Hash } else { $CleanVersion }

    if ( $Uri -match '^https://github\.com/([^/]+)/([^/]+?)(\.git)?(/|$)' ) {
        $Component.purl = "pkg:github/$($Matches[1].ToLower())/$($Matches[2].ToLower())@${PurlVersion}"
    } elseif ( $Uri -match '^local://' ) {
        $Component.purl = "pkg:generic/$($Name.ToLower())@${CleanVersion}"
    } else {
        $Component.purl = "pkg:generic/$($Name.ToLower())@${CleanVersion}?download_url=$([uri]::EscapeDataString($Uri))"
    }

    if ( $Cpe -ne '' ) {
        $Component.cpe = "cpe:2.3:a:${Cpe}:${CleanVersion}:*:*:*:*:*:*:*"
    }

    $Properties = @(
        [ordered]@{ name = 'sesame-deps:platform'; value = "windows-$($script:Target)" }
    )

    if ( $Hash -match '^[0-9a-f]{40}$' ) {
        $Component.externalReferences = @([ordered]@{ type = 'vcs'; url = $Uri })
        $Properties += [ordered]@{ name = 'sesame-deps:git-commit'; value = $Hash }
    } else {
        $Archive = if ( $Uri -match '^local://' ) {
            "$PSScriptRoot/../binary-packages/$([System.IO.Path]::GetFileName($Uri))"
        }

        $Sha256 = if ( $Hash -ne '' -and ( Test-Path $Hash ) ) {
            (Import-Clixml $Hash).Hash
        } elseif ( $Archive -and ( Test-Path $Archive ) ) {
            (Get-FileHash -Algorithm SHA256 $Archive).Hash
        }

        if ( $Uri -notmatch '^local://' ) {
            $Component.externalReferences = @([ordered]@{ type = 'distribution'; url = $Uri })
        }

        if ( $Sha256 ) {
            $Component.hashes = @([ordered]@{ alg = 'SHA-256'; content = $Sha256.ToLower() })
        }
    }

    if ( $Patches.Count -gt 0 ) {
        $RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
        $Commit = (git -C $RepoRoot rev-parse HEAD 2>$null) ?? 'main'

        $Component.pedigree = @{
            patches = @($Patches | ForEach-Object {
                $Relative = [System.IO.Path]::GetRelativePath($RepoRoot, $_.PatchFile) -replace '\\', '/'
                [ordered]@{
                    type = 'unofficial'
                    diff = @{ url = "https://github.com/stinkydev/sesame-dependencies/blob/${Commit}/${Relative}" }
                }
            })
        }
    }

    $Component.properties = $Properties

    $ComponentDir = "$($ConfigData.OutputPath)/share/sesame-deps/components"
    New-Item -ItemType Directory -Force -Path $ComponentDir *> $null
    $Component | ConvertTo-Json -Depth 6 | Set-Content -Path "${ComponentDir}/$($Name.ToLower()).json"
}
