if [ -n "$SSH_CONNECTION" ] && [ -z "$ZLOGIN_SOURCED" ]; then
    export ZLOGIN_SOURCED=1
    
    echo ""
    echo "=========================================="
    
    # 【终极防截断逻辑】优先从 systemd 日志提取，完美支持完整 IPv6 喵！
    # 注意：Debian 系统中 SSH 服务名通常为 ssh.service 而不是 sshd.service 喵~
    LAST_LOG=$(journalctl -u ssh.service --grep="Accepted.*for $USER" -n 1 --no-pager -q -o short-iso 2>/dev/null | tail -n 1)
    
    # 如果 journalctl 没权限或没找到，优雅回退到传统的 /var/log/auth.log 喵~
    if [ -z "$LAST_LOG" ]; then
        LAST_LOG=$(grep "Accepted.*for $USER" /var/log/auth.log 2>/dev/null | tail -n 1)
    fi
    
    if [ -n "$LAST_LOG" ]; then
        # 智能判断日志来源格式并提取时间
        if echo "$LAST_LOG" | grep -q "T[0-9][0-9]:[0-9][0-9]"; then
            # journalctl 格式: 2026-08-25T05:57:07+08:00 -> 转换为 2026-08-25 05:57:07
            LAST_TIME=$(echo "$LAST_LOG" | awk '{print $1}' | sed 's/T/ /; s/[+-].*//')
        else
            # auth.log 格式: Aug 25 05:57:07
            LAST_TIME=$(echo "$LAST_LOG" | awk '{print $1, $2, $3}')
        fi
        
        # 提取 IP (精准定位 "from" 关键字后的字段，IPv4/IPv6 通吃，绝不截断喵！)
        LAST_IP=$(echo "$LAST_LOG" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}')
        
        echo "上次登录: $LAST_TIME"
        echo "来源 IP : $LAST_IP"
    else
        # 【最终回退】如果日志都读不到，才使用 last 命令 (加上 -w 参数尽量防止截断)
        LAST_INFO=$(last -w -n 50 "$USER" 2>/dev/null | awk -v user="$USER" '$1 == user && $0 !~ /still logged in/ && $0 !~ /wtmp begins/ {print; exit}')
        
        if [ -n "$LAST_INFO" ]; then
            LAST_IP=$(echo "$LAST_INFO" | awk '{print $3}')
            LAST_TIME=$(echo "$LAST_INFO" | awk '{
                for(i=4; i<=NF; i++) {
                    if ($i == "-" || $i == "down" || $i == "still") break;
                    printf "%s ", $i;
                }
                print ""
            }' | sed 's/ *$//')
            
            # 智能检测：如果 IP 长度正好是 16 且包含多个冒号，说明被 last 命令截断了喵！
            if [ "${#LAST_IP}" -eq 16 ] && [[ "$LAST_IP" == *":"*":"* ]]; then
                LAST_IP="$LAST_IP (可能被截断)"
            fi
            
            echo "上次登录: $LAST_TIME"
            echo "来源 IP : $LAST_IP"
        else
            echo "没有查询到上次登录日志喵~"
        fi
    fi
    
    # 获取当前真实来源 IP
    CURRENT_IP=$(echo "$SSH_CLIENT" | awk '{print $1}')
    echo "当前来源: $CURRENT_IP"
    echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Ciallo～(∠・ω< )⌒★"
    echo "=========================================="
fi
