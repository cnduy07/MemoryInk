# MemoryInk — Tính năng, Kiến trúc & Lịch sử phát triển

> Sản phẩm là gì, được xây dựng thế nào, tại sao lại xây theo cách đó, và cái gì đã ra mắt vào lúc
> nào.
>
> Viết để bạn có thể trình bày trọn vẹn dự án mà không cần mở code — và bảo vệ được các quyết định,
> vốn mới là phần hay bị hỏi.
>
> Bản tiếng Anh: [`FEATURES_AND_TASKS.md`](FEATURES_AND_TASKS.md) · Tài liệu đi kèm:
> [`BUGS_AND_FIXES.vi.md`](BUGS_AND_FIXES.vi.md) · [`INTERVIEW_PREP.vi.md`](INTERVIEW_PREP.vi.md)
>
> **Cập nhật lần cuối:** 20/08/2026

---

## Tóm tắt trong một đoạn

**MemoryInk là một ứng dụng nhật ký riêng tư trên iOS, biến một tấm ảnh, một cảm xúc và một ghi chú
tuỳ chọn thành một đoạn văn ngắn ấm áp do AI viết — mà tấm ảnh không bao giờ rời khỏi thiết bị.**

Người dùng ghi lại khoảnh khắc; app viết một đoạn suy ngẫm 15–40 từ **chỉ từ metadata** (nhãn nhận
diện ảnh, thẻ ngữ nghĩa, nội dung ghi chú, cảm xúc), rồi gợi lại theo thời gian: tổng kết tuần,
"Ngày này năm xưa", tổng kết năm, các cột mốc, lịch.

App đã lên App Store, viết bằng SwiftUI, dùng Core Data làm nguồn dữ liệu gốc, Supabase Edge
Functions làm lớp trung gian gọi AI, và RevenueCat cho phần đăng ký trả phí.

**Quy mô:** 78 file Swift · ~14.100 dòng · 44 commit · 3 Supabase Edge Function · 30 unit test ·
**một** thư viện bên thứ ba duy nhất.

**App Store:** https://apps.apple.com/vn/app/memoryink-journal/id6770572153 · bundle
`com.memoryink.app`

---

## Ràng buộc cốt lõi: quyền riêng tư

Hãy nói điều này đầu tiên, vì nó chi phối mọi quyết định còn lại.

| Nguyên tắc | Được đảm bảo bằng cách nào |
|---|---|
| **Ảnh không bao giờ rời khỏi thiết bị** | Trong toàn bộ mã nguồn không tồn tại đường upload nào. Core Data chỉ lưu **chuỗi đường dẫn file**, không lưu dữ liệu ảnh. Supabase Storage hoàn toàn không dùng cho media. |
| **AI chỉ thấy metadata** | Request gửi đi chỉ chứa nhãn nhận diện ảnh, thẻ ngữ nghĩa, nội dung ghi chú, cảm xúc, phong cách và ngôn ngữ. Không bao giờ có ảnh, EXIF hay GPS. |
| **Không thu thập hành vi người dùng** | `AnalyticsService.track()` cố tình để rỗng — có danh sách sự kiện nhưng không hề gửi đi đâu. Không Mixpanel, không Firebase, không SDK nào. |
| **Bản export chứa tham chiếu, không chứa nội dung** | File sao lưu chỉ chứa **tên file** ảnh để sau này import có thể nối lại — đã kiểm chứng bằng test rằng đầu ra không có byte ảnh, không có cấu trúc thư mục, không có trường GPS/EXIF. |
| **Widget chỉ nhận một bản snapshot, không nhận cả nhật ký** | Tiến trình widget chỉ đọc một file JSON nhỏ cùng một ảnh thumbnail, không bao giờ đọc kho Core Data. |

> **Nếu bị hỏi "làm sao bạn chắc chắn?"** — các quy tắc export được bảo vệ bởi những khẳng định
> (assertion) chạy trực tiếp trên file `ExportService.swift` thật, và sẽ fail nếu đầu ra xuất hiện
> bất kỳ chữ nào trong `gps`, `latitude`, `longitude`, `exif`, hoặc một dấu phân cách thư mục. Cam
> kết này được **kiểm chứng**, không chỉ là ý định.

