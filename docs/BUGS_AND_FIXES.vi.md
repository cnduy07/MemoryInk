# MemoryInk — Lỗi & Cách sửa

> Ghi chép lại mọi lỗi đáng kể của dự án: chuyện gì đã xảy ra, **tại sao** xảy ra, sửa thế nào, và
> rút ra bài học gì.
>
> Viết theo kiểu để bạn nói ra miệng được. Nếu ai đó hỏi "kể về một lỗi khó mà bạn từng sửa", câu
> trả lời nằm ở đây — và cả quá trình suy luận dẫn tới nó, vốn mới là phần người phỏng vấn thực sự
> muốn nghe.
>
> Bản tiếng Anh: [`BUGS_AND_FIXES.md`](BUGS_AND_FIXES.md) · Tài liệu đi kèm:
> [`FEATURES_AND_TASKS.vi.md`](FEATURES_AND_TASKS.vi.md) · [`INTERVIEW_PREP.vi.md`](INTERVIEW_PREP.vi.md)
>
> **Cập nhật lần cuối:** 20/08/2026

---

## Dùng tài liệu này khi phỏng vấn thế nào

Người phỏng vấn hiếm khi cần một danh sách lỗi. Họ muốn thấy cách bạn **tư duy**. Vì vậy mọi mục
dưới đây đều viết theo cùng một khuôn:

**Biểu hiện** → người dùng thấy gì · **Giả thuyết ban đầu** → thoạt nhìn nó giống lỗi gì, kể cả khi
giả thuyết đó sai · **Nguyên nhân gốc** → cơ chế thật sự · **Cách sửa** → đã thay đổi gì · **Bài
học** → ý tưởng có thể áp dụng cho chỗ khác.

Dòng "giả thuyết ban đầu" là quan trọng nhất. Ai cũng kể lại được một bản sửa sau khi mọi thứ đã
xong. Nói được *"tôi đã tưởng là X, và đây là thứ loại bỏ giả thuyết đó"* mới là điều phân biệt
người thật sự đã gỡ lỗi với người chỉ đọc lại kết quả.

### Những câu chuyện mạnh nhất, xếp theo thứ tự

1. **Lỗi giới hạn AI (§6)** — chỉ dời một dòng code nhưng ảnh hưởng trực tiếp tới tiền của người
   dùng. Đây là câu chuyện "thay đổi nhỏ, lập luận lớn" tốt nhất bạn có.
2. **Bảng màu không thể tồn tại (§10.2)** — bạn chứng minh một yêu cầu là bất khả thi bằng phép
   tính thay vì tranh luận, rồi đổi thiết kế. Hiếm và dễ nhớ.
3. **Xoá tài khoản (§7)** — nói về niềm tin, thẩm quyền phía server, và việc không bao giờ báo
   "thành công" giả với người dùng.
4. **Hiệu ứng hero không hề chuyển động (§9.4)** — đọc **hợp đồng** của một API chứ không chỉ đọc
   chữ ký hàm. Giá trị nằm trọn ở phần chẩn đoán.
5. **Tràn ngang trong SwiftUI (§1)** — cho thấy bạn hiểu cơ chế **hệ thống layout**, không chỉ biết
   gọi API.
6. **Hệ thống build đã "nói dối" (§9.1)** — bạn phát hiện được chính **cách kiểm thử** của mình sai,
   điều này hiếm hơn nhiều so với phát hiện code sai.

### Nếu chỉ thuộc một câu cho mỗi chuyện

- §1 — "`scaledToFill` phóng to nhưng không cắt ảnh, và một đề xuất chiều rộng không giới hạn khiến
  kích thước gốc của ảnh trở thành kích thước của container."
- §6 — "Hãy đếm kết quả, đừng đếm lần thử."
- §7 — "Không bao giờ báo 'đã xong' một cách lạc quan với thao tác huỷ dữ liệu."
- §9.1 — "Kiểm tra kiểu dữ liệu không phải là build; file đó chưa hề nằm trong target."
- §9.4 — "`matchedGeometryEffect` cần view nguồn biến mất, mà view nguồn của tôi thì không bao giờ
  biến mất."
- §10.1 — "`UIColor(Color)` làm mất tính thích ứng của màu, nên bản sửa của tôi không làm gì cả mà
  vẫn biên dịch thành công."
- §10.2 — "Không một màu cố định nào đạt đủ độ tương phản trên cả nền gần đen lẫn nền trắng. Hai
  khoảng giá trị không giao nhau."

---

## 1. Tràn ngang ở màn hình Detail và Browse

**Commit:** `27d09c1`, `d19225c` (21/05/2026)

**Biểu hiện.** Màn hình Memory Detail và Browse có thể cuộn ngang được. Nội dung tràn ra khỏi mép
phải màn hình.

**Giả thuyết ban đầu.** Tưởng là lỗi styling vặt — một chỗ padding thừa hay margin âm. Giả thuyết
này sai, và việc đuổi theo nó tốn thời gian. Không có gì bất thường trong chuỗi padding cả.

**Nguyên nhân gốc.** `scaledToFill()` đặt trên ảnh nằm trong một `ZStack` nhận được **đề xuất chiều
rộng không giới hạn**.

SwiftUI bố trí giao diện bằng cách đề xuất một kích thước cho từng view con rồi hỏi nó muốn bao
nhiêu. `ZStack` không tự ràng buộc chiều rộng nên đẩy thẳng đề xuất đó xuống dưới. `scaledToFill`
trả lời bằng kích thước gốc đã scale của ảnh — với ảnh preview 1600px thì rộng hơn màn hình điện
thoại rất nhiều. Câu trả lời đó lan ngược lên trên và trở thành chiều rộng của container.

