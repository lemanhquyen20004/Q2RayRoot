# Q2Ray Root v0.0.2

**Q2Ray Root** là module proxy dành cho Android đã root, do tài khoản **lemanhquyen20004** phát triển riêng với sự hỗ trợ của AI.

**Chức năng phiên bản đầu:**
- Xray-core TPROXY cho TCP/UDP.
- Bật/tắt bằng Magisk Action hoặc WebUI; sau khi cài không tự bật proxy.
- WebUI chọn **Tiếng Việt / English**, nhập VLESS TLS/REALITY hoặc JSON.
- Tùy chọn phát Hotspot qua proxy (mặc định tắt, chỉ nhận diện giao diện AP).
- Nếu Xray không chạy, khởi động lỗi, hoặc không cài được rule, module cố gắng gỡ rule riêng và trả mạng về Direct.
- Không tự động tắt IPv6, không flush toàn bộ iptables hoặc đổi DNS của Android.

## Cài đặt

Dùng tệp **Q2RayRoot-v0.0.2-arm64.zip** do GitHub Actions build hoặc tệp trong GitHub Releases (nếu đã phát hành). Không dùng **Source code ZIP** của GitHub để cài bởi source ZIP **không có Xray-core**.

Cài qua Magisk / KernelSU / APatch, khởi động lại, mở WebUI trong trình quản lý hỗ trợ hoặc KsuWebUIStandalone. Nhập node và lưu trước khi bật proxy.

## Cập nhật qua GitHub (từ v0.0.2)

- Trong **Magisk**: mở danh sách module, bấm **Update / Cập nhật** ở **Q2Ray Root** khi Magisk phát hiện versionCode cao hơn. Không cần tự tải ZIP lên GitHub.
- Trong **WebUI**: mục **Cập nhật**, bấm **Kiểm tra cập nhật**. Nếu có bản mới, bấm **Tải & cài đặt** và xác nhận. WebUI tải bản ZIP chỉ từ GitHub của dự án, kiểm tra SHA-256 rồi yêu cầu **Magisk CLI** cài đặt. Sau khi hiện **Đã cài**, khởi động lại máy. Nếu dùng KernelSU/APatch, hãy dùng nút Update trong trình quản lý root.
- Không tự tải hay cài cập nhật khi bạn chưa bấm xác nhận. File ZIP tạm được xóa sau khi cập nhật xong.
- Khi mã nguồn thay đổi, người quản lý tăng cả `version` và `versionCode` trong `module.prop` và `update.json`; GitHub Actions sẽ tạo bản phát hành mới sau khi kiểm tra mã và build ZIP thành công.

**Lưu ý:** Bản này là technical preview, **chưa thử thực tế trên Redmi Note 8T MIUI Android 11**. Tuyệt đối không bật đồng thời Q2Ray Root với Box for Root / Magic V2Ray. Nếu không vào mạng, nhấn **Tắt / Direct**, hoặc tắt module trong Magisk và khởi động lại.

**Dữ liệu riêng:** File node nằm ở `/data/adb/q2rayroot/config.json`; đừng đẩy UUID hoặc subscription lên GitHub.

## Kế hoạch

Mihomo, sing-box, subscription nâng cao, giới hạn thiết bị Hotspot và game profile **chưa có trong v0.0.2**. Chỉ triển khai sau kiểm thử.

## Bản quyền

© 2026 **lemanhquyen20004** đối với mã nguồn gốc được tạo cho Q2Ray Root. Giấy phép dự án GPL-3.0-or-later. Xray-core và các thư viện bên thứ ba vẫn thuộc tác giả tương ứng. Xem [NOTICE.md](NOTICE.md).
