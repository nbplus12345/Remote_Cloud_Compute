#!/bin/bash
# ==============================================================================
# 脚本名称: setup_linux_compute.sh
# 功能描述: Ubuntu 算力端一键环境配置 (ZeroTier + SSH + tmux + 电源/权限优化)
# 作者: nbplus12345
# ==============================================================================

# 定义颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}      Linux 算力端一键配置脚本启动                ${NC}"
echo -e "${GREEN}==================================================${NC}"

# 1. 检查 root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[错误] 请使用 sudo 运行此脚本！(例如: sudo bash setup_linux_compute.sh)${NC}"
  exit 1
fi

# 获取执行 sudo 的真实用户名（不能把环境配给 root）
REAL_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(eval echo ~$REAL_USER)

# 2. 基础工具安装
echo -e "\n${YELLOW}[1/5] 更新软件源并安装基础工具 (curl, openssh-server, tmux)...${NC}"
apt update -y
apt install -y curl openssh-server tmux

# 3. 安装并配置 ZeroTier
echo -e "\n${YELLOW}[2/5] 检查并安装 ZeroTier...${NC}"
if command -v zerotier-cli &> /dev/null; then
    echo -e "${GREEN}  -> ZeroTier 已安装，跳过下载。${NC}"
else
    echo -e "  -> 正在拉取 ZeroTier 官方脚本并安装..."
    curl -s https://install.zerotier.com | bash
fi

# 交互式输入 Network ID
read -p "请输入你的 ZeroTier Network ID (按回车跳过): " ZT_NETWORK_ID
if [ ! -z "$ZT_NETWORK_ID" ]; then
    zerotier-cli join "$ZT_NETWORK_ID"
    echo -e "${GREEN}  -> 已发送加入网络请求，请前往 ZeroTier 网页后台打勾授权！${NC}"
fi

# 4. 配置 SSH 与免密登录白名单
echo -e "\n${YELLOW}[3/5] 配置 SSH 服务与免密登录目录...${NC}"
systemctl enable ssh
systemctl start ssh

# 为真实用户创建 .ssh 目录并设置权限
mkdir -p "$USER_HOME/.ssh"
touch "$USER_HOME/.ssh/authorized_keys"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chown -R $REAL_USER:$REAL_USER "$USER_HOME/.ssh"

echo -e "${GREEN}  -> SSH 服务已启动。.ssh 目录结构已初始化 (${USER_HOME}/.ssh)。${NC}"
read -p "请粘贴你笔记本电脑的 SSH 公钥(id_rsa.pub)内容 (按回车跳过手动配置): " SSH_PUB_KEY
if [ ! -z "$SSH_PUB_KEY" ]; then
    echo "$SSH_PUB_KEY" >> "$USER_HOME/.ssh/authorized_keys"
    echo -e "${GREEN}  -> 公钥已写入 authorized_keys，实现免密登录！${NC}"
fi

# 5. 屏蔽系统休眠 (防止训练断网)
echo -e "\n${YELLOW}[4/5] 正在屏蔽系统休眠与挂起机制...${NC}"
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
echo -e "${GREEN}  -> 系统休眠已彻底关闭。${NC}"

# 6. 炼丹专属：GPU 权限配置
echo -e "\n${YELLOW}[5/5] 配置深度学习硬件权限...${NC}"
usermod -aG video $REAL_USER
usermod -aG render $REAL_USER
echo -e "${GREEN}  -> 用户 ${REAL_USER} 已加入 video 和 render 组 (解决 PyTorch 无法识别 GPU 权限问题)。${NC}"

echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN}配置全部完成！${NC}"
echo -e "你可以使用 ${YELLOW}tmux new -s train${NC} 来开启一个后台守护窗口。"
echo -e "注意：部分 GPU 权限组的修改可能需要 ${RED}重启电脑${NC} 才能完全生效。"
echo -e "${GREEN}==================================================${NC}"