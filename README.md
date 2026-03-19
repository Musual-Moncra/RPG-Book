<div align="center">

![RPG-Book Banner](file:///Users/musual/.gemini/antigravity/brain/f7525148-f52f-4c27-95ed-f73eac3233e1/rpg_book_banner_1773884452326.png)

# 📖 RPG-Book: The Arcane Archives

[![Language](https://img.shields.io/badge/Language-Lua-blue.svg?style=for-the-badge&logo=lua)](https://www.lua.org/)
[![Version](https://img.shields.io/badge/Version-1.0.0-gold.svg?style=for-the-badge)](https://github.com/Musual-Moncra/RPG-Book)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**RPG-Book** là nơi lưu trữ tinh hoa của những chiêu thức, kỹ năng (skill source) đỉnh cao. Được chế tác và phát triển bởi nghệ nhân **Musual**, đây là một thư viện mã nguồn dành riêng cho các thế giới RPG huyền ảo.

---

</div>

## ✨ Tính Năng Nổi Bật

Trong cuốn sách ma thuật này, bạn sẽ tìm thấy:

- 🛡️ **Hệ Thống Phản Vệ & Knockback:** Các thuật toán xử lý va chạm và đẩy lùi mượt mà.
- 🪄 **Kho Spell Đồ Sộ:** Các bộ kỹ năng từ cơ bản đến nâng cao (Fireball, Frost Nova, Blizzard...).
- ⚒️ **Cường Hóa & Trang Bị:** Hệ thống Enchant và Consumable Suites được tối ưu hóa.
- 👹 **Kỹ Năng Quái Vật:** AI Skill cho cả Client và Server side, đảm bảo độ trễ thấp và độ chính xác cao.

## 📁 Cấu Trúc Dự Án

Cuốn sách được chia thành các chương chuyên biệt:

```bash
RPG-Book/
├── 📂 Base/                # Các tiện ích cơ bản (Knockback, AttackUtils...)
├── 📂 SkillsServer/        # Logic xử lý kỹ năng phía máy chủ
├── 📂 SkillsClients/       # Hiệu ứng và UI kỹ năng phía người chơi
├── 📂 MobSkills/           # Kho kỹ năng dành cho quái vật (NPC)
├── 📜 SpellSuites.lua      # Định nghĩa các bộ phép thuật
├── 📜 EnchantsSuites.lua   # Hệ thống cường hóa vật phẩm
└── 📜 GameConfig.lua       # Cấu hình cân bằng cho toàn bộ game
```

## 🚀 Hướng Dẫn Sử Dụng

Để triệu hồi các kỹ năng vào dự án của bạn, hãy thực hiện theo các bước sau:

1. **Clone Thư Viện:**
   ```bash
   git clone https://github.com/Musual-Moncra/RPG-Book.git
   ```
2. **Tích Hợp:**
   Import các Module trong thư mục `Base` vào mã nguồn game của bạn.
3. **Cấu Hình:**
   Chỉnh sửa `GameConfig.lua` để thay đổi sát thương, thời gian hồi chiêu hoặc hiệu ứng.

## 📜 Giấy Phép & Tác Giả

Dự án này được tạo ra với niềm đam mê vô tận dành cho thế giới RPG.

- **Người Sáng Tạo:** [Musual](https://github.com/Musual-Moncra)
- **Giấy Phép:** MIT License. Tự do sử dụng với mục đích học tập và phát triển game.

---

<div align="center">

*“Sức mạnh thực sự không nằm ở vũ khí bạn cầm, mà ở linh hồn của từng dòng code.”*

</div>