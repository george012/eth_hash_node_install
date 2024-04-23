#!/bin/bash
set -e

COIN=""
COIN_NAME=""
NODE_TYPE=""
SCRIPT_NAME=$(basename $0)
IDENTITY_NAME="MYNODE"
ETC_MINER_WALLET_ADDRESS="0xYourMinerAccountAddress"

PRODUCK_NAME=""
GETH_Dir=""
GETH_LOG_Dir=""
GETH_DATA_Dir=""
GETH_DAG_Dir=""
GETH_CACHE_Dir=""
API_PORT="8545"
ExecStart=""

function parse_json(){
    echo "${1//\"/}" | tr -d '\n' | tr -d '\r' | sed "s/.*$2:\([^,}]*\).*/\1/"
}

# # geth_logrotate config
function create_logrotate_config(){
sudo rm -rf /etc/logrotate.d/$COIN_NAME-geth

cat << EOF | sudo tee /etc/logrotate.d/$COIN_NAME-geth
$GETH_LOG_Dir/geth.log {
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

# geth_logrotate systemd
function create_geth_logrotate_service(){
sudo rm -rf /etc/systemd/system/$COIN_NAME-geth_logrotate.service

cat << EOF | sudo tee /etc/systemd/system/$COIN_NAME-geth_logrotate.service
[Unit]
Description=Logrotate for geth

[Service]
Type=oneshot
ExecStart=/usr/sbin/logrotate /etc/logrotate.d/$COIN_NAME-geth
EOF
}

# geth_logrotate systemd timer
function create_geth_logrotate_service_timer(){
sudo rm -rf /etc/systemd/system/$COIN_NAME-geth_logrotate.timer

cat << EOF | sudo tee /etc/systemd/system/$COIN_NAME-geth_logrotate.timer
[Unit]
Description=Run logrotate for geth every 5 minutes

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

function handle_log_split(){
    mkdir -p $GETH_LOG_Dir \
    && create_logrotate_config \
    && wait \
    && create_geth_logrotate_service \
    && wait \
    && create_geth_logrotate_service_timer \
    && wait \
    && sudo systemctl daemon-reload \
    && wait \
    && sudo systemctl enable $COIN_NAME-geth_logrotate.timer \
    && wait \
    && sudo systemctl start $COIN_NAME-geth_logrotate.timer
}

function set_execStart_value() {
    if [[ "$COIN" == "ETC" ]]; then
        ExecStart="$GETH_Dir/bin/geth --identity \"$IDENTITY_NAME\" --maxpeers 100 --classic --datadir $GETH_DATA_Dir --ethash.dagdir $GETH_DATA_Dir --ethash.cachedir $GETH_CACHE_Dir --http --http.addr 0.0.0.0 --http.port $API_PORT --http.api eth,web3,net,miner,txpool --syncmode $NODE_TYPE --mine --miner.threads=2 --miner.etherbase $ETC_MINER_WALLET_ADDRESS"
    elif [[ "$COIN" == "ETHW" ]]; then
        ExecStart="$GETH_Dir/bin/geth --identity \"$IDENTITY_NAME\" --maxpeers 100 --datadir $GETH_DATA_Dir --ethash.dagdir $GETH_DAG_Dir --ethash.cachedir $GETH_CACHE_Dir --http --http.addr 0.0.0.0 --http.port $API_PORT --http.api eth,web3,net,miner,txpool --syncmode $NODE_TYPE --mine --miner.threads=2 --miner.etherbase $ETC_MINER_WALLET_ADDRESS"
    elif [[ "$COIN" == "OCTA" ]]; then
        ExecStart="$GETH_Dir/bin/geth --identity \"$IDENTITY_NAME\" --maxpeers 100 --datadir $GETH_DATA_Dir --ethash.dagdir $GETH_DAG_Dir --ethash.cachedir $GETH_CACHE_Dir --http --http.addr 0.0.0.0 --http.port $API_PORT --http.api eth,web3,net,miner,txpool --syncmode $NODE_TYPE --mine --miner.threads=2 --miner.etherbase $ETC_MINER_WALLET_ADDRESS"
    elif [[ "$COIN" == "META" ]]; then
        ExecStart="$GETH_Dir/bin/geth --identity \"$IDENTITY_NAME\" --maxpeers 100 --datadir $GETH_DATA_Dir --ethash.dagdir $GETH_DAG_Dir --ethash.cachedir $GETH_CACHE_Dir --http --http.addr 0.0.0.0 --http.port $API_PORT --http.api eth,web3,net,miner,txpool --syncmode $NODE_TYPE --mine --miner.threads=2 --miner.etherbase $ETC_MINER_WALLET_ADDRESS"
    fi
}

# zh-CN---:创建一个新的systemd服务文件
# en-US---:Create a new systemd service file
function create_geth_service(){
sudo systemctl disable $COIN_NAME-geth.service \
&& sudo rm -rf /etc/systemd/system/$COIN_NAME-geth.service

cat << EOF | sudo tee /etc/systemd/system/$COIN_NAME-geth.service
[Unit]
Description=$COIN_NAME-geth service
After=network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=$ExecStart
ExecStop=/bin/kill -TERM \$MAINPID
WorkingDirectory=$GETH_Dir
StandardOutput=append:$GETH_LOG_Dir/geth.log
StandardError=append:$GETH_LOG_Dir/geth.log

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload \
&& sudo systemctl enable $COIN_NAME-geth.service
}

# zh-CN---:优化系统配置以支持更高的并发连接
# en-US---:Optimize system configuration to support higher concurrent connections
function optimize_network(){
    wget --no-check-certificate https://raw.githubusercontent.com/george012/gt_script/master/optimize_network.sh && chmod a+x ./optimize_network.sh && ./optimize_network.sh
}

function download_latest_geth(){
    # zh-CN---:获取最新版本的信息
    # en-US---:Get the latest version of the information
    if [[ "$COIN" == "ETC" ]]; then
        local LATEST_RELEASE_INFO=$(curl --silent https://api.github.com/repos/etclabscore/core-geth/releases/latest)
    elif [[ "$COIN" == "ETHW" ]]; then
        local LATEST_RELEASE_INFO=$(curl --silent https://api.github.com/repos/ethereumpow/go-ethereum/releases/latest)
    elif [[ "$COIN" == "OCTA" ]]; then
        local LATEST_RELEASE_INFO=$(curl --silent https://api.github.com/repos/octaspace/go-octa/releases/latest)
    elif [[ "$COIN" == "META" ]]; then
        local LATEST_RELEASE_INFO=$(curl --silent https://api.github.com/repos/MetachainOfficial/metachain-core/releases/latest)
    local GETH_VERSION=$(parse_json "$LATEST_RELEASE_INFO" "tag_name")
    # zh-CN---:筛选linux版本
    # en-US---:Filter linux version

    local DOWNLOAD_LINK_ARRAY=($(echo "$LATEST_RELEASE_INFO" | grep -oP '"browser_download_url": "\K(.*linux.*)(?=")'))
    local GETH_DOWNLOAD_URL=""
    for aurl in "${DOWNLOAD_LINK_ARRAY[@]}"; do
        if [[ ! $aurl =~ \.sha256$ ]] && [[ ! $aurl =~ alltools ]] && [[ ! $aurl =~ asc ]]; then
            GETH_DOWNLOAD_URL=$aurl
        fi
    done

    # zh-CN---:检查目标目录是否存在,如果不存在则创建目录
    # en-US---:Check if the target directory exists and create the directory if not
    if [ ! -d "$GETH_Dir" ]; then
        mkdir -p "$GETH_Dir"
    fi
    # zh-CN---:检查目标目录是否存在,如果不存在则创建目录
    # en-US---:Check if the geth file exists and back it up if it does
    if [ -f "$GETH_Dir/geth" ]; then
        old_version=`$GETH_Dir/geth version`
        echo Old Version With:$old_version
        current_datetime=$(date +"%Y%m%d%H%M%S")
        mv "$GETH_Dir/geth" "$GETH_Dir/geth.$current_datetime.bak"
    fi

    file_name=`echo ${GETH_DOWNLOAD_URL##*'/'}`
    wget --no-check-certificate $GETH_DOWNLOAD_URL \
    && wait \
    && echo "Download (下载): "$GETH_DOWNLOAD_URL"Complate (完成)",FielWith: $file_name \
    && if [[ "$COIN" == "OCTA" ]]; then
            mv "$file_name" "$GETH_Dir/geth"
        else
            unzip "$file_name" -d "$GETH_Dir"
            chmod a+x $GETH_Dir/geth
            $GETH_Dir/geth version
        fi \
    && rm -rf "$file_name"
}

function pre_config(){
    apt update && wait && apt install unzip zip tar wget logrotate net-tools vim
}

# 长度40 ETC地址，长度42 LTC地址，长度34 DOGE地址
is_valid_etc_wallet_address() {
  local input_address="$1"
  if [[ "$input_address" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    return 0
  else
    return 1
  fi
}

function input_wallet_address(){
    while true; do
        echo "====Please enter the $COIN node wallet address (请输入 $COIN 节点钱包地址) ===="
        read -p "Please Input (请输入): " input_string
        if [ -z "$input_string" ]; then
            break
        elif is_valid_etc_wallet_address "$input_string"; then
            ETC_MINER_WALLET_ADDRESS="$input_string"
            break
        else
            echo "Invalid ETC wallet address. Please Again (钱包地址无效,请重试) "
        fi
    done
}


function add_path() {
    if [ ! -d "$GETH_Dir/bin" ]; then
        mkdir -p "$GETH_Dir/bin"
    fi

    if [ ! -L "$GETH_Dir/bin/geth" ]; then
        ln -s $GETH_Dir/geth $GETH_Dir/bin/geth
    fi

    if grep -q "geth" /etc/profile; then
        sudo sed -i "/export PATH=.*geth/c\export PATH=\$PATH:$GETH_Dir/bin" /etc/profile
    else
        echo "export PATH=\$PATH:$GETH_Dir/bin" | sudo tee -a /etc/profile
    fi
    source /etc/profile
}

function setting_custom_node_id_name(){
    echo "====Please input the $COIN node name (请输入 $COIN 节点名称) ===="
    read -p "Please Input (请输入): " input_name
    IDENTITY_NAME="$input_name"
}

function setting_ufw() {
    echo "setting ufw starting"
    if [[ "$COIN" == "ETC" ]]; then
        ufw allow 33033/tcp && ufw allow 33033/udp && ufw allow 8551/tcp  && ufw allow ${API_PORT}/tcp && ufw status
    elif [[ "$COIN" == "ETHW" ]]; then
        ufw allow 30303/tcp && ufw allow 30303/udp && ufw allow 8551/tcp  && ufw allow ${API_PORT}/tcp && ufw status
    elif [[ "$COIN" == "OCTA" ]]; then
        ufw allow 30303/tcp && ufw allow 30303/udp && ufw allow 8551/tcp  && ufw allow ${API_PORT}/tcp && ufw status
    elif [[ "$COIN" == "META" ]]; then
        ufw allow 30303/tcp && ufw allow 30303/udp && ufw allow 8551/tcp  && ufw allow ${API_PORT}/tcp && ufw status
    fi

    if [[ "$SERVER_TYPE" == "Esxi" ]]; then
        sudo systemctl enable ufw
        sudo systemctl start ufw
        sudo ufw enable
        sudo ufw status
    elif [[ "$SERVER_TYPE" == "Cloud" ]]; then
        sudo systemctl disable ufw
        sudo systemctl stop ufw
        sudo ufw status
    fi
    echo "setting ufw end"
}

function setting_api_port(){
    echo "====Please input API port,default With 8545 (请输入API端口,默认: 8545)===="
    read -p "Please input (请输入): " input_port
        # 如果输入为空,则使用默认端口 8545
    if [ -z "$input_port" ]; then
        API_PORT="8545"
    else
        # 如果输入在 1 到 65534 范围内,则使用输入的值
        if [ "$input_port" -ge 1 ] && [ "$input_port" -le 65534 ]; then
            API_PORT="$input_port"
        else
            echo "Invalid port number. Please enter a value between 1 and 65534."
            echo "无效的端口号。请输入1到65534之间的值。"
            # 在这里可以添加更多的错误处理逻辑
            setting_api_port  # 重新调用此函数,以便用户重新输入
        fi
    fi
}


function welcome(){
    echo "============================ ${PRODUCK_NAME} ============================"
    echo "============== 执行此脚本会停止当前 geth服务,请谨慎操作 =============="
    echo "  1、Install geth、Create Config File、Create Systemctl Serveice、Optimize Network(安装geth、创建Systemctl服务、优化网络)"
    echo "  2、Install geth And Create Systemctl Serveice(安装 geth 并创建 Systemctl 服务)"
    echo "  3、Just Only Download geth(只下载 geth)"
    echo "  4、Just Only Create geth Systemctl Serveice(只创建 geth Systemctl 服务)"
    echo "  5、Just Only Optimize Network(只优化网络)"
    echo "  6、Handle Log Split (处理日志分片)"
    echo "  7、Add geth to PATH (添加geth环境变量)"
    echo "======================================================================"
    read -p "$(echo -e "Please Choose [1-7]: (请选择[1-7]: )")" choose
    case $choose in
    1)
        pre_config && wait && download_latest_geth && wait && input_wallet_address && wait && setting_api_port && wait && setting_custom_node_id_name && wait && set_execStart_value && create_geth_service && wait && handle_log_split && wait && add_path && wait && optimize_network && wait && setting_ufw && wait && rm  -rf $SCRIPT_NAME
        ;;
    2)
        pre_config && wait && download_latest_geth && wait && input_wallet_address && wait && setting_api_port && wait && set_execStart_value && wait  && create_geth_service
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
    7)
        add_path
        ;;
    *)
        echo "Input Error,Please Again (输入错误,请重试)"
        ;;
    esac
}

function select_node_type(){
    echo "====Please select build node type (请选择搭建节点类型)===="
    echo "  1、syncmode: full (全节点类型)"
    echo "  2、syncmode: snap (快照类型)"
    read -p "$(echo -e "Please Choose [1-2]: (请选择[1-2]: )")" choose
    case $choose in
    1)  
        NODE_TYPE="full"
        ;;
    2)
        NODE_TYPE="snap"
        ;;
    *)
        echo "Input Error,Please Again (输入错误,请重试)"
        ;;
    esac
}

function select_server_platform(){
    echo "====Please select the server platform (请选择服务器平台)===="
    echo "  1、ESXI server - Virtual machine (ESXI服务器-虚拟机) "
    echo "  2、Cloud server - Virtual machine (云服务器-虚拟机) "
    read -p "$(echo -e "Please Choose [1-2]: (请选择[1-2]: )")" choose
    case $choose in
    1)  
        SERVER_TYPE="Esxi"
        ;;
    2)
        SERVER_TYPE="Cloud"
        ;;
    *)
        echo "Input Error,Please Again (输入错误,请重试)"
        ;;
    esac
}

