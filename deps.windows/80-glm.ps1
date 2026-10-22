param(
    [string] $Name = 'glm',
    [string] $Version = '0.9.9.8',
    [string] $Uri = 'https://github.com/g-truc/glm.git',
    [string] $Hash = 'bf71a834948186f4097caa076cd2663c69a10e1e',
    [array] $Targets = @('x64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    New-Item -Path "$($ConfigData.OutputPath)/include" -ItemType Directory -Force *> $null

    Log-Output "glm => $($ConfigData.OutputPath)/include"
    Copy-Item -Path glm -Destination "$($ConfigData.OutputPath)/include" -Recurse -Force
    Remove-Item -Path "$($ConfigData.OutputPath)/include/glm/CMakeLists.txt" -Force
}
