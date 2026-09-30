# LoginWelcome_Script
一个用于在登录时显示自定义欢迎的脚本，适用于 zsh

---------------------------

## 效果

```
==========================================
上次登录: 2026-08-24 21:03:11
来源 IP : 203.0.113.7
当前来源: 2408:abcd:1234:5678::9
当前时间: 2026-08-25 06:00:01
Ciallo～(∠・ω< )⌒★
==========================================
```

脚本只在 SSH 会话中输出（通过 `SSH_CONNECTION` 判断），本地终端不受影响；
并且会记录本次会话的去重标记，避免在 tmux 新 pane、嵌套 shell 里重复刷屏。

## 使用方法

在希望显示该欢迎信息的用户家目录下执行：

```sh
git clone https://github.com/hras11/LoginWelcome_Script.git
```

然后把下面这行追加到该用户的 `~/.zshrc` 末尾（路径按实际安装位置调整）：

```sh
[[ -n "$SSH_CONNECTION" ]] && source "$HOME/LoginWelcome_Script/Welcome.zsh"
```

**注意：这里必须用 `source`（或等价的 `.`），不能写成 `zsh ~/LoginWelcome_Script/Welcome.zsh`，也不能只放一个裸路径。**
脚本靠 `export ZLOGIN_SOURCED=1` 记住「本次会话已经打印过」，用子 shell 执行时这个变量随子进程一起退出，
去重就失效了——每开一个新的 zsh（tmux pane、`zsh` 二次进入）都会重新打印一遍。

也可以放到 `~/.zlogin`（zsh 仅在登录 shell 中读取它，语义上更贴合“登录欢迎”）：

```sh
source "$HOME/LoginWelcome_Script/Welcome.zsh"
```

脚本带有 `#!/usr/bin/env zsh`，如果你确实想直接执行（例如给某个快捷键用），
先 `chmod +x "$HOME/LoginWelcome_Script/Welcome.zsh"` 即可，但这会失去去重效果。

## 数据来源

脚本按下面的顺序尝试，读不到就自动降级，全程不会报错刷屏：

1. `journalctl -u ssh.service -u sshd.service`（systemd 日志，两种单元名都覆盖：Debian/Ubuntu 是 `ssh.service`，RHEL/Arch/openSUSE 是 `sshd.service`）
2. `/var/log/auth.log`、`/var/log/secure`（传统 syslog，非 systemd 或未授权读 journal 时）
3. `last -Fiw`（wtmp，普通用户一定可读；`-i` 输出数值 IP 不做 DNS 反解，`-w` 不截断，`-F` 带年份）

三者都拿不到时输出「没有可查询的历史记录」。

> 关于「上次登录」：sshd 在你的 shell 启动**之前**就把本次的 `Accepted ... for <user> from <ip>` 写进了日志，
> 所以只看最后一条匹配到的日志，得到的其实是**本次**登录。脚本取的是倒数第二条匹配记录，
> 即真正意义上的上一次登录（IPv4 / IPv6 均完整显示，不截断）。

## 依赖

`zsh`、`awk`、`sed`、`grep`、`date`，以及按环境可选的 `journalctl` / `last`。终端与 SSH 会话需要 UTF-8
locale，否则中文和颜文字会乱码（`echo $LANG` 应类似 `zh_CN.UTF-8` / `en_US.UTF-8`）。

## 许可

Apache License 2.0，详见 `LICENSE`。
