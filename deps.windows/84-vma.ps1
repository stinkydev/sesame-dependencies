param(
    [string] $Name = 'vma',
    [string] $Version = '3.1.0-dev+a53702cb',
    [string] $Uri = 'https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git',
    [string] $Hash = 'a53702cbe2289b3c37f0904290ad2b03f703d0df',
    [array] $Targets = @('x64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    New-Item -Path "$($ConfigData.OutputPath)/include/vma" -ItemType Directory -Force *> $null

    Log-Output "include/vk_mem_alloc.h => $($ConfigData.OutputPath)/include/vma"
    Copy-Item -Path 'include/vk_mem_alloc.h' -Destination "$($ConfigData.OutputPath)/include/vma"
}