Chi tiết mấu chốt: **`scaledToFill` chỉ phóng to chứ không cắt (clip) ảnh.** Nó hoàn toàn "vui vẻ"
với việc mình khổng lồ.

**Cách sửa.** Ràng buộc trước, cắt sau, và sắp thứ tự modifier sao cho `ZStack` nhận được một đề
xuất có giới hạn:

- `imageArea`: `.frame(height: 380).clipped()`, kèm `UIScreen.main.bounds.width` rõ ràng
- Đoạn narrative dài: `.fixedSize(horizontal: false, vertical: true)` để nó xuống dòng thay vì nới
  rộng ra

**Bài học.** Trong SwiftUI, layout là một cuộc **thương lượng**, không phải một tập thuộc tính
styling. Khi thứ gì đó quá rộng, câu hỏi không bao giờ là "padding nào sai" mà là **"ai đã đề xuất
chiều rộng không giới hạn, và view con nào đã trả lời bằng kích thước gốc của nó?"**

Học cách đọc cây view như một cuộc đối thoại thì loại lỗi này trở nên hiển nhiên thay vì bí ẩn.

---

## 2. Thích ứng iPad và iPhone nhỏ

**Commit:** `d8c33d7`, `6fac36c`, `4530edd` (23/05/2026) — ba đợt, vì mỗi lần sửa lại lộ ra vấn đề
tiếp theo.

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| Nút "Done" không bấm tới được trên iPhone SE | `Spacer()` phía trên giãn ra khiến nút bị đẩy ra ngoài màn hình | Giới hạn Spacer ở 80pt; cho nút `frame(maxWidth: .infinity, minHeight: 44)` |
| Hộp thoại chọn ảnh neo sai chỗ trên iPad | Trên iPad, `confirmationDialog` hiện dạng popover và cần một điểm neo mà nó không có | Thay bằng `Menu` — tự neo vào chính nhãn của nó |
| Onboarding kéo giãn hết chiều ngang iPad | Không giới hạn chiều rộng — layout điện thoại bị phóng to | Căn giữa, tối đa 560pt |
| Chữ quá nhỏ trên iPad | Cỡ chữ là hằng số cố định | Mọi style tính cỡ chữ lúc chạy theo `UIDevice.userInterfaceIdiom`; iPad to hơn 13–20% |
| Thẻ Timeline trông lọt thỏm trên iPad | Chiều rộng bị giới hạn 430pt | Lên 580pt khi chiều rộng khung nhìn > 700 |
| **Lỗi hồi quy:** chạm vào thẻ ảnh trống không mở được trình chọn ảnh | Khi đổi dialog sang `Menu`, chỉ có nút được bọc trong Menu, còn trạng thái rỗng thì không | Bọc luôn trạng thái rỗng của `photoPreview` vào cùng `Menu` |

**Bài học.** "Universal app" không phải một tuỳ chọn build, mà là một quyết định thiết kế **cho từng
màn hình**.

Hai điều lặp đi lặp lại: **giới hạn chiều rộng tối đa rõ ràng** (layout điện thoại kéo giãn lên iPad
luôn xấu) và **vùng chạm tối thiểu 44pt** (theo chuẩn HIG của Apple).

Đặc biệt để ý lỗi hồi quy: **đổi API hiển thị là dời luôn chỗ chứa tương tác.**
`confirmationDialog` gắn vào một modifier; `Menu` gắn vào nhãn của nó. Đổi cái này nghĩa là phải
kiểm tra lại mọi điểm vào — và đã bỏ sót một chỗ.

---

## 3. Bị từ chối khi nộp App Store

**Commit:** `9115ce8`, `e4585c6`, `2acfcd4` (23/05/2026)

Ba lỗi chỉ xuất hiện lúc upload, không bao giờ lộ ra khi đang phát triển:

1. **Icon bị từ chối.** Icon 1024×1024 có kênh alpha; App Store Connect không chấp nhận icon lớn có
   nền trong suốt. *Cách sửa:* bỏ kênh alpha, chuyển RGBA → RGB, ghép trên nền trắng (1.5MB →
   920KB).
2. **Chỉ hỗ trợ hướng dọc bị từ chối trên iPad.** Apple yêu cầu app iPad hỗ trợ cả 4 hướng xoay,
   **trừ khi** app từ chối chế độ đa nhiệm. *Cách sửa:* đặt `UIRequiresFullScreen = YES` ở cả cấu
   hình Debug lẫn Release.
3. **Chuỗi mô tả quyền riêng tư sai định dạng.** Các chuỗi mô tả quyền có dấu nháy thừa và một
   khoảng trắng ở đầu, khiến giá trị trong plist build ra bị hỏng.

**Bài học.** Lỗi lúc nộp app là lỗi cấu hình, và vòng phản hồi cực chậm — phải archive và upload
xong mới biết, mỗi lần bị từ chối có thể mất cả ngày.

Cách xử lý là một **checklist trước khi nộp**, không phải trông vào may mắn. Mọi thứ mà trình biên
dịch không kiểm tra được và simulator không cho bạn thấy đều cần một cái "cổng" ghi thành văn bản.

---

## 4. Video slideshow bị lộn ngược

**Commit:** `5f5c51a` (23/05/2026)

