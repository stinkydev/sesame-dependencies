param(
    [string] $Name = 'FFmpeg',
    [string] $Version = '7.1',
    [string] $Uri = 'https://github.com/FFmpeg/FFmpeg.git',
    [string] $Hash = "b08d7969c550a804a59511c7b83f2dd8cc0499b8",
    [array] $Patches = @(
    ),
    [array] $Targets = @('x64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path

    if ( ! ( $SkipAll -or $SkipDeps ) ) {
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar nasm
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar make
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar perl
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar pkgconf
    }
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

    $TargetCPUs = @{
        x64 = 'x86_64'
        x86 = 'x86'
    }

    New-Item -ItemType Directory -Force "build_${Target}" > $null

    $ConfigureCommand = @(
        'bash'
        '../configure'
        ('--prefix="' + $($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/') + '"')
        ('--arch=' + $($TargetCPUs[$Target]))
        '--toolchain=msvc'
        ('--extra-cflags=' + "'-D_WINDLL -MD -D_WIN32_WINNT=0x0A00'")
        ('--extra-cxxflags=' + "'-MD -D_WIN32_WINNT=0x0A00'")
        ('--extra-ldflags=' + "'-APPCONTAINER:NO -MACHINE:${Target}'")
        '--pkg-config=pkg-config'
        $(if ( $Target -eq 'x64' ) { '--target-os=win64' } else { '--target-os=win32' })
        '--enable-libmp3lame'
        '--enable-w32threads'
        '--enable-version3'
        '--enable-gpl'
        '--enable-libx264'
        '--enable-libopus'
        '--enable-libvorbis'
        '--enable-libvpx'
        '--enable-shared'
        '--enable-zlib'
        '--disable-static'
        '--disable-libjack'
        '--disable-indev=jack'
        '--disable-sdl2'
        '--disable-doc'
        '--disable-postproc'
        '--disable-programs'
        '--disable-hwaccels'
        '--disable-amf'
        $(if ( ! $script:Shared ) { ('--pkg-config-flags=' + "'--static'") })
        $(if ( $Configuration -eq 'Debug' ) { '--enable-debug' } else { '--disable-debug' })
        $(if ( $Configuration -eq 'RelWithDebInfo' ) { '--disable-stripping' })
    )

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "build_${Target}"
        BuildCommand = $($ConfigureCommand -join ' ')
        Target = $Target
    }

    $Backup = @{
        CFLAGS = $env:CFLAGS
        CXXFLAGS = $env:CXXFLAGS
        PKG_CONFIG_LIBDIR = $env:PKG_CONFIG_LIBDIR
        LDFLAGS = $env:LDFLAGS
        MSYS2_PATH_TYPE = $env:MSYS2_PATH_TYPE
    }
    $env:CFLAGS = "$($script:CFlags) -I$($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/')/include"
    $env:CXXFLAGS = "$($script:CxxFlags) -I$($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/')/include"
    $env:PKG_CONFIG_LIBDIR = "$($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/')/lib/pkgconfig"
    $env:LDFLAGS = "-LIBPATH:$($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/')/lib"
    $env:MSYS2_PATH_TYPE = 'inherit'
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
    ($(Get-Content build_${Target}\config.h) -replace '[^\x20-\x7D]+', '') | Set-Content -Path build_${Target}\config.h
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "build_${Target}"
        BuildCommand = "make -j${env:NUMBER_OF_PROCESSORS}"
        Target = $Target
    }

    $Backup = @{
        MSYS2_PATH_TYPE = $env:MSYS2_PATH_TYPE
        VERBOSE = $env:VERBOSE
    }
    $env:MSYS2_PATH_TYPE = 'inherit'
    $env:VERBOSE = $(if ( $VerbosePreference -eq 'Continue' ) { '1' })
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "build_${Target}"
        BuildCommand = "make -r install"
        Target = $Target
    }

    $Backup = @{
        MSYS2_PATH_TYPE = $env:MSYS2_PATH_TYPE
        VERBOSE = $env:VERBOSE
    }
    $env:MSYS2_PATH_TYPE = 'inherit'
    $env:VERBOSE = $(if ( $VerbosePreference -eq 'Continue' ) { '1' })
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}
