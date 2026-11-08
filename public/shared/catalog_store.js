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
  }
}(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  var STORAGE_KEY = 'SMART_GIMBAL_CATALOG_V3';
  var CART_KEY = 'SMART_GIMBAL_CART_V3';
  var ORDERS_KEY = 'SMART_GIMBAL_ORDERS_V3';
  var CURRENT_USER_KEY = 'SMART_GIMBAL_CURRENT_USER_V3';

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
    mvpProductId: "s1",
    groups: [
      {
        id: "cat-phone",
        name: "Gimbal Điện Thoại",
        desc: "Thiết bị ổn định 3 trục cho iPhone & Smartphone cao cấp, thuật toán FOC 20kHz, ngàm MagSafe lực hút 2.8kg",
        badge: "Chủ Lực"
      },
      {
        id: "cat-cam",
        name: "Gimbal Du Lịch",
        desc: "Camera chống rung 3 trục cầm tay bỏ túi, cảm biến 1 inch, quay 4K/120fps và bám nét khuôn mặt độc lập",
        badge: "Chuyên Nghiệp"
      },
      {
        id: "cat-acc",
        name: "Phụ Kiện",
        desc: "Mô-đun mở rộng hệ sinh thái: Micro thu âm không dây 2.4GHz, Đèn trợ sáng, Chân đế Carbon và Ngàm MagSafe",
        badge: "Đồng Bộ"
      }
    ],
    products: [
      // === SẢN PHẨM 1: SMART GIMBAL S1 (MVP CHỦ LỰC) ===
      {
        id: "s1",
        groupId: "cat-phone",
        name: "Smart Gimbal S1",
        tagline: "Đưa thước phim di động lên tầm điện ảnh.",
        subtitle: "Dòng Gimbal 3 trục tối ưu hàng đầu cho iPhone. Tích hợp ngàm MagSafe N52, chống rung FOC 20kHz và pin 18 giờ.",
        badge: "Sản Phẩm Chủ Lực",
        img: "../shared/img/feed_portrait_dusk.jpg",
        status: "Đang Mở Bán",
        totalOrders: 1420,
        orderGrowth: "+18%",
        is_flagship: true,
        gallery: [
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_person_portrait.jpg",
          "../shared/img/feed_land_dusk.jpg"
        ],
        colors: [
          { id: "natural-titanium", name: "Titanium Tự Nhiên", hex: "#D4D2CD" },
          { id: "space-black", name: "Đen Không Gian", hex: "#2C2C2E" },
          { id: "starlight", name: "Bạc Ánh Kim", hex: "#E5E5EA" }
        ],
        overview: [
          {
            title: "Thuật Toán FOC 20kHz Triệt Tiêu Rung Lắc Tuyệt Đối",
            desc: "Động cơ không chổi than từ tính mạnh mẽ điều khiển vi bước phản hồi trong 0.05 mili-giây. Dù bạn đi bộ, chạy leo cầu thang hay di chuyển trên xe, khung hình luôn êm ái như bay trên ray trượt điện ảnh.",
            img: "../shared/img/feed_person_portrait.jpg"
          },
          {
            title: "Ngàm Hít MagSafe Quick-Snap N52 Lực Hút 2.8kg",
            desc: "Thao tác gắn điện thoại trong 1 giây không cần kẹp siết, không lo cấn phím nguồn hay nút âm lượng. Nam châm Neodymium N52 phân bổ đa cực giữ chắc iPhone ngay cả khi vận động mạnh.",
            img: "../shared/img/feed_portrait_day.jpg"
          },
          {
            title: "Đồng Bộ Sâu iOS & Điều Khiển Bánh Xe Focus Cơ Học",
            desc: "Kết nối tức thì khi đặt máy lại gần. Bánh xe CNC kim loại bên hông cho phép lấy nét tay mượt mà từng milimet, zoom điện tử mượt mà và hiển thị thông số pin trực tiếp trên Dynamic Island.",
            img: "../preview/02_camera_pro_dark.png"
          }
        ],
        boxContents: [
          "01 Thân máy Smart Gimbal S1",
          "01 Ngàm hít từ tính MagSafe N52 Quick-Snap",
          "01 Chân đế Tripod Mini sợi Carbon CNC",
          "01 Cáp sạc nhanh USB-C to USB-C bọc dù cao cấp",
          "01 Túi nhung chống sốc bảo quản du lịch",
          "01 Thẻ bảo hành điện tử chính hãng 12 tháng"
        ],
        specs: {
          "Trọng lượng thân máy": "480g (đã bao gồm pin Li-ion dung lượng cao)",
          "Tải trọng tối đa": "380g (tương thích iPhone 16 Pro Max và Rig quay phim)",
          "Thời lượng pin": "18 giờ hoạt động liên tục (Pin 4500mAh)",
          "Thời gian sạc": "1.5 giờ (Sạc nhanh USB-C PD 18W)",
          "Góc xoay cơ học": "Pan 360° vô cực • Tilt -135° đến +135° • Roll -85° đến +85°",
          "Chuẩn kết nối": "Bluetooth 5.3 Low Energy (Độ trễ tín hiệu < 4ms)",
          "Kích thước gấp gọn": "163 × 99 × 54 mm (Bỏ túi áo khoác dễ dàng)",
          "Kích thước mở rộng": "276 × 111 × 99 mm",
          "Hệ điều hành": "iOS 16.0 trở lên & Android 12 trở lên"
        },
        warranty: "Bảo hành 12 tháng 1 đổi 1 chính hãng, 30 ngày dùng thử đổi mới, hỗ trợ cập nhật firmware OTA trọn đời.",
        tiers: [
          {
            key: "standard",
            label: "S1 Tiêu Chuẩn",
            name: "Smart Gimbal S1 Tiêu Chuẩn",
            price: 2890000,
            priceFormatted: "2.890.000₫",
            oldPriceFormatted: "3.490.000₫",
            save: "Tiết kiệm 600.000₫",
            gift: "Ngàm MagSafe + Tripod Mini Carbon",
            sku: "SG-S1-STD",
            stock: 840,
            ordersCount: 850,
            specs: "Tải trọng 380g • Pin 18 Giờ • MagSafe N52 • Bluetooth 5.3",
            highlights: [
              "Động cơ FOC 20kHz chịu tải 380g (iPhone 16 Pro Max)",
              "Ngàm hít từ tính MagSafe Quick-Snap lực hút 2.8kg",
              "Pin 18 giờ liên tục & Sạc ngược Type-C 18W",
              "Kết nối Bluetooth 5.3 & Đồng bộ Dynamic Island"
            ]
          },
          {
            key: "pro",
            label: "S1 Pro",
            name: "Smart Gimbal S1 Pro",
            price: 3690000,
            priceFormatted: "3.690.000₫",
            oldPriceFormatted: "4.390.000₫",
            save: "Tiết kiệm 700.000₫",
            gift: "01 Micro Wireless 2.4GHz + Tripod Carbon",
            sku: "SG-S1-PRO",
            stock: 420,
            ordersCount: 420,
            specs: "Màn hình OLED 1.4 inch • Focus Wheel cơ học • Tải 420g",
            highlights: [
              "Màn hình OLED hiển thị góc trục & dung lượng pin",
              "Bánh xe lấy nét cơ học Follow Focus kim loại CNC",
              "Tặng kèm 01 Micro không dây 2.4GHz chống ồn AI",
              "Tải trọng nâng cấp 420g hỗ trợ ống kính ngoài"
            ]
          },
          {
            key: "max",
            label: "S1 Max Creator",
            name: "Smart Gimbal S1 Max Creator Kit",
            price: 4390000,
            priceFormatted: "4.390.000₫",
            oldPriceFormatted: "5.190.000₫",
            save: "Tiết kiệm 800.000₫",
            gift: "Vali Hợp Kim + Bộ Mic Kép + Cảm Biến AI",
            sku: "SG-S1-MAX",
            stock: 190,
            ordersCount: 150,
            specs: "Creator Kit • 2 Mic Thu Âm • Mô-đun AI Tracking • Vali",
            highlights: [
              "Trọn bộ Creator Kit: Cảm biến AI Tracking quang học rời",
              "Hệ thống Micro thu âm không dây kép Duo Transmitter",
              "Vali chống sốc hợp kim nhôm kèm pin dự phòng",
              "Mở khóa toàn bộ tính năng Pro Cinema trên ứng dụng"
            ]
          }
        ]
      },

      // === SẢN PHẨM 2: SMART GIMBAL S2 CINEMA ===
      {
        id: "s2",
        groupId: "cat-phone",
        name: "Smart Gimbal S2 Cinema",
        tagline: "Sức mạnh điều khiển điện ảnh trong lòng bàn tay.",
        subtitle: "Thế hệ Gimbal Cinema tích hợp màn hình cảm ứng Touch OLED, thuật toán FOC thế hệ 3, tải trọng 480g cho Rig quay phim chuyên nghiệp.",
        badge: "Thế Hệ Mới",
        img: "../shared/img/feed_portrait_dusk.jpg",
        status: "Đang Mở Bán",
        totalOrders: 980,
        orderGrowth: "+32%",
        is_flagship: false,
        gallery: [
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_land_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_person_portrait.jpg"
        ],
        colors: [
          { id: "graphite", name: "Xám Than Chì", hex: "#3A3A3C" },
          { id: "silver", name: "Bạc Titan", hex: "#E5E5EA" }
        ],
        overview: [
          {
            title: "Màn Hình Cảm Ứng OLED 1.8 Inch Thông Minh",
            desc: "Trực tiếp điều chỉnh ISO, Shutter, chọn chế độ Waypoint Timelapse và xem dung lượng pin mà không cần chạm vào màn hình điện thoại.",
            img: "../shared/img/feed_land_dusk.jpg"
          },
          {
            title: "Động Cơ FOC Thế Hệ 3 Tải Trọng 480g",
            desc: "Công suất mô-men xoắn tăng 40%, tương thích hoàn hảo với các bộ khung Rig, ống kính Anamorphic và kính lọc ND nặng.",
            img: "../shared/img/feed_portrait_dusk.jpg"
          },
          {
            title: "Sạc Nhanh GaN 30W Cung Cấp Năng Lượng Cả Ngày",
            desc: "Nạp 80% pin chỉ trong 40 phút. Hỗ trợ cổng xuất nguồn PD 20W duy trì điện thoại quay 4K ProRes liên tục suốt buổi ghi hình.",
            img: "../preview/02_camera_pro_dark.png"
          }
        ],
        boxContents: [
          "01 Thân máy Smart Gimbal S2 Cinema",
          "01 Ngàm kẹp trợ lực kiêm MagSafe V2",
          "01 Chân đế Carbon chân rộng chống gió",
          "01 Bộ cáp kết nối máy ảnh chuyên nghiệp",
          "01 Hộp đựng cứng EVA cao cấp chống nước"
        ],
        specs: {
          "Trọng lượng": "530g",
          "Tải trọng tối đa": "480g (Cân tốt rig điện thoại chuyên nghiệp)",
          "Màn hình điều khiển": "OLED 1.8 inch cảm ứng điện dung",
          "Pin": "20 giờ liên tục (Pin Li-Po 5200mAh)",
          "Sạc": "Cổng Type-C GaN 30W Fast Charge",
          "Kết nối": "Bluetooth 5.3 LE + Wi-Fi 2.4GHz Direct"
        },
        warranty: "Bảo hành 12 tháng 1 đổi 1 chính hãng, bảo trì vệ sinh trục motor miễn phí trọn đời.",
        tiers: [
          {
            key: "standard",
            label: "S2 Tiêu Chuẩn",
            name: "Smart Gimbal S2 Tiêu Chuẩn",
            price: 3490000,
            priceFormatted: "3.490.000₫",
            oldPriceFormatted: "4.190.000₫",
            save: "Tiết kiệm 700.000₫",
            gift: "Ngàm MagSafe V2 + Chân đế hợp kim",
            sku: "SG-S2-STD",
            stock: 520,
            ordersCount: 520,
            specs: "Màn hình OLED 1.8 inch Touch • FOC Gen 3 • Tải 450g",
            highlights: [
              "Màn hình cảm ứng OLED 1.8 inch điều khiển trực tiếp",
              "Động cơ FOC Gen 3 xung 30kHz triệt tiêu rung giật 99.8%",
              "Chịu tải 450g cân mọi dòng smartphone kèm ống kính",
              "Sạc nhanh GaN 30W nạp 80% pin trong 40 phút"
            ]
          },
          {
            key: "pro",
            label: "S2 Pro Cinema",
            name: "Smart Gimbal S2 Pro Cinema",
            price: 4490000,
            priceFormatted: "4.490.000₫",
            oldPriceFormatted: "5.390.000₫",
            save: "Tiết kiệm 900.000₫",
            gift: "Mô-đun AI Vision + Focus Wheel Kép",
            sku: "SG-S2-PRO",
            stock: 280,
            ordersCount: 310,
            specs: "Focus Wheel Kép • Mô-đun AI Tracking rời • Tải 480g",
            highlights: [
              "Cụm bánh xe xoay kép điều chỉnh Focus và Zoom đồng thời",
              "Mô-đun AI Vision bám khuôn mặt không cần qua App",
              "Ngàm tháo lắp đa năng tương thích Arca-Swiss tiêu chuẩn",
              "Bảo hành 1 đổi 1 trong 18 tháng chính hãng"
            ]
          },
          {
            key: "ultra",
            label: "S2 Ultra Director Kit",
            name: "Smart Gimbal S2 Ultra Director Kit",
            price: 5690000,
            priceFormatted: "5.690.000₫",
            oldPriceFormatted: "6.890.000₫",
            save: "Tiết kiệm 1.200.000₫",
            gift: "Vali Chống Sốc + Monitor Không Dây + Full Kit",
            sku: "SG-S2-ULTRA",
            stock: 110,
            ordersCount: 150,
            specs: "Director Kit • Bộ phát HDMI không dây • Vali Hợp Kim",
            highlights: [
              "Bộ truyền video HDMI không dây độ trễ siêu thấp 30ms",
              "Vali hợp kim đúc nguyên khối chống va đập IP67",
              "Tích hợp hệ thống tay cầm đôi Director Ring Grip",
              "Gói hỗ trợ dịch vụ VIP thay mới linh kiện tận nơi"
            ]
          }
        ]
      },

      // === SẢN PHẨM 3: SMART GIMBAL S1 AIR ===
      {
        id: "s1-air",
        groupId: "cat-phone",
        name: "Smart Gimbal S1 Air",
        tagline: "Nhẹ nhàng bỏ túi, sẵn sàng mọi khoảnh khắc.",
        subtitle: "Phiên bản siêu nhỏ gọn chỉ 290g, cơ chế gập 1 chạm bỏ túi quần, ngàm MagSafe hít nhanh và pin 10 giờ bền bỉ.",
        badge: "Siêu Nhỏ Gọn",
        img: "../shared/img/feed_portrait_dusk.jpg",
        status: "Đang Mở Bán",
        totalOrders: 650,
        orderGrowth: "+12%",
        is_flagship: false,
        gallery: [
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_person_portrait.jpg",
          "../shared/img/feed_land_dusk.jpg"
        ],
        colors: [
          { id: "snow-white", name: "Trắng Tuyết", hex: "#F2F2F7" },
          { id: "midnight", name: "Đen Nửa Đêm", hex: "#1C1C1E" }
        ],
        overview: [
          {
            title: "Trọng Lượng Siêu Nhẹ Chỉ 290g",
            desc: "Thiết kế từ sợi carbon tổng hợp siêu nhẹ, gấp gọn vừa vặn trong túi quần, là người bạn đồng hành lý tưởng cho du lịch và dạo phố.",
            img: "../shared/img/feed_person_portrait.jpg"
          },
          {
            title: "Gập Mở 1 Chạm Sẵn Sàng Ghi Hình",
            desc: "Không cần khóa trục cơ học rườm rà. Chỉ cần xoay nhẹ thân máy, gimble tự động bật nguồn và kết nối với iPhone trong 2 giây.",
            img: "../shared/img/feed_portrait_day.jpg"
          },
          {
            title: "Pin 10 Giờ Thoải Mái Sáng Tạo",
            desc: "Thoải mái quay vlog, story cả ngày dài. Hỗ trợ sạc nhanh qua cổng USB-C tiện lợi chung với củ sạc điện thoại.",
            img: "../shared/img/feed_land_dusk.jpg"
          }
        ],
        boxContents: [
          "01 Thân máy Smart Gimbal S1 Air",
          "01 Ngàm hít từ tính MagSafe",
          "01 Cáp sạc USB-C",
          "01 Dây đeo cổ tay chống rơi",
          "01 Thẻ bảo hành điện tử 12 tháng"
        ],
        specs: {
          "Trọng lượng": "290g",
          "Tải trọng tối đa": "280g",
          "Thời lượng pin": "10 giờ",
          "Kết nối": "Bluetooth 5.2 LE",
          "Kích thước khi gập": "140 × 85 × 40 mm"
        },
        warranty: "Bảo hành 12 tháng 1 đổi 1 chính hãng.",
        tiers: [
          {
            key: "standard",
            label: "S1 Air Tiêu Chuẩn",
            name: "Smart Gimbal S1 Air",
            price: 1990000,
            priceFormatted: "1.990.000₫",
            oldPriceFormatted: "2.490.000₫",
            save: "Tiết kiệm 500.000₫",
            gift: "Túi đựng nhung mềm",
            sku: "SG-AIR-STD",
            stock: 350,
            ordersCount: 420,
            specs: "Siêu nhẹ 290g • Gập bỏ túi • Pin 10H • MagSafe N52",
            highlights: [
              "Trọng lượng siêu nhẹ chỉ 290g bỏ gọn túi áo",
              "Cơ chế xoay mở tự khởi động nhanh trong 2 giây",
              "Ngàm hít từ tính MagSafe tương thích tức thì",
              "Thuật toán FOC chống rung mượt mà cho Vlog hàng ngày"
            ]
          },
          {
            key: "plus",
            label: "S1 Air Plus",
            name: "Smart Gimbal S1 Air Plus",
            price: 2490000,
            priceFormatted: "2.490.000₫",
            oldPriceFormatted: "2.990.000₫",
            save: "Tiết kiệm 500.000₫",
            gift: "Đèn LED mini + Tripod Carbon",
            sku: "SG-AIR-PLUS",
            stock: 180,
            ordersCount: 230,
            specs: "Kèm Đèn LED trợ sáng từ tính • Chân đế mini",
            highlights: [
              "Tặng kèm đèn LED trợ sáng hít từ tính 3 mức nhiệt màu",
              "Chân đế tripod mini hợp kim chắc chắn",
              "Túi bảo quản chống va đập du lịch chuyên dụng",
              "Pin nâng cấp hoạt động lên tới 12 giờ"
            ]
          }
        ]
      },

      // === SẢN PHẨM 4: SMARTCAM POCKET P1 ===
      {
        id: "p1",
        groupId: "cat-cam",
        name: "SmartCam Pocket P1",
        tagline: "Camera 4K 3 trục độc lập, bắt trọn từng thước phim du lịch.",
        subtitle: "Camera bỏ túi tích hợp gimbal 3 trục cơ học, cảm biến 1-inch 4K/120fps, lấy nét siêu nhanh và màn hình xoay 2.0 inch OLED.",
        badge: "Camera Bỏ Túi",
        img: "../shared/img/feed_land_dusk.jpg",
        status: "Đang Mở Bán",
        totalOrders: 430,
        orderGrowth: "+24%",
        is_flagship: false,
        gallery: [
          "../shared/img/feed_land_dusk.jpg",
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_person_portrait.jpg"
        ],
        colors: [
          { id: "matte-black", name: "Đen Nhám Cổ Điển", hex: "#1D1D1F" }
        ],
        overview: [
          {
            title: "Cảm Biến Lớn 1-Inch Quay 4K/120fps",
            desc: "Chất lượng hình ảnh vượt trội trong điều kiện thiếu sáng. Độ phân giải 4K sắc nét cùng tốc độ 120 khung hình/giây giúp tạo nên các thước phim Slow-motion mượt mà.",
            img: "../shared/img/feed_land_dusk.jpg"
          },
          {
            title: "Màn Hình Xoay 2.0 Inch OLED Chạm Nhạy",
            desc: "Xoay ngang để quay chuẩn Cinematic 16:9, xoay dọc để chuyển tức thì sang định dạng TikTok/Reels 9:16.",
            img: "../shared/img/feed_portrait_dusk.jpg"
          },
          {
            title: "Bám Nét Khuôn Mặt Độc Lập ActiveTrack 6.0",
            desc: "Tự động nhận diện chủ thể và xoay gimbal bám theo dù bạn di chuyển khắp khung hình mà không cần nhờ người khác quay hộ.",
            img: "../shared/img/feed_person_portrait.jpg"
          }
        ],
        boxContents: [
          "01 SmartCam Pocket P1",
          "01 Tay cầm pin mở rộng",
          "01 Cáp sạc USB-C PD",
          "01 Ốp bảo vệ thân máy",
          "01 Dây đeo cổ tay"
        ],
        specs: {
          "Cảm biến": "CMOS 1-inch độ phân giải cao",
          "Ống kính": "Tiêu cự tương đương 20mm, khẩu độ f/2.0",
          "Video tối đa": "4K UHD tại 120fps, 10-bit D-Log M",
          "Trọng lượng": "179g",
          "Thời lượng pin": "166 phút quay 4K liên tục"
        },
        warranty: "Bảo hành 12 tháng 1 đổi 1 chính hãng.",
        tiers: [
          {
            key: "standard",
            label: "P1 Tiêu Chuẩn",
            name: "SmartCam Pocket P1 Tiêu Chuẩn",
            price: 8990000,
            priceFormatted: "8.990.000₫",
            oldPriceFormatted: "9.990.000₫",
            save: "Tiết kiệm 1.000.000₫",
            gift: "Thẻ nhớ 64GB 160MB/s",
            sku: "SC-P1-STD",
            stock: 120,
            ordersCount: 280,
            specs: "Cảm biến 1-inch • 4K/120fps • Màn xoay 2.0 inch OLED",
            highlights: [
              "Cảm biến CMOS 1-inch thu sáng vượt trội trong đêm",
              "Quay video 4K/120fps siêu mượt với màu 10-bit D-Log",
              "Màn hình OLED cảm ứng 2.0 inch xoay ngang/dọc 1 giây",
              "Hệ thống 3 micro thu âm định hướng lọc gió thông minh"
            ]
          },
          {
            key: "creator",
            label: "P1 Creator Combo",
            name: "SmartCam Pocket P1 Creator Combo",
            price: 11490000,
            priceFormatted: "11.490.000₫",
            oldPriceFormatted: "12.990.000₫",
            save: "Tiết kiệm 1.500.000₫",
            gift: "Mic Không Dây + Ống Kính Rộng + Pin Phụ",
            sku: "SC-P1-CREATOR",
            stock: 65,
            ordersCount: 150,
            specs: "Bộ Creator Combo • Mic Không Dây • Ống Kính Rộng",
            highlights: [
              "Bao gồm bộ phát Micro không dây chống ồn AI chuyên nghiệp",
              "Ống kính mở rộng góc nhìn Wide-Angle Lens 15mm",
              "Tay cầm tích hợp pin dự phòng tăng gấp đôi thời gian quay",
              "Chân đế tripod mini và túi chống sốc du lịch"
            ]
          }
        ]
      },

      // === SẢN PHẨM 5: SMARTCAM ACTION X2 ===
      {
        id: "x2",
        groupId: "cat-cam",
        name: "SmartCam Action X2",
        tagline: "Vững vàng trước mọi bão táp thể thao mạo hiểm.",
        subtitle: "Camera hành động chống nước 16m không cần vỏ, chống rung gimbal cơ học kết hợp EIS 360 HorizonSteady, quay 5.3K/60fps.",
        badge: "Thể Thao Mạo Hiểm",
        img: "../shared/img/feed_land_day.jpg",
        status: "Đang Mở Bán",
        totalOrders: 310,
        orderGrowth: "+8%",
        is_flagship: false,
        gallery: [
          "../shared/img/feed_land_day.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_land_dusk.jpg"
        ],
        colors: [
          { id: "stealth-black", name: "Đen Nhám Thể Thao", hex: "#1C1C1E" }
        ],
        overview: [
          {
            title: "Kháng Nước 16 Mét Không Cần Vỏ Bảo Vệ",
            desc: "Thoải mái lặn biển ngắm san hô, lướt ván và đi mưa bão mà không lo ngại hư hỏng.",
            img: "../shared/img/feed_land_day.jpg"
          },
          {
            title: "Chống Rung HorizonSteady Khóa Đường Chân Trời 360°",
            desc: "Dù camera xoay lộn vòng 360 độ trên xe đạp địa hình, khung hình vẫn giữ nguyên phương nằm ngang hoàn hảo.",
            img: "../shared/img/feed_portrait_day.jpg"
          },
          {
            title: "Màn Hình Cảm Ứng Kép Trước & Sau",
            desc: "Dễ dàng canh khung hình khi quay vlog thể thao hoặc ghi lại khoảnh khắc gia đình.",
            img: "../shared/img/feed_portrait_dusk.jpg"
          }
        ],
        boxContents: [
          "01 SmartCam Action X2",
          "01 Pin dung lượng cao chịu nhiệt -20°C",
          "01 Khung gắn từ tính Quick-Release",
          "01 Chân đế dán phẳng",
          "01 Vít vặn khóa trục"
        ],
        specs: {
          "Độ phân giải": "5.3K tại 60fps & 4K tại 120fps",
          "Kháng nước": "16 mét không cần ốp bảo vệ",
          "Màn hình": "Màn hình kép cảm ứng cực nhạy dưới nước",
          "Pin": "Chịu lạnh âm 20 độ C, quay 160 phút"
        },
        warranty: "Bảo hành 12 tháng 1 đổi 1 chính hãng.",
        tiers: [
          {
            key: "standard",
            label: "X2 Tiêu Chuẩn",
            name: "SmartCam Action X2 Tiêu Chuẩn",
            price: 7490000,
            priceFormatted: "7.490.000₫",
            oldPriceFormatted: "8.290.000₫",
            save: "Tiết kiệm 800.000₫",
            gift: "Thẻ nhớ 64GB Extreme",
            sku: "SC-X2-STD",
            stock: 90,
            ordersCount: 210,
            specs: "5.3K/60fps • Kháng nước 16m • Màn hình cảm ứng kép",
            highlights: [
              "Quay video độ nét cực cao 5.3K/60fps sắc sảo từng chi tiết",
              "Chống nước độ sâu 16m nguyên bản không cần vỏ bảo vệ",
              "Khóa đường chân trời HorizonSteady 360° bất chấp lộn vòng",
              "Pin chịu lạnh Extreme Battery hoạt động bền bỉ ở -20°C"
            ]
          },
          {
            key: "adventure",
            label: "X2 Adventure Combo",
            name: "SmartCam Action X2 Adventure Combo",
            price: 9490000,
            priceFormatted: "9.490.000₫",
            oldPriceFormatted: "10.690.000₫",
            save: "Tiết kiệm 1.200.000₫",
            gift: "3 Pin + Hộp Sạc Nhanh + Gậy Chụp 1.5m",
            sku: "SC-X2-ADV",
            stock: 50,
            ordersCount: 100,
            specs: "3 Pin • Hộp Sạc Đa Năng • Gậy Kéo Dài 1.5m",
            highlights: [
              "Bao gồm trọn bộ 3 viên pin Extreme dung lượng cao",
              "Hộp sạc nhanh đa năng nạp cùng lúc 3 pin kiêm pin sạc dự phòng",
              "Gậy nối dài tàng hình Extension Rod 1.5m sợi carbon",
              "Ngàm hút chân không gắn kính xe hơi và mũ bảo hiểm"
            ]
          }
        ]
      },

      // === PHỤ KIỆN 1: WIRELESS MIC DUO ===
      {
        id: "acc-mic",
        groupId: "cat-acc",
        name: "Wireless Mic Duo 2.4GHz",
        tagline: "Âm thanh trong trẻo chuẩn studio cho mọi thước phim.",
        subtitle: "Hệ thống 2 micro thu âm không dây khử ồn thuật toán AI 2 tầng, ghi âm nội bộ 32-bit float, phạm vi truyền xa 250m.",
        badge: "Phụ Kiện Studio",
        img: "../shared/img/thumb_01.jpg",
        status: "Đang Mở Bán",
        totalOrders: 540,
        orderGrowth: "+20%",
        is_flagship: false,
        gallery: [
          "../shared/img/thumb_01.jpg",
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_person_portrait.jpg",
          "../shared/img/feed_land_dusk.jpg"
        ],
        colors: [
          { id: "black", name: "Đen Nhám", hex: "#1C1C1E" }
        ],
        overview: [
          {
            title: "Khử Ồn AI Thông Minh 2 Tầng",
            desc: "Triệt tiêu tiếng còi xe, tiếng gió rít ngoài đường phố, giữ trọn vẹn giọng nói ấm áp và tự nhiên của người nói.",
            img: "../shared/img/thumb_01.jpg"
          },
          {
            title: "Ghi Âm Nội Bộ 32-Bit Float Không Lo Bể Tiếng",
            desc: "Bộ nhớ trong lưu trữ 14 giờ âm thanh chất lượng phòng thu, cứu vãn mọi tình huống âm lượng tăng đột biến.",
            img: "../shared/img/feed_person_portrait.jpg"
          },
          {
            title: "Khoảng Cách Truyền Xa 250 Mét Ổn Định",
            desc: "Tần số sóng 2.4GHz mã hóa chống nhiễu đảm bảo âm thanh liền mạch dù người nói quay lưng lại camera.",
            img: "../shared/img/feed_portrait_dusk.jpg"
          }
        ],
        boxContents: [
          "02 Bộ phát micro không dây (Transmitter)",
          "01 Bộ thu tín hiệu (Receiver) có màn hình OLED",
          "01 Hộp sạc thông minh nạp điện tự động",
          "02 Đầu lọc gió lông thú cao cấp",
          "01 Bộ chuyển đổi Lightning & USB-C cho iPhone"
        ],
        specs: {
          "Phạm vi hoạt động": "250m trong điều kiện không vật cản",
          "Thời lượng pin": "18 giờ (kèm hộp sạc)",
          "Định dạng ghi": "32-bit float / 24-bit 48kHz WAV",
          "Độ trễ": "Siêu thấp 5ms"
        },
        warranty: "Bảo hành 12 tháng 1 đổi 1 chính hãng.",
        tiers: [
          {
            key: "standard",
            label: "Bộ 1 Mic Đơn",
            name: "Wireless Mic Solo (1 TX + 1 RX)",
            price: 1890000,
            priceFormatted: "1.890.000₫",
            oldPriceFormatted: "2.290.000₫",
            save: "Tiết kiệm 400.000₫",
            gift: "Bông lọc gió lông thú",
            sku: "MIC-SOLO",
            stock: 200,
            ordersCount: 300,
            specs: "1 TX + 1 RX • Khử ồn AI • Pin 6H • Khoảng cách 200m",
            highlights: [
              "Bộ 1 Micro phát + 1 Bộ thu cắm thẳng vào cổng iPhone",
              "Khử ồn thông minh lọc sạch tạp âm gió và xe cộ",
              "Gắn áo từ tính gọn gàng không lộ dây",
              "Thời lượng pin 6 giờ hoạt động liên tục"
            ]
          },
          {
            key: "duo",
            label: "Bộ Kép Hộp Sạc",
            name: "Wireless Mic Duo Hộp Sạc (2 TX + 1 RX)",
            price: 2890000,
            priceFormatted: "2.890.000₫",
            oldPriceFormatted: "3.490.000₫",
            save: "Tiết kiệm 600.000₫",
            gift: "Hộp sạc thông minh + 2 Lọc gió",
            sku: "MIC-DUO",
            stock: 150,
            ordersCount: 240,
            specs: "2 TX + 1 RX + Hộp sạc • Pin 18H • 32-bit Float",
            highlights: [
              "Trọn bộ 2 Micro phỏng vấn kép kèm Hộp sạc thông minh",
              "Tổng thời lượng pin lên đến 18 giờ liên tục",
              "Bộ nhớ ghi âm nội bộ 32-bit Float lưu 14 giờ",
              "Màn hình OLED cảm ứng trên bộ thu dễ dàng chỉnh Gain"
            ]
          }
        ]
      },

      // === PHỤ KIỆN 2: NGÀM MAGSAFE AI VISION ===
      {
        id: "acc-magsafe",
        groupId: "cat-acc",
        name: "Ngàm MagSafe AI Vision",
        tagline: "Cảm biến quang học nhận diện chủ thể độc lập.",
        subtitle: "Mô-đun ngàm từ tính tích hợp camera AI nhận diện khuôn mặt và cử chỉ tay độc lập không cần kết nối qua App.",
        badge: "Công Nghệ AI",
        img: "../shared/img/thumb_02.jpg",
        status: "Đang Mở Bán",
        totalOrders: 380,
        orderGrowth: "+15%",
        is_flagship: false,
        gallery: [
          "../shared/img/thumb_02.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_person_portrait.jpg",
          "../shared/img/feed_portrait_dusk.jpg"
        ],
        colors: [
          { id: "titanium", name: "Titan Bạc", hex: "#D4D2CD" }
        ],
        overview: [
          {
            title: "Nhận Diện Cử Chỉ Tay OK & Dừng Lại",
            desc: "Giơ ký hiệu OK để kích hoạt bám theo, giơ lòng bàn tay để dừng quay mà không cần chạm vào điện thoại.",
            img: "../shared/img/thumb_02.jpg"
          },
          {
            title: "Tương Thích Mọi Ứng Dụng Livestream",
            desc: "Vì AI xử lý phần cứng độc lập nên hoạt động hoàn hảo với TikTok, Instagram Live, Facebook và Zoom.",
            img: "../shared/img/feed_person_portrait.jpg"
          },
          {
            title: "Lực Hít MagSafe 2.8kg Chắc Chắn",
            desc: "Gắn kết tức thời với iPhone hoặc ốp lưng từ tính an toàn tuyệt đối.",
            img: "../shared/img/feed_portrait_day.jpg"
          }
        ],
        boxContents: [
          "01 Mô-đun ngàm MagSafe AI Vision",
          "01 Vòng từ tính phụ trợ cho điện thoại khác",
          "01 Cáp sạc từ tính"
        ],
        specs: {
          "Cảm biến AI": "Camera quang học góc rộng 120°",
          "Tốc độ bám": "120 khung hình/giây",
          "Lực hút": "2.8kg Neodymium N52",
          "Khối lượng": "68g"
        },
        warranty: "Bảo hành 12 tháng 1 đổi 1 chính hãng.",
        tiers: [
          {
            key: "standard",
            label: "Ngàm AI Tiêu Chuẩn",
            name: "Ngàm MagSafe AI Vision",
            price: 990000,
            priceFormatted: "990.000₫",
            oldPriceFormatted: "1.290.000₫",
            save: "Tiết kiệm 300.000₫",
            gift: "Vòng từ tính đa năng",
            sku: "ACC-MAG-AI",
            stock: 220,
            ordersCount: 380,
            specs: "Camera AI độc lập • Điều khiển cử chỉ tay • Lực hút 2.8kg",
            highlights: [
              "Tự động xoay bám người khi livestream không cần qua app",
              "Điều khiển cử chỉ tay: Giơ bàn tay để dừng, giơ chữ V để chụp",
              "Nam châm MagSafe siêu mạnh hút 2.8kg chuẩn xác",
              "Tương thích hoàn hảo Smart Gimbal S1 và S2"
            ]
          }
        ]
      },

      // === PHỤ KIỆN 3: ĐÈN TRỢ SÁNG BI-COLOR LED ===
      {
        id: "acc-light",
        groupId: "cat-acc",
        name: "Đèn Trợ Sáng Bi-Color LED",
        tagline: "Ánh sáng studio mịn màng tôn da trong mọi khung hình.",
        subtitle: "Đèn LED hít từ tính MagSafe điều chỉnh nhiệt độ màu 2500K - 6500K, chỉ số hoàn màu CRI 96+, pin 3 giờ liên tục.",
        badge: "Phụ Kiện Studio",
        img: "../shared/img/thumb_03.jpg",
        status: "Đang Mở Bán",
        totalOrders: 290,
        orderGrowth: "+10%",
        is_flagship: false,
        gallery: [
          "../shared/img/thumb_03.jpg",
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_land_dusk.jpg"
        ],
        colors: [
          { id: "white", name: "Trắng Sữa", hex: "#FFFFFF" }
        ],
        overview: [
          {
            title: "Chỉ Số Hoàn Màu CRI 96+ Tự Nhiên",
            desc: "Giúp làn da hồng hào tự nhiên, tái tạo màu sắc chuẩn xác cho livestream bán hàng và quay vlog.",
            img: "../shared/img/thumb_03.jpg"
          },
          {
            title: "Dải Nhiệt Màu Linh Hoạt 2500K - 6500K",
            desc: "Dễ dàng chuyển đổi từ ánh sáng vàng ấm cúng sang ánh sáng trắng ban ngày chỉ với 1 núm xoay.",
            img: "../shared/img/feed_portrait_dusk.jpg"
          },
          {
            title: "Tích Hợp Tấm Tán Sáng Silicon Mịn Màng",
            desc: "Ánh sáng dịu nhẹ không gây chói mắt cho người mẫu khi quay cự ly gần.",
            img: "../shared/img/feed_portrait_day.jpg"
          }
        ],
        boxContents: [
          "01 Đèn LED Bi-Color",
          "01 Tấm tản sáng silicon",
          "01 Cáp sạc Type-C"
        ],
        specs: {
          "Độ sáng": "800 Lux tại 0.5m",
          "CRI": "96+ / TLCI 98+",
          "Nhiệt độ màu": "2500K - 6500K",
          "Thời lượng pin": "3 giờ ở độ sáng 50%"
        },
        warranty: "Bảo hành 12 tháng 1 đổi 1 chính hãng.",
        tiers: [
          {
            key: "standard",
            label: "Đèn LED Tiêu Chuẩn",
            name: "Đèn Trợ Sáng Bi-Color LED",
            price: 690000,
            priceFormatted: "690.000₫",
            oldPriceFormatted: "890.000₫",
            save: "Tiết kiệm 200.000₫",
            gift: "Tấm tản sáng silicon mềm",
            sku: "ACC-LIGHT",
            stock: 310,
            ordersCount: 290,
            specs: "CRI 96+ • Đổi màu 2500K-6500K • Hít MagSafe • Pin 3H",
            highlights: [
              "Hít từ tính MagSafe trực tiếp sau lưng điện thoại hoặc gimbal",
              "Dải nhiệt độ màu tùy chỉnh 2500K - 6500K êm dịu cho da",
              "Độ hoàn màu CRI 96+ chuẩn phòng thu truyền hình",
              "Pin tích hợp thắp sáng liên tục 3 giờ không lo cạn nguồn"
            ]
          }
        ]
      },

      // === PHỤ KIỆN 4: CHÂN ĐẾ TRIPOD MINI CARBON ===
      {
        id: "acc-tripod",
        groupId: "cat-acc",
        name: "Chân Đế Tripod Mini Carbon",
        tagline: "Vững chắc như kiềng ba chân trên mọi bề mặt.",
        subtitle: "Chân đế 3 chân gia công từ sợi carbon 8 lớp và hợp kim nhôm CNC, chân cao su chống trượt ren 1/4 tiêu chuẩn.",
        badge: "Phụ Kiện",
        img: "../shared/img/thumb_04.jpg",
        status: "Đang Mở Bán",
        totalOrders: 420,
        orderGrowth: "+14%",
        is_flagship: false,
        gallery: [
          "../shared/img/thumb_04.jpg",
          "../shared/img/feed_land_dusk.jpg",
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg"
        ],
        colors: [
          { id: "carbon-black", name: "Đen Vân Carbon", hex: "#222222" }
        ],
        overview: [
          {
            title: "Sợi Carbon 8 Lớp Siêu Cứng",
            desc: "Triệt tiêu độ rung lắc mặt sàn khi đặt gimbal quay Timelapse dài hạn trong gió.",
            img: "../shared/img/thumb_04.jpg"
          },
          {
            title: "Ren 1/4 Inch Chuẩn Quốc Tế",
            desc: "Lắp đặt vừa vặn với mọi gimbal, máy ảnh không gương lật và phụ kiện studio.",
            img: "../shared/img/feed_land_dusk.jpg"
          },
          {
            title: "Chân Đế Cao Su Đúc Chống Trượt Tuyệt Đối",
            desc: "Bám chắc chắn trên bề mặt đá hoa cương, kính trơn hoặc bùn đất dã ngoại.",
            img: "../shared/img/feed_portrait_dusk.jpg"
          }
        ],
        boxContents: [
          "01 Chân đế Tripod Carbon",
          "01 Khóa lục giác điều chỉnh độ siết chân"
        ],
        specs: {
          "Chất liệu": "Sợi Carbon 8X + Hợp kim nhôm 6061-T6",
          "Tải trọng tối đa": "5.0kg",
          "Khối lượng": "115g",
          "Chiều cao khi mở": "75mm"
        },
        warranty: "Bảo hành 24 tháng chính hãng.",
        tiers: [
          {
            key: "standard",
            label: "Tripod Mini Carbon",
            name: "Chân Đế Tripod Mini Carbon",
            price: 490000,
            priceFormatted: "490.000₫",
            oldPriceFormatted: "650.000₫",
            save: "Tiết kiệm 160.000₫",
            gift: "Khóa siết lục giác",
            sku: "ACC-TRIPOD",
            stock: 400,
            ordersCount: 420,
            specs: "Sợi Carbon 8 lớp • Chịu tải 5kg • Ren 1/4 tiêu chuẩn",
            highlights: [
              "Vật liệu sợi carbon 8 lớp giảm chấn rung triệt để",
              "Chân đế bọc silicon chống trượt trên bề mặt nghiêng",
              "Khả năng chịu tải cực cao lên đến 5.0kg",
              "Thiết kế gập phẳng ôm sát tay cầm gimbal êm ái"
            ]
          }
        ]
      },

      // === PHỤ KIỆN 5: VALI HỢP KIM CHỐNG SỐC ===
      {
        id: "acc-case",
        groupId: "cat-acc",
        name: "Vali Hợp Kim Chống Sốc",
        tagline: "Bảo vệ toàn diện thiết bị trong mọi chuyến bay.",
        subtitle: "Vali chống sốc khung hợp kim nhôm nguyên khối, mút định hình CNC cắt laser chính xác cho Gimbal S1 và trọn bộ phụ kiện.",
        badge: "Phụ Kiện",
        img: "../shared/img/thumb_05.jpg",
        status: "Đang Mở Bán",
        totalOrders: 180,
        orderGrowth: "+5%",
        is_flagship: false,
        gallery: [
          "../shared/img/thumb_05.jpg",
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_land_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg"
        ],
        colors: [
          { id: "silver", name: "Bạc Ánh Kim", hex: "#E5E5EA" },
          { id: "black", name: "Đen Nhám", hex: "#1C1C1E" }
        ],
        overview: [
          {
            title: "Khung Hợp Kim Nhôm Đúc Chịu Lực",
            desc: "Chống va đập mạnh, chống nén áp suất trong khoang hành lý máy bay.",
            img: "../shared/img/thumb_05.jpg"
          },
          {
            title: "Mút Xốp EVA Định Hình Cắt Laser Chuẩn Xác",
            desc: "Mỗi phụ kiện từ mic, cáp, đèn trợ sáng đều có ngăn chứa riêng ôm khít hoàn hảo.",
            img: "../shared/img/feed_portrait_dusk.jpg"
          },
          {
            title: "Khóa Kép Chắc Chắn & Chống Nước Chuẩn IP67",
            desc: "Gioăng cao su kín nước ngăn bụi bẩn và hơi ẩm xâm nhập làm mốc thấu kính.",
            img: "../shared/img/feed_land_dusk.jpg"
          }
        ],
        boxContents: [
          "01 Vali Hợp Kim Chống Sốc",
          "01 Dây đeo vai đệm khí",
          "02 Chìa khóa an toàn"
        ],
        specs: {
          "Kích thước": "320 × 240 × 110 mm",
          "Trọng lượng": "1.25kg",
          "Tiêu chuẩn": "Chống nước & kháng bụi IP67",
          "Vật liệu": "Hợp kim nhôm + Mút EVA mật độ cao"
        },
        warranty: "Bảo hành 24 tháng chính hãng.",
        tiers: [
          {
            key: "standard",
            label: "Vali Hợp Kim Chống Sốc",
            name: "Vali Hợp Kim Chống Sốc",
            price: 1190000,
            priceFormatted: "1.190.000₫",
            oldPriceFormatted: "1.590.000₫",
            save: "Tiết kiệm 400.000₫",
            gift: "Dây đeo vai đệm khí",
            sku: "ACC-CASE",
            stock: 95,
            ordersCount: 180,
            specs: "Khung nhôm nguyên khối • Mút EVA laser • Kháng nước IP67",
            highlights: [
              "Bảo vệ chống sốc tuyệt đối tiêu chuẩn hàng không",
              "Khay mút EVA cắt laser chính xác từng phụ kiện",
              "Chống nước kháng bụi chuẩn IP67 với gioăng cao su khép kín",
              "Quai xách êm ái kèm dây đeo vai giảm tải cơ động"
            ]
          }
        ]
      }
    ],

    // DEFAULT USERS (SYNCHRONIZED WITH ADMIN CMS & USER PORTAL)
    users: [
      {
        id: "usr-dung",
        name: "Đặng Anh Dũng",
        email: "dung.travel@gmail.com",
        phone: "0908 123 456",
        device: "Smart Gimbal S1 Titanium",
        tier: "Pro Cinema",
        tierBadge: "Pro Cinema Tier",
        memberSince: "Tháng 03/2025",
        serial: "SG-S1-VN-2025-8899",
        warrantyDays: 342,
        battery: 92,
        firmware: "v2.4.1 (Mới nhất)",
        status: "Hoạt Động",
        modules: [true, true, true, true, true, true, true]
      },
      {
        id: "usr-mailinh",
        name: "Mai Linh Creative",
        email: "mailinh.film@gmail.com",
        phone: "0909 234 567",
        device: "Smart Gimbal S1 Pro",
        tier: "Pro Cinema",
        tierBadge: "Pro Cinema Tier",
        memberSince: "Tháng 05/2025",
        serial: "SG-S1-VN-2025-6677",
        warrantyDays: 310,
        battery: 88,
        firmware: "v2.4.1 (Mới nhất)",
        status: "Hoạt Động",
        modules: [true, true, true, true, true, false, true]
      },
      {
        id: "usr-minh",
        name: "Nguyễn Văn Minh",
        email: "minh.vlog@gmail.com",
        phone: "0912 345 678",
        device: "Smart Gimbal S1 Air",
        tier: "Basic Creator",
        tierBadge: "Basic Creator Tier",
        memberSince: "Tháng 08/2025",
        serial: "SG-S1-VN-2025-4421",
        warrantyDays: 280,
        battery: 85,
        firmware: "v2.4.1 (Mới nhất)",
        status: "Hoạt Động",
        modules: [true, false, true, false, false, false, false]
      },
      {
        id: "usr-long",
        name: "Hoàng Long Studio",
        email: "long.cinema@film.vn",
        phone: "0933 888 999",
        device: "Smart Gimbal S2 Cinema",
        tier: "Enterprise Studio",
        tierBadge: "Enterprise Studio Tier",
        memberSince: "Tháng 01/2025",
        serial: "SG-S2-VN-2025-1102",
        warrantyDays: 365,
        battery: 98,
        firmware: "v2.4.1 (Mới nhất)",
        status: "Hoạt Động",
        modules: [true, true, true, true, true, true, true]
      },
      {
        id: "usr-huong",
        name: "Lê Thu Hương",
        email: "huong.media@gmail.com",
        phone: "0977 654 321",
        device: "Smart Gimbal S1",
        tier: "Basic Creator",
        tierBadge: "Basic Creator Tier",
        memberSince: "Tháng 09/2025",
        serial: "SG-S1-VN-2025-5532",
        warrantyDays: 295,
        battery: 90,
        firmware: "v2.4.1 (Mới nhất)",
        status: "Hoạt Động",
        modules: [true, false, false, false, false, false, false]
      },
      {
        id: "usr-ngoc",
        name: "Trần Bích Ngọc",
        email: "ngoc.agency@film.vn",
        phone: "0988 999 111",
        device: "SmartCam Pocket P1",
        tier: "Pro Cinema",
        tierBadge: "Pro Cinema Tier",
        memberSince: "Tháng 04/2025",
        serial: "SC-P1-VN-2025-9920",
        warrantyDays: 320,
        battery: 94,
        firmware: "v2.4.1 (Mới nhất)",
        status: "Hoạt Động",
        modules: [true, true, true, true, true, false, false]
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
