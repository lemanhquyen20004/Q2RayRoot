# Q2Ray Root v0.0.1

**Q2Ray Root** là module proxy dành cho Android đã root, do tài khoản **lemanhquyen20004** phát triển riêng với sự hỗ trợ của AI.

**Chức năng phiên bản đầu:**
- Xray-core TPROXY cho TCP/UDP.
- Bật/tắt bằng Magisk Action hoặc WebUI; sau khi cài không tự bật proxy.
- WebUI chọn **Tiếng Việt / English**, nhập VLESS TLS/REALITY hoặc JSON.
- Tùy chọn phát Hotspot qua proxy (mặc định tắt, chỉ nhận diện giao diện AP).
- Nếu Xray không chạy, khởi động lỗi, hoặc không cài được rule, module cố gắng gỡ rule riêng và trả mạng về Direct.
- Không tự động tắt IPv6, không flush toàn bộ iptables hoặc đổi DNS của Android.

## Cài đặt

Dùng tệp **Q2RayRoot-v0.0.1-arm64.zip** do GitHub Actions build hoặc tệp trong GitHub Releases (nếu đã phát hành). Không dùng **Source code ZIP** của GitHub để cài bởi source ZIP **không có Xray-core**.

Cài qua Magisk / KernelSU / APatch, khởi động lại, mở WebUI trong trình quản lý hỗ trợ hoặc KsuWebUIStandalone. Nhập node và lưu trước khi bật proxy.

**Lưu ý:** Bản này là technical preview, **chưa thử thực tế trên Redmi Note 8T MIUI Android 11**. Tuyệt đối không bật đồng thời Q2Ray Root với Box for Root / Magic V2Ray. Nếu không vào mạng, nhấn **Tắt / Direct**, hoặc tắt module trong Magisk và khởi động lại.

**Dữ liệu riêng:** File node nằm ở `/data/adb/q2rayroot/config.json`; đừng đẩy UUID hoặc subscription lên GitHub.

## Kế hoạch

Mihomo, sing-box, subscription nâng cao, giới hạn thiết bị Hotspot và game profile **chưa có trong v0.0.1**. Chỉ triển khai sau kiểm thử.

## Bản quyền

© 2026 **lemanhquyen20004** đối với mã nguồn gốc được tạo cho Q2Ray Root. Giấy phép dự án GPL-3.0-or-later. Xray-core và các thư viện bên thứ ba vẫn thuộc tác giả tương ứng. Xem [NOTICE.md](NOTICE.md).
