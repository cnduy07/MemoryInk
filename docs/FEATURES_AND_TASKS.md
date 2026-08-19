# MemoryInk — Features, Architecture & Delivery History
# MemoryInk — Tính năng, Kiến trúc & Lịch sử phát triển

> What the app is, how it's built, what shipped when, and why each significant decision was made.
> *App này là gì, được xây dựng ra sao, cái gì ra mắt lúc nào, và vì sao mỗi quyết định quan trọng lại được đưa ra như vậy.*
>
> Written to be explainable out loud.
> *Viết theo kiểu để bạn có thể nói ra miệng và giải thích được.*
>
> Companion document: [`BUGS_AND_FIXES.md`](BUGS_AND_FIXES.md).
> *Tài liệu đi kèm: [`BUGS_AND_FIXES.md`](BUGS_AND_FIXES.md).*
>
> **Last updated:** 2026-08-19 · *Cập nhật lần cuối: 19/08/2026*

---

## The one-paragraph version / Tóm tắt trong một đoạn

**MemoryInk is a private iOS journal that turns a photo, a mood, and an optional note into a short warm narrative written by AI — without the photo ever leaving the device.**
***MemoryInk là một ứng dụng nhật ký riêng tư trên iOS, biến một tấm ảnh, một cảm xúc và một ghi chú tuỳ chọn thành một đoạn văn ngắn ấm áp do AI viết — mà tấm ảnh không bao giờ rời khỏi thiết bị.***

Users capture moments, the app writes a 15–40 word reflection from *metadata only* (vision labels, tags, note text, mood), and surfaces them back over time: a weekly recap, "On This Day", a yearly review, milestones, a calendar.
*Người dùng ghi lại khoảnh khắc, app viết một đoạn suy ngẫm 15–40 từ **chỉ từ metadata** (nhãn nhận diện ảnh, thẻ ngữ nghĩa, nội dung ghi chú, cảm xúc), rồi gợi lại theo thời gian: tổng kết tuần, "Ngày này năm xưa", tổng kết năm, các cột mốc, lịch.*

It's live on the App Store, built in SwiftUI with Core Data as the source of truth, Supabase Edge Functions as an AI proxy, and RevenueCat for subscriptions.
*App đã lên App Store, viết bằng SwiftUI, dùng Core Data làm nguồn dữ liệu gốc, Supabase Edge Functions làm lớp trung gian gọi AI, và RevenueCat cho phần đăng ký trả phí.*

**Scale:** 74 Swift files · ~13,400 lines · 33 commits · 3 Supabase Edge Functions · **one** third-party dependency.
***Quy mô:** 74 file Swift · ~13.400 dòng · 33 commit · 3 Supabase Edge Function · **một** thư viện bên thứ ba duy nhất.*

**App Store:** https://apps.apple.com/vn/app/memoryink-journal/id6770572153 · bundle `com.memoryink.app`

---

## The defining constraint: privacy / Ràng buộc cốt lõi: quyền riêng tư

This is the thing to lead with, because it shaped every other decision.
*Đây là điều nên nói đầu tiên, vì nó chi phối mọi quyết định còn lại.*

| Rule / Nguyên tắc | How it's enforced / Được đảm bảo bằng cách nào |
|---|---|
| **Photos never leave the device**<br>***Ảnh không bao giờ rời khỏi thiết bị*** | No upload path exists anywhere in the codebase. Core Data stores *file path strings*, never image blobs. Supabase Storage is not used for media at all.<br>*Trong toàn bộ mã nguồn không tồn tại đường upload nào. Core Data chỉ lưu **chuỗi đường dẫn file**, không lưu dữ liệu ảnh. Supabase Storage hoàn toàn không dùng cho media.* |
| **AI sees metadata only**<br>***AI chỉ thấy metadata*** | The narrative request carries vision labels, semantic tags, note text, mood, style, and locale. Never the image, never EXIF, never GPS.<br>*Request gửi đi chỉ chứa nhãn nhận diện ảnh, thẻ ngữ nghĩa, nội dung ghi chú, cảm xúc, phong cách và ngôn ngữ. Không bao giờ có ảnh, EXIF hay GPS.* |
| **No analytics**<br>***Không thu thập hành vi người dùng*** | `AnalyticsService.track()` is a deliberate no-op — the event taxonomy exists, the transmission doesn't. No Mixpanel, no Firebase, no SDK.<br>*`AnalyticsService.track()` cố tình để rỗng — có danh sách sự kiện nhưng không hề gửi đi đâu. Không Mixpanel, không Firebase, không SDK nào.* |
| **Export carries references, not content**<br>***Bản export chứa tham chiếu, không chứa nội dung*** | The backup file contains a photo's *file name* so a future import can re-link it — verified by test that the output has no image bytes, no directory structure, and no GPS/EXIF field.<br>*File sao lưu chỉ chứa **tên file** ảnh để sau này import có thể nối lại — đã kiểm chứng bằng test rằng đầu ra không có byte ảnh, không có cấu trúc thư mục, không có trường GPS/EXIF.* |
| **Widgets get a snapshot, not the journal**<br>***Widget chỉ nhận một bản snapshot, không nhận cả nhật ký*** | The widget process reads a small JSON + one thumbnail, never the Core Data store.<br>*Tiến trình widget chỉ đọc một file JSON nhỏ + một ảnh thumbnail, không bao giờ đọc kho Core Data.* |

