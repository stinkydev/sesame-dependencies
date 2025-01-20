$BuildArgs = @{
  PackageName = 'ffmpeg'
  Target = 'x64'
  Configuration = 'Release'
  Shared = $true
  Dependencies = (Get-ChildItem deps.ffmpeg -filter '*.ps1' | Where-Object { $_.Name -ne '99-ffmpeg.ps1' } | ForEach-Object { $_.Name -replace "[0-9]+-(.+).ps1",'$1' })
}

./Build-Dependencies.ps1 @BuildArgs