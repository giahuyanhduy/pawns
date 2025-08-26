#!/bin/bash
# Script để cài Docker, đồng bộ thời gian, lấy device-id từ /opt/autorun và chạy container Pawns.app
# Version 1.2.1

# Đồng bộ thời gian hệ thống với timeout
sync_time() {
    echo "Đồng bộ thời gian hệ thống..."
    if ! command -v ntpdate &> /dev/null; then
        echo "ntpdate chưa được cài đặt, đang cài..."
        apt-get install -y ntpdate || { echo "Cài ntpdate thất bại, tiếp tục..."; return 1; }
    fi
    timeout 10 ntpdate pool.ntp.org || echo "Đồng bộ thời gian thất bại, tiếp tục..."
    echo "Thời gian hiện tại: $(date)"
}

# Cài Docker nếu chưa có (sử dụng docker-ce)
install_docker() {
    echo "Kiểm tra và cài đặt Docker..."
    if ! command -v docker &> /dev/null; then
        echo "Docker chưa được cài đặt. Đang cài đặt..."
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || { echo "Cài phụ thuộc thất bại"; exit 1; }
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || { echo "Thêm GPG key thất bại"; exit 1; }
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null || { echo "Thêm repository thất bại"; exit 1; }
        apt-get install -y docker-ce docker-ce-cli containerd.io || { echo "Cài docker-ce thất bại"; exit 1; }
        systemctl start docker || { echo "Khởi động Docker thất bại"; exit 1; }
        systemctl enable docker
        echo "Docker đã được cài đặt và kích hoạt."
    else
        echo "Docker đã có sẵn."
    fi
    # Đảm bảo Docker đang chạy
    systemctl is-active docker >/dev/null || systemctl start docker || { echo "Khởi động Docker thất bại"; exit 1; }
}

# Lấy device-id từ file /opt/autorun hoặc dùng hostname
get_device_id() {
    if [ -f "/opt/autorun" ]; then
        device_id=$(grep ":localhost:22" /opt/autorun | grep -oP '(?<= -R )\d+(?=:localhost:22)' | head -n 1)
        if [[ ${#device_id} -eq 4 || ${#device_id} -eq 5 ]]; then
            echo "Device ID: $device_id"
        else
            echo "Device ID không hợp lệ (phải là 4 hoặc 5 ký tự). Nội dung trích xuất: '$device_id'. Sử dụng hostname..."
            device_id="Ubuntu$(hostname)"
            echo "Device ID mới: $device_id"
        fi
    else
        echo "File /opt/autorun không tồn tại. Sử dụng hostname..."
        device_id="Ubuntu$(hostname)"
        echo "Device ID: $device_id"
    fi
}

# Chạy container Pawns.app
run_pawns_container() {
    echo "Kéo image Pawns.app từ Docker Hub..."
    timeout 60 docker pull iproyal/pawns-cli:latest || { echo "Không thể kéo image, tiếp tục với image cũ nếu có..."; }
    
    echo "Xóa container cũ nếu tồn tại..."
    docker stop pawns-container 2>/dev/null || true
    docker rm pawns-container 2>/dev/null || true

    echo "Chạy container Pawns.app với device-id: $device_id..."
    docker run -d --name pawns-container \
        --restart=always \
        iproyal/pawns-cli:latest \
        -email=giahuyanhduy@gmail.com \
        -password=Anhduy3112 \
        -device-name="device-$device_id" \
        -device-id="$device_id" \
        -accept-tos

    if [ $? -eq 0 ]; then
        echo "Container đã được chạy thành công. Check logs with 'docker logs pawns-container'."
    else
        echo "Có lỗi khi chạy container. Vui lòng kiểm tra log: 'docker logs pawns-container'."
        exit 1
    fi
}

# Main
echo "Bắt đầu script..."
echo "Version 1.2.1"
sync_time
install_docker
get_device_id
run_pawns_container
echo "Hoàn tất! Container sẽ chạy ngầm và tự khởi động sau reboot."
