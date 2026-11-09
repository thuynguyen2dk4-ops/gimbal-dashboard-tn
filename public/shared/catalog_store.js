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

  var STORAGE_KEY = 'TFLOW_STORE_FINAL_V6';
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
      "desc": "Không dùng mã số phức tạp. Giữ tên gọi dưới 4 từ để hiển thị đẹp trên vỏ hộp và sàn TMĐT.",
      "convention": "Hậu tố: Go/Air (Gọn nhẹ, phổ thông) • Pro/Max (Cao cấp, tải nặng) • SE (Bản rút gọn giá tốt)",
      "example": "T-Flow Go, T-Flow Pro, T-Flow Air, T-Flow Eye"
    },
    {
      "id": "rule-2",
      "title": "2. Quy tắc Mã Kỹ thuật (SKU / PCB)",
      "formula": "TF - [Phân hệ][Thông số] - [Chức năng] - [Rev]",
      "desc": "TF là tiền tố cố định. Phân hệ: G (Gimbal), CAM (Camera), M (Mainboard), D (Driver), X (Mạch mở rộng/Cảm biến), B (Bridge - Mạch chuyển đổi). [Rev]: Bản phần cứng (R1.0, R1.1).",
      "convention": "In lụa bắt buộc trên PCB kèm chữ ký: 'Engineered by T-Flow in Hanoi' & 'Pure FOC Inside - Zero Jitter'",
      "example": "TF-D3X-FOC-R1.0, TF-G31-PRO-R1.0, TF-CAM-AI01-R1.0"
    },
    {
      "id": "rule-3",
      "title": "3. Quy tắc Đánh mã Chi tiết Cơ khí / In 3D",
      "formula": "TF - [Mã Máy] - MEC - [Số thứ tự] - [Vật liệu]",
      "desc": "Dùng để quản lý các file CAD 3D, bản vẽ kỹ thuật 2D, file STL in 3D và gia công cơ khí chính xác CNC.",
      "convention": "Vật liệu: PETG (Nhựa in 3D), AL6061 (Nhôm hàng không CNC), CF (Sợi carbon)",
      "example": "TF-G31-MEC-01-PETG, TF-G31-MEC-02-AL6061"
    },
    {
      "id": "rule-4",
      "title": "4. Quy tắc Đặt tên Kho mã nguồn (GitHub / Firmware)",
      "formula": "tflow-[phân-hệ]-[loại-code]",
      "desc": "Viết thường toàn bộ, nối bằng dấu gạch ngang (-) để chuẩn hóa đường dẫn lập trình trên Git và CI/CD.",
      "convention": "Phân nhánh: main (production), develop (phát triển), feature/ (tính năng mới)",
      "example": "tflow-g31-firmware, tflow-foc-library, tflow-studio-app, tflow-cam-ios"
    },
    {
      "id": "rule-5",
      "title": "5. Quy tắc Đánh số Phiên bản (Versioning)",
      "formula": "v[Major].[Minor].[Patch]",
      "desc": "Major: Thay đổi kiến trúc lớn (đổi dòng chip STM32, đổi cấu trúc cơ khí) • Minor: Thêm tính năng mới (chế độ Inception, tối ưu FOC) • Patch: Sửa lỗi nhỏ (Fix bug).",
      "convention": "Áp dụng đồng bộ cho Firmware phần cứng, Phần mềm máy tính và App điện thoại",
      "example": "FW-TF-G31-v1.2.0, FW-TF-D3X-v1.0.4"
    }
  ],
  "groups": [
    {
      "id": "group-gimbal",
      "name": "Gimbal Cầm Tay",
      "desc": "Thiết bị chống rung 3 trục chuẩn điện ảnh cho Smartphone",
      "badge": "Sản Phẩm Chủ Lực"
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
          "title": "Vòng Xoay Focus & Zoom Cơ Khí Chính Xác Tuyệt Đối",
          "desc": "Vòng xoay kim loại CNC đa năng ở cạnh thân máy cho phép người dùng vê nét tay mượt mà như ống kính máy quay điện ảnh hoặc điều khiển tiêu cự zoom từng milimet êm ái.",
          "img": "../shared/img/feed_person_portrait.jpg"
        },
        {
          "title": "Động Cơ Tải Trọng Lớn 450g & Thuật Toán Pure FOC 20kHz",
          "desc": "Cân mọi dòng điện thoại kích thước lớn kể cả iPhone 13-16 Pro Max kèm phụ kiện kính lọc và micro. Tần số điều khiển vector 20kHz triệt tiêu hoàn toàn rung giật micro-jitter.",
          "img": "../shared/img/feed_portrait_day.jpg"
        },
        {
          "title": "Khung Hợp Kim Nhôm Hàng Không & Sợi Carbon Dệt 8 Lớp",
          "desc": "Vừa đạt độ cứng cáp và khả năng hấp thụ rung động cơ học tối đa, vừa giữ trọng lượng thân máy nhẹ nhàng cho cả ngày quay liên tục không mỏi tay.",
          "img": "../shared/img/feed_portrait_dusk.jpg"
        }
      ],
      "boxContents": [
        "Thân Gimbal 3 trục T-Flow Pro (Mã SKU: TF-G31-PRO)",
        "Chân đế Tripod hợp kim nhôm bọc silicon chống trượt",
        "Cáp sạc nhanh Type-C bện dù cao cấp (1.2m) hỗ trợ PD 18W",
        "Túi đựng chống sốc cao cấp chuẩn du lịch kháng nước",
        "Sách hướng dẫn sử dụng tiếng Việt & Thẻ bảo hành chính hãng 24 tháng"
      ],
      "specs": {
        "Mã Kỹ Thuật (SKU / In trên PCB)": "TF-G31-PRO-R1.0",
        "Số Trục Ổn Định": "3 Trục (Pan • Roll • Tilt) điều khiển độc lập Pure FOC",
        "Tải Trọng Hỗ Trợ Tối Đa": "150g – 450g (Tương thích iPhone 13-16 Pro Max)",
        "Phạm Vi Góc Quay Cơ Học": "Pan 360° Không giới hạn • Roll 335° • Tilt 335°",
        "Dung Lượng Pin & Thời Gian Dùng": "4800 mAh Li-ion (Dùng liên tục 18 giờ)",
        "Thời Gian Sạc Đầy": "2 giờ qua cổng USB-C Power Delivery 18W",
        "Cổng Xuất Nguồn Sạc": "USB-C 5V/1A sạc ngược trực tiếp cho điện thoại",
        "Kết Nối Không Dây": "Bluetooth 5.3 Low Energy (Độ trễ < 8ms)",
        "Vật Liệu Khung Thân": "Hợp kim nhôm AL6061 kết hợp sợi Carbon dệt 8 lớp",
        "Chữ Ký Kỹ Thuật Silkscreen": "Engineered by T-Flow in Hanoi • Pure FOC Inside"
      },
      "warranty": "Bảo hành chính hãng 24 tháng 1 đổi 1 trong 30 ngày đầu tiên tại Công ty TNHH Công nghệ T-Flow Việt Nam.",
      "tiers": [
        {
          "key": "tier-pro-std",
          "id": "tier-pro-std",
          "label": "Gói Tiêu Chuẩn (Standard Kit)",
          "name": "Gói Tiêu Chuẩn (Standard Kit)",
          "price": 2890000,
          "priceFormatted": "2.890.000₫",
          "oldPriceFormatted": "3.290.000₫",
          "sku": "TF-G31-PRO-STD",
          "badge": "Bán Chạy Nhất",
          "specs": "Thân T-Flow Pro + Mini Tripod + Cáp sạc PD + Túi chống sốc",
          "desc": "Thân T-Flow Pro + Chân đế Mini Tripod nhôm + Cáp sạc USB-C + Túi chống sốc",
          "is_featured": true,
          "highlights": [
            "Thân Gimbal T-Flow Pro FOC 20kHz tải trọng 450g",
            "Vòng xoay kim loại Focus Wheel cơ khí chính xác",
            "Chân đế Tripod nhôm bọc silicon chống trượt",
            "Bảo hành chính hãng 24 tháng 1 đổi 1"
          ]
        },
        {
          "key": "tier-pro-combo",
          "id": "tier-pro-combo",
          "label": "Combo Sáng Tạo (Creator Kit)",
          "name": "Combo Sáng Tạo (Creator Kit)",
          "price": 3490000,
          "priceFormatted": "3.490.000₫",
          "oldPriceFormatted": "4.190.000₫",
          "sku": "TF-G31-PRO-COMBO",
          "badge": "Khuyên Dùng",
          "specs": "Kèm Mắt thần AI T-Flow Eye + Đèn trợ sáng T-Flow Glow",
          "desc": "T-Flow Pro + Mắt thần AI T-Flow Eye (bám nét không cần App) + Đèn trợ sáng T-Flow Glow",
          "is_featured": false,
          "highlights": [
            "Bao gồm toàn bộ Gói Tiêu Chuẩn",
            "Mô-đun Camera AI T-Flow Eye nhận diện cử chỉ 60fps",
            "Đèn trợ sáng từ tính T-Flow Glow CRI 95+ 3 dải màu",
            "Tặng kèm túi đeo chéo thời trang chống nước"
          ]
        },
        {
          "key": "tier-pro-cine",
          "id": "tier-pro-cine",
          "label": "Combo Điện Ảnh (Cinematic Master)",
          "name": "Combo Điện Ảnh (Cinematic Master)",
          "price": 4290000,
          "priceFormatted": "4.290.000₫",
          "oldPriceFormatted": "5.290.000₫",
          "sku": "TF-G31-PRO-CINE",
          "badge": "Chuyên Nghiệp",
          "specs": "Trọn bộ Kèm Vali nhôm IP67 + Micro không dây 2.4GHz",
          "desc": "Trọn bộ T-Flow Pro + T-Flow Eye AI + T-Flow Glow + Vali nhôm chống nước IP67 + Micro không dây 2.4GHz",
          "is_featured": false,
          "highlights": [
            "Trọn bộ combo tối thượng cho nhà làm phim & vlogger",
            "Vali hợp kim nhôm đúc chống va đập IP67 chuẩn hàng không",
            "Micro không dây kép 2.4GHz cự ly thu 100m",
            "Dịch vụ bảo hành vàng đổi mới ngay tại nhà"
          ]
        }
      ]
    }
  ],
  "users": [
    {
      "id": "thuy-nguyen",
      "name": "Thuy Nguyen",
      "email": "thuynguyen2dk4@gmail.com",
      "phone": "0908 888 888",
      "role": "Master Administrator & Founder",
      "company": "Công ty TNHH Công nghệ T-Flow Việt Nam",
      "tierBadge": "Master Admin",
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
      
  // ==========================================================================
  // GMAIL AUTHENTICATION & ROLE-BASED ACCESS CONTROL (NO PASSWORD REQUIRED)
  // ==========================================================================
  var ADMIN_GMAILS = ['thuynguyen2dk4@gmail.com', 'thuy.nguyen@tflow.tech'];

  function isUserAdmin(user) {
    if (!user || !user.email) return false;
    var em = user.email.trim().toLowerCase();
    return ADMIN_GMAILS.indexOf(em) !== -1 || (user.role && user.role.toLowerCase().indexOf('admin') !== -1);
  }

  function loginWithGmail(email, displayName) {
    if (!email) 
  // ==========================================================================
  // REVIEWS & TESTIMONIALS API
  // ==========================================================================
  var REVIEWS_KEY = 'tflow_user_reviews_v1';
  var REVIEWS_EVENT = 'tflow_reviews_updated';

  var DEFAULT_REVIEWS = [
    {
      id: "rev-01",
      author: "Đặng Anh Dũng",
      avatar: "D",
      role: "Travel Filmmaker • 1.2M Followers",
      package: "T-Flow Pro - Cinematic Master",
      rating: 5,
      date: "15/10/2026",
      title: "Ngàm MagSafe và động cơ FOC là bước đột phá xuất sắc!",
      comment: "Ngàm MagSafe là bước cải tiến xuất sắc nhất trên T-Flow Pro. Khi cần rút máy ra nghe điện thoại hoặc đổi góc quay cầm tay, chỉ mất đúng một giây mà không phải cân lại trục. Động cơ FOC tải trọng 450g giữ máy cực kỳ vững vàng.",
      tags: ["MagSafe cực nhạy", "Chống rung FOC", "Tải trọng 450g"],
      verified: true
    },
    {
      id: "rev-02",
      author: "Mai Linh Creative",
      avatar: "M",
      role: "Đạo Diễn Hình Ảnh (DoP)",
      package: "T-Flow Pro - Creator Kit",
      rating: 5,
      date: "28/10/2026",
      title: "Vòng xoay lấy nét Focus Wheel mượt mà như máy điện ảnh",
      comment: "Bánh xe lấy nét cơ học rất êm và có lực cản vừa phải. Khi kết hợp với chế độ quay Apple Log trên iPhone 16 Pro Max qua App T-Flow Cam, kết quả cho ra như máy quay phim rạp. Cực kỳ ấn tượng với hoàn thiện sợi Carbon 8 lớp.",
      tags: ["Focus Wheel êm", "Apple Log Pro", "Sợi Carbon 8 lớp"],
      verified: true
    },
    {
      id: "rev-03",
      author: "Trần Hoàng Nam",
      avatar: "N",
      role: "Tech Reviewer & Nhiếp Ảnh Gia",
      package: "T-Flow Pro - Standard Kit",
      rating: 5,
      date: "02/11/2026",
      title: "Triệt tiêu hoàn toàn micro-jitter trên địa hình gồ ghề",
      comment: "Thuật toán Pure FOC 20kHz triệt tiêu hoàn toàn hiện tượng rung giật micro-jitter. Ngay cả khi đi bộ nhanh trên địa hình sỏi đá hay chạy theo chủ thể, đường chân trời vẫn thẳng tắp và mượt mà từng khoảnh khắc.",
      tags: ["Zero Jitter", "Horizon Lock", "Pin trâu 18h"],
      verified: true
    }
  ];

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
      console.warn('[SmartGimbalCatalog] Error parsing reviews:', e);
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
      avatar: authorName.charAt(0).toUpperCase() || 'T',
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

    reviews.unshift(newRev); // Prepend to top

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
    var filtered = reviews.filter(function(r) { return r.id !== reviewId; });
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

  return { success: false, message: 'Vui lòng cung cấp email Google (Gmail) hợp lệ.' };
    var cleanEmail = email.trim().toLowerCase();
    var isAdmin = (ADMIN_GMAILS.indexOf(cleanEmail) !== -1);

    var cat = getCatalog();
    var user = (cat.users || []).find(function (u) { return u.email && u.email.toLowerCase() === cleanEmail; });

    if (!user) {
      user = {
        id: cleanEmail.replace(/[^a-zA-Z0-9]/g, '-'),
        name: displayName || (isAdmin ? 'Thuy Nguyen' : cleanEmail.split('@')[0]),
        email: cleanEmail,
        phone: isAdmin ? '0908 888 888' : '',
        role: isAdmin ? 'Master Administrator & Founder' : 'Khách Hàng Thành Viên',
        company: 'Công ty TNHH Công nghệ T-Flow Việt Nam',
        tierBadge: isAdmin ? 'Master Admin' : 'Thành Viên Mới',
        registeredDevice: isAdmin ? 'T-Flow Pro (TF-G31-PRO)' : 'T-Flow Pro',
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
    }

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user));
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

    return { success: true, user: found };
    }
    
  // ==========================================================================
  // GMAIL AUTHENTICATION & ROLE-BASED ACCESS CONTROL (NO PASSWORD REQUIRED)
  // ==========================================================================
  var ADMIN_GMAILS = ['thuynguyen2dk4@gmail.com', 'thuy.nguyen@tflow.tech'];

  function isUserAdmin(user) {
    if (!user || !user.email) return false;
    var em = user.email.trim().toLowerCase();
    return ADMIN_GMAILS.indexOf(em) !== -1 || (user.role && user.role.toLowerCase().indexOf('admin') !== -1);
  }

  function loginWithGmail(email, displayName) {
    if (!email) return { success: false, message: 'Vui lòng cung cấp email Google (Gmail) hợp lệ.' };
    var cleanEmail = email.trim().toLowerCase();
    var isAdmin = (ADMIN_GMAILS.indexOf(cleanEmail) !== -1);

    var cat = getCatalog();
    var user = (cat.users || []).find(function (u) { return u.email && u.email.toLowerCase() === cleanEmail; });

    if (!user) {
      user = {
        id: cleanEmail.replace(/[^a-zA-Z0-9]/g, '-'),
        name: displayName || (isAdmin ? 'Thuy Nguyen' : cleanEmail.split('@')[0]),
        email: cleanEmail,
        phone: isAdmin ? '0908 888 888' : '',
        role: isAdmin ? 'Master Administrator & Founder' : 'Khách Hàng Thành Viên',
        company: 'Công ty TNHH Công nghệ T-Flow Việt Nam',
        tierBadge: isAdmin ? 'Master Admin' : 'Thành Viên Mới',
        registeredDevice: isAdmin ? 'T-Flow Pro (TF-G31-PRO)' : 'T-Flow Pro',
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
    }

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user));
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

    return { success: false, message: 'Email hoặc số điện thoại không tồn tại trong hệ thống!' };
  }

  function registerUser(userData) {
    var cat = getCatalog();
    var exists = cat.users.some(function (u) { return u.email.toLowerCase() === userData.email.toLowerCase(); });
    if (exists) {
      
  // ==========================================================================
  // GMAIL AUTHENTICATION & ROLE-BASED ACCESS CONTROL (NO PASSWORD REQUIRED)
  // ==========================================================================
  var ADMIN_GMAILS = ['thuynguyen2dk4@gmail.com', 'thuy.nguyen@tflow.tech'];

  function isUserAdmin(user) {
    if (!user || !user.email) return false;
    var em = user.email.trim().toLowerCase();
    return ADMIN_GMAILS.indexOf(em) !== -1 || (user.role && user.role.toLowerCase().indexOf('admin') !== -1);
  }

  function loginWithGmail(email, displayName) {
    if (!email) return { success: false, message: 'Vui lòng cung cấp email Google (Gmail) hợp lệ.' };
    var cleanEmail = email.trim().toLowerCase();
    var isAdmin = (ADMIN_GMAILS.indexOf(cleanEmail) !== -1);

    var cat = getCatalog();
    var user = (cat.users || []).find(function (u) { return u.email && u.email.toLowerCase() === cleanEmail; });

    if (!user) {
      user = {
        id: cleanEmail.replace(/[^a-zA-Z0-9]/g, '-'),
        name: displayName || (isAdmin ? 'Thuy Nguyen' : cleanEmail.split('@')[0]),
        email: cleanEmail,
        phone: isAdmin ? '0908 888 888' : '',
        role: isAdmin ? 'Master Administrator & Founder' : 'Khách Hàng Thành Viên',
        company: 'Công ty TNHH Công nghệ T-Flow Việt Nam',
        tierBadge: isAdmin ? 'Master Admin' : 'Thành Viên Mới',
        registeredDevice: isAdmin ? 'T-Flow Pro (TF-G31-PRO)' : 'T-Flow Pro',
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
    }

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user));
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
    
  // ==========================================================================
  // GMAIL AUTHENTICATION & ROLE-BASED ACCESS CONTROL (NO PASSWORD REQUIRED)
  // ==========================================================================
  var ADMIN_GMAILS = ['thuynguyen2dk4@gmail.com', 'thuy.nguyen@tflow.tech'];

  function isUserAdmin(user) {
    if (!user || !user.email) return false;
    var em = user.email.trim().toLowerCase();
    return ADMIN_GMAILS.indexOf(em) !== -1 || (user.role && user.role.toLowerCase().indexOf('admin') !== -1);
  }

  function loginWithGmail(email, displayName) {
    if (!email) return { success: false, message: 'Vui lòng cung cấp email Google (Gmail) hợp lệ.' };
    var cleanEmail = email.trim().toLowerCase();
    var isAdmin = (ADMIN_GMAILS.indexOf(cleanEmail) !== -1);

    var cat = getCatalog();
    var user = (cat.users || []).find(function (u) { return u.email && u.email.toLowerCase() === cleanEmail; });

    if (!user) {
      user = {
        id: cleanEmail.replace(/[^a-zA-Z0-9]/g, '-'),
        name: displayName || (isAdmin ? 'Thuy Nguyen' : cleanEmail.split('@')[0]),
        email: cleanEmail,
        phone: isAdmin ? '0908 888 888' : '',
        role: isAdmin ? 'Master Administrator & Founder' : 'Khách Hàng Thành Viên',
        company: 'Công ty TNHH Công nghệ T-Flow Việt Nam',
        tierBadge: isAdmin ? 'Master Admin' : 'Thành Viên Mới',
        registeredDevice: isAdmin ? 'T-Flow Pro (TF-G31-PRO)' : 'T-Flow Pro',
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
    }

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user));
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

  
  // ==========================================================================
  // GMAIL AUTHENTICATION & ROLE-BASED ACCESS CONTROL (NO PASSWORD REQUIRED)
  // ==========================================================================
  var ADMIN_GMAILS = ['thuynguyen2dk4@gmail.com', 'thuy.nguyen@tflow.tech'];

  function isUserAdmin(user) {
    if (!user || !user.email) return false;
    var em = user.email.trim().toLowerCase();
    return ADMIN_GMAILS.indexOf(em) !== -1 || (user.role && user.role.toLowerCase().indexOf('admin') !== -1);
  }

  function loginWithGmail(email, displayName) {
    if (!email) return { success: false, message: 'Vui lòng cung cấp email Google (Gmail) hợp lệ.' };
    var cleanEmail = email.trim().toLowerCase();
    var isAdmin = (ADMIN_GMAILS.indexOf(cleanEmail) !== -1);

    var cat = getCatalog();
    var user = (cat.users || []).find(function (u) { return u.email && u.email.toLowerCase() === cleanEmail; });

    if (!user) {
      user = {
        id: cleanEmail.replace(/[^a-zA-Z0-9]/g, '-'),
        name: displayName || (isAdmin ? 'Thuy Nguyen' : cleanEmail.split('@')[0]),
        email: cleanEmail,
        phone: isAdmin ? '0908 888 888' : '',
        role: isAdmin ? 'Master Administrator & Founder' : 'Khách Hàng Thành Viên',
        company: 'Công ty TNHH Công nghệ T-Flow Việt Nam',
        tierBadge: isAdmin ? 'Master Admin' : 'Thành Viên Mới',
        registeredDevice: isAdmin ? 'T-Flow Pro (TF-G31-PRO)' : 'T-Flow Pro',
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
    }

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(CURRENT_USER_KEY, JSON.stringify(user));
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
    loginWithGmail: loginWithGmail,
    isUserAdmin: isUserAdmin,
    logoutUser: logoutUser,
    // Reviews API
    getReviews: getReviews,
    addReview: addReview,
    deleteReview: deleteReview,
    REVIEWS_EVENT: REVIEWS_EVENT,
    registerUser: registerUser,
    logoutUser: logoutUser,
    // Reviews API
    getReviews: getReviews,
    addReview: addReview,
    deleteReview: deleteReview,
    REVIEWS_EVENT: REVIEWS_EVENT,
    updateUserProfile: updateUserProfile,
    updateUserModules: updateUserModules,
    // Excel CSV Import / Export
    exportProductsCSV: exportProductsCSV,
    importProductsCSV: importProductsCSV,
    exportUsersCSV: exportUsersCSV
  };
}));