> **If asked "how do you know?"** — the export rules are covered by 21 assertions that run against the real `ExportService.swift` and fail on any of `gps`, `latitude`, `longitude`, `exif`, or a directory separator appearing in the output.
> ***Nếu bị hỏi "làm sao bạn chắc chắn?"** — các quy tắc export được bảo vệ bởi 21 khẳng định (assertion) chạy trực tiếp trên file `ExportService.swift` thật, và sẽ fail nếu đầu ra xuất hiện bất kỳ chữ nào trong `gps`, `latitude`, `longitude`, `exif`, hoặc một dấu phân cách thư mục.*

---

## Architecture / Kiến trúc

```
┌─────────────────────────────────────────────────────────┐
│  SwiftUI Views  ·  Features/ (12 screens / 12 màn hình) │
├─────────────────────────────────────────────────────────┤
│  ViewModels  ·  lightweight, per-feature, @MainActor    │
│                 gọn nhẹ, theo từng tính năng            │
├─────────────────────────────────────────────────────────┤
│  Services/ (15)  ·  AI · Sync · Auth · Images · Export  │
│                     Slideshow · Notifications · Lock    │
├─────────────────────────────────────────────────────────┤
│  Persistence/  ·  Core Data = SOURCE OF TRUTH           │
│                   Core Data = NGUỒN DỮ LIỆU GỐC         │
│                   JournalEntryRepository (@Published)   │
├─────────────────────────────────────────────────────────┤
│  Files on disk  ·  /originals /thumbnails /medium /voice │
│  File trên đĩa                                          │
└─────────────────────────────────────────────────────────┘
        │                          │
        │ metadata only            │ snapshot file
        │ chỉ metadata             │ file snapshot
        ▼                          ▼
  Supabase Edge Functions    App Group container
  (AI proxy + delete)         → WidgetKit extension
```

**Stack:** iOS 16+ · SwiftUI · pragmatic MVVM · Core Data · Swift Concurrency (async/await) · WidgetKit · LocalAuthentication · AVFoundation · RevenueCat · Supabase Edge Functions (Deno/TS).
***Công nghệ sử dụng:** iOS 16+ · SwiftUI · MVVM thực dụng · Core Data · Swift Concurrency (async/await) · WidgetKit · LocalAuthentication · AVFoundation · RevenueCat · Supabase Edge Functions (Deno/TS).*

**Dependencies: exactly one.** RevenueCat, via SPM. Supabase is called with plain `URLSession` — no SDK.
***Thư viện ngoài: đúng một cái.** RevenueCat, cài qua SPM. Supabase được gọi bằng `URLSession` thuần — không dùng SDK.*

Everything else is a first-party Apple framework.
*Toàn bộ phần còn lại đều là framework chính chủ của Apple.*

This was deliberate: fewer dependencies means fewer supply-chain surprises, no version-lock on Apple releases, and nothing to strip out later.
*Đây là lựa chọn có chủ đích: ít thư viện ngoài đồng nghĩa ít rủi ro chuỗi cung ứng, không bị kẹt phiên bản mỗi khi Apple ra bản mới, và sau này không phải gỡ bỏ thứ gì.*

### Five decisions worth being able to defend / Năm quyết định bạn nên bảo vệ được

**1. Core Data is the source of truth; Supabase is a mirror.**
***1. Core Data là nguồn dữ liệu gốc; Supabase chỉ là bản sao.***

