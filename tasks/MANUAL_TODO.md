# Manual TODO — things only you can do
# Việc thủ công — những việc chỉ bạn làm được

> **This file is yours.** Claude Code can't do these — they need the Xcode GUI, a simulator or device, your Apple Developer account, or a file that lives outside git.
> ***File này là của bạn.** Claude Code không làm được những việc này — chúng cần giao diện Xcode, máy thật/simulator, tài khoản Apple Developer của bạn, hoặc file nằm ngoài git.*
>
> Every part and every session adds to this one file; nothing gets dropped just because a session ended.
> *Mọi phần việc và mọi phiên làm việc đều ghi thêm vào đúng file này; không việc nào bị rơi rớt chỉ vì một phiên kết thúc.*
>
> **Rules Claude follows / Quy tắc Claude tuân theo:**
> - Whenever a task or part finishes and something is left for you, it gets appended here **and** said in the chat reply — never only one of the two.
>   *Mỗi khi xong một task hay một phần mà còn việc cho bạn, việc đó được ghi vào đây **và** nói trong phần trả lời chat — không bao giờ chỉ một trong hai.*
> - Nothing is ticked off on your behalf. You tick it when you've done it.
>   *Không ai tick thay bạn. Bạn làm xong thì bạn tick.*
> - Completed items move to the archive at the bottom rather than being deleted, so there's a record of what was configured and when.
>   *Việc đã xong được chuyển xuống mục lưu trữ ở cuối thay vì xoá đi, để còn dấu vết đã cấu hình cái gì và vào lúc nào.*
>
> **How to tell Claude something is done:** just say so ("I added the App Group", "font looks fine") and it'll move the item to the archive.
> ***Cách báo Claude là đã xong:** chỉ cần nói ra ("tôi thêm App Group rồi", "font nhìn ổn") là nó sẽ chuyển mục đó xuống lưu trữ.*

**Last updated:** 2026-08-19 (session 5 — Part B complete) · *Cập nhật lần cuối: 19/08/2026 (phiên 5 — hoàn thành Phần B)*

---

## 🔴 Blocking — a shipped feature is broken or missing without this
## 🔴 Chặn — thiếu cái này thì tính năng đã ship sẽ hỏng hoặc không chạy

### 1. Back up the two Info.plist keys outside git
### 1. Sao lưu hai key Info.plist ra ngoài git

*`UIAppFonts` added 2026-08-18 (A.4), `NSFaceIDUsageDescription` added 2026-08-19 (B4).*
*`UIAppFonts` thêm ngày 18/08/2026 (A.4), `NSFaceIDUsageDescription` thêm ngày 19/08/2026 (B4).*

`MemoryInk/Info.plist` is deliberately gitignored (commit `4cef949` — it holds live API keys), so **these keys exist only on this Mac's disk.**
*`MemoryInk/Info.plist` bị cố ý loại khỏi git (commit `4cef949` — vì chứa API key thật), nên **hai key này chỉ tồn tại trên ổ đĩa của chiếc Mac này.***

A fresh clone loses them: the serif silently falls back to the system font, and Face ID crashes on first use (iOS requires the usage string).
*Clone mới về là mất: font serif âm thầm rơi về font hệ thống, và Face ID sẽ crash ngay lần dùng đầu tiên (iOS bắt buộc phải có chuỗi mô tả quyền).*

- [ ] Add both to wherever you keep your Info.plist backup (1Password / Notes)
      *Thêm cả hai vào nơi bạn lưu bản sao Info.plist (1Password / Notes)*

```xml
<key>UIAppFonts</key>
<array>
    <string>Spectral-SemiBold.ttf</string>
</array>
<key>NSFaceIDUsageDescription</key>
<string>MemoryInk uses Face ID to keep your journal private on this device.</string>
```

---

## 🟡 Verification — code is build-verified but has never been seen running
## 🟡 Kiểm chứng — code đã build thành công nhưng chưa từng được nhìn thấy chạy thật

No simulator or Xcode GUI exists in Claude's environment, so *nothing below has been looked at*.
*Môi trường của Claude không có simulator hay giao diện Xcode, nên **chưa có thứ nào dưới đây được nhìn tận mắt**.*

A build passing proves it compiles, links, and bundles — not that it looks or feels right.
*Build thành công chỉ chứng minh code biên dịch, liên kết và đóng gói được — không chứng minh nó nhìn đẹp hay dùng đã tay.*

Roughly in order of how likely something is wrong:
*Xếp gần đúng theo mức độ dễ có lỗi:*

- [ ] **Themed share cards** (B2) — highest risk in the whole v2 batch. The themed layout is hand-placed drawing code (margins, a 520pt photo frame, narrative wrapping). Check each of the four themes, with a photo and without, and with a long narrative. Classic should look exactly as it always has.
      ***Thiệp chia sẻ có chủ đề** (B2) — rủi ro cao nhất trong cả đợt v2. Layout theo chủ đề là code vẽ đặt toạ độ bằng tay (lề, khung ảnh 520pt, cách xuống dòng của narrative). Kiểm tra cả bốn chủ đề, có ảnh và không ảnh, và với narrative dài. Chủ đề Classic phải trông y hệt như trước giờ.*
