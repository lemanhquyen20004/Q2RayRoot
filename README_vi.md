# Q2Ray Root

**Q2Ray Root** là module proxy dành cho **Android đã root**, do **lemanhquyen20004** phát triển và quản lý. Dự án tích hợp Xray-core, giao diện WebUI và khả năng chia sẻ proxy qua điểm phát Wi-Fi (Hotspot).

[English](README.md) · [Tải phiên bản](https://github.com/lemanhquyen20004/Q2RayRoot/releases) · [Mã nguồn](https://github.com/lemanhquyen20004/Q2RayRoot)

> **Phiên bản v0.0.2 — bản thử nghiệm kỹ thuật.** Bản này đã vượt qua kiểm tra tự động trên GitHub Actions nhưng **chưa được xác nhận chạy ổn định trên Redmi Note 8T / MIUI 12.5.5 / Android 11**.

## Chức năng chính

- **Xray-core:** chuyển tiếp lưu lượng TCP/UDP bằng cơ chế TPROXY.
- **Giao diện hai ngôn ngữ:** **Tiếng Việt** và **English**, có thể chuyển đổi ngay trong WebUI.
- **Quản lý cấu hình:** nhập liên kết VLESS hỗ trợ TLS/REALITY, chỉnh sửa JSON Xray và kiểm tra cấu hình.
- **Chia sẻ proxy qua Hotspot:** tùy chọn định tuyến lưu lượng thiết bị kết nối vào điểm phát Wi-Fi.
- **Bảo vệ kết nối:** cố gắng khôi phục mạng Direct và dọn những quy tắc do module tạo khi khởi động thất bại hoặc Xray dừng bất thường.
- **Cập nhật qua GitHub:** kiểm tra phiên bản mới, xác minh file ZIP bằng SHA-256 và hỗ trợ cài từ WebUI trên Magisk.

**Mặc định an toàn:** Module không tự bật proxy sau khi cài hoặc sau khi khởi động lại điện thoại. Chức năng chia sẻ proxy qua Hotspot cũng mặc định tắt.

## Yêu cầu

- Điện thoại Android đã root bằng **Magisk, KernelSU hoặc APatch**.
- Vi xử lý **ARM64**.
- Trình quản lý hỗ trợ WebUI (một số phiên bản Magisk cần KsuWebUIStandalone).
- Có node proxy đang hoạt động để sử dụng Internet qua Xray.

## Cách cài đặt

1. Tải **[Q2RayRoot-v0.0.2-arm64.zip](https://github.com/lemanhquyen20004/Q2RayRoot/releases/download/v0.0.2/Q2RayRoot-v0.0.2-arm64.zip)** từ trang Release chính thức.
2. Mở **Magisk → Modules → Install from storage** (hoặc chức năng cài module tương ứng trên KernelSU/APatch).
3. Chọn file ZIP và khởi động lại điện thoại sau khi cài.
4. Mở **Q2Ray Root WebUI** và chọn **Tiếng Việt** hoặc **English**.
5. Nhập link VLESS hoặc cấu hình Xray JSON, sau đó lưu và kiểm tra.
6. Nhấn **Bật Xray**, thử truy cập Internet trên điện thoại trước.
7. Nếu muốn chia sẻ proxy, bật **Chia sẻ Proxy qua Hotspot** rồi kiểm tra Internet trên thiết bị nhận Wi-Fi.

**Lưu ý:** Không dùng file **Source code ZIP** được GitHub tạo tự động để cài Magisk, vì file đó không chứa Xray-core ARM64.

## Cập nhật tự động qua GitHub

### Cách 1: Trong Magisk

Khi có bản mới với `versionCode` cao hơn, mở **Magisk → Modules → Q2Ray Root → Update**. Magisk sẽ tải và cài file module từ GitHub Releases. Khởi động lại khi cài xong.

### Cách 2: Trong WebUI

Mở **Cập nhật → Kiểm tra cập nhật**. Nếu có phiên bản mới, nhấn **Tải & cài đặt** và xác nhận. Chức năng sẽ tải ZIP từ GitHub của dự án, kiểm tra SHA-256 và cài bằng lệnh Magisk. Sau khi thông báo cài đặt thành công, **khởi động lại** để áp dụng.

Với **KernelSU/APatch**, dùng nút cập nhật trong trình quản lý module. Module **không tự cài đặt khi bạn chưa xác nhận** và sẽ xóa file ZIP tạm sau khi cập nhật hoàn tất.

Khi phát triển bản mới, cần tăng `version` và `versionCode` trong `module.prop` và `update.json`. GitHub Actions sẽ kiểm tra mã nguồn, build ZIP ARM64 và xuất bản bản prerelease cùng checksum.

## Khắc phục lỗi mạng

Không nên chạy đồng thời nhiều module proxy trong suốt trên máy root vì các quy tắc tường lửa và định tuyến có thể xung đột.

Nếu không vào được 4G hoặc Wi-Fi sau khi bật Xray, hãy nhấn **Tắt / Direct**. Nếu mạng vẫn chưa khôi phục, tắt module trong Magisk và khởi động lại.

| Đường dẫn | Nội dung |
| --- | --- |
| `/data/adb/q2rayroot/config.json` | Cấu hình Xray đã lưu |
| `/data/adb/q2rayroot/run.log` | Nhật ký hoạt động và định tuyến |
| `/data/adb/q2rayroot/update.status` | Trạng thái cập nhật |
| `/data/adb/q2rayroot/update.log` | Nhật ký cập nhật |

**Bảo mật:** Không đăng UUID của node VLESS, link subscription có token hoặc thông tin máy chủ riêng tư lên GitHub công khai.

## Cấu trúc dự án

| Thành phần | Chức năng |
| --- | --- |
| `scripts/q2r.sh` | Điều khiển Xray, TPROXY, Hotspot, khôi phục mạng |
| `scripts/update.sh` | Kiểm tra và cài bản cập nhật đã xác minh |
| `webroot/index.html` | Giao diện tiếng Việt và tiếng Anh |
| `config/default.json` | Cấu hình Xray ban đầu ở chế độ Direct |
| `build.sh` | Đóng gói module ARM64 |
| `.github/workflows/build.yml` | Kiểm tra, build và tạo bản phát hành |

## Định hướng phát triển

Các tính năng dự kiến cho phiên bản sau gồm: **Mihomo, sing-box, quản lý subscription nâng cao, giới hạn dữ liệu theo thiết bị Hotspot và chế độ chơi game**. Những chức năng này **chưa có trong v0.0.2**.

## Bản quyền

**Copyright © 2026 lemanhquyen20004** — đối với mã nguồn và giao diện gốc của dự án Q2Ray Root.

Dự án sử dụng giấy phép **GPL-3.0-or-later**. Những thành phần bên thứ ba, bao gồm **Xray-core (MPL-2.0)**, giữ nguyên giấy phép và quyền tác giả tương ứng. Xem [LICENSE](LICENSE) và [NOTICE.md](NOTICE.md).

*Q2Ray Root là dự án được phát triển và quản lý riêng. Tính tương thích và độ ổn định phụ thuộc từng thiết bị, bản Android và kernel.*
