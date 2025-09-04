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
        
        if ! command -v tmux &> /dev/null; then
            echo "未检测到 tmux，正在安装 tmux..."
            brew install tmux
        fi

        session="nexus_nodes"
        tmux new-session -d -s $session
        
        for node_id in "${ids[@]}"; do
            tmux new-window -t $session -n "$node_id" "nexus-network start --node-id $node_id"
        done

        echo "节点启动完成!"
    else
        echo "未找到 $(dirname "$0")/nexus-node-ids 文件，请先设置节点ID列表."
    fi
}

# 查看日志/进入终端
function view_logs() {
    tmux list-sessions | grep "nexus_nodes" &> /dev/null

    if [ $? -eq 0 ]; then
        tmux attach-session -t nexus_nodes
    else
        echo "没有运行中的节点会话."
    fi
}

# 停止节点
function stop_nodes() {
    tmux list-sessions | grep "nexus_nodes" &> /dev/null

    if [ $? -eq 0 ]; then
        tmux kill-session -t nexus_nodes
        echo "所有节点已停止."
    else
        echo "没有运行中的节点会话."
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
