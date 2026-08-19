# MemoryInk — Bugs & Fixes / Lỗi & Cách sửa

> A record of every significant bug in the project: what went wrong, **why** it went wrong, how it was fixed, and what it teaches.
> *Ghi chép lại mọi lỗi đáng kể của dự án: chuyện gì đã xảy ra, **tại sao** xảy ra, sửa thế nào, và rút ra bài học gì.*
>
> Written to be explainable out loud — if someone asks "tell me about a tricky bug you fixed," the answer is in here.
> *Viết theo kiểu để bạn nói ra miệng được — nếu ai đó hỏi "kể về một lỗi khó mà bạn từng sửa", câu trả lời nằm ở đây.*
>
> Companion document: [`FEATURES_AND_TASKS.md`](FEATURES_AND_TASKS.md).
> *Tài liệu đi kèm: [`FEATURES_AND_TASKS.md`](FEATURES_AND_TASKS.md).*
>
> **Last updated:** 2026-08-19 · *Cập nhật lần cuối: 19/08/2026*

---

## How to use this in an interview / Dùng tài liệu này khi phỏng vấn thế nào

Interviewers rarely want a bug list — they want to see how you *think*.
*Người phỏng vấn hiếm khi cần một danh sách lỗi — họ muốn thấy cách bạn **tư duy**.*

The strongest stories here, in order:
*Những câu chuyện mạnh nhất ở đây, xếp theo thứ tự:*

1. **The AI rate-limit bug** (§6) — a one-line move with real user-money consequences. Best "small change, big reasoning" story.
   ***Lỗi giới hạn AI** (§6) — chỉ dời một dòng code nhưng ảnh hưởng trực tiếp tới tiền của người dùng. Câu chuyện "thay đổi nhỏ, lập luận lớn" tốt nhất.*
2. **SwiftUI horizontal overflow** (§1) — shows you understand a layout system, not just its API.
   ***Lỗi tràn ngang trong SwiftUI** (§1) — cho thấy bạn hiểu cơ chế layout, chứ không chỉ biết gọi API.*
3. **Account deletion** (§7) — trust, server authority, and never lying to the user about success.
   ***Xoá tài khoản** (§7) — nói về niềm tin, thẩm quyền phía server, và việc không bao giờ báo "thành công" giả với người dùng.*
4. **The build system lied to me** (§9.1) — shows you notice when your *verification* is wrong, which is rarer than noticing when your code is wrong.
   ***Hệ thống build đã "nói dối"** (§9.1) — cho thấy bạn phát hiện được khi chính **cách kiểm thử** của mình sai, điều này hiếm hơn nhiều so với việc phát hiện code sai.*

---

## 1. Horizontal overflow in Detail and Browse screens / Tràn ngang ở màn hình Detail và Browse

**Commits:** `27d09c1`, `d19225c` (2026-05-21)

**Symptom.** The Memory Detail and Browse screens could be scrolled sideways. Content bled past the right edge of the screen.
***Biểu hiện.** Màn hình Memory Detail và Browse có thể cuộn ngang được. Nội dung tràn ra khỏi mép phải màn hình.*

It looked like a styling glitch; it wasn't.
*Nhìn thì tưởng lỗi styling vặt, nhưng không phải.*

**Root cause.** `scaledToFill()` on an image inside a `ZStack` that received an *unbounded width proposal*.
***Nguyên nhân gốc.** `scaledToFill()` đặt trên ảnh nằm trong một `ZStack` nhận được **đề xuất chiều rộng không giới hạn**.*

SwiftUI lays out by proposing a size to each child and asking what it wants.
*SwiftUI bố trí giao diện bằng cách đề xuất một kích thước cho từng view con rồi hỏi nó muốn kích thước bao nhiêu.*

`ZStack` with no width constraint of its own passes the proposal down; `scaledToFill` answers with the image's scaled intrinsic size — which for a 1600px preview is far wider than the phone.
*`ZStack` không tự ràng buộc chiều rộng nên đẩy đề xuất đó xuống dưới; `scaledToFill` trả lời bằng kích thước gốc đã scale của ảnh — với ảnh preview 1600px thì rộng hơn màn hình điện thoại rất nhiều.*

