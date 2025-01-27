param(
    [string] $Name = 'protobuf',
    [string] $Version = '3.21.12',
    [string] $Uri = 'https://github.com/protocolbuffers/protobuf.git',
    [string] $Hash = "f0dc78d7e6e331b8c6bb2d5283e06aa26883ca7c",
    [array] $Targets = @('x64'),
    [switch] $ForceShared = $false,
    [array] $Patches = @(
    )
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
        "-Dprotobuf_BUILD_SHARED_LIBS:BOOL=$($OnOff[$script:Shared.isPresent])"
        "-Dprotobuf_BUILD_TESTS:BOOL=OFF"
        "-Dprotobuf_MSVC_STATIC_RUNTIME:BOOL=OFF"
        "-Dprotobuf_BUILD_PROTOC_BINARIES:BOOL=ON"
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