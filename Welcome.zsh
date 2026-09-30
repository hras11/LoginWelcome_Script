#!/usr/bin/env zsh
# SSH 登录欢迎横幅（zsh）。
# 必须用 source（或 `.`）引入，`ZLOGIN_SOURCED` 去重标记才能生效；
# 写成 `zsh Welcome.zsh` 或只在 .zshrc 里放一个裸路径，都会在子 shell 执行，标记随进程退出而丢失。

if [ -n "$SSH_CONNECTION" ] && [ -z "$ZLOGIN_SOURCED" ]; then
    export ZLOGIN_SOURCED=1

    # 包一层函数：所有临时变量随函数结束销毁，不污染交互 shell 的环境。
    _lw_show() {
        local me current_ip last_log last_time last_ip f info awk_prev
        me=${USER:-${LOGNAME:-$(id -un)}}
        current_ip=$(echo "${SSH_CLIENT:-$SSH_CONNECTION}" | awk '{print $1}')

        # 从一列「由旧到新」的 Accepted 日志里，取属于本用户的倒数第二条。
        # 倒数第一条就是本次登录（sshd 在启动 shell 之前已写好这条日志），
        # 所以只看最后一条会把「本次」当成「上次」显示。
        # 用户名按整字段比较，避免 alice 命中 alice2。
        awk_prev='
            {
                u = ""
                for (i = 1; i < NF - 1; i++)
                    if ($i == "for" && $(i + 2) == "from") u = $(i + 1)
                if (u == me) line[++n] = $0
            }
            END { if (n >= 2) print line[n - 1] }
        '

        echo ""
        echo "=========================================="

        last_log=""

        # ── 数据源 1：systemd journal ────────────────────────────────
        # Debian/Ubuntu 的单元名是 ssh.service，RHEL/Arch/openSUSE 是 sshd.service，两个都给上。
        # --grep 里 "for 用户名 from" 前后带空格，等价于精确匹配；-n 20 给降级留足窗口。
        last_log=$(journalctl -u ssh.service -u sshd.service \
            --grep="Accepted .* for $me from" -n 20 --no-pager -q -o short-iso 2>/dev/null |
            awk -v me="$me" "$awk_prev")

        # ── 数据源 2：传统 syslog 文件（无权读 journal 或没有 systemd 时） ──
        if [ -z "$last_log" ]; then
            for f in /var/log/auth.log /var/log/secure; do
                [ -r "$f" ] || continue
                last_log=$(grep " for $me from" "$f" 2>/dev/null | awk -v me="$me" "$awk_prev")
                [ -n "$last_log" ] && break
            done
        fi

        last_time=""
        last_ip=""

        if [ -n "$last_log" ]; then
            # journalctl 的 short-iso 时间戳固定在行首 19 个字符：YYYY-MM-DDTHH:MM:SS
            # （常见写法 sed 's/[+-].*//' 会从日期里的第一个 "-" 开始删，结果只剩 "2026"）
            case $last_log in
                *[0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]*)
                    last_time=$(echo "$last_log" | cut -c1-19 | tr 'T' ' ')
                    ;;
                *)
                    # syslog 格式：Aug 25 05:57:07（不带年份）
                    last_time=$(echo "$last_log" | awk '{print $1, $2, $3}')
                    ;;
            esac
            # "from" 后一个字段就是 IP，IPv4 / IPv6 都完整
            last_ip=$(echo "$last_log" | awk '{for (i = 1; i < NF; i++) if ($i == "from") { print $(i + 1); exit }}')
        else
            # ── 数据源 3：wtmp（last）───────────────────────────────
            # -i 直接输出数值 IP 不做反解，-w 不截断主机列，-F 带上完整年份。
            info=$(last -Fiw -n 50 "$me" 2>/dev/null |
                awk -v user="$me" '$1 == user && $0 !~ /still logged in/ && $0 !~ /^wtmp begins/ { print; exit }')

            if [ -n "$info" ]; then
                last_ip=$(echo "$info" | awk '{print $3}')
                last_time=$(echo "$info" | awk '{
                    for (i = 4; i <= NF; i++) {
                        if ($i == "-" || $i == "down" || $i == "still") break
                        printf "%s ", $i
                    }
                }' | sed 's/ *$//')
            fi
        fi

        if [ -n "$last_ip" ]; then
            echo "上次登录: $last_time"
            echo "来源 IP : $last_ip"
        elif [ -n "$current_ip" ]; then
            echo "上次登录: 没有可查询的历史记录（可能是首次登录，或当前用户无权限读取登录日志）"
        else
            echo "上次登录: 没有查询到上次登录日志喵~"
        fi

        # 本次连接的真实来源与时间
        echo "当前来源: ${current_ip:-未知}"
        echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Ciallo～(∠・ω< )⌒★"
        echo "=========================================="
    }

    _lw_show
    unfunction _lw_show
fi
