#!/bin/bash
# SillyTavern 运行时管理模块 (Ubuntu)

# 启动 SillyTavern
st_start() {
    clear
    show_header
    show_submenu_header "启动 SillyTavern"
    
    # 检查是否已安装
    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_error "SillyTavern 未安装"
        echo ""
        show_info "请先选择 [2] SillyTavern 管理 → [1] 首次安装"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    
    # 检查是否已运行
    if [ "$(get_st_status)" == "running" ]; then
        show_warning "SillyTavern 已在运行"
        echo ""
        show_success "访问地址: http://127.0.0.1:8000"
        echo ""
        read -p "按任意键继续..." -n 1
        return 0
    fi
    
    # 启动服务
    show_info "正在启动 SillyTavern..."
    echo ""
    
    cd "$SILLYTAVERN_DIR" || {
        show_error "无法进入目录"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    }
    
    # 检查并禁用缩略图（修复 proot 环境崩溃问题）
    local config_file="$SILLYTAVERN_DIR/config.yaml"
    if [ -f "$config_file" ]; then
        if ! grep -q "enableThumbnails: false" "$config_file"; then
            show_info "检测到缩略图功能，正在禁用以避免崩溃..."
            
            # 备份配置
            cp "$config_file" "$config_file.bak.$(date +%s)" 2>/dev/null
            
            # 禁用缩略图
            if grep -q "enableThumbnails:" "$config_file"; then
                sed -i 's/enableThumbnails: true/enableThumbnails: false/' "$config_file"
                sed -i 's/enableThumbnails:true/enableThumbnails: false/' "$config_file"
            else
                echo "" >> "$config_file"
                echo "# 禁用缩略图（修复 proot 环境崩溃问题）" >> "$config_file"
                echo "enableThumbnails: false" >> "$config_file"
            fi
            
            show_success "已自动禁用缩略图功能"
            echo ""
        fi
    fi
    
    # 前台运行（添加环境变量修复 proot 内存问题）
    # 设置较小的内存限制和禁用某些优化以避免 proot 环境下的崩溃
    export NODE_OPTIONS="--max-old-space-size=512 --max-semi-space-size=2"
    export MALLOC_ARENA_MAX=2
    
    node server.js
    
    # 清理环境变量
    unset NODE_OPTIONS
    unset MALLOC_ARENA_MAX
    
    # 如果执行到这里，说明服务已停止
    echo ""
    show_info "SillyTavern 已停止"
    echo ""
    read -p "按任意键继续..." -n 1
}

# 获取 SillyTavern 状态
get_st_status() {
    if pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
}

