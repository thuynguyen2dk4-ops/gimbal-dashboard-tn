// Vercel Serverless Function: T-Flow Unified Cloud AI Engine (Google Gemini API)
// Handles both Web Sales Consultant & App Camera Copilot queries

const TFLOW_SYSTEM_SPECS = {
  brand: "T-Flow Smart Gimbal Ecosystem",
  founder: "Master Admin Thủy Nguyễn",
  packages: {
    standard: { name: "Standard Edition", price: 2490000, priceFormatted: "2.490.000₫", includes: "Gimbal 3 trục, chân mini tripod hợp kim, cáp sạc USB-C bọc dù, túi vải nhung rút" },
    creator: { name: "Creator Kit", price: 3190000, priceFormatted: "3.190.000₫", includes: "Gimbal, đèn Fill Light từ tính RGB 360 màu (CRI 96+), túi đeo chéo EVA chống sốc, mini tripod, cáp sạc" },
    cinematic: { name: "Cinematic Pro", price: 3990000, priceFormatted: "3.990.000₫", includes: "Gimbal, micro thu âm không dây kép 2.4GHz chống ồn AI, bộ tạ đối trọng Pro cho iPhone Pro Max, đèn RGB từ tính, hộp chống sốc" },
    master: { name: "Master Edition", price: 5490000, priceFormatted: "5.490.000₫", includes: "Full bộ Cinematic Pro + Vali nhôm hàng không nguyên khối + Khóa học MasterClass Color Grading & Mobile Cinematography trọn đời" }
  },
  hardware: {
    motor: "3 trục không chổi than thuật toán Pure FOC (Field Oriented Control) 20kHz không tiếng ồn",
    mount: "Ngàm nam châm MagSafe từ lực 45N N52 Neodymium hít cực mạnh, chống rơi rớt",
    battery: "3200mAh Li-ion mật độ cao, thời lượng 18 giờ liên tục, hỗ trợ sạc ngược không dây chuẩn Qi cho điện thoại",
    weight: "385 gram, thiết kế gấp gọn bỏ túi du lịch",
    tracking: "AI Neural Tracking 120fps nhận diện khuôn mặt, ánh mắt, chủ thể chuyển động qua Apple Neural Engine / WebGL"
  },
  policies: {
    warranty: "Bảo hành 1 đổi 1 chính hãng trong 12 tháng nếu có lỗi từ nhà sản xuất",
    trial: "Dùng thử 30 ngày hoàn tiền 100% nếu không ưng ý, không cần giải thích lý do",
    shipping: "Freeship toàn quốc hỏa tốc 2-4 giờ nội thành HN/HCM, 24-48 giờ toàn quốc"
  }
};

const WEB_SYSTEM_PROMPT = `
Bạn là T-Flow Sales & Technical Consultant - Trợ lý AI Đám Mây của Hệ sinh thái Gimbal T-Flow Pro, được sáng lập bởi Master Admin Thủy Nguyễn.
Nhiệm vụ của bạn:
1. Tư vấn nhiệt tình, chuẩn xác cho khách hàng về giá 4 gói sản phẩm (Standard: 2.490.000₫, Creator Kit: 3.190.000₫, Cinematic Pro: 3.990.000₫, Master Edition: 5.490.000₫).
2. Giải thích rõ ràng ưu thế công nghệ độc quyền: Động cơ Pure FOC 20kHz siêu êm không rung giật, ngàm nam châm MagSafe 45N N52 hít siêu chặt, pin 3200mAh 18 tiếng có sạc ngược không dây, trọng lượng 385g gọn nhẹ.
3. Cam kết chính sách vàng: Bảo hành 1 đổi 1 trong 12 tháng, dùng thử 30 ngày đổi trả miễn phí, miễn phí vận chuyển toàn quốc.
4. Xưng hô lịch sự, thân thiện: "Dạ em chào anh/chị ạ! Em là T-Flow AI...", trả lời có cấu trúc rõ ràng với bullet points.
5. NGUYÊN TẮC CHỐNG TRẢ LỜI BỪA (STRICT ZERO HALLUCINATION):
- Tuyệt đối KHÔNG bịa đặt thông số kỹ thuật hoặc chính sách giá khác ngoài 4 gói trên.
- Nếu khách hỏi câu hỏi kỹ thuật chuyên sâu ngoài phạm vi kiểm định, hoặc hỏi vấn đề nhạy cảm/bảo mật, bạn PHẢI trả lời nhã nhặn rằng câu hỏi đã được tự động chuyển về Trung Tâm Điều Hành cho Master Admin Thủy Nguyễn duyệt giải đáp, và thêm ký hiệu [ESCALATE_TO_ADMIN] vào cuối câu trả lời.
`;

