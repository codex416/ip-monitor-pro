#!/bin/bash

# ==========================================
# IP Monitor Pro GFW Check
# 中国网络连通性检测
# ==========================================


APP_DIR="/opt/ip-monitor"

CONFIG="$APP_DIR/config.conf"

STATE_DIR="$APP_DIR/state"

LOG_FILE="$APP_DIR/logs/gfw.log"

TG_SCRIPT="$APP_DIR/telegram.sh"



source "$CONFIG"


mkdir -p "$STATE_DIR"

mkdir -p "$(dirname $LOG_FILE)"



log(){

echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"

}



send_tg(){

if [ "$TG_NOTIFY" = true ]; then

bash "$TG_SCRIPT" "$1"

fi

}



# ==========================================
# 中国网站检测
# ==========================================


check_cn_sites(){


SITES="
https://www.baidu.com
https://www.qq.com
https://www.taobao.com
"



OK=0

FAIL=0


RESULT=""



for SITE in $SITES

do


CODE=$(curl \
-k \
-L \
--connect-timeout 5 \
-o /dev/null \
-s \
-w "%{http_code}" \
"$SITE")



if [ "$CODE" = "200" ] || [ "$CODE" = "301" ] || [ "$CODE" = "302" ]; then


RESULT+="$(echo $SITE | awk -F/ '{print $3}') ✅\n"

OK=$((OK+1))


else


RESULT+="$(echo $SITE | awk -F/ '{print $3}') ❌\n"

FAIL=$((FAIL+1))


fi


done



echo -e "$RESULT" > "$STATE_DIR/cn_sites"



if [ "$FAIL" -ge 2 ]; then

echo "FAIL"

else

echo "OK"

fi



}




# ==========================================
# TCP Reset检测
# ==========================================


check_rst(){


RST=$(timeout 10 tcpdump \
-nn \
-i any \
"tcp[tcpflags] & tcp-rst != 0" \
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


CN_STATUS=$(check_cn_sites)

RST_STATUS=$(check_rst)



if [ "$CN_STATUS" = "FAIL" ] || [ "$RST_STATUS" = "RST" ];then


STATUS="SUSPECT_GFW"


else


STATUS="NORMAL"


fi



OLD=""


if [ -f "$STATE_DIR/gfw_status" ];then

OLD=$(cat "$STATE_DIR/gfw_status")

fi



echo "$STATUS" > "$STATE_DIR/gfw_status"



if [ "$STATUS" != "$OLD" ];then


if [ "$STATUS" = "SUSPECT_GFW" ];then



REPORT=$(cat "$STATE_DIR/cn_sites")



send_tg "
🚨 <b>GFW检测报警</b>


状态:
疑似异常


中国网站检测:

<pre>
$REPORT
</pre>


TCP:

$RST_STATUS


时间:

$(date)
"



log "GFW suspect"



else



send_tg "
✅ <b>网络恢复正常</b>


时间:

$(date)
"



fi



fi
