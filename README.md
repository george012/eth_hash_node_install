<font size=20>目录：</font>
<!-- TOC -->

- [1. `summary`(简介)](#1-summary简介)
- [2. `Q & A`(为什么？)](#2-q--a为什么)
- [3. `Functions`(功能)](#3-functions功能)
- [4. `core-geth Infos` (core-geth 相关信息)](#4-core-geth-infos-core-geth-相关信息)
- [5. `Use`(使用)](#5-use使用)

<!-- /TOC -->

# 1. `summary`(简介)
* This script is for one-click installation and configuration of Ethereum Classic (ETC) nodes on Linux systems. This script can help users easily install and configure ETC nodes, saving the trouble of manually executing multiple commands. Just run the script according to the prompts and select the corresponding operation to complete the construction of the ETC node

* `zh-CN--->`这个脚本是用于在Linux系统上一键安装和配置Ethereum Classic（ETC）节点的。这个脚本可以帮助用户轻松地安装和配置ETC节点，省去了手动执行多个命令的麻烦。只需根据提示运行脚本，选择相应的操作，即可完成ETC节点的搭建。

# 2. `Q & A`(为什么？)
* Q1: Why not use the official docker way(<font color=red>为什么不用官方docker方式？</font>)
* A1: The docker method is cumbersome for running and monitoring, with limited energy, and not enough time to learn the docker ecology.（<font color=red>docker的方式对于运行监控繁琐，精力有限，对于docker生态的学习时间不够。</font>）

# 3. `Functions`(功能)
- [x] Automatically download the latest version of core-geth(自动下载最新版本core-geth)
- [x] Automatically generate the startup configuration file for core-geth running in the ETC network(自动生成core-geth运行在ETC网络中的启动配置文件)
- [x] `systemd` system services(`systemd`系统服务)
- [x] menu processing(菜单化)
- [x] High concurrent network optimization `default 51200`(高并发网络优化`默认51200`)

# 4. `core-geth Infos` (core-geth 相关信息)
* [core-geth github](https://github.com/etclabscore/core-geth)
* [core-geth Documentation](https://etclabscore.github.io/core-geth/)

# 5. `Use`(使用)
```wget --no-check-certificate https://raw.githubusercontent.com/george012/one_key_install_core-geth/master/one_key_install_etc_node.sh && chmod a+x ./one_key_install_etc_node.sh && ./one_key_install_etc_node.sh```
