#!/bin/bash
set -e
ETC_MINER_WALLET_ADDRESS="0xYourMinerAccountAddress"

produckName="One Key Install ETC Node"
CORE_GETH_Dir=/core-geth
CORE_GETH_LOG_Dir=$CORE_GETH_Dir/logs
CORE_GETH_DATA_Dir=$CORE_GETH_Dir/datas
parse_json(){
    echo "${1//\"/}" | tr -d '\n' | tr -d '\r' | sed "s/.*$2:\([^,}]*\).*/\1/"
}

# # core-geth_logrotate config
create_logrotate_config(){
sudo rm -rf /etc/logrotate.d/core-geth

cat << EOF | sudo tee /etc/logrotate.d/core-geth
$CORE_GETH_LOG_Dir/core-geth.log {
    hourly
    rotate 720
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
EOF
}

# core-geth_logrotate systemd
create_core-geth_logrotate_service(){
sudo rm -rf /etc/systemd/system/core-geth_logrotate.service

cat << EOF | sudo tee /etc/systemd/system/core-geth_logrotate.service
[Unit]
Description=Logrotate for Core-Geth

[Service]
Type=oneshot
ExecStart=/usr/sbin/logrotate /etc/logrotate.d/core-geth
EOF
}

# core-geth_logrotate systemd timer
create_core-geth_logrotate_service_timer(){
sudo rm -rf /etc/systemd/system/core-geth_logrotate.timer

cat << EOF | sudo tee /etc/systemd/system/core-geth_logrotate.timer
[Unit]
Description=Run logrotate for Core-Geth every 5 minutes

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

handle_log_split(){
    mkdir -p $CORE_GETH_LOG_Dir \
    && create_logrotate_config \
    && wait \
    && create_core-geth_logrotate_service \
    && wait \
    && create_core-geth_logrotate_service_timer \
    && wait \
    && sudo systemctl daemon-reload \
    && wait \
    && sudo systemctl enable core-geth_logrotate.timer \
    && wait \
    && sudo systemctl start core-geth_logrotate.timer
}

# zh-CN---:创建一个新的systemd服务文件
# en-US---:Create a new systemd service file
create_geth_service(){
sudo systemctl disable core-geth.service \
&& sudo rm -rf /etc/systemd/system/core-geth.service

cat << EOF | sudo tee /etc/systemd/system/core-geth.service
[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=$CORE_GETH_Dir/geth --classic --datadir $CORE_GETH_DATA_Dir --http --http.addr 0.0.0.0 --http.port 8545 --http.api eth,web3,net,miner,txpool --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,web3,net,miner,txpool --syncmode full --miner.etherbase $ETC_MINER_WALLET_ADDRESS
ExecStop=/bin/kill -TERM '$MAINPID'
WorkingDirectory=$CORE_GETH_Dir
StandardOutput=append:$CORE_GETH_LOG_Dir/core-geth.log
StandardError=append:$CORE_GETH_LOG_Dir/core-geth.log

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload \
&& sudo systemctl enable core-geth.service
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
    local DOWNLOAD_LINK_ARRAY=($(echo "$LATEST_RELEASE_INFO" | grep -oP '"browser_download_url": "\K(.*linux.*)(?=")'))
    local CORE_GETH_DOWNLOAD_URL=""
    for aurl in "${DOWNLOAD_LINK_ARRAY[@]}"; do
        if [[ ! $aurl =~ \.sha256$ ]] && [[ ! $aurl =~ alltools ]]; then
            CORE_GETH_DOWNLOAD_URL=$aurl
        fi
    done

    # zh-CN---:检查目标目录是否存在，如果不存在则创建目录
    # en-US---:Check if the target directory exists and create the directory if not
    if [ ! -d "$CORE_GETH_Dir" ]; then
        mkdir -p "$CORE_GETH_Dir"
    fi
    # zh-CN---:检查目标目录是否存在，如果不存在则创建目录
    # en-US---:Check if the geth file exists and back it up if it does
    if [ -f "$CORE_GETH_Dir/geth" ]; then
        old_version=`$CORE_GETH_Dir/geth version`
        echo Old Version With:$old_version
        current_datetime=$(date +"%Y%m%d%H%M%S")
        mv "$CORE_GETH_Dir/geth" "$CORE_GETH_Dir/geth.$current_datetime.bak"
    fi

    file_name=`echo ${CORE_GETH_DOWNLOAD_URL##*'/'}`
    wget --no-check-certificate $CORE_GETH_DOWNLOAD_URL \
    && wait \
    && echo "Download(下载)："$CORE_GETH_DOWNLOAD_URL"Complate(完成)",FielWith：$file_name \
    && unzip "$file_name" -d "$CORE_GETH_Dir" \
    && rm -rf "$file_name" \
    && $CORE_GETH_Dir/geth version
}

pre_config(){
    apt update && wait && apt install unzip zip wget logrotate
}

is_valid_etc_wallet_address() {
  local input_address="$1"
  if [[ "$input_address" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    return 0
  else
    return 1
  fi
}

input_wallet_address(){
    while true; do
        echo "====Please enter the ETC wallet address, if you do not want to configure, just press Enter===="
        echo "============================ 请输入ETC钱包地址,如果不想配置直接回车 ============================="
        read -p "Please Input(请输入): " input_string
        if [ -z "$input_string" ]; then
            break
        elif is_valid_etc_wallet_address "$input_string"; then
            ETC_MINER_WALLET_ADDRESS="$input_string"
            break
        else
            echo "Invalid ETC wallet address. Please try again.（ETC 钱包地址无效。 请再试一次。）"
        fi
    done
}

add_path() {
    if [ ! -d "$CORE_GETH_Dir/bin" ]; then
        mkdir -p "$CORE_GETH_Dir/bin"
    fi

    if [ ! -L "$CORE_GETH_Dir/bin/geth" ]; then
        ln -s $CORE_GETH_Dir/geth $CORE_GETH_Dir/bin/geth
    fi

    if grep -q "geth" /etc/profile; then
        sudo sed -i "/export PATH=.*geth/c\export PATH=\$PATH:$CORE_GETH_Dir/bin" /etc/profile
    else
        echo "export PATH=\$PATH:$CORE_GETH_Dir/bin" | sudo tee -a /etc/profile
    fi
    source /etc/profile
}

echo "============================ ${produckName} ============================"
echo "============== 执行此脚本会停止当前 core-geth服务，请谨慎操作 =============="
echo "  1、Install core-geth、Create Config File、Create Systemctl Serveice、Optimize Network(安装core-geth、创建Systemctl服务、优化网络)"
echo "  2、Install core-geth And Create Systemctl Serveice(安装 core-geth 并创建 Systemctl 服务)"
echo "  3、Just Only Download core-geth(只下载 core-geth)"
echo "  4、Just Only Create core-geth Systemctl Serveice(只创建 core-geth Systemctl 服务)"
echo "  5、Just Only Optimize Network(只优化网络)"
echo "  6、Handle Log Split (处理日志分片)"
echo "  7、Add geth to PATH (添加geth环境变量)"
echo "======================================================================"
read -p "$(echo -e "Plase Choose [1-7]：(请选择[1-7]：)")" choose
case $choose in
1)
    pre_config && wait && download_latest_geth && wait  && input_wallet_address && wait && create_geth_service && wait && handle_log_split && wait && add_path && wait && optimize_network && wait && rm -rf 
    ;;
2)
    pre_config && wait && download_latest_geth && wait && input_wallet_address && wait && create_geth_service
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
6)
    handle_log_split
    ;;
6)
    add_path
    ;;
*)
    echo "Input Error，Plase Again(输入错误，请重试)"
    ;;
esac