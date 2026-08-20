# App Store — "What's New in This Version" · 2.0

Paste the short version below into App Store Connect. Max allowed is 4000 characters.
The longer version further down is kept in case you want more detail later.

---

## SHORT — English (use this one)

```
Your memories, now on your Home Screen.

Widgets — your latest memory on the Home and Lock Screen.

Face ID lock — keep your journal private. Off unless you turn it on.

Share cards — four looks to choose from when you share a memory.

Calendar — every day coloured by how often you wrote and how you felt.

On This Day — the same date gathered across the years, with quiet milestones along the way.

Export — your writing, moods and dates, free, any time. Photos stay on this device.

Plus new type, softer light, and calmer motion throughout.

Thank you for writing here.
```

## SHORT — Tiếng Việt

```
Kỷ niệm của bạn, giờ đã có trên Màn hình chính.

Widget — kỷ niệm mới nhất của bạn trên Màn hình chính và Màn hình khoá.

Khoá Face ID — giữ nhật ký riêng tư. Chỉ bật khi bạn muốn.

Thiệp chia sẻ — bốn kiểu để bạn chọn khi chia sẻ một kỷ niệm.

Lịch — mỗi ngày được tô màu theo mức độ bạn viết và cảm xúc của bạn.

Ngày này năm xưa — cùng một ngày qua nhiều năm, cùng những cột mốc lặng lẽ trên đường đi.

Xuất dữ liệu — chữ viết, cảm xúc và ngày tháng của bạn, miễn phí, bất cứ lúc nào. Ảnh vẫn ở lại trên máy này.

Cùng với kiểu chữ mới, ánh sáng dịu hơn và chuyển động êm hơn ở khắp nơi.

Cảm ơn bạn đã viết ở đây.
```

---

# LONGER VERSION (optional)

## English

```
Your memories, now on your Home Screen.

WIDGETS
Keep your latest memory close. Small, medium, and Lock Screen widgets show its mood, its photo, and a line of its story.

FACE ID LOCK
Your journal can stay private behind Face ID, Touch ID, or your passcode. It's off unless you turn it on, and it locks the moment you leave the app — so nothing shows on the way in.

SHARE CARDS, FOUR WAYS
Sharing a memory now opens a preview with four looks to choose from. Classic is still here, exactly as it was.

A YEAR AT A GLANCE
The calendar now colours each day by how often you wrote and how you felt, so a whole season of your life reads in one look.

ON THIS DAY, DEEPER
Memories from the same date now gather by year, so you can see the same day across the years at once. New journey moments quietly mark the milestones worth noticing — your hundredth day, your first year.

YOUR WORDS, YOURS TO KEEP
Export your writing, moods and dates any time from Settings, free, for everyone. Your photos aren't part of that file — they stay on this device, the way they always have.

AND EVERYWHERE ELSE
New typography, softer light, calmer motion, and several screens rebuilt from the ground up.

Thank you for writing here.
```

**Character count:** ~1,270 of 4,000.

---

## Vietnamese / Tiếng Việt

```
Kỷ niệm của bạn, giờ đã có trên Màn hình chính.

TIỆN ÍCH WIDGET
Giữ kỷ niệm mới nhất luôn trong tầm mắt. Widget cỡ nhỏ, cỡ vừa và trên Màn hình khoá hiển thị cảm xúc, tấm ảnh và một dòng câu chuyện của kỷ niệm đó.

KHOÁ BẰNG FACE ID
Nhật ký của bạn có thể được giữ riêng tư sau Face ID, Touch ID hoặc mật mã. Tính năng này chỉ bật khi bạn muốn, và tự khoá ngay khi bạn rời khỏi ứng dụng — nên sẽ không có gì thoáng hiện ra lúc mở lại.

BỐN KIỂU THIỆP CHIA SẺ
Khi chia sẻ một kỷ niệm, giờ sẽ có bản xem trước với bốn kiểu để bạn chọn. Kiểu Classic vẫn ở đó, y như trước.

NHÌN LẠI CẢ NĂM TRONG MỘT ÁNH MẮT
Lịch giờ tô màu từng ngày theo mức độ bạn viết và cảm xúc của bạn, để cả một mùa trong đời hiện lên chỉ trong một lần nhìn.

NGÀY NÀY NĂM XƯA, SÂU HƠN
Những kỷ niệm cùng một ngày giờ được nhóm lại theo năm, để bạn thấy cùng một ngày qua nhiều năm cùng lúc. Những cột mốc hành trình mới sẽ lặng lẽ đánh dấu điều đáng nhớ — ngày thứ một trăm, năm đầu tiên của bạn.

LỜI BẠN VIẾT, THUỘC VỀ BẠN
Bạn có thể xuất phần chữ viết, cảm xúc và ngày tháng bất cứ lúc nào trong phần Cài đặt, miễn phí cho tất cả mọi người. Ảnh của bạn không nằm trong tệp đó — chúng ở lại trên máy này, như xưa nay vẫn vậy.

VÀ Ở KHẮP MỌI NƠI KHÁC
Kiểu chữ mới, ánh sáng dịu hơn, chuyển động êm hơn, và nhiều màn hình được dựng lại từ đầu.

Cảm ơn bạn đã viết ở đây.
```

---

## Notes on the wording

- **"free, for everyone"** on export is deliberate and accurate — `ExportService` has no
  entitlement check. Saying it plainly is worth more than leaving people to wonder.
- **"Your photos aren't part of that file"** — the export writes photo *file names* only, and
  embeds the line *"Your photos are not included — they stay on this device."* The notes must not
  let anyone expect a photo backup and lose their pictures to that assumption.
- **"It's off unless you turn it on"** — Face ID defaults to off. Stating it prevents the reading
  that the update locks people out of their own journal.
- No version of "unlimited", no urgency, no exclamation marks. House style per `AGENTS.md`.
