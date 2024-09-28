#!/usr/bin/env pwsh
# Copyright 2020 Deta authors. All rights reserved. MIT license.

$ErrorActionPreference = 'Stop'

if ($v) {
  if ($v[0] -match "v") {
    $Version = "${v}"
  } else {
    $Version = "v${v}"
  }
}

if ($args.Length -eq 1) {
  $Version = $args.Get(0)
}

$DetaInstall = $env:DETA_INSTALL
$BinDir = if ($DetaInstall) {
  "$DetaInstall\bin"
} else {
  "$Home\.deta\bin"
}

$DetaZip = "$BinDir\deta.zip"
$DetaExe = "$BinDir\deta.exe"
$DetaOldExe = "$env:Temp\detaold.exe"
$Target = 'x86_64-windows'

# GitHub requires TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$DetaUri = if (!$Version) {
  <# $Response = Invoke-WebRequest 'https://github.com/deta/deta-cli/releases' -UseBasicParsing
  if ($PSVersionTable.PSEdition -eq 'Core') {
    $Response.Links |
      Where-Object { $_.href -like "/deta/deta-cli/releases/download/*/deta-${Target}.zip" } |
      ForEach-Object { 'https://github.com' + $_.href } |
      Select-Object -First 1
  } else {
    $HTMLFile = New-Object -Com HTMLFile
    if ($HTMLFile.IHTMLDocument2_write) {
      $HTMLFile.IHTMLDocument2_write($Response.Content)
    } else {
      $ResponseBytes = [Text.Encoding]::Unicode.GetBytes($Response.Content)
      $HTMLFile.write($ResponseBytes)
    }
    $HTMLFile.getElementsByTagName('a') |
      Where-Object { $_.href -like "about:/deta/deta-cli/releases/download/*/deta-${Target}.zip" } |
      ForEach-Object { $_.href -replace 'about:', 'https://github.com' } |
      Select-Object -First 1
  } #>
  "https://github.com/deta/deta-cli/releases/download/v1.3.3-beta/deta-${Target}.zip"
} else {
  "https://github.com/deta/deta-cli/releases/download/${Version}/deta-${Target}.zip"
}

if (!(Test-Path $BinDir)) {
  New-Item $BinDir -ItemType Directory | Out-Null
}

Invoke-WebRequest $DetaUri -OutFile $DetaZip -UseBasicParsing

if (Test-Path $DetaExe) {
  Move-Item -Path $DetaExe -Destination $DetaOldExe -Force
}

if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
  Expand-Archive $DetaZip -Destination $BinDir -Force
} else {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($DetaZip, $BinDir)
}

Remove-Item $DetaZip

$User = [EnvironmentVariableTarget]::User
$Path = [Environment]::GetEnvironmentVariable('Path', $User)
if (!(";$Path;".ToLower() -like "*;$BinDir;*".ToLower())) {
  [Environment]::SetEnvironmentVariable('Path', "$Path;$BinDir", $User)
  $Env:Path += ";$BinDir"
}

Write-Output "Deta was installed successfully to $DetaExe"
Write-Output "Run 'deta --help' to get started"