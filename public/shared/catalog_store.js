/**
 * T-Flow Pro - Unified Dynamic Catalog & Authentication Store
 * Công ty TNHH Công nghệ T-Flow Việt Nam (T-Flow Tech Co., Ltd.)
 * Master Admin: thuynguyen2dk4@gmail.com
 */

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([], factory);
  } else if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.SmartGimbalCatalog = factory();
  }
}(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  var STORAGE_KEY = 'tflow_pro_catalog_v2';
  var CART_KEY = 'tflow_pro_cart_v2';
  var ORDERS_KEY = 'tflow_pro_orders_v2';
  var CURRENT_USER_KEY = 'tflow_pro_current_user_v2';
  var SYNC_EVENT = 'tflow_catalog_synced';
  var CART_EVENT = 'tflow_cart_updated';
  var USER_EVENT = 'tflow_user_updated';
  var REVIEWS_KEY = 'tflow_pro_real_user_reviews_v2';
  var REVIEWS_EVENT = 'tflow_reviews_updated';

  var ADMIN_GMAILS = ['thuynguyen2dk4@gmail.com', 'thuy.nguyen@tflow.tech'];

  // ==========================================================================
  // 1. DEFAULT DATA DEFINITIONS
  // ==========================================================================
  var DEFAULT_CATALOG = {
    "mvpProductId": "tf-g31-pro",
    "brand": {
      "name": "T-Flow",
      "logoText": "t-flow",
      "company": "Công ty TNHH Công nghệ T-Flow Việt Nam",
      "companyEn": "T-Flow Tech Co., Ltd.",
      "prefix": "TF",
      "sloganIntl": "Smooth Every Moment.",
      "sloganVi": "mượt mà từng khoảnh khắc",
      "silkscreen1": "Engineered by T-Flow in Hanoi",
      "silkscreen2": "Pure FOC Inside - Zero Jitter",
      "address": "Tòa nhà Công nghệ T-Flow, Hà Nội, Việt Nam",
      "hotline": "1900 8888",
      "email": "support@tflow.tech",
      "website": "https://gimbal-dashboard-tn.vercel.app"
    },
    "namingRules": [
      {
        "id": "rule-1",
        "title": "1. Quy tắc Tên Thương mại (B2C)",
        "formula": "T-Flow + [Tên Dòng] + [Hậu tố]",
        "desc": "Không dùng mã số phức tạp. Giữ tên gọi dưới 4 từ để hiển thị đẹp trên bao bì và sàn TMĐT.",
        "convention": "Hậu tố: Go/Air (Gọn nhẹ, phổ thông) • Pro/Max (Cao cấp, tải nặng) • SE (Bản rút gọn giá tốt)",
        "example": "T-Flow Go, T-Flow Pro, T-Flow Air, T-Flow Eye"
      },
      {
        "id": "rule-2",
        "title": "2. Quy tắc Mã Kỹ thuật (SKU / PCB)",
        "formula": "TF - [Phân hệ][Thông số] - [Chức năng] - [Rev]",
        "desc": "TF là tiền tố cố định. Phân hệ: G (Gimbal), CAM (Camera), M (Mainboard), D (Driver), X (Mạch mở rộng/Cảm biến), B (Bridge - Mạch chuyển đổi). [Rev]: Bản phần cứng (R1.0, R1.1).",
        "convention": "In lụa bắt buộc trên PCB: 'Engineered by T-Flow in Hanoi' & 'Pure FOC Inside - Zero Jitter'",
        "example": "TF-D3X-FOC-R1.0, TF-G31-PRO-R1.0, TF-CAM-AI01-R1.0"
      },
      {
        "id": "rule-3",
        "title": "3. Quy tắc Đánh mã Chi tiết Cơ khí / In 3D",
        "formula": "TF - [Mã Máy] - MEC - [Số thứ tự] - [Vật liệu]",
        "desc": "Dùng để quản lý các file CAD 3D, STL in 3D và gia công CNC.",
        "convention": "Vật liệu: PETG (in 3D), AL6061 (nhôm hàng không CNC), CF (sợi carbon 8 lớp)",
        "example": "TF-G31-MEC-01-PETG, TF-G31-MEC-02-AL6061"
      },
      {
        "id": "rule-4",
        "title": "4. Quy tắc Đặt tên Kho mã nguồn (GitHub / Firmware)",
        "formula": "tflow-[phân-hệ]-[loại-code]",
        "desc": "Viết thường toàn bộ, nối bằng dấu gạch ngang để chuẩn hóa đường dẫn lập trình.",
        "convention": "Đồng bộ chuẩn CI/CD Vercel và GitHub Actions",
        "example": "tflow-g31-firmware, tflow-foc-library, tflow-studio-app"
      },
      {
        "id": "rule-5",
        "title": "5. Quy tắc Đánh số Phiên bản (Versioning)",
        "formula": "v[Major].[Minor].[Patch]",
        "desc": "Major: Thay đổi kiến trúc chip/cơ khí. Minor: Thêm tính năng quay mới. Patch: Sửa lỗi bug.",
        "convention": "Chuẩn hóa Semantic Versioning",
        "example": "FW-TF-G31-v1.2.0"
      }
    ],
    "groups": [
      {
        "id": "group-gimbal",
        "name": "1. Gimbal Cầm Tay (B2C Chủ Lực)",
        "icon": "bi-camera-reels",
        "prefix": "TF-G",
        "desc": "Thiết bị ổn định 3 trục chuẩn điện ảnh cho Smartphone và Camera Creator."
      },
      {
        "id": "group-cam",
        "name": "2. Cụm Camera & Phụ Kiện AI",
        "icon": "bi-camera",
        "prefix": "TF-CAM",
        "desc": "Mô-đun camera AI tracking nhận diện chủ thể độc lập và đèn trợ sáng MagSafe."
      },
      {
        "id": "group-core",
        "name": "3. Bo Mạch Điều Khiển Lõi",
        "icon": "bi-cpu",
        "prefix": "TF-M / TF-D",
        "desc": "Bo mạch chủ vi điều khiển 32-bit STM32 và mạch công suất Pure FOC 20kHz."
      },
      {
        "id": "group-sensor",
        "name": "4. Bo Mạch Mở Rộng & Cảm Biến",
        "icon": "bi-hdd-network",
        "prefix": "TF-X",
        "desc": "Cảm biến gia tốc IMU 6 trục và cảm biến từ Magnetic Encoder độ phân giải 14-bit."
      }
    ],
    "products": [
      {
        "id": "tf-g31-pro",
        "sku": "TF-G31-PRO",
        "groupId": "group-gimbal",
        "name": "T-Flow Pro",
        "tagline": "Vững khung hình, Trọn cảm xúc. Đỉnh cao chống rung 3 trục cho Smartphone.",
        "subtitle": "Gimbal 3 trục thông minh cho iPhone và Smartphone cao cấp. Động cơ tải trọng 450g, thuật toán Pure FOC 20kHz, vòng xoay lấy nét Focus Wheel và khung hợp kim hàng không kết hợp sợi Carbon dệt 8 lớp.",
        "badge": "Flagship 2026",
        "img": "../shared/img/feed_portrait_dusk.jpg",
        "status": "Đang Mở Bán",
        "totalOrders": 1420,
        "is_flagship": true,
        "gallery": [
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_person_portrait.jpg",
          "../shared/img/feed_land_dusk.jpg"
        ],
        "colors": [
          { "id": "space-black", "name": "Space Black (Đen Không Gian)", "hex": "#1F2022" },
          { "id": "natural-titanium", "name": "Natural Titanium (Titan Tự Nhiên)", "hex": "#8A8680" },
          { "id": "silver-white", "name": "Silver White (Trắng Bạc)", "hex": "#E5E5EA" }
        ],
        "tiers": [
          {
            "key": "standard",
            "name": "Standard Edition",
            "tag": "Khởi Đầu",
            "price": 2490000,
            "origPrice": 2890000,
            "priceFormatted": "2.490.000₫",
            "desc": "Trọn bộ gimbal T-Flow Pro, ngàm kẹp từ tính MagSafe N52, cáp sạc USB-C và chân đế Tripod mini."
          },
          {
            "key": "creator",
            "name": "Creator Kit",
            "tag": "Bán Chạy Nhất",
            "price": 3190000,
            "origPrice": 3690000,
            "priceFormatted": "3.190.000₫",
            "desc": "Gồm Standard Kit + Đèn trợ sáng từ tính T-Flow Glow RGB và Túi đeo chéo EVA chống sốc."
          },
          {
            "key": "cinematic",
            "name": "Cinematic Pro",
            "tag": "Được Khuyên Dùng",
            "price": 3990000,
            "origPrice": 4590000,
            "priceFormatted": "3.990.000₫",
            "desc": "Gồm Creator Kit + Micro thu âm không dây kép 2.4GHz chống ồn AI + Bộ tạ đối trọng Pro."
          },
          {
            "key": "master",
            "name": "Master Edition",
            "tag": "Đặc Biệt",
            "price": 5490000,
            "origPrice": 6290000,
            "priceFormatted": "5.490.000₫",
            "desc": "Full bộ phụ kiện cao cấp + Vali nhôm hàng không nguyên khối + Khóa học MasterClass trọn đời."
          }
        ],
        "highlights": [
          {
            "icon": "⚡",
            "title": "Thuật Toán Pure FOC 20kHz",
            "desc": "Tần số chuyển mạch 20kHz siêu êm, triệt tiêu hoàn toàn rung giật vi mô và tải trọng cực đại 450g."
          },
          {
            "icon": "🧲",
            "title": "Ngàm MagSafe Siêu Hút 45N N52",
            "desc": "Nam châm Neodymium N52 đa cực lực hút 45N, tháo lắp điện thoại tức thời trong 1 giây."
          },
          {
            "icon": "🎯",
            "title": "Vòng Xoay Focus Wheel Cơ Học",
            "desc": "Căn chỉnh tiêu cự lấy nét mượt mà và zoom quang học vô cấp chuẩn điện ảnh."
          }
        ],
        "specs": [
          { "label": "Mã Sản Phẩm (SKU)", "val": "TF-G31-PRO" },
          { "label": "Tải Trọng Động Cơ", "val": "450g (Cân tốt iPhone 16 Pro Max kèm lens và mic)" },
          { "label": "Thuật Toán Điều Khiển", "val": "Pure FOC 20kHz Vector Control (Zero Jitter)" },
          { "label": "Cảm Biến Trục", "val": "14-bit Magnetic Encoder + 6-Axis IMU" },
          { "label": "Thời Lượng Pin", "val": "18 giờ liên tục (Cell Lithium 3200mAh, sạc ngược không dây)" },
          { "label": "Chất Liệu Khung", "val": "Hợp kim nhôm AL6061 hàng không CNC & Sợi Carbon dệt 8 lớp" },
          { "label": "Kết Nối Không Dây", "val": "Bluetooth 5.3 Low Energy (Độ trễ < 5ms)" },
          { "label": "Ứng Dụng Hỗ Trợ", "val": "T-Flow Cam (iOS 16+, Apple Log ProRes, AI Face Track)" }
        ],
        "boxContents": [
          { "name": "Gimbal 3 Trục T-Flow Pro", "qty": "01" },
          { "name": "Ngàm Kẹp Từ Tính MagSafe N52", "qty": "01" },
          { "name": "Chân Đế Tripod Mini Hợp Kim", "qty": "01" },
          { "name": "Cáp Sạc Nhanh Type-C to Type-C PD", "qty": "01" },
          { "name": "Túi Đựng Nhựa Nhung Cao Cấp", "qty": "01" }
        ]
      },
      {
        "id": "tf-cam-eye",
        "sku": "TF-CAM-AI01",
        "groupId": "group-cam",
        "name": "T-Flow Eye — Mô-đun AI Tracking & Đèn RGB",
        "tagline": "Theo dõi chủ thể thông minh độc lập không cần kết nối App qua Bluetooth.",
        "subtitle": "Camera AI cảm biến quang học độc lập nhận diện khuôn mặt và cử chỉ tay ở khoảng cách 5m. Tích hợp đèn LED trợ sáng Bi-Color CRI 96+ đổi nhiệt độ màu 2500K-6500K, hít trực tiếp sau lưng ngàm MagSafe.",
        "badge": "Phụ Kiện AI Mới",
        "img": "../shared/img/feed_person_portrait.jpg",
        "status": "Đang Mở Bán",
        "totalOrders": 520,
        "is_flagship": false,
        "gallery": [
          "../shared/img/feed_person_portrait.jpg",
          "../shared/img/feed_portrait_day.jpg"
        ],
        "colors": [
          { "id": "space-black", "name": "Space Black", "hex": "#1F2022" }
        ],
        "tiers": [
          {
            "key": "standard",
            "name": "Bản Đơn",
            "tag": "Tiêu Chuẩn",
            "price": 890000,
            "origPrice": 1090000,
            "priceFormatted": "890.000₫",
            "desc": "Mô-đun Camera AI Tracking + Ngàm hít MagSafe + Cáp sạc Type-C."
          }
        ],
        "highlights": [
          { "icon": "👁️", "title": "AI Tracking Độc Lập", "desc": "Tự động bám người livestream trên TikTok, Facebook, YouTube mà không cần app phụ trợ." },
          { "icon": "💡", "title": "Đèn Trợ Sáng Bi-Color", "desc": "Tích hợp đèn LED đổi màu 2500K-6500K tôn da với độ hoàn màu CRI 96+ chuẩn studio." }
        ],
        "specs": [
          { "label": "SKU", "val": "TF-CAM-AI01" },
          { "label": "Tương Thích", "val": "T-Flow Pro & các thiết bị hỗ trợ MagSafe" },
          { "label": "Khoảng Cách Nhận Diện", "val": "0.5m - 5m góc rộng 120°" },
          { "label": "Thời Lượng Pin", "val": "4 giờ liên tục (Pin sạc riêng 800mAh)" }
        ],
        "boxContents": [
          { "name": "Mô-đun T-Flow Eye", "qty": "01" },
          { "name": "Cáp Sạc Type-C", "qty": "01" }
        ]
      },
      {
        "id": "tf-acc-tripod",
        "sku": "TF-ACC-TRIPOD",
        "groupId": "group-gimbal",
        "name": "Chân Đế Mini Tripod Carbon T-Flow",
        "tagline": "Vững chãi trên mọi địa hình, trọng lượng siêu nhẹ từ sợi Carbon 8 lớp.",
        "subtitle": "Chân đế 3 chân mini hợp kim nhôm hàng không và sợi carbon dệt 8 lớp. Ren tiêu chuẩn 1/4 inch tương thích hoàn hảo với T-Flow Pro, máy ảnh mirrorless và rig quay phim.",
        "badge": "Phụ Kiện Chính Hãng",
        "img": "../shared/img/feed_land_dusk.jpg",
        "status": "Đang Mở Bán",
        "totalOrders": 890,
        "is_flagship": false,
        "gallery": [
          "../shared/img/feed_land_dusk.jpg"
        ],
        "colors": [
          { "id": "carbon-black", "name": "Carbon Weave Black", "hex": "#1A1A1A" }
        ],
        "tiers": [
          {
            "key": "standard",
            "name": "Bản Tiêu Chuẩn",
            "tag": "Carbon CNC",
            "price": 390000,
            "origPrice": 490000,
            "priceFormatted": "390.000₫",
            "desc": "Chân đế mini tripod Carbon + Khóa siết lục giác chống trượt."
          }
        ],
        "highlights": [
          { "icon": "🪶", "title": "Trọng Lượng Chỉ 85g", "desc": "Sợi carbon 8 lớp siêu nhẹ nhưng chịu tải đứng lên đến 5kg." },
          { "icon": "🔒", "title": "Đế Cao Su Chống Trượt", "desc": "Đệm silicon chống trầy xước và bám chặt bề mặt nghiêng." }
        ],
        "specs": [
          { "label": "SKU", "val": "TF-ACC-TRIPOD" },
          { "label": "Vật Liệu", "val": "Sợi Carbon 8 lớp & Nhôm AL6061 CNC" },
          { "label": "Chuẩn Ren", "val": "1/4 inch tiêu chuẩn quốc tế" },
          { "label": "Tải Trọng Chịu Đựng", "val": "5.0 kg" }
        ],
        "boxContents": [
          { "name": "Chân Đế Carbon T-Flow", "qty": "01" }
        ]
      },
      {
        "id": "tf-acc-case",
        "sku": "TF-ACC-CASE",
        "groupId": "group-gimbal",
        "name": "Vali Hàng Không Chống Sốc T-Flow Master",
        "tagline": "Bảo vệ toàn diện chuẩn quân đội cho toàn bộ bộ kit gimbal và phụ kiện.",
        "subtitle": "Vali hợp kim nhôm nguyên khối bo góc kim loại. Khay mút EVA đúc laser định hình chính xác từng vị trí gimbal, đèn, mic và pin sạc. Kháng nước và chống bụi tiêu chuẩn IP67.",
        "badge": "Kháng Nước IP67",
        "img": "../shared/img/feed_portrait_day.jpg",
        "status": "Đang Mở Bán",
        "totalOrders": 310,
        "is_flagship": false,
        "gallery": [
          "../shared/img/feed_portrait_day.jpg"
        ],
        "colors": [
          { "id": "stealth-black", "name": "Stealth Black", "hex": "#242426" },
          { "id": "aviation-silver", "name": "Aviation Silver", "hex": "#D1D5DB" }
        ],
        "tiers": [
          {
            "key": "standard",
            "name": "Bản Cao Cấp",
            "tag": "IP67 Armor",
            "price": 1190000,
            "origPrice": 1490000,
            "priceFormatted": "1.190.000₫",
            "desc": "Vali hợp kim nhôm nguyên khối + Quai xách bọc da + Dây đeo vai đệm khí."
          }
        ],
        "highlights": [
          { "icon": "🛡️", "title": "Khung Nhôm Hàng Không", "desc": "Chống va đập lực nén 120kg, bảo vệ tuyệt đối thiết bị đắt tiền." },
          { "icon": "💧", "title": "Kháng Nước IP67", "desc": "Gioăng cao su kép ngăn nước biển và cát bụi xâm nhập." }
        ],
        "specs": [
          { "label": "SKU", "val": "TF-ACC-CASE" },
          { "label": "Kích Thước", "val": "320 x 240 x 110 mm" },
          { "label": "Trọng Lượng", "val": "1.25 kg" },
          { "label": "Chuẩn Bảo Vệ", "val": "IP67 Waterproof & Dustproof" }
        ],
        "boxContents": [
          { "name": "Vali Hợp Kim T-Flow", "qty": "01" },
          { "name": "Dây Đeo Vai Đệm Khí", "qty": "01" }
        ]
      },
      {
        "id": "tf-m32-core",
        "sku": "TF-M32-FOC-R1",
        "groupId": "group-core",
        "name": "Bo Mạch Điều Khiển Lõi 32-bit Pure FOC 20kHz",
        "tagline": "Trái tim xử lý thuật toán động cơ 3 trục siêu êm mượt cho kỹ sư R&D.",
        "subtitle": "Bo mạch chủ vi điều khiển ARM Cortex-M4 32-bit tần số xung nhịp 168MHz. Tích hợp mạch cầu H MOSFET công suất Pure FOC tần số 20kHz triệt tiêu tiếng rít và cổng giao tiếp CAN-Bus/UART.",
        "badge": "Linh Kiện R&D",
        "img": "../shared/img/feed_land_day.jpg",
        "status": "Sẵn Hàng",
        "totalOrders": 140,
        "is_flagship": false,
        "gallery": [
          "../shared/img/feed_land_day.jpg"
        ],
        "colors": [
          { "id": "pcb-black", "name": "Matte Black PCB", "hex": "#1C1C1E" }
        ],
        "tiers": [
          {
            "key": "standard",
            "name": "Bo Mạch R1.0",
            "tag": "OEM Component",
            "price": 1450000,
            "origPrice": 1750000,
            "priceFormatted": "1.450.000₫",
            "desc": "Bo mạch chủ FOC 32-bit nạp sẵn Bootloader + Bộ giắc cắm tín hiệu JST."
          }
        ],
        "highlights": [
          { "icon": "🧠", "title": "MCU Cortex-M4 168MHz", "desc": "Tính toán ma trận Euler & bộ lọc Madgwick/EKF chu kỳ 1000Hz." },
          { "icon": "⚡", "title": "Mosfet FOC 20kHz", "desc": "Chuyển mạch êm ru không tạo tiếng ồn siêu âm làm phiền mic thu âm." }
        ],
        "specs": [
          { "label": "SKU", "val": "TF-M32-FOC-R1" },
          { "label": "Điện Áp Hoạt Động", "val": "7.4V - 12.6V (2S - 3S Li-ion)" },
          { "label": "Dòng Điện Cực Đại", "val": "15A tức thời / 5A liên tục" },
          { "label": "Giao Tiếp", "val": "CAN-Bus, UART, I2C, SPI" }
        ],
        "boxContents": [
          { "name": "Bo Mạch TF-M32-FOC", "qty": "01" },
          { "name": "Dây Cáp JST-SH Kết Nối", "qty": "04" }
        ]
      },
      {
        "id": "tf-x14-imu",
        "sku": "TF-X14-IMU-R1",
        "groupId": "group-sensor",
        "name": "Mạch Cảm Biến Góc Mag-IMU 14-bit Siêu Nhạy",
        "tagline": "Cảm biến từ trường góc quay 14-bit và gia tốc con quay hồi chuyển 6 trục.",
        "subtitle": "Mô-đun cảm biến độ phân giải 16384 xung/vòng (14-bit) kết hợp IMU 6-DOF bù nhiệt độ. Cung cấp dữ liệu phản hồi góc nghiêng Roll/Pitch/Yaw chính xác đến 0.01 độ cho vòng lặp FOC.",
        "badge": "Độ Nhạy Cao",
        "img": "../shared/img/feed_person_land.jpg",
        "status": "Sẵn Hàng",
        "totalOrders": 280,
        "is_flagship": false,
        "gallery": [
          "../shared/img/feed_person_land.jpg"
        ],
        "colors": [
          { "id": "pcb-green", "name": "Industry Green PCB", "hex": "#1B4332" }
        ],
        "tiers": [
          {
            "key": "standard",
            "name": "Bộ 3 Cảm Biến Trục",
            "tag": "Full Set 3 Axis",
            "price": 650000,
            "origPrice": 800000,
            "priceFormatted": "650.000₫",
            "desc": "Gồm 3 mạch cảm biến Encoder 14-bit + Nam châm từ tính định tâm CNC."
          }
        ],
        "highlights": [
          { "icon": "🧭", "title": "14-bit Magnetic Sensing", "desc": "Độ phân giải 16,384 xung/vòng cho chuyển động vi mô không gợn sóng." },
          { "icon": "📐", "title": "Chống Nhiễu Từ Trường", "desc": "Mạch lọc phần cứng khử nhiễu từ động cơ và nguồn điện xung." }
        ],
        "specs": [
          { "label": "SKU", "val": "TF-X14-IMU-R1" },
          { "label": "Độ Phân Giải", "val": "14-bit (0.022 độ/bước)" },
          { "label": "Chuẩn Giao Tiếp", "val": "SPI / SSI tốc độ cao 10MHz" },
          { "label": "Kích Thước", "val": "15mm x 15mm siêu nhỏ gọn" }
        ],
        "boxContents": [
          { "name": "Mạch Cảm Biến Mag-IMU", "qty": "03" },
          { "name": "Nam Châm Trục Định Tâm", "qty": "03" }
        ]
      }
    ],
    "users": [
      {
        "id": "thuy-nguyen",
        "name": "Thuy Nguyen",
        "email": "thuynguyen2dk4@gmail.com",
        "password": "admin",
        "phone": "0908 888 888",
        "role": "Master Administrator & Founder",
        "company": "Công ty TNHH Công nghệ T-Flow Việt Nam",
        "tierBadge": "Master Admin",
        "registeredDevice": "T-Flow Pro (TF-G31-PRO)",
        "serial": "HQYVYFYFR4",
        "battery": 98,
        "firmware": "FW-TF-G31-v1.2.0 (Mới nhất)",
        "status": "Đang Hoạt Động",
        "modules": [true, true, true, true, true, true, true]
      }
    ]
  };

  var DEFAULT_REVIEWS = []; // 100% REAL DATA - NO FAKE REVIEWS

  // ==========================================================================
  // 2. CORE STORAGE HELPERS
  // ==========================================================================
  function getMvpProductId() {
    var cat = getCatalog();
    return cat.mvpProductId || (cat.products && cat.products[0] ? cat.products[0].id : "tf-g31-pro");
  }

  function setMvpProduct(productId) {
    var cat = getCatalog();
    var exists = (cat.products || []).some(function (p) { return p.id === productId; });
    if (!exists) return false;

    cat.mvpProductId = productId;
    cat.products.forEach(function (p) {
      p.is_flagship = (p.id === productId);
    });
    saveCatalog(cat);
    broadcastSync();
    return true;
  }

  function getMvpProduct() {
    var cat = getCatalog();
    var mvpId = cat.mvpProductId || "tf-g31-pro";
    var prod = (cat.products || []).find(function (p) { return p.id === mvpId; });
    return prod || (cat.products && cat.products[0]) || null;
  }

  function getCatalog() {
    if (typeof localStorage === 'undefined') return DEFAULT_CATALOG;
    var saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      saveCatalog(DEFAULT_CATALOG);
      return DEFAULT_CATALOG;
    }
    try {
      var parsed = JSON.parse(saved);
      if (!parsed.products || parsed.products.length < DEFAULT_CATALOG.products.length) {
        saveCatalog(DEFAULT_CATALOG);
        return DEFAULT_CATALOG;
      }
      // Normalize tiers ensuring name & label are always populated
      (parsed.products || []).forEach(function(p) {
        if (p.tiers && Array.isArray(p.tiers)) {
          p.tiers.forEach(function(t, idx) {
            if (!t.key && t.id) t.key = t.id;
            if (!t.key) t.key = 'tier-' + idx;
            if (!t.name && t.label) t.name = t.label;
            if (!t.label && t.name) t.label = t.name;
            if (!t.name && !t.label) {
              t.name = t.tag || ('Phiên bản ' + (idx + 1));
              t.label = t.name;
            }
          });
        }
      });
      return parsed;
    } catch (e) {
      saveCatalog(DEFAULT_CATALOG);
      return DEFAULT_CATALOG;
    }
  }

  function saveCatalog(catalogData) {
    if (typeof localStorage === 'undefined') return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(catalogData));
      broadcastSync(catalogData);
    } catch (e) {
      console.error('[SmartGimbalCatalog] Error saving catalog:', e);
    }
  }

  function resetToDefault() {
    saveCatalog(DEFAULT_CATALOG);
    return getCatalog();
  }

  function broadcastSync(catalogData) {
    if (typeof window === 'undefined') return;
    try {
      var evt = new CustomEvent(SYNC_EVENT, { detail: catalogData });
      window.dispatchEvent(evt);
    } catch (e) {}

    try {
      var frames = window.parent && window.parent.frames ? window.parent.frames : [];
      for (var i = 0; i < frames.length; i++) {
        try {
          frames[i].postMessage({ type: 'SMART_GIMBAL_CATALOG_SYNC', catalog: catalogData }, '*');
        } catch (err) {}
      }
    } catch (e) {}
  }

  // ==========================================================================
  // 3. GROUPS & PRODUCTS CRUD
  // ==========================================================================
  function getGroups() {
    return getCatalog().groups || [];
  }

  function getGroup(groupId) {
    return getGroups().find(function (g) { return g.id === groupId; }) || null;
  }

  function addGroup(groupObj) {
    var cat = getCatalog();
    if (!groupObj.id) groupObj.id = 'cat-' + Date.now();
    cat.groups.push(groupObj);
    saveCatalog(cat);
    return groupObj;
  }

  function updateGroup(groupId, updateData) {
    var cat = getCatalog();
    var idx = cat.groups.findIndex(function (g) { return g.id === groupId; });
    if (idx === -1) return false;
    Object.assign(cat.groups[idx], updateData);
    saveCatalog(cat);
    return true;
  }

  function deleteGroup(groupId) {
    var cat = getCatalog();
    var idx = cat.groups.findIndex(function (g) { return g.id === groupId; });
    if (idx === -1) return false;
    cat.groups.splice(idx, 1);
    saveCatalog(cat);
    return true;
  }

  function getProducts(groupId) {
    var prods = getCatalog().products || [];
    if (!groupId || groupId === 'all') return prods;
    return prods.filter(function (p) { return p.groupId === groupId; });
  }

  function getProduct(productId) {
    return getProducts().find(function (p) { return p.id === productId; }) || null;
  }

  function addProduct(prodObj) {
    var cat = getCatalog();
    if (!prodObj.id) prodObj.id = 'prod-' + Date.now();
    cat.products.push(prodObj);
    saveCatalog(cat);
    return prodObj;
  }

  function updateProduct(productId, updateData) {
    var cat = getCatalog();
    var idx = cat.products.findIndex(function (p) { return p.id === productId; });
    if (idx === -1) return false;
    Object.assign(cat.products[idx], updateData);
    saveCatalog(cat);
    return true;
  }

  function deleteProduct(productId) {
    var cat = getCatalog();
    var idx = cat.products.findIndex(function (p) { return p.id === productId; });
    if (idx === -1) return false;
    cat.products.splice(idx, 1);
    saveCatalog(cat);
    return true;
  }

  function addTier(productId, tierObj) {
    var cat = getCatalog();
    var prod = cat.products.find(function (p) { return p.id === productId; });
    if (!prod) return false;
    if (!prod.tiers) prod.tiers = [];
    prod.tiers.push(tierObj);
    saveCatalog(cat);
    return true;
  }

  function updateTier(productId, tierKey, updateData) {
    var cat = getCatalog();
    var prod = cat.products.find(function (p) { return p.id === productId; });
    if (!prod || !prod.tiers) return false;
    var idx = prod.tiers.findIndex(function (t) { return t.key === tierKey; });
    if (idx === -1) return false;
    Object.assign(prod.tiers[idx], updateData);
    saveCatalog(cat);
    return true;
  }

  function deleteTier(productId, tierKey) {
    var cat = getCatalog();
    var prod = cat.products.find(function (p) { return p.id === productId; });
    if (!prod || !prod.tiers) return false;
    var idx = prod.tiers.findIndex(function (t) { return t.key === tierKey; });
    if (idx === -1) return false;
    prod.tiers.splice(idx, 1);
    saveCatalog(cat);
    return true;
  }

  function formatVND(amount) {
    if (!amount) return '0 ₫';
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + ' ₫';
  }

  // ==========================================================================
  // 4. SHOPPING CART API
  // ==========================================================================
  function getCart() {
    if (typeof localStorage === 'undefined') return [];
    try {
      var raw = localStorage.getItem(CART_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch (e) {
      return [];
    }
  }

  function saveCart(cartItems) {
    if (typeof localStorage === 'undefined') return;
    try {
      localStorage.setItem(CART_KEY, JSON.stringify(cartItems));
      if (typeof window !== 'undefined') {
        var evt = new CustomEvent(CART_EVENT, { detail: cartItems });
        window.dispatchEvent(evt);
      }
    } catch (e) {}
  }

  function addToCart(item) {
    var cart = getCart();
    var existingIdx = cart.findIndex(function (i) {
      return i.productId === item.productId &&
             i.tierKey === item.tierKey &&
             i.colorId === item.colorId;
    });

    if (existingIdx !== -1) {
      cart[existingIdx].qty += (item.qty || 1);
    } else {
      cart.push({
        id: 'cart-' + Date.now(),
        productId: item.productId,
        name: item.name || 'T-Flow Pro',
        tierKey: item.tierKey || 'standard',
        tierName: item.tierName || 'Standard Kit',
        price: item.price || 2890000,
        colorId: item.colorId || 'natural-titanium',
        colorName: item.colorName || 'Natural Titanium',
        img: item.img || '../shared/img/feed_portrait_dusk.jpg',
        qty: item.qty || 1
      });
    }
    saveCart(cart);
    return cart;
  }

  function updateCartQty(cartItemId, delta) {
    var cart = getCart();
    var idx = cart.findIndex(function (i) { return i.id === cartItemId; });
    if (idx === -1) return cart;
    cart[idx].qty += delta;
    if (cart[idx].qty <= 0) cart.splice(idx, 1);
    saveCart(cart);
    return cart;
  }

  function removeFromCart(cartItemId) {
    var cart = getCart();
    cart = cart.filter(function (i) { return i.id !== cartItemId; });
    saveCart(cart);
    return cart;
  }

  function clearCart() {
    saveCart([]);
    return [];
  }

  function getCartCount() {
    var cart = getCart();
    return cart.reduce(function (sum, item) { return sum + (item.qty || 1); }, 0);
  }

  function getCartTotal() {
    var cart = getCart();
    return cart.reduce(function (sum, item) { return sum + ((item.price || 0) * (item.qty || 1)); }, 0);
  }

  // ==========================================================================
  // 5. ORDERS API
  // ==========================================================================
  function getOrders() {
    if (typeof localStorage === 'undefined') return [];
    try {
      var raw = localStorage.getItem(ORDERS_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch (e) {
      return [];
    }
  }

  function createOrder(orderData) {
    var orders = getOrders();
    var newOrder = Object.assign({
      id: 'TF-' + Math.floor(100000 + Math.random() * 900000),
      createdAt: new Date().toISOString(),
      status: 'Chờ Xác Nhận'
    }, orderData);
    orders.unshift(newOrder);
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(ORDERS_KEY, JSON.stringify(orders));
    }
    return newOrder;
  }

  function getUserOrders(userId) {
    var orders = getOrders();
    if (!userId) return orders;
    return orders.filter(function (o) { return o.userId === userId; });
  }

  // ==========================================================================
  // 5.5 COOKIE MANAGEMENT & PERSISTENT SESSION ENGINE
  // ==========================================================================
  function setCookie(name, value, days) {
    if (typeof document === 'undefined') return;
    days = days || 30;
    var d = new Date();
    d.setTime(d.getTime() + (days * 24 * 60 * 60 * 1000));
    var expires = "expires=" + d.toUTCString();
    var valStr = (typeof value === 'object') ? JSON.stringify(value) : String(value);
    document.cookie = name + "=" + encodeURIComponent(valStr) + ";" + expires + ";path=/;SameSite=Lax";
  }

  function getCookie(name) {
    if (typeof document === 'undefined') return null;
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
      var c = ca[i];
      while (c.charAt(0) === ' ') c = c.substring(1, c.length);
      if (c.indexOf(nameEQ) === 0) {
        var raw = c.substring(nameEQ.length, c.length);
        try {
          var decoded = decodeURIComponent(raw);
          try {
            return JSON.parse(decoded);
          } catch(e) {
            return decoded;
          }
        } catch(e) {
          return raw;
        }
      }
    }
    return null;
  }

  function deleteCookie(name) {
    if (typeof document === 'undefined') return;
    document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;SameSite=Lax";
  }

  function getCookieConsent() {
    return getCookie('tflow_cookie_consent') || (typeof localStorage !== 'undefined' ? localStorage.getItem('tflow_cookie_consent') : null);
  }

  function setCookieConsent(accepted) {
    var val = accepted ? 'accepted' : 'declined';
    setCookie('tflow_cookie_consent', val, 365);
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('tflow_cookie_consent', val);
    }
    return val;
  }

  // ==========================================================================
  // 5.6 ENTERPRISE SESSION ENGINE (SESSIONSTORAGE + REAL-TIME SESSION TRACKER)
  // ==========================================================================
  var ACTIVE_SESSION_KEY = 'tflow_active_session';
  var ALL_SESSIONS_KEY = 'tflow_user_sessions_history';

  function createSession(user) {
    if (!user || !user.email) return null;
    var sessId = 'sess_' + Date.now().toString(36) + '_' + Math.random().toString(36).substring(2, 7);
    var sessToken = 'stk_' + Math.random().toString(36).substring(2) + Date.now().toString(36);
    var platform = 'Trình duyệt Web';
    if (typeof navigator !== 'undefined') {
      var ua = navigator.userAgent || '';
      if (/iPhone|iPad|iPod/i.test(ua)) platform = 'Apple iOS (Safari)';
      else if (/Macintosh|Mac OS X/i.test(ua)) platform = 'macOS (Safari / Chrome)';
      else if (/Android/i.test(ua)) platform = 'Android Mobile';
      else if (/Windows/i.test(ua)) platform = 'Windows PC';
    }

    var now = new Date();
    var sessionData = {
      sessionId: sessId,
      sessionToken: sessToken,
      userId: user.id || user.email,
      email: user.email,
      name: user.name || user.email,
      role: user.role || 'Thành Viên',
      isAdmin: isUserAdmin(user),
      devicePlatform: platform,
      createdAt: now.toISOString(),
      createdAtFormatted: now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) + ', ' + now.toLocaleDateString('vi-VN'),
      lastActiveAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + (24 * 60 * 60 * 1000)).toISOString(),
      status: 'active',
      isCurrentDevice: true
    };

    // 1. Save to sessionStorage
    if (typeof sessionStorage !== 'undefined') {
      sessionStorage.setItem(ACTIVE_SESSION_KEY, JSON.stringify(sessionData));
    }

    // 2. Set Session Cookie (No expires tag = true session cookie expiring when browser closes)
    if (typeof document !== 'undefined') {
      document.cookie = "tflow_session_id=" + encodeURIComponent(sessId) + ";path=/;SameSite=Lax";
    }

    // 3. Register to persistent sessions list in catalog
    try {
      var allSessionsRaw = localStorage.getItem(ALL_SESSIONS_KEY);
      var allSessions = allSessionsRaw ? JSON.parse(allSessionsRaw) : [];
      allSessions = allSessions.filter(function(s) { return s.sessionId !== sessId; });
      allSessions.unshift(sessionData);
      if (allSessions.length > 5) allSessions = allSessions.slice(0, 5);
      localStorage.setItem(ALL_SESSIONS_KEY, JSON.stringify(allSessions));
    } catch(e) {}

    return sessionData;
  }

  function getActiveSession() {
    var sess = null;
    if (typeof sessionStorage !== 'undefined') {
      try {
        var raw = sessionStorage.getItem(ACTIVE_SESSION_KEY);
        if (raw) sess = JSON.parse(raw);
      } catch(e) {}
    }

    // If no active session in sessionStorage but user is logged in, spawn one automatically!
    if (!sess) {
      var user = getCurrentUser();
      if (user) {
        sess = createSession(user);
      }
    } else {
      // Touch lastActiveAt
      sess.lastActiveAt = new Date().toISOString();
      if (typeof sessionStorage !== 'undefined') {
        sessionStorage.setItem(ACTIVE_SESSION_KEY, JSON.stringify(sess));
      }
    }

    return sess;
  }

  function destroySession() {
    if (typeof sessionStorage !== 'undefined') {
      sessionStorage.removeItem(ACTIVE_SESSION_KEY);
      sessionStorage.removeItem('TFLOW_ADMIN_AUTH');
    }
    if (typeof document !== 'undefined') {
      document.cookie = "tflow_session_id=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;SameSite=Lax";
    }
  }

  function getUserSessionsHistory(userId) {
    if (typeof localStorage === 'undefined') return [];
    try {
      var raw = localStorage.getItem(ALL_SESSIONS_KEY);
      if (!raw) return [];
      var list = JSON.parse(raw);
      var current = getActiveSession();
      return list.map(function(s) {
        s.isCurrentDevice = current && (current.sessionId === s.sessionId);
        return s;
      });
    } catch(e) {
      return [];
    }
  }

  function terminateOtherSessions() {
    var current = getActiveSession();
    if (typeof localStorage !== 'undefined' && current) {
      localStorage.setItem(ALL_SESSIONS_KEY, JSON.stringify([current]));
    }
    return true;
  }

  // ==========================================================================
  // 6. USER AUTHENTICATION & ACCESS CONTROL (DUAL MODE: STANDARD + GOOGLE)
  // ==========================================================================
  function isUserAdmin(user) {
    if (!user || !user.email) return false;
    var em = user.email.trim().toLowerCase();
    return ADMIN_GMAILS.indexOf(em) !== -1;
  }

  function getUsers() {
    return getCatalog().users || [];
  }

  function getCurrentUser() {
    var user = null;
    // 1. Check localStorage first for rich profiles (including Base64 photo avatars)
    if (typeof localStorage !== 'undefined') {
      try {
        var raw = localStorage.getItem(CURRENT_USER_KEY);
        if (raw) user = JSON.parse(raw);
      } catch (e) {}
    }
    // 2. Fallback to cookie
    if (!user) {
      try {
        user = getCookie('tflow_user_session') || getCookie('tflow_user');
      } catch(e) {}
    }

    if (user) {
      try {
        var cookieUser = Object.assign({}, user);
        if (cookieUser.avatar && cookieUser.avatar.length > 150) {
          cookieUser.avatar = 'photo_avatar';
        }
        setCookie('tflow_user_session', cookieUser, 30);
        if (typeof localStorage !== 'undefined') {
          localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user));
          setCookie('tflow_user_session', user, 30);
          setCookie('tflow_auth_token', 'token_' + Date.now(), 30);
          if (typeof sessionStorage !== 'undefined' && !sessionStorage.getItem(ACTIVE_SESSION_KEY)) {
            createSession(user);
          }
        }
      } catch(e) {}
    }

    return user;
  }

  // 6.1 Standard Email & Password Login
  function loginUser(emailOrPhone, password) {
    if (!emailOrPhone) {
      return { success: false, message: 'Vui lòng nhập Email hoặc Số điện thoại.' };
    }
    var cleanInput = emailOrPhone.trim().toLowerCase();
    var cleanPhone = emailOrPhone.replace(/\s+/g, '');
    var users = getUsers();

    var found = users.find(function (u) {
      return (u.email && u.email.toLowerCase() === cleanInput) ||
             (u.phone && u.phone.replace(/\s+/g, '') === cleanPhone);
    });

    if (!found) {
      return { success: false, message: 'Tài khoản không tồn tại. Vui lòng đăng ký tài khoản mới.' };
    }

    if (found.password && password && found.password !== password) {
      return { success: false, message: 'Mật khẩu không chính xác. Vui lòng thử lại.' };
    }

    var isAdmin = isUserAdmin(found);
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(found));
      setCookie('tflow_user_session', found, 30);
      setCookie('tflow_auth_token', 'token_' + Date.now(), 30);
      createSession(found);
    }
    if (typeof sessionStorage !== 'undefined') {
      if (isAdmin) {
        sessionStorage.setItem('TFLOW_ADMIN_AUTH', 'true');
      } else {
        sessionStorage.removeItem('TFLOW_ADMIN_AUTH');
      }
    }

    if (typeof window !== 'undefined') {
      var evt = new CustomEvent(USER_EVENT, { detail: found });
      window.dispatchEvent(evt);
    }

    return { success: true, user: found, isAdmin: isAdmin };
  }

  // 6.2 Standard User Registration
  function registerUser(userData) {
    if (!userData || !userData.email) {
      return { success: false, message: 'Vui lòng cung cấp địa chỉ Email.' };
    }
    var cat = getCatalog();
    var cleanEmail = userData.email.trim().toLowerCase();

    var exists = (cat.users || []).some(function (u) {
      return u.email && u.email.toLowerCase() === cleanEmail;
    });

    if (exists) {
      return { success: false, message: 'Email này đã được sử dụng. Vui lòng đăng nhập.' };
    }

    var isAdmin = isUserAdmin({ email: cleanEmail });
    var newUser = {
      id: 'user-' + Date.now(),
      name: userData.name || cleanEmail.split('@')[0],
      email: cleanEmail,
      password: userData.password || '123456',
      phone: userData.phone || '',
      role: isAdmin ? 'Master Administrator & Founder' : 'Khách Hàng Thành Viên',
      company: userData.company || 'Công ty TNHH Công nghệ T-Flow Việt Nam',
      tierBadge: isAdmin ? 'Master Admin' : 'Thành Viên Mới',
      registeredDevice: userData.serial ? 'T-Flow Pro' : 'T-Flow Pro (Chưa kích hoạt)',
      serial: userData.serial || '',
      battery: 100,
      firmware: 'FW-TF-G31-v1.2.0 (Mới nhất)',
      status: 'Đang Hoạt Động',
      modules: isAdmin ? [true, true, true, true, true, true, true] : [true, false, false, false, false, false, false]
    };

    cat.users.push(newUser);
    saveCatalog(cat);

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(newUser));
      setCookie('tflow_user_session', newUser, 30);
      setCookie('tflow_auth_token', 'token_' + Date.now(), 30);
      createSession(newUser);
    }
    if (typeof sessionStorage !== 'undefined') {
      if (isAdmin) {
        sessionStorage.setItem('TFLOW_ADMIN_AUTH', 'true');
      } else {
        sessionStorage.removeItem('TFLOW_ADMIN_AUTH');
      }
    }

    if (typeof window !== 'undefined') {
      var evt = new CustomEvent(USER_EVENT, { detail: newUser });
      window.dispatchEvent(evt);
    }

    return { success: true, user: newUser, isAdmin: isAdmin };
  }

  // 6.3 Google Account Sign-In (Cơ chế đăng nhập bổ sung bằng Google)
  function loginWithGmail(email, displayName) {
    if (!email) return { success: false, message: 'Vui lòng cung cấp địa chỉ Email Google (Gmail).' };
    var cleanEmail = email.trim().toLowerCase();
    var isAdmin = isUserAdmin({ email: cleanEmail });

    var cat = getCatalog();
    var user = (cat.users || []).find(function (u) {
      return u.email && u.email.toLowerCase() === cleanEmail;
    });

    if (!user) {
      user = {
        id: cleanEmail.replace(/[^a-zA-Z0-9]/g, '-'),
        name: displayName || (isAdmin ? 'Thuy Nguyen' : cleanEmail.split('@')[0]),
        email: cleanEmail,
        password: '',
        phone: isAdmin ? '0908 888 888' : '',
        role: isAdmin ? 'Master Administrator & Founder' : 'Khách Hàng Thành Viên',
        company: 'Công ty TNHH Công nghệ T-Flow Việt Nam',
        tierBadge: isAdmin ? 'Master Admin' : 'Thành Viên Mới',
        registeredDevice: 'T-Flow Pro (TF-G31-PRO)',
        serial: isAdmin ? 'HQYVYFYFR4' : '',
        battery: 98,
        firmware: 'FW-TF-G31-v1.2.0 (Mới nhất)',
        status: 'Đang Hoạt Động',
        modules: isAdmin ? [true, true, true, true, true, true, true] : [true, false, false, false, false, false, false]
      };
      cat.users.push(user);
      saveCatalog(cat);
    } else if (isAdmin) {
      user.modules = [true, true, true, true, true, true, true];
      user.role = 'Master Administrator & Founder';
      user.tierBadge = 'Master Admin';
      saveCatalog(cat);
    }

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user));
      setCookie('tflow_user_session', user, 30);
      setCookie('tflow_auth_token', 'token_' + Date.now(), 30);
      createSession(user);
    }
    if (typeof sessionStorage !== 'undefined') {
      if (isAdmin) {
        sessionStorage.setItem('TFLOW_ADMIN_AUTH', 'true');
      } else {
        sessionStorage.removeItem('TFLOW_ADMIN_AUTH');
      }
    }

    if (typeof window !== 'undefined') {
      var evt = new CustomEvent(USER_EVENT, { detail: user });
      window.dispatchEvent(evt);
    }

    return { success: true, user: user, isAdmin: isAdmin };
  }

  function logoutUser() {
    destroySession();
    deleteCookie('tflow_user_session');
    deleteCookie('tflow_user');
    deleteCookie('tflow_auth_token');
    if (typeof localStorage !== 'undefined') {
      localStorage.removeItem(CURRENT_USER_KEY);
    }
    if (typeof sessionStorage !== 'undefined') {
      sessionStorage.removeItem('TFLOW_ADMIN_AUTH');
    }
    if (typeof window !== 'undefined') {
      var evt = new CustomEvent(USER_EVENT, { detail: null });
      window.dispatchEvent(evt);
    }
  }

  function updateUserProfile(userId, profileData) {
    if (!profileData) return false;
    var cat = getCatalog();
    if (!cat.users) cat.users = [];
    var cur = getCurrentUser();

    var targetId = userId || (cur ? cur.id : null);
    var targetEmail = (cur && cur.email ? cur.email.toLowerCase() : null) || (profileData && profileData.email ? profileData.email.toLowerCase() : null);

    var idx = cat.users.findIndex(function (u) {
      return (targetId && u.id === targetId) ||
             (targetEmail && u.email && u.email.toLowerCase() === targetEmail);
    });

    if (idx !== -1) {
      Object.assign(cat.users[idx], profileData);
      saveCatalog(cat);
    } else if (cur) {
      Object.assign(cur, profileData);
      cat.users.push(cur);
      saveCatalog(cat);
    }

    if (cur) {
      Object.assign(cur, profileData);
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(cur));
      }
      var cookieCur = Object.assign({}, cur);
      if (cookieCur.avatar && cookieCur.avatar.length > 150) {
        cookieCur.avatar = 'photo_avatar';
      }
      setCookie('tflow_user_session', cookieCur, 30);
      createSession(cur);
      if (typeof window !== 'undefined') {
        var evt = new CustomEvent(USER_EVENT, { detail: cur });
        window.dispatchEvent(evt);
      }
    }
    return true;
  }

  function updateUserModules(userId, moduleIndex, isEnabled) {
    var cat = getCatalog();
    var idx = cat.users.findIndex(function (u) { return u.id === userId; });
    if (idx === -1) return false;
    if (!cat.users[idx].modules) {
      cat.users[idx].modules = [false, false, false, false, false, false, false];
    }
    cat.users[idx].modules[moduleIndex] = isEnabled;
    saveCatalog(cat);

    var cur = getCurrentUser();
    if (cur && cur.id === userId) {
      cur.modules[moduleIndex] = isEnabled;
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(cur));
      }
      if (typeof window !== 'undefined') {
        var evt = new CustomEvent(USER_EVENT, { detail: cur });
        window.dispatchEvent(evt);
      }
    }
    return true;
  }

  // ==========================================================================
  // 7. USER REVIEWS API
  // ==========================================================================
  function getReviews() {
    if (typeof localStorage === 'undefined') return DEFAULT_REVIEWS;
    try {
      var raw = localStorage.getItem(REVIEWS_KEY);
      if (!raw) {
        localStorage.setItem(REVIEWS_KEY, JSON.stringify(DEFAULT_REVIEWS));
        return JSON.parse(JSON.stringify(DEFAULT_REVIEWS));
      }
      var parsed = JSON.parse(raw);
      if (!Array.isArray(parsed) || parsed.length === 0) {
        localStorage.setItem(REVIEWS_KEY, JSON.stringify(DEFAULT_REVIEWS));
        return JSON.parse(JSON.stringify(DEFAULT_REVIEWS));
      }
      return parsed;
    } catch (e) {
      return DEFAULT_REVIEWS;
    }
  }

  function addReview(reviewData) {
    if (!reviewData) return { success: false, message: 'Dữ liệu đánh giá không hợp lệ.' };
    var reviews = getReviews();
    var now = new Date();
    var dateStr = ('0' + now.getDate()).slice(-2) + '/' + ('0' + (now.getMonth() + 1)).slice(-2) + '/' + now.getFullYear();

    var authorName = (reviewData.author || '').trim() || 'Người Dùng T-Flow';
    var newRev = {
      id: 'rev-' + Date.now(),
      author: authorName,
      avatar: reviewData.avatar || (authorName.charAt(0).toUpperCase() || 'T'),
      role: reviewData.role || 'Khách Hàng Đã Mua T-Flow Pro',
      email: (reviewData.email || '').trim().toLowerCase(),
      package: reviewData.package || 'T-Flow Pro - Creator Kit',
      rating: Math.max(1, Math.min(5, parseInt(reviewData.rating) || 5)),
      date: dateStr,
      title: (reviewData.title || '').trim() || 'Trải nghiệm T-Flow Pro tuyệt vời',
      comment: (reviewData.comment || '').trim(),
      tags: Array.isArray(reviewData.tags) && reviewData.tags.length > 0 ? reviewData.tags : ['Chống rung FOC', 'Hài lòng'],
      verified: true,
      isRecent: true
    };

    reviews.unshift(newRev);

    if (typeof localStorage !== 'undefined') {
      try {
        localStorage.setItem(REVIEWS_KEY, JSON.stringify(reviews));
      } catch (e) {}
    }

    if (typeof window !== 'undefined') {
      try {
        var evt = new CustomEvent(REVIEWS_EVENT, { detail: reviews });
        window.dispatchEvent(evt);
      } catch (e) {}
    }
    return { success: true, review: newRev, reviews: reviews };
  }

  function deleteReview(reviewId) {
    var reviews = getReviews();
    var filtered = reviews.filter(function (r) { return r.id !== reviewId; });
    if (typeof localStorage !== 'undefined') {
      try {
        localStorage.setItem(REVIEWS_KEY, JSON.stringify(filtered));
      } catch (e) {}
    }
    if (typeof window !== 'undefined') {
      try {
        var evt = new CustomEvent(REVIEWS_EVENT, { detail: filtered });
        window.dispatchEvent(evt);
      } catch (e) {}
    }
    return { success: true, reviews: filtered };
  }

  // ==========================================================================
  // 8. CSV EXPORT & IMPORT API
  // ==========================================================================
  function exportProductsCSV() {
    var cat = getCatalog();
    var rows = [
      ["Nhom_Hang", "Ma_San_Pham", "Ten_San_Pham", "Slogan", "Phan_Cap", "Gia_Ban", "Gia_Goc", "Qua_Tang", "So_Don_Ban", "Trang_Thai"]
    ];

    cat.products.forEach(function (p) {
      var group = getGroup(p.groupId);
      var groupName = group ? group.name : p.groupId;
      if (p.tiers && p.tiers.length > 0) {
        p.tiers.forEach(function (t) {
          rows.push([
            groupName,
            p.sku || p.id,
            p.name,
            p.tagline || '',
            t.name,
            t.price,
            t.origPrice || t.price,
            t.tag || '',
            p.totalOrders || 0,
            p.status || 'Đang Mở Bán'
          ]);
        });
      } else {
        rows.push([
          groupName,
          p.sku || p.id,
          p.name,
          p.tagline || '',
          'Tiêu Chuẩn',
          p.price || 0,
          p.origPrice || 0,
          '',
          p.totalOrders || 0,
          p.status || 'Đang Mở Bán'
        ]);
      }
    });

    var csvContent = "\uFEFF" + rows.map(function (e) {
      return e.map(function (val) {
        var str = (val === null || val === undefined) ? '' : val.toString();
        if (str.indexOf(',') !== -1 || str.indexOf('"') !== -1 || str.indexOf('\n') !== -1) {
          return '"' + str.replace(/"/g, '""') + '"';
        }
        return str;
      }).join(",");
    }).join("\n");

    var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    var link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.setAttribute("download", "TFlow_Products_Export_" + Date.now() + ".csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  function importProductsCSV(csvText) {
    if (!csvText) return { success: false, message: 'Dữ liệu CSV trống.' };
    return { success: true, count: 1, message: 'Đã xử lý danh mục sản phẩm T-Flow.' };
  }

  function exportUsersCSV() {
    var users = getUsers();
    var rows = [
      ["ID", "Ho_Va_Ten", "Email", "So_Dien_Thoai", "Cap_Bac", "Thiet_Bi", "Trang_Thai"]
    ];

    users.forEach(function (u) {
      rows.push([
        u.id,
        u.name,
        u.email,
        u.phone || '',
        u.tierBadge || u.role,
        u.registeredDevice || 'T-Flow Pro',
        u.status || 'Đang Hoạt Động'
      ]);
    });

    var csvContent = "\uFEFF" + rows.map(function (e) {
      return e.map(function (val) {
        var str = (val === null || val === undefined) ? '' : val.toString();
        if (str.indexOf(',') !== -1 || str.indexOf('"') !== -1 || str.indexOf('\n') !== -1) {
          return '"' + str.replace(/"/g, '""') + '"';
        }
        return str;
      }).join(",");
    }).join("\n");

    var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    var link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.setAttribute("download", "TFlow_Users_Export_" + Date.now() + ".csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  // ==========================================================================
  // 9. PUBLIC API EXPORTS
  // ==========================================================================

  // =========================================================================
  // SECTION 10: T-FLOW REAL-AI DUAL BRAIN (WEB SALES & APP COPILOT) ENGINE
  // =========================================================================
  var AI_CONVERSATIONS_KEY = 'tflow_ai_conversations_v2';
  var AI_PENDING_KEY = 'tflow_ai_pending_questions_v2';
  var AI_KB_KEY = 'tflow_ai_knowledge_base_v2';
  var AI_EVENT = 'tflow_ai_updated_event';

  var DEFAULT_AI_KNOWLEDGE_BASE = [
    // =========================================================================
    // --- 1. CHUYÊN MỤC 1: TƯ VẤN BÁN HÀNG & CHÍNH SÁCH (SALES CONSULTING) ---
    // =========================================================================
    {
      id: 'kb_sales_packages_pricing',
      target: 'sales',
      topic: 'Bảng giá và 4 gói cấu hình T-Flow Pro',
      keywords: ['sản phẩm', 'sản phẩm nào', 'có những', 'bán gì', 'danh mục', 'giá', 'bao nhiêu', 'tiền', 'gói', 'bản', 'phiên bản', 'combo', 'mua', 'khuyến mãi', 'standard', 'creator', 'cinematic', 'master', 'chi phí', 'báo giá'],
      answer: "T-Flow Pro hiện đang mở bán chính thức với **4 gói cấu hình** chuyên nghiệp:\n\n" +
              "• **Gói Standard (2.490.000đ)**: Thân gimbal T-Flow Pro Pure FOC, tripod mini kim loại, ngàm nam châm MagSafe N52 45N, cáp sạc USB-C và túi nhung cao cấp.\n" +
              "• **Gói Creator Kit (3.190.000đ) - Bán chạy nhất ⭐**: Trọn bộ Standard + Đèn Fill Light MagSafe RGB 360 màu (CRI 96+) + Túi đeo chéo EVA chống sốc cao cấp.\n" +
              "• **Gói Cinematic Pro (3.990.000đ)**: Trọn bộ Creator + Micro không dây kép 2.4GHz chống ồn AI + Bộ tạ đối trọng Pro cho iPhone Pro Max.\n" +
              "• **Gói Master Edition (5.490.000đ)**: Toàn bộ hệ sinh thái phụ kiện cao cấp + Vali nhôm hàng không nguyên khối + Khóa học MasterClass quay dựng trọn đời.\n\n" +
              "Anh/chị có muốn em hỗ trợ thêm gói nào vào giỏ hàng ngay bây giờ không ạ?",
      actions: [
        { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' },
        { label: '⭐ Thêm Gói Creator Kit', action: 'addCreatorKit' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_sales_magsafe_force',
      target: 'sales',
      topic: 'Ngàm nam châm MagSafe N52 và độ an toàn',
      keywords: ['magsafe', 'nam châm', 'rơi', 'hít', 'chắc', 'lực', 'n52', 'an toàn', 'giữ', 'rơi vỡ', 'chống rơi', 'khóa', 'lực hút'],
      answer: "T-Flow Pro trang bị hệ thống **MagSafe Ultra-Hold thế hệ mới** sử dụng 32 lõi nam châm vĩnh cửu Neodymium N52 với lực hút định danh **45N (chịu tải 2.8kg - 4.5kg)**.\n\n" +
              "Điểm đột phá là cơ chế **Khóa cơ học kép Snap-Lock**: khi điện thoại hít vào, chốt khóa an toàn tự động gài chặt. Dù anh/chị chạy bộ nước rút, trượt ván hay vận động mạnh, điện thoại tuyệt đối không bao giờ bị tuột hay rơi rớt. Đi kèm máy có thêm vòng từ tính trợ lực dán lưng cho điện thoại Android.",
      actions: [
        { label: '⚡ Xem Chi Tiết Ngàm MagSafe', view: 'detail' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_sales_motor_foc',
      target: 'sales',
      topic: 'Động cơ Pure FOC 20kHz và chống rung điện ảnh',
      keywords: ['foc', 'động cơ', 'motor', '20khz', 'chống rung', 'rung', 'ồn', 'tiếng ồn', 'tần số', 'mô men', 'lag', 'trễ', 'mượt'],
      answer: "T-Flow Pro ứng dụng **công nghệ điều khiển vector Pure FOC 20kHz** tiên tiến nhất ngành:\n\n" +
              "• **Tần số siêu âm 20kHz**: Vượt qua ngưỡng nghe của tai người, động cơ vận hành hoàn toàn tĩnh âm 0dB, giúp micro thu âm không bị lọt tiếng rít motor.\n" +
              "• **Tốc độ phản hồi < 1ms**: Vi xử lý ARM Cortex-M4 kép tính toán 20.000 lần mỗi giây, triệt tiêu tức thì 99.8% rung lắc.\n" +
              "• **Độ chính xác 0.005°**: Trục chuyển động mượt như ray trượt dolly điện ảnh, không giật khấc.",
      actions: [
        { label: '📐 Xem Bản Vẽ Kỹ Thuật Động Cơ', view: 'detail' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_sales_compatibility',
      target: 'sales',
      topic: 'Độ tương thích thiết bị và trọng tải smartphone',
      keywords: ['tương thích', 'dùng được', 'iphone', 'hỗ trợ', 'android', 'samsung', 'nặng', 'tải trọng', 'máy nào', '15 pro max', '16 pro max', 'điện thoại'],
      answer: "T-Flow Pro tương thích hoàn hảo với:\n\n" +
              "• **Toàn bộ dải iPhone**: Từ iPhone 12 series đến iPhone 16 Pro Max (hít nam châm MagSafe trực tiếp không cần tháo ốp).\n" +
              "• **Điện thoại Android**: Samsung Galaxy S24 Ultra, Xiaomi, Vivo, Oppo... (thông qua vòng từ tính siêu mỏng tặng kèm).\n" +
              "• **Tải trọng tối đa 420g**: Thoải mái gắn thêm ống kính rời (Anamorphic, Tele 3x), kính lọc ND và micro thu âm bên ngoài mà không lo quá tải motor.",
      actions: [
        { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_sales_battery_powerbank',
      target: 'sales',
      topic: 'Thời lượng pin và sạc dự phòng không dây',
      keywords: ['pin', 'dung lượng', 'thời gian', 'dùng được bao lâu', 'sạc', 'mah', 'sạc ngược', 'powerbank', 'sạc dự phòng', '18h', '24h', 'pin bao lâu'],
      answer: "T-Flow Pro sở hữu hệ thống pin kép hiệu năng cao:\n\n" +
              "• **Thời lượng 18 - 24 giờ liên tục**: Đáp ứng trọn vẹn cả ngày dài quay phim, du lịch hoặc phát livestream sự kiện mà không cần cắm sạc.\n" +
              "• **Sạc ngược không dây MagSafe 15W**: Tự động sạc pin không dây chuẩn Qi trực tiếp cho iPhone trong lúc đang gắn trên ngàm gimbal.\n" +
              "• **Cổng ra USB-C PD 20W**: Hỗ trợ sạc nhanh có dây cho phụ kiện đèn hoặc điện thoại thứ hai.",
      actions: [
        { label: '⚡ Xem Chi Tiết Kỹ Thuật', view: 'detail' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_sales_warranty_policy',
      target: 'sales',
      topic: 'Chính sách bảo hành và cam kết đổi trả',
      keywords: ['bảo hành', 'đổi trả', 'hỏng', 'lỗi', '1 đổi 1', 'chính sách', 'sửa', 'yên tâm', 'chính hãng', '30 ngày', '12 tháng'],
      answer: "Chính sách hậu mãi của T-Flow Pro dẫn đầu thị trường:\n\n" +
              "• **Bảo hành 1 đổi 1 chính hãng 12 tháng**: Nếu phát sinh bất kỳ lỗi kỹ thuật nào từ nhà sản xuất, đổi mới 100% thiết bị nguyên hộp.\n" +
              "• **Dùng thử 30 ngày hoàn tiền 100%**: Khách hàng được trải nghiệm thực tế trong 30 ngày, nếu không ưng ý có thể đổi trả hoàn tiền không cần lý do.\n" +
              "• **Hỗ trợ kỹ thuật 24/7**: Đội ngũ kỹ sư R&D do Master Admin Thủy Nguyễn dẫn dắt hỗ trợ căn chỉnh và hướng dẫn sử dụng trọn đời.",
      actions: [
        { label: '⭐ Xem Đánh Giá Khách Hàng', view: 'reviews' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_sales_shipping_delivery',
      target: 'sales',
      topic: 'Giao hàng và vận chuyển hỏa tốc toàn quốc',
      keywords: ['ship', 'giao hàng', 'vận chuyển', 'bao lâu', 'ở đâu', 'phí ship', 'hỏa tốc', 'nhận hàng', 'kiểm tra', 'freeship', 'cod'],
      answer: "T-Flow áp dụng chính sách **Miễn phí vận chuyển toàn quốc 100% (Freeship)**:\n\n" +
              "• **Hà Nội & TP. Hồ Chí Minh**: Giao hỏa tốc nhận hàng trong vòng **2 giờ**.\n" +
              "• **Các tỉnh thành khác**: Giao nhanh bưu điện trong **24 - 48 giờ**.\n" +
              "• **Đồng kiểm khi nhận**: Quý khách được mở hộp kiểm tra thiết bị, bật nguồn test động cơ trước khi thanh toán tiền mặt (COD) hoặc chuyển khoản.",
      actions: [
        { label: '📦 Đặt Hàng Ngay', view: 'catalog' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },

    // =========================================================================
    // --- 2. CHUYÊN MỤC 2: KỸ THUẬT QUAY CHỤP & EDIT (CREATIVE & POST-PROD) ---
    // =========================================================================
    {
      id: 'kb_creative_sunset_golden_hour',
      target: 'creative',
      topic: 'Kỹ thuật quay cảnh hoàng hôn trên biển / ngược sáng',
      keywords: ['hoàng hôn', 'bãi biển', 'mặt trời', 'ngược sáng', 'biển', 'golden hour', 'chiều tà', 'bình minh', 'cháy sáng', 'quay hoàng hôn'],
      answer: "🌅 **Kỹ Thuật Đạo Diễn - Cảnh Hoàng Hôn & Biển Chiều:**\n" +
              "Khi quay ngược sáng mặt trời lặn, ánh sáng rất gắt dễ làm cháy vùng mây trời hoặc làm tối đen chủ thể. Chúng ta cần giảm nhẹ bù sáng EV để bảo vệ highlight của mặt trời, khóa ISO ở mức thấp nhất để khử nhiễu dải màu cam vàng, và kích hoạt màu phim Apple Log để cứu toàn bộ dynamic range.\n\n" +
              "📋 **Bộ thông số tối ưu đề xuất:**\n" +
              "• **Chế độ quay:** PRO CINEMA (4K 60fps mượt mà)\n" +
              "• **Tốc độ màn trập (Shutter):** 1/120s (chuẩn 180° cinematic)\n" +
              "• **ISO:** 100 (độ trong tối đa, triệt tiêu hạt noise)\n" +
              "• **Bù sáng (EV):** -0.3 EV (bảo vệ bầu trời hoàng hôn rực rỡ)\n" +
              "• **Màu sắc & 3D LUT:** Apple Log + 'Sunset Golden Hour Film LUT'\n" +
              "• **Chế độ Gimbal:** FPV 3-Trục (mềm mại, bám theo hướng lia tự nhiên)",
      cameraPreset: {
        mode: 'PRO CINEMA',
        fps: 60,
        resolution: '4K',
        iso: 100,
        shutter: '1/120s',
        ev: '-0.3',
        wb: '5500K Golden',
        lut: 'Sunset Golden Hour Film',
        gimbalMode: 'FPV 3-Trục',
        followSpeed: 'Mượt mà (Smooth 30%)',
        summary: 'PRO CINEMA 4K/60fps • ISO 100 • EV -0.3 • Sunset LUT • FPV Mode'
      },
      suggestAction: true,
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_creative_action_sport_fast',
      target: 'creative',
      topic: 'Quay thể thao, xe chạy, hành động chuyển động nhanh',
      keywords: ['thể thao', 'xe chạy', 'tốc độ', 'chạy bộ', 'xe máy', 'ô tô', 'nhanh', 'hành động', 'nhòe', 'slow motion', 'bắt dính'],
      answer: "🏎️ **Kỹ Thuật Đạo Diễn - Hành Động Tốc Độ Cao:**\n" +
              "Với các cảnh xe chạy hoặc thể thao tốc độ cao, hiện tượng nhòe nét (motion blur) và rung giật là kẻ thù số một. Chúng ta cần đẩy tốc độ khung hình lên 120fps để có thể làm chậm (slow-motion) khi edit, đồng thời tăng tốc độ phản hồi của động cơ FOC lên chế độ Sport Fast Follow để bám dính chủ thể không bị văng khung hình.\n\n" +
              "📋 **Bộ thông số tối ưu đề xuất:**\n" +
              "• **Chế độ quay:** SLOW-MO (4K 120fps siêu nét)\n" +
              "• **Tốc độ màn trập (Shutter):** 1/240s (đóng băng chuyển động)\n" +
              "• **ISO:** 200\n" +
              "• **Bù sáng (EV):** 0.0 EV\n" +
              "• **Màu sắc & 3D LUT:** Action Sport High Contrast LUT\n" +
              "• **Chế độ Gimbal:** FPV 3-Trục (Phản hồi nhanh 85%)",
      cameraPreset: {
        mode: 'SLOW-MO',
        fps: 120,
        resolution: '4K',
        iso: 200,
        shutter: '1/240s',
        ev: '0.0',
        wb: 'Auto 5200K',
        lut: 'Action Sport High Contrast',
        gimbalMode: 'FPV 3-Trục',
        followSpeed: 'Thể thao (Fast 85%)',
        summary: 'SLOW-MO 4K/120fps • Shutter 1/240s • Fast Follow 85%'
      },
      suggestAction: true,
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_creative_portrait_cinematic',
      target: 'creative',
      topic: 'Quay chân dung, phỏng vấn, xóa phông và tôn da',
      keywords: ['chân dung', 'phỏng vấn', 'xóa phông', 'mịn da', 'bokeh', 'người', 'mẫu', 'da đẹp', 'tự nhiên', 'nói chuyện', 'quay mẫu'],
      answer: "🎬 **Kỹ Thuật Đạo Diễn - Chân Dung Cinematic:**\n" +
              "Để tạo thước phim chân dung có chiều sâu điện ảnh, máy ảnh cần khóa tốc độ 24fps chuẩn Hollywood, sử dụng camera tele 3x/5x để nén hậu cảnh xóa phông nhẹ nhàng, và sử dụng LUT da tự nhiên tôn vinh sắc tố da châu Á mà không bị bết màu.\n\n" +
              "📋 **Bộ thông số tối ưu đề xuất:**\n" +
              "• **Chế độ quay:** CHÂN DUNG (4K 24fps Cinematic)\n" +
              "• **Tốc độ màn trập (Shutter):** 1/48s (quy tắc 180° chuyển động chuẩn)\n" +
              "• **ISO:** 50 (độ mịn hạt cực đại)\n" +
              "• **Bù sáng (EV):** +0.3 EV (làm sáng bừng khuôn mặt)\n" +
              "• **Màu sắc & 3D LUT:** Natural Skin Tone Film LUT\n" +
              "• **Chế độ Gimbal:** PF (Pan Follow mượt mà, lia nhẹ nhàng quanh mẫu)",
      cameraPreset: {
        mode: 'CHÂN DUNG',
        fps: 24,
        resolution: '4K',
        iso: 50,
        shutter: '1/48s',
        ev: '+0.3',
        wb: '5200K Warm Skin',
        lut: 'Natural Skin Tone Film',
        gimbalMode: 'PF (Pan Follow)',
        followSpeed: 'Chậm điện ảnh (Slow 15%)',
        summary: 'CHÂN DUNG 4K/24fps • Shutter 1/48s • ISO 50 • Skin LUT'
      },
      suggestAction: true,
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_creative_night_lowlight',
      target: 'creative',
      topic: 'Quay cảnh đêm, thiếu sáng, phố thị ánh đèn neon',
      keywords: ['đêm', 'tối', 'thiếu sáng', 'phố đêm', 'neon', 'lung linh', 'nhiễu', 'hạt', 'mờ', 'chụp đêm', 'quay tối'],
      answer: "🌃 **Kỹ Thuật Đạo Diễn - Cảnh Đêm & Thiếu Sáng:**\n" +
              "Trong môi trường ánh sáng yếu, việc đẩy ISO quá cao sẽ gây nhiễu hạt phá hỏng khung hình. Kỹ thuật ở đây là hạ FPS về 24fps để cảm biến có thời gian hấp thụ ánh sáng lâu nhất (1/48s), kết hợp thuật toán FOC khử rung tuyệt đối để không bị nhòe hình.\n\n" +
              "📋 **Bộ thông số tối ưu đề xuất:**\n" +
              "• **Chế độ quay:** PRO CINEMA (4K 24fps Night Mode)\n" +
              "• **Tốc độ màn trập (Shutter):** 1/48s\n" +
              "• **ISO:** 400 (cân bằng hoàn hảo giữa sáng và độ trong)\n" +
              "• **Bù sáng (EV):** -0.7 EV (bảo vệ các bóng đèn neon không bị cháy trắng)\n" +
              "• **Màu sắc & 3D LUT:** Cyberpunk Teal & Orange Neon LUT\n" +
              "• **Chế độ Gimbal:** LOCK Khóa (giữ khung hình vững chãi như đặt tripod)",
      cameraPreset: {
        mode: 'PRO CINEMA',
        fps: 24,
        resolution: '4K',
        iso: 400,
        shutter: '1/48s',
        ev: '-0.7',
        wb: '4500K Neon Teal',
        lut: 'Cyberpunk Teal & Orange Neon',
        gimbalMode: 'LOCK Khóa',
        followSpeed: 'Ổn định ban đêm (Lock 100%)',
        summary: 'PRO CINEMA 4K/24fps • ISO 400 • EV -0.7 • Lock Axis'
      },
      suggestAction: true,
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_creative_inception_vortex',
      target: 'creative',
      topic: 'Quay hiệu ứng 360° Inception Roll lốc xoáy vũ trụ',
      keywords: ['inception', '360', 'xoay', 'lốc xoáy', 'nghiêng', 'vòng tròn', 'vũ trụ', 'roll', 'xoay vòng'],
      answer: "🌀 **Kỹ Thuật Đạo Diễn - Hiệu Ứng Inception 360° Roll:**\n" +
              "Đây là cú máy đặc trưng của các đạo diễn Hollywood! Gimbal sẽ tự động quay tròn trục Pan 360° vô cực trong khi camera tiến về phía trước, tạo cảm giác thế giới xung quanh đang xoay tròn mê hoặc.\n\n" +
              "📋 **Bộ thông số tối ưu đề xuất:**\n" +
              "• **Chế độ quay:** PRO CINEMA (4K 60fps mượt mà)\n" +
              "• **Tốc độ màn trập (Shutter):** 1/120s\n" +
              "• **ISO:** 100\n" +
              "• **Chế độ Gimbal:** 360° Inception (Tự động kích hoạt mô-men xoắn xoay vô cực)\n" +
              "• **Mẹo cầm máy:** Cầm gimbal nằm ngang kiểu đèn pin (Flashlight Mode) hướng thẳng về phía mục tiêu và bước đi đều chân.",
      cameraPreset: {
        mode: 'PRO CINEMA',
        fps: 60,
        resolution: '4K',
        iso: 100,
        shutter: '1/120s',
        ev: '0.0',
        wb: 'Auto',
        lut: 'Hollywood Blockbuster Film',
        gimbalMode: '360° Inception',
        followSpeed: 'Tự động xoay 360°',
        summary: 'PRO CINEMA 4K/60 • Chế độ Gimbal: 360° Inception Roll'
      },
      suggestAction: true,
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_creative_running_walk_smooth',
      target: 'creative',
      topic: 'Chạy bộ, leo bậc thang, triệt tiêu rung giật bước chân',
      keywords: ['chạy', 'bước đi', 'bậc thang', 'đi bộ', 'leo núi', 'giật bước chân', 'z-axis', 'rung chân trời', 'chống rung bước chân'],
      answer: "🏃 **Kỹ Thuật Đạo Diễn - Triệt Tiêu Rung Bước Chân:**\n" +
              "Khi đi bộ hoặc chạy bộ, trọng lượng cơ thể dồn lên từng bước chân tạo ra dao động trục Z (Z-axis bobbing). Chúng ta kích hoạt thuật toán giảm chấn bước đi kết hợp tính năng Khóa Chân Trời (Horizon Lock) để giữ đường chân trời luôn thẳng tuyệt đối dù thân người có nhấp nhô.\n\n" +
              "📋 **Bộ thông số tối ưu đề xuất:**\n" +
              "• **Chế độ quay:** VIDEO 4K/60 (ổn định khung hình cao)\n" +
              "• **ISO:** 100\n" +
              "• **Chế độ Gimbal:** LOCK Khóa (Triệt tiêu rung Z-axis & Khóa chân trời)\n" +
              "• **Mẹo di chuyển:** Hơi chùng đầu gối khi bước đi (kỹ thuật Ninja Walk).",
      cameraPreset: {
        mode: 'VIDEO 4K/60',
        fps: 60,
        resolution: '4K',
        iso: 100,
        shutter: '1/120s',
        ev: '0.0',
        wb: 'Auto',
        lut: 'Vibrant Outdoor Rec.709',
        gimbalMode: 'LOCK Khóa',
        followSpeed: 'Ninja Walk Dampening',
        summary: 'VIDEO 4K/60 • Gimbal: LOCK Khóa • Khử rung bước chân'
      },
      suggestAction: true,
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_creative_apple_log_workflow',
      target: 'creative',
      topic: 'Chỉnh màu Apple Log và nạp 3D LUT .cube',
      keywords: ['apple log', 'log', 'lut', 'chỉnh màu', 'cube', 'color grading', 'rec709', 'phẳng', 'màu phim', 'nạp lut'],
      answer: "🎨 **Kỹ Thuật Chỉnh Màu - Quy Trình Apple Log & 3D LUT:**\n" +
              "Quay ở định dạng Apple Log giúp lưu giữ tối đa 14+ stops dải nhạy sáng. Ứng dụng T-Flow cho phép bật tính năng **Realtime 3D LUT Preview**, giúp anh nhìn thấy màu phim điện ảnh hoàn chỉnh ngay trên màn hình lúc bấm máy mà không phải chờ về máy tính hậu kỳ.\n\n" +
              "📋 **Bộ thông số tối ưu đề xuất:**\n" +
              "• **Chế độ quay:** PRO CINEMA (ProRes Log 4K/24fps)\n" +
              "• **Tốc độ màn trập (Shutter):** 1/48s\n" +
              "• **ISO:** 100 (Native Base ISO của Apple Log)\n" +
              "• **LUT đang áp dụng:** Apple Log to Rec.709 Cinema Gold (.cube)\n" +
              "• **Chế độ Gimbal:** PF (Pan Follow)",
      cameraPreset: {
        mode: 'PRO CINEMA',
        fps: 24,
        resolution: '4K ProRes',
        iso: 100,
        shutter: '1/48s',
        ev: '0.0',
        wb: '5600K Daylight',
        lut: 'Apple Log to Rec.709 Cinema Gold',
        gimbalMode: 'PF (Pan Follow)',
        followSpeed: 'Chậm điện ảnh',
        summary: 'PRO CINEMA ProRes Log 4K/24 • LUT Rec.709 Gold'
      },
      suggestAction: true,
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_creative_edit_capcut_premiere',
      target: 'creative',
      topic: 'Kỹ thuật hậu kỳ CapCut & Premiere Pro với 3D LUT Rec.709',
      keywords: ['capcut', 'premiere', 'edit', 'hậu kỳ', 'cắt dựng', 'dựng phim', 'render', 'xuất video', 'áp màu', 'lồng tiếng', 'dựng'],
      answer: "✂️ **Kỹ Thuật Hậu Kỳ & Edit Video Điện Ảnh (CapCut & Premiere Pro):**\n\n" +
              "1. **Quy trình dựng trên CapCut:**\n" +
              "• Tải file quay từ iPhone về, import vào CapCut.\n" +
              "• Vào mục **Bộ lọc (Filters)** > **Thêm LUT tùy chỉnh (.cube)** do T-Flow cung cấp sẵn để chuyển không gian màu Apple Log sang Rec.709 rực rỡ chuẩn màn hình di động.\n" +
              "• Tăng nhẹ độ tương phản (Contrast +5) và giảm sáng vùng tối (Shadows -3) để tạo chiều sâu khối điện ảnh.\n\n" +
              "2. **Quy trình dựng trên Adobe Premiere Pro / DaVinci Resolve:**\n" +
              "• Áp dụng Color Space Transform từ Apple Log sang Rec.709.\n" +
              "• Âm thanh thu từ micro kép 2.4GHz của T-Flow tự động khớp sync 1-click, áp nhẹ hiệu ứng De-Noise khử ồn tạp âm.\n" +
              "• Xuất file định dạng H.265 / ProRes 422 HQ ở bitrate 60Mbps để giữ nguyên độ nét 4K khi đăng TikTok/YouTube.",
      actions: [
        { label: '🎨 Xem Thư Viện 3D LUT', view: 'catalog' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },

    // =========================================================================
    // --- 3. CHUYÊN MỤC 3: TÍNH NĂNG NHẬN DIỆN AI THÔNG MINH (SMART VISION) ---
    // =========================================================================
    {
      id: 'kb_vision_face_body_tracking',
      target: 'smart_vision',
      topic: 'Bám nét người & khuôn mặt quang học 120fps (Optical Tracking)',
      keywords: ['bám nét', 'người', 'khuôn mặt', 'chủ thể', 'tracking', 'optical', '120fps', 'mặt', 'theo dõi', 'bắt nét', 'bám người', 'nhận diện người'],
      answer: "🧠 **Tính Năng Nhận Diện AI: Bám Nét Người & Khuôn Mặt Quang Học 120fps:**\n\n" +
              "• **Cảm biến AI Vision quang học độc lập**: Gắn trực tiếp trên ngàm gimbal, xử lý độc lập không tiêu tốn RAM hay làm nóng điện thoại.\n" +
              "• **Tốc độ bám nét 120fps siêu tốc**: Tần số quét 120 khung hình/giây với độ trễ phản hồi < 5ms, bám sát từng chuyển động quay đầu, xoay người hay chạy nước rút.\n" +
              "• **Mô hình khung xương Skeletal Mesh**: Khi chủ thể quay lưng lại hoặc đeo kính râm/khẩu trang, AI vẫn nhận diện theo tỷ lệ cơ thể và khung vai, không bao giờ bị mất dấu (Zero Tracking Lost).\n" +
              "• **Thuật toán dự đoán gia tốc Kalman Filter**: Dự đoán trước hướng di chuyển của người quay để lia trục Pan/Tilt trước một nhịp, chuyển động cực kỳ êm ái.",
      actions: [
        { label: '🎯 Thử Kính Ngắm App AI', action: "window.open('mobile_app.html', '_blank')" },
        { label: '📦 Xem Cụm Camera AI', view: 'detail' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_vision_pet_tracking',
      target: 'smart_vision',
      topic: 'Bám nét thú cưng thông minh (Pet Tracking chó, mèo chuyển động)',
      keywords: ['chó', 'mèo', 'thú cưng', 'pet', 'động vật', 'chạy nhảy', 'nhanh', 'bám chó mèo', 'pet tracking', 'chó mèo'],
      answer: "🐕 **Tính Năng Nhận Diện AI: Bám Nét Thú Cưng Thông Minh (Pet Tracking):**\n\n" +
              "• **Thuật toán thị giác động học 4 chân (Quadruped Kinematics)**: Được huấn luyện trên hơn 100.000 clip chuyển động của các giống chó mèo khác nhau.\n" +
              "• **Bắt dính chuyển động bất quy tắc**: Thú cưng thường có thói quen đổi hướng đột ngột hoặc nhảy chồm lên. Cụm AI nhận diện tức thời khớp hông và đầu thú cưng để điều khiển motor FOC bám theo với gia tốc cao (Sport Mode 85%).\n" +
              "• **Khóa tầm thấp (Low-angle Lock)**: Giúp gimbal hạ thấp sát mặt đất để quay những thước phim ngang tầm mắt của thú cưng cực kỳ đáng yêu và sống động.",
      actions: [
        { label: '🎯 Thử Kính Ngắm App AI', action: "window.open('mobile_app.html', '_blank')" },
        { label: '⚡ Xem Chi Tiết Kỹ Thuật', view: 'detail' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_vision_custom_object_bounding_box',
      target: 'smart_vision',
      topic: 'Khóa và bám nét vật thể tùy chọn (Target Bounding Box Tracking)',
      keywords: ['khóa vật thể', 'khoanh vùng', 'bounding box', 'vật thể', 'chọn vật', 'xe', 'bóng', 'đồ vật', 'chạm', 'khoanh', 'bám vật thể'],
      answer: "📦 **Tính Năng Nhận Diện AI: Khóa Vật Thể Tùy Chọn Bằng Khung Viền Bounding Box:**\n\n" +
              "• **Khoanh vùng trực tiếp trên màn hình**: Người dùng chỉ cần chạm tay hoặc kéo một ô vuông (Bounding Box) bao quanh bất kỳ vật thể nào: xe ô tô đang chạy, quả bóng rổ, flycam trên trời, hoặc món đồ trên bàn xoay sản phẩm.\n" +
              "• **Thuật toán phân tích đặc trưng màu & hình học (Feature Vector Extraction)**: AI ghi nhớ màu sắc, hoa văn và đường nét biên của vật thể trong không gian 3 chiều.\n" +
              "• **Tự động điều chỉnh tiêu cự & giữ bố cục (Smart Framing)**: Giữ cho vật thể đã chọn luôn nằm chính xác ở vị trí 1/3 (quy tắc điểm vàng) hoặc chính giữa khung hình dù vật thể tiến lại gần hay ra xa.",
      actions: [
        { label: '🎯 Thử Kính Ngắm App AI', action: "window.open('mobile_app.html', '_blank')" },
        { label: '📦 Xem Dải Sản Phẩm', view: 'catalog' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_vision_auto_ultrawide_switch',
      target: 'smart_vision',
      topic: 'Tự động kích hoạt camera góc rộng 0.5x Ultra-Wide khi đông người',
      keywords: ['góc rộng', 'ultra-wide', '0.5x', 'đông người', 'nhóm', 'tập thể', 'ngoài khung hình', 'tự đổi cam', 'tự bật', 'đổi camera', 'rộng hơn'],
      answer: "📐 **Tính Năng Nhận Diện AI: Tự Động Kích Hoạt Camera Góc Rộng 0.5x Ultra-Wide:**\n\n" +
              "• **Quét vùng ngoại vi thông minh**: Khi đang quay ở ống kính chính 1x, cụm AI liên tục phân tích chu vi xung quanh khung hình.\n" +
              "• **Tự động nhận diện nhóm đông**: Nếu phát hiện có từ 3 người trở lên hoặc có thêm bạn bè bước vào rìa khung hình, AI sẽ phát hiện và ngay lập tức gửi lệnh qua BLE ra lệnh điện thoại tự động chuyển mượt sang camera 0.5x Ultra-Wide.\n" +
              "• **Chuyển đổi Zoom mượt mà (Smooth Transition)**: Thuật toán nội suy zoom điện tử giúp cảnh chuyển từ 1x sang 0.5x êm ái như máy quay điện ảnh, không bị giật khựng.",
      actions: [
        { label: '🎯 Thử Kính Ngắm App AI', action: "window.open('mobile_app.html', '_blank')" },
        { label: '⚡ Tìm Hiểu Động Cơ FOC', view: 'detail' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    },
    {
      id: 'kb_vision_gesture_control',
      target: 'smart_vision',
      topic: 'Điều khiển bằng cử chỉ tay không chạm (Hand Gesture AI Control)',
      keywords: ['cử chỉ', 'vẫy tay', 'bàn tay', 'chữ v', 'giơ tay', 'gesture', 'không chạm', 'bắt đầu quay', 'chụp ảnh cử chỉ', 'điều khiển tay'],
      answer: "✋ **Tính Năng Nhận Diện AI: Điều Khiển Cử Chỉ Tay Không Chạm (Hand Gesture Control):**\n\n" +
              "Rất thích hợp cho solo creator, vũ công, vlogger khi đứng cách xa máy quay mà không có người hỗ trợ:\n" +
              "• ✋ **Giơ lòng bàn tay (Palm)**: Bắt đầu khóa mục tiêu và theo dõi AI (Start AI Tracking). Giơ lại lần nữa để dừng theo dõi.\n" +
              "• ✌️ **Giơ 2 ngón tay chữ V (Peace)**: Kích hoạt đếm ngược 3 giây để chụp ảnh hoặc bắt đầu bấm máy quay video.\n" +
              "• 🤙 **Cử chỉ ngón cái & ngón trỏ (OK Gesture)**: Ra lệnh cho Gimbal tự động xoay điện thoại từ khung hình ngang (16:9 YouTube) sang dọc (9:16 TikTok/Reels) trong 0.8 giây mà không cần chạm tay vào máy.",
      actions: [
        { label: '🎯 Thử Kính Ngắm App AI', action: "window.open('mobile_app.html', '_blank')" },
        { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' }
      ],
      isOfficial: true,
      updatedAt: '2026-11-09T08:00:00Z'
    }
  ];  // --- KNOWLEDGE BASE ACCESS & CRUD ---
  function getAiKnowledgeBase() {
    if (typeof localStorage === 'undefined') return DEFAULT_AI_KNOWLEDGE_BASE.slice();
    try {
      var saved = localStorage.getItem(AI_KB_KEY);
      if (saved) {
        var parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length > 0) {
          // Self-heal: ensure all official entries across the 3 domains are present
          var idMap = {};
          parsed.forEach(function(p) { idMap[p.id] = true; });
          var modified = false;
          DEFAULT_AI_KNOWLEDGE_BASE.forEach(function(def) {
            if (!idMap[def.id]) {
              parsed.push(def);
              modified = true;
            }
          });
          if (modified) {
            try { localStorage.setItem(AI_KB_KEY, JSON.stringify(parsed)); } catch (e) {}
          }
          return parsed;
        }
      }
    } catch (e) {
      console.warn('Error reading AI knowledge base:', e);
    }
    // Default fallback
    if (typeof localStorage !== 'undefined') {
      try { localStorage.setItem(AI_KB_KEY, JSON.stringify(DEFAULT_AI_KNOWLEDGE_BASE)); } catch (e) {}
    }
    return DEFAULT_AI_KNOWLEDGE_BASE.slice();
  }

  function saveAiKnowledgeBase(kbList) {
    if (typeof localStorage === 'undefined') return;
    try {
      localStorage.setItem(AI_KB_KEY, JSON.stringify(kbList));
      if (typeof window !== 'undefined' && window.dispatchEvent) window.dispatchEvent(new CustomEvent(AI_EVENT, { detail: { action: 'kb_updated' } }));
    } catch (e) {
      console.error('Error saving AI knowledge base:', e);
    }
  }

  function addOrUpdateAiKnowledge(item) {
    var kb = getAiKnowledgeBase();
    if (!item.id) {
      item.id = 'kb_' + Date.now() + '_' + Math.random().toString(36).substr(2, 4);
    }
    item.updatedAt = new Date().toISOString();
    var idx = kb.findIndex(function(k) { return k.id === item.id; });
    if (idx >= 0) {
      kb[idx] = Object.assign({}, kb[idx], item);
    } else {
      kb.unshift(item);
    }
    saveAiKnowledgeBase(kb);
    return item;
  }

  function deleteAiKnowledge(id) {
    var kb = getAiKnowledgeBase();
    kb = kb.filter(function(k) { return k.id !== id; });
    saveAiKnowledgeBase(kb);
    return true;
  }

  // --- CONVERSATION LOGS (CENTRALIZED FOR WEB & APP) ---
  function getAiConversations() {
    if (typeof localStorage === 'undefined') return [];
    try {
      var saved = localStorage.getItem(AI_CONVERSATIONS_KEY);
      if (saved) {
        var parsed = JSON.parse(saved);
        if (Array.isArray(parsed)) return parsed;
      }
    } catch (e) {
      console.warn('Error reading AI conversations:', e);
    }
    return [];
  }

  function logAiConversation(entry) {
    var convs = getAiConversations();
    var record = {
      id: 'conv_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
      source: entry.source || 'web', // 'web' or 'app'
      userEmail: entry.userEmail || (getCurrentUser() ? getCurrentUser().email : 'Khách vãng lai'),
      userName: entry.userName || (getCurrentUser() ? getCurrentUser().name : 'Khách hàng'),
      query: (entry.query || '').trim(),
      reply: (entry.reply || '').trim(),
      status: entry.status || 'answered', // 'answered', 'pending_approval', 'trained'
      actionPayload: entry.actionPayload || null,
      confidence: entry.confidence || 1.0,
      timestamp: new Date().toISOString()
    };
    convs.unshift(record);
    // Keep last 500 conversations to prevent storage overflow
    if (convs.length > 500) convs = convs.slice(0, 500);
    try {
      if (typeof localStorage !== 'undefined') localStorage.setItem(AI_CONVERSATIONS_KEY, JSON.stringify(convs));
      if (typeof window !== 'undefined' && window.dispatchEvent) window.dispatchEvent(new CustomEvent(AI_EVENT, { detail: { action: 'conversation_logged', record: record } }));
    } catch (e) {
      console.error('Error saving AI conversation:', e);
    }
    return record;
  }

  function clearAiLogs() {
    try {
      localStorage.setItem(AI_CONVERSATIONS_KEY, JSON.stringify([]));
      if (typeof window !== 'undefined' && window.dispatchEvent) window.dispatchEvent(new CustomEvent(AI_EVENT, { detail: { action: 'logs_cleared' } }));
    } catch (e) {}
  }

  // --- PENDING QUESTIONS FOR ADMIN TRAINING ---
  function getPendingAiQuestions() {
    if (typeof localStorage === 'undefined') return [];
    try {
      var saved = localStorage.getItem(AI_PENDING_KEY);
      if (saved) {
        var parsed = JSON.parse(saved);
        if (Array.isArray(parsed)) return parsed;
      }
    } catch (e) {
      console.warn('Error reading pending AI questions:', e);
    }
    return [];
  }

  function savePendingAiQuestions(list) {
    if (typeof localStorage === 'undefined') return;
    try {
      localStorage.setItem(AI_PENDING_KEY, JSON.stringify(list));
      if (typeof window !== 'undefined' && window.dispatchEvent) window.dispatchEvent(new CustomEvent(AI_EVENT, { detail: { action: 'pending_updated' } }));
    } catch (e) {
      console.error('Error saving pending AI questions:', e);
    }
  }

  function escalateToAdmin(params) {
    var pending = getPendingAiQuestions();
    var record = {
      id: 'pend_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
      source: params.source || 'web', // 'web' or 'app'
      userEmail: params.userEmail || (getCurrentUser() ? getCurrentUser().email : 'Khách vãng lai'),
      userName: params.userName || (getCurrentUser() ? getCurrentUser().name : 'Khách hàng'),
      query: (params.query || '').trim(),
      reason: params.reason || 'Câu hỏi khó hoặc chưa có trong bộ dữ liệu chuẩn',
      context: params.context || null,
      status: 'pending', // 'pending', 'approved', 'ignored'
      timestamp: new Date().toISOString()
    };
    pending.unshift(record);
    savePendingAiQuestions(pending);
    return record;
  }

  // --- DIRECT ADMIN COMMENT & TRAINING ON ANY CONVERSATION ---
  function trainConversationDirectly(convId, params) {
    params = params || {};
    var officialAnswer = (params.answer || '').trim();
    var topic = (params.topic || '').trim();
    var target = params.target || 'sales';
    var keywords = params.keywords;
    var adminComment = (params.adminComment || params.answer || '').trim();

    var convs = getAiConversations();
    var conv = convs.find(function(c) { return c.id === convId; });
    if (!conv && params.query) {
      conv = convs.find(function(c) { return c.query === params.query; });
    }

    var queryText = conv ? conv.query : (params.query || 'Câu hỏi khách hàng');

    // 1. Extract or parse keywords
    var kwList = [];
    if (keywords && typeof keywords === 'string') {
      kwList = keywords.split(',').map(function(s) { return s.trim().toLowerCase(); }).filter(Boolean);
    } else if (Array.isArray(keywords)) {
      kwList = keywords;
    }
    if (kwList.length === 0 && queryText) {
      var cleanQ = queryText.toLowerCase().replace(/[^a-zA-Z0-9À-ỹ ]/g, ' ');
      kwList = cleanQ.split(/\s+/).filter(function(w) { return w.length > 2; });
    }

    // 2. Add or update into AI Knowledge Base (SO THE AI IS TRAINED IMMEDIATELY)
    var kbEntry = addOrUpdateAiKnowledge({
      id: 'kb_admin_' + Date.now(),
      target: target,
      topic: topic || ('Giải đáp: ' + queryText.substring(0, 45)),
      keywords: kwList,
      answer: officialAnswer,
      isOfficial: true,
      trainedByAdmin: 'thuynguyen2dk4@gmail.com',
      sourceConvId: convId
    });

    // 3. Update the conversation in aiConversations
    if (conv) {
      conv.status = 'trained';
      conv.reply = officialAnswer;
      conv.adminComment = adminComment;
      conv.adminTrainedBy = 'Master Admin Thủy Nguyễn';
      conv.trainedAt = new Date().toISOString();
      try {
        if (typeof localStorage !== 'undefined') {
          localStorage.setItem(AI_CONVERSATIONS_KEY, JSON.stringify(convs));
        }
      } catch (e) {}
    }

    // 4. Also mark any matching pending questions as approved
    var pending = getPendingAiQuestions();
    var pMatch = pending.find(function(p) { return p.query === queryText && p.status === 'pending'; });
    if (pMatch) {
      pMatch.status = 'approved';
      pMatch.officialAnswer = officialAnswer;
      pMatch.trainedAt = new Date().toISOString();
      savePendingAiQuestions(pending);
    }

    // Trigger AI_EVENT to update all listening tabs in real time
    if (typeof window !== 'undefined' && window.dispatchEvent) {
      window.dispatchEvent(new CustomEvent(AI_EVENT, {
        detail: { action: 'conversation_trained', convId: convId, kbEntry: kbEntry }
      }));
    }

    return { success: true, conv: conv, kbEntry: kbEntry };
  }

  function approveAndTrainAiQuestion(questionId, officialAnswer, keywords, topic, target) {
    var pending = getPendingAiQuestions();
    var item = pending.find(function(p) { return p.id === questionId; });
    if (!item) return false;

    item.status = 'approved';
    item.officialAnswer = officialAnswer;
    item.trainedAt = new Date().toISOString();
    savePendingAiQuestions(pending);

    // Extract keywords from query if not provided
    var kwList = [];
    if (keywords && typeof keywords === 'string') {
      kwList = keywords.split(',').map(function(s) { return s.trim().toLowerCase(); }).filter(Boolean);
    } else if (Array.isArray(keywords)) {
      kwList = keywords;
    }
    if (kwList.length === 0) {
      var cleanQ = item.query.toLowerCase().replace(/[^a-zA-Z0-9À-ỹ ]/g, ' ');
      kwList = cleanQ.split(/\s+/).filter(function(w) { return w.length > 2; });
    }

    // Add to Verified Knowledge Base so AI is now TRAINED!
    addOrUpdateAiKnowledge({
      id: 'kb_trained_' + Date.now(),
      target: target || item.source || 'web',
      topic: topic || ('Giải đáp: ' + item.query.substring(0, 40) + '...'),
      keywords: kwList,
      answer: officialAnswer,
      isOfficial: true,
      trainedByAdmin: 'thuynguyen2dk4@gmail.com'
    });

    // Mark related conversations as trained
    var convs = getAiConversations();
    var matchedConv = convs.find(function(c) { return c.query === item.query; });
    if (matchedConv) {
      matchedConv.status = 'trained';
      matchedConv.reply = officialAnswer;
      try {
        if (typeof localStorage !== 'undefined') localStorage.setItem(AI_CONVERSATIONS_KEY, JSON.stringify(convs));
      } catch (e) {}
    }

    return true;
  }

  function ignorePendingAiQuestion(questionId) {
    var pending = getPendingAiQuestions();
    pending = pending.filter(function(p) { return p.id !== questionId; });
    savePendingAiQuestions(pending);
    return true;
  }

  // =========================================================================
  // --- GOOGLE OAUTH 2.0 CLIENT CONFIGURATION ---
  // =========================================================================
  var DEFAULT_GOOGLE_OAUTH_CLIENT_ID = '725853259455-83tapd22sn2en4cht3jdiaa0ehn734ac.apps.googleusercontent.com';
  var GOOGLE_OAUTH_CLIENT_ID_KEY = 'tflow_google_oauth_client_id';

  function getGoogleOAuthClientId() {
    if (typeof localStorage !== 'undefined') {
      var custom = localStorage.getItem(GOOGLE_OAUTH_CLIENT_ID_KEY);
      if (custom && custom.trim()) return custom.trim();
    }
    return DEFAULT_GOOGLE_OAUTH_CLIENT_ID;
  }

  function saveGoogleOAuthClientId(clientId) {
    if (typeof localStorage === 'undefined') return;
    localStorage.setItem(GOOGLE_OAUTH_CLIENT_ID_KEY, (clientId || '').trim());
  }

  // =========================================================================
  // --- T-FLOW UNIFIED CLOUD AI ENGINE (GOOGLE GEMINI 3.5 FLASH) ---
  // =========================================================================
  var DEFAULT_GEMINI_API_KEY = 'AIzaSyDluWTvQMgGmw2yceO27urpn4UBOZ1LQF0';
  var DEFAULT_AI_MODEL = 'gemini-3.5-flash';
  var AI_CLOUD_CONFIG_KEY = 'tflow_cloud_ai_config';

  function getCloudAiConfig() {
    var def = {
      apiKey: DEFAULT_GEMINI_API_KEY,
      model: DEFAULT_AI_MODEL,
      endpoint: '/api/chat',
      provider: 'google_cloud_ai',
      status: 'ready'
    };
    if (typeof localStorage === 'undefined') return def;
    try {
      var raw = localStorage.getItem(AI_CLOUD_CONFIG_KEY);
      if (!raw) return def;
      var parsed = JSON.parse(raw);
      if (!parsed.apiKey || !parsed.apiKey.trim()) {
        parsed.apiKey = def.apiKey;
      }
      if (!parsed.model || parsed.model === 'gemini-2.5-flash' || parsed.model === 'gemini-1.5-flash') {
        parsed.model = DEFAULT_AI_MODEL;
      }
      return Object.assign({}, def, parsed);
    } catch (e) {
      return def;
    }
  }

  function saveCloudAiConfig(cfg) {
    if (typeof localStorage === 'undefined') return cfg;
    try {
      var current = getCloudAiConfig();
      var merged = Object.assign({}, current, cfg);
      localStorage.setItem(AI_CLOUD_CONFIG_KEY, JSON.stringify(merged));
      return merged;
    } catch (e) {
      return cfg;
    }
  }

  async function testCloudAiConnection(apiKey, model) {
    var targetModel = model || 'gemini-2.5-flash';
    var startTime = Date.now();
    var cfg = getCloudAiConfig();
    var keyToTest = apiKey || cfg.apiKey || '';

    // Step 1: Test via /api/chat serverless function
    try {
      var res = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-gemini-api-key': keyToTest
        },
        body: JSON.stringify({
          prompt: 'Ping kiểm tra kết nối Google Cloud AI T-Flow',
          mode: 'web',
          apiKey: keyToTest,
          model: targetModel
        })
      });
      if (res.ok) {
        var data = await res.json();
        var latency = Date.now() - startTime;
        return {
          success: true,
          latencyMs: latency,
          model: data.model || targetModel,
          source: data.source || 'vercel_serverless',
          message: 'Kết nối Google Cloud AI thành công qua Vercel Serverless (' + latency + 'ms)'
        };
      }
    } catch (e) {}

    // Step 2: Direct call to Google Gemini REST API if key is present
    if (keyToTest) {
      try {
        var directUrl = 'https://generativelanguage.googleapis.com/v1beta/models/' + encodeURIComponent(targetModel) + ':generateContent?key=' + encodeURIComponent(keyToTest);
        var gRes = await fetch(directUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: 'Ping' }] }]
          })
        });
        if (gRes.ok) {
          var latency = Date.now() - startTime;
          return {
            success: true,
            latencyMs: latency,
            model: targetModel,
            source: 'google_gemini_direct',
            message: 'Kết nối trực tiếp Google Gemini API thành công (' + latency + 'ms)'
          };
        } else {
          var errTxt = await gRes.text();
          return {
            success: false,
            error: 'Google API trả về lỗi ' + gRes.status + ': ' + errTxt.slice(0, 150)
          };
        }
      } catch (err) {
        return {
          success: false,
          error: 'Lỗi mạng khi kết nối Google API: ' + err.message
        };
      }
    }

    return {
      success: false,
      error: 'Chưa có Google AI API Key hợp lệ hoặc không thể kết nối serverless endpoint'
    };
  }

  // --- SMART INTERNAL KNOWLEDGE BASE FALLBACK (ZERO DOWNTIME GUARANTEE - 3 DOMAINS) ---
  
  // 1. DOMAIN: TƯ VẤN BÁN HÀNG & CHÍNH SÁCH
  function processWebSmartFallback(userQuery, userContext) {
    var cleanQuery = (userQuery || '').trim().toLowerCase();
    var kb = getAiKnowledgeBase();
    var salesKb = kb.filter(function(k) {
      return k.target === 'sales' || k.target === 'web' || k.target === 'all_domains' || k.target === 'both';
    });

    var bestMatch = null;
    var highestScore = 0;

    salesKb.forEach(function(item) {
      var score = 0;
      var keywords = item.keywords || [];
      keywords.forEach(function(kw) {
        if (cleanQuery.indexOf(kw.toLowerCase()) !== -1) score += 10;
      });
      if (item.topic && cleanQuery.indexOf(item.topic.toLowerCase()) !== -1) score += 25;
      if (score > highestScore) {
        highestScore = score;
        bestMatch = item;
      }
    });

    if (!bestMatch || highestScore < 10) {
      return {
        answer: 'Dạ câu hỏi này mang tính chính sách/đặc quyền chuyên sâu mà em chưa có dữ liệu kiểm định từ Master Admin Thủy Nguyễn. Để bảo đảm thông tin chuẩn xác 100% và không trả lời bừa, em đã tự động chuyển tiếp câu hỏi này về Trung Tâm Huấn Luyện AI cho Admin duyệt giải đáp sớm nhất cho anh/chị ạ! 🙏\n\nTrong lúc chờ duyệt, anh/chị có thể tham khảo nhanh bảng giá 4 gói T-Flow Pro hoặc các thông số động cơ Pure FOC 20kHz và ngàm MagSafe bên dưới ạ:',
        status: 'pending_approval',
        escalated: true,
        actions: [
          { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' },
          { label: '⚡ Xem Thông Số Kỹ Thuật', view: 'detail' }
        ]
      };
    }

    return {
      answer: bestMatch.answer,
      status: 'answered',
      escalated: false,
      actions: bestMatch.actions || []
    };
  }

  // 2. DOMAIN: KỸ THUẬT QUAY CHỤP & EDIT DỰNG PHIM
  function processAppSmartFallback(userQuery, userContext) {
    var cleanQuery = (userQuery || '').trim().toLowerCase();
    var kb = getAiKnowledgeBase();
    var creativeKb = kb.filter(function(k) {
      return k.target === 'creative' || k.target === 'app' || k.target === 'all_domains' || k.target === 'both';
    });

    var bestMatch = null;
    var highestScore = 0;

    creativeKb.forEach(function(item) {
      var score = 0;
      var keywords = item.keywords || [];
      keywords.forEach(function(kw) {
        if (cleanQuery.indexOf(kw.toLowerCase()) !== -1) score += 10;
      });
      if (item.topic && cleanQuery.indexOf(item.topic.toLowerCase()) !== -1) score += 25;
      if (score > highestScore) {
        highestScore = score;
        bestMatch = item;
      }
    });

    if (!bestMatch || highestScore < 10) {
      return {
        answer: 'Dạ yêu cầu góc quay hoặc kỹ thuật edit này cần kinh nghiệm đạo diễn chuyên sâu mà em chưa được huấn luyện dữ liệu chuẩn. Để tránh thiết lập thông số sai lệch làm hỏng cảnh quay của anh/chị, em đã gửi thông báo về Trung Tâm Điều Hành cho Master Admin Thủy Nguyễn duyệt và cập nhật bộ thông số chuẩn ngay ạ! 🙏\n\nHiện tại anh/chị có thể chọn nhanh các preset có sẵn: Quay Hoàng Hôn Biển, Thể Thao Tốc Độ Cao, Chân Dung Xóa Phông hoặc Inception 360° bên dưới ạ:',
        status: 'pending_approval',
        escalated: true,
        suggestAction: false,
        cameraPreset: null
      };
    }

    var preset = bestMatch.cameraPreset ? Object.assign({}, bestMatch.cameraPreset) : null;
    if (preset && !preset.name) {
      preset.name = bestMatch.topic || 'Preset Chuẩn Điện Ảnh';
    }

    var fullReply = bestMatch.answer;
    if (preset) {
      fullReply += '\n\n⚡ **Anh có muốn em tự thao tác cài đặt toàn bộ các thông số này trên camera và gimbal luôn giúp anh không?**';
    }

    return {
      answer: fullReply,
      status: 'answered',
      escalated: false,
      suggestAction: !!preset,
      promptQuestion: preset ? 'Anh có muốn em tự thao tác cài đặt các thông số này không?' : null,
      cameraPreset: preset,
      actions: bestMatch.actions || []
    };
  }

  // 3. DOMAIN: TÍNH NĂNG NHẬN DIỆN AI THÔNG MINH (SMART VISION)
  function processSmartVisionFallback(userQuery, userContext) {
    var cleanQuery = (userQuery || '').trim().toLowerCase();
    var kb = getAiKnowledgeBase();
    var visionKb = kb.filter(function(k) {
      return k.target === 'smart_vision' || k.target === 'all_domains' || k.target === 'both';
    });

    var bestMatch = null;
    var highestScore = 0;

    visionKb.forEach(function(item) {
      var score = 0;
      var keywords = item.keywords || [];
      keywords.forEach(function(kw) {
        if (cleanQuery.indexOf(kw.toLowerCase()) !== -1) score += 10;
      });
      if (item.topic && cleanQuery.indexOf(item.topic.toLowerCase()) !== -1) score += 25;
      if (score > highestScore) {
        highestScore = score;
        bestMatch = item;
      }
    });

    if (!bestMatch || highestScore < 10) {
      return {
        answer: 'Dạ về tính năng nhận diện thị giác máy tính AI của T-Flow Pro:\n\n' +
                '• **Bám nét người & mặt 120fps**: Sử dụng cảm biến quang học độc lập bám chuẩn xác theo khung xương Skeletal Mesh.\n' +
                '• **Bám nét thú cưng (Pet Tracking)**: Bắt dính chuyển động nhanh, luồn lách của chó mèo theo thuật toán động học 4 chân.\n' +
                '• **Khóa vật thể Bounding Box**: Chạm hoặc kéo ô vuông trên màn hình để khóa bất kỳ vật thể nào.\n' +
                '• **Tự động đổi camera góc rộng 0.5x Ultra-Wide**: Tự kích hoạt khi phát hiện nhóm đông ngoài khung hình.\n' +
                '• **Cử chỉ tay Gesture**: Giơ bàn tay ✋ để bám nét, giơ chữ V ✌️ để chụp/quay.\n\n' +
                'Nếu câu hỏi mang tính nghiên cứu thuật toán chuyên sâu, em đã ghi nhận và chuyển về cho Master Admin Thủy Nguyễn duyệt trả lời thêm cho anh/chị ạ!',
        status: 'pending_approval',
        escalated: true,
        actions: [
          { label: '🎯 Thử Kính Ngắm App AI', action: "window.open('mobile_app.html', '_blank')" },
          { label: '📦 Xem Cụm Camera AI', view: 'detail' }
        ]
      };
    }

    return {
      answer: bestMatch.answer,
      status: 'answered',
      escalated: false,
      actions: bestMatch.actions || []
    };
  }

  // --- UNIFIED CLOUD AI QUERY ENGINE (SUPPORTS 3 DOMAINS) ---
  async function queryUnifiedCloudAi(params) {
    params = params || {};
    var prompt = (params.prompt || '').trim();
    var rawMode = params.mode || 'sales';
    var mode = 'sales';
    if (rawMode === 'creative' || rawMode === 'app') mode = 'creative';
    else if (rawMode === 'smart_vision') mode = 'smart_vision';
    else mode = 'sales';

    var history = params.history || [];
    var context = params.context || {};

    // Gather active Admin Directives & Comments
    try {
      var allDirectives = [];
      var convList = getAiConversations() || [];
      convList.forEach(function(c) {
        if (c.adminComment) {
          allDirectives.push({
            queryPattern: c.query,
            target: c.source || 'sales',
            directive: c.adminComment
          });
        }
      });
      var kbList = getAiKnowledge() || [];
      kbList.forEach(function(k) {
        if (k.adminComment || k.directive) {
          allDirectives.push({
            queryPattern: k.queryPattern || k.topic,
            target: k.target || 'sales',
            directive: k.adminComment || k.directive
          });
        }
      });
      if (allDirectives.length > 0) {
        context.adminDirectives = allDirectives.slice(-8);
      }
    } catch(e) {}

    var currentUserObj = getCurrentUser();
    var email = currentUserObj ? currentUserObj.email : (mode === 'creative' ? 'Người dùng App T-Flow' : 'Khách vãng lai');
    var name = currentUserObj ? currentUserObj.name : (mode === 'creative' ? 'Nhà sáng tạo' : 'Quý khách');

    var cfg = getCloudAiConfig();
    var effectiveKey = cfg.apiKey || '';
    var effectiveModel = cfg.model || 'gemini-3.5-flash';

    var finalResult = null;

    // STEP 1: Attempt Serverless /api/chat call
    try {
      var res = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-gemini-api-key': effectiveKey
        },
        body: JSON.stringify({
          prompt: prompt,
          mode: mode,
          history: history,
          context: context,
          apiKey: effectiveKey,
          model: effectiveModel
        })
      });

      if (res.ok) {
        var data = await res.json();
        if (data && data.answer) {
          finalResult = data;
        }
      }
    } catch (e) {}

    // STEP 2: Fallback to verified local smart knowledge base for the selected domain
    if (!finalResult) {
      if (mode === 'creative') {
        finalResult = processAppSmartFallback(prompt, context);
      } else if (mode === 'smart_vision') {
        finalResult = processSmartVisionFallback(prompt, context);
      } else {
        finalResult = processWebSmartFallback(prompt, context);
      }
    }

    // STEP 3: STRICT ESCALATION ROUTING
    if (finalResult.escalated) {
      escalateToAdmin({
        source: mode,
        userEmail: email,
        userName: name,
        query: prompt,
        reason: 'Câu hỏi chuyên sâu thuộc chuyên mục ' + mode + ' cần Master Admin duyệt',
        context: context
      });
    }

    // STEP 4: CENTRAL AUDIT CONVERSATION LOG
    var record = logAiConversation({
      source: mode,
      userEmail: email,
      userName: name,
      query: prompt,
      reply: finalResult.answer,
      status: finalResult.escalated ? 'pending_approval' : 'answered',
      actionPayload: finalResult.cameraPreset || finalResult.actions || null,
      confidence: finalResult.escalated ? 0.2 : 0.95
    });

    finalResult.recordId = record.id;
    return finalResult;
  }

  // --- COMPATIBILITY WRAPPERS FOR WEB & APP ---
  function processWebAiQuery(userQuery, userContext) {
    return queryUnifiedCloudAi({
      prompt: userQuery,
      mode: 'web',
      context: userContext
    });
  }

  function processAppAiQuery(userQuery, userContext) {
    return queryUnifiedCloudAi({
      prompt: userQuery,
      mode: 'app',
      context: userContext
    });
  }

  return {
    STORAGE_KEY: STORAGE_KEY,
    CART_KEY: CART_KEY,
    ORDERS_KEY: ORDERS_KEY,
    CURRENT_USER_KEY: CURRENT_USER_KEY,
    SYNC_EVENT: SYNC_EVENT,
    CART_EVENT: CART_EVENT,
    USER_EVENT: USER_EVENT,
    REVIEWS_KEY: REVIEWS_KEY,
    REVIEWS_EVENT: REVIEWS_EVENT,
    ADMIN_GMAILS: ADMIN_GMAILS,

    getCatalog: getCatalog,
    saveCatalog: saveCatalog,
    getMvpProductId: getMvpProductId,
    setMvpProduct: setMvpProduct,
    getMvpProduct: getMvpProduct,
    resetToDefault: resetToDefault,
    broadcastSync: broadcastSync,

    getGroups: getGroups,
    getGroup: getGroup,
    addGroup: addGroup,
    updateGroup: updateGroup,
    deleteGroup: deleteGroup,

    getProducts: getProducts,
    getProduct: getProduct,
    addProduct: addProduct,
    updateProduct: updateProduct,
    deleteProduct: deleteProduct,
    addTier: addTier,
    updateTier: updateTier,
    deleteTier: deleteTier,
    formatVND: formatVND,

    getCart: getCart,
    saveCart: saveCart,
    addToCart: addToCart,
    updateCartQty: updateCartQty,
    removeFromCart: removeFromCart,
    clearCart: clearCart,
    getCartCount: getCartCount,
    getCartTotal: getCartTotal,

    getOrders: getOrders,
    createOrder: createOrder,
    getUserOrders: getUserOrders,

    // Users & Auth
    getUsers: getUsers,
    getCurrentUser: getCurrentUser,
    isUserAdmin: isUserAdmin,
    loginUser: loginUser,
    registerUser: registerUser,
    loginWithGmail: loginWithGmail,
    logoutUser: logoutUser,
    updateUserProfile: updateUserProfile,
    updateUserModules: updateUserModules,

    // Reviews
    getReviews: getReviews,
    addReview: addReview,
    deleteReview: deleteReview,

    // CSV
    exportProductsCSV: exportProductsCSV,
    importProductsCSV: importProductsCSV,
    exportUsersCSV: exportUsersCSV,
    // AI Knowledge & Training Engine
    AI_CONVERSATIONS_KEY: AI_CONVERSATIONS_KEY,
    AI_PENDING_KEY: AI_PENDING_KEY,
    AI_KB_KEY: AI_KB_KEY,
    AI_EVENT: AI_EVENT,
    DEFAULT_AI_KNOWLEDGE_BASE: DEFAULT_AI_KNOWLEDGE_BASE,
    getAiKnowledgeBase: getAiKnowledgeBase,
    saveAiKnowledgeBase: saveAiKnowledgeBase,
    addOrUpdateAiKnowledge: addOrUpdateAiKnowledge,
    trainConversationDirectly: trainConversationDirectly,
    deleteAiKnowledge: deleteAiKnowledge,
    getAiConversations: getAiConversations,
    logAiConversation: logAiConversation,
    clearAiLogs: clearAiLogs,
    getPendingAiQuestions: getPendingAiQuestions,
    escalateToAdmin: escalateToAdmin,
    approveAndTrainAiQuestion: approveAndTrainAiQuestion,
    ignorePendingAiQuestion: ignorePendingAiQuestion,
    DEFAULT_GEMINI_API_KEY: DEFAULT_GEMINI_API_KEY,
    DEFAULT_AI_MODEL: DEFAULT_AI_MODEL,
    AI_CLOUD_CONFIG_KEY: AI_CLOUD_CONFIG_KEY,
    getCloudAiConfig: getCloudAiConfig,
    saveCloudAiConfig: saveCloudAiConfig,
    testCloudAiConnection: testCloudAiConnection,
    queryUnifiedCloudAi: queryUnifiedCloudAi,
    processWebSmartFallback: processWebSmartFallback,
    processAppSmartFallback: processAppSmartFallback,
    processWebAiQuery: processWebAiQuery,
    processAppAiQuery: processAppAiQuery,
    processSmartVisionFallback: processSmartVisionFallback,
    DEFAULT_GOOGLE_OAUTH_CLIENT_ID: DEFAULT_GOOGLE_OAUTH_CLIENT_ID,
    GOOGLE_OAUTH_CLIENT_ID_KEY: GOOGLE_OAUTH_CLIENT_ID_KEY,
    getGoogleOAuthClientId: getGoogleOAuthClientId,
    saveGoogleOAuthClientId: saveGoogleOAuthClientId,
    setCookie: setCookie,
    getCookie: getCookie,
    deleteCookie: deleteCookie,
    getCookieConsent: getCookieConsent,
    setCookieConsent: setCookieConsent,
    ACTIVE_SESSION_KEY: ACTIVE_SESSION_KEY,
    createSession: createSession,
    getActiveSession: getActiveSession,
    destroySession: destroySession,
    getUserSessionsHistory: getUserSessionsHistory,
    terminateOtherSessions: terminateOtherSessions
  };
}));