**Biểu hiện.** Video slideshow xuất ra bị lật ngược theo chiều dọc.

**Nguyên nhân gốc.** Có một phép lật trục Y được áp dụng ở bước copy `CVPixelBuffer`.

CoreVideo và context vẽ của UIKit có gốc trục Y ngược nhau nên đôi khi cần lật — nhưng ở đây hệ toạ
độ **đã** được chỉnh đúng từ bước trước, và phép lật thứ hai đã huỷ luôn phần chỉnh đó.

**Cách sửa.** Bỏ phép lật trục Y trong `renderFrame` và `renderImageFrame`.

**Bài học.** Đây là lỗi kinh điển "sửa hai lần thành sai". Khi nối các framework có quy ước toạ độ
khác nhau (UIKit ↔ CoreVideo ↔ AVFoundation), chỉ chỉnh hướng ở **đúng một chỗ** và phải biết rõ đó
là chỗ nào. Hai bản sửa nhìn đều đúng khi đứng riêng, nhưng đặt nối tiếp nhau lại ra kết quả sai.

---

## 5. Xung đột cử chỉ và crash khi vuốt

**Commit:** `7099052` (21/05/2026)

- **Vuốt để yêu thích xung đột với ScrollView.** Dùng `.gesture` thường trên thẻ khiến nó tranh chấp
  với cử chỉ kéo của ScrollView cha. *Cách sửa:* dùng `simultaneousGesture` kèm điều kiện kiểm tra
  hướng, để thẻ chỉ nhận chuyển động ngang, còn kéo dọc vẫn cuộn bình thường.
- **Crash khi vuốt nhanh ở Browse.** Chồng thẻ truy cập mảng theo chỉ số trong khi mảng đang bị thay
  đổi — vuốt nhanh có thể đọc vào chỉ số không còn tồn tại. *Cách sửa:* kiểm tra giới hạn chỉ số
  trước khi truy cập.
- **Không đóng được màn hình Browse.** *Cách sửa:* đóng bằng `router.path.removeLast` thay vì cờ
  hiển thị cục bộ, đúng với mô hình điều hướng một nguồn dữ liệu duy nhất của app.

**Bài học.** Cử chỉ tuỳ chỉnh nằm trong scroll view cần quy tắc cùng tồn tại rõ ràng. Và bất kỳ chỉ
số mảng nào do cử chỉ điều khiển trên một collection thay đổi được đều là crash đang chờ một người
dùng thao tác nhanh — lỗi không nằm ở cử chỉ, cũng không nằm ở mảng, mà nằm ở **giả định rằng hai
thứ đó luôn khớp nhau**.

---

## 6. ⭐ Lỗi giới hạn AI — lượt tạo thất bại vẫn trừ hạn mức của người dùng

**Được ghi trong `AGENTS.md`; bản sửa nằm ở `NarrativeGenerationService.swift:134`**

**Biểu hiện.** Người dùng miễn phí có 3 lượt tạo narrative/ngày (gói tháng 15, gói năm 30). Nếu việc
tạo thất bại — rớt mạng, timeout, lỗi server — lượt đó **vẫn bị tính**.

Người dùng có thể mất sạch hạn mức cả ngày mà không nhận được câu narrative nào. Với gói trả phí, đó
là thu tiền mà không giao hàng.

**Nguyên nhân gốc.** Bộ đếm tăng lên ngay khi **gửi** request, chứ không phải khi request **thành
công**. Tức là đang đếm lần thử thay vì đếm kết quả.

**Cách sửa.** Dời lệnh tăng bộ đếm xuống sau khi lệnh `await` trả về thành công:

```swift
let data = try await aiService.generateNarrative(request(for: entry))
usageTracker.recordNarrativeRequest()   // chỉ tính sau khi thành công — gọi lỗi thì không mất lượt
repository.updateNarrative(data.narrative, generatedAt: data.generatedAt, for: entry.id)
```

Vì nó nằm sau `try await`, nếu có lỗi ném ra thì dòng này bị bỏ qua hoàn toàn. Không cần xử lý thêm
trong `catch` — chính luồng điều khiển đã làm việc đó.

**Bài học. Hãy đếm kết quả, đừng đếm lần thử.** Mọi bộ đếm gắn với hạn mức mà người dùng đã trả tiền
đều phải nằm trên nhánh thành công.

**Vì sao đây là câu chuyện phỏng vấn hay.** Chỉ dời một dòng, nhưng ảnh hưởng trực tiếp tới tiền và
niềm tin. Nó cho thấy bạn tư duy về các tình huống lỗi chứ không chỉ về luồng thuận lợi, và bản sửa
đủ nhỏ để giải thích trọn vẹn trong ba mươi giây.

---

## 7. ⭐ Xoá tài khoản nhưng thực ra không xoá

**Task:** `tasks/delete-account-task.md`; phát hành trong `91ada2f` (11/07/2026)

**Biểu hiện.** Nút "Delete Account" báo thành công, nhưng tài khoản vẫn còn trên server.

**Nguyên nhân gốc.** Endpoint `DELETE /auth/v1/user` của Supabase GoTrue **không** xoá được người
dùng khi gọi từ phía client. Nó cần service-role key, mà key này tuyệt đối không được đóng gói trong
app.

Vậy là client đang gọi một endpoint không bao giờ chạy được, rồi coi việc "không có lỗi trả về" là
đã xoá thành công. Hai lỗi chồng lên nhau: **gọi sai endpoint**, và **coi "không lỗi" là "thành
công"**.

