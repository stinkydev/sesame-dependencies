function Write-Notices {
    <#
        .SYNOPSIS
            Writes the third-party notices for an assembled dependency package.
        .DESCRIPTION
            Combines the package's component records (share/sesame-deps/components/*.json)
            with licenses/components.json and licenses/THIRD-PARTY-NOTICES.md.in into
            share/sesame-deps/THIRD-PARTY-NOTICES.md. Run it on the final package, after
            the FFmpeg and dependency packages are merged, so every component is listed.
        .EXAMPLE
            Write-Notices -PackagePath ./windows/sesame-dependencies-x64-Release
    #>

    param(
        [Parameter(Mandatory)]
        [string] $PackagePath
    )

    $RepoRoot = Resolve-Path "$PSScriptRoot/.."
    $Metadata = Get-Content -Raw "${RepoRoot}/licenses/components.json" | ConvertFrom-Json -AsHashtable
    $Template = Get-Content -Raw "${RepoRoot}/licenses/THIRD-PARTY-NOTICES.md.in"
    $ShareDir = Join-Path $PackagePath 'share/sesame-deps'

    $Records = @(Get-ChildItem "${ShareDir}/components" -Filter '*.json' | Sort-Object Name | ForEach-Object {
        Get-Content -Raw $_.FullName | ConvertFrom-Json
    })

    if ( $Records.Count -eq 0 ) {
        throw "No component records under ${ShareDir}/components."
    }

    $Components = @($Records | ForEach-Object {
        $Meta = $Metadata[$_.name.ToLower()]

        if ( ! $Meta ) {
            throw "No entry for $($_.name.ToLower()) in licenses/components.json."
        }

        [pscustomobject]@{
            Name = $_.name
            Version = $_.version
            Excluded = $_.scope -eq 'excluded'
            License = $Meta.license
            Website = $Meta.website
            Holder = $Meta.holder
            Notice = $Meta.notice
        }
    })

    $Runtime = @($Components | Where-Object { ! $_.Excluded })
    $Tools = @($Components | Where-Object { $_.Excluded })

    $Table = @(
        '| Component | Version | License |'
        '|---|---|---|'
        $Runtime | ForEach-Object { "| [$($_.Name)]($($_.Website)) | $($_.Version) | $($_.License) |" }
    )

    if ( $Tools.Count -gt 0 ) {
        $Table += ''
        $Table += "Build-time tools in the package, not part of an application at run time: " +
            (($Tools | ForEach-Object { "$($_.Name) $($_.Version) ($($_.License))" }) -join ', ') + '.'
    }

    $Notices = @($Runtime | Where-Object { $_.Notice } | ForEach-Object { "- **$($_.Name)**: $($_.Notice)" })

    # One clause per copyright holder, e.g. "the Xiph.Org Foundation (libogg, libvorbis, opus; BSD-3-Clause)".
    $Attribution = @($Runtime | Group-Object Holder | ForEach-Object {
        $Names = ($_.Group.Name | Sort-Object -Unique) -join ', '
        $Licenses = ($_.Group.License | Sort-Object -Unique) -join ', '
        "$($_.Name) (${Names}; ${Licenses})"
    })

    $Version = if ( Test-Path "${ShareDir}/VERSION" ) { (Get-Content -Raw "${ShareDir}/VERSION").Trim() } else { 'unversioned' }
    $Platform = ($Records[0].properties | Where-Object name -eq 'sesame-deps:platform').value

    $Notes = $Template.
        Replace('{{package}}', "${Version} ${Platform}").
        Replace('{{components}}', ($Table -join "`n")).
        Replace('{{notices}}', ($Notices -join "`n")).
        Replace('{{attribution}}', "This product includes software developed by $($Attribution -join '; ').")

    $OutFile = Join-Path $ShareDir 'THIRD-PARTY-NOTICES.md'
    Set-Content -Path $OutFile -Value $Notes -NoNewline
    Write-Host "Wrote ${OutFile} ($($Runtime.Count) components)"
}