**Vì sao nên nói điều này đầu tiên.** Ở đây quyền riêng tư không phải một câu marketing gắn thêm vào
cuối; nó là một **ràng buộc đã loại bỏ bớt lựa chọn**. Đó là lý do AI làm việc trên metadata thay vì
ảnh, lý do phải có một lớp Edge Function trung gian, lý do widget đọc snapshot, và lý do định dạng
export trông như hiện tại. Việc lần theo được **một** ràng buộc xuyên suốt **năm** quyết định thiết
kế không liên quan nhau là một điều rất đáng thể hiện.

---

## Kiến trúc

```
┌─────────────────────────────────────────────────────────┐
│  SwiftUI Views  ·  Features/ (12 màn hình)              │
├─────────────────────────────────────────────────────────┤
│  ViewModels  ·  gọn nhẹ, theo từng tính năng, @MainActor│
├─────────────────────────────────────────────────────────┤
│  Services/ (15)  ·  AI · Sync · Auth · Ảnh · Export     │
│                     Slideshow · Thông báo · Khoá app    │
├─────────────────────────────────────────────────────────┤
│  Persistence/  ·  Core Data = NGUỒN DỮ LIỆU GỐC         │
│                   JournalEntryRepository (@Published)   │
├─────────────────────────────────────────────────────────┤
│  File trên đĩa  ·  /originals /thumbnails /medium /voice│
└─────────────────────────────────────────────────────────┘
        │                          │
        │ chỉ metadata             │ file snapshot
        ▼                          ▼
  Supabase Edge Functions    App Group container
  (trung gian AI + xoá TK)    → WidgetKit extension
```

**Công nghệ sử dụng:** iOS 16+ · SwiftUI · MVVM thực dụng · Core Data · Swift Concurrency
(async/await) · WidgetKit · LocalAuthentication · AVFoundation · Vision · RevenueCat · Supabase Edge
Functions (Deno/TypeScript).

**Thư viện ngoài: đúng một cái.** RevenueCat, cài qua SPM. Supabase được gọi bằng `URLSession` thuần
— không dùng SDK. Toàn bộ phần còn lại đều là framework chính chủ của Apple.

Đây là lựa chọn có chủ đích: ít thư viện ngoài đồng nghĩa ít rủi ro chuỗi cung ứng, không bị kẹt
phiên bản mỗi khi Apple ra bản OS mới, và sau này không phải gỡ bỏ thứ gì. Cái giá phải trả là tự
viết lớp networking, mà với ba endpoint thì chỉ mất một buổi sáng.

### Sáu quyết định bạn nên bảo vệ được

**1. Core Data là nguồn dữ liệu gốc; Supabase chỉ là bản sao.**

App hoạt động đầy đủ khi offline và với cả người dùng không bao giờ đăng nhập. Đồng bộ chỉ là **tính
năng cộng thêm** cho người dùng trả phí, không phải lớp lưu trữ chính.

Hệ quả: lỗi đồng bộ không bao giờ làm mất nhật ký của người dùng. Trường hợp xấu nhất chỉ là bản
trên cloud bị cũ.

**2. Lưu trước, AI sau.**

Luồng bắt buộc là: người dùng tạo kỷ niệm → **lưu ngay xuống máy** → xếp hàng gọi AI bất đồng bộ →
timeline cập nhật nhẹ nhàng khi kết quả về.

Người dùng không bao giờ phải chờ mạng để giữ lại một kỷ niệm. Mục tiêu độ trễ khi lưu là <300ms; AI
được phép tới 10s chính vì nó nằm ngoài đường đi quan trọng.

**3. Ghi sau thắng, dựa trên `updated_at`, kèm một quy tắc cho xoá.**

Cách xử lý xung đột cố tình đơn giản. Đây là nhật ký một người dùng, không phải tài liệu cộng tác,
nên CRDT hay giao diện gộp dữ liệu chẳng đem lại lợi ích gì mà tốn kém rất nhiều.

Điểm bất đối xứng duy nhất: `deleted_at` thắng một bản cập nhật cũ, nên một bản ghi đã xoá mềm không
bao giờ bị một client cũ làm sống lại.

**4. Ba kích cỡ ảnh, sinh ra một lần lúc lưu.**

Ảnh gốc, thumbnail (500px), ảnh vừa (1600px), cộng thêm cache trong bộ nhớ. Timeline **không bao
giờ** hiển thị ảnh full độ phân giải — đây chính là thứ giữ cho việc cuộn mượt 60fps dù có hàng trăm
thẻ ảnh.