**Cách sửa.** Viết riêng một Edge Function có xác thực (`supabase/functions/delete-account`):

- chỉ chấp nhận `DELETE` và `OPTIONS` (còn lại trả 405), bắt buộc có header `Authorization`
- xác minh danh tính người gọi ở phía server qua `/auth/v1/user` bằng bearer token của họ
- chỉ xoá **đúng người dùng đã được xác minh** qua `/auth/v1/admin/users/{user_id}`, dùng
  service-role key nằm trong biến môi trường phía server
- client chỉ báo thành công **sau khi server xác nhận**, và giữ nguyên phiên đăng nhập nếu có lỗi
  mạng/xác thực/cấu hình/server để người dùng thử lại được

**Bài học.** Hai điều đáng nói ra:

1. **Thao tác có đặc quyền phải do server nắm giữ đặc quyền thực hiện.** Không thể giao admin key
   cho client, nên bất kỳ thiết kế nào đòi hỏi có key đó trên máy người dùng đều đã sai từ đầu.
2. **Tuyệt đối không báo "đã xong" một cách lạc quan với thao tác huỷ dữ liệu.** Người dùng tin rằng
   tài khoản đã bị xoá trong khi thực tế chưa, tức là phần mềm đã nói dối họ. Đó là sự cố về niềm
   tin, không chỉ là một cái bug — và đây cũng là loại vấn đề mà cơ quan quản lý quan tâm.

---

## 8. Ảnh chia sẻ thiếu mất tấm ảnh kỷ niệm

**Commit:** `487dbfa` (23/05/2026)

**Biểu hiện.** Chia sẻ một kỷ niệm chỉ ra được tấm thiệp có chữ narrative trên nền gradient. Không
có tấm ảnh thật, khiến tính năng gần như vô nghĩa.

**Nguyên nhân gốc.** Không phải lỗi logic: hàm `MemoryShareRenderer.render` **hoàn toàn không có
tham số ảnh.** Tấm thiệp vốn được thiết kế chỉ gồm chữ và gradient, và không ai quay lại xem xét nó
nữa.

**Cách sửa.** Thêm tham số ảnh tuỳ chọn, vẽ tràn viền kèm lớp phủ gradient tối và chữ trắng. Những
mục không có ảnh (kỷ niệm dùng nền cảm xúc và slideshow) giữ nguyên layout gradient cũ.

**Bài học.** Lỗi nằm ở **thiết kế hàm (interface)**, không phải ở phần cài đặt.

"Hàm không diễn đạt được điều tính năng cần" là cả một loại lỗi riêng, và nó ẩn mình cực giỏi **vì
từng dòng code hiện có đều đúng.** Review code sẽ không bắt được nó. Chỉ có dùng thử tính năng mới
phát hiện ra.

---

## 9. Lỗi phát hiện trong đợt nâng cấp v2 (08/2026)

### 9.1 ⭐ Cách kiểm thử đã "nói dối"

**Biểu hiện.** Một task được báo là đã hoàn thành và đã kiểm chứng. Lần build thật ngay sau đó thất
bại lập tức với lỗi thiếu symbol.

**Nguyên nhân gốc.** Việc kiểm chứng chỉ là một lượt **kiểm tra kiểu dữ liệu** bằng `swiftc` trên
một danh sách file, không phải build thật. Một file mới thêm chưa hề được đăng ký vào target Xcode,
nên:

- lượt kiểm tra kiểu qua được, vì file đó được đưa vào một cách tường minh
- build thật thất bại, vì target không hề chứa file đó

Cách kiểm chứng và sản phẩm thật đang nhìn vào hai tập file khác nhau.

**Cách sửa.** Hai thay đổi. Chuẩn kiểm chứng đổi thành chạy **`xcodebuild` thật**. Và sau khi thêm
file mới phải xác nhận nó xuất hiện trong `SwiftFileList` của target trong DerivedData.

**Bài học. Hãy kiểm tra sản phẩm thật, đừng kiểm tra thứ thay thế nó.** Một phương án rẻ hơn bản
thật thường rẻ vì nó bỏ qua đúng cái bước sẽ hỏng.

Đây là kỹ năng hiếm hơn: nhận ra **cách kiểm tra** của mình sai, chứ không phải code sai. Mọi thứ
nằm sau một phép kiểm tra hỏng đều coi như chưa được kiểm chứng, kể cả những thứ đã "pass".

### 9.2 Bản xem trước vẽ lại ảnh 2160×2160 mỗi lần layout

**Biểu hiện.** Phát hiện nhờ đọc lại diff trước khi coi task là xong — chưa bao giờ lọt ra bản phát
hành.

Sheet chia sẻ có chủ đề gọi thẳng `MemoryShareRenderer.render(...)` bên trong `body`. SwiftUI tính
lại `body` mỗi khi state đổi, nên mỗi lần như vậy lại chạy một lượt vẽ ảnh 2160×2160 đầy đủ.

**Cách sửa.** Chỉ vẽ một lần cho mỗi theme, lưu vào `@State` qua `.task(id: selectedThemeId)`, và
khoá nút chia sẻ cho tới khi ảnh sẵn sàng.

**Bài học.** Trong SwiftUI, `body` chạy nhiều hơn bạn tưởng rất nhiều. Mọi thứ tốn tài nguyên nên
đưa vào state, gắn khoá theo đúng thứ làm nó thay đổi. Hãy coi `body` như một hàm thuần có thể bị
gọi bất cứ lúc nào, vì bất cứ lý do gì.

