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

**Last updated:** 2026-08-20 (session 6 — Part C Cinematic Dark complete) · *Cập nhật lần cuối: 20/08/2026 (phiên 6 — hoàn thành Phần C Cinematic Dark)*

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

- [ ] **The whole app in Cinematic Dark** (Part C) — this is the big one. Every screen changed
      ground, text, hue and motion. Look at it in **both light and dark mode**: the palette was
      designed dark-first and light was derived from it, so light mode is the side more likely to
      look off. Contrast is proven by tests; what tests cannot judge is whether it feels calm.
      ***Toàn bộ app ở giao diện Cinematic Dark** (Phần C) — đây là mục lớn nhất. Mọi màn hình đều đổi
      nền, chữ, màu nhấn và chuyển động. Hãy xem ở **cả chế độ sáng và tối**: bảng màu được thiết kế
      cho nền tối trước rồi mới suy ra nền sáng, nên chế độ sáng dễ có chỗ chưa ổn hơn. Độ tương phản
      đã được test chứng minh; thứ test không đánh giá được là cảm giác có "tĩnh" hay không.*
- [ ] **Share cards after the palette change** (C.8) — all four themes again, please. Classic now
      renders on a near-black ground instead of cream, and `Parchment` had a real bug: its light
      artwork was asking for the app's ink, which after the change resolved to near-white — pale
      text on pale parchment. Fixed, but never seen.
      ***Thiệp chia sẻ sau khi đổi bảng màu** (C.8) — làm ơn kiểm tra lại cả bốn chủ đề. Chủ đề Classic
      giờ hiện trên nền gần đen thay vì màu kem, và chủ đề `Parchment` từng có lỗi thật: phần artwork
      sáng lại lấy màu chữ của app, mà sau thay đổi màu đó thành gần trắng — chữ nhạt trên nền nhạt.
      Đã sửa nhưng chưa ai nhìn thấy.*
- [ ] **The widget in both appearances** — it keeps its own copy of the palette with no compiler
      link to the app's, so drift there is silent. It should now match the app, not the old look.
      ***Widget ở cả hai chế độ sáng/tối** — widget giữ một bản sao bảng màu riêng, không có liên kết
      biên dịch nào với app, nên lệch màu ở đó sẽ âm thầm xảy ra. Giờ nó phải trông giống app, không
      còn giống giao diện cũ.*
- [ ] **The Spectral serif on screen** (A.4) — kerning and weight at title sizes, on device. Note
      it now also sets the *narrative*, which is a much bigger surface than titles were.
      ***Font serif Spectral trên màn hình** (A.4) — khoảng cách chữ và độ đậm ở cỡ tiêu đề, xem trên máy thật.*

---

## 🟢 Decisions waiting on you / 🟢 Quyết định đang chờ bạn

- [ ] **Add a lighter Spectral weight?** Only `Spectral-SemiBold.ttf` is bundled, so the narrative —
      now set in the serif — is semibold at reading size. It works, but a Regular or Light weight
      would read better for long text. Adding one needs you: drop the `.ttf` into `MemoryInk/Fonts`,
      add it to the target, and add the filename to `UIAppFonts` in the gitignored `Info.plist`.
      Spectral is SIL OFL, so the extra weights are free to bundle. Say the word and I'll wire the
      code to use it. **Not urgent — nothing is broken without it.**
      ***Có thêm một độ đậm nhẹ hơn của Spectral không?** Trong bundle chỉ có `Spectral-SemiBold.ttf`,
      nên phần narrative — giờ dùng font serif — đang là semibold ở cỡ chữ đọc. Vẫn dùng được, nhưng
      một weight Regular hoặc Light sẽ dễ đọc hơn với đoạn văn dài. Việc này cần bạn: bỏ file `.ttf`
      vào `MemoryInk/Fonts`, thêm vào target, và thêm tên file vào `UIAppFonts` trong `Info.plist`
      (file này bị gitignore). Spectral dùng giấy phép SIL OFL nên các weight khác được bundle miễn
      phí. Bạn đồng ý thì tôi sẽ sửa code dùng nó. **Không gấp — thiếu nó cũng không hỏng gì.***

---

## ✅ Archive — done / ✅ Lưu trữ — đã xong

### Part B device pass cleared — you confirmed 2026-08-19
### Đã kiểm tra xong Phần B trên máy thật — bạn xác nhận ngày 19/08/2026

You ran the app and confirmed each of these working:
*Bạn đã chạy app và xác nhận từng mục sau chạy được:*

- ✅ **Face ID lock flow** (B4)
      *Luồng khoá Face ID (B4)*