The app is fully functional offline and for users who never sign in. Sync is an *enhancement* for premium users, not the storage layer.
*App hoạt động đầy đủ khi offline và với cả người dùng không bao giờ đăng nhập. Đồng bộ chỉ là **tính năng cộng thêm** cho người dùng trả phí, không phải lớp lưu trữ chính.*

Consequence: a sync failure can never cost a user their journal — the worst case is that the cloud copy is stale.
*Hệ quả: lỗi đồng bộ không bao giờ làm mất nhật ký của người dùng — trường hợp xấu nhất chỉ là bản trên cloud bị cũ.*

**2. Save first, AI later.**
***2. Lưu trước, AI sau.***

The required flow is: user creates memory → **saved locally immediately** → AI request queued async → timeline updates softly when it lands.
*Luồng bắt buộc là: người dùng tạo kỷ niệm → **lưu ngay xuống máy** → xếp hàng gọi AI bất đồng bộ → timeline cập nhật nhẹ nhàng khi kết quả về.*

The user never waits on a network round-trip to keep a memory. Save latency target is <300ms; AI is allowed up to 10s because it's off the critical path.
*Người dùng không bao giờ phải chờ mạng để giữ lại một kỷ niệm. Mục tiêu độ trễ khi lưu là <300ms; AI được phép tới 10s vì nó nằm ngoài đường đi quan trọng.*

**3. Last-write-wins on `updated_at`, with a delete rule.**
***3. Ghi sau thắng, dựa trên `updated_at`, kèm một quy tắc cho xoá.***

Conflict resolution is intentionally simple — this is a single-user journal, not a collaborative document, so the complexity of CRDTs or merge UI would buy nothing.
*Cách xử lý xung đột cố tình đơn giản — đây là nhật ký một người dùng, không phải tài liệu cộng tác, nên sự phức tạp của CRDT hay giao diện gộp dữ liệu chẳng đem lại lợi ích gì.*

The one asymmetry: `deleted_at` beats a stale update, so a soft-deleted record can never be resurrected by an older client.
*Điểm bất đối xứng duy nhất: `deleted_at` thắng một bản cập nhật cũ, nên một bản ghi đã xoá mềm không bao giờ bị một client cũ làm sống lại.*

**4. Three image sizes, generated once on save.**
***4. Ba kích cỡ ảnh, sinh ra một lần lúc lưu.***

Original, thumbnail (500px), medium (1600px), plus an in-memory cache. The timeline *never* renders full resolution.
*Ảnh gốc, thumbnail (500px), ảnh vừa (1600px), cộng thêm cache trong bộ nhớ. Timeline **không bao giờ** hiển thị ảnh full độ phân giải.*

This is what keeps scrolling at 60fps with hundreds of photo cards.
*Đây chính là thứ giữ cho việc cuộn mượt 60fps dù có hàng trăm thẻ ảnh.*

**5. The AI never regenerates over an existing narrative.**
***5. AI không bao giờ viết đè lên một narrative đã có.***

If `aiNarrative` exists, it's kept. A user's memory shouldn't quietly change wording because they reopened a screen — and it also caps cost.
*Nếu `aiNarrative` đã tồn tại thì giữ nguyên. Kỷ niệm của người dùng không nên tự đổi câu chữ chỉ vì họ mở lại màn hình — và điều này cũng giới hạn chi phí.*

Regeneration is explicit, on edit or retry.
*Việc tạo lại phải là hành động rõ ràng: khi sửa nội dung hoặc khi bấm thử lại.*

---

## Feature inventory / Danh mục tính năng

### Capture / Ghi lại khoảnh khắc
- **Memory creation** — photo (library/camera) *or* a mood backdrop for photo-less entries, mood picker, optional note, optional voice path support.
  ***Tạo kỷ niệm** — ảnh (từ thư viện/máy ảnh) **hoặc** nền cảm xúc cho mục không có ảnh, bộ chọn cảm xúc, ghi chú tuỳ chọn, hỗ trợ sẵn đường dẫn ghi âm.*
- **Image pipeline** — original + 500px thumbnail + 1600px medium written on save, JPEG q0.82/0.86, cached in memory.
  ***Quy trình xử lý ảnh** — ghi ra ảnh gốc + thumbnail 500px + ảnh vừa 1600px ngay lúc lưu, JPEG chất lượng 0.82/0.86, có cache trong bộ nhớ.*