function run(){
    select_server_platform
    echo "====Please select build node coin (请选择搭建节点币种)===="
    echo "  1、Build ETC node (搭建ETC节点) "
    echo "  2、Build ETHW node (搭建ETHW节点) "
    echo "  3、Build OCTA node (搭建OCTA节点) "
    echo "  4、Build META node (搭建META节点) "
    read -p "$(echo -e "Please Choose [1-4]: (请选择[1-4]: )")" choose
    case $choose in
    1)  
        COIN="ETC"
        COIN_NAME="etc"
        ;;
    2)
        COIN="ETHW"
        COIN_NAME="ethw"
        ;;
    3)
        COIN="OCTA"
        COIN_NAME="octa"
        ;;
    4)
        COIN="META"
        COIN_NAME="meta"
        ;;
    *)
        echo "Input Error,Please Again (输入错误,请重试)"
        ;;
    esac
    PRODUCK_NAME="One Key Install $COIN Node"
    GETH_Dir=/$COIN_NAME-geth
    GETH_LOG_Dir=$GETH_Dir/logs
    GETH_DATA_Dir=$GETH_Dir/datas
    GETH_DAG_Dir=$GETH_DATA_Dir/dag
    GETH_CACHE_Dir=$GETH_DATA_Dir/cache
    select_node_type
    welcome
    echo "$COIN node server is successfully,start it using systemctl start $COIN_NAME-geth ($COIN 节点服务搭建成功,使用 systemctl start $COIN_NAME-geth 启动)"
}

run
