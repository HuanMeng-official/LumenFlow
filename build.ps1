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
        Write-Output "Building Android universal APK (release), BUILD_DATE=$buildDate"
        flutter build apk --release --dart-define=BUILD_DATE=$buildDate
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Move-Item `
            'build/app/outputs/flutter-apk/app-release.apk' `
            'build/app/outputs/flutter-apk/app-universal-release.apk' `
            -Force

        Write-Output "Building Android split APKs (release), BUILD_DATE=$buildDate"
        flutter build apk --release --split-per-abi --dart-define=BUILD_DATE=$buildDate
    }
}

exit $LASTEXITCODE
