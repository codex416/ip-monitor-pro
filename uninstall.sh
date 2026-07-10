#!/bin/bash

# ==========================================
# IP Monitor Pro 卸载脚本
# ==========================================


APP_DIR="/opt/ip-monitor"


echo "======================================"

echo " IP Monitor Pro Uninstaller"

echo "======================================"



if [ "$EUID" -ne 0 ]; then

    echo "请使用 root 用户运行"

    exit 1

fi



echo

echo "停止服务..."



systemctl stop ip-monitor 2>/dev/null || true

systemctl stop telegram-bot 2>/dev/null || true



echo

echo "关闭开机启动..."



systemctl disable ip-monitor 2>/dev/null || true

systemctl disable telegram-bot 2>/dev/null || true



echo

echo "删除systemd文件..."



rm -f /etc/systemd/system/ip-monitor.service

rm -f /etc/systemd/system/telegram-bot.service



systemctl daemon-reload



echo

echo "删除程序目录..."



rm -rf "$APP_DIR"



echo

echo "======================================"

echo "卸载完成"

echo "======================================"



echo

echo "注意："

echo "- GitHub仓库不会删除"

echo "- Telegram机器人不会删除"

echo "- VPS系统依赖不会删除"
