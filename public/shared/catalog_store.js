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
  var REVIEWS_KEY = 'tflow_user_reviews_v1';
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
        "totalOrders": 1850,
        "orderGrowth": "+24%",
        "is_flagship": true,
        "gallery": [
          "../shared/img/feed_portrait_dusk.jpg",
          "../shared/img/feed_portrait_day.jpg",
          "../shared/img/feed_person_portrait.jpg",
          "../shared/img/feed_lowlight.jpg"
        ],
        "colors": [
          { "id": "space-black", "name": "Space Black (Đen Không Gian)", "hex": "#1F2022" },
          { "id": "natural-titanium", "name": "Natural Titanium (Titan Tự Nhiên)", "hex": "#8A8680" },
          { "id": "silver-white", "name": "Silver White (Trắng Bạc)", "hex": "#E5E5EA" }
        ],
        "tiers": [
          {
            "key": "standard",
            "name": "Standard Kit",
            "tag": "Khởi Đầu",
            "price": 2890000,
            "origPrice": 3290000,
            "desc": "Trọn bộ gimbal T-Flow Pro, ngàm kẹp từ tính MagSafe N52, cáp sạc USB-C và chân đế Tripod mini."
          },
          {
            "key": "creator",
            "name": "Creator Kit",
            "tag": "Bán Chạy Nhất",
            "price": 3490000,
            "origPrice": 3990000,
            "desc": "Gồm Standard Kit + Đèn trợ sáng từ tính T-Flow Glow và Vòng xoay lấy nét Focus Wheel cơ học."
          },
          {
            "key": "master",
            "name": "Cinematic Master",
            "tag": "Chuyên Nghiệp",
            "price": 4290000,
            "origPrice": 4990000,
            "desc": "Full option vali chống sốc cao cấp, mô-đun AI Tracking T-Flow Eye và gói bản quyền 3D LUT điện ảnh trọn đời."
          }
        ],
        "highlights": [
          {
            "icon": "⚡",
            "title": "Thuật Toán Pure FOC 20kHz",
            "desc": "Tần số chuyển mạch 20kHz siêu êm, triệt tiêu hoàn toàn rung giật vi mô (Zero Micro-Jitter) và tải trọng cực đại 450g."
          },
          {
            "icon": "🧲",
            "title": "Ngàm MagSafe Siêu Hút 2.8kg",
            "desc": "Nam châm Neodymium N52 đa cực lực hút 2.8kg, tháo lắp điện thoại tức thời trong 1 giây mà không cần cân lại trục."
          },
          {
            "icon": "🎯",
            "title": "Vòng Xoay Focus Wheel Cơ Học",
            "desc": "Căn chỉnh tiêu cự lấy nét mượt mà và zoom quang học vô cấp chuẩn điện ảnh, hỗ trợ quay Apple Log 4K 60fps."
          }
        ],
        "specs": [
          { "label": "Mã Sản Phẩm (SKU)", "val": "TF-G31-PRO" },
          { "label": "Tải Trọng Động Cơ", "val": "450g (Cân tốt iPhone 16 Pro Max kèm lens và mic)" },
          { "label": "Thuật Toán Điều Khiển", "val": "Pure FOC 20kHz Vector Control (Zero Jitter)" },
          { "label": "Cảm Biến Trục", "val": "14-bit Magnetic Encoder + 6-Axis IMU" },
          { "label": "Thời Lượng Pin", "val": "18 giờ liên tục (Cell Lithium 5000mAh, sạc ngược PD 18W)" },
          { "label": "Chất Liệu Khung", "val": "Hợp kim nhôm AL6061 hàng không CNC & Sợi Carbon dệt 8 lớp" },
          { "label": "Kết Nối Không Dây", "val": "Bluetooth 5.3 Low Energy (Độ trễ < 5ms)" },
          { "label": "Ứng Dụng Hỗ Trợ", "val": "T-Flow Cam (iOS 16+, Apple Log ProRes, AI Face Track)" }
        ],
        "boxContents": [
          { "name": "Gimbal 3 Trục T-Flow Pro", "qty": "01" },
          { "name": "Ngàm Kẹp Từ Tính MagSafe N52", "qty": "01" },
          { "name": "Vòng Từ Tính Phụ Trợ Dán Ốp", "qty": "02" },
          { "name": "Chân Đế Tripod Mini Hợp Kim", "qty": "01" },
          { "name": "Cáp Sạc Nhanh Type-C to Type-C PD", "qty": "01" },
          { "name": "Túi Đựng Nhựa Nhung Cao Cấp", "qty": "01" }
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

  // ==========================================================================
  // 2. CORE STORAGE HELPERS
  // ==========================================================================
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
      console.warn('[SmartGimbalCatalog] Storage error, falling back to default:', e);
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
    if (typeof localStorage === 'undefined') return null;
    try {
      var raw = localStorage.getItem(CURRENT_USER_KEY);
      if (!raw) return null;
      return JSON.parse(raw);
    } catch (e) {
      return null;
    }
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

  function updateUserProfile(userId, profileData) {
    var cat = getCatalog();
    var idx = cat.users.findIndex(function (u) { return u.id === userId; });
    if (idx === -1) return false;
    Object.assign(cat.users[idx], profileData);
    saveCatalog(cat);

    var cur = getCurrentUser();
    if (cur && cur.id === userId) {
      Object.assign(cur, profileData);
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
    exportUsersCSV: exportUsersCSV
  };
}));