**5. AI không bao giờ viết đè lên một narrative đã có.**

Nếu `aiNarrative` đã tồn tại thì giữ nguyên. Kỷ niệm của người dùng không nên tự đổi câu chữ chỉ vì
họ mở lại màn hình — và điều này cũng giới hạn chi phí. Việc tạo lại phải là hành động rõ ràng: khi
sửa nội dung, hoặc khi bấm thử lại.

**6. Màu được đặt tên theo vai trò, không theo sắc màu.**

Áp dụng từ Phần C, sau khi bảng màu cũ thất bại. Các màn hình gọi `accent`, `success`, `destructive`,
`onAccent`, `ink` — không bao giờ gọi `amber` hay `teal`. Cách cũ khiến cùng một sắc màu mang nghĩa
"cảm xúc: tự hào" ở màn hình này và "kiểu slideshow cổ điển" ở màn hình khác, nên các màn hình chọn
màu bằng mắt và chẳng có gì nhất quán. Tên theo sắc màu giờ chỉ còn tồn tại cho hệ thống cảm xúc,
nơi bản thân sắc màu **chính là** ý nghĩa.

---

## Danh mục tính năng

### Ghi lại khoảnh khắc
- **Tạo kỷ niệm** — ảnh (từ thư viện hoặc máy ảnh) **hoặc** nền cảm xúc cho mục không có ảnh, bộ
  chọn cảm xúc, ghi chú tuỳ chọn, hỗ trợ sẵn đường dẫn ghi âm.
- **Quy trình xử lý ảnh** — ghi ra ảnh gốc + thumbnail 500px + ảnh vừa 1600px ngay lúc lưu, JPEG
  chất lượng 0.82/0.86, có cache trong bộ nhớ.
- **Ưu tiên lưu offline** — ghi xuống máy xong xuôi rồi mới làm bất cứ việc gì khác.

### AI
- **Sinh narrative** — gọi `POST /v1/narratives/generate` qua Supabase Edge Function, nhờ vậy khoá
  OpenAI không bao giờ nằm trong app. Lý tưởng 15–40 từ, tối đa 60. Ba phong cách (Ấm áp, Tối giản,
  Suy ngẫm) chỉ khác nhau ở prompt. Phản hồi có cờ `cached` để client phân biệt kết quả lấy từ cache
  hay vừa sinh mới.
- **Tổng kết tuần** — `POST /v1/recaps/generate`, tóm tắt một tuần cảm xúc. Không tính vào hạn mức
  narrative hằng ngày.
- **Tổng kết năm** — bản nhìn lại cả năm kiểu "Wrapped" dành cho người dùng trả phí, kèm ảnh ghép
  thumbnail.
- **Giới hạn lượt dùng** — 3 lượt/ngày cho bản miễn phí, 15 cho gói tháng, 30 cho gói năm, đếm theo
  ngày trong `AIUsageTracker`. Chỉ tính khi thành công (xem BUGS §6).

### Duyệt lại & gợi nhớ
- **Timeline** — bố cục danh sách **hoặc** lưới (được ghi nhớ), tìm kiếm trong ghi chú và narrative,
  lọc theo cảm xúc, lọc yêu thích, chạm để mở lớp phủ chi tiết với hiệu ứng mờ dần + nhoè nhẹ (xem
  BUGS §9.4 để biết vì sao không dùng matched-geometry).
- **Duyệt dạng thẻ** — chồng thẻ vuốt toàn màn hình.
- **Trình xem kỷ niệm** — xem ảnh toàn màn hình, lật qua lại.
- **Lịch** — lưới tháng với **bản đồ nhiệt theo mật độ cảm xúc** (năm mức đậm nhạt theo số mục/ngày)
  và lọc theo ngày/tháng.
- **Ngày này năm xưa+** — cùng một ngày qua các năm trước, **nhóm theo năm**, kèm dải so sánh
  "Across the years" và bộ đếm hành trình "Ngày thứ N cùng MemoryInk".