- ✅ **Themed share cards** (B2) — the riskiest code in the whole v2 batch, hand-placed drawing
      *Thiệp chia sẻ có chủ đề (B2) — phần code rủi ro nhất của cả đợt v2, vẽ bằng toạ độ đặt tay*
- ✅ **Sharing overall** — the share sheet and the post-creation share card
      *Chức năng chia sẻ nói chung — share sheet và thiệp chia sẻ sau khi tạo kỷ niệm*
- ✅ **On This Day+** (B1) — see the caveat below
      *Ngày này năm xưa+ (B1) — xem lưu ý bên dưới*
- ✅ **Dark mode**, including the calendar heatmap colour ramp (B5)
      *Chế độ tối, gồm cả dải màu của bản đồ nhiệt trên lịch (B5)*
- ✅ **The memory detail overlay** (A.5, after the §9.4 fix)
      *Lớp phủ chi tiết kỷ niệm (A.5, sau bản sửa §9.4)*

**Caveat on B1 — not your problem to solve, mine.** "On This Day+ works" confirms the screen
renders and behaves. It cannot confirm the multi-year *sectioning*, because that needs a journal
holding the same calendar date in 3+ different years, and the app has only existed since May 2026.
That path stays unproven by device testing by definition, so it is being covered by a unit test
instead rather than left as a checkbox you can never truthfully tick.
***Lưu ý về B1 — phần này là việc của tôi, không phải của bạn.** "Ngày này năm xưa+ chạy được"
xác nhận màn hình hiển thị và hoạt động đúng. Nhưng nó không thể xác nhận phần **chia nhóm theo
nhiều năm**, vì muốn vậy cần nhật ký có cùng một ngày ở 3 năm khác nhau trở lên, mà app mới tồn tại
từ tháng 5/2026. Nhánh code đó về bản chất không thể kiểm chứng bằng máy thật, nên nó sẽ được phủ
bằng unit test thay vì để lại một ô tick mà bạn không bao giờ tick thật lòng được.*


### Timeline → detail transition re-verified — you confirmed 2026-08-19
### Đã kiểm chứng lại hiệu ứng chuyển cảnh Timeline → chi tiết — bạn xác nhận ngày 19/08/2026

You ran the app after the fix and confirmed it behaves correctly. The overlay now lays out on its
own instead of being pinned to the source card's on-screen position (`matchedGeometryEffect`
removed — [`docs/BUGS_AND_FIXES.md`](../docs/BUGS_AND_FIXES.md) §9.4).
*Bạn đã chạy app sau khi sửa và xác nhận nó chạy đúng. Lớp phủ giờ tự bố trí layout của chính nó
thay vì bị ghim vào vị trí của thẻ nguồn trên màn hình (đã bỏ `matchedGeometryEffect` —
[`docs/BUGS_AND_FIXES.md`](../docs/BUGS_AND_FIXES.md) §9.4).*


### Part A motion work checked on device — you confirmed 2026-08-19
### Đã kiểm tra phần chuyển động của Phần A trên máy thật — bạn xác nhận ngày 19/08/2026

You went through the Part A motion work (A.5 hero transition, A.6 haptics sweep, A.7 four
redesigned screens, A.9 shared swipe gesture) and asked for this item to be ticked.
*Bạn đã xem qua phần chuyển động của Phần A (A.5 hiệu ứng chuyển cảnh, A.6 rà soát phản hồi rung,
A.7 bốn màn hình thiết kế lại, A.9 cử chỉ vuốt dùng chung) và yêu cầu tick mục này.*

That check earned its keep: it caught the one real bug in the batch — the Timeline → detail
transition pinned the overlay's photo to wherever the source card sat on screen. Fixed the same
day by dropping `matchedGeometryEffect` (full write-up in [`docs/BUGS_AND_FIXES.md`](../docs/BUGS_AND_FIXES.md) §9.4).
*Lần kiểm tra đó rất đáng giá: nó bắt được đúng một lỗi thật trong cả đợt — hiệu ứng chuyển cảnh
Timeline → chi tiết ghim ảnh của lớp phủ vào đúng vị trí thẻ nguồn đang đứng trên màn hình. Đã sửa
ngay trong ngày bằng cách bỏ `matchedGeometryEffect` (chi tiết ở [`docs/BUGS_AND_FIXES.md`](../docs/BUGS_AND_FIXES.md) §9.4).*

**Still open above:** the re-verification of that rewritten transition — the fix itself has only
been built, never seen running.
***Vẫn còn mở ở trên:** kiểm chứng lại hiệu ứng vừa viết lại — bản sửa mới chỉ được build, chưa ai
nhìn thấy nó chạy.*


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