### 9.3 Script vá file đặt nhầm 8 mục

**Biểu hiện.** Khi thêm target WidgetKit bằng cách sửa tay `project.pbxproj` (không có giao diện
Xcode), 4 file rơi vào nhóm "Preview Content" và 4 mục build rơi vào giai đoạn Resources thay vì
Sources.

**Nguyên nhân gốc.** Script tìm chuỗi `\t\t<UUID>` để xác định phần định nghĩa — nhưng dòng tham
chiếu con thụt 4 tab cũng chứa chuỗi con 2 tab đó.

**Cách sửa.** Neo vào toàn bộ cấu trúc của dòng định nghĩa (`\n\t\t<UUID> ... = {`), và rà soát lại
mọi vị trí bằng script chứ không nhìn bằng mắt.

**Bài học.** Khi sinh code hoặc cấu hình bằng cách so khớp chuỗi, hãy neo vào thứ gì đó **độc nhất
về mặt cấu trúc**, không chỉ là "có xuất hiện". Và build ngay — build thật là cách nhanh nhất để
biết một thao tác sửa máy móc đã sai.

### 9.4 ⭐ Hiệu ứng hero ghim ảnh đúng chỗ thẻ đang đứng

**Sửa ngày 19/08/2026, commit `7123b47`**

**Biểu hiện.** Chạm vào một kỷ niệm ở Timeline thì lớp phủ chi tiết mở ra với tấm ảnh dính đúng vị
trí của thẻ nguồn trên màn hình: thẻ đang ở trên đầu → ảnh nằm trên đầu lớp phủ; thẻ ở gần cuối →
ảnh nằm dưới đáy. Nó sai ngay từ khoảnh khắc lớp phủ hiện ra, và không có chuyển động nào cả.

**Giả thuyết ban đầu — và manh mối đã bác bỏ nó.** Cách hiểu hiển nhiên là "hiệu ứng kết thúc sai
chỗ". Nhưng **một hiệu ứng hero chỉ kết thúc sai chỗ thì vẫn phải có chuyển động.** Cái này thì đứng
yên hoàn toàn. Quan sát đó đã đổi hướng toàn bộ quá trình chẩn đoán: câu hỏi không còn là *"tại sao
điểm đến sai"* mà thành *"rốt cuộc có transition nào đang chạy không?"*

**Nguyên nhân gốc.** `matchedGeometryEffect` là API **bàn giao** hình học, không phải API "chép
khung một lần". Nó giả định tại mỗi thời điểm chỉ có đúng một view nguồn còn sống:

- view nguồn công bố khung của nó
- view không-nguồn bị bố trí **tại** khung đó suốt thời gian view nguồn còn tồn tại
- ta chỉ **thấy** nó như một hiệu ứng biến hình vì sau đó view nguồn biến mất, và view không-nguồn
  mới giãn về layout của chính nó

Lớp phủ của MemoryInk phá vỡ giả định đó. Gán `selectedMemory` không thay thế Timeline — nó chồng
thêm một lớp lên trên, trong cùng một `ZStack`, còn scroll view vẫn nằm nguyên đó suốt thời gian ấy,
chỉ bị làm mờ và `allowsHitTesting(false)`.

Nghĩa là thẻ thu gọn (`isSource: true`) không bao giờ rời đi. Thẻ trong lớp phủ không hề chuyển động
**từ** khung của thẻ nguồn; nó bị bố trí **tại** khung đó, vĩnh viễn, layout căn giữa của chính nó
bị ghi đè suốt thời gian lớp phủ còn mở. Vì vậy mới không có chuyển động: không có transition nào,
chỉ có một lệnh ghi đè hình học áp dụng ngay ở khung hình đầu tiên.

**Cách sửa.** Bỏ hẳn `matchedGeometryEffect` cho lớp phủ này — bỏ helper, bỏ `@Namespace`, bỏ tham
số `namespace` của `TimelineCard`, và bỏ ở cả ba chỗ gọi. Bản thân lớp phủ vốn đã có sẵn
`.transition(.opacity.combined(with: .scale(scale: 0.985)))` chạy bằng `withAnimation`. Khi lệnh ghi
đè hình học biến mất, transition đó được tự do chạy.

Muốn có hiệu ứng matched-geometry đúng nghĩa ở đây thì phải trình bày kiểu `fullScreenCover`, nơi
thẻ ở Timeline thực sự bị gỡ đi trong lúc màn chi tiết đang mở — đó là thay đổi lớn hơn nhiều về mô
hình hiển thị của lớp phủ, không đáng so với giá trị mà hiệu ứng mang lại.

**Bài học.** Trước khi dùng một API hoạt ảnh, hãy kiểm tra xem cây view của bạn có thoả mãn **giả
định mà API đó dựa vào** hay không. `matchedGeometryEffect` cần view nguồn **biến mất**; một lớp phủ
giữ nguyên mọi thứ bên dưới thì không bao giờ đáp ứng được điều đó.

Và khi một transition **hoàn toàn không có chuyển động**, đừng đi tìm "điểm đến sai" — hãy hỏi trước
xem có transition nào đang chạy hay không.

**Phát hiện bởi:** người dùng test trên máy thật, ngay ở thao tác được dùng nhiều nhất của app. Cả
build lẫn kiểm tra kiểu dữ liệu đều qua ngon lành — code hợp lệ, chỉ có giả định là sai.

