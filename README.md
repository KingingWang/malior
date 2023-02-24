# README

# Malior \[🎮]

*   面向 Mali GPU 的 Linux 容器化游戏打包。

    *   支持全音频、图形。

    *   兼容 Linux 本机游戏、box86/64 模拟游戏等。

    *   支持 systemd 等。

*   目前仍在早期开发阶段，假定 SOC 为 RK3588(S)。

*   测试环境：

    *   Linux 发行版：Ubuntu 22.04（Jammy）

    *   桌面环境：Gnome with Wayland

    *   SOC：RK3588S

*   [测试环境项目地址](https://github.com/Joshua-Riek/ubuntu-orange-pi5) ,使用此项目glmark2跑分可以达到1800分。

\*## \*快速入门

*   安装 Docker（必需）

<!---->

     curl -sSL https://get.daocloud.io/docker | sh

*   安装 “malior” 命令

<!---->

     sudo -s
     wget https://github.com/kingingwang/malior/raw/main/install.sh  && bash ./install.sh  && rm ./install.sh
     ​

*   malior help

<!---->

     使用方法：
         malior [command] <game|application> <args>
         例如：
             'malior install xonotic' 以安装 xonotic
             'malior xonotic' 以开始运行 xonotic
             'malior update (malior, xonotic, etc...)' 以更新某些内容
             'malior update' 以更新 malior 镜像
     命令：
         help                   此使用指南
         update <game|app>      更新 malior 镜像
         recreate               重建 malior 运行时容器
         destroy                停止和删除 malior 运行时容器
         pause|stop             暂停（docker stop）malior 运行时容器
         resume|start           恢复（docker start）malior 运行时容器
         remove                 删除游戏
     ​

*   malior-sudo

<!---->

     malior-sudo 'echo $USER'
     ​

## 设置

*   [设置文档](notion://www.notion.so/kingingwang/SETTINGS.md)

## 提示

*   已经在本地安装了 xonotic 吗？

<!---->

     # 游戏目录
     mv ${LOCAL_XONOTIC_DIR} $HOME/.local/malior/xonotic
     # 配置目录
     mv $HOME/.xonotic $HOME/.config/malior/.xonotic
     # 链接 $HOME/.local/malior/xonotic 到 ${LOCAL_XONOTIC_DIR}
     # 链接 $HOME/.config/malior/.xonotic 到 $HOME/.xonotic
     malior install xonotic # 无需重新下载所有内容
     ​

## 应用程序（游戏）兼容性列表

## 硬件兼容性列表

# 感谢以下项目：

*   [box86](https://github.com/ptitSeb/box86)、[box64](https://github.com/ptitSeb/box64)

*   [panfork](https://gitlab.com/panfork/mesa)

# Malior Redroid

安装malior-droid命令

     wget  https://raw.githubusercontent.com/kingingwang/malior/main/malior-droid  -O /usr/local/bin/malior-droid && chmod a+x /usr/local/bin/malior-droid

*   malior install malior-redroid

*   malior-redroid help

<!---->

     ls使用方法：
         malior-droid [command] <game|application> <args>
         注意：需要内核配置 PSI ASHMEM ANDROID_BINDERFS 等……
         警告：不支持 zygisk，启用后会破坏容器。
         例如：
             'malior-droid whoami' 等同于 'adb shell whoami'（root 用户）
             'adb connect localhost:5555' 以连接 adb
             'scrcpy -s localhost:5555' 查看 redroid 屏幕
     命令：
         help                   此使用指南
         update                 更新 malior redroid 镜像
         recreate               重建 malior redroid 容器
         destroy                停止和删除 malior redroid 容器
         pause|stop             暂停（docker stop）malior redroid 容器
         resume|start           恢复（docker start）malior redroid 容器
         restart                重新启动 malior redroid 容器
         resize                 调整 redroid 窗口大小，例如 malior-droid resize 1920x1080
         install-overlay        Overlays，它将被挂载在 redroid 的 rootfs 上，并存储在 ~/.local/malior/redroid_overlay 中
                                    base：自动安装的重叠，提供 Magisk 支持和 Gapps 支持
     ​

*   手动部分

    *   修复 Magisk 安装并重新启动（可能需要两次，可能会导致主机重启）

    *   （可选）安装 Riru-v25.4.4 LSPosed-v1.8.5（已测试版本）

    *   （可选）注册 GSF ID，让 Google 框架工作

        *   使用设备 ID 应用程序获取 GSF ID

*   备份：数据分区 `~/.local/malior/redroid`。

<!---->

     # 备份
     cd ~/.local/malior/redroid
     sudo tar cvpjf backup.tgz *
     ​

*   恢复：`malior-droid destroy` 并从备份中恢复数据分区。

```
# 恢复
malior-droid destroy
cd ~/.local/malior/redroid
sudo tar xvpjf backup.tgz
malior-droid echo 'hello'

```

# Malior Redroid使用方法

     apt install -y scrcpy adb
     adb connect localhost:5555
     scrcpy -s localhost:5555

