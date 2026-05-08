# Remote-Cloud-Compute: 异构系统下的个人云算力平台搭建
[![License|78](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
## 简介 / Introduction
本项目提供了一套完整的自动化脚本与架构指南，旨在解决 AI 开发者在异构系统（Windows / Linux）下远程调用本地高配硬件算力的网络与环境痛点。通过集成 SD-WAN 虚拟局域网、SSH 隧道通信、IoT 硬件唤醒及进程守护技术，实现随时随地的低延迟“云端炼丹”。
详细图文教程：[保姆级教程：把家里的台式机变成深度学习“云算力”（基于 ZeroTier 与 SSH 隧道实践）](https://blog.csdn.net/weixin_53384391/article/details/160889805?spm=1001.2014.3001.5502)
## 亮点 / Features
- **零成本内网穿透**：基于 ZeroTier SD-WAN，跨越 NAT 限制，分配固定虚拟局域网 IP。
    
- **安全加密通信**：构建 VS Code Client-Server 架构，底层由 SSH 隧道进行加密传输。
    
- **物理级高可用**：结合 IoT 智能插座与主板 `AC Recovery`（断电恢复）机制，实现 100% 成功率的远程硬件唤醒。
    
- **进程级守护**：Linux 端自动集成 `tmux` 守护后台进程；Windows/Linux 端双重防休眠机制，保障长周期训练不中断。
    
- **自动化部署**：提供跨平台双端一键配置脚本，自动完成网络握手、服务注册、端口放行及 PyTorch 硬件权限分配。
## 架构说明 / Architecture
1. **控制端 (Client)**：轻薄本 / 随身设备（安装 VS Code + Remote-SSH + ZeroTier 客户端）。
    
2. **底层链路 (Network)**：ZeroTier P2P 虚拟局域网。
    
3. **算力端 (Server)**：部署在家中/宿舍的高配台式机（执行本项目提供的一键配置脚本）。
## 快速开始 / Quick Start
### 1. 前置准备 / Prerequisites

- 注册 [ZeroTier](https://www.zerotier.com/) 账号，创建一个网络并获取 `Network ID`。
    
- 准备一个支持 App 远程控制的智能插座，并在台式机主板 BIOS 中开启 `Restore on AC Power Loss` (来电自启) 功能。
    
### 2. 算力端部署 / Server Setup
请根据算力端台式机的操作系统，选择对应的脚本执行：
####  路线 A: Linux (Ubuntu) 端部署
将 `setup_linux_compute.sh` 下载到台式机并执行：
```Bash
chmod +x setup_linux_compute.sh
sudo ./setup_linux_compute.sh
```
_脚本将自动安装 ZeroTier、OpenSSH、tmux，并配置显卡识别权限 (video/render)。执行后请根据提示输入 ZeroTier Network ID 与公钥。_
#### 路线 B: Windows 端部署
将 `setup_windows_compute.ps1` 下载到台式机，右键 PowerShell 选择**以管理员身份运行**：
```PowerShell
# 1. 允许执行本地脚本
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# 2. 运行配置脚本
.\setup_windows_compute.ps1
```
_脚本将自动部署 OpenSSH Server、配置开机自启、在防火墙放行 TCP 22 端口并修改电源防休眠计划。_

> ⚠️ **注意**：算力端脚本执行完毕后，请务必登录 ZeroTier 网页端后台，在 `Member Devices` 列表中勾选新加入的设备以完成授权，并获取虚拟 IP。
### 3. 控制端连接 / Client Connection

1. 在控制端设备上安装 ZeroTier 客户端并加入同一个 `Network ID`。
    
2. 打开 VS Code，安装 `Remote - SSH` 插件。
    
3. 修改控制端的 `~/.ssh/config` 文件，添加算力端节点：
    
```Plaintext
Host My-ML-Workspace
    HostName [填写算力端在 ZeroTier 中的虚拟 IP]
    User [填写算力端的系统用户名]
```

4. 在 VS Code 中点击连接，开启你的远程炼丹之旅！