That answer propagates back up and becomes the container's width. **`scaledToFill` scales but does not clip.**
*Câu trả lời đó lan ngược lên trên và trở thành chiều rộng của container. **`scaledToFill` chỉ phóng to chứ không cắt (clip) ảnh.***

**Fix.** Constrain first, then clip, and make sure the modifier order gives the ZStack a bounded proposal to work with:
***Cách sửa.** Ràng buộc trước, cắt sau, và đảm bảo thứ tự modifier cho ZStack một đề xuất có giới hạn:*

- `imageArea`: `.frame(height: 380).clipped()`, and an explicit `UIScreen.main.bounds.width`
  *`imageArea`: dùng `.frame(height: 380).clipped()` và chỉ định rõ `UIScreen.main.bounds.width`*
- `BrowseCardFace`: `.frame(maxWidth: .infinity)` **before** the height frame, so the ZStack proposes a bounded width to the image
  *`BrowseCardFace`: đặt `.frame(maxWidth: .infinity)` **trước** frame chiều cao, để ZStack đề xuất một chiều rộng có giới hạn cho ảnh*
- `MemoryViewerPage` text: explicit `frame(width: screenWidth - 44)` instead of `maxWidth` + `fixedSize`, which together re-created the unbounded case
  *Phần text của `MemoryViewerPage`: dùng `frame(width: screenWidth - 44)` thay cho `maxWidth` + `fixedSize` — hai cái này kết hợp lại tạo ra đúng tình huống "không giới hạn" ban đầu*
- `similarTile`: frame + clip the image *before* the ZStack frame
  *`similarTile`: frame và clip ảnh **trước** frame của ZStack*

**Lesson.** In SwiftUI, layout bugs are usually a *proposal* problem, not a *rendering* problem.
***Bài học.** Trong SwiftUI, lỗi layout thường là vấn đề của **đề xuất kích thước**, không phải vấn đề vẽ (rendering).*

Ask "what size is being proposed to this view, and what is it answering?"
*Hãy tự hỏi: "view này đang được đề xuất kích thước bao nhiêu, và nó đang trả lời bao nhiêu?"*

And any `scaledToFill` without a `.frame(...)` + `.clipped()` next to it is an overflow waiting to happen.
*Và bất kỳ `scaledToFill` nào không đi kèm `.frame(...)` + `.clipped()` đều là một lỗi tràn đang chờ xảy ra.*

---

## 2. iPad and small-iPhone adaptivity / Thích ứng iPad và iPhone nhỏ

**Commits:** `d8c33d7`, `6fac36c`, `4530edd` (2026-05-23) — three rounds, because each fix exposed the next problem.
*Ba đợt sửa, vì mỗi lần sửa lại lộ ra vấn đề tiếp theo.*