- **Cột mốc hành trình** — 15 khoảnh khắc chỉ xuất hiện một lần: theo số kỷ niệm (10→500), theo số
  ngày từ kỷ niệm đầu tiên (30/100/500/1000), và các dịp kỷ niệm năm (1–5 năm). Ngưỡng dùng `>=` nên
  không bao giờ bị bỏ lỡ; nếu nhiều mốc đạt cùng lúc thì chỉ hiện mốc sâu nhất; và mỗi mốc chỉ hiện
  đúng một lần duy nhất.
- **Surprise Me** — mở một kỷ niệm ngẫu nhiên.

### Chia sẻ & xuất dữ liệu
- **Thiệp chia sẻ** — ảnh 1080×1080 vẽ ngay trên máy, có xem trước trực tiếp và **bốn chủ đề**
  (Classic cùng ba cảnh gradient). Cả bốn lối vào chia sẻ đều dùng chung một component duy nhất.
- **Xuất slideshow** — video dựng bằng AVFoundation, có nhạc theo từng cảm xúc và cảnh nền.
- **Sao lưu cục bộ** — xuất file JSON có ghi ngày, gồm ghi chú, cảm xúc, narrative và mục yêu thích,
  lưu vào Files qua share sheet. Miễn phí cho tất cả. Chỉ có metadata — ảnh không nằm trong file.

### Riêng tư & nền tảng
- **Khoá bằng Face ID / Touch ID / mật mã** — tuỳ chọn, mặc định tắt, tự khoá khi chuyển app xuống
  nền, và khởi động ở trạng thái khoá để nhật ký không bao giờ loé lên lúc mở app.
- **Widget màn hình chính & màn hình khoá** — cỡ nhỏ, vừa, tròn, chữ nhật. Lấy dữ liệu từ file
  snapshot trong App Group dùng chung.
- **Nhắc nhở hằng ngày + thông báo Ngày này năm xưa** — thông báo cục bộ qua
  `UNUserNotificationCenter`.
- **Chế độ sáng và tối** — một bảng màu thích ứng đầy đủ với các ngưỡng tương phản được test bảo
  vệ, không phải chỉ đổi màu nhấn.

### Tài khoản & doanh thu
- **Đăng nhập bằng Apple + email** (V1 không cần xác thực email). Người dùng miễn phí không cần tài
  khoản.
- **Đồng bộ chỉ metadata** cho người dùng trả phí; áp dụng quy tắc ghi sau thắng.
- **Xoá tài khoản** qua Edge Function có xác thực (xem BUGS §7).
- **Màn hình trả phí** chỉ xuất hiện **sau** khoảnh khắc cảm xúc đầu tiên — không bao giờ hiện ngay
  khi mở app.

| Gói | Giá | Lượt AI mỗi ngày |
|---|---|---|
| Miễn phí | — | 3 |
| Theo tháng | $5.99/tháng | 15 |
| Theo năm | $39.99/năm | 30 |

Dùng RevenueCat, một quyền lợi duy nhất (`premium`), hai sản phẩm `memoryink_monthly` /
`memoryink_yearly`, dùng thử miễn phí 7 ngày. Gói trả phí mở khoá đồng bộ đám mây, hạn mức AI cao
hơn, nhật ký bằng giọng nói, và các phong cách tổng kết cao cấp.

---

## Lịch sử phát triển

