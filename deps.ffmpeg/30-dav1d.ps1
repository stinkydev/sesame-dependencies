param(
    [string] $Name = 'dav1d',
    [string] $Version = '1.5.1',
    [string] $Uri = 'https://code.videolan.org/videolan/dav1d.git',
    [string] $Hash = '3060ebf8dd26952579373084984daf70a54f5368',
    [array] $Targets = @('x64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path

    if ( ! ( $SkipAll -or $SkipDeps ) ) {
        # Native (mingw-w64) meson/ninja/nasm: a native meson spawns cl.exe
        # directly, so no msys path/argument conversion corrupts MSVC flags.
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar mingw-w64-x86_64-meson
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar mingw-w64-x86_64-ninja
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar mingw-w64-x86_64-nasm
    }
}

function Clean {
    Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Invoke-DavdMeson {
    param([string] $MesonArgs)

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = '.'
        BuildCommand = "bash -c 'PATH=/mingw64/bin:`$PATH meson ${MesonArgs}'"
        Target = $Target
    }

    $Backup = @{
        CC = $env:CC
        CXX = $env:CXX
        MSYS2_PATH_TYPE = $env:MSYS2_PATH_TYPE
    }
    $env:CC = 'cl'
    $env:CXX = 'cl'
    $env:MSYS2_PATH_TYPE = 'inherit'
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $MesonPrefix = $($script:ConfigData.OutputPath -replace '\\','/')

    $MesonArgs = @(
        'setup'
        "build_${Target}"
        "--prefix=${MesonPrefix}"
        '--libdir=lib'
        '--buildtype=release'
        '--default-library=static'
        '-Denable_tools=false'
        '-Denable_tests=false'
        '-Denable_examples=false'
    )

    Invoke-DavdMeson -MesonArgs $($MesonArgs -join ' ')
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    Invoke-DavdMeson -MesonArgs "compile -C build_${Target}"
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    Invoke-DavdMeson -MesonArgs "install -C build_${Target}"
}

function Fixup {
    Log-Information "Fixup (${Target})"

    # Meson names the MSVC static library libdav1d.a; FFmpeg's msvc toolchain
    # resolves -ldav1d against dav1d.lib.
    $StaticLib = "$($script:ConfigData.OutputPath)/lib/libdav1d.a"
    if ( Test-Path $StaticLib ) {
        Move-Item -Path $StaticLib -Destination "$($script:ConfigData.OutputPath)/lib/dav1d.lib" -Force
    }
}