- **Offline-first save** — local write completes before anything else is attempted.
  ***Ưu tiên lưu offline** — ghi xuống máy xong xuôi rồi mới làm bất cứ việc gì khác.*

### AI
- **Narrative generation** — `POST /v1/narratives/generate` through a Supabase Edge Function so the OpenAI key never ships in the app.
  ***Sinh narrative** — gọi `POST /v1/narratives/generate` qua Supabase Edge Function, nhờ vậy khoá OpenAI không bao giờ nằm trong app.*
  15–40 words ideal, 60 max. Three styles (Warm, Minimal, Reflective) implemented as prompting only.
  *Lý tưởng 15–40 từ, tối đa 60. Ba phong cách (Ấm áp, Tối giản, Suy ngẫm) chỉ khác nhau ở prompt.*
  Responses carry a `cached` flag so the client can tell a cache hit from a fresh generation.
  *Phản hồi có cờ `cached` để client phân biệt kết quả lấy từ cache hay vừa sinh mới.*
- **Weekly recap** — `POST /v1/recaps/generate`, summarises the emotional week. Doesn't count against the daily narrative limit.
  ***Tổng kết tuần** — `POST /v1/recaps/generate`, tóm tắt một tuần cảm xúc. Không tính vào hạn mức narrative hằng ngày.*
- **Yearly review** — premium "Wrapped"-style annual retrospective with a thumbnail collage.
  ***Tổng kết năm** — bản nhìn lại cả năm kiểu "Wrapped" dành cho người dùng trả phí, kèm ảnh ghép thumbnail.*
- **Rate limiting** — 3/day free, 15 monthly, 30 yearly, tracked per-day in `AIUsageTracker`. Counted only on success (see BUGS §6).
  ***Giới hạn lượt dùng** — 3 lượt/ngày cho bản miễn phí, 15 cho gói tháng, 30 cho gói năm, đếm theo ngày trong `AIUsageTracker`. Chỉ tính khi thành công (xem BUGS §6).*

### Browse & resurface / Duyệt lại & gợi nhớ
- **Timeline** — list *or* grid layout (persisted), search over notes and narratives, mood filter, favourites filter, matched-geometry hero transition into detail.
  ***Timeline** — bố cục danh sách **hoặc** lưới (được ghi nhớ), tìm kiếm trong ghi chú và narrative, lọc theo cảm xúc, lọc yêu thích, hiệu ứng chuyển cảnh matched-geometry sang màn hình chi tiết.*
- **Card Browse** — full-screen Tinder-style swipe deck.
  ***Duyệt dạng thẻ** — chồng thẻ vuốt toàn màn hình kiểu Tinder.*
- **Memory Viewer** — full-screen photo pager.
  ***Trình xem kỷ niệm** — xem ảnh toàn màn hình, lật qua lại.*
- **Calendar** — month grid with a **mood-density heatmap** (five intensity steps by entries/day) and day/month filtering.
  ***Lịch** — lưới tháng với **bản đồ nhiệt theo mật độ cảm xúc** (năm mức đậm nhạt theo số mục/ngày) và lọc theo ngày/tháng.*
- **On This Day+** — same calendar date across past years, **grouped by year** with an "Across the years" comparison strip and a "Day N of MemoryInk" journey counter.
  ***Ngày này năm xưa+** — cùng một ngày qua các năm trước, **nhóm theo năm**, kèm dải so sánh "Across the years" và bộ đếm hành trình "Ngày thứ N cùng MemoryInk".*
- **Journey milestones** — 15 one-off moments: entry counts (10→500), days since the first memory (30/100/500/1000), anniversaries (1–5 years).
  ***Cột mốc hành trình** — 15 khoảnh khắc chỉ xuất hiện một lần: theo số kỷ niệm (10→500), theo số ngày từ kỷ niệm đầu tiên (30/100/500/1000), và các dịp kỷ niệm năm (1–5 năm).*
  Thresholds are `>=` so none can be missed, only the deepest shows when several land at once, and each fires exactly once, ever.
  *Ngưỡng dùng `>=` nên không bao giờ bị bỏ lỡ; nếu nhiều mốc đạt cùng lúc thì chỉ hiện mốc sâu nhất; và mỗi mốc chỉ hiện đúng một lần duy nhất.*
