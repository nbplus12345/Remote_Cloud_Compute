<#
.SYNOPSIS
    Windows 算力端一键环境配置脚本 (基于 ZeroTier + SSH 架构)

.DESCRIPTION
    此脚本用于自动化配置 Windows 台式机作为远程深度学习服务器，
    包含：权限检测、OpenSSH 服务端部署、防火墙放行、电源管理（防休眠）等核心步骤。

.NOTES
    作者: nbplus12345
    项目链接: github.com/nbplus12345
#>

# 1. 检查是否以管理员身份运行
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[错误] 权限不足！请右键点击 PowerShell，选择“以管理员身份运行”后再执行此脚本。" -ForegroundColor Red
    Exit
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      Windows 算力端一键配置脚本启动              " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 2. 安装 OpenSSH 服务器
Write-Host "`n[1/4] 正在检测并安装 OpenSSH 服务器..." -ForegroundColor Yellow
$sshState = Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
if ($sshState.State -eq 'Installed') {
    Write-Host "  -> OpenSSH 服务器已安装，跳过下载。" -ForegroundColor Green
} else {
    Write-Host "  -> 开始联网下载 OpenSSH 服务器 (如果在此处卡死，请参考教程手动离线安装)..." -ForegroundColor Magenta
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
    Write-Host "  -> OpenSSH 服务器安装完成！" -ForegroundColor Green
}

# 3. 配置并启动 SSH 服务
Write-Host "`n[2/4] 正在配置 SSH 服务及开机自启..." -ForegroundColor Yellow
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType 'Automatic'
Write-Host "  -> sshd 服务已启动并设置为开机自启。" -ForegroundColor Green

# 4. 配置 Windows 防火墙 (放行 22 端口)
Write-Host "`n[3/4] 正在配置防火墙规则..." -ForegroundColor Yellow
$fwRuleName = "OpenSSH-Server-In-TCP-Custom"
$fwRule = Get-NetFirewallRule -Name $fwRuleName -ErrorAction SilentlyContinue

if ($null -eq $fwRule) {
    New-NetFirewallRule -Name $fwRuleName -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    Write-Host "  -> 已成功在防火墙上放行 TCP 22 端口。" -ForegroundColor Green
} else {
    Write-Host "  -> 防火墙规则已存在，跳过配置。" -ForegroundColor Green
}

# 5. 配置电源管理 (禁止休眠，保障训练不中断)
Write-Host "`n[4/4] 正在配置电源选项 (防止系统断网挂起)..." -ForegroundColor Yellow
# 设置接通电源时，睡眠时间为“从不” (0)
powercfg /change standby-timeout-ac 0
# 设置接通电源时，关闭显示器时间为“从不” (0) - 可选，你也可以设为 10
powercfg /change monitor-timeout-ac 0
Write-Host "  -> 电源计划已修改：永不休眠，永不关闭显示器。" -ForegroundColor Green

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "配置完成！接下来请确保你已安装 ZeroTier 客户端。" -ForegroundColor Cyan
Write-Host "你可以使用以下命令加入你的虚拟网络：" -ForegroundColor Cyan
Write-Host "zerotier-cli join <你的Network ID>" -ForegroundColor White -BackgroundColor Black
Write-Host "==================================================" -ForegroundColor Cyan