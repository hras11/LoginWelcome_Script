# LoginWelcome_Script
一个用于在登录时显示自定义欢迎的脚本，适用于zsh

---------------------------

## 使用方法
于希望显示该登录欢迎的用户的家目录下，执行 `git clone https://github.com/hras11/LoginWelcome_Script.git`

使用 `cd ./LoginWelcome_Script` 进入本项目，使用 `chmod +x .\Welcome.zsh` 授予脚本执行权限，然后再把 `Welcome.zsh` 文件的绝对路径追加到希望显示该登录欢迎的用户的 `.zshrc` 文件的末尾即可

或者，直接将 `zsh /home/{USERNAME}/LoginWelcome_Script/Welcome.zsh` 追加到希望显示该登录欢迎的用户的 `.zshrc` 文件的末尾，无需授予该脚本执行权限。记得将{USERNAME}替换为希望显示该登录欢迎的用户的用户名，如果更改了安装路径，就改为 `Welcome.zsh` 的实际绝对路径。