---

## 10. Lỗi phát hiện trong Phần C — đợt dựng lại giao diện Cinematic Dark (20/08/2026)

Phần C viết lại hệ thống màu, chữ và chuyển động của app theo hướng ưu tiên nền tối. Bốn lỗi dưới
đây có chung một đặc điểm đáng đặt tên: **tất cả đều vô hình với trình biên dịch và với một bản build
thành công.**

### 10.1 ⭐ `UIColor(Color)` âm thầm làm mất tính thích ứng của màu

**Biểu hiện.** Một test độ tương phản báo rằng cả mười hai màu cảm xúc có độ sáng **giống hệt nhau**
ở chế độ sáng và tối — đều là `0.1733`, đúng bằng giá trị mục tiêu của chế độ sáng.

**Vì sao con số đó là manh mối.** Độ sáng giống hệt nhau ở cả hai chế độ chỉ có thể xảy ra nếu tính
thích ứng đã bị vứt bỏ **trước khi** đo. Các màu không phải "không thích ứng được"; chúng đã bị **làm
phẳng** ở đâu đó phía trên.

**Nguyên nhân gốc.** Bảng màu định nghĩa mỗi màu là một `UIColor` động (một closure được giải theo
trait collection), rồi bọc lại cho SwiftUI thành `Color(dynamicUIColor)`. Chuyển **ngược** lại bằng
`UIColor(someColor)` không khôi phục được closure đó — nó giải ra theo chế độ đang hiện hành và trả
về một màu tĩnh. Sau vòng chuyển đổi đó, `resolvedColor(with:)` **không làm gì cả**: nó trả về cùng
một giá trị cho cả hai trait.

**Điều đó làm hỏng gì trong sản phẩm.** `MemoryShareRenderer` nung màu cảm xúc vào ảnh PNG 1080×1080
xuất ra. Để một tấm thiệp chia sẻ trông giống nhau với mọi người, renderer ghim màu vào một chế độ
cố định:

```swift
UIColor(mood.tint).resolvedColor(with: exportTraits)   // nhìn thì đúng, thực ra không làm gì
```

Vì bị làm phẳng, dòng này biên dịch được, chạy được, và không có tác dụng gì. Một tấm thiệp xuất từ
máy đang ở chế độ sáng sẽ có màu khác với cùng kỷ niệm đó xuất từ máy đang ở chế độ tối, và người
nhận sẽ thấy đúng cái chế độ mà người gửi tình cờ đang dùng.

**Cách sửa.** Lấy `UIColor` động làm nguồn sự thật (`MemoryInkColors.Raw`) và để các giá trị `Color`
bọc **quanh nó**, không bao giờ làm ngược lại. Mọi thứ vẽ ra ảnh đều lấy từ `Raw` và giải một cách
tường minh. `MoodType` được thêm `tintRaw: UIColor` cũng vì lý do đó.

Hiện có một test khẳng định rằng hiện tượng làm phẳng **vẫn đang xảy ra** — để nếu sau này Apple đổi
hành vi, ta có thể bỏ lớp trung gian đi thay vì giữ mãi theo quán tính.

**Bài học.** Một bản sửa biên dịch được chưa chắc đã là bản sửa. Cái này nhìn đúng khi review, đúng
trong diff, và đúng cả khi app đang chạy — thứ duy nhất phơi bày nó ra là đo giá trị đầu ra thật.

Việc bắc cầu giữa hai hệ kiểu (SwiftUI `Color` ↔ UIKit `UIColor`) có thể **mất mát theo một chiều**,
và sự mất mát đó diễn ra âm thầm. Mỗi khi chuyển đổi qua một ranh giới như vậy, hãy tự hỏi kiểu đích
**không** biểu diễn được điều gì.

### 10.2 ⭐ Yêu cầu về bảng màu là bất khả thi về mặt số học

**Biểu hiện.** Mục tiêu thiết kế là một bộ màu cố định dùng được trên cả nền gần đen lẫn nền trắng.
Mọi lần thử đều hoặc nhìn đục, hoặc không đạt độ tương phản.

**Cách giải quyết dứt điểm.** Thay vì tiếp tục chỉnh bằng mắt, yêu cầu đó được kiểm tra trực tiếp.
Độ tương phản WCAG là `(L1 + 0.05) / (L2 + 0.05)` trên độ sáng tương đối, nên có thể giải ra biên:

- để đạt chuẩn AA (4,5:1) trên nền gần đen, màu cần độ sáng **≥ 0,195**
- để đạt AA trên nền trắng, màu cần độ sáng **≤ 0,161**

Hai khoảng đó **không giao nhau**. Không một màu cố định nào đạt chuẩn ở cả hai chế độ. Đây là số
học, không phải gu thẩm mỹ, và có chỉnh bao lâu cũng không bao giờ tìm ra được giá trị phù hợp.

Hạ xuống ngưỡng 3:1 dành cho đối tượng đồ hoạ thì **có** giá trị cố định — nhưng chỉ toàn màu đục.
Giải màu amber vào khoảng đó ra `0,59 / 0,46 / 0,27`, tức một màu nâu, phá hỏng toàn bộ hướng thiết
kế.

**Cách sửa.** Mọi màu đều thích ứng: một biến thể sáng cho nền tối, một biến thể đậm hơn cho nền
sáng. Còn bài toán "xuất ảnh phải nhất quán" — thứ mà màu cố định vốn định giải — được chuyển về
đúng chỗ của nó: ghim renderer (§10.1).