- [ ] **Face ID lock flow** (B4) — enable in Settings → Privacy, background the app, reopen. Also: cancel the prompt (should be silent, no error text), and check the lock screen doesn't end up underneath an already-open sheet.
      ***Luồng khoá Face ID** (B4) — bật ở Settings → Privacy, đưa app xuống nền, mở lại. Ngoài ra: thử bấm huỷ khi hiện hộp thoại (phải im lặng, không hiện chữ lỗi), và kiểm tra màn hình khoá không bị nằm dưới một sheet đang mở.*
- [ ] **On This Day+ year sections** (B1) — ideally against a journal with the same date in 3+ different years, which no test data here can produce.
      ***Phần chia theo năm của Ngày này năm xưa+** (B1) — lý tưởng là thử với nhật ký có cùng một ngày ở 3 năm khác nhau trở lên, thứ mà dữ liệu test ở đây không tạo ra được.*
- [ ] **Calendar heatmap in dark mode** (B5) — the colour ramp was only reasoned about, not seen.
      ***Bản đồ nhiệt của Lịch ở chế độ tối** (B5) — dải màu mới chỉ được suy luận, chưa được nhìn thấy.*
- [ ] **Part A motion work** (A.5, A.6, A.7, A.9) — the matched-geometry hero transition, the haptics sweep, the four redesigned screens, and the shared swipe gesture.
      ***Phần chuyển động của Phần A** (A.5, A.6, A.7, A.9) — hiệu ứng chuyển cảnh matched-geometry, đợt rà soát phản hồi rung, bốn màn hình thiết kế lại, và cử chỉ vuốt dùng chung.*
- [ ] **The Spectral serif on screen** (A.4) — kerning and weight at title sizes, on device.
      ***Font serif Spectral trên màn hình** (A.4) — khoảng cách chữ và độ đậm ở cỡ tiêu đề, xem trên máy thật.*

---

## 🟢 Decisions waiting on you / 🟢 Quyết định đang chờ bạn

*(none right now — both v2 approval checkpoints were cleared on 2026-08-19: Face ID go-ahead, and the widget snapshot approach over moving the Core Data store.)*
*(hiện không có — cả hai điểm cần duyệt của v2 đã xong ngày 19/08/2026: đồng ý làm Face ID, và chọn phương án snapshot cho widget thay vì di chuyển kho Core Data.)*

---

## ✅ Archive — done / ✅ Lưu trữ — đã xong

### App Group + widget App ID registered — confirmed by you 2026-08-19
### Đã đăng ký App Group + App ID cho widget — bạn xác nhận ngày 19/08/2026

Confirmed from your Developer portal screenshots:
*Xác nhận từ ảnh chụp màn hình cổng Developer của bạn:*

- ✅ App Group `group.com.memoryink.app` registered
      *Đã đăng ký App Group `group.com.memoryink.app`*
- ✅ Widget App ID `com.memoryink.app.MemoryInkWidget` exists — **Xcode created this automatically** when it signed the new target (the `XC` prefix marks an Xcode-managed identifier), so the manual registration step I originally listed was never actually needed
      *App ID cho widget `com.memoryink.app.MemoryInkWidget` đã có — **Xcode tự tạo ra nó** khi ký target mới (tiền tố `XC` là dấu hiệu identifier do Xcode quản lý), nên bước đăng ký thủ công mà tôi ghi ban đầu thực ra không cần thiết*
- ✅ App Groups capability enabled, group ticked (1 of 1 selected)
      *Đã bật capability App Groups và tick chọn group (1 trên 1 mục được chọn)*

**Note for next time:** with automatic signing, Xcode registers App IDs for new targets by itself. What it does *not* do on its own is create the App Group or decide which identifiers it applies to — that part was genuinely yours.
***Ghi chú cho lần sau:** với chế độ ký tự động, Xcode tự đăng ký App ID cho target mới. Thứ nó **không** tự làm là tạo App Group và quyết định gán group đó cho identifier nào — phần đó đúng là việc của bạn.*

### Widget verified working on a physical device — 2026-08-19
### Đã xác nhận widget chạy được trên máy thật — 19/08/2026

You confirmed both App IDs have `group.com.memoryink.app` ticked, ran the app on a device, added the widget, and it displays a real memory.
*Bạn đã xác nhận cả hai App ID đều tick `group.com.memoryink.app`, chạy app trên máy thật, thêm widget, và widget hiển thị đúng một kỷ niệm thật.*

That proves the whole B6 chain end to end: entitlement → App Group container → the app writing the snapshot → the widget process reading it.
*Điều đó chứng minh toàn bộ chuỗi B6 hoạt động từ đầu đến cuối: entitlement → container App Group → app ghi file snapshot → tiến trình widget đọc được nó.*

### Committed and pushed to GitHub — 2026-08-19
### Đã commit và đẩy lên GitHub — 19/08/2026

Branches `memoryink-v2-part-a` and `memoryink-v2-part-b` pushed to `github.com/cnduy07/MemoryInk`. `main` is untouched and still holds the shipped App Store code.
*Đã đẩy nhánh `memoryink-v2-part-a` và `memoryink-v2-part-b` lên `github.com/cnduy07/MemoryInk`. Nhánh `main` giữ nguyên, vẫn là code đang phát hành trên App Store.*

Secret scan before pushing: no keys, tokens or JWTs in any of the 45 files; `MemoryInk/Info.plist` confirmed ignored and never tracked.
*Đã quét bí mật trước khi đẩy: không có key, token hay JWT nào trong cả 45 file; `MemoryInk/Info.plist` được xác nhận là bị ignore và chưa từng bị theo dõi bởi git.*
