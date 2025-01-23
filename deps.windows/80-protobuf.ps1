param(
    [string] $Name = 'libprotobuf',
    [string] $Version = '3.20.3',
    [string] $Uri = 'https://github.com/protocolbuffers/protobuf.git',
    [string] $Hash = 'fe271ab76f2ad2b2b28c10443865d2af21e27e0e',
    [array] $Targets = @('x64'),
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
    $Path = Join-Path -Path $Path -ChildPath 'cmake'
    Set-Location $Path 

    $Options = @(
        $CmakeOptions
        '-Dprotobuf_BUILD_TESTS:BOOL=OFF'
        '-Dprotobuf_BUILD_SHARED_LIBS:BOOL=OFF'
        '-Dprotobuf_BUILD_PROTOC_BINARIES:BOOL=ON'
        '-Dprotobuf_MSVC_STATIC_RUNTIME:BOOL=OFF'
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
    if (-not ($Path -like '*\cmake')) {
      $Path = Join-Path -Path $Path -ChildPath 'cmake'
    }
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
