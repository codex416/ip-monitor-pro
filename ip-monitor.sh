#!/bin/bash

# ==========================================
# IP Monitor Pro 核心检测程序
# ==========================================


BASE_DIR="/opt/ip-monitor"

CONFIG="$BASE_DIR/config.conf"


source $CONFIG



LOG_FILE="$BASE_DIR/logs/monitor.log"


STATE_DIR="$BASE_DIR/state"


TELEGRAM="$BASE_DIR/telegram.sh"



mkdir -p $STATE_DIR
mkdir -p $(dirname $LOG_FILE)



log(){

echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> $LOG_FILE

}



notify(){

if [ "$TG_NOTIFY" = true ];then

bash $TELEGRAM "$1"

fi

}



get_ip(){

curl -s4 "$IP_API"

}



# ==========================================
# IP变化检测
# ==========================================


check_ip(){


NEW_IP=$(get_ip)


OLD_IP=""


if [ -f "$STATE_DIR/ip" ];then

OLD_IP=$(cat "$STATE_DIR/ip")

fi



if [ "$NEW_IP" != "$OLD_IP" ] && [ -n "$OLD_IP" ];then


notify "
⚠️ IP地址变化

旧IP:
$OLD_IP

新IP:
$NEW_IP

时间:
$(date)
"


log "IP changed $OLD_IP -> $NEW_IP"


fi



echo "$NEW_IP" > "$STATE_DIR/ip"


IP="$NEW_IP"


}




# ==========================================
# 端口检测
# ==========================================


check_ports(){


RESULT=""


for PORT in $PORTS

do


timeout 5 bash -c \
"</dev/tcp/$IP/$PORT" \
>/dev/null 2>&1



if [ $? -eq 0 ];then


RESULT+="端口 $PORT ✅\n"


else


RESULT+="端口 $PORT ❌\n"


fi



done



echo -e "$RESULT" > "$STATE_DIR/ports"


echo -e "$RESULT"

}




# ==========================================
# TCP Reset检测
# ==========================================


check_rst(){


RST=$(timeout 10 tcpdump \
-nn \
-i any \
"tcp port $RST_PORT and tcp[tcpflags] & tcp-rst != 0" \
-c 1 2>/dev/null)



if [ -n "$RST" ];then


echo "RST"

else

echo "NORMAL"

fi


}




# ==========================================
# 综合判断
# ==========================================


check_status(){


PORT_FAIL=$(grep -c "❌" "$STATE_DIR/ports")

RST_STATUS=$(check_rst)



if [ "$PORT_FAIL" -gt 0 ];then


STATUS="PORT_FAIL"



elif [ "$RST_STATUS" = "RST" ];then


STATUS="GFW_RST"



else


STATUS="NORMAL"



fi



OLD_STATUS=""


if [ -f "$STATE_DIR/status" ];then

OLD_STATUS=$(cat "$STATE_DIR/status")

fi



echo "$STATUS" > "$STATE_DIR/status"



if [ "$STATUS" != "$OLD_STATUS" ];then


case "$STATUS" in



GFW_RST)


notify "
🚨 TCP Reset检测

疑似GFW干扰

IP:
$IP

端口:
$RST_PORT

时间:
$(date)
"

;;



PORT_FAIL)


notify "
⚠️ 节点端口异常

IP:
$IP


$(
cat $STATE_DIR/ports
)


时间:
$(date)
"

;;



NORMAL)


notify "
✅ 节点恢复正常

IP:
$IP

时间:
$(date)
"

;;


esac



fi



}



# ==========================================
# 主循环
# ==========================================


log "IP Monitor Pro Started"



while true

do



log "开始检测"



check_ip


check_ports


check_status



sleep $CHECK_INTERVAL



done