- **Surprise Me** — random memory.
  ***Surprise Me** — mở một kỷ niệm ngẫu nhiên.*

### Share & export / Chia sẻ & xuất dữ liệu
- **Share card** — a 1080×1080 image rendered on-device, with a live preview and **four themes** (Classic plus three gradient scenes).
  ***Thiệp chia sẻ** — ảnh 1080×1080 vẽ ngay trên máy, có xem trước trực tiếp và **bốn chủ đề** (Classic cùng ba cảnh gradient).*
  One shared component behind all four share entry points.
  *Cả bốn lối vào chia sẻ đều dùng chung một component duy nhất.*
- **Slideshow export** — AVFoundation video with per-mood audio and background scenes.
  ***Xuất slideshow** — video dựng bằng AVFoundation, có nhạc theo từng cảm xúc và cảnh nền.*
- **Local backup** — dated JSON export of notes, moods, narratives, and favourites, saved via the share sheet to Files. Free for everyone. Metadata only.
  ***Sao lưu cục bộ** — xuất file JSON có ghi ngày, gồm ghi chú, cảm xúc, narrative và mục yêu thích, lưu vào Files qua share sheet. Miễn phí cho tất cả. Chỉ có metadata.*

### Privacy & platform / Riêng tư & nền tảng
- **Face ID / Touch ID / passcode lock** — optional, off by default, locks on backgrounding, starts locked so the journal never flashes at launch.
  ***Khoá bằng Face ID / Touch ID / mật mã** — tuỳ chọn, mặc định tắt, tự khoá khi chuyển app xuống nền, và khởi động ở trạng thái khoá để nhật ký không bao giờ loé lên lúc mở app.*
- **Home & Lock Screen widgets** — small, medium, circular, rectangular. Fed by a snapshot file in a shared App Group container.
  ***Widget màn hình chính & màn hình khoá** — cỡ nhỏ, vừa, tròn, chữ nhật. Lấy dữ liệu từ file snapshot trong App Group dùng chung.*
- **Daily reminder + On This Day notifications** — local, via `UNUserNotificationCenter`.
  ***Nhắc nhở hằng ngày + thông báo Ngày này năm xưa** — thông báo cục bộ qua `UNUserNotificationCenter`.*
- **Dark mode** — a full adaptive palette, not a tint swap.
  ***Chế độ tối** — một bảng màu thích ứng đầy đủ, không phải chỉ đổi màu nhấn.*

### Account & monetization / Tài khoản & doanh thu
- **Sign in with Apple + email** (no verification in V1). Free users never need an account.
  ***Đăng nhập bằng Apple + email** (V1 không cần xác thực email). Người dùng miễn phí không cần tài khoản.*
- **Metadata-only sync** for premium users; last-write-wins.
  ***Đồng bộ chỉ metadata** cho người dùng trả phí; áp dụng quy tắc ghi sau thắng.*
- **Account deletion** via an authenticated Edge Function (see BUGS §7).
  ***Xoá tài khoản** qua Edge Function có xác thực (xem BUGS §7).*
- **Paywall** appears only *after* a first emotional moment — never on launch.
  ***Màn hình trả phí** chỉ xuất hiện **sau** khoảnh khắc cảm xúc đầu tiên — không bao giờ hiện ngay khi mở app.*

| Plan / Gói | Price / Giá | AI narratives/day / Lượt AI mỗi ngày |
|---|---|---|
| Free / *Miễn phí* | — | 3 |
| Monthly / *Theo tháng* | $5.99/mo | 15 |
| Yearly / *Theo năm* | $39.99/yr | 30 |

RevenueCat, one entitlement (`premium`), products `memoryink_monthly` / `memoryink_yearly`, 7-day free trial.
*Dùng RevenueCat, một quyền lợi duy nhất (`premium`), hai sản phẩm `memoryink_monthly` / `memoryink_yearly`, dùng thử miễn phí 7 ngày.*

Premium unlocks cloud sync, higher AI limits, voice journaling, premium recap styles.
*Gói trả phí mở khoá đồng bộ đám mây, hạn mức AI cao hơn, nhật ký bằng giọng nói, và các phong cách tổng kết cao cấp.*

---

## Delivery history / Lịch sử phát triển