| Thời gian | Nội dung |
|---|---|
| **18/05/2026** | **Giai đoạn 0** — dựng nguyên mẫu giao diện timeline. **Giai đoạn 1** — MVP chạy cục bộ: tạo kỷ niệm, Core Data, xử lý ảnh. **Giai đoạn 2** — tích hợp AI qua Supabase Edge Functions. |
| **19/05/2026** | **Giai đoạn 3** — tích hợp RevenueCat; đấu nối và làm chắc phần xác thực Supabase + đồng bộ metadata. |
| **21/05/2026** | **Đợt tính năng V1.1** — sửa/xoá, tìm kiếm, nhắc nhở, lọc cảm xúc, chuyển lưới, thiệp chia sẻ, Surprise Me, cột mốc, chế độ tối, Tổng kết năm, Lịch. Sau đó là Trình xem kỷ niệm, thiết kế lại Recap, chế độ Browse, Cảnh nền, và các bản sửa lỗi tràn/cử chỉ. |
| **23/05/2026** | Xuất video slideshow. Thích ứng iPad + iPhone SE (ba đợt). Sửa lỗi để nộp App Store. **Phát hành lên App Store bản 1.0.** |
| **11/07/2026** | Làm mới giao diện + siết chặt vòng đời tài khoản (xoá qua Edge Function). |
| **18/08/2026** | **v2 Phần A — làm mới giao diện (9/9).** Hợp nhất hệ thống thiết kế: dùng chung một nền gradient ở mọi màn hình, một hero header dùng chung, thang khoảng cách/bo góc, nhúng font serif hiển thị (Spectral, giấy phép SIL OFL), hiệu ứng chuyển cảnh vào lớp phủ chi tiết (sau đó bị thay — BUGS §9.4), rà soát phản hồi rung toàn app, thiết kế lại bốn màn hình, và tách code biểu đồ + cử chỉ vuốt bị trùng lặp thành component dùng chung. |
| **19/08/2026** | **v2 Phần B — tính năng mới (6/6).** Ngày này năm xưa+ & cột mốc hành trình · chủ đề thiệp chia sẻ · xuất dữ liệu cục bộ · bản đồ nhiệt lịch · khoá Face ID · widget màn hình chính/khoá. |
| **19/08/2026** | Kiểm tra Phần B trên máy thật. Cả đợt chỉ tìm ra một lỗi: hiệu ứng chuyển cảnh của Timeline (BUGS §9.4). Nâng phiên bản lên **2.0 (build 5)**, gộp vào `main`, gắn tag `v2.0-appstore`. |
| **20/08/2026** | **v3 Phần C — dựng lại giao diện Cinematic Dark (8/8).** Bảng màu ưu tiên nền tối với ngưỡng tương phản được test bảo vệ, gỡ sạch mọi lớp phủ khỏi ảnh, hạ cảm xúc xuống thành một dấu hiệu nhỏ, đổi chuyển động từ phóng to sang mờ dần + nhoè, đưa font serif sang phần narrative, và chỉnh lại widget + bộ vẽ thiệp chia sẻ. Tìm ra bốn lỗi (BUGS §10). |

### Phạm vi bản nâng cấp v2 được xác định ra sao

Bắt đầu bằng một đợt nghiên cứu đối chiếu với một app tham khảo (*Memories: My Love Days Counter*).

Phát hiện quyết định mọi thứ: **hệ thống thiết kế của MemoryInk đã có sẵn, nhưng chỉ được áp dụng
cho 3 trong khoảng 12 màn hình.** Vì vậy Phần A là hợp nhất, không phải sáng tạo mới — việc tạo tác
động lớn nhất là đưa các component sẵn có ra dùng ở mọi nơi.

Điều quan trọng không kém là những gì đã bị **loại bỏ**. Điểm hút chính của app tham khảo là dành
cho các cặp đôi: không gian chung, thú ảo, tiền xu, nhắn tin trong app. Tất cả đều bị loại vì mang
tính mạng xã hội/game hoá — trái với bản sắc sản phẩm (**tĩnh lặng · riêng tư · cá nhân**) và trái
với những điều cấm ghi rõ trong bộ quy tắc của dự án.

Thứ được giữ lại là **các nhóm ý tưởng** — bộ đếm ngày, widget, khoá riêng tư, thiệp chia sẻ, sao
lưu — được diễn giải lại cho một cuốn nhật ký cá nhân.

> Đáng nói khi phỏng vấn: hệ thống cột mốc **không phải** là chuỗi ngày liên tiếp (streak). Streak
> trừng phạt bạn khi bỏ lỡ một ngày; còn đây là các dịp kỷ niệm tính từ kỷ niệm đầu tiên — không có
> gì bị reset, không có gì bị đứt, không có điểm số nào. Sự phân biệt đó là quyết định về sản phẩm,
> không phải về kỹ thuật, và đó là kiểu phán đoán cho thấy bạn hiểu sản phẩm này dành cho ai.

### Phạm vi Phần C được xác định ra sao

Phần C bắt đầu từ một nhận xét thẳng thắn: giao diện nhìn không đẹp. Bản thân câu đó không hành động
được, nên bước đầu tiên là biến nó thành thứ đo được.

Việc đếm số lần dùng màu đã tìm ra khuyết điểm thật sự. Có 484 chỗ tham chiếu màu, tất cả đều đi qua
một file token duy nhất — và riêng `amber` chiếm 43 chỗ, trong khi chín màu nhấn khác chia nhau 62
chỗ. **App vốn đã có một màu nhấn chủ đạo, chỉ là chưa bao giờ dứt khoát chọn nó.**

