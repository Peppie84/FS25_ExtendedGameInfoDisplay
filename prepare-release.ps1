#
# Use this script to generate a zip file to upload to farmingsimulators modhub
#
$modDirectory = Split-Path -Path $pwd -Leaf
$modName = "$modDirectory";
$origModName = $modName
$modDescFileName = "$modDirectory/modDesc.xml"
$testRunnerLogPath = ".\.testrunner\"
$readmeFilePath = "README.md"
$isDevelopmentVersion = 0

$xmlData = [xml] (Get-Content $modDescFileName -Encoding UTF8)
$currentVersion = $xmlData.modDesc.version

$newVersion = read-host -Prompt "Please enter a new version (like: a.b.c.d). Current Version is: $currentVersion "
if (([string]::IsNullOrEmpty($newVersion)))
{
    $newVersion = "$currentVersion"
}

# Check if we have a update version
if ( $newVersion -ne "1.0.0.0" )
{
    $modName = "$($modName)_update"
}

$devVersionConfirmation = read-host -Prompt "DEV version? (y/N) "
if ($devVersionConfirmation -eq 'y') {
    $currentGitHash = ((git rev-parse --short HEAD) | Out-String).Trim()
    $newVersion = "$newVersion-$currentGitHash"
    $isDevelopmentVersion = 1
    $modName = "$($origModName)_dev_release"
}

# Write new moddesc version
$xmlData = [xml] (Get-Content $modDescFileName -Encoding UTF8)
$backupXmlData = $xmlData.Clone()
$xmlData.modDesc.version = "$newVersion"

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
$xmlStreamWriter = New-Object System.IO.StreamWriter($modDescFileName, $false, $utf8WithoutBom)

$xmlData.Save( $xmlStreamWriter )
$xmlStreamWriter.Close()

# Write new readme version
((Get-Content -path $readmeFilePath -Raw) -replace "Modhub-v$currentVersion","Modhub-v$newVersion") | Set-Content -NoNewline -Path $readmeFilePath

# Make test run (add testrunner path to your environment path)
New-Item -ItemType Directory -Force -Path "$testRunnerLogPath"
LS25TestRunner_public --logPath "$testRunnerLogPath" --outputPath "$testRunnerLogPath" --noPause "$modDirectory\"

# Make zip file
7z a -bd -stl -tzip -mx=9 "$modName.zip" "$modDirectory/."

# Write old moddesc version back if we have a dev version
if ($isDevelopmentVersion -eq '1') {
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    $xmlStreamWriter = New-Object System.IO.StreamWriter($modDescFileName, $false, $utf8WithoutBom)

    $backupXmlData.Save( $xmlStreamWriter )
    $xmlStreamWriter.Close()

    # Write new readme version
    ((Get-Content -path $readmeFilePath -Raw) -replace "Modhub-v$newVersion","Modhub-v$currentVersion") | Set-Content -NoNewline -Path $readmeFilePath
}
