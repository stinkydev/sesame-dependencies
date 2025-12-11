param(
    [string] $Name = 'audio-plugins',
    [string] $Version = '0.0.2',
    [string] $Uri = 'https://github.com/stinkydev/audio-plugins.git',
    [string] $Hash = '44ec4ff655f3bea41738b47c199faa013729dda5',
    [array] $Targets = @('x64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
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
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $Options = @(
        $CmakeOptions
        '-DBUILD_TESTS:BOOL=OFF'
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