Điều đó thay đổi hoàn toàn cách nhìn về khối lượng công việc. "Giao diện xấu" nghe như phải viết lại
18 màn hình; còn "bảng màu đang phân tán qua mười màu nhấn và các token được đặt tên theo sắc màu
thay vì theo vai trò" là một thay đổi ở **một** file cộng với một đợt rà soát. Việc đo đạc đã biến
một nhiệm vụ không có giới hạn thành một nhiệm vụ có giới hạn.

Sau đó, chính hai giả định trong kế hoạch hoá ra lại sai và phải sửa giữa chừng — những màu "thừa"
thật ra là hệ thống cảm xúc, và bộ màu cố định là bất khả thi về mặt toán học (BUGS §10.2). Cả hai
đều được ghi lại trung thực thay vì âm thầm sửa đi, bởi vì **thay đổi kế hoạch khi bằng chứng phản
bác nó** mới chính là điều đáng nói.

---

## Những bài toán kỹ thuật đáng chú ý

**Thêm một extension WidgetKit mà không có giao diện Xcode.**

Toàn bộ target widget — các giai đoạn build, cấu hình build, phụ thuộc target, container proxy, và
giai đoạn nhúng extension của app — được viết thẳng vào `project.pbxproj`, sau đó kiểm chứng bằng
cách xem danh sách target, danh sách file được biên dịch của từng target, và xác nhận file `.appex`
đã nằm trong `MemoryInk.app/PlugIns/` với đúng điểm mở rộng.

**Chọn cách đưa dữ liệu cho widget.**

Có hai phương án: chuyển kho Core Data vào App Group (một kho dữ liệu sống, nhưng phải migrate nhật
ký của mọi người dùng hiện có) hoặc tạo một file snapshot nhỏ (không cần migrate, dữ liệu hơi cũ một
chút).

Phương án snapshot thắng — widget chỉ cần một cảm xúc, một thumbnail và một số ngày, nên rủi ro
migrate chẳng đổi lại được gì. **Kho dữ liệu không hề bị di chuyển.** Đây là ví dụ tốt cho việc chọn
phương án "nhàm chán" vì lợi ích của phương án đắt đỏ không hề áp dụng được ở đây.

**Biến một yêu cầu về khả năng tiếp cận thành thứ test được.**

Độ tương phản thường được kiểm tra bằng mắt hoặc bằng một lượt xem qua của designer. Ở đây nó trở
thành số học: một bộ test giải từng vai trò chữ trên từng bề mặt ở cả hai chế độ và khẳng định tỉ lệ
WCAG.

Điều đó quan trọng vì ba vòng chỉnh tay đã qua được mắt người mà trượt phép tính (BUGS §10.5). Bộ
test cũng mã hoá lại hai sự thật dễ bị quên: rằng `UIColor(Color)` làm mất tính thích ứng của màu,
và rằng màu trắng thuần **sẽ** không đạt chuẩn trên các màu ở chế độ tối — cả hai đều được khẳng
định bằng test, nên lập luận vẫn còn đó kể cả khi người viết ra nó không còn.

**Một component chia sẻ thay vì bốn.**

Thiệp chia sẻ trước đây được dựng ở bốn nơi khác nhau với dữ liệu đầu vào hơi lệch nhau. Lúc thêm
chủ đề chính là thời điểm hợp nhất chúng lại thành một component duy nhất, để phần xem trước và chọn
chủ đề giống hệt nhau ở mọi nơi. Làm tính năng mới là lúc rẻ nhất để trả món nợ trùng lặp kiểu này,
vì dù sao bạn cũng đang phải đụng vào mọi chỗ gọi.

**Kiểm chứng quyền riêng tư từ trước khi có target test.**

`MilestoneService` và `ExportService` chỉ phụ thuộc Foundation, nên có thể biên dịch độc lập cùng
các model giả — các khẳng định chạy trên chính file nguồn thật, bao phủ các cam kết riêng tư của
tính năng export và máy trạng thái của cột mốc (chỉ hiện một lần, tương thích khoá cũ, lệch đồng
hồ). Giờ đã có target test thật (30 test), nhưng kỹ thuật này vẫn đáng biết: những service chỉ phụ
thuộc Foundation có thể test được từ rất lâu trước khi hạ tầng test của app kịp hình thành.

