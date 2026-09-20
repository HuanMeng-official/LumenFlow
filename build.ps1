# LumenFlow build script -- Windows / Android
#
# Usage:  .\build.ps1
#
# Injects the build date so the About page can show a real build timestamp
# instead of a value derived from runtime DateTime.now().

$ErrorActionPreference = 'Stop'

$buildDate = Get-Date -Format 'yyyy-MM-dd'

$choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
    [System.Management.Automation.Host.ChoiceDescription]::new('&Windows'),
    [System.Management.Automation.Host.ChoiceDescription]::new('&Android')
)

$selected = $Host.UI.PromptForChoice(
    'Build Target',
    'Select the platform to build:',
    $choices,
    0
)

switch ($selected) {
    0 {
        Write-Output "Building Windows (release), BUILD_DATE=$buildDate"
        flutter build windows --release --dart-define=BUILD_DATE=$buildDate
    }
    1 {
        Write-Output "Building Android (release, split-per-abi), BUILD_DATE=$buildDate"
        flutter build apk --release --split-per-abi --dart-define=BUILD_DATE=$buildDate
    }
}

exit $LASTEXITCODE