| When / Thời gian | What / Nội dung |
|---|---|
| **2026-05-18** | **Phase 0** — timeline UI prototype. **Phase 1** — local MVP: capture, Core Data, image pipeline. **Phase 2** — AI integration behind Supabase Edge Functions.<br>***Giai đoạn 0** — dựng nguyên mẫu giao diện timeline. **Giai đoạn 1** — MVP chạy cục bộ: tạo kỷ niệm, Core Data, xử lý ảnh. **Giai đoạn 2** — tích hợp AI qua Supabase Edge Functions.* |
| **2026-05-19** | **Phase 3** — RevenueCat integration; Supabase auth + metadata sync wired and hardened.<br>***Giai đoạn 3** — tích hợp RevenueCat; đấu nối và làm chắc phần xác thực Supabase + đồng bộ metadata.* |
| **2026-05-21** | **V1.1 feature wave** — edit/delete, search, reminders, mood filters, grid toggle, share card, Surprise Me, milestones, dark mode, Yearly Review, Calendar. Then Memory Viewer, Recap redesign, Browse Mode, Background Scenes, and the overflow/gesture fixes.<br>***Đợt tính năng V1.1** — sửa/xoá, tìm kiếm, nhắc nhở, lọc cảm xúc, chuyển lưới, thiệp chia sẻ, Surprise Me, cột mốc, chế độ tối, Tổng kết năm, Lịch. Sau đó là Trình xem kỷ niệm, thiết kế lại Recap, chế độ Browse, Cảnh nền, và các bản sửa lỗi tràn/cử chỉ.* |
| **2026-05-23** | Slideshow video export. iPad + iPhone SE adaptivity (three rounds). App Store submission fixes. **Shipped to the App Store.**<br>*Xuất video slideshow. Thích ứng iPad + iPhone SE (ba đợt). Sửa lỗi để nộp App Store. **Phát hành lên App Store.*** |
| **2026-07-11** | UI revitalisation + hardened account lifecycle (Edge Function deletion).<br>*Làm mới giao diện + siết chặt vòng đời tài khoản (xoá qua Edge Function).* |
| **2026-08-18** | **v2 Milestone 1 / Part A — visual refresh (9/9).** Design-system consolidation: one ambient backdrop everywhere, a shared hero header, a spacing/radius scale, a bundled display serif (Spectral, SIL OFL), the matched-geometry hero transition activated, an app-wide haptics sweep, four weakest screens redesigned, and duplicated chart + swipe-gesture code extracted into shared components.<br>***v2 Mốc 1 / Phần A — làm mới giao diện (9/9).** Hợp nhất hệ thống thiết kế: dùng chung một nền gradient ở mọi màn hình, một hero header dùng chung, thang khoảng cách/bo góc, nhúng font serif hiển thị (Spectral, giấy phép SIL OFL), kích hoạt hiệu ứng matched-geometry, rà soát phản hồi rung toàn app, thiết kế lại bốn màn hình yếu nhất, và tách code biểu đồ + cử chỉ vuốt bị trùng lặp thành component dùng chung.* |
| **2026-08-19** | **v2 Milestone 2 / Part B — new features (6/6).** On This Day+ & journey milestones · share card themes · local export · calendar heatmap · Face ID lock · Home/Lock Screen widgets.<br>***v2 Mốc 2 / Phần B — tính năng mới (6/6).** Ngày này năm xưa+ & cột mốc hành trình · chủ đề thiệp chia sẻ · xuất dữ liệu cục bộ · bản đồ nhiệt lịch · khoá Face ID · widget màn hình chính/khoá.* |

### How the v2 upgrade was scoped / Phạm vi bản nâng cấp v2 được xác định ra sao

It started as a research pass against a reference app (*Memories: My Love Days Counter*).
*Bắt đầu bằng một đợt nghiên cứu đối chiếu với một app tham khảo (*Memories: My Love Days Counter*).*

The finding that shaped everything: **MemoryInk's design system already existed but was applied to only 3 of ~12 screens.**
*Phát hiện quyết định mọi thứ: **hệ thống thiết kế của MemoryInk đã có sẵn, nhưng chỉ được áp dụng cho 3 trong khoảng 12 màn hình.***

So Part A was consolidation, not invention — the highest-impact work was making existing components universal.
*Vì vậy Phần A là hợp nhất, không phải sáng tạo mới — việc tạo tác động lớn nhất là đưa các component sẵn có ra dùng ở mọi nơi.*

Equally important was what got *excluded*.
*Điều quan trọng không kém là những gì đã bị **loại bỏ**.*

