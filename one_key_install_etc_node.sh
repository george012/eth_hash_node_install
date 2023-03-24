#!/bin/bash


parse_json(){
    echo "${1//\"/}" | tr -d '\n' | tr -d '\r' | sed "s/.*$2:\([^,}]*\).*/\1/"
}


create_geth_service(){
rm -rf /etc/systemd/system/core-geth.service
systemctl daemon-reload
# 创建一个新的systemd服务文件
cat << EOF | sudo tee /etc/systemd/system/core-geth.service
[Unit]
Description=Core-Geth Ethereum node
After=network.target

[Service]
User=root
ExecStart=/geth/geth --http --http.addr "0.0.0.0" --http.port "8545" --http.api "eth,web3,net" --cache 1024 --ethash.dagdir "/geth/.ethash" --datadir "/geth/.ethereum" --chain "classic" --syncmode "full" --gcmode "archive"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 开机自启Core-Geth服务
sudo systemctl enable core-geth

# 显示Core-Geth服务状态
sudo systemctl status core-geth
}

optimize_network(){
    # 优化系统配置以支持更高的并发连接,利用已存在脚本优化
    wget --no-check-certificate https://raw.githubusercontent.com/george012/gt_script/master/optimize_network.sh && chmod a+x ./optimize_network.sh && ./optimize_network.sh
}

download_latest_geth(){
    # 获取最新版本的信息
    LATEST_RELEASE_INFO=$(curl --silent https://api.github.com/repos/etclabscore/core-geth/releases/latest)
    GETH_VERSION=$(parse_json "$LATEST_RELEASE_INFO" "tag_name")

    # 从JSON响应中提取下载链接（请根据您的Linux发行版和架构修改）
    DOWNLOAD_LINK=$(echo "$LATEST_RELEASE_INFO" | grep -oP '"browser_download_url": "\K(.*linux.*)(?=")')


    DOWNLOAD_LINK_ARRAY=(${DOWNLOAD_LINK// / })

    for i in "${!DOWNLOAD_LINK_ARRAY[@]}"; do
        aurl=${DOWNLOAD_LINK_ARRAY[i]}
        file_name=`echo ${aurl##*'/'}`
        wget $aurl
        wait
        echo "下载："$aurl"完成",文件为：$file_name
    done


    # # 解压缩下载的文件
    # tar -xzf core-geth.tar.gz

    # # 获取解压后的目录名
    # DIRECTORY_NAME=$(echo "$DOWNLOAD_LINK" | grep -oP "core-geth-.*-1")

    # # 创建/geth目录（如果不存在）
    # mkdir -p /geth

    # # 将geth二进制文件移动到/geth目录
    # mv $DIRECTORY_NAME/geth /geth/

    # # 删除下载的压缩包和解压后的目录
    # rm -rf core-geth.tar.gz $DIRECTORY_NAME

    # # 输出geth版本信息以验证安装成功
    # /geth/geth version
}

pre_config(){
    apt update && wait && apt install unzip zip wget
}

pre_config && wait && download_latest_geth && wait && create_geth_service && wait && optimize_network

echo "============================ ${produckName} ============================"
echo "  1、"
echo "  2、更新 ${produckName}"

echo "======================================================================"
read -p "$(echo -e "请选择[1-6]：")" choose
case $choose in
1)
    install
    ;;
2)
    update
    ;;
3)
    uninstall
    ;;
4)
    start
    ;;
5)
    restart
    ;;
6)
    stop
    ;;
7)
    show_log
    ;;
8)
    check_limit
    ;;
9)
    uninstall_tx_mon
    ;;
*)
    echo "输入错误，请重新输入！"
    ;;
esac