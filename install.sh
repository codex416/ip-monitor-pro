#!/bin/bash

# ==========================================
# IP Monitor Pro 自动安装脚本
# GitHub版本
# ==========================================


set -e


APP_NAME="ip-monitor"

INSTALL_DIR="/opt/ip-monitor"


SYSTEMD_DIR="/etc/systemd/system"


REPO="https://github.com/codex416/ip-monitor-pro.git"



echo "======================================"
echo " IP Monitor Pro Installer"
echo "======================================"



# 检查root

if [ "$EUID" -ne 0 ]; then

    echo "请使用 root 用户运行"

    exit 1

fi



echo

echo "[1/7] 更新系统依赖..."



apt update



apt install -y \
git \
curl \
jq \
tcpdump \
openssl \
net-tools



echo

echo "[2/7] 下载GitHub项目..."



if [ -d "$INSTALL_DIR" ]; then

    echo "检测到旧版本"

    echo "正在删除旧文件..."

    rm -rf "$INSTALL_DIR"

fi



git clone "$REPO" "$INSTALL_DIR"



echo

echo "[3/7] 设置权限..."



chmod +x "$INSTALL_DIR"/*.sh



mkdir -p "$INSTALL_DIR/logs"

mkdir -p "$INSTALL_DIR/state"




echo

echo "[4/7] 创建配置文件..."



if [ ! -f "$INSTALL_DIR/config.conf" ]; then


    if [ -f "$INSTALL_DIR/config.example.conf" ]; then


        cp \
        "$INSTALL_DIR/config.example.conf" \
        "$INSTALL_DIR/config.conf"


    fi


fi



echo

echo "======================================"

echo "请编辑配置文件："

echo

echo "$INSTALL_DIR/config.conf"

echo

echo "填写："

echo "BOT_TOKEN"

echo "CHAT_ID"

echo

echo "完成后按回车继续"

echo "======================================"



read



# 检查配置


if grep -q "YOUR_TELEGRAM_BOT_TOKEN" \
"$INSTALL_DIR/config.conf"; then


echo

echo "错误：Telegram TOKEN 未配置"

echo "请修改 config.conf 后重新运行"

exit 1


fi




echo

echo "[5/7] 安装systemd服务..."



cp \
"$INSTALL_DIR/ip-monitor.service" \
"$SYSTEMD_DIR/ip-monitor.service"



cp \
"$INSTALL_DIR/telegram-bot.service" \
"$SYSTEMD_DIR/telegram-bot.service"




echo

echo "[6/7] 启动服务..."



systemctl daemon-reload



systemctl enable ip-monitor

systemctl enable telegram-bot



systemctl restart ip-monitor

systemctl restart telegram-bot




echo

echo "[7/7] 检查状态..."



sleep 3



echo

echo "======================================"

echo " IP Monitor Pro 安装完成"

echo "======================================"



echo

echo "检测服务:"

systemctl --no-pager status ip-monitor | head -10



echo

echo "Telegram服务:"

systemctl --no-pager status telegram-bot | head -10



echo

echo "日志查看："

echo

echo "检测日志:"
echo "tail -f /opt/ip-monitor/logs/monitor.log"

echo

echo "Telegram日志:"
echo "tail -f /opt/ip-monitor/logs/telegram.log"

echo

echo "卸载:"
echo "/opt/ip-monitor/uninstall.sh"