---

## Những câu hỏi bạn dễ bị hỏi

**"AI hoạt động kiểu gì nếu ảnh không bao giờ rời khỏi máy?"**

Framework Vision chạy ngay trên máy để sinh ra nhãn và thẻ ngữ nghĩa. Những thứ đó cùng nội dung ghi
chú, cảm xúc và phong cách được gửi tới một Supabase Edge Function, và hàm này mới gọi OpenAI. Lớp
trung gian tồn tại để khoá API không bao giờ nằm trong file app. Bản thân tấm ảnh không bao giờ có
trong dữ liệu gửi đi.

**"Tại sao dùng Core Data thay vì đồng bộ hết mọi thứ lên server?"**

Vì app phải chạy đầy đủ khi offline và cho cả người dùng không bao giờ tạo tài khoản; và vì nhật ký
là loại dữ liệu mà một lỗi đồng bộ làm mất bài viết là điều không thể tha thứ. Server chỉ là bản sao
cho tiện; thiết bị mới là nguồn sự thật.

**"Bạn xử lý xung đột đồng bộ thế nào?"**

Ghi sau thắng dựa trên `updated_at`, và `deleted_at` thắng các bản cập nhật cũ. Với nhật ký một
người dùng thì đó là mức phức tạp hợp lý — làm gì tinh vi hơn là đang giải một bài toán mà sản phẩm
không hề có.

**"Lỗi khó nhất là lỗi nào?"**

Chọn theo thứ người phỏng vấn có vẻ muốn nghe. BUGS §1 cho câu trả lời kỹ thuật về hệ thống layout,
§6 cho tư duy về các tình huống lỗi, §9.1 cho câu trả lời về quy trình, §9.4 cho việc đọc "hợp đồng"
của một API, hoặc §10.2 nếu bạn muốn cho thấy mình có thể chứng minh một yêu cầu là bất khả thi thay
vì cứ hì hục làm mãi.

**"Kể về một lần bạn đã sai."**

Phần C, sai hai lần trong cùng một task. Kế hoạch ghi là xoá chín màu nhấn thừa — hoá ra chúng chính
là hệ thống cảm xúc. Kế hoạch cũng ghi là giữ các màu cố định để việc xuất ảnh nhất quán — điều đó
bất khả thi về mặt số học. Cả hai đều được phát hiện bằng cách đo đạc chứ không bằng ý kiến, cả hai
đều được ghi vào tài liệu chứ không âm thầm sửa, và mục tiêu "xuất ảnh nhất quán" vẫn đạt được bằng
một cách khác.

**"Làm sao bạn biết phần khả năng tiếp cận của mình là đúng?"**

Nó được khẳng định bằng test, không phải bằng giả định: từng vai trò chữ trên từng bề mặt ở cả hai
chế độ, theo ngưỡng WCAG 4,5:1 cho chữ thường và 3:1 cho phần tử đồ hoạ. Đáng nói thêm rằng việc
chỉnh tay đã sai ba lần trước khi bộ test này ra đời — đó là lý do trung thực cho sự tồn tại của nó.

**"Tiếp theo bạn sẽ làm gì?"**

Nhật ký bằng giọng nói và CloudKit là hai tính năng được cố ý hoãn lại. Gần hơn: mở rộng bộ test ra
ngoài phạm vi bảng màu và các service chỉ phụ thuộc Foundation — lớp SwiftUI hiện vẫn được kiểm tra
thủ công trên máy thật.

**"Phần yếu nhất của codebase là gì?"**

Độ phủ test của lớp giao diện. Phần bảng màu, export và logic cột mốc đã được phủ; còn các view
SwiftUI thì kiểm chứng bằng cách build lên và nhìn. Đó là đánh đổi có chủ đích cho một dự án cá nhân
ở giai đoạn này, không phải điều nên bảo vệ như một chuẩn mực lý tưởng.

Câu trả lời trung thực này tốt hơn một "điểm yếu" giả tạo, và nó ăn khớp với §10 — chính khoảng
trống đó là thứ để lọt những lỗi kia, và phản ứng là **tự động hoá những phép kiểm tra có thể tự
động hoá** thay vì hứa sẽ nhìn kỹ hơn.
