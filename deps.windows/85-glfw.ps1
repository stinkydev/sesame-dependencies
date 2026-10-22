param(
    [string] $Name = 'glfw',
    [string] $Version = '3.3.2',
    [string] $Uri = 'https://github.com/glfw/glfw.git',
    [string] $Hash = '0a49ef0a00baa3ab520ddc452f0e3b1e099c5589',
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

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$script:Shared.isPresent])"
        '-DGLFW_BUILD_DOCS:BOOL=OFF'
        '-DGLFW_BUILD_EXAMPLES:BOOL=OFF'
        '-DGLFW_BUILD_TESTS:BOOL=OFF'
        '-DUSE_MSVC_RUNTIME_LIBRARY_DLL:BOOL=ON'
        # glfw 3.3.2 declares cmake_minimum_required(VERSION 3.0), which CMake 4 rejects.
        '-DCMAKE_POLICY_VERSION_MINIMUM=3.5'
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