The reference app's real hook is couple-focused: a shared space, virtual pets, coins, in-app messaging.
*Điểm hút chính của app tham khảo là dành cho các cặp đôi: không gian chung, thú ảo, tiền xu, nhắn tin trong app.*

All of it was rejected as social/gamified — it conflicts with the product identity (*calm · private · personal*) and with explicit bans in the project's own rulebook.
*Tất cả đều bị loại vì mang tính mạng xã hội/game hoá — trái với bản sắc sản phẩm (**tĩnh lặng · riêng tư · cá nhân**) và trái với những điều cấm ghi rõ trong bộ quy tắc của dự án.*

What carried over were **idea categories** — day counters, widgets, a private lock, shareable cards, backup — reinterpreted for a solo journal.
*Thứ được giữ lại là **các nhóm ý tưởng** — bộ đếm ngày, widget, khoá riêng tư, thiệp chia sẻ, sao lưu — được diễn giải lại cho một cuốn nhật ký cá nhân.*

> Worth saying in an interview: the milestone system is explicitly **not a streak**.
> *Đáng nói khi phỏng vấn: hệ thống cột mốc **không phải** là chuỗi ngày liên tiếp (streak).*
> Streaks punish you for missing a day; these are anniversaries measured from your first memory — nothing resets, nothing breaks, nothing is scored.
> *Streak trừng phạt bạn khi bỏ lỡ một ngày; còn đây là các dịp kỷ niệm tính từ kỷ niệm đầu tiên — không có gì bị reset, không có gì bị đứt, không có điểm số nào.*
> That distinction is a product decision, not a technical one.
> *Sự phân biệt đó là quyết định về sản phẩm, không phải về kỹ thuật.*

---

## Notable engineering problems solved / Những bài toán kỹ thuật đáng chú ý

**Shipping a WidgetKit extension without the Xcode GUI.**
***Thêm một extension WidgetKit mà không có giao diện Xcode.***

The widget target — build phases, build configurations, target dependency, container proxy, and the app's Embed Extensions phase — was written directly into `project.pbxproj`, then verified by checking the target list, each target's compiled file list, and that the `.appex` was embedded at `MemoryInk.app/PlugIns/` with the right extension point.
*Toàn bộ target widget — các giai đoạn build, cấu hình build, phụ thuộc target, container proxy, và giai đoạn nhúng extension của app — được viết thẳng vào `project.pbxproj`, sau đó kiểm chứng bằng cách xem danh sách target, danh sách file được biên dịch của từng target, và xác nhận file `.appex` đã nằm trong `MemoryInk.app/PlugIns/` với đúng điểm mở rộng.*

**Choosing a widget data path.**
***Chọn cách đưa dữ liệu cho widget.***

