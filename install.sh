#!/bin/bash

# ==========================================
# IP Monitor Pro 一键安装脚本
# GitHub版本
# ==========================================


set -e


APP_NAME="ip-monitor"

INSTALL_DIR="/opt/ip-monitor"

SERVICE_FILE="/etc/systemd/system/ip-monitor.service"


# 修改成你的GitHub仓库地址

GITHUB_REPO="https://github.com/你的用户名/ip-monitor-pro.git"



echo "================================="
echo " IP Monitor Pro Installer"
echo "================================="


if [ "$EUID" -ne 0 ]; then

    echo "请使用 root 用户运行"

    exit 1

fi



echo "[1/6] 安装依赖..."


apt update


apt install -y \
git \
curl \
jq \
tcpdump \
openssl \
net-tools



echo "[2/6] 下载程序..."


if [ -d "$INSTALL_DIR" ]; then

    echo "检测到旧目录，删除..."

    rm -rf $INSTALL_DIR

fi



git clone $GITHUB_REPO $INSTALL_DIR



echo "[3/6] 设置权限..."


chmod +x $INSTALL_DIR/*.sh



mkdir -p $INSTALL_DIR/logs

mkdir -p $INSTALL_DIR/state



echo "[4/6] 安装配置文件..."


if [ ! -f "$INSTALL_DIR/config.conf" ]; then

    cp $INSTALL_DIR/config.example.conf \
    $INSTALL_DIR/config.conf

fi



echo
echo "================================="
echo "请编辑配置文件:"
echo
echo "$INSTALL_DIR/config.conf"
echo
echo "填写 Telegram TOKEN 和 CHAT_ID"
echo "================================="


read -p "配置完成后按回车继续..."



echo "[5/6] 安装systemd服务..."



cp $INSTALL_DIR/ip-monitor.service \
$SERVICE_FILE



systemctl daemon-reload


systemctl enable ip-monitor



echo "[6/6] 启动服务..."


systemctl restart ip-monitor



echo
echo "================================="
echo "安装完成"
echo "================================="


echo

echo "查看状态:"
echo

echo "systemctl status ip-monitor"


echo

echo "查看日志:"
echo

echo "tail -f /opt/ip-monitor/logs/monitor.log"
