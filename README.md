<font size=20>目录：</font>
<!-- TOC -->

- [1. `summary`(简介)](#1-summary简介)
- [2. `Functions`(功能)](#2-functions功能)
- [3. `core-geth Infos` (core-geth 相关信息)](#3-core-geth-infos-core-geth-相关信息)
- [4. `Use`(使用)](#4-use使用)

<!-- /TOC -->

# 1. `summary`(简介)
* This is a script to install the latest version of the Ethereum Classic node with one click
* `zh-CN--->`这是一个一键安装以太经典节点最新版本的脚本

# 2. `Functions`(功能)
- [x] Automatically download the latest version of core-geth(自动下载最新版本core-geth)
- [x] Automatically generate the startup configuration file for core-geth running in the ETC network(自动生成core-geth运行在ETC网络中的启动配置文件)
- [x] `systemd` system services(`systemd`系统服务)
- [x] menu processing(菜单化)
- [x] High concurrent network optimization `default 51200`(高并发网络优化`默认51200`)

# 3. `core-geth Infos` (core-geth 相关信息)
* [core-geth github](https://github.com/etclabscore/core-geth)
* [core-geth Documentation](https://etclabscore.github.io/core-geth/)

# 4. `Use`(使用)
```wget --no-check-certificate https://raw.githubusercontent.com/george012/one_key_install_core-geth/master/one_key_install_etc_node.sh && chmod a+x ./one_key_install_etc_node.sh && ./one_key_install_etc_node.sh```