Two options: move the Core Data store into the App Group container (one live store, but every existing user's journal has to be migrated) or mirror a small snapshot file (no migration, slightly stale).
*Có hai phương án: chuyển kho Core Data vào App Group (một kho dữ liệu sống, nhưng phải migrate nhật ký của mọi người dùng hiện có) hoặc tạo một file snapshot nhỏ (không cần migrate, dữ liệu hơi cũ một chút).*

The snapshot won — the widget only needs a mood, a thumbnail, and a day count, so the migration risk bought nothing. **The store never moves.**
*Phương án snapshot thắng — widget chỉ cần một cảm xúc, một thumbnail và một số ngày, nên rủi ro migrate chẳng đổi lại được gì. **Kho dữ liệu không hề bị di chuyển.***

**Verifying privacy without a test target.**
***Kiểm chứng quyền riêng tư mà không có target test.***

`MilestoneService` and `ExportService` depend only on Foundation, so they compile standalone against stub models — 37 assertions total, run against the real source files, covering the export's privacy guarantees and the milestone state machine (fires-once, legacy key compatibility, clock skew).
*`MilestoneService` và `ExportService` chỉ phụ thuộc Foundation, nên có thể biên dịch độc lập cùng các model giả — tổng cộng 37 khẳng định, chạy trên chính file nguồn thật, bao phủ các cam kết riêng tư của tính năng export và máy trạng thái của cột mốc (chỉ hiện một lần, tương thích khoá cũ, lệch đồng hồ).*

**One share component instead of four.**
***Một component chia sẻ thay vì bốn.***

The share card was being constructed at four separate call sites with slightly different inputs.
*Thiệp chia sẻ trước đây được dựng ở bốn nơi khác nhau với dữ liệu đầu vào hơi lệch nhau.*

Adding themes was the moment to collapse them into a single component, so the preview and theme choice are identical everywhere.
*Lúc thêm chủ đề chính là thời điểm hợp nhất chúng lại thành một component duy nhất, để phần xem trước và chọn chủ đề giống hệt nhau ở mọi nơi.*

---

## Questions you're likely to be asked / Những câu hỏi bạn dễ bị hỏi

**"How does the AI work if photos never leave the device?"**
***"AI hoạt động kiểu gì nếu ảnh không bao giờ rời khỏi máy?"***

On-device Vision produces labels and semantic tags; those plus the note text, mood, and style go to a Supabase Edge Function, which calls OpenAI.
*Framework Vision chạy ngay trên máy để sinh ra nhãn và thẻ ngữ nghĩa; những thứ đó cùng nội dung ghi chú, cảm xúc và phong cách được gửi tới một Supabase Edge Function, và hàm này mới gọi OpenAI.*

The proxy exists so the API key never ships in the binary. The image itself is never in the payload.
*Lớp trung gian tồn tại để khoá API không bao giờ nằm trong file app. Bản thân tấm ảnh không bao giờ có trong dữ liệu gửi đi.*

**"Why Core Data instead of just syncing everything to the server?"**
***"Tại sao dùng Core Data thay vì đồng bộ hết mọi thứ lên server?"***

Because the app has to work fully offline and for users who never create an account, and because a journal is the kind of data where a sync bug losing entries would be unforgivable.
*Vì app phải chạy đầy đủ khi offline và cho cả người dùng không bao giờ tạo tài khoản; và vì nhật ký là loại dữ liệu mà một lỗi đồng bộ làm mất bài viết là điều không thể tha thứ.*

The server is a convenience mirror; the device is the truth.
*Server chỉ là bản sao cho tiện; thiết bị mới là nguồn sự thật.*

**"How do you handle sync conflicts?"**
***"Bạn xử lý xung đột đồng bộ thế nào?"***

Last-write-wins on `updated_at`, with `deleted_at` beating stale updates.
*Ghi sau thắng dựa trên `updated_at`, và `deleted_at` thắng các bản cập nhật cũ.*

For a single-user journal that's the right complexity level — anything more sophisticated would be solving a problem the product doesn't have.
*Với nhật ký một người dùng thì đó là mức phức tạp hợp lý — làm gì tinh vi hơn là đang giải một bài toán mà sản phẩm không hề có.*

**"What was the hardest bug?"**
***"Lỗi khó nhất là lỗi nào?"***

See BUGS §1 (SwiftUI layout proposals) for a technical answer, §6 (AI rate limit) for a reasoning-about-failure answer, or §9.1 (the verification method was lying) for a process answer.
*Xem BUGS §1 (cơ chế đề xuất kích thước của SwiftUI) cho câu trả lời thiên kỹ thuật, §6 (giới hạn AI) cho câu trả lời về tư duy xử lý lỗi, hoặc §9.1 (cách kiểm thử nói dối) cho câu trả lời về quy trình.*

**"What would you do next?"**
***"Tiếp theo bạn sẽ làm gì?"***

Voice journaling and CloudKit are the two features consciously deferred.
*Nhật ký bằng giọng nói và CloudKit là hai tính năng được cố ý hoãn lại.*

Nearer term: a real test target — the highest-risk logic is currently verified by standalone assertions, which works but doesn't run in CI.
*Gần hơn: dựng một target test thật — phần logic rủi ro cao nhất hiện được kiểm chứng bằng các assertion độc lập, cách này chạy được nhưng không chạy trong CI.*

**"What's the weakest part of the codebase?"**
***"Phần yếu nhất của codebase là gì?"***

Test coverage. Verification leans on real builds plus targeted assertions against Foundation-only services; the SwiftUI layer is verified by hand on a device.
*Độ phủ test. Việc kiểm chứng dựa vào build thật cộng với các assertion nhắm vào những service chỉ phụ thuộc Foundation; còn lớp SwiftUI thì kiểm tra thủ công trên máy thật.*

That's a deliberate trade for a solo project at this stage, not something to defend as ideal.
*Đó là đánh đổi có chủ đích cho một dự án cá nhân ở giai đoạn này, không phải điều nên bảo vệ như một chuẩn mực lý tưởng.*