| Bug / Lỗi | Cause / Nguyên nhân | Fix / Cách sửa |
|---|---|---|
| "Done" button unreachable on iPhone SE<br>*Nút "Done" không bấm tới được trên iPhone SE* | A `Spacer()` above it grew until the button was pushed off-screen<br>*`Spacer()` phía trên giãn ra khiến nút bị đẩy ra ngoài màn hình* | Cap the Spacer at 80pt; give the button `frame(maxWidth: .infinity, minHeight: 44)`<br>*Giới hạn Spacer ở 80pt; cho nút `frame(maxWidth: .infinity, minHeight: 44)`* |
| Photo-picker dialog anchored to the wrong place on iPad<br>*Hộp thoại chọn ảnh hiện sai vị trí trên iPad* | `confirmationDialog` presents as a popover on iPad and needs an anchor it didn't have<br>*Trên iPad, `confirmationDialog` hiện dạng popover và cần một điểm neo mà nó không có* | Replaced with `Menu`, which anchors to its own label<br>*Thay bằng `Menu` — tự neo vào chính nút của nó* |
| Onboarding stretched edge-to-edge on iPad<br>*Màn hình onboarding kéo giãn hết chiều ngang iPad* | No max width — a phone layout scaled up<br>*Không giới hạn chiều rộng — layout điện thoại bị phóng to* | Centered at max 560pt<br>*Căn giữa, tối đa 560pt* |
| Type too small on iPad<br>*Chữ quá nhỏ trên iPad* | Font sizes were fixed constants<br>*Cỡ chữ là hằng số cố định* | All 7 styles compute at runtime from `UIDevice.userInterfaceIdiom`; iPad gets 13–20% larger (badges 12→14pt, narrative 18→20pt, title 36→44pt)<br>*Cả 7 style tính cỡ chữ lúc chạy theo `UIDevice.userInterfaceIdiom`; iPad to hơn 13–20%* |
| Timeline cards looked lost on iPad<br>*Thẻ Timeline trông lọt thỏm trên iPad* | Width capped at 430pt<br>*Chiều rộng bị giới hạn 430pt* | 580pt when viewport width > 700<br>*Lên 580pt khi chiều rộng khung nhìn > 700* |
| **Regression:** tapping the empty photo card stopped opening the picker<br>***Lỗi hồi quy:** chạm vào thẻ ảnh trống không mở được trình chọn ảnh nữa* | When the dialog became a `Menu`, the empty state wasn't wrapped in it — only the button was<br>*Khi đổi dialog sang `Menu`, chỉ có nút được bọc trong Menu, còn trạng thái rỗng thì không* | Wrapped `photoPreview`'s empty state in the same `Menu`<br>*Bọc luôn trạng thái rỗng của `photoPreview` vào cùng `Menu`* |

**Lesson.** "Universal app" is not a build setting, it's a design decision per screen.
***Bài học.** "Universal app" không phải một tuỳ chọn build, mà là một quyết định thiết kế cho từng màn hình.*

