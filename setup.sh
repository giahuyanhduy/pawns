#!/bin/bash

# Script để cài Docker, đồng bộ thời gian, lấy device-id từ /opt/autorun và chạy container Pawns.app

# Đồng bộ thời gian hệ thống
sync_time() {
    echo "Đồng bộ thời gian hệ thống..."
    #apt install ntpdate -y
    ntpdate pool.ntp.org
    echo "Thời gian đã được đồng bộ: $(date)"
}

# Cập nhật hệ thống và cài Docker nếu chưa có
install_docker() {
    echo "Kiểm tra và cài đặt Docker..."
    if ! command -v docker &> /dev/null; then
        echo "Docker chưa được cài đặt. Đang cài đặt..."
        #apt-get update -y
        apt-get install -y docker.io
        systemctl start docker
        systemctl enable docker
        echo "Docker đã được cài đặt và kích hoạt."
    else
        echo "Docker đã có sẵn."
    fi
}

# Lấy device-id từ file /opt/autorun (4 hoặc 5 ký tự trước ":localhost:22" trong -R)
get_device_id() {
    if [ -f "/opt/autorun" ]; then
        # Tìm dòng chứa ":localhost:22" và trích xuất cổng từ -R
        device_id=$(grep ":localhost:22" /opt/autorun | grep -oP '(?<= -R )\d+(?=:localhost:22)' | head -n 1)
        if [[ ${#device_id} -eq 4 || ${#device_id} -eq 5 ]]; then
            echo "Device ID: $device_id"
        else
            echo "Device ID không hợp lệ (phải là 4 hoặc 5 ký tự). Nội dung trích xuất: '$device_id'. Thoát..."
            exit 1
        fi
    else
        echo "File /opt/autorun không tồn tại. Thoát..."
        exit 1
    fi
}

# Chạy container Pawns.app
run_pawns_container() {
    echo "Kéo image Pawns.app từ Docker Hub..."
    docker pull iproyal/pawns-cli:latest

    echo "Xóa container cũ nếu tồn tại..."
    docker stop pawns-container 2>/dev/null
    docker rm pawns-container 2>/dev/null

    echo "Chạy container Pawns.app với device-id: $device_id..."
    docker run -d --name pawns-container \
        --restart=unless-stopped \
        iproyal/pawns-cli:latest \
        -email=giahuyanhduy@gmail.com \
        -password=Anhduy3112 \
        -device-name="device-$device_id" \
        -device-id="$device_id" \
        -accept-tos

    if [ $? -eq 0 ]; then
        echo "Container đã được chạy thành công."
    else
        echo "Có lỗi khi chạy container. Vui lòng kiểm tra lại."
        exit 1
    fi
}

# Main
echo "Bắt đầu script..."
echo "version 1.1.3"
sync_time
install_docker
get_device_id
run_pawns_container
echo "Hoàn tất! Container sẽ chạy ngầm và tự khởi động sau reboot."
