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
      defaultModel: 'gemini-2.5-flash',
      modes: ['web', 'app'],
      timestamp: new Date().toISOString()
    });
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { prompt, mode = 'web', history = [], context = {}, apiKey: reqApiKey, model = 'gemini-2.5-flash' } = req.body || {};

    if (!prompt || typeof prompt !== 'string' || !prompt.trim()) {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    const cleanPrompt = prompt.trim();
    const reqHeaders = req.headers || {};
    const effectiveKey = reqApiKey || reqHeaders['x-gemini-api-key'] || process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;

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
function generateSmartFallbackResponse(query, mode, context) {
  const q = query.toLowerCase();

  if (mode === 'app') {
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

    if (q.includes('chân dung') || q.includes('xóa phông') || q.includes('mẫu') || q.includes('người')) {
      return {
        answer: "✨ Chế độ Chân Dung Điện Ảnh kích hoạt thuật toán tách chủ thể và làm mờ hậu cảnh tự nhiên. T-Flow AI tự động khóa nét vào đồng tử mắt của chủ thể, đồng thời áp dụng LUT Film Noir tinh tế.\n\nAnh có muốn em tự thao tác cài đặt các thông số này không?",
        cameraPreset: {
          name: "Chân Dung Điện Ảnh (Pro Portrait)",
          mode: "CINEMATIC",
          resolution: "4K",
          fps: 24,
          shutter: "1/48s",
          iso: 100,
          ev: "+0.0EV",
          lut: "FILM_NOIR",
          gimbalMode: "FOLLOW"
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

  // WEB FALLBACK
  if (q.includes('giá') || q.includes('bao nhiêu') || q.includes('gói') || q.includes('bảng giá')) {
    return {
      answer: "Dạ T-Flow Pro hiện có 4 gói chính hãng phù hợp mọi nhu cầu:\n\n" +
              "1. **Standard Edition**: 2.490.000₫ (Gimbal + Chân mini tripod + Cáp sạc)\n" +
              "2. **Creator Kit** (Phổ biến nhất): 3.190.000₫ (+ Đèn Fill Light từ tính RGB + Túi chống sốc EVA)\n" +
              "3. **Cinematic Pro**: 3.990.000₫ (+ Mic thu âm kép 2.4GHz + Bộ tạ đối trọng Pro)\n" +
              "4. **Master Edition**: 5.490.000₫ (+ Vali nhôm nguyên khối + Khóa học MasterClass trọn đời)\n\n" +
              "Tất cả các gói đều được bảo hành 1 đổi 1 trong 12 tháng và hỗ trợ 30 ngày dùng thử đổi trả miễn phí ạ!",
      escalated: false,
      actions: [
        { label: 'Xem Bảng Giá 4 Gói', view: 'catalog' },
        { label: 'Mua Creator Kit (3.19M)', action: 'addCreatorKit' }
      ]
    };
  }

  if (q.includes('foc') || q.includes('động cơ') || q.includes('magsafe') || q.includes('nam châm') || q.includes('pin') || q.includes('thông số')) {
    return {
      answer: "Dạ T-Flow Pro sở hữu những công nghệ phần cứng hàng đầu hiện nay:\n\n" +
              "• **Động cơ Pure FOC 20kHz**: Triệt tiêu hoàn toàn tiếng rít motor, phản hồi gia tốc siêu nhạy.\n" +
              "• **Ngàm nam châm MagSafe 45N**: Lực hút nam châm N52 hít cực chặt, tháo lắp điện thoại chỉ 1 giây.\n" +
              "• **Pin 3200mAh**: Thời lượng lên đến 18 tiếng liên tục và hỗ trợ sạc ngược không dây cho iPhone.\n" +
              "• **Trọng lượng 385g**: Nhẹ hơn 20% so với thế hệ trước, gập lại gọn gàng trong túi xách.",
      escalated: false,
      actions: [
        { label: 'Xem Chi Tiết Kỹ Thuật', view: 'detail' },
        { label: 'Xem Dải Sản Phẩm', view: 'catalog' }
      ]
    };
  }

  // Out of domain: Strict Escalation
  return {
    answer: "Dạ câu hỏi này mang tính kỹ thuật/chính sách chuyên sâu mà em chưa có dữ liệu kiểm định chính thức từ xưởng R&D. Để bảo đảm thông tin chuẩn xác 100% và không trả lời bừa, em đã tự động chuyển tiếp câu hỏi này về Trung Tâm Điều Hành cho Master Admin Thủy Nguyễn duyệt và cập nhật giải đáp sớm nhất cho anh ạ! 🙏",
    escalated: true,
    actions: [
      { label: 'Xem Bảng Giá 4 Gói', view: 'catalog' },
      { label: 'Xem Chi Tiết Kỹ Thuật', view: 'detail' }
    ]
  };
}
