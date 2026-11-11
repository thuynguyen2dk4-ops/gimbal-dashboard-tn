# T-Flow Smart Gimbal — Web Platform & Native iOS App

Mã nguồn hợp nhất (Monorepo) cho hệ sinh thái phần mềm **T-Flow Smart Gimbal**:
- **Commercial Web & Portals** (deploy trực tiếp trên Vercel tại [t-flow-tech.vercel.app](https://t-flow-tech.vercel.app))
- **Serverless AI Assistant API** (`/api/chat`)
- **Native iOS App (`SmartGimbalPro`)** xây dựng theo kiến trúc Modular SwiftUI (biên dịch `.ipa` tự động qua GitHub Actions macOS Xcode)

---

## Cấu trúc Thư mục Chuẩn Hóa

```text
gimbal-dashboard-tn/
├── index.html                           # Storefront chính + SPA Router (/ , /san-pham , /san-pham/:slug , /danh-gia)
├── vercel.json                          # Rewrites Clean URL & Redirects 301/308 vĩnh viễn
├── package.json / vite.config.js        # Cấu hình build Vite & ESLint cho Vercel
├── api/
│   └── chat.js                          # Vercel Serverless Function (Trợ lý ảo T-Flow AI)
├── public/                              # Static routes & assets public (Vercel phục vụ tại root /)
│   ├── favicon.svg
│   ├── account/index.html               # /account — Cổng khách hàng, đơn hàng & thiết bị
│   ├── admin/index.html                 # /admin — Admin CMS quản lý sản phẩm & module iOS
│   ├── profile/index.html               # /profile — Chỉnh sửa hồ sơ người dùng
│   ├── studio/index.html                # /studio — Vibe-Coding Live Inspector
│   ├── auth/google/index.html           # /auth/google/ — Cửa sổ OAuth Google thống nhất
│   └── shared/
│       ├── catalog_store.js             # Nguồn dữ liệu sản phẩm, giỏ hàng & đồng bộ realtime
│       └── img/                         # Tài nguyên ảnh 3D CAD/PCB thật, vector SVG phụ kiện & logo thương hiệu T-Flow
├── ios_app/                             # Native iOS App (Swift / SwiftUI — iOS 16+)
│   ├── project.yml                      # Đặc tả XcodeGen tự động gom Sources/**
│   ├── SmartGimbalPro.xcodeproj/        # Project Xcode đồng bộ 1:1 với 20 module Swift
│   └── Sources/
│       ├── Info.plist
│       ├── Assets.xcassets/             # AppIcon đầy đủ kích thước
│       ├── App/                         # SmartGimbalApp.swift (@main), MainTabShellView.swift
│       ├── Models/                      # GimbalModels.swift
│       ├── Services/                    # BLEGimbalManager.swift, CameraService.swift, SupabaseModuleStore.swift
│       ├── Components/                  # TFlowBrandLogo.swift, AspectLetterboxMaskView.swift, TelemetryMetersView.swift
│       └── Views/
│           ├── Camera/                  # CameraStudioNativeView, NativeCameraPreviewRepresentable, Sheets...
│           ├── Gimbal/                  # GimbalDeviceHubView, AutoCalibrationModalView
│           ├── Assistant/               # TFlowAIChatAssistantView
│           └── Profile/                 # UserProfilePermissionsView, ModuleDetailInspectorSheet, Paywall...
├── .github/workflows/
│   └── build_ios_ipa.yml                # GitHub Actions macOS XcodeGen + xcodebuild đóng gói .ipa
└── src/                                 # Nguyên mẫu Web BLE bằng Vite + React (giữ làm nền build Vite / tham khảo)
```

---

## Bản đồ Route Web Chuẩn (Single Source of Truth)

| URL Công Khai | Tệp Nguồn | Ghi Chú |
| :--- | :--- | :--- |
| `/` | `index.html` | Trang chủ T-Flow Pro Flagship |
| `/san-pham`, `/san-pham/:slug` | `index.html` | Dải sản phẩm DJI-style & trang chi tiết sản phẩm |
| `/danh-gia` | `index.html` | Đánh giá & Hỏi đáp |
| `/account` | `public/account/index.html` | Cổng khách hàng |
| `/admin` | `public/admin/index.html` | Quản trị CMS & Feature Flags |
| `/profile` | `public/profile/index.html` | Hồ sơ cá nhân |
| `/auth/google/` | `public/auth/google/index.html` | Google OAuth Popup |
| `/studio` | `public/studio/index.html` | Vibe-Coding Live Studio |
| `/api/chat` | `api/chat.js` | AI Chatbot API |

> Các đường dẫn cũ (`/web/*.html`, `/google_auth.html`) được chuyển hướng vĩnh viễn (`308`) sang đường dẫn chuẩn tương ứng trong `vercel.json`.
