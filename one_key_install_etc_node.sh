#!/bin/bash
produckName="One Key Install ETC Node"
CORE_GETH_Dir=/core-geth

parse_json(){
    echo "${1//\"/}" | tr -d '\n' | tr -d '\r' | sed "s/.*$2:\([^,}]*\).*/\1/"
}

# zh-CN---:创建一个新的systemd服务文件
# en-US---:Create a new systemd service file
create_geth_service(){
sudo rm -rf /etc/systemd/system/core-geth.service
sudo systemctl daemon-reload
cat << EOF | sudo tee /etc/systemd/system/core-geth.service
[Unit]
Description=Core-Geth Ethereum node
After=network.target

[Service]
User=root
ExecStart=$CORE_GETH_Dir/geth --http --http.addr "0.0.0.0" --http.port "8545" --http.api "eth,web3,net" --cache 1024 --ethash.dagdir "$CORE_GETH_Dir/.ethash" --datadir "$CORE_GETH_Dir/.ethereum" --chain "classic" --syncmode "full" --gcmode "archive"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

ln -s /etc/systemd/system/core-geth.service /etc/systemd/system/geth.service \
&& sudo systemctl daemon-reload \
&& sudo systemctl enable geth \
&& sudo systemctl status geth
}

# zh-CN---:优化系统配置以支持更高的并发连接
# en-US---:Optimize system configuration to support higher concurrent connections
optimize_network(){
    
    wget --no-check-certificate https://raw.githubusercontent.com/george012/gt_script/master/optimize_network.sh && chmod a+x ./optimize_network.sh && ./optimize_network.sh
}

download_latest_geth(){
    # zh-CN---:获取最新版本的信息
    # en-US---:Get the latest version of the information
    local LATEST_RELEASE_INFO=$(curl --silent https://api.github.com/repos/etclabscore/core-geth/releases/latest)
    local GETH_VERSION=$(parse_json "$LATEST_RELEASE_INFO" "tag_name")

    # zh-CN---:筛选linux版本
    # en-US---:Filter linux version
    local DOWNLOAD_LINK=$(echo "$LATEST_RELEASE_INFO" | grep -oP '"browser_download_url": "\K(.*linux.*)(?=")')


    local DOWNLOAD_LINK_ARRAY=(${DOWNLOAD_LINK// / })

    local CORE_GETH_DOWNLOAD_URL=""
    for aurl in "${DOWNLOAD_LINK_ARRAY[@]}"; do
        if [[ ! $aurl =~ \.sha256d$ ]] && [[ ! $aurl =~ alltools ]]; then
            $CORE_GETH_DOWNLOAD_URL=aurl
        fi
    done

    file_name=`echo ${CORE_GETH_DOWNLOAD_URL##*'/'}`
    wget wget --no-check-certificate $CORE_GETH_DOWNLOAD_URL \
    && wait \
    && echo "下载："$CORE_GETH_DOWNLOAD_URL"完成",文件为：$file_name \


    # 检查目标目录是否存在，如果不存在则创建目录
    if [ ! -d "$CORE_GETH_Dir" ]; then
        mkdir -p "$CORE_GETH_Dir"
    fi

    # 检查geth文件是否存在，如果存在则备份
    if [ -f "$CORE_GETH_Dir/geth" ]; then
        old_version=`$CORE_GETH_Dir/geth version`
        echo Old Version With:$old_version
        current_datetime=$(date +"%Y%m%d%H%M%S")
        mv "$CORE_GETH_Dir/geth" "$CORE_GETH_Dir/geth.$current_datetime.bak"
    fi

    # 解压缩文件到指定目录
    unzip "$file_name" -d "$CORE_GETH_Dir"

    # 删除下载的压缩包和解压后的目录
    rm -rf "$file_name"

    # 输出geth版本信息以验证安装成功
    $CORE_GETH_Dir/geth version
}

pre_config(){
    apt update && wait && apt install unzip zip wget
}

echo "============================ ${produckName} ============================"
echo "  1、Install core-geth、Create Systemctl Serveice、Optimize Network(安装core-geth、创建Systemctl服务、优化网络)"
echo "  2、Install core-geth And Create Systemctl Serveice(安装 core-geth 并创建 Systemctl 服务)"
echo "  3、Just Only Download core-geth(只下载 core-geth)"
echo "  4、Just Only Create core-geth Systemctl Serveice(只创建 core-geth Systemctl 服务)"
echo "  5、Just Only Optimize Network(只优化网络)"
echo "======================================================================"
read -p "$(echo -e "Plase Choose [1-5]：(请选择[1-5]：)")" choose
case $choose in
1)
    pre_config && wait && download_latest_geth && wait && create_geth_service && wait && optimize_network
    ;;
2)
    pre_config && wait && download_latest_geth && wait && create_geth_service
    ;;
3)
    pre_config && wait && download_latest_geth
    ;;
4)
    create_geth_service
    ;;
5)
    optimize_network
    ;;
*)
    echo "Input Error，Plase Again(输入错误，请重试)"
    ;;
esac