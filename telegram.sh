#!/bin/bash

# ==========================================
# IP Monitor Pro Telegram模块
# ==========================================


BASE_DIR="/opt/ip-monitor"


CONFIG="$BASE_DIR/config.conf"


LOG_FILE="$BASE_DIR/logs/monitor.log"


STATE_DIR="$BASE_DIR/state"



if [ ! -f "$CONFIG" ]; then

    exit 1

fi



source $CONFIG



# ==========================================
# Telegram发送消息
# ==========================================


send_message(){


TEXT="$1"


curl -s \
-X POST \
"https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
-d chat_id="${CHAT_ID}" \
-d parse_mode="HTML" \
-d text="$TEXT" \
>/dev/null



}



# ==========================================
# 设置机器人菜单
# ==========================================


set_commands(){


curl -s \
-X POST \
"https://api.telegram.org/bot${BOT_TOKEN}/setMyCommands" \
-d 'commands=[
{"command":"status","description":"查看节点状态"},
{"command":"check","description":"立即检测"},
{"command":"ip","description":"查看当前IP"},
{"command":"log","description":"查看日志"}
]' \
>/dev/null



}



# ==========================================
# 获取当前IP
# ==========================================


get_ip(){


curl -s4 "$IP_API"


}



# ==========================================
# 当前状态
# ==========================================


status(){


IP=$(get_ip)



if [ -f "$STATE_DIR/status" ];then

STATUS=$(cat "$STATE_DIR/status")

else

STATUS="UNKNOWN"

fi



PORT_STATUS=""



if [ -f "$STATE_DIR/ports" ];then

PORT_STATUS=$(cat "$STATE_DIR/ports")

fi



MSG="
🖥 <b>IP Monitor Pro</b>


🌐 IP:

<code>$IP</code>


📡 状态:

$STATUS


🔌 端口:

$PORT_STATUS


🕒 时间:

$(date '+%Y-%m-%d %H:%M:%S')
"



send_message "$MSG"


}




# ==========================================
# IP信息
# ==========================================


show_ip(){


IP=$(get_ip)



send_message "
🌐 当前IP

<code>$IP</code>

时间:
$(date '+%Y-%m-%d %H:%M:%S')
"



}



# ==========================================
# 日志
# ==========================================


show_log(){


LOG=$(tail -n 20 "$LOG_FILE")



send_message "
📜 最近日志:


<pre>
$LOG
</pre>
"


}



# ==========================================
# 立即检测
# ==========================================


manual_check(){


touch "$STATE_DIR/manual_check"



send_message "
🔍 已执行立即检测

请等待下一次检测结果。
"



}




# ==========================================
# Telegram轮询
# ==========================================


OFFSET=0



while true

do



RESULT=$(curl -s \
"https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=${OFFSET}")



COUNT=$(echo "$RESULT" | jq '.result | length')



if [ "$COUNT" -gt 0 ];then



for ((i=0;i<COUNT;i++))

do



UPDATE=$(echo "$RESULT" | jq ".result[$i]")



OFFSET=$(echo "$UPDATE" | jq '.update_id + 1')



CMD=$(echo "$UPDATE" | jq -r '.message.text')



USER=$(echo "$UPDATE" | jq -r '.message.chat.id')



if [ "$USER" != "$CHAT_ID" ];then

continue

fi



case "$CMD" in


/status)

status

;;



/ip)

show_ip

;;



/log)

show_log

;;



/check)

manual_check

;;



esac



done



fi



sleep 3



done