**Một lỗi thứ hai rơi ra từ cùng phép tính đó.** Khi các màu đảo chiều, mọi nút có nền màu trong app
đều hỏng. Tất cả đều dùng `.foregroundStyle(.white)` trên nền màu, vốn an toàn khi các màu còn tối.
Ở chế độ tối, màu giờ **sáng** — amber ở mức độ sáng 0,51 — nên chữ trắng trên nền amber rơi xuống
khoảng **1,9:1**: không đạt chuẩn, và nhìn rất chói mắt.

Cách sửa là thêm một vai trò ngữ nghĩa mới, `onAccent`, đảo chiều **ngược với màu nền của nút** chứ
không phải ngược với nền màn hình: gần đen trên các màu sáng ở chế độ tối, gần trắng trên các màu
đậm ở chế độ sáng. Nó được áp dụng cho 17 nút có nền màu ở 9 file.

**Bài học.** Khi một yêu cầu thiết kế cứ chống lại mọi nỗ lực, hãy kiểm tra xem nó có **thoả mãn
được** hay không trước khi chỉnh tiếp. Các ràng buộc về khả năng tiếp cận, layout và hiệu năng
thường là số học, mà số học thì giải được chứ không cần tranh cãi.

Ngoài ra: đổi bảng màu không bao giờ là thay đổi cục bộ. Việc đảo chiều các màu đã âm thầm làm đổi
màu chữ đúng cho mọi nút có nền màu trong app, và trình biên dịch không hề hay biết.

### 10.3 Chủ đề chia sẻ có nền sáng lại đi lấy màu chữ của app

**Biểu hiện.** Chủ đề chia sẻ `Parchment` lẽ ra sẽ hiện chữ gần trắng trên nền giấy nhạt — tức là
gần như vô hình.

**Nguyên nhân gốc.** Thiệp chia sẻ có hai loại: các chủ đề có nền gradient cố định, và chủ đề
Classic dùng chính màu nền của app. Renderer chọn màu chữ bằng một cờ duy nhất, `usesLightInk`, và
khi cờ này là false thì quay về lấy màu `ink` của bảng màu app.

Khi việc xuất ảnh bị ghim vào chế độ tối (§10.1), màu `ink` của bảng màu giải ra thành **gần trắng**.
Cảnh `Parchment` là nền sáng với `usesLightInk: false`, nên nó đi lấy màu chữ của app và nhận về màu
trắng.

Sai lầm sâu hơn: **màu chữ của tấm thiệp lẽ ra không nên phụ thuộc vào chế độ hiển thị của app chút
nào.** Một tấm thiệp chia sẻ là một bức ảnh cố định. Nền của nó hoặc là artwork gradient cứng, hoặc
là nền đã ghim — cả hai đều không đi theo cài đặt sáng/tối của người dùng, nên chữ trên nó cũng
không nên đi theo.

**Cách sửa.** Hai hằng số cố định, `inkOnDarkArtwork` và `inkOnLightArtwork`, chọn theo đúng cái nền
mà chữ nằm lên, không theo gì khác. Cờ của Classic cũng được sửa lại cho đúng: từ Phần C, nền của nó
là gần đen, nên giờ nó khai báo trung thực rằng nó cần màu chữ sáng.

Nhân tiện, màu cảm xúc được chỉnh để phủ lên nhãn mood ở **mọi** chủ đề. Trước đó nó quay về màu
trắng phẳng ở các chủ đề chữ sáng, âm thầm làm mất đi đúng cái mảng màu mà tấm thiệp được xây quanh.

**Bài học.** Hãy hỏi một giá trị nên **đi theo cái gì**. Chữ trên ảnh render thì đi theo bức ảnh;
chữ trong giao diện thì đi theo giao diện. Dùng chung một token cho cả hai là ghép cứng hai thứ chỉ
trông giống nhau bề ngoài.

### 10.4 `Font.custom` lỗi trong im lặng, và suýt xoá sổ font serif khỏi app

**Biểu hiện.** Không có biểu hiện nào — phát hiện trước khi build, nhờ kiểm tra lại bundle.

Thang chữ mới được viết với giả định `Spectral-Regular` và `Spectral-Medium` đã có sẵn, vì một
weight nhẹ hơn sẽ dễ đọc hơn cho đoạn narrative dài. Nhưng trong bundle chỉ có
`Spectral-SemiBold.ttf`.

**Vì sao sẽ không ai nhận ra.** `Font.custom` **âm thầm quay về font hệ thống** khi không tìm thấy
tên font. Không crash, không cảnh báo, không log. Tiêu đề và narrative sẽ chỉ đơn giản hiện bằng SF
Pro, và cái "font serif hiển thị được nhúng" mà app đã phát hành từ hai mốc trước sẽ biến mất khỏi
mọi màn hình — với một bản build xanh và test đều pass.

**Cách sửa.** Hàm helper giờ không nhận tham số weight nữa; nó chỉ có thể yêu cầu đúng font đang tồn
tại. Các cỡ chữ được chọn lại cho một font semibold, vốn nhìn đậm hơn font regular ở cùng cỡ. Việc
thêm một weight nhẹ hơn được đưa vào danh sách việc cần làm thật sự, vì file font còn cần một mục
trong `Info.plist` mà file đó lại bị gitignore.