Two things recur: **explicit max widths** (a phone layout stretched to iPad always looks wrong) and **44pt minimum tap targets** (Apple's HIG).
*Hai điều lặp đi lặp lại: **giới hạn chiều rộng tối đa rõ ràng** (layout điện thoại kéo giãn lên iPad luôn xấu) và **vùng chạm tối thiểu 44pt** (theo chuẩn HIG của Apple).*

Also note the regression: swapping a presentation API changes *where* the interaction lives, so every entry point has to be re-checked.
*Cũng để ý lỗi hồi quy: đổi API hiển thị sẽ đổi luôn **nơi** chứa tương tác, nên phải kiểm tra lại mọi điểm vào.*

---

## 3. App Store submission rejections / Bị từ chối khi nộp App Store

**Commits:** `9115ce8`, `e4585c6`, `2acfcd4` (2026-05-23)

Three failures that only appear at upload time, never during development:
*Ba lỗi chỉ xuất hiện lúc upload, không bao giờ lộ ra khi đang phát triển:*

1. **App icon rejected.** The 1024×1024 icon had an alpha channel. App Store Connect rejects transparency in the large icon.
   ***Icon bị từ chối.** Icon 1024×1024 có kênh alpha. App Store Connect không chấp nhận icon lớn có nền trong suốt.*
   *Fix:* stripped RGBA → RGB, composited on white (1.5MB → 920KB).
   *Cách sửa: bỏ kênh alpha, chuyển RGBA → RGB, ghép trên nền trắng (1.5MB → 920KB).*
2. **Portrait-only rejected on iPad.** Apple requires an iPad app to support all four orientations *unless* it opts out of multitasking.
   ***Chỉ hỗ trợ dọc bị từ chối trên iPad.** Apple yêu cầu app iPad hỗ trợ cả 4 hướng xoay, **trừ khi** app từ chối chế độ đa nhiệm.*
   *Fix:* `UIRequiresFullScreen = YES` in both Debug and Release configs.
   *Cách sửa: đặt `UIRequiresFullScreen = YES` ở cả cấu hình Debug lẫn Release.*
3. **Malformed privacy strings.** The usage-description strings contained stray quotes and a leading space, which produced broken values in the built plist.
   ***Chuỗi mô tả quyền riêng tư bị lỗi định dạng.** Các chuỗi mô tả quyền có dấu nháy thừa và một khoảng trắng ở đầu, khiến giá trị trong plist build ra bị hỏng.*

**Lesson.** Submission bugs are configuration bugs, and the feedback loop is brutally slow — you learn about them after a full archive and upload.
***Bài học.** Lỗi lúc nộp app là lỗi cấu hình, và vòng phản hồi cực chậm — phải archive và upload xong mới biết.*

Worth a pre-submission checklist rather than discovering them one rejection at a time.
*Nên có một checklist trước khi nộp, thay vì phát hiện từng lỗi qua từng lần bị từ chối.*

---

## 4. Slideshow video rendered upside down / Video slideshow bị lộn ngược

**Commit:** `5f5c51a` (2026-05-23)

**Symptom.** Exported slideshow videos came out vertically flipped.
***Biểu hiện.** Video slideshow xuất ra bị lật ngược theo chiều dọc.*

**Root cause.** A Y-axis flip applied during the `CVPixelBuffer` copy step.
***Nguyên nhân gốc.** Có một phép lật trục Y được áp dụng ở bước copy `CVPixelBuffer`.*

CoreVideo pixel buffers and UIKit's drawing context have opposite Y origins, so a flip is sometimes needed — but here the coordinate system had *already* been corrected upstream, and the second flip undid the correction.
*CoreVideo và context vẽ của UIKit có gốc trục Y ngược nhau nên đôi khi cần lật — nhưng ở đây hệ toạ độ **đã** được chỉnh đúng từ bước trước, và phép lật thứ hai đã huỷ luôn phần chỉnh đó.*

**Fix.** Removed the Y-flip from `renderFrame` and `renderImageFrame`.
***Cách sửa.** Bỏ phép lật trục Y trong `renderFrame` và `renderImageFrame`.*

**Lesson.** Classic double-correction bug.
***Bài học.** Đây là lỗi kinh điển "sửa hai lần thành sai".*

When bridging two frameworks with different coordinate conventions (UIKit ↔ CoreVideo ↔ AVFoundation), fix the orientation in exactly one place and know which one.
*Khi nối hai framework có quy ước toạ độ khác nhau (UIKit ↔ CoreVideo ↔ AVFoundation), chỉ chỉnh hướng ở đúng **một** chỗ và phải biết rõ chỗ đó là chỗ nào.*

---

## 5. Gesture conflicts and a swipe crash / Xung đột cử chỉ và crash khi vuốt

**Commit:** `7099052` (2026-05-21)

- **Swipe-to-favourite fought the scroll view.** A plain `.gesture` on the card competed with the parent ScrollView's pan.
  ***Vuốt để yêu thích xung đột với ScrollView.** Dùng `.gesture` thường trên thẻ khiến nó tranh chấp với cử chỉ kéo của ScrollView cha.*
  *Fix:* `simultaneousGesture` plus a directional guard so the card only claims horizontal movement and vertical drags still scroll.
  *Cách sửa: dùng `simultaneousGesture` kèm một điều kiện kiểm tra hướng, để thẻ chỉ nhận chuyển động ngang, còn kéo dọc vẫn cuộn bình thường.*
- **Crash on rapid swiping in Browse.** The card stack indexed into an array that mutated underneath the gesture — a fast swipe could read an index that no longer existed.
  ***Crash khi vuốt nhanh ở Browse.** Chồng thẻ truy cập mảng theo chỉ số trong khi mảng đang bị thay đổi — vuốt nhanh có thể đọc vào chỉ số không còn tồn tại.*
  *Fix:* bounds guard before access.
  *Cách sửa: kiểm tra giới hạn chỉ số trước khi truy cập.*
- **Browse couldn't be dismissed.** *Fix:* dismiss via `router.path.removeLast` rather than a local presentation flag, matching the app's single-source-of-truth navigation.
  ***Không đóng được màn hình Browse.** Cách sửa: đóng bằng `router.path.removeLast` thay vì cờ hiển thị cục bộ, đúng với mô hình điều hướng một nguồn dữ liệu duy nhất của app.*

**Lesson.** Custom gestures inside scroll views need explicit coexistence rules, and any gesture-driven index into a mutable collection is a crash waiting for a fast user.
***Bài học.** Cử chỉ tuỳ chỉnh nằm trong scroll view cần quy tắc cùng tồn tại rõ ràng; và bất kỳ chỉ số mảng nào điều khiển bởi cử chỉ trên một collection thay đổi được đều là crash đang chờ một người dùng thao tác nhanh.*

---

## 6. ⭐ AI rate-limit bug / Lỗi giới hạn AI — failed generations burned the user's daily quota

**Recorded in `AGENTS.md`; fix visible at `NarrativeGenerationService.swift:134`**
*Được ghi trong `AGENTS.md`; bản sửa nằm ở `NarrativeGenerationService.swift:134`.*

**Symptom.** Free users get 3 AI narratives a day (15 monthly, 30 yearly). If generation failed — network drop, timeout, server error — the attempt *still* counted.
***Biểu hiện.** Người dùng miễn phí có 3 lượt tạo narrative/ngày (gói tháng 15, gói năm 30). Nếu việc tạo thất bại — rớt mạng, timeout, lỗi server — lượt đó **vẫn bị tính**.*

A user could lose their whole day's allowance without ever receiving a single narrative. On a paid tier, that's charging someone for nothing.
*Người dùng có thể mất sạch hạn mức cả ngày mà không nhận được câu narrative nào. Với gói trả phí, đó là thu tiền mà không giao hàng.*

**Root cause.** The usage counter was incremented when the request was *sent*, not when it *succeeded*. Metering the attempt instead of the outcome.
***Nguyên nhân gốc.** Bộ đếm tăng lên ngay khi **gửi** request, chứ không phải khi request **thành công**. Tức là đang đếm lần thử thay vì đếm kết quả.*

**Fix.** Move the increment to after the awaited call returns successfully:
***Cách sửa.** Dời lệnh tăng bộ đếm xuống sau khi lệnh `await` trả về thành công:*

```swift
let data = try await aiService.generateNarrative(request(for: entry))
usageTracker.recordNarrativeRequest()   // only after success — a failed call costs nothing
                                        // chỉ tính sau khi thành công — gọi lỗi thì không mất lượt
repository.updateNarrative(data.narrative, generatedAt: data.generatedAt, for: entry.id)
```

Because it sits after `try await`, a thrown error skips it entirely — no `catch` bookkeeping needed.
*Vì nó nằm sau `try await`, nếu có lỗi ném ra thì dòng này bị bỏ qua hoàn toàn — không cần xử lý thêm trong `catch`.*

**Lesson.** **Meter the outcome, not the attempt.** Any counter tied to a limit the user paid for belongs on the success path.
***Bài học. Hãy đếm kết quả, đừng đếm lần thử.** Mọi bộ đếm gắn với hạn mức mà người dùng đã trả tiền đều phải nằm trên nhánh thành công.*

This is a one-line change with direct money and trust consequences, which is exactly why it's a good interview story: small diff, clear reasoning about failure modes.
*Đây là thay đổi một dòng nhưng ảnh hưởng trực tiếp tới tiền và niềm tin — chính vì vậy nó là câu chuyện phỏng vấn hay: diff nhỏ, lập luận rõ ràng về các tình huống lỗi.*

---

## 7. ⭐ Account deletion silently didn't delete / Xoá tài khoản nhưng thực ra không xoá

**Task:** `tasks/delete-account-task.md`; shipped in `91ada2f` (2026-07-11)

**Symptom.** "Delete Account" reported success, but the account still existed on the server.
***Biểu hiện.** Nút "Delete Account" báo thành công, nhưng tài khoản vẫn còn trên server.*

**Root cause.** Supabase's GoTrue `DELETE /auth/v1/user` endpoint does **not** delete the calling user from a client context — it needs the service-role key, which must never be shipped in an app binary.
***Nguyên nhân gốc.** Endpoint `DELETE /auth/v1/user` của Supabase GoTrue **không** xoá được người dùng khi gọi từ phía client — nó cần service-role key, mà key này tuyệt đối không được đóng gói trong app.*

The client was calling an endpoint that could never work, and treating a non-error response as confirmation.
*Client đang gọi một endpoint không bao giờ chạy được, rồi coi việc "không có lỗi trả về" là đã xoá thành công.*

**Fix.** A dedicated authenticated Edge Function (`supabase/functions/delete-account`):
***Cách sửa.** Viết riêng một Edge Function có xác thực (`supabase/functions/delete-account`):*

- accepts only `DELETE` and `OPTIONS` (405 otherwise), requires an `Authorization` header
  *chỉ chấp nhận `DELETE` và `OPTIONS` (còn lại trả 405), bắt buộc có header `Authorization`*
- verifies the caller's identity server-side via `/auth/v1/user` with their bearer token
  *xác minh danh tính người gọi ở phía server qua `/auth/v1/user` bằng bearer token của họ*
- deletes **only that verified user** via `/auth/v1/admin/users/{user_id}`, using a service-role key that stays in server-side environment variables
  *chỉ xoá **đúng người dùng đã được xác minh** qua `/auth/v1/admin/users/{user_id}`, dùng service-role key nằm trong biến môi trường phía server*
- the client reports success **only after the server confirms**, and preserves the local session on any network, auth, config, or server failure so the user can retry
  *client chỉ báo thành công **sau khi server xác nhận**, và giữ nguyên phiên đăng nhập nếu có lỗi mạng/xác thực/cấu hình/server để người dùng thử lại được*

**Lesson.** Two things worth saying out loud: (1) privileged operations need a server that holds the privilege — a client can't be trusted with an admin key;
***Bài học.** Hai điều đáng nói ra: (1) thao tác có đặc quyền phải do server nắm giữ đặc quyền thực hiện — không thể giao admin key cho client;*

(2) never optimistically report a destructive action as done. A user who believes their account is deleted when it isn't has been lied to by the software, and that's a trust failure, not just a bug.
*(2) tuyệt đối không báo "đã xong" một cách lạc quan với thao tác huỷ dữ liệu. Người dùng tin rằng tài khoản đã bị xoá trong khi thực tế chưa, tức là phần mềm đã nói dối họ — đó là sự cố về niềm tin, không chỉ là một cái bug.*

---

## 8. Shared image was missing the memory's photo / Ảnh chia sẻ thiếu mất tấm ảnh kỷ niệm

**Commit:** `487dbfa` (2026-05-23, "Task W")

**Symptom.** Sharing a memory produced a card with the AI narrative on a plain gradient — the actual photo was absent, which made the feature nearly pointless.
***Biểu hiện.** Chia sẻ một kỷ niệm chỉ ra được tấm thiệp có chữ narrative trên nền gradient — không có tấm ảnh thật, khiến tính năng gần như vô nghĩa.*

**Root cause.** Not a logic error: `MemoryShareRenderer.render` **had no photo parameter at all.**
***Nguyên nhân gốc.** Không phải lỗi logic: hàm `MemoryShareRenderer.render` **hoàn toàn không có tham số ảnh.***

The share card had been built as a text-and-gradient design and nobody had revisited it.
*Tấm thiệp chia sẻ vốn được thiết kế chỉ gồm chữ và gradient, và không ai quay lại xem xét nó nữa.*

**Fix.** Optional photo drawn full-bleed with a dark gradient overlay and white text; entries with no photo (mood-backdrop and slideshow memories) keep the original gradient layout unchanged.
***Cách sửa.** Thêm tham số ảnh tuỳ chọn, vẽ tràn viền kèm lớp phủ gradient tối và chữ trắng; những mục không có ảnh (kỷ niệm dùng nền cảm xúc và slideshow) giữ nguyên layout gradient cũ.*

**Lesson.** The bug was in the *interface*, not the implementation.
***Bài học.** Lỗi nằm ở **thiết kế hàm (interface)**, không phải ở phần cài đặt.*

Worth remembering that "the function can't express what the feature needs" is a whole category of bug, and it hides well because every line of the existing code is correct.
*Đáng nhớ: "hàm không diễn đạt được điều tính năng cần" là cả một loại lỗi riêng, và nó ẩn mình rất giỏi vì từng dòng code hiện có đều đúng.*

---

## 9. Bugs found during the v2 upgrade / Lỗi phát hiện trong đợt nâng cấp v2 (2026-08)

Included deliberately — these were caught in my own work-in-progress, and how they were caught matters more than the bugs themselves.
*Đưa vào có chủ đích — đây là lỗi phát hiện ngay trong lúc làm, và **cách phát hiện** ra chúng còn quan trọng hơn bản thân cái lỗi.*

### 9.1 ⭐ The verification method was lying / Cách kiểm thử đã "nói dối" (2026-08-18)

**Symptom.** A newly added Swift file passed every check, then wasn't in the app.
***Biểu hiện.** Một file Swift mới thêm vào vượt qua mọi bước kiểm tra, nhưng rốt cuộc lại không có trong app.*

**Root cause.** Verification used `xcrun swiftc -typecheck` on the source files. That compiles **whatever is on disk**, regardless of whether the file is a member of the Xcode target.
***Nguyên nhân gốc.** Việc kiểm tra dùng `xcrun swiftc -typecheck` trên các file nguồn. Lệnh này biên dịch **mọi thứ có trên ổ đĩa**, bất kể file đó có thuộc target Xcode hay không.*

The file had never been registered in `project.pbxproj`, so the real build silently ignored it — while the check happily reported success.
*File chưa từng được đăng ký trong `project.pbxproj`, nên bản build thật lặng lẽ bỏ qua nó — trong khi bước kiểm tra vẫn vui vẻ báo thành công.*

**Fix.** Two changes: the verification standard became a **real `xcodebuild`**, and after adding any new file, confirm it appears in the built target's `SwiftFileList` in DerivedData.
***Cách sửa.** Hai thay đổi: chuẩn kiểm thử đổi thành chạy **`xcodebuild` thật**, và sau khi thêm file mới phải xác nhận nó xuất hiện trong `SwiftFileList` của target trong DerivedData.*

**Lesson.** A green check that doesn't test the real thing is worse than no check — it converts an obvious failure into a silent one. Ask what your test *actually* exercises.
***Bài học.** Một dấu tích xanh không kiểm tra đúng thứ cần kiểm tra còn tệ hơn là không kiểm tra gì — nó biến một lỗi lộ liễu thành lỗi âm thầm. Hãy tự hỏi bài kiểm tra của bạn **thực sự** chạy qua cái gì.*

### 9.2 Share preview re-rendered a 2160×2160 image on every layout pass / Bản xem trước vẽ lại ảnh 2160×2160 mỗi lần layout

Found in self-review before shipping. The preview image was a computed property, so SwiftUI re-rendered an 18MB bitmap on every `body` evaluation.
*Phát hiện khi tự review trước khi ship. Ảnh xem trước là một computed property, nên SwiftUI vẽ lại một bitmap 18MB mỗi lần `body` được tính lại.*

Fixed by rendering once per theme into `@State` via `.task(id: selectedThemeId)`, with the share button disabled until it's ready.
*Sửa bằng cách chỉ vẽ một lần cho mỗi theme, lưu vào `@State` qua `.task(id: selectedThemeId)`, và khoá nút chia sẻ cho tới khi ảnh sẵn sàng.*

**Lesson.** In SwiftUI, `body` runs far more often than you think. Anything expensive belongs in state, keyed to what actually changes it.
***Bài học.** Trong SwiftUI, `body` chạy nhiều hơn bạn tưởng rất nhiều. Mọi thứ tốn tài nguyên nên đưa vào state, gắn khoá theo đúng thứ làm nó thay đổi.*

### 9.3 A patch script filed eight entries into the wrong place / Script vá file đặt nhầm 8 mục

While adding the WidgetKit target by hand-editing `project.pbxproj` (no Xcode GUI available), the script searched for `\t\t<UUID>` to find a definition — but a 4-tab *child reference* line also contains that 2-tab substring.
*Khi thêm target WidgetKit bằng cách sửa tay `project.pbxproj` (không có giao diện Xcode), script tìm chuỗi `\t\t<UUID>` để xác định phần định nghĩa — nhưng dòng tham chiếu con thụt 4 tab cũng chứa chuỗi con 2 tab đó.*

Four files landed in the "Preview Content" group and four build entries in the Resources phase instead of Sources.
*Kết quả: 4 file rơi vào nhóm "Preview Content" và 4 mục build rơi vào giai đoạn Resources thay vì Sources.*

The first build caught it; the fix anchored on the definition line (`\n\t\t<UUID> ... = {`), and every placement was then re-audited programmatically rather than by eye.
*Lần build đầu tiên đã phát hiện ra; bản sửa neo vào đúng dòng định nghĩa (`\n\t\t<UUID> ... = {`), và sau đó mọi vị trí đều được rà soát lại bằng script chứ không nhìn bằng mắt.*

**Lesson.** When generating code or config with string matching, anchor on something structurally unique. And build immediately — the fastest way to find out a mechanical edit went wrong.
***Bài học.** Khi sinh code hoặc cấu hình bằng cách so khớp chuỗi, hãy neo vào thứ gì đó độc nhất về mặt cấu trúc. Và build ngay — đó là cách nhanh nhất để biết một thao tác sửa máy móc đã sai.*

---

## Patterns across all of these / Các mô-típ lặp lại

| Pattern / Mô-típ | Where it showed up / Xuất hiện ở đâu |
|---|---|
| **Meter/report the outcome, not the attempt**<br>***Đếm và báo cáo kết quả, đừng đếm lần thử*** | AI rate limit (§6), account deletion (§7)<br>*Giới hạn AI (§6), xoá tài khoản (§7)* |
| **Layout systems need constraints, not just styling**<br>***Hệ thống layout cần ràng buộc, không chỉ cần styling*** | Overflow (§1), iPad adaptivity (§2)<br>*Tràn màn hình (§1), thích ứng iPad (§2)* |
| **Framework boundaries are where bugs live**<br>***Lỗi hay nằm ở ranh giới giữa các framework*** | Video Y-flip (§4), gesture conflicts (§5), GoTrue client limits (§7)<br>*Lật trục Y video (§4), xung đột cử chỉ (§5), giới hạn client của GoTrue (§7)* |
| **Config bugs surface late and cost the most time**<br>***Lỗi cấu hình lộ ra muộn và tốn thời gian nhất*** | App Store rejections (§3), pbxproj registration (§9.1, §9.3)<br>*Bị App Store từ chối (§3), đăng ký file trong pbxproj (§9.1, §9.3)* |
| **Changing a presentation API moves the interaction**<br>***Đổi API hiển thị là dời luôn chỗ chứa tương tác*** | Dialog → Menu regression (§2)<br>*Lỗi hồi quy khi đổi Dialog → Menu (§2)* |
| **Verify the real artifact, not a proxy for it**<br>***Hãy kiểm tra sản phẩm thật, đừng kiểm tra thứ thay thế nó*** | §9.1, and why every v2 task ends in a real `xcodebuild`<br>*§9.1, và đó là lý do mọi task v2 đều kết thúc bằng `xcodebuild` thật* |

## How bugs actually got caught / Lỗi thực sự được phát hiện bằng cách nào

1. **Device testing by the user** — every layout, tap-target, and iPad bug. No substitute for it.
   ***Người dùng test trên máy thật** — toàn bộ lỗi layout, vùng chạm và iPad. Không có gì thay thế được.*
2. **App Store validation** — three config bugs nothing else would have found.
   ***Khâu kiểm duyệt App Store** — ba lỗi cấu hình mà không cách nào khác tìm ra được.*
3. **A real build** — the pbxproj bugs; a typecheck missed one entirely.
   ***Một bản build thật** — các lỗi pbxproj; kiểm tra kiểu dữ liệu đã bỏ sót hoàn toàn một lỗi.*
4. **Targeted unit tests against the real source file** — how the export's privacy guarantees (no photo bytes, no EXIF, no GPS) were verified without a simulator.
   ***Unit test nhắm thẳng vào file nguồn thật** — đây là cách kiểm chứng các cam kết riêng tư của tính năng export (không có dữ liệu ảnh, không EXIF, không GPS) mà không cần simulator.*
5. **Reading your own diff before calling it done** — the 2160×2160 re-render never shipped.
   ***Đọc lại diff của chính mình trước khi coi là xong** — nhờ vậy lỗi vẽ lại ảnh 2160×2160 không bao giờ lọt ra bản phát hành.*
