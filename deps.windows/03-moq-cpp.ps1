param(
    [string] $Name = 'moq-cpp',
    [string] $Version = 'v0.0.12',
    [string] $Uri = 'https://github.com/stinkydev/moq-cpp.git',
    [string] $Hash = "406ae7dd8fd150d361c13122eb341ca5a431ed1c",
    [array] $Targets = @('x64'),
    [switch] $ForceShared = $false,
    [array] $Patches = @(
    )
)

function Setup {
  Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path -Branch "main"
}

function Clean {
  Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location $Path

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

   if ( $ForceShared -and ( $script:Shared -eq $false ) ) {
        $Shared = $true
    } else {
        $Shared = $script:Shared.isPresent
    }
  
    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
    )

    Invoke-External cmake -S . -B "build_${Target}" @Options
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Options = @(
        '--build', "build_${Target}"
        '--config', $Configuration
    )

    if ( $VerbosePreference -eq 'Continue' ) {
        $Options += '--verbose'
    }

    $Options += @($CmakePostfix)

    Invoke-External cmake @Options
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}

function Fixup {
    Log-Information "Fixup (${Target})"
    Set-Location $Path

    # moq-cpp statically links its full Rust crate tree; the aggregated
    # attribution is generated upstream (cargo-about). Harvest those notices
    # into the package instead of maintaining a copy in this repo.
    $LicenseDir = "$($script:ConfigData.OutputPath)/licenses/${Name}"
    $null = New-Item -ItemType Directory -Path $LicenseDir -Force

    $Found = $false
    foreach ( $f in @('LICENSE', 'THIRD-PARTY-NOTICES.txt', 'THIRD_PARTY_LICENSES.md') ) {
        if ( Test-Path $f ) {
            Copy-Item -Path $f -Destination $LicenseDir -Force
            $Found = $true
        }
    }

    if ( ! $Found ) {
        Log-Warning "${Name}: no upstream license/notice files found - attribution may be incomplete"
    }
}
