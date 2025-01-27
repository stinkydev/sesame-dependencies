param(
    [string] $Name = 'srt',
    [string] $Version = '1.5.4',
    [string] $Uri = 'https://github.com/Haivision/srt/archive/refs/tags/v1.5.4.zip',
    [string] $Hash = "${PSScriptRoot}/checksums/v1.5.4.zip.sha256",
    [array] $Targets = @('x64', 'arm64'),
    [switch] $ForceShared = $true,
    [array] $Patches = @(
    )
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath .
}

function Clean {
    Set-Location "${Name}-${Version}"

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location "${Name}-${Version}"

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location "${Name}-${Version}"

   if ( $ForceShared -and ( $script:Shared -eq $false ) ) {
        $Shared = $true
    } else {
        $Shared = $script:Shared.isPresent
    }

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$script:Shared.isPresent])"
        "-DENABLE_APPS:BOOL=OFF"
        "-DENABLE_LOGGING:BOOL=OFF"
        "-DENABLE_SHARED:BOOL=$($OnOff[$script:Shared.isPresent])"
        "-DENABLE_STATIC:BOOL=ON"
        "-DENABLE_STDCXX_SYNC:BOOL=ON"
        "-DENABLE_ENCRYPTION:BOOL=ON"
        "-DOPENSSL_USE_STATIC_LIBS:BOOL=ON"
        "-DUSE_OPENSSL_PC:BOOL=OFF"
    )

    Invoke-External cmake -S . -B "build_${Target}" @Options
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location "${Name}-${Version}"

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
    Set-Location "${Name}-${Version}"

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}