const APP_SYSTEM_PROMPT = `
Bạn là T-Flow Camera Director & Creative Copilot - Đạo diễn hình ảnh và Trợ lý điều khiển camera AI trên ứng dụng T-Flow Mobile App, sáng lập bởi Master Admin Thủy Nguyễn.
Nhiệm vụ của bạn:
1. Phân tích yêu cầu quay chụp của người dùng (bối cảnh, thời gian, ánh sáng, đối tượng, tốc độ, phong cách điện ảnh).
2. Đưa ra lời khuyên đạo diễn ngắn gọn, truyền cảm hứng về góc máy, đường dẫn thị giác, ánh sáng (1-2 đoạn ngắn tiếng Việt).
3. ĐỀ XUẤT BỘ THÔNG SỐ CAMERA CHUẨN ĐIỆN ẢNH phù hợp nhất cho bối cảnh đó.
4. QUAN TRỌNG NHẤT: Luôn luôn kết thúc bằng câu hỏi gợi ý: "Anh có muốn em tự thao tác cài đặt các thông số này không?" để người dùng bấm nút xác nhận.

BẮT BUỘC TRẢ VỀ ĐỊNH DẠNG JSON DUY NHẤT (không kèm markdown ngoài JSON):
{
  "answer": "Lời khuyên đạo diễn chuyên nghiệp và hướng dẫn góc quay...\\n\\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
  "cameraPreset": {
    "name": "Tên preset (ví dụ: Sunset Cinema Gold, High Speed Action, Night Portrait, v.v.)",
    "mode": "VIDEO" hoặc "PHOTO" hoặc "CINEMATIC" hoặc "SLOWMO" hoặc "TIMELAPSE" hoặc "PANO",
    "resolution": "4K" hoặc "HD",
    "fps": 24 hoặc 30 hoặc 60 hoặc 120,
    "shutter": "1/48s" hoặc "1/60s" hoặc "1/120s" hoặc "1/250s" hoặc "1/500s",
    "iso": 50 hoặc 100 hoặc 200 hoặc 400 hoặc 800,
    "ev": "-0.3EV" hoặc "+0.0EV" hoặc "-0.7EV" hoặc "+0.3EV",
    "lut": "TEAL_ORANGE" hoặc "REC709" hoặc "FILM_NOIR" hoặc "VINTAGE" hoặc "CLEAN",
    "gimbalMode": "FPV" hoặc "FOLLOW" hoặc "LOCK" hoặc "POV" hoặc "INCEPTION"
  },
  "suggestAction": true,
  "promptQuestion": "Anh có muốn em tự thao tác cài đặt các thông số này không?",
  "escalated": false
}
Nếu câu hỏi hoàn toàn vô nghĩa hoặc ngoài tầm kiểm soát camera, hãy trả lời lịch sự và đặt "escalated": true, "cameraPreset": null, "suggestAction": false.
`;