**Bài học.** Phải biết API nào báo lỗi ầm ĩ và API nào lỗi trong im lặng. Cơ chế quay về mặc định là
một **tính năng** xét về độ bền, nhưng là một **cái bẫy** xét về tính đúng đắn — và nên grep lại
chính giả định của mình trên bundle trước khi tin vào nó.

### 10.5 Ba vòng chỉnh độ tương phản nhìn thì đúng mà thực ra sai

**Biểu hiện.** Màu chữ chỉnh bằng mắt trên nền tiêu chuẩn đã qua được vòng kiểm tra thị giác ba lần
và trượt phép tính ba lần: **4,23:1**, rồi **4,25:1**, rồi **4,28:1** — đều dưới ngưỡng 4,5:1.

**Nguyên nhân gốc.** Mỗi vòng chỉ đo chữ trên **nền tiêu chuẩn**. Nhưng app có tới bốn bề mặt —
`parchmentDeep`, `parchment`, `paper`, `paperWarm` — và trường hợp xấu nhất không phải là bề mặt tiêu
chuẩn. Ở chế độ tối, bề mặt xấu nhất là `paperWarm` (bề mặt tối sáng nhất); ở chế độ sáng là
`parchmentDeep` (bề mặt sáng tối nhất).

**Cách sửa.** `tertiaryInk` được giải theo bề mặt xấu nhất của từng chế độ thay vì theo bề mặt phổ
biến. Phép kiểm tra trở thành một bộ test thường trực (`PaletteContrastTests`) phủ mọi vai trò chữ ×
mọi bề mặt × cả hai chế độ, cộng thêm ngưỡng cho các màu, thứ tự thang nền, tính nhất quán khi xuất
ảnh, và `onAccent` trên từng màu.

**Bài học.** Độ tương phản không phải thuộc tính của **một màu**, mà là thuộc tính của một **cặp
màu**. Kiểm tra trên trường hợp phổ biến sẽ pass trong khi trường hợp xấu nhất thật sự lại trượt.

Rộng hơn: ba vòng phán đoán cẩn thận của con người thua một phép tính. Khi một tính chất đúng đắn có
thể tính được, hãy tính nó — và đặt phép tính đó vào chỗ nó sẽ tự chạy lại, vì nếu không nó sẽ hỏng
lại trong im lặng.

---

## Các mô-típ lặp lại

| Mô-típ | Xuất hiện ở đâu |
|---|---|
| **Đếm và báo cáo kết quả, đừng đếm lần thử** | Giới hạn AI (§6), xoá tài khoản (§7) |
| **Hệ thống layout cần ràng buộc, không chỉ cần styling** | Tràn màn hình (§1), thích ứng iPad (§2) |
| **Lỗi hay nằm ở ranh giới giữa các framework** | Lật trục Y video (§4), xung đột cử chỉ (§5), giới hạn client của GoTrue (§7), `Color` ↔ `UIColor` (§10.1) |
| **Lỗi cấu hình lộ ra muộn và tốn thời gian nhất** | Bị App Store từ chối (§3), đăng ký file trong pbxproj (§9.1, §9.3) |
| **Đổi API hiển thị là dời luôn chỗ chứa tương tác** | Lỗi hồi quy khi đổi Dialog → Menu (§2) |
| **Hãy kiểm tra sản phẩm thật, đừng kiểm tra thứ thay thế nó** | §9.1, và đó là lý do mọi task v2/v3 đều kết thúc bằng `xcodebuild` thật |
| **Mỗi API đều giả định một cấu trúc — hãy kiểm tra bạn có đáp ứng không** | `matchedGeometryEffect` cần view nguồn bị gỡ bỏ (§9.4) |
| **Lỗi trong im lặng nguy hiểm hơn lỗi ầm ĩ** | `UIColor(Color)` làm phẳng màu (§10.1), `Font.custom` quay về mặc định (§10.4) |
| **Tính chất nào tính được thì hãy tính** | Bảng màu bất khả thi (§10.2), ngưỡng tương phản (§10.5) |

## Lỗi thực sự được phát hiện bằng cách nào

1. **Người dùng test trên máy thật** — toàn bộ lỗi layout, vùng chạm và iPad, cộng thêm hiệu ứng
   hero (§9.4). Không có gì thay thế được.
2. **Đo đạc tự động** — toàn bộ cụm §10. Ba trong bốn lỗi đó vô hình với build, với review, và với
   cả app đang chạy.
3. **Khâu kiểm duyệt App Store** — ba lỗi cấu hình mà không cách nào khác tìm ra được.
4. **Một bản build thật** — các lỗi pbxproj; kiểm tra kiểu dữ liệu đã bỏ sót hoàn toàn một lỗi.
5. **Unit test nhắm thẳng vào file nguồn thật** — cách kiểm chứng các cam kết riêng tư của tính năng
   export (không có dữ liệu ảnh, không EXIF, không GPS) từ trước khi có target test.
6. **Đọc lại diff của chính mình trước khi coi là xong** — nhờ vậy lỗi vẽ lại ảnh 2160×2160 (§9.2)
   không bao giờ lọt ra bản phát hành.

Đáng chú ý là tỷ trọng đã dịch chuyển. Các lỗi thời kỳ đầu được phát hiện bằng cách **nhìn** vào
app. Còn các lỗi ở Phần C thì hoàn toàn không thể bắt theo cách đó — một màu sai nhưng hợp lý trông
vẫn ổn với bất kỳ ai không biết trước nó phải như thế nào. Khi các kiểu lỗi ngày càng im lặng hơn,
cách kiểm chứng buộc phải máy móc hơn.
