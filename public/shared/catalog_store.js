/*!
 * Smart Gimbal Catalog & User Shared Store v3.5
 * Dynamic 2-Way Real-time Store for E-Commerce, Admin Publishing CMS & User Portal
 * Apple Store / DJI Store Light Monochrome Standard (Zero Emojis, Zero Customs Terms)
 * (C) 2026 Smart Gimbal S1 Ecosystem
 */
(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([], factory);
  } else if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.SmartGimbalCatalog = factory();
    root.TFlowCatalog = root.SmartGimbalCatalog;
  }
}(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  var STORAGE_KEY = 'TFLOW_CATALOG_V4';
  var CART_KEY = 'TFLOW_CART_V4';
  var ORDERS_KEY = 'TFLOW_ORDERS_V4';
  var CURRENT_USER_KEY = 'TFLOW_CURRENT_USER_V4';

  var SYNC_EVENT = 'smartgimbal:catalog_updated';
  var CART_EVENT = 'smartgimbal:cart_updated';
  var USER_EVENT = 'smartgimbal:user_updated';

  // 1.5 SUPABASE CLOUD DATABASE CONFIGURATION & REALTIME HOOKS
  var SUPABASE_URL = "https://dlgkrwodxdsbbliwdnkg.supabase.co";
  var SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsZ2tyd29keGRzYmJsaXdkbmtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxMjIwNjQsImV4cCI6MjEwOTY5ODA2NH0.Lg6C6MpLhX_CoKgWtl_nhWLGNw5NuYE9FZJoTxXnu6I";

  function syncUserModulesToSupabase(userId, modulesArray) {
    if (typeof fetch === 'undefined') return;
    try {
      fetch(SUPABASE_URL + '/rest/v1/users?id=eq.' + encodeURIComponent(userId), {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': 'Bearer ' + SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify({ modules: modulesArray })
      }).then(function(res) {
        console.log('[Supabase Sync] updateUserModules status:', res.status);
      }).catch(function(err) {
        console.warn('[Supabase Sync] Error updating modules:', err);
      });
    } catch(e) {}
  }

  function syncMvpProductToSupabase(productId) {
    if (typeof fetch === 'undefined') return;
    try {
      fetch(SUPABASE_URL + '/rest/v1/app_settings?key=eq.catalog_settings', {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': 'Bearer ' + SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify({ value: { mvpProductId: productId } })
      }).catch(function(err) {});
    } catch(e) {}
  }


  // 1. DEFAULT DATASET (MONOCHROME LUXURY STORE - RICH PUBLISHING SCHEMA)
  var DEFAULT_CATALOG = {
  "mvpProductId": "tf-g31-pro",
  "brand": {
    "name": "T-Flow",
    "logoText": "T-FLOW",
    "company": "Công ty TNHH Công nghệ T-Flow Việt Nam",
    "companyEn": "T-Flow Tech Co., Ltd.",
    "prefix": "TF",
    "sloganIntl": "Smooth Every Moment.",
    "sloganIntl2": "Flow With Your Story.",
    "sloganVi": "Mượt mà từng khoảnh khắc.",
    "sloganVi2": "Vững khung hình, Trọn cảm xúc.",
    "silkscreen1": "Engineered by T-Flow in Hanoi",
    "silkscreen2": "Pure FOC Inside - Zero Jitter",
    "address": "Tòa nhà Công nghệ T-Flow, Hà Nội, Việt Nam",
    "hotline": "1900 8888 (T-Flow Hotline)",
    "email": "contact@tflow.tech",
    "website": "https://gimbal-dashboard-tn.vercel.app"
  },
  "namingRules": [
    {
      "id": "rule-1",
      "title": "1. Quy tắc Tên Thương mại (B2C)",
      "formula": "T-Flow + [Tên Dòng] + [Hậu tố]",
      "desc": "Không dùng mã số phức tạp. Giữ tên gọi dưới 4 từ để hiển thị đẹp trên vỏ hộp, sàn TMĐT và ứng dụng di động.",
      "convention": "Hậu tố chuẩn: Go/Air (Gọn nhẹ, phổ thông) • Pro/Max (Cao cấp, tải nặng) • SE (Bản rút gọn giá tốt)",
      "example": "T-Flow Go, T-Flow Pro, T-Flow Air, T-Flow Eye"
    },
    {
      "id": "rule-2",
      "title": "2. Quy tắc Mã Kỹ thuật (SKU / In trên PCB)",
      "formula": "TF - [Phân hệ][Thông số] - [Chức năng] - [Rev]",
      "desc": "TF là tiền tố cố định của T-Flow. [Phân hệ]: G (Gimbal), CAM (Camera), M (Mainboard), D (Driver), X (Mạch mở rộng/Cảm biến), B (Bridge - Cầu nối).",
      "convention": "In lụa bắt buộc trên PCB: 'Engineered by T-Flow in Hanoi' & 'Pure FOC Inside - Zero Jitter'",
      "example": "TF-G31-PRO-R1.0, TF-D3X-FOC-R1.0, TF-CAM-AI01-R1.0"
    },
    {
      "id": "rule-3",
      "title": "3. Quy tắc Đánh mã Chi tiết Cơ khí / In 3D",
      "formula": "TF - [Mã Máy] - MEC - [Số thứ tự] - [Vật liệu]",
      "desc": "Dùng để quản lý các file CAD 3D, bản vẽ kỹ thuật 2D, file STL in 3D và chi tiết gia công CNC chính xác.",
      "convention": "Vật liệu: PETG (In 3D), AL6061 (Nhôm hàng không CNC), CF (Sợi Carbon dệt 8 lớp)",
      "example": "TF-G31-MEC-01-PETG, TF-G31-MEC-02-AL6061, TF-G31-MEC-03-CF"
    },
    {
      "id": "rule-4",
      "title": "4. Quy tắc Đặt tên Kho mã nguồn (GitHub / Firmware)",
      "formula": "tflow-[phân-hệ]-[loại-code]",
      "desc": "Viết thường toàn bộ, nối bằng dấu gạch ngang (-) để chuẩn hóa đường dẫn lập trình trên Git và CI/CD.",
      "convention": "Kho chính: tflow-g31-firmware, tflow-foc-library, tflow-cam-ios, tflow-studio-app",
      "example": "https://github.com/tflow-tech/tflow-g31-firmware"
    },
    {
      "id": "rule-5",
      "title": "5. Quy tắc Đánh số Phiên bản (Versioning)",
      "formula": "v[Major].[Minor].[Patch]",
      "desc": "Major: Thay đổi kiến trúc lớn • Minor: Thêm tính năng mới (Inception, FOC filter) • Patch: Sửa lỗi (Fix bug).",
      "convention": "Áp dụng đồng bộ cho Firmware phần cứng, Phần mềm máy tính và App điện thoại",
      "example": "FW-TF-G31-v1.2.0, FW-TF-D3X-v1.0.4, APP-v2.1.0"
    }
  ],
  "groups": [
    {
      "id": "group-gimbal",
      "name": "Gimbal Cầm Tay",
      "desc": "Thiết bị ổn định 3 trục cho điện thoại và máy quay, thuật toán FOC vi bước 20kHz, ngàm MagSafe và khung hợp kim hàng không",
      "badge": "B2C Chủ Lực"
    },
    {
      "id": "group-camera",
      "name": "Cụm Camera & Phụ Kiện AI",
      "desc": "Mô-đun nhận diện thị giác máy tính độc lập, camera zoom quang học và hệ sinh thái phụ kiện từ tính thông minh",
      "badge": "Thông Minh"
    },
    {
      "id": "group-core",
      "name": "Bo Mạch Điều Khiển Lõi",
      "desc": "Bo mạch chủ vi điều khiển 32-bit STM32 và mạch công suất điều khiển động cơ không chổi than 3 trục bằng thuật toán FOC",
      "badge": "R&D Phần Cứng"
    },
    {
      "id": "group-sensor",
      "name": "Bo Mạch Mở Rộng & Cảm Biến",
      "desc": "Mạch cảm biến gia tốc / con quay hồi chuyển IMU 6 trục, cảm biến từ Magnetic Encoder 14-bit và mạch cầu nối truyền thông",
      "badge": "Độ Phân Giải Cao"
    },
    {
      "id": "group-software",
      "name": "Phần Mềm & Ứng Dụng",
      "desc": "Ứng dụng quay chụp T-Flow Cam cho iOS/Android và phần mềm máy tính T-Flow Studio căn chỉnh PID, FOC và nạp Firmware",
      "badge": "Hệ Sinh Thái"
    }
  ],
  "products": [
    {
      "id": "tf-g31-pro",
      "sku": "TF-G31-PRO",
      "groupId": "group-gimbal",
      "name": "T-Flow Pro",
      "tagline": "Vững khung hình, Trọn cảm xúc. Đỉnh cao chống rung 3 trục chuyên nghiệp.",
      "subtitle": "Dòng Gimbal cao cấp cho nhà sáng tạo nội dung. Động cơ tải trọng 450g, tích hợp vòng xoay lấy nét Focus Wheel và khung sợi Carbon siêu nhẹ.",
      "badge": "Flagship B2C",
      "img": "../shared/img/feed_portrait_dusk.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 1850,
      "orderGrowth": "+24%",
      "is_flagship": true,
      "gallery": [
        "../shared/img/feed_portrait_dusk.jpg",
        "../shared/img/feed_portrait_day.jpg",
        "../shared/img/feed_person_portrait.jpg",
        "../shared/img/feed_land_dusk.jpg"
      ],
      "colors": [
        {
          "id": "carbon-black",
          "name": "Đen Carbon (Titanium)",
          "hex": "#1C1C1E"
        },
        {
          "id": "silver-frost",
          "name": "Bạc Ánh Kim (Silver Frost)",
          "hex": "#D1D1D6"
        },
        {
          "id": "deep-navy",
          "name": "Xanh Biển Sâu (Deep Navy)",
          "hex": "#1A2A3A"
        }
      ],
      "overview": [
        {
          "title": "Vòng Xoay Focus & Zoom Vật Lý Chính Xác Tuyệt Đối",
          "desc": "Vòng xoay CNC đa năng ở cạnh thân máy cho phép lấy nét mượt mà như ống kính máy quay điện ảnh chuyên nghiệp hoặc điều khiển tiêu cự zoom từng milimet mượt mà.",
          "img": "../shared/img/feed_person_portrait.jpg"
        },
        {
          "title": "Động Cơ Tải Trọng Lớn 450g & Thuật Toán Pure FOC 20kHz",
          "desc": "Cân mọi dòng điện thoại kích thước lớn kèm ống kính gắn ngoài và microphone không dây. Tần số điều chế vector 20kHz triệt tiêu hoàn toàn độ trễ và rung giật micro-jitter.",
          "img": "../shared/img/feed_portrait_day.jpg"
        },
        {
          "title": "Khung Thân Hợp Kim Nhôm Hàng Không Kết Hợp Sợi Carbon",
          "desc": "Vừa đạt độ cứng cáp và triệt tiêu rung động tối đa, vừa giữ trọng lượng thân gimbal ở mức tối ưu cho cả ngày quay liên tục không mỏi tay.",
          "img": "../shared/img/feed_portrait_dusk.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Thân Gimbal 3 trục T-Flow Pro (TF-G31-PRO)",
          "qty": "1 cái"
        },
        {
          "name": "Chân đế Tripod từ tính chống trượt hợp kim nhôm",
          "qty": "1 cái"
        },
        {
          "name": "Cáp sạc nhanh USB-C bện dù cao cấp (1.2m)",
          "qty": "1 sợi"
        },
        {
          "name": "Túi đựng chống sốc cao cấp chuẩn du lịch",
          "qty": "1 chiếc"
        },
        {
          "name": "Sách hướng dẫn tiếng Việt & Thẻ bảo hành chính hãng 24 tháng",
          "qty": "1 bộ"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-G31-PRO-R1.0"
        },
        {
          "label": "Tải Trọng Hỗ Trợ Tối Đa",
          "val": "450 g (Tương thích iPhone 13-16 Pro Max)"
        },
        {
          "label": "Dung Lượng Pin & Thời Gian Dùng",
          "val": "4800 mAh Li-ion (Dùng liên tục 18 giờ)"
        },
        {
          "label": "Thời Gian Sạc Đầy",
          "val": "2 giờ (Sạc nhanh USB-C PD 18W)"
        },
        {
          "label": "Cổng Giao Tiếp Mở Rộng",
          "val": "Cổng cấp nguồn USB-C 5V/1A cho điện thoại + Ren 1/4 inch"
        },
        {
          "label": "Kết Nối Không Dây",
          "val": "Bluetooth 5.3 Low Energy (Độ trễ < 8ms)"
        }
      ],
      "warranty": "Bảo hành chính hãng 24 tháng 1 đổi 1 trong 30 ngày đầu tiên tại Công ty TNHH Công nghệ T-Flow Việt Nam.",
      "tiers": [
        {
          "key": "tier-pro-std",
          "id": "tier-pro-std",
          "label": "Gói Tiêu Chuẩn (Standard)",
          "name": "Gói Tiêu Chuẩn (Standard)",
          "price": 2890000,
          "priceFormatted": "2.890.000₫",
          "sku": "TF-G31-PRO-STD",
          "badge": "Bán Chạy Nhất",
          "desc": "Thân T-Flow Pro + Chân đế Mini Tripod nhôm + Cáp sạc USB-C + Túi chống sốc",
          "is_featured": true,
          "highlights": [
            "Thân Gimbal T-Flow Pro động cơ FOC 20kHz tải 450g",
            "Vòng xoay cơ khí Focus Wheel kim loại CNC",
            "Chân đế Tripod hợp kim nhôm bọc silicon chống trượt",
            "Bảo hành 24 tháng chính hãng T-Flow Tech"
          ]
        },
        {
          "key": "tier-pro-combo",
          "id": "tier-pro-combo",
          "label": "Combo Sáng Tạo (Creator Kit)",
          "name": "Combo Sáng Tạo (Creator Kit)",
          "price": 3490000,
          "priceFormatted": "3.490.000₫",
          "sku": "TF-G31-PRO-COMBO",
          "badge": "Khuyên Dùng",
          "desc": "T-Flow Pro + Mô-đun Camera AI T-Flow Eye (TF-CAM-AI01) + Đèn trợ sáng T-Flow Glow",
          "is_featured": false,
          "highlights": [
            "Bao gồm toàn bộ Gói Tiêu Chuẩn",
            "Mô-đun Camera AI T-Flow Eye bám nét độc lập không cần App",
            "Đèn trợ sáng từ tính T-Flow Glow CRI 95+ 3 dải màu",
            "Tặng kèm túi đeo chéo chống nước cao cấp"
          ]
        },
        {
          "key": "tier-pro-cine",
          "id": "tier-pro-cine",
          "label": "Combo Điện Ảnh (Cinematic Master)",
          "name": "Combo Điện Ảnh (Cinematic Master)",
          "price": 4290000,
          "priceFormatted": "4.290.000₫",
          "sku": "TF-G31-PRO-CINE",
          "badge": "Chuyên Nghiệp",
          "desc": "Trọn bộ T-Flow Pro + T-Flow Eye AI + T-Flow Glow + Vali nhôm chống nước IP67 + Micro không dây 2.4GHz",
          "is_featured": false,
          "highlights": [
            "Trọn bộ thiết bị cao cấp nhất của hệ sinh thái T-Flow",
            "Vali hợp kim nhôm đúc chống va đập chuẩn hàng không IP67",
            "Bộ Micro thu âm không dây 2.4GHz kép cự ly 100m",
            "Gói dịch vụ bảo hành vàng 24 tháng đổi mới ngay lập tức"
          ]
        }
      ]
    },
    {
      "id": "tf-g31-go",
      "sku": "TF-G31-GO",
      "groupId": "group-gimbal",
      "name": "T-Flow Go",
      "tagline": "Mượt mà từng khoảnh khắc. Người bạn đồng hành vlog lý tưởng.",
      "subtitle": "Bản tiêu chuẩn 3 trục cho điện thoại; thiết kế thanh thoát, cân bằng tự động trong 3 giây, hoàn hảo cho du lịch, dạo phố và livestream.",
      "badge": "Bán Chạy",
      "img": "../shared/img/feed_portrait_day.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 3210,
      "orderGrowth": "+32%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_portrait_day.jpg",
        "../shared/img/feed_portrait_dusk.jpg",
        "../shared/img/feed_land_dusk.jpg"
      ],
      "colors": [
        {
          "id": "frost-white",
          "name": "Trắng Tinh Khôi (Frost White)",
          "hex": "#F2F2F7"
        },
        {
          "id": "space-gray",
          "name": "Xám Không Gian (Space Gray)",
          "hex": "#3A3A3C"
        }
      ],
      "overview": [
        {
          "title": "Cân Bằng Tự Động Trong 3 Giây",
          "desc": "Chỉ cần gắn điện thoại lên ngàm, bật nguồn và hệ thống tự động nhận diện trọng tâm và kích hoạt động cơ FOC êm ái.",
          "img": "../shared/img/feed_portrait_day.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Gimbal 3 trục T-Flow Go (TF-G31-GO)",
          "qty": "1 cái"
        },
        {
          "name": "Chân đế mini tripod để bàn",
          "qty": "1 cái"
        },
        {
          "name": "Cáp sạc USB Type-C",
          "qty": "1 sợi"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-G31-GO-R1.0"
        },
        {
          "label": "Tải Trọng Tối Đa",
          "val": "300 g"
        },
        {
          "label": "Pin",
          "val": "10 giờ liên tục (3000 mAh)"
        },
        {
          "label": "Trọng Lượng Thân Máy",
          "val": "380 g"
        }
      ],
      "warranty": "Bảo hành chính hãng 18 tháng.",
      "tiers": [
        {
          "key": "tier-go-std",
          "id": "tier-go-std",
          "label": "Bản Đơn (Standard)",
          "name": "Bản Đơn (Standard)",
          "price": 1490000,
          "priceFormatted": "1.490.000₫",
          "sku": "TF-G31-GO-STD",
          "badge": "Giá Tốt Nhất",
          "desc": "Gimbal T-Flow Go + Mini Tripod + Cáp sạc",
          "is_featured": true,
          "highlights": [
            "Gimbal 3 trục cân bằng tự động",
            "Chuyển ngang dọc 1 nút",
            "Pin 10 giờ"
          ]
        },
        {
          "key": "tier-go-combo",
          "id": "tier-go-combo",
          "label": "Bản Vlogger Kit",
          "name": "Bản Vlogger Kit",
          "price": 1890000,
          "priceFormatted": "1.890.000₫",
          "sku": "TF-G31-GO-COMBO",
          "badge": "Được Mua Nhiều",
          "desc": "T-Flow Go + Đèn LED từ tính T-Flow Glow + Túi đựng",
          "is_featured": false,
          "highlights": [
            "Bao gồm gimbal T-Flow Go",
            "Kèm đèn LED T-Flow Glow",
            "Túi nỉ đựng máy du lịch"
          ]
        }
      ]
    },
    {
      "id": "tf-g21-air",
      "sku": "TF-G21-AIR",
      "groupId": "group-gimbal",
      "name": "T-Flow Air",
      "tagline": "Siêu nhẹ bỏ túi. Sẵn sàng bắt trọn mọi chuyển động.",
      "subtitle": "Bản gập gọn siêu cơ động bỏ vừa túi quần; trọng lượng chỉ 285g, tích hợp gậy kéo dài 21cm, tối ưu cho du lịch và thao tác một chạm.",
      "badge": "Siêu Gọn Nhẹ",
      "img": "../shared/img/feed_land_dusk.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 2100,
      "orderGrowth": "+19%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_land_dusk.jpg"
      ],
      "colors": [
        {
          "id": "pastel-pink",
          "name": "Hồng Phấn (Blush)",
          "hex": "#E0A899"
        },
        {
          "id": "pure-black",
          "name": "Đen Mờ (Matte Black)",
          "hex": "#222222"
        }
      ],
      "overview": [
        {
          "title": "Thiết Kế Khớp Gập Đột Phá Bỏ Túi Gọn Gàng",
          "desc": "Khi gấp lại máy chỉ dài 16cm, mang theo bên mình mọi lúc mọi nơi.",
          "img": "../shared/img/feed_land_dusk.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Gimbal gập gọn T-Flow Air (TF-G21-AIR)",
          "qty": "1 cái"
        },
        {
          "name": "Cáp sạc USB-C & Dây đeo tay",
          "qty": "1 bộ"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-G21-AIR-R1.0"
        },
        {
          "label": "Trọng Lượng",
          "val": "285 g"
        },
        {
          "label": "Pin",
          "val": "8 giờ liên tục"
        }
      ],
      "warranty": "Bảo hành chính hãng 12 tháng.",
      "tiers": [
        {
          "key": "tier-air-std",
          "id": "tier-air-std",
          "label": "Bản Tiêu Chuẩn",
          "name": "Bản Tiêu Chuẩn",
          "price": 1190000,
          "priceFormatted": "1.190.000₫",
          "sku": "TF-G21-AIR-STD",
          "badge": "Giá Tốt",
          "desc": "T-Flow Air + Cáp sạc USB-C + Dây đeo cổ tay",
          "is_featured": true,
          "highlights": [
            "Siêu nhẹ 285g",
            "Gập gọn 16cm",
            "Kéo dài 21cm"
          ]
        }
      ]
    },
    {
      "id": "tf-cam-ai01",
      "sku": "TF-CAM-AI01",
      "groupId": "group-camera",
      "name": "T-Flow Eye",
      "tagline": "Mắt thần AI thông minh. Tự động bám nét độc lập không cần App.",
      "subtitle": "Mô-đun camera AI gắn rời từ tính; tích hợp chip NPU xử lý thị giác trực tiếp tại biên, nhận diện cử chỉ tay (OK để theo dõi, Giơ tay để dừng) trên mọi ứng dụng.",
      "badge": "Bán Chạy Nhất",
      "img": "../shared/img/feed_person_portrait.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 1650,
      "orderGrowth": "+45%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_person_portrait.jpg"
      ],
      "colors": [
        {
          "id": "titanium-gray",
          "name": "Xám Titan",
          "hex": "#48484A"
        }
      ],
      "overview": [
        {
          "title": "Bám Bắt Đối Tượng Độc Lập Hoàn Toàn",
          "desc": "Không cần cài đặt ứng dụng, cắm trực tiếp lên gimbal và tương thích ngay với Camera mặc định, TikTok, Facebook Live, Zoom...",
          "img": "../shared/img/feed_person_portrait.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Mô-đun camera AI T-Flow Eye",
          "qty": "1 cái"
        },
        {
          "name": "Ngàm kẹp từ tính",
          "qty": "1 chiếc"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-CAM-AI01-R1.0"
        },
        {
          "label": "Tốc Độ Nhận Diện NPU",
          "val": "60 khung hình/giây (Độ trễ < 15ms)"
        },
        {
          "label": "Góc Nhìn Cảm Biến AI",
          "val": "110 độ góc rộng"
        }
      ],
      "warranty": "Bảo hành 12 tháng.",
      "tiers": [
        {
          "key": "tier-eye-std",
          "id": "tier-eye-std",
          "label": "Bản Đơn T-Flow Eye",
          "name": "Bản Đơn T-Flow Eye",
          "price": 890000,
          "priceFormatted": "890.000₫",
          "sku": "TF-CAM-AI01-STD",
          "badge": "Phụ Kiện Hot",
          "desc": "Mô-đun AI T-Flow Eye + Ngàm từ tính gắn kẹp",
          "is_featured": true,
          "highlights": [
            "Bám nét AI 60fps",
            "Cử chỉ bàn tay thông minh",
            "Không cần cài App"
          ]
        }
      ]
    },
    {
      "id": "tf-cam-z30",
      "sku": "TF-CAM-Z30",
      "groupId": "group-camera",
      "name": "T-Flow Optix Z30",
      "tagline": "Cụm camera zoom quang học 30x chuyên dụng độ nét 4K.",
      "subtitle": "Dành riêng cho dòng T-Flow Pro và các hệ thống trinh sát, quan sát đặc thù; tích hợp hệ thấu kính quang học chống rung và truyền tín hiệu không nén.",
      "badge": "Chuyên Nghiệp",
      "img": "../shared/img/feed_land_dusk.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 420,
      "orderGrowth": "+12%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_land_dusk.jpg"
      ],
      "colors": [
        {
          "id": "black-anodized",
          "name": "Đen Anodized",
          "hex": "#111111"
        }
      ],
      "overview": [
        {
          "title": "Zoom Quang Học 30x Không Suy Giảm Chi Tiết",
          "desc": "Cảm biến Sony CMOS 1/2.8 inch kết hợp thấu kính tán xạ thấp ED sắc nét.",
          "img": "../shared/img/feed_land_dusk.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Cụm camera T-Flow Optix Z30",
          "qty": "1 cái"
        },
        {
          "name": "Cáp truyền dữ liệu vi sai LVDS",
          "qty": "1 sợi"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-CAM-Z30-R1.0"
        },
        {
          "label": "Độ Phân Giải",
          "val": "4K Ultra HD @ 60fps"
        },
        {
          "label": "Tỉ Lệ Zoom",
          "val": "30x Quang học (Optical Zoom)"
        }
      ],
      "warranty": "Bảo hành 24 tháng.",
      "tiers": [
        {
          "key": "tier-optix-std",
          "id": "tier-optix-std",
          "label": "Cụm Camera Độc Lập",
          "name": "Cụm Camera Độc Lập",
          "price": 2490000,
          "priceFormatted": "2.490.000₫",
          "sku": "TF-CAM-Z30-STD",
          "badge": "Dành Cho Pro",
          "desc": "Mô-đun Camera Zoom Z30 + Cáp giao tiếp",
          "is_featured": true,
          "highlights": [
            "Zoom quang học 30x",
            "Độ phân giải 4K",
            "Truyền LVDS không nén"
          ]
        }
      ]
    },
    {
      "id": "tf-acc-led01",
      "sku": "TF-ACC-LED01",
      "groupId": "group-camera",
      "name": "T-Flow Glow",
      "tagline": "Đèn trợ sáng từ tính CRI 95+. Rạng rỡ trong mọi bóng đêm.",
      "subtitle": "Đèn trợ sáng gắn ngàm từ tính siêu mỏng; tùy chỉnh 3 dải nhiệt độ màu (3000K - 6500K) và 10 cấp độ sáng mượt mà.",
      "badge": "Phụ Kiện",
      "img": "../shared/img/feed_portrait_dusk.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 1980,
      "orderGrowth": "+28%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_portrait_dusk.jpg"
      ],
      "colors": [
        {
          "id": "pearl-white",
          "name": "Trắng Ngọc Trai",
          "hex": "#EEEEEE"
        }
      ],
      "overview": [
        {
          "title": "Chỉ Số Hoàn Màu Điện Ảnh CRI 95+",
          "desc": "Đảm bảo tông màu da hồng hào tự nhiên, không bị ám xanh khi quay ban đêm.",
          "img": "../shared/img/feed_portrait_dusk.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Đèn trợ sáng T-Flow Glow",
          "qty": "1 cái"
        },
        {
          "name": "Cáp sạc USB-C mini",
          "qty": "1 sợi"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-ACC-LED01-R1.0"
        },
        {
          "label": "Chỉ Số Hoàn Màu",
          "val": "CRI >= 95"
        },
        {
          "label": "Nhiệt Độ Màu",
          "val": "3000K - 4500K - 6500K"
        }
      ],
      "warranty": "Bảo hành 12 tháng 1 đổi 1.",
      "tiers": [
        {
          "key": "tier-glow-std",
          "id": "tier-glow-std",
          "label": "Đèn Đơn T-Flow Glow",
          "name": "Đèn Đơn T-Flow Glow",
          "price": 390000,
          "priceFormatted": "390.000₫",
          "sku": "TF-ACC-LED01-STD",
          "badge": "Giá Tốt",
          "desc": "Đèn T-Flow Glow + Cáp sạc",
          "is_featured": true,
          "highlights": [
            "CRI 95+ điện ảnh",
            "Ngàm hít từ tính",
            "3 dải nhiệt độ màu"
          ]
        }
      ]
    },
    {
      "id": "tf-m32-main",
      "sku": "TF-M32-MAIN",
      "groupId": "group-core",
      "name": "T-Flow Core 32",
      "tagline": "Trái tim tính toán nhúng 32-bit. Engineered by T-Flow in Hanoi.",
      "subtitle": "Bo mạch chủ điều khiển trung tâm sử dụng vi điều khiển 32-bit STM32 ARM Cortex-M4/G4, tích hợp bộ giải mã kép và giao tiếp CAN Bus công nghiệp.",
      "badge": "Linh Kiện Lõi",
      "img": "../shared/img/feed_portrait_day.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 850,
      "orderGrowth": "+15%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_portrait_day.jpg"
      ],
      "colors": [
        {
          "id": "pcb-black",
          "name": "Đen Mạ Vàng (ENIG Matte Black)",
          "hex": "#242424"
        }
      ],
      "overview": [
        {
          "title": "Chữ Ký Kỹ Thuật In Lụa Trên Bo Mạch",
          "desc": "In lụa 'Engineered by T-Flow in Hanoi' và 'Pure FOC Inside - Zero Jitter' khẳng định bản quyền thiết kế R&D chuẩn mực.",
          "img": "../shared/img/feed_portrait_day.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Bo mạch T-Flow Core 32 (TF-M32-MAIN-R1.0)",
          "qty": "1 bo"
        },
        {
          "name": "Bộ cáp bẹ JST SH 1.0mm chống nhiễu",
          "qty": "1 bộ"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-M32-MAIN-R1.0"
        },
        {
          "label": "Vi Điều Khiển Lõi",
          "val": "STM32 32-bit ARM Cortex-M 170MHz"
        },
        {
          "label": "Chữ Ký Silkscreen",
          "val": "Engineered by T-Flow in Hanoi"
        }
      ],
      "warranty": "Bảo hành kỹ thuật 12 tháng.",
      "tiers": [
        {
          "key": "tier-core32-std",
          "id": "tier-core32-std",
          "label": "Bo Mạch Tiêu Chuẩn R1.0",
          "name": "Bo Mạch Tiêu Chuẩn R1.0",
          "price": 750000,
          "priceFormatted": "750.000₫",
          "sku": "TF-M32-MAIN-R1.0",
          "badge": "R&D",
          "desc": "Bo mạch chính T-Flow Core 32 + Jack kết nối",
          "is_featured": true,
          "highlights": [
            "STM32 32-bit 170MHz",
            "Giao tiếp CAN Bus 2.0B",
            "Chữ ký Silkscreen Hanoi"
          ]
        }
      ]
    },
    {
      "id": "tf-d3x-foc",
      "sku": "TF-D3X-FOC",
      "groupId": "group-core",
      "name": "T-Flow Drive 3X",
      "tagline": "Pure FOC Inside — Zero Jitter. Mạch điều khiển động cơ 3 trục đỉnh cao.",
      "subtitle": "Mạch công suất điều khiển 3 động cơ BLDC không chổi than bằng thuật toán điều khiển định hướng từ trường FOC SVPWM, cảm biến dòng điện shunt độ chính xác cao.",
      "badge": "Hiệu Năng Cao",
      "img": "../shared/img/feed_portrait_dusk.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 920,
      "orderGrowth": "+21%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_portrait_dusk.jpg"
      ],
      "colors": [
        {
          "id": "pcb-black",
          "name": "Đen Carbon (ENIG Gold)",
          "hex": "#1E1E1E"
        }
      ],
      "overview": [
        {
          "title": "Điều Khiển Định Hướng Từ Trường FOC Triệt Tiêu Độ Rung",
          "desc": "Vòng lặp điều khiển dòng điện 20kHz giúp động cơ hoạt động siêu êm và phản ứng tức thì.",
          "img": "../shared/img/feed_portrait_dusk.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Bo mạch công suất T-Flow Drive 3X (TF-D3X-FOC)",
          "qty": "1 bo"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-D3X-FOC-R1.0"
        },
        {
          "label": "Số Kênh Điều Khiển",
          "val": "3 Kênh Động Cơ Không Chổi Than (BLDC)"
        },
        {
          "label": "Thuật Toán Nhúng",
          "val": "Pure FOC SVPWM 20kHz"
        }
      ],
      "warranty": "Bảo hành 12 tháng.",
      "tiers": [
        {
          "key": "tier-drive3x-std",
          "id": "tier-drive3x-std",
          "label": "Bo Mạch Driver FOC 3 Trục",
          "name": "Bo Mạch Driver FOC 3 Trục",
          "price": 950000,
          "priceFormatted": "950.000₫",
          "sku": "TF-D3X-FOC-R1.0",
          "badge": "Chính Hãng",
          "desc": "Bo mạch T-Flow Drive 3X + Tản nhiệt nhôm đùn nguyên khối",
          "is_featured": true,
          "highlights": [
            "Điều khiển FOC 3 trục 20kHz",
            "Dòng đỉnh 5A mỗi trục",
            "Khử rung Zero Jitter"
          ]
        }
      ]
    },
    {
      "id": "tf-x-imu6",
      "sku": "TF-X-IMU6",
      "groupId": "group-sensor",
      "name": "T-Flow Sense IMU",
      "tagline": "Cảm biến đo góc nghiêng 6 trục độ ồn siêu thấp đặt tại kẹp camera.",
      "subtitle": "Tích hợp cảm biến gia tốc và con quay hồi chuyển MEMS 6 trục độ nhạy cao, giao tiếp SPI tốc độ cao 10MHz truyền dữ liệu trực tiếp về bộ lọc Kalman của bộ điều khiển.",
      "badge": "Cảm Biến",
      "img": "../shared/img/feed_land_dusk.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 1400,
      "orderGrowth": "+17%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_land_dusk.jpg"
      ],
      "colors": [
        {
          "id": "pcb-green",
          "name": "Đen Nhám (Matte)",
          "hex": "#1F1F1F"
        }
      ],
      "overview": [
        {
          "title": "Đo Góc Tuyệt Đối Với Độ Nhiễu Cực Thấp",
          "desc": "Bộ lọc phần cứng tích hợp khử nhiễu nhiệt và dao động cơ khí tần số cao.",
          "img": "../shared/img/feed_land_dusk.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Mạch cảm biến T-Flow Sense IMU",
          "qty": "1 cái"
        },
        {
          "name": "Cáp tín hiệu xoắn chống nhiễu",
          "qty": "1 sợi"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-X-IMU6-R1.0"
        },
        {
          "label": "Trục Cảm Biến",
          "val": "3 trục Con quay (Gyro) + 3 trục Gia tốc (Accel)"
        }
      ],
      "warranty": "Bảo hành 12 tháng.",
      "tiers": [
        {
          "key": "tier-imu6-std",
          "id": "tier-imu6-std",
          "label": "Module Cảm Biến IMU 6 Trục",
          "name": "Module Cảm Biến IMU 6 Trục",
          "price": 290000,
          "priceFormatted": "290.000₫",
          "sku": "TF-X-IMU6-R1.0",
          "badge": "Linh Kiện",
          "desc": "Mạch T-Flow Sense IMU + Cáp mềm dẻo chịu xoắn",
          "is_featured": true,
          "highlights": [
            "IMU 6 trục độ ồn thấp",
            "Giao tiếp SPI 10MHz",
            "Gắn cụm kẹp camera"
          ]
        }
      ]
    },
    {
      "id": "tf-x-enc14",
      "sku": "TF-X-ENC14",
      "groupId": "group-sensor",
      "name": "T-Flow Sense ENC",
      "tagline": "Cảm biến từ Magnetic Encoder 14-bit (16.384 xung/vòng) gắn sau trục động cơ.",
      "subtitle": "Đo góc quay rotor độ phân giải 14-bit không tiếp xúc; giao tiếp SSI/PWM/I2C phản hồi tức thời vị trí góc cho thuật toán FOC.",
      "badge": "Chính Xác Cao",
      "img": "../shared/img/feed_portrait_day.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 1780,
      "orderGrowth": "+22%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_portrait_day.jpg"
      ],
      "colors": [
        {
          "id": "pcb-black",
          "name": "Đen Vi Mạch",
          "hex": "#1A1A1A"
        }
      ],
      "overview": [
        {
          "title": "Độ Phân Giải 16.384 Bước Cho Mỗi Vòng Quay 360 Độ",
          "desc": "Triệt tiêu sai số vị trí, giúp động cơ giữ vững góc mà không bị rùng.",
          "img": "../shared/img/feed_portrait_day.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Mạch encoder T-Flow Sense ENC",
          "qty": "1 bo"
        },
        {
          "name": "Nam châm từ tính hướng kính Neodymium",
          "qty": "1 viên"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-X-ENC14-R1.0"
        },
        {
          "label": "Độ Phân Giải Góc",
          "val": "14-bit (0.0219 độ/bước)"
        }
      ],
      "warranty": "Bảo hành 12 tháng.",
      "tiers": [
        {
          "key": "tier-enc14-std",
          "id": "tier-enc14-std",
          "label": "Mạch Cảm Biến Từ 14-bit",
          "name": "Mạch Cảm Biến Từ 14-bit",
          "price": 320000,
          "priceFormatted": "320.000₫",
          "sku": "TF-X-ENC14-R1.0",
          "badge": "Linh Kiện",
          "desc": "Bo mạch Encoder + Nam châm từ tính phân cực hướng kính",
          "is_featured": true,
          "highlights": [
            "Độ phân giải 14-bit 16.384 xung",
            "Không tiếp xúc ma sát",
            "Tần số quét 50kHz"
          ]
        }
      ]
    },
    {
      "id": "tf-b-lvds2hd",
      "sku": "TF-B-LVDS2HD",
      "groupId": "group-sensor",
      "name": "T-Flow Link",
      "tagline": "Cầu nối chuyển đổi tín hiệu hình ảnh & mở rộng giao tiếp CAN/UART/USB-C.",
      "subtitle": "Bo mạch cầu nối chuyên dụng nhận luồng vi sai LVDS từ cụm camera và chuyển đổi sang cổng ra HDMI / Type-C cho màn hình phụ hoặc bộ phát sóng không dây.",
      "badge": "Cầu Nối",
      "img": "../shared/img/feed_portrait_dusk.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 610,
      "orderGrowth": "+9%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_portrait_dusk.jpg"
      ],
      "colors": [
        {
          "id": "pcb-black",
          "name": "Đen Nhám",
          "hex": "#1E1E1E"
        }
      ],
      "overview": [
        {
          "title": "Chuyển Đổi Video Không Độ Trễ (Zero Latency)",
          "desc": "Truyền trực tiếp tín hiệu 1080p/4K từ đầu trục xoay gimbal xuống thân máy qua cổ góp điện trượt Slip-ring.",
          "img": "../shared/img/feed_portrait_dusk.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Bo mạch chuyển đổi T-Flow Link",
          "qty": "1 bo"
        }
      ],
      "specs": [
        {
          "label": "Mã Kỹ Thuật (SKU / PCB)",
          "val": "TF-B-LVDS2HD-R1.0"
        },
        {
          "label": "Ngõ Vào / Ra",
          "val": "LVDS 4-ch / Micro HDMI / USB-C UVC"
        }
      ],
      "warranty": "Bảo hành 12 tháng.",
      "tiers": [
        {
          "key": "tier-link-std",
          "id": "tier-link-std",
          "label": "Mạch T-Flow Link R1.0",
          "name": "Mạch T-Flow Link R1.0",
          "price": 450000,
          "priceFormatted": "450.000₫",
          "sku": "TF-B-LVDS2HD-R1.0",
          "badge": "Kỹ Thuật",
          "desc": "Mạch chuyển đổi tín hiệu + Cáp FFC 30-pin mạ vàng",
          "is_featured": true,
          "highlights": [
            "Chuyển đổi LVDS sang HDMI",
            "Zero latency không trễ",
            "Hỗ trợ slip-ring"
          ]
        }
      ]
    },
    {
      "id": "tf-app-ios",
      "sku": "TF-APP-IOS",
      "groupId": "group-software",
      "name": "T-Flow Cam",
      "tagline": "Ứng dụng quay chụp điện ảnh thông minh trên iPhone & Android.",
      "subtitle": "Khai phóng toàn bộ sức mạnh phần cứng gimbal: Quay 4K/60fps ProRes, nhận diện khuôn mặt và chủ thể AI 60fps, chế độ quay Inception 360 độ và Dolly Zoom mượt mà.",
      "badge": "App Miễn Phí",
      "img": "../shared/img/feed_portrait_day.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 12500,
      "orderGrowth": "+80%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_portrait_day.jpg"
      ],
      "colors": [
        {
          "id": "app-dark",
          "name": "Apple HIG Dark Mode",
          "hex": "#000000"
        }
      ],
      "overview": [
        {
          "title": "Bám Bắt Chủ Thể Bằng Apple Vision & NPU Tại Biên",
          "desc": "Tự động khóa khung hình vào khuôn mặt hoặc vật thể được khoanh vùng ở 60 khung hình/giây.",
          "img": "../shared/img/feed_portrait_day.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Ứng dụng tải trực tiếp từ Apple App Store / Google Play",
          "qty": "Bản quyền số"
        }
      ],
      "specs": [
        {
          "label": "Mã Sản Phẩm",
          "val": "TF-APP-IOS / AND"
        },
        {
          "label": "Tương Thích",
          "val": "iOS 16+ / iOS 17 / iOS 18 / iOS 27 & Android 12+"
        }
      ],
      "warranty": "Cập nhật tính năng miễn phí trọn đời.",
      "tiers": [
        {
          "key": "tier-app-free",
          "id": "tier-app-free",
          "label": "Bản Miễn Phí (Standard)",
          "name": "Bản Miễn Phí (Standard)",
          "price": 0,
          "priceFormatted": "Miễn Phí",
          "sku": "TF-APP-FREE",
          "badge": "Miễn Phí",
          "desc": "Tải miễn phí với đầy đủ chế độ quay chụp, điều khiển FOC và kết nối Bluetooth",
          "is_featured": true,
          "highlights": [
            "Quay 4K/60fps",
            "Theo dõi khuôn mặt AI",
            "Chế độ Inception 360"
          ]
        },
        {
          "key": "tier-app-pro",
          "id": "tier-app-pro",
          "label": "Gói Hội Viên Pro Creator (Trọn Đời)",
          "name": "Gói Hội Viên Pro Creator (Trọn Đời)",
          "price": 499000,
          "priceFormatted": "499.000₫",
          "sku": "TF-APP-PRO-VIP",
          "badge": "Đặc Quyền",
          "desc": "Mở khóa quay Apple ProRes 4K, lưu trữ đám mây Cloud AI 500GB, LUTs màu điện ảnh độc quyền",
          "is_featured": false,
          "highlights": [
            "Ghi hình Apple ProRes 4K",
            "500GB Cloud AI Storage",
            "Bộ LUTs màu điện ảnh"
          ]
        }
      ]
    },
    {
      "id": "tf-sw-studio",
      "sku": "TF-SW-STUDIO",
      "groupId": "group-software",
      "name": "T-Flow Studio",
      "tagline": "Phần mềm máy tính căn chỉnh chuyên sâu FOC, PID và cập nhật Firmware.",
      "subtitle": "Công cụ đồ họa chuyên nghiệp cho kỹ sư và người dùng nâng cao trên macOS & Windows: Vẽ đồ thị phản hồi thời gian thực, tinh chỉnh hệ số PID từng trục và nạp Firmware OTA.",
      "badge": "Phần Mềm PC",
      "img": "../shared/img/feed_portrait_dusk.jpg",
      "status": "Đang Mở Bán",
      "totalOrders": 3400,
      "orderGrowth": "+35%",
      "is_flagship": false,
      "gallery": [
        "../shared/img/feed_portrait_dusk.jpg"
      ],
      "colors": [
        {
          "id": "studio-dark",
          "name": "Giao Diện Dark Kỹ Thuật",
          "hex": "#121212"
        }
      ],
      "overview": [
        {
          "title": "Hiệu Chỉnh Tham Số PID & FOC Trực Quan",
          "desc": "Tự động phân tích dao động tần số tự nhiên và tối ưu thông số PID.",
          "img": "../shared/img/feed_portrait_dusk.jpg"
        }
      ],
      "boxContents": [
        {
          "name": "Bộ cài đặt phần mềm T-Flow Studio (macOS / Windows)",
          "qty": "Bản quyền số"
        }
      ],
      "specs": [
        {
          "label": "Mã Sản Phẩm",
          "val": "TF-SW-STUDIO"
        },
        {
          "label": "Hệ Điều Hành",
          "val": "macOS 12+ (Apple Silicon & Intel) / Windows 10/11 64-bit"
        }
      ],
      "warranty": "Cập nhật miễn phí trọn đời.",
      "tiers": [
        {
          "key": "tier-studio-free",
          "id": "tier-studio-free",
          "label": "Bản Studio Miễn Phí",
          "name": "Bản Studio Miễn Phí",
          "price": 0,
          "priceFormatted": "Miễn Phí",
          "sku": "TF-SW-STUDIO-FREE",
          "badge": "Miễn Phí",
          "desc": "Bản chuẩn cho mọi khách hàng sở hữu phần cứng T-Flow",
          "is_featured": true,
          "highlights": [
            "Đồ thị phản hồi FOC trực quan",
            "Căn chỉnh PID 3 trục",
            "Nạp Firmware OTA an toàn"
          ]
        }
      ]
    }
  ],
  "users": [
    {
      "id": "thuy-nguyen",
      "name": "Thuy Nguyen",
      "email": "thuy.nguyen@tflow.tech",
      "phone": "0908 888 888",
      "role": "Nhà Sáng Lập & Kỹ Sư Trưởng",
      "company": "Công ty TNHH Công nghệ T-Flow Việt Nam",
      "tierBadge": "VIP Founder",
      "registeredDevice": "T-Flow Pro (TF-G31-PRO)",
      "serial": "HQYVYFYFR4",
      "battery": 98,
      "firmware": "FW-TF-G31-v1.2.0 (Mới nhất)",
      "status": "Đang Hoạt Động",
      "modules": [
        true,
        true,
        true,
        true,
        true,
        true,
        true
      ]
    },
    {
      "id": "creator-pro",
      "name": "Minh Tuấn (Kỹ Sư Phần Cứng)",
      "email": "tuan.m@tflow.tech",
      "phone": "0912 345 678",
      "role": "Trưởng Nhóm Bo Mạch & FOC",
      "company": "T-Flow Tech",
      "tierBadge": "Hardware Team",
      "registeredDevice": "T-Flow Drive 3X (TF-D3X-FOC)",
      "serial": "HQYVYF2026M",
      "battery": 100,
      "firmware": "FW-TF-D3X-v1.0.4",
      "status": "Đang Hoạt Động",
      "modules": [
        true,
        true,
        true,
        true,
        false,
        true,
        false
      ]
    }
  ]
};

  // 2. CORE STORAGE HELPERS
  function getCatalog() {
    if (typeof localStorage === 'undefined') return DEFAULT_CATALOG;
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(DEFAULT_CATALOG));
        return JSON.parse(JSON.stringify(DEFAULT_CATALOG));
      }
      var parsed = JSON.parse(raw);
      if (!parsed.products || !parsed.groups) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(DEFAULT_CATALOG));
        return JSON.parse(JSON.stringify(DEFAULT_CATALOG));
      }
      // Ensure users exist
      if (!parsed.users || parsed.users.length === 0) {
        parsed.users = DEFAULT_CATALOG.users;
        localStorage.setItem(STORAGE_KEY, JSON.stringify(parsed));
      }
      return parsed;
    } catch (e) {
      console.warn('[SmartGimbalCatalog] Error parsing storage, falling back to default:', e);
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

    // Cross-iframe communication
    try {
      var frames = window.parent && window.parent.frames ? window.parent.frames : [];
      for (var i = 0; i < frames.length; i++) {
        try {
          frames[i].postMessage({ type: 'SMART_GIMBAL_CATALOG_SYNC', catalog: catalogData }, '*');
        } catch (err) {}
      }
    } catch (e) {}
  }

  // 3. MVP SPOTLIGHT API
  function getMvpProductId() {
    var cat = getCatalog();
    return cat.mvpProductId || "s1";
  }

  function setMvpProduct(productId) {
    var cat = getCatalog();
    var exists = cat.products.some(function (p) { return p.id === productId; });
    if (!exists) return false;

    cat.mvpProductId = productId;
    cat.products.forEach(function (p) {
      p.is_flagship = (p.id === productId);
    });
    saveCatalog(cat);
    return true;
  }

  function getMvpProduct() {
    var cat = getCatalog();
    var mvpId = cat.mvpProductId || "s1";
    var prod = cat.products.find(function (p) { return p.id === mvpId; });
    return prod || cat.products[0] || null;
  }

  // 4. GROUPS CRUD
  function getGroups() {
    return getCatalog().groups || [];
  }

  function getGroup(groupId) {
    return getGroups().find(function (g) { return g.id === groupId; }) || null;
  }

  function addGroup(groupObj) {
    var cat = getCatalog();
    if (!groupObj.id) {
      groupObj.id = 'cat-' + Date.now();
    }
    cat.groups.push(groupObj);
    saveCatalog(cat);
    return groupObj;
  }

  function updateGroup(groupId, updateData) {
    var cat = getCatalog();
    var idx = cat.groups.findIndex(function (g) { return g.id === groupId; });
    if (idx === -1) return false;
    cat.groups[idx] = Object.assign({}, cat.groups[idx], updateData);
    saveCatalog(cat);
    return cat.groups[idx];
  }

  function deleteGroup(groupId) {
    var cat = getCatalog();
    cat.groups = cat.groups.filter(function (g) { return g.id !== groupId; });
    cat.products.forEach(function (p) {
      if (p.groupId === groupId) {
        p.groupId = 'cat-phone';
      }
    });
    saveCatalog(cat);
    return true;
  }

  // 5. PRODUCTS CRUD
  function getProducts(groupId) {
    var list = getCatalog().products || [];
    if (groupId && groupId !== 'all') {
      return list.filter(function (p) { return p.groupId === groupId; });
    }
    return list;
  }

  function getProduct(productId) {
    return (getCatalog().products || []).find(function (p) { return p.id === productId; }) || null;
  }

  function addProduct(prodObj) {
    var cat = getCatalog();
    if (!prodObj.id) {
      prodObj.id = 'prod-' + Date.now();
    }
    if (!prodObj.tiers || prodObj.tiers.length === 0) {
      prodObj.tiers = [
        {
          key: "standard",
          label: prodObj.name + " Tiêu Chuẩn",
          name: prodObj.name,
          price: 1990000,
          priceFormatted: "1.990.000₫",
          oldPriceFormatted: "2.490.000₫",
          save: "Tiết kiệm 500.000₫",
          gift: "Phụ kiện tiêu chuẩn",
          sku: prodObj.id.toUpperCase() + "-STD",
          stock: 100,
          ordersCount: 0,
          specs: "Thông số tiêu chuẩn",
          highlights: ["Chất lượng hoàn thiện cao", "Bảo hành chính hãng 12 tháng"]
        }
      ];
    }
    cat.products.push(prodObj);
    saveCatalog(cat);
    return prodObj;
  }

  function updateProduct(productId, updateData) {
    var cat = getCatalog();
    var idx = cat.products.findIndex(function (p) { return p.id === productId; });
    if (idx === -1) return false;
    cat.products[idx] = Object.assign({}, cat.products[idx], updateData);
    saveCatalog(cat);
    return cat.products[idx];
  }

  function deleteProduct(productId) {
    var cat = getCatalog();
    cat.products = cat.products.filter(function (p) { return p.id !== productId; });
    if (cat.mvpProductId === productId) {
      cat.mvpProductId = cat.products[0] ? cat.products[0].id : "";
    }
    saveCatalog(cat);
    return true;
  }

  // 6. TIERS CRUD
  function addTier(productId, tierObj) {
    var cat = getCatalog();
    var prod = cat.products.find(function (p) { return p.id === productId; });
    if (!prod) return false;
    if (!prod.tiers) prod.tiers = [];
    if (!tierObj.key) tierObj.key = 'tier-' + Date.now();
    if (!tierObj.priceFormatted && tierObj.price) {
      tierObj.priceFormatted = formatVND(tierObj.price);
    }
    prod.tiers.push(tierObj);
    saveCatalog(cat);
    return tierObj;
  }

  function updateTier(productId, tierKey, updateData) {
    var cat = getCatalog();
    var prod = cat.products.find(function (p) { return p.id === productId; });
    if (!prod || !prod.tiers) return false;
    var idx = prod.tiers.findIndex(function (t) { return t.key === tierKey; });
    if (idx === -1) return false;
    if (updateData.price && !updateData.priceFormatted) {
      updateData.priceFormatted = formatVND(updateData.price);
    }
    prod.tiers[idx] = Object.assign({}, prod.tiers[idx], updateData);
    saveCatalog(cat);
    return prod.tiers[idx];
  }

  function deleteTier(productId, tierKey) {
    var cat = getCatalog();
    var prod = cat.products.find(function (p) { return p.id === productId; });
    if (!prod || !prod.tiers) return false;
    prod.tiers = prod.tiers.filter(function (t) { return t.key !== tierKey; });
    saveCatalog(cat);
    return true;
  }

  // 7. FORMATTERS
  function formatVND(amount) {
    if (typeof amount !== 'number') {
      amount = parseInt(amount, 10) || 0;
    }
    return amount.toLocaleString('vi-VN') + '₫';
  }

  // 8. SHOPPING CART API (REQUIREMENT 3)
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
      var count = getCartCount();
      var evt = new CustomEvent(CART_EVENT, { detail: { items: cartItems, count: count } });
      window.dispatchEvent(evt);
    } catch (e) {}
  }

  function addToCart(item) {
    // item: { productId, tierKey, colorId, quantity }
    var cart = getCart();
    var existingIndex = cart.findIndex(function (c) {
      return c.productId === item.productId &&
             c.tierKey === item.tierKey &&
             c.colorId === item.colorId;
    });

    if (existingIndex !== -1) {
      cart[existingIndex].quantity += (item.quantity || 1);
    } else {
      var prod = getProduct(item.productId);
      var tier = prod && prod.tiers ? prod.tiers.find(function (t) { return t.key === item.tierKey; }) : null;
      var color = prod && prod.colors ? prod.colors.find(function (cl) { return cl.id === item.colorId; }) : null;

      var cartItem = {
        cartId: 'cart-' + Date.now() + '-' + Math.random().toString(36).substr(2, 4),
        productId: item.productId,
        productName: prod ? prod.name : 'Smart Gimbal',
        tierKey: item.tierKey,
        tierLabel: tier ? tier.label : (prod ? prod.name : ''),
        price: tier ? tier.price : 2890000,
        priceFormatted: tier ? tier.priceFormatted : '2.890.000₫',
        oldPriceFormatted: tier ? tier.oldPriceFormatted : '',
        gift: tier ? tier.gift : 'Quà tặng chính hãng',
        colorId: item.colorId,
        colorName: color ? color.name : (prod && prod.colors && prod.colors[0] ? prod.colors[0].name : 'Titanium Tự Nhiên'),
        colorHex: color ? color.hex : '#D4D2CD',
        img: prod ? prod.img : '../shared/img/feed_portrait_dusk.jpg',
        quantity: item.quantity || 1
      };
      cart.push(cartItem);
    }
    saveCart(cart);
    return cart;
  }

  function updateCartQty(cartId, delta) {
    var cart = getCart();
    var idx = cart.findIndex(function (c) { return c.cartId === cartId; });
    if (idx !== -1) {
      cart[idx].quantity += delta;
      if (cart[idx].quantity <= 0) {
        cart.splice(idx, 1);
      }
      saveCart(cart);
    }
    return cart;
  }

  function removeFromCart(cartId) {
    var cart = getCart().filter(function (c) { return c.cartId !== cartId; });
    saveCart(cart);
    return cart;
  }

  function clearCart() {
    saveCart([]);
  }

  function getCartCount() {
    var cart = getCart();
    return cart.reduce(function (sum, item) { return sum + (item.quantity || 1); }, 0);
  }

  function getCartTotal() {
    var cart = getCart();
    return cart.reduce(function (sum, item) { return sum + (item.price * (item.quantity || 1)); }, 0);
  }

  // 9. ORDERS & CHECKOUT API
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
    // orderData: { userId, customerName, phone, address, items, total, paymentMethod }
    var orders = getOrders();
    var newOrder = Object.assign({
      orderId: 'ORD-' + Math.floor(100000 + Math.random() * 900000),
      createdAt: new Date().toISOString(),
      dateFormatted: new Date().toLocaleDateString('vi-VN') + ' ' + new Date().toLocaleTimeString('vi-VN', {hour: '2-digit', minute:'2-digit'}),
      status: 'Đang Giao Hàng',
      statusColor: '#0071E3'
    }, orderData);

    orders.unshift(newOrder);
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(ORDERS_KEY, JSON.stringify(orders));
    }
    clearCart();
    return newOrder;
  }

  function getUserOrders(userId) {
    var orders = getOrders();
    if (!userId) return orders;
    return orders.filter(function (o) { return o.userId === userId; });
  }

  // 10. USER AUTH & PERMISSIONS API (REQUIREMENT 4)
  function getUsers() {
    return getCatalog().users || [];
  }

  function getCurrentUser() {
    if (typeof localStorage === 'undefined') return null;
    try {
      var raw = localStorage.getItem(CURRENT_USER_KEY);
      if (raw) {
        var u = JSON.parse(raw);
        // Refresh modules from current catalog store
        var catUser = (getCatalog().users || []).find(function (cu) { return cu.id === u.id || cu.email === u.email; });
        if (catUser) {
          u.modules = catUser.modules;
          u.tier = catUser.tier;
          u.tierBadge = catUser.tierBadge;
        }
        return u;
      }
    } catch (e) {}
    return null;
  }

  function loginUser(emailOrPhone, password) {
    var users = getUsers();
    var found = users.find(function (u) {
      return (u.email.toLowerCase() === emailOrPhone.toLowerCase() ||
              (u.phone && u.phone.replace(/\s+/g, '') === emailOrPhone.replace(/\s+/g, '')));
    });

    if (found) {
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(found));
      }
      var evt = new CustomEvent(USER_EVENT, { detail: found });
      window.dispatchEvent(evt);
      return { success: true, user: found };
    }
    return { success: false, message: 'Email hoặc số điện thoại không tồn tại trong hệ thống!' };
  }

  function registerUser(userData) {
    var cat = getCatalog();
    var exists = cat.users.some(function (u) { return u.email.toLowerCase() === userData.email.toLowerCase(); });
    if (exists) {
      return { success: false, message: 'Email này đã được sử dụng!' };
    }

    var newUser = {
      id: 'usr-' + Date.now(),
      name: userData.name || 'Khách Hàng',
      email: userData.email,
      phone: userData.phone || '',
      device: userData.device || 'Smart Gimbal S1',
      tier: userData.tier || 'Basic Creator',
      tierBadge: (userData.tier || 'Basic Creator') + ' Tier',
      memberSince: 'Tháng ' + (new Date().getMonth() + 1).toString().padStart(2, '0') + '/' + new Date().getFullYear(),
      serial: userData.serial || ('SG-S1-VN-' + new Date().getFullYear() + '-' + Math.floor(1000 + Math.random() * 9000)),
      warrantyDays: 365,
      battery: 100,
      firmware: 'v2.4.1 (Mới nhất)',
      status: 'Hoạt Động',
      modules: userData.tier === 'Pro Cinema' ? [true, true, true, true, true, false, true] : [true, false, true, false, false, false, false]
    };

    cat.users.push(newUser);
    saveCatalog(cat);

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(newUser));
    }
    var evt = new CustomEvent(USER_EVENT, { detail: newUser });
    window.dispatchEvent(evt);
    return { success: true, user: newUser };
  }

  function logoutUser() {
    if (typeof localStorage !== 'undefined') {
      localStorage.removeItem(CURRENT_USER_KEY);
    }
    var evt = new CustomEvent(USER_EVENT, { detail: null });
    window.dispatchEvent(evt);
  }

  function updateUserProfile(userId, updateData) {
    var cat = getCatalog();
    var idx = cat.users.findIndex(function (u) { return u.id === userId; });
    if (idx === -1) return false;
    cat.users[idx] = Object.assign({}, cat.users[idx], updateData);
    saveCatalog(cat);

    var cur = getCurrentUser();
    if (cur && cur.id === userId) {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(cat.users[idx]));
    }
    return cat.users[idx];
  }

  function updateUserModules(userId, modulesArray) {
    var cat = getCatalog();
    var idx = cat.users.findIndex(function (u) { return u.id === userId; });
    if (idx === -1) return false;
    cat.users[idx].modules = modulesArray;
    saveCatalog(cat);

    var cur = getCurrentUser();
    if (cur && cur.id === userId) {
      cur.modules = modulesArray;
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(cur));
      var evt = new CustomEvent(USER_EVENT, { detail: cur });
      window.dispatchEvent(evt);
    }
    return true;
  }

  // 11. EXCEL CSV IMPORT & EXPORT (UTF-8 BOM COMPATIBLE)
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
            p.id,
            p.name,
            p.tagline || p.subtitle,
            t.label,
            t.price,
            t.oldPriceFormatted || '',
            t.gift || '',
            t.ordersCount || 0,
            p.status || 'Đang Mở Bán'
          ]);
        });
      } else {
        rows.push([
          groupName,
          p.id,
          p.name,
          p.tagline || p.subtitle,
          "Tiêu Chuẩn",
          p.price || 0,
          "",
          "",
          p.totalOrders || 0,
          p.status || 'Đang Mở Bán'
        ]);
      }
    });

    var csvContent = "\uFEFF" + rows.map(function (e) {
      return e.map(function (val) {
        var s = String(val).replace(/"/g, '""');
        return '"' + s + '"';
      }).join(",");
    }).join("\r\n");

    return csvContent;
  }

  function importProductsCSV(csvText) {
    if (!csvText) return 0;
    var lines = csvText.split(/\r\n|\n/);
    if (lines.length < 2) return 0;

    var cat = getCatalog();
    var count = 0;

    for (var i = 1; i < lines.length; i++) {
      var line = lines[i].trim();
      if (!line) continue;

      var cols = line.split(",").map(function (c) {
        return c.replace(/^"|"$/g, '').replace(/""/g, '"').trim();
      });

      if (cols.length >= 3 && cols[1] && cols[2]) {
        var prodId = cols[1];
        var prodName = cols[2];
        var tierLabel = cols[4] || 'Tiêu Chuẩn';
        var price = parseInt(cols[5], 10) || 1990000;

        var existing = cat.products.find(function (p) { return p.id === prodId; });
        if (existing) {
          existing.name = prodName;
          var t = existing.tiers.find(function (tier) { return tier.label === tierLabel; });
          if (t) {
            t.price = price;
            t.priceFormatted = formatVND(price);
          } else {
            existing.tiers.push({
              key: 'tier-' + Date.now() + '-' + Math.random().toString(36).substr(2, 4),
              label: tierLabel,
              name: prodName + ' ' + tierLabel,
              price: price,
              priceFormatted: formatVND(price),
              oldPriceFormatted: formatVND(price + 500000),
              save: "Tiết kiệm 500.000₫",
              gift: cols[7] || "Quà tặng chính hãng",
              ordersCount: parseInt(cols[8], 10) || 0,
              specs: "Thông số tiêu chuẩn",
              highlights: ["Chất lượng hoàn thiện cao", "Bảo hành 12 tháng"]
            });
          }
          count++;
        }
      }
    }

    saveCatalog(cat);
    return count;
  }

  function exportUsersCSV(users) {
    var rows = [
      ["Ho_Ten", "Email", "So_Dien_Thoai", "Thiet_Bi", "Goi_Tai_Khoan", "Module_AI_Vision", "Module_ProRes_Log", "Module_Motionlapse", "Module_MultiCam", "Module_3D_LUT", "Module_FOC_Tuning", "Module_500Hz", "Trang_Thai"]
    ];

    (users || getUsers()).forEach(function (u) {
      rows.push([
        u.name || '',
        u.email || '',
        u.phone || '',
        u.device || '',
        u.tier || '',
        u.modules && u.modules[0] ? 'Bật' : 'Tắt',
        u.modules && u.modules[1] ? 'Bật' : 'Tắt',
        u.modules && u.modules[2] ? 'Bật' : 'Tắt',
        u.modules && u.modules[3] ? 'Bật' : 'Tắt',
        u.modules && u.modules[4] ? 'Bật' : 'Tắt',
        u.modules && u.modules[5] ? 'Bật' : 'Tắt',
        u.modules && u.modules[6] ? 'Bật' : 'Tắt',
        u.status || 'Hoạt Động'
      ]);
    });

    var csvContent = "\uFEFF" + rows.map(function (e) {
      return e.map(function (val) {
        var s = String(val).replace(/"/g, '""');
        return '"' + s + '"';
      }).join(",");
    }).join("\r\n");

    return csvContent;
  }

  // 12. SETUP LISTENERS
  if (typeof window !== 'undefined') {
    window.addEventListener('storage', function (e) {
      if (e.key === STORAGE_KEY && e.newValue) {
        try {
          var updated = JSON.parse(e.newValue);
          var evt = new CustomEvent(SYNC_EVENT, { detail: updated });
          window.dispatchEvent(evt);
        } catch (err) {}
      } else if (e.key === CART_KEY && e.newValue) {
        try {
          var cartUpdated = JSON.parse(e.newValue);
          var cartEvt = new CustomEvent(CART_EVENT, { detail: { items: cartUpdated, count: getCartCount() } });
          window.dispatchEvent(cartEvt);
        } catch (err) {}
      } else if (e.key === CURRENT_USER_KEY && e.newValue) {
        try {
          var userUpdated = JSON.parse(e.newValue);
          var userEvt = new CustomEvent(USER_EVENT, { detail: userUpdated });
          window.dispatchEvent(userEvt);
        } catch (err) {}
      }
    });

    window.addEventListener('message', function (e) {
      if (e.data && e.data.type === 'SMART_GIMBAL_CATALOG_SYNC' && e.data.catalog) {
        try {
          var current = localStorage.getItem(STORAGE_KEY);
          var newStr = JSON.stringify(e.data.catalog);
          if (current !== newStr) {
            localStorage.setItem(STORAGE_KEY, newStr);
            var evt = new CustomEvent(SYNC_EVENT, { detail: e.data.catalog });
            window.dispatchEvent(evt);
          }
        } catch (err) {}
      }
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
    getCatalog: getCatalog,
    saveCatalog: saveCatalog,
    resetToDefault: resetToDefault,
    broadcastSync: broadcastSync,
    getMvpProductId: getMvpProductId,
    setMvpProduct: setMvpProduct,
    getMvpProduct: getMvpProduct,
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
    // Cart API
    getCart: getCart,
    saveCart: saveCart,
    addToCart: addToCart,
    updateCartQty: updateCartQty,
    removeFromCart: removeFromCart,
    clearCart: clearCart,
    getCartCount: getCartCount,
    getCartTotal: getCartTotal,
    // Orders API
    getOrders: getOrders,
    createOrder: createOrder,
    getUserOrders: getUserOrders,
    // Users API
    getUsers: getUsers,
    getCurrentUser: getCurrentUser,
    loginUser: loginUser,
    registerUser: registerUser,
    logoutUser: logoutUser,
    updateUserProfile: updateUserProfile,
    updateUserModules: updateUserModules,
    // Excel CSV Import / Export
    exportProductsCSV: exportProductsCSV,
    importProductsCSV: importProductsCSV,
    exportUsersCSV: exportUsersCSV
  };
}));
