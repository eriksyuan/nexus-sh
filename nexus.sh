#!/bin/bash

# 菜单显示
function show_menu() {
    echo "请选择一个选项:"
    echo "1. 安装/更新 CLI"
    echo "2. 设置 Node-ID 列表"
    echo "3. 启动节点"
    echo "4. 查看日志/进入终端"
    echo "5. 停止节点"
    echo "6. 退出"
    read -p "输入你的选择: " choice
}

# 安装/更新 CLI
function install_update_cli() {
    echo "正在安装/更新 CLI..."
    curl https://cli.nexus.xyz/ | sh
    echo "完成!"
}

# 设置 Node-ID 列表
function set_node_ids() {
    read -p "请输入节点ID列表(使用逗号分隔): " node_ids
    echo "$node_ids" > "$(dirname "$0")/nexus-node-ids"
    echo "节点ID已经保存到 $(dirname "$0")/nexus-node-ids 文件中."
}

# 启动节点
function start_nodes() {
    if [ -f "$(dirname "$0")/nexus-node-ids" ]; then
        node_ids=$(cat "$(dirname "$0")/nexus-node-ids")
        IFS=',' read -ra ids <<< "$node_ids"
        
        APP_DIR="$(cd "$(dirname "$0")" && pwd)"
        
        echo "正在使用 Terminal.app 启动节点..."
        for node_id in "${ids[@]}"; do
            # 去掉前后空格
            node_id=$(echo "$node_id" | xargs)
            echo "启动节点: $node_id"
            
            osascript -e "tell application \"Terminal\"
                activate
                do script \"cd '$APP_DIR' && echo '启动节点: $node_id' && nexus-network start --node-id $node_id\"
            end tell"
            
            # 稍微延迟一下，避免窗口创建太快
            sleep 0.5
        done

        echo "所有节点已在新的 Terminal 窗口中启动完成!"
        echo "提示: 每个节点都在独立的 Terminal 窗口中运行"
    else
        echo "未找到 $(dirname "$0")/nexus-node-ids 文件，请先设置节点ID列表."
    fi
}

# 查看日志/进入终端
function view_logs() {
    # 检查是否有 nexus-network 进程在运行
    if pgrep -f "nexus-network start" > /dev/null; then
        echo "检测到正在运行的节点进程:"
        ps aux | grep "nexus-network start" | grep -v grep | awk '{print "PID:", $2, "Node:", $NF}'
        echo ""
        echo "提示: 节点正在各自的 Terminal 窗口中运行"
        echo "你可以直接在对应的 Terminal 窗口中查看日志输出"
        echo "或者使用 'ps aux | grep nexus-network' 命令查看所有节点进程"
    else
        echo "没有检测到运行中的节点进程."
        echo "请先启动节点 (选项 3)"
    fi
}

# 停止节点
function stop_nodes() {
    # 查找所有 nexus-network 进程
    pids=$(pgrep -f "nexus-network start")
    
    if [ -n "$pids" ]; then
        echo "正在停止所有节点进程..."
        echo "找到的进程 PID: $pids"
        
        # 逐个停止进程
        for pid in $pids; do
            if kill -TERM "$pid" 2>/dev/null; then
                echo "已发送停止信号给进程 $pid"
            fi
        done
        
        # 等待进程优雅退出
        sleep 2
        
        # 检查是否还有残留进程，强制杀死
        remaining_pids=$(pgrep -f "nexus-network start")
        if [ -n "$remaining_pids" ]; then
            echo "强制停止残留进程: $remaining_pids"
            pkill -KILL -f "nexus-network start"
        fi
        
        echo "所有节点已停止."
        echo "提示: 对应的 Terminal 窗口可能仍然打开，你可以手动关闭它们"
    else
        echo "没有检测到运行中的节点进程."
    fi
}

# 主流程
while true; do
    show_menu
    case $choice in
        1)
            install_update_cli
            ;;
        2)
            set_node_ids
            ;;
        3)
            start_nodes
            ;;
        4)
            view_logs
            ;;
        5)
            stop_nodes
            ;;
        6)
            echo "退出程序."
            exit 0
            ;;
        *)
            echo "无效选项，请重新选择."
            ;;
    esac
done
