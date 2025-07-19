
param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$ZipPath = "DXMatrix-Win11-$Version.zip"
)

# Define variables
$title = "DXMatrix Edition for Windows 11 (CPU-only) - $Version"
$notes = @"
## 🚀 DXMatrix $Version - Windows Native Release

✅ Runs without Docker, WSL, or Linux  
✅ CPU-only build (no CUDA needed)  
🖥️ Native execution on Windows 11  
🎮 Based on Open WebUI with DXMatrix enhancements

> For full installation instructions, see \`STARTUP-GUIDE.md\`

"@

# 1. Install GitHub CLI (gh) (If not already installed)
Write-Host "1. Checking and installing GitHub CLI (gh)..." -ForegroundColor Yellow
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI (gh) not found. Attempting to install via winget..." -ForegroundColor Cyan
    try {
        winget install --id GitHub.cli -e --accept-package-agreements --accept-source-agreements
        Write-Host "GitHub CLI installed successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to install GitHub CLI via winget. Please install it manually from https://cli.github.com/ or ensure winget is set up correctly."
        exit 1
    }
} else {
    Write-Host "GitHub CLI (gh) is already installed." -ForegroundColor Green
}

# 2. Authenticate with GitHub CLI
Write-Host "2. Authenticating with GitHub CLI..." -ForegroundColor Yellow
try {
    gh auth status -t > $null 2>&1
    Write-Host "Already authenticated with GitHub CLI." -ForegroundColor Green
} catch {
    Write-Host "Not authenticated with GitHub CLI. Please follow the browser prompts to log in." -ForegroundColor Cyan
    gh auth login --web --hostname github.com
    Write-Host "Authentication complete." -ForegroundColor Green
}

# 3. Prepare Your Build Artifact
Write-Host "3. Preparing build artifact..." -ForegroundColor Yellow
$currentDir = Get-Location
$buildSourcePath = Join-Path $currentDir "OWUI_DXMatrix_Edition" # Assuming your build is in this directory
$destinationZipPath = Join-Path $currentDir $ZipPath

if (Test-Path $destinationZipPath) {
    Remove-Item $destinationZipPath -Force
    Write-Host "Removed existing zip file: $destinationZipPath" -ForegroundColor Yellow
}

Write-Host "Compressing archive from '$buildSourcePath' to '$destinationZipPath'..." -ForegroundColor Cyan
try {
    Compress-Archive -Path $buildSourcePath -DestinationPath $destinationZipPath -Force
    Write-Host "Build artifact '$ZipPath' created successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to create ZIP archive. Please ensure the path '$buildSourcePath' exists and you have write permissions."
    exit 1
}

# 4. Tag the Commit
Write-Host "4. Tagging the commit..." -ForegroundColor Yellow
try {
    git add .
    git commit -m "Prepare $Version Windows release"
    git tag -a $Version -m "DXMatrix Edition - CPU-only native Windows build $Version"
    git push origin main --tags
    Write-Host "Commit tagged and pushed successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to tag commit or push to origin. Ensure you are in a Git repository and have permissions."
    exit 1
}

# 5. Create the GitHub Release via PowerShell
Write-Host "5. Creating the GitHub Release..." -ForegroundColor Yellow
try {
    gh release create $Version $destinationZipPath --title "$title" --notes "$notes"
    Write-Host "GitHub Release '$Version' created successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to create GitHub Release. Please check your network connection, permissions, and ensure the tag does not already exist."
    exit 1
}

Write-Host "Script finished." -ForegroundColor Green 