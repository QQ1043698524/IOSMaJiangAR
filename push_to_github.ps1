$ErrorActionPreference = "Stop"

function Test-Command($command) {
    return (Get-Command $command -ErrorAction SilentlyContinue) -ne $null
}

Write-Host "正在检查 Git 环境..." -ForegroundColor Cyan

if (-not (Test-Command "git")) {
    Write-Host "错误: 未找到 git 命令。请先安装 Git for Windows (https://git-scm.com/download/win) 并确保添加到 PATH。" -ForegroundColor Red
    Pause
    exit 1
}

$gitVersion = git --version
Write-Host "Git 已就绪: $gitVersion" -ForegroundColor Green

# 代理配置
$proxyPort = Read-Host "请输入代理端口 (例如 7890，直接回车跳过代理设置)"
if ($proxyPort -match "^\d+$") {
    $proxyUrl = "http://127.0.0.1:$proxyPort"
    Write-Host "正在设置 Git 代理为 $proxyUrl ..." -ForegroundColor Yellow
    git config --global http.proxy $proxyUrl
    git config --global https.proxy $proxyUrl
} else {
    Write-Host "跳过代理设置。" -ForegroundColor Gray
}

# 初始化仓库
if (-not (Test-Path ".git")) {
    Write-Host "初始化 Git 仓库..."
    git init
}

# 配置提交信息（如果未配置）
try {
    git config user.name
} catch {
    git config user.name "AI Assistant"
    git config user.email "ai@assistant.com"
}

# 添加文件
Write-Host "添加文件..."
git add .

# 提交
$status = git status --porcelain
if ($status) {
    Write-Host "提交更改..."
    git commit -m "Initial commit of iOS MaJiang AR project"
} else {
    Write-Host "没有需要提交的更改。"
}

# 关联远程
$remoteUrl = "https://github.com/QQ1043698524/IOSMaJiangAR.git"
$remotes = git remote
if ($remotes -contains "origin") {
    Write-Host "远程仓库 origin 已存在，正在更新 URL..."
    git remote set-url origin $remoteUrl
} else {
    Write-Host "添加远程仓库 origin..."
    git remote add origin $remoteUrl
}

# 推送
Write-Host "准备推送代码到 GitHub..." -ForegroundColor Cyan
Write-Host "注意: 接下来的步骤可能需要您在弹出的窗口中输入 GitHub 账号密码或 Token。" -ForegroundColor Yellow
git branch -M main
try {
    git push -u origin main
    Write-Host "推送成功！" -ForegroundColor Green
    Write-Host "现在您可以访问 https://github.com/QQ1043698524/IOSMaJiangAR/actions 查看编译进度。" -ForegroundColor Cyan
} catch {
    Write-Host "推送失败。请检查网络连接或权限设置。" -ForegroundColor Red
    Write-Error $_
}

# 清理代理（可选，避免影响其他操作）
if ($proxyPort -match "^\d+$") {
    $cleanup = Read-Host "是否清除 Git 全局代理设置? (Y/n)"
    if ($cleanup -ne "n") {
        git config --global --unset http.proxy
        git config --global --unset https.proxy
        Write-Host "Git 代理已清除。"
    }
}

Pause
