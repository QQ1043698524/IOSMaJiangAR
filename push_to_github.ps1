$ErrorActionPreference = "Stop"

function Test-Command($command) {
    return (Get-Command $command -ErrorAction SilentlyContinue) -ne $null
}

Write-Host "Checking Git environment..." -ForegroundColor Cyan

if (-not (Test-Command "git")) {
    Write-Host "Error: Git command not found. Please install Git for Windows." -ForegroundColor Red
    Pause
    exit 1
}

$gitVersion = git --version
Write-Host "Git is ready: $gitVersion" -ForegroundColor Green

# Proxy settings
$proxyPort = Read-Host "Enter proxy port (e.g., 7890, press Enter to skip)"
if ($proxyPort -match "^\d+$") {
    $proxyUrl = "http://127.0.0.1:$proxyPort"
    Write-Host "Setting Git proxy to $proxyUrl ..." -ForegroundColor Yellow
    git config --global http.proxy $proxyUrl
    git config --global https.proxy $proxyUrl
} else {
    Write-Host "Skipping proxy setup." -ForegroundColor Gray
}

# Init repo
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..."
    git init
}

# Config user (if needed)
try {
    git config user.name
} catch {
    git config user.name "AI Assistant"
    git config user.email "ai@assistant.com"
}

# Add files
Write-Host "Adding files..."
git add .

# Commit
$status = git status --porcelain
if ($status) {
    Write-Host "Committing changes..."
    git commit -m "Initial commit of iOS MaJiang AR project"
} else {
    Write-Host "No changes to commit."
}

# Remote
$remoteUrl = "https://github.com/QQ1043698524/IOSMaJiangAR.git"
$remotes = git remote
if ($remotes -contains "origin") {
    Write-Host "Updating origin URL..."
    git remote set-url origin $remoteUrl
} else {
    Write-Host "Adding remote origin..."
    git remote add origin $remoteUrl
}

# Push
Write-Host "Pushing code to GitHub..." -ForegroundColor Cyan
Write-Host "Note: You may need to enter your GitHub credentials in the popup window." -ForegroundColor Yellow
git branch -M main
try {
    git push -u origin main
    Write-Host "Push SUCCESS!" -ForegroundColor Green
    Write-Host "Visit https://github.com/QQ1043698524/IOSMaJiangAR/actions to see build progress." -ForegroundColor Cyan
} catch {
    Write-Host "Push FAILED. Please check your network or credentials." -ForegroundColor Red
    Write-Error $_
}

# Cleanup proxy
if ($proxyPort -match "^\d+$") {
    $cleanup = Read-Host "Remove Git global proxy settings? (Y/n)"
    if ($cleanup -ne "n") {
        git config --global --unset http.proxy
        git config --global --unset https.proxy
        Write-Host "Git proxy settings removed."
    }
}

Pause