export default async function handler(req, res) {
  // CORS setup
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, x-gemini-api-key'
  );

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // GET: Health Check & Cloud Engine Info
  if (req.method === 'GET') {
    return res.status(200).json({
      status: 'active',
      service: 'T-Flow Unified Cloud AI Engine',
      engine: 'Google Gemini AI',
      defaultModel: 'gemini-3.5-flash',
      modes: ['web', 'app'],
      timestamp: new Date().toISOString()
    });
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const DEFAULT_SERVER_GEMINI_KEY = 'AIzaSyDluWTvQMgGmw2yceO27urpn4UBOZ1LQF0';
    let { prompt, mode = 'web', history = [], context = {}, apiKey: reqApiKey, model = 'gemini-3.5-flash' } = req.body || {};

    if (!prompt || typeof prompt !== 'string' || !prompt.trim()) {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    // Auto map legacy or deprecated model keys to active high-performance model
    if (!model || model === 'gemini-2.5-flash' || model === 'gemini-1.5-flash' || model === 'gemini-2.0-flash') {
      model = 'gemini-3.5-flash';
    }

    const cleanPrompt = prompt.trim();
    const reqHeaders = req.headers || {};
    const effectiveKey = reqApiKey || reqHeaders['x-gemini-api-key'] || process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY || DEFAULT_SERVER_GEMINI_KEY;

    // IF NO GOOGLE API KEY AVAILABLE IN RUNTIME, USE SMART EMBEDDED KNOWLEDGE BASE ENGINE
    if (!effectiveKey) {
      const fallbackResult = generateSmartFallbackResponse(cleanPrompt, mode, context);
      return res.status(200).json({
        ...fallbackResult,
        source: 'tflow_smart_engine',
        cloudProvider: 'T-Flow Cloud Brain (Offline/Internal Mode)',
        note: 'Google AI API Key chưa được gắn vào Environment Variable hoặc Admin CMS. Đang dùng bộ não tri thức kiểm định nội bộ.'
      });
    }

    // CALL GOOGLE GEMINI API
    const systemPrompt = mode === 'app' ? APP_SYSTEM_PROMPT : WEB_SYSTEM_PROMPT;
    const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(effectiveKey)}`;

    const geminiPayload = {
      contents: [
        ...history.slice(-4).map(msg => ({
          role: msg.sender === 'user' ? 'user' : 'model',
          parts: [{ text: msg.text || '' }]
        })),
        {
          role: 'user',
          parts: [{ text: cleanPrompt }]
        }
      ],
      system_instruction: {
        parts: [{ text: systemPrompt }]
      },
      generationConfig: {
        temperature: mode === 'app' ? 0.2 : 0.4,
        maxOutputTokens: 1024
      }
    };

    if (mode === 'app') {
      geminiPayload.generationConfig.responseMimeType = 'application/json';
    }

    const apiResponse = await fetch(apiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(geminiPayload)
    });

    if (!apiResponse.ok) {
      const errText = await apiResponse.text();
      console.warn('Google Gemini API Error:', apiResponse.status, errText);
      // Fallback seamlessly to ensure zero interruption
      const fallbackResult = generateSmartFallbackResponse(cleanPrompt, mode, context);
      return res.status(200).json({
        ...fallbackResult,
        source: 'tflow_smart_engine_fallback',
        apiStatus: apiResponse.status,
        note: 'Google API trả về mã phản hồi ngoài mong đợi, đã tự động kích hoạt bộ tri thức kiểm định an toàn.'
      });
    }

    const data = await apiResponse.json();
    const candidateText = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';

    if (mode === 'app') {
      try {
        let parsed = JSON.parse(candidateText.trim());
        return res.status(200).json({
          answer: parsed.answer,
          cameraPreset: parsed.cameraPreset,
          suggestAction: !!parsed.suggestAction,
          promptQuestion: parsed.promptQuestion || "Anh có muốn em tự thao tác cài đặt các thông số này không?",
          escalated: !!parsed.escalated,
          source: 'google_gemini_cloud',
          model: model
        });
      } catch (jsonErr) {
        // Safe regex extraction for json inside markdown
        const match = candidateText.match(/\{[\s\S]*\}/);
        if (match) {
          try {
            const parsed = JSON.parse(match[0]);
            return res.status(200).json({
              answer: parsed.answer,
              cameraPreset: parsed.cameraPreset,
              suggestAction: !!parsed.suggestAction,
              promptQuestion: parsed.promptQuestion || "Anh có muốn em tự thao tác cài đặt các thông số này không?",
              escalated: !!parsed.escalated,
              source: 'google_gemini_cloud',
              model: model
            });
          } catch (e) {}
        }

        return res.status(200).json({
          answer: candidateText + "\n\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
          cameraPreset: {
            name: "Cinema Balanced Pro",
            mode: "VIDEO",
            resolution: "4K",
            fps: 30,
            shutter: "1/60s",
            iso: 100,
            ev: "+0.0EV",
            lut: "TEAL_ORANGE",
            gimbalMode: "FOLLOW"
          },
          suggestAction: true,
          promptQuestion: "Anh có muốn em tự thao tác cài đặt các thông số này không?",
          escalated: false,
          source: 'google_gemini_cloud',
          model: model
        });
      }
    } else {
      // WEB MODE
      const isEscalated = candidateText.includes('[ESCALATE_TO_ADMIN]');
      const cleanAnswer = candidateText.replace(/\[ESCALATE_TO_ADMIN\]/g, '').trim();

      return res.status(200).json({
        answer: cleanAnswer,
        escalated: isEscalated,
        actions: [
          { label: 'Xem Bảng Giá 4 Gói', view: 'catalog' },
          { label: 'Xem Thông Số Kỹ Thuật', view: 'detail' },
          { label: 'Đặt Mua Ngay', view: 'detail' }
        ],
        source: 'google_gemini_cloud',
        model: model
      });
    }

  } catch (err) {
    console.error('Server error handling AI query:', err);
    const fallbackResult = generateSmartFallbackResponse(req.body?.prompt || '', req.body?.mode || 'web', req.body?.context);
    return res.status(200).json({
      ...fallbackResult,
      source: 'tflow_smart_engine_rescue',
      error: err.message
    });
  }
}

// Fallback Knowledge Engine (guarantees 100% uptime & zero downtime)
// T-Flow Unified Cloud AI Engine (Natural Language Understanding & Conversational Brain)
function generateSmartFallbackResponse(query, mode, context) {
  const q = (query || '').toLowerCase().trim();

  // =========================================================================
  // APP MODE: CAMERA COPILOT & REAL-TIME VISION DIRECTOR
  // =========================================================================
  if (mode === 'app') {
    // 1. Multi-Target Focus (Người, Thú cưng, Vật thể tự chọn)
    if (q.includes('thú cưng') || q.includes('chó') || q.includes('mèo') || q.includes('động vật') || q.includes('pet')) {
      return {
        answer: "🐾 **Chế Độ Bám Nét Thú Cưng (Pet Agile Tracking):**\nEm đã kích hoạt thuật toán Cloud Vision nhận diện dáng chuyển động của thú cưng. Động cơ FOC 20kHz được nâng hệ số gia tốc lên 1.8x để bám sát từng cú nhảy và chạy nhanh của chó/mèo mà không bị văng khung hình.\n\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
        cameraPreset: {
          name: "Pet Agile Action (Thú Cưng Tốc Độ)",
          mode: "VIDEO",
          resolution: "4K",
          fps: 60,
          shutter: "1/250s",
          iso: 200,
          ev: "+0.0EV",
          lut: "CLEAN",
          gimbalMode: "FPV",
          targetTrackingMode: "PET"
        },
        suggestAction: true,
        promptQuestion: "Anh có muốn em tự thao tác cài đặt các thông số này không?",
        escalated: false
      };
    }

    if (q.includes('vật thể') || q.includes('đồ vật') || q.includes('chạm') || q.includes('tap') || q.includes('khóa nét') || q.includes('laser')) {
      return {
        answer: "🎯 **Chế Độ Khóa Nét Vật Thể Tự Chọn (Tap-to-Track Laser Lock):**\nAnh chỉ cần chạm tay vào bất kỳ đồ vật nào trên màn hình kính ngắm (sản phẩm review, xe cộ, chi tiết máy...), AI Cloud sẽ chiếu vòng laser khóa chặt pixel của vật thể đó. Động cơ Gimbal sẽ xoay bám theo dù anh di chuyển góc máy quanh đồ vật.\n\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
        cameraPreset: {
          name: "Custom Object Review Lock",
          mode: "VIDEO",
          resolution: "4K",
          fps: 30,
          shutter: "1/60s",
          iso: 100,
          ev: "+0.0EV",
          lut: "REC709",
          gimbalMode: "FOLLOW",
          targetTrackingMode: "CUSTOM_OBJECT"
        },
        suggestAction: true,
        promptQuestion: "Anh có muốn em tự thao tác cài đặt các thông số này không?",
        escalated: false
      };
    }

    // 2. Auto Ultra-Wide Lens Switch (Tự bật góc rộng 0.5x khi đông người)
    if (q.includes('góc rộng') || q.includes('cam góc rộng') || q.includes('0.5x') || q.includes('nhiều người') || q.includes('đông người') || q.includes('nhóm') || q.includes('auto-framing') || q.includes('auto wide')) {
      return {
        answer: "📸 **Tính Năng Tự Bật Cam Góc Rộng (Smart Group Auto-Framing):**\nKhi AI Cloud nhận diện có từ 2-3 người bước vào khuôn hình hoặc chủ thể đứng sát viền, hệ thống sẽ **tự động chuyển sang Camera Góc Siêu Rộng 0.5x (FOV 120°)** để bao trọn tất cả mọi người, đồng thời Gimbal tự tính tâm nhóm (Centroid) để giữ bố cục cân đối. Khi chỉ còn 1 người, AI sẽ tự zoom mượt về 1x.\n\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
        cameraPreset: {
          name: "Smart Group Auto-Wide (0.5x FOV 120°)",
          mode: "CINEMATIC",
          resolution: "4K",
          fps: 30,
          shutter: "1/60s",
          iso: 100,
          ev: "+0.0EV",
          lut: "REC709",
          gimbalMode: "FOLLOW",
          lensMode: "AUTO_WIDE"
        },
        suggestAction: true,
        promptQuestion: "Anh có muốn em tự thao tác cài đặt các thông số này không?",
        escalated: false
      };
    }

    if (q.includes('hoàng hôn') || q.includes('sunset') || q.includes('vàng') || q.includes('chiều')) {
      return {
        answer: "🌅 Để ghi lại trọn vẹn dải màu ấm áp của hoàng hôn và tránh hiện tượng cháy sáng bầu trời, em đã thiết lập chế độ quay Cinematic 4K 24fps với bộ lọc màu Teal & Orange đặc trưng. Khóa độ phơi sáng EV -0.3 để giữ chi tiết mây.\n\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
        cameraPreset: {
          name: "Hoàng Hôn Biển Vàng (Golden Sunset)",
          mode: "VIDEO",
          resolution: "4K",
          fps: 24,
          shutter: "1/48s",
          iso: 50,
          ev: "-0.3EV",
          lut: "TEAL_ORANGE",
          gimbalMode: "FOLLOW"
        },
        suggestAction: true,
        promptQuestion: "Anh có muốn em tự thao tác cài đặt các thông số này không?",
        escalated: false
      };
    }

    if (q.includes('thể thao') || q.includes('chạy') || q.includes('xe') || q.includes('nhanh') || q.includes('tốc độ')) {
      return {
        answer: "⚡ Với các cảnh quay chuyển động nhanh như chạy bộ hoặc đạp xe, tốc độ màn trập cao 1/250s kết hợp 60fps sẽ triệt tiêu bóng mờ chuyển động (motion blur). Gimbal kích hoạt chế độ FPV để bám sát từng cú đổi hướng linh hoạt.\n\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
        cameraPreset: {
          name: "Thể Thao Tốc Độ Cao (Action FPV)",
          mode: "VIDEO",
          resolution: "4K",
          fps: 60,
          shutter: "1/250s",
          iso: 200,
          ev: "+0.0EV",
          lut: "REC709",
          gimbalMode: "FPV"
        },
        suggestAction: true,
        promptQuestion: "Anh có muốn em tự thao tác cài đặt các thông số này không?",
        escalated: false
      };
    }

    // Default App Cinema recommendation
    return {
      answer: "🎬 Em đã phân tích bối cảnh và chuẩn bị bộ thông số Cinema 4K 30fps cân bằng hoàn hảo cho cảnh quay của anh. Động cơ FOC sẽ giữ ổn định đường chân trời tuyệt đối.\n\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
      cameraPreset: {
        name: "Cinema All-Rounder",
        mode: "VIDEO",
        resolution: "4K",
        fps: 30,
        shutter: "1/60s",
        iso: 100,
        ev: "+0.0EV",
        lut: "REC709",
        gimbalMode: "FOLLOW"
      },
      suggestAction: true,
      promptQuestion: "Anh có muốn em tự thao tác cài đặt các thông số này không?",
      escalated: false
    };
  }

  // =========================================================================
  // WEB MODE: STORE CONSULTANT & CONVERSATIONAL NATURAL LANGUAGE ENGINE
  // =========================================================================

  // 1. GREETINGS & CASUAL OPENINGS (hi em, chào bạn, hello, alo, ơi...)
  if (q === 'hi' || q === 'hello' || q === 'alo' || q.includes('hi em') || q.includes('chào em') || q.includes('chào bạn') || q.includes('xin chào') || q.includes('em ơi') || q.includes('tflow ơi') || q.includes('bạn ơi') || q === 'hey') {
    return {
      answer: "Dạ em chào anh/chị ạ! 👋 Em là **T-Flow AI Consultant** — Trợ lý ảo AI Đám Mây chính thức của Hệ sinh thái Gimbal T-Flow Pro.\n\nEm rất vui được đồng hành cùng anh/chị. Em có thể giải đáp chi tiết về:\n• **4 gói sản phẩm T-Flow Pro** (từ gói cơ bản 2.49M đến gói Master)\n• **Công nghệ độc quyền**: Động cơ Pure FOC 20kHz, ngàm hít nam châm MagSafe 45N N52, pin 18h\n• **Tính năng AI Vision Cloud**: Tự nhận diện bám nét người, thú cưng, vật thể tự chọn & tự động chuyển cam góc rộng 0.5x khi đông người\n• **Chính sách**: Bảo hành 1 đổi 1 trong 12 tháng, 30 ngày dùng thử miễn phí.\n\nAnh/chị đang quan tâm đến nội dung nào ạ? Em tư vấn ngay cho anh/chị nhé!",
      escalated: false,
      actions: [
        { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' },
        { label: '🎯 Tính Năng AI Vision', action: "sendQuickPrompt('T-Flow AI nhận diện bám nét người, thú cưng và vật thể thế nào?')" },
        { label: '⚡ Công Nghệ FOC 20kHz', action: "sendQuickPrompt('Thuật toán Pure FOC 20kHz khác gì gimbal thường?')" }
      ]
    };
  }

  // 2. NHẬN DIỆN FOCUS (NGƯỜI, THÚ CƯNG, VẬT THỂ TỰ CHỌN)
  if (q.includes('thú cưng') || q.includes('chó') || q.includes('mèo') || q.includes('vật thể') || q.includes('người quay') || q.includes('chủ thể') || q.includes('bám nét') || q.includes('nhận diện') || q.includes('focus') || q.includes('tracking')) {
    return {
      answer: "Dạ T-Flow Pro tích hợp công nghệ **Cloud AI Vision 3.0** độc quyền với 3 chế độ nhận diện bám nét thông minh:\n\n" +
              "1. **Bám Nét Người (Human / Host Tracking):** Khóa nét vào mắt, khuôn mặt và vóc dáng với tần số 120fps, dù người quay xoay người hay di chuyển nhanh thì gimbal vẫn giữ chủ thể ở trung tâm.\n" +
              "2. **Bám Nét Thú Cưng (Pet Tracking):** Tối ưu riêng cho chuyển động nhanh, bất ngờ của chó, mèo; tự động tăng tốc đáp ứng của động cơ FOC 20kHz lên 1.8x.\n" +
              "3. **Khóa Nét Vật Thể Tự Chọn (Tap-to-Track):** Người dùng chỉ cần chạm tay vào bất kỳ vật thể nào trên màn hình (sản phẩm review, đồ vật, xe cộ...), AI Cloud sẽ khóa laser và xoay gimbal bám theo vật thể đó.\n\n" +
              "Toàn bộ thuật toán xử lý trên Cloud AI, không làm nóng máy hay hao pin điện thoại của anh/chị ạ!",
      escalated: false,
      actions: [
        { label: '📸 Trải Nghiệm App Simulator', action: "window.open('mobile_app.html', '_blank')" },
        { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' },
        { label: '⚡ Chi Tiết Kỹ Thuật', view: 'detail' }
      ]
    };
  }

  // 3. TỰ BẬT CAM GÓC RỘNG KHI ĐÔNG NGƯỜI
  if (q.includes('góc rộng') || q.includes('cam góc rộng') || q.includes('0.5x') || q.includes('nhiều người') || q.includes('đông người') || q.includes('nhóm') || q.includes('auto wide') || q.includes('tự bật')) {
    return {
      answer: "Dạ tính năng **Tự Động Bật Cam Góc Rộng (Smart Group Auto-Framing)** là điểm đột phá cực kỳ tiện lợi trên T-Flow Pro ạ! 🌟\n\n" +
              "• **Cách thức hoạt động:** Khi AI Cloud quét thấy trong khung hình xuất hiện từ **2-3 người trở lên** hoặc có người đứng sát viền mép mà cam góc hẹp 1x không bao trùm hết, hệ thống sẽ **tự động chuyển sang Camera Góc Siêu Rộng 0.5x (FOV 120°)** hoàn toàn tự động!\n" +
              "• **Tự căn giữa nhóm:** Gimbal tự tính toán tâm trọng lực (Centroid) của tất cả mọi người để không ai bị lọt ra ngoài mép khung hình.\n" +
              "• **Tự thu về 1x khi ít người:** Khi mọi người rời đi chỉ còn 1 người, sau 3 giây hệ thống sẽ tự động zoom mượt về camera chính 1x.\n\n" +
              "Anh/chị có thể mở thử ngay tại **Trình giả lập App T-Flow** để xem AI tự kích hoạt ống kính 0.5x nhé!",
      escalated: false,
      actions: [
        { label: '📸 Thử Ngay Trên App Simulator', action: "window.open('mobile_app.html', '_blank')" },
        { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' }
      ]
    };
  }

  // 4. GIÁ CẢ & 4 GÓI SẢN PHẨM
  if (q.includes('giá') || q.includes('bao nhiêu') || q.includes('gói') || q.includes('bảng giá') || q.includes('mua') || q.includes('creator') || q.includes('cinematic') || q.includes('standard') || q.includes('master')) {
    return {
      answer: "Dạ T-Flow Pro hiện có 4 gói chính hãng phù hợp mọi nhu cầu sáng tạo nội dung:\n\n" +
              "1. **Standard Edition**: 2.490.000₫ (Gimbal 3 trục FOC + Chân mini tripod + Cáp sạc USB-C + Túi nhung)\n" +
              "2. **Creator Kit** (Khuyên dùng • Bán chạy nhất): 3.190.000₫ (+ Đèn Fill Light từ tính RGB 360 màu + Túi EVA chống sốc)\n" +
              "3. **Cinematic Pro**: 3.990.000₫ (+ Micro thu âm không dây kép 2.4GHz chống ồn AI + Bộ tạ đối trọng Pro cho iPhone Max)\n" +
              "4. **Master Edition**: 5.490.000₫ (+ Full phụ kiện Cinematic + Vali nhôm hàng không nguyên khối + Khóa học MasterClass trọn đời)\n\n" +
              "Tất cả đều được bảo hành 1 đổi 1 trong 12 tháng, 30 ngày dùng thử miễn phí và freeship toàn quốc ạ!",
      escalated: false,
      actions: [
        { label: 'Xem Bảng Giá 4 Gói', view: 'catalog' },
        { label: 'Mua Creator Kit (3.19M)', action: 'addCreatorKit' }
      ]
    };
  }

  // 5. CÔNG NGHỆ PHẦN CỨNG (FOC, MAGSAFE, PIN, KHỐI LƯỢNG)
  if (q.includes('foc') || q.includes('động cơ') || q.includes('magsafe') || q.includes('nam châm') || q.includes('pin') || q.includes('thông số') || q.includes('nặng') || q.includes('trọng lượng') || q.includes('thời lượng')) {
    return {
      answer: "Dạ T-Flow Pro sở hữu những công nghệ phần cứng hàng đầu phân khúc:\n\n" +
              "• **Động cơ Pure FOC 20kHz**: Triệt tiêu hoàn toàn tiếng rít motor, phản hồi gia tốc siêu nhạy và cân mượt các dòng máy nặng như iPhone 16 Pro Max.\n" +
              "• **Ngàm nam châm MagSafe 45N**: Lực hút nam châm N52 hít cực chặt (chịu tải 2.8kg), tháo lắp điện thoại chỉ trong 1 giây mà không lo trầy xước viền.\n" +
              "• **Pin 3200mAh**: Thời lượng lên đến 18 tiếng liên tục, hỗ trợ sạc ngược không dây chuẩn Qi trực tiếp cho điện thoại khi đang quay.\n" +
              "• **Trọng lượng 385g**: Nhẹ hơn 20% so với gimbal truyền thống, gập lại gọn gàng bỏ vừa túi du lịch.",
      escalated: false,
      actions: [
        { label: 'Xem Chi Tiết Kỹ Thuật', view: 'detail' },
        { label: 'Xem Dải Sản Phẩm', view: 'catalog' }
      ]
    };
  }

  // 6. TƯƠNG THÍCH ĐIỆN THOẠI
  if (q.includes('điện thoại') || q.includes('iphone') || q.includes('samsung') || q.includes('android') || q.includes('tương thích') || q.includes('máy nào')) {
    return {
      answer: "Dạ T-Flow Pro tương thích hoàn hảo 100% với hầu hết smartphone hiện nay ạ:\n\n" +
              "• **Dành cho iPhone (từ iPhone 12 đến 16 Pro Max)**: Hít nam châm MagSafe nguyên bản trực tiếp không cần ngàm kẹp.\n" +
              "• **Dành cho Android & các máy khác (Samsung, Xiaomi, Vivo, Oppo...)**: T-Flow tặng kèm sẵn **Vòng từ tính trợ lực siêu mỏng** dán vào mặt lưng hoặc ốp lưng, hít chặt như MagSafe nguyên bản.\n" +
              "• Tải trọng tối đa hỗ trợ lên tới **320 gram**, thoải mái gắn thêm kính lọc Filter hoặc ống kính rời Anamorphic ạ!",
      escalated: false,
      actions: [
        { label: 'Xem Bảng Giá 4 Gói', view: 'catalog' },
        { label: 'Xem Chi Tiết Kỹ Thuật', view: 'detail' }
      ]
    };
  }

  // 7. BẢO HÀNH & GIAO HÀNG
  if (q.includes('bảo hành') || q.includes('đổi trả') || q.includes('dùng thử') || q.includes('ship') || q.includes('vận chuyển') || q.includes('giao hàng')) {
    return {
      answer: "Dạ T-Flow cam kết chính sách hậu mãi số 1 thị trường:\n\n" +
              "• **Bảo hành 1 đổi 1 trong 12 tháng** chính hãng nếu có lỗi từ nhà sản xuất.\n" +
              "• **Dùng thử 30 ngày hoàn tiền 100%** nếu anh/chị trải nghiệm không ưng ý, không cần giải thích lý do.\n" +
              "• **Miễn phí vận chuyển toàn quốc (Freeship)**: Giao hỏa tốc 2-4 giờ tại nội thành Hà Nội & TP.HCM, 24-48 giờ toàn quốc, được kiểm tra hàng trước khi thanh toán.",
      escalated: false,
      actions: [
        { label: 'Xem Bảng Giá 4 Gói', view: 'catalog' },
        { label: 'Đặt Mua Ngay', view: 'detail' }
      ]
    };
  }

  // 8. BẠN LÀ AI / NGƯỜI SÁNG LẬP
  if (q.includes('bạn là ai') || q.includes('thủy nguyễn') || q.includes('sáng lập') || q.includes('thương hiệu') || q.includes('tflow') || q.includes('t-flow')) {
    return {
      answer: "Dạ em là **T-Flow AI Consultant** — Trợ lý ảo AI Đám Mây độc quyền của Hệ sinh thái Gimbal T-Flow Pro, được sáng lập và phát triển bởi **Master Admin Thủy Nguyễn**.\n\nSứ mệnh của em là đồng hành cùng các nhà sáng tạo nội dung từ khâu tư vấn thiết bị, hỗ trợ kỹ thuật đến đạo diễn góc máy quay chụp chuyên nghiệp. Anh/chị cần em hỗ trợ gì thêm không ạ?",
      escalated: false,
      actions: [
        { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' },
        { label: 'Xem Dải Sản Phẩm', view: 'catalog' }
      ]
    };
  }

  // 9. GENERAL CONVERSATIONAL INTELLIGENCE (Thay vì né tránh, hãy hỗ trợ tự nhiên)
  return {
    answer: "Dạ cảm ơn câu hỏi của anh/chị! Về vấn đề này, Hệ sinh thái Smart Gimbal T-Flow Pro với thuật toán điều khiển động cơ Pure FOC 20kHz và hệ thống Cloud AI Vision hoàn toàn có thể đáp ứng linh hoạt mọi nhu cầu quay phim, livestream và sáng tạo nội dung.\n\nAnh/chị có thể xem nhanh thông tin 4 gói combo hoặc thông số kỹ thuật chi tiết bằng các nút bên dưới. Nếu cần trao đổi chuyên sâu hơn, em sẽ kết nối ngay cùng Master Admin Thủy Nguyễn để hỗ trợ anh/chị tốt nhất ạ! 😊",
    escalated: false,
    actions: [
      { label: '📦 Xem Bảng Giá 4 Gói', view: 'catalog' },
      { label: '⚡ Xem Chi Tiết Kỹ Thuật', view: 'detail' },
      { label: '🎯 Thử Kính Ngắm App AI', action: "window.open('mobile_app.html', '_blank')" }
    ]
  };
}
