#!/bin/bash

# ==========================================
# IP Monitor Pro Telegram模块
# ==========================================


APP_DIR="/opt/ip-monitor"

CONFIG="$APP_DIR/config.conf"

LOG_FILE="$APP_DIR/logs/monitor.log"

STATE_DIR="$APP_DIR/state"


source "$CONFIG"



# ==========================================
# 发送消息函数
# ==========================================


send_message(){


TEXT="$1"


curl -s \
-X POST \
"https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
-d chat_id="$CHAT_ID" \
-d parse_mode="HTML" \
--data-urlencode text="$TEXT" \
>/dev/null



}



# ==========================================
# 如果收到参数
# 说明来自监控程序
# 发送后退出
# ==========================================


if [ -n "$1" ]; then


send_message "$1"


exit 0


fi




# ==========================================
# 设置机器人菜单
# ==========================================


set_commands(){


curl -s \
-X POST \
"https://api.telegram.org/bot${BOT_TOKEN}/setMyCommands" \
-d 'commands=[
{"command":"status","description":"查看状态"},
{"command":"check","description":"立即检测"},
{"command":"ip","description":"查看IP"},
{"command":"log","description":"查看日志"}
]' \
>/dev/null


}




# ==========================================
# 获取IP
# ==========================================


get_ip(){


curl -s4 "$IP_API"


}




# ==========================================
# 状态查询
# ==========================================


show_status(){


IP=$(get_ip)



STATUS="UNKNOWN"


if [ -f "$STATE_DIR/status" ];then

STATUS=$(cat "$STATE_DIR/status")

fi



PORTS=""



if [ -f "$STATE_DIR/ports" ];then

PORTS=$(cat "$STATE_DIR/ports")

fi



send_message "
🖥 <b>IP Monitor Pro</b>


🌐 IP:

<code>$IP</code>


📡 状态:

<b>$STATUS</b>


🔌 端口:

<pre>
$PORTS
</pre>


时间:

$(date '+%Y-%m-%d %H:%M:%S')
"


}




# ==========================================
# 查看IP
# ==========================================


show_ip(){


IP=$(get_ip)


send_message "
🌐 当前IP:

<code>$IP</code>
"


}




# ==========================================
# 查看日志
# ==========================================


show_log(){


LOG=$(tail -20 "$LOG_FILE")



send_message "
📜 最近日志:

<pre>
$LOG
</pre>
"


}




# ==========================================
# 命令监听
# ==========================================


OFFSET=0


set_commands



while true

do



DATA=$(curl -s \
"https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=$OFFSET")



COUNT=$(echo "$DATA" | jq '.result|length')



if [ "$COUNT" -gt 0 ];then



for ((i=0;i<COUNT;i++))

do



UPDATE=$(echo "$DATA" | jq ".result[$i]")



OFFSET=$(echo "$UPDATE" | jq '.update_id+1')



CMD=$(echo "$UPDATE" | jq -r '.message.text')



USER_ID=$(echo "$UPDATE" | jq -r '.message.chat.id')



if [ "$USER_ID" != "$CHAT_ID" ];then

continue

fi



case "$CMD" in


/status)

show_status

;;


/ip)

show_ip

;;


/log)

show_log

;;


/check)

touch "$STATE_DIR/manual_check"

send_message "
🔍 已执行立即检测
"

;;


esac



done


fi



sleep 3


done
