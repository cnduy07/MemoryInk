# MemoryInk — Chuẩn bị phỏng vấn

> Câu trả lời cho những câu hỏi **về bạn**, không phải về code: tại sao bạn làm app này, bạn học
> được gì, và bạn học được gì khi dùng AI để làm nó.
>
> Bản tiếng Anh: [`INTERVIEW_PREP.md`](INTERVIEW_PREP.md)
> Chi tiết kỹ thuật: [`FEATURES_AND_TASKS.vi.md`](FEATURES_AND_TASKS.vi.md) ·
> [`BUGS_AND_FIXES.vi.md`](BUGS_AND_FIXES.vi.md)
>
> **Cập nhật lần cuối:** 20/08/2026

---

## Dùng file này thế nào

Hai tài liệu kia nói về **dự án là gì**. File này nói về **bạn là ai** — và đó mới là thứ quyết định
kết quả phỏng vấn một khi bạn đã qua được ngưỡng kỹ thuật.

**Một nguyên tắc trước tiên: đừng học thuộc lòng như kịch bản.** Một câu trả lời học thuộc nghe ra
được ngay, và nó sụp đổ ngay ở câu hỏi đào sâu đầu tiên. Hãy học **bằng chứng** phía sau mỗi câu trả
lời — đúng cái lỗi đó, đúng con số đó, đúng quyết định đó — rồi để câu chữ mỗi lần bật ra một khác.
Bằng chứng thì trụ được khi bị vặn; câu chữ thì không.

**Chỗ nào có 🔵 là chỗ chỉ mình bạn điền được.** Đó là sự thật về đời bạn và động cơ của bạn. Nếu bạn
đọc thuộc một điều không có thật ở đó, người phỏng vấn chỉ cần hỏi thêm hai câu là chạm tới rìa của
nó, và mọi thứ khác bạn nói đều trở nên đáng ngờ.

---

## 1. "Tại sao bạn làm app này?"

### Vì sao họ hỏi câu này

Nó gần như không phải hỏi về app. Người phỏng vấn dùng câu này để biết: bạn làm ra thứ gì đó vì bạn
**muốn nó tồn tại**, hay vì một bài hướng dẫn bảo bạn làm? Bạn có nhận ra được vấn đề đáng giải
không? Bạn có ra quyết định, hay chỉ chấp nhận mặc định?

Câu trả lời yếu là "em muốn luyện SwiftUI". Nó ngụ ý app chỉ là phương tiện làm đẹp CV. Câu trả lời
mạnh nêu được một vấn đề thật, một người dùng thật, và một quyết định bạn đưa ra vì điều đó.

### Cấu trúc của một câu trả lời mạnh

1. **Quan sát** — điều bạn nhận thấy về cách người ta (hoặc chính bạn) thực sự hành xử
2. **Khoảng trống** — vì sao các lựa chọn hiện có không đáp ứng được
3. **Một ràng buộc bạn nhất quyết không nhượng bộ** — đây là phần khiến nó là **của bạn**
4. **Cái giá bạn đã trả** — bằng chứng cho thấy ràng buộc đó là thật, không phải trang trí

Phần thứ tư là phần đa số ứng viên bỏ quên. Ai cũng tuyên bố được một nguyên tắc. Chứng minh rằng
nguyên tắc đó đã **loại bỏ bớt lựa chọn** mới là thứ khiến nó đáng tin.

### 🔵 Điền vào: lý do thật của bạn

Hãy viết hai ba câu trung thực bằng lời của chính bạn. Vài gợi ý nếu bạn cần:

- Bạn có hay giữ những tấm ảnh mà chẳng bao giờ mở lại không? Điều đó có làm bạn bận lòng?
- Bạn từng thử vài app nhật ký rồi bỏ? Cái gì khiến bạn bỏ?
- Có ai cụ thể bạn hình dung sẽ dùng nó — chính bạn, người thân, một người bạn?
- Có một khoảnh khắc nào khiến bạn bắt tay vào làm, hay nó tích tụ dần?

> **Câu trả lời của bạn:**
>
> _______________________________________________
>
> _______________________________________________

Dù bạn viết gì, nó nên nói được trong khoảng hai mươi giây và phải **thật**. Đừng thổi phồng. "Em
chụp rất nhiều ảnh nhưng chẳng bao giờ xem lại, và những tấm em có xem lại thì em cũng không nhớ nổi
hôm đó cảm giác thế nào" là một lý do hoàn toàn đủ. Nó không cần phải là một bi kịch.

### Chất liệu mà codebase thật sự chứng minh được

Tất cả những điều dưới đây đều bảo vệ được, vì code chứng minh chúng. Dùng cái nào khớp với động cơ
thật của bạn.

**Sản phẩm được định nghĩa bằng một sự từ chối, không phải bằng một tính năng.** Câu *"ảnh không bao
giờ rời khỏi thiết bị"* là một câu **loại bỏ** lựa chọn chứ không thêm vào. Đó là lý do AI làm việc
trên nhãn Vision thay vì trên ảnh, lý do phải có lớp Edge Function trung gian, lý do widget đọc
snapshot thay vì đọc database, và lý do bản export chứa tên file chứ không chứa ảnh. Một ràng buộc,
năm hệ quả thiết kế không liên quan nhau — đó là thứ phân biệt một nguyên tắc với một khẩu hiệu.

**Bạn đã nói không với đúng thứ có thể giúp app tăng trưởng.** Khi lên kế hoạch v2, có một app tham
khảo được nghiên cứu, và app đó giữ chân người dùng bằng các tính năng xã hội cho cặp đôi: không gian
chung, thú ảo, tiền xu, nhắn tin trong app. Tất cả đều bị loại vì mang tính game hoá và mạng xã hội,
trái với mục đích của sản phẩm. Đó là một đánh đổi thật — những cơ chế đó **được biết là** làm tăng
tỷ lệ giữ chân. Chủ động chọn từ bỏ chúng là một phán đoán về sản phẩm, và người phỏng vấn để ý điều
đó.

**Cột mốc dứt khoát không phải là streak.** Streak trừng phạt bạn khi bỏ lỡ một ngày. Cột mốc của
MemoryInk là các dịp kỷ niệm tính từ kỷ niệm đầu tiên — không có gì bị reset, không có gì bị đứt,
không có điểm số nào. Nếu mục đích là làm người ta thấy bình yên với quá khứ của chính mình, thì một
cơ chế khiến họ thấy có lỗi không phải là tính năng, mà là một sự mâu thuẫn.

**Không có SDK phân tích hành vi nào.** `AnalyticsService.track()` cố tình để rỗng: danh sách sự kiện
có sẵn để code sẵn sàng, nhưng không có gì được gửi đi. Với một app nhật ký, chính **nội dung** mới
là thứ riêng tư.

> **Nếu người phỏng vấn vặn: "vậy có hại cho kinh doanh không?"** — hãy xem đó là câu hỏi nghiêm túc
> thay vì phòng thủ. Câu trả lời trung thực là: đúng, đó là cái giá thật và được chấp nhận có chủ ý.
> Không có analytics thì bạn không thấy người dùng rơi rụng ở đâu; không có cơ chế xã hội thì bạn
> tăng trưởng chậm hơn. Đánh cược ở đây là: một sản phẩm mà người ta tin tưởng giao phó kỷ niệm riêng
> tư thì giá trị hơn một sản phẩm bị gỡ đi sau khi hết mới lạ. Cược đó có thắng hay không vẫn là câu
> hỏi mở — nói thẳng như vậy mạnh hơn nhiều so với việc giả vờ không có đánh đổi nào.

---

## 2. "Bạn học được gì khi làm app này?"

Hãy nói **hai hoặc ba** ý, kèm bằng chứng cụ thể. Đừng nói hết — kể một danh sách nghe như học
thuộc, còn đi sâu nghe như thật.

### 2.1 Framework có "hợp đồng", không chỉ có API

Lỗi `matchedGeometryEffect` (BUGS §9.4) là ví dụ rõ nhất. API biên dịch được, tham số đúng hết, mà
kết quả sai hoàn toàn — vì hiệu ứng đó giả định tại mỗi thời điểm chỉ có đúng một view nguồn còn
sống, trong khi lớp phủ của app vẫn giữ nguyên Timeline ở bên dưới.

**Điều này đổi cách bạn làm việc:** trước khi dùng một API hoạt ảnh hay layout, hãy hỏi nó **giả định
gì về cây view của bạn**, chứ không chỉ hỏi nó nhận tham số gì. Chữ ký hàm cho bạn biết cách gọi;
"hợp đồng" mới cho bạn biết nó có chạy được không.

### 2.2 Hệ thống layout là một cuộc thương lượng

Lỗi tràn ngang (BUGS §1) nhìn như lỗi styling nhưng không phải. SwiftUI đề xuất kích thước cho từng
view con rồi hỏi nó muốn bao nhiêu; một đề xuất không giới hạn gặp `scaledToFill`, và hàm này trả lời
bằng kích thước gốc của ảnh — mà **`scaledToFill` chỉ phóng to chứ không cắt.**

**Điều này đổi cách bạn làm việc:** khi một thứ sai kích thước, câu hỏi không bao giờ là "padding nào
sai" mà là "ai đã đề xuất một chiều không giới hạn, và view con nào đã trả lời bằng kích thước gốc?"

### 2.3 Đếm kết quả, đừng đếm lần thử

Lỗi giới hạn AI (BUGS §6) trừ tiền lượt của người dùng cho những lần tạo narrative **thất bại**. Chỉ
dời một dòng, từ trước lệnh gọi mạng xuống sau nó.

**Điều này đổi cách bạn làm việc:** mọi bộ đếm gắn với thứ người dùng đã trả tiền đều phải nằm trên
nhánh thành công. Rộng hơn — khi bạn viết một giới hạn, hãy hỏi chuyện gì xảy ra khi thứ bị giới hạn
đó **thất bại**.

### 2.4 Đừng bao giờ báo "đã xong" một cách lạc quan với thao tác huỷ dữ liệu

Nút "Delete Account" báo thành công trong khi tài khoản vẫn còn (BUGS §7), vì client gọi một endpoint
không thể chạy được từ phía client, rồi coi "không có lỗi" là "đã xong".

**Điều này đổi cách bạn làm việc:** hai thói quen. Thao tác có đặc quyền phải nằm ở server nắm giữ
đặc quyền. Và "không lỗi" không phải là "thành công" — hãy xác nhận kết quả, nhất là khi người dùng
tin rằng một điều không thể hoàn tác vừa xảy ra.

### 2.5 Kiểm tra sản phẩm thật, đừng kiểm tra thứ thay thế nó

Một task được báo hoàn thành sau khi qua vòng kiểm tra kiểu dữ liệu. Bản build thật ngay sau đó thất
bại lập tức, vì file mới chưa hề được thêm vào target Xcode (BUGS §9.1). Phép kiểm tra và sản phẩm
đang nhìn vào hai tập file khác nhau.

**Điều này đổi cách bạn làm việc:** chuẩn kiểm chứng trở thành chạy `xcodebuild` thật, mọi lần. Và
một thói quen rộng hơn — thỉnh thoảng hãy tự hỏi **cách kiểm tra** của mình có thể sai không, bởi mọi
thứ nằm sau một phép kiểm tra hỏng đều coi như chưa được kiểm chứng, kể cả những phần đã "pass".

### 2.6 Tính chất nào tính được thì hãy tính

Độ tương phản được chỉnh bằng mắt ba lần, qua được vòng nhìn ba lần, và trượt phép tính ba lần: 4,23
rồi 4,25 rồi 4,28 so với ngưỡng 4,5 (BUGS §10.5). Mỗi vòng đều đo trên nền tiêu chuẩn, trong khi
trường hợp xấu nhất lại nằm ở một bề mặt hoàn toàn khác.

**Điều này đổi cách bạn làm việc:** các ràng buộc về khả năng tiếp cận, layout và hiệu năng rất hay là
số học. Khi một tính chất đúng đắn có thể tính được, hãy tính nó — và đặt phép tính vào chỗ nó sẽ tự
chạy lại, vì nếu không nó sẽ hỏng lại trong im lặng.

### 2.7 Đo đạc biến một nhiệm vụ vô hạn thành một nhiệm vụ có giới hạn

"Giao diện nhìn không đẹp" là câu không hành động được. Việc đếm đã làm nó hành động được: 484 chỗ
tham chiếu màu, riêng `amber` dùng 43 lần, chín màu nhấn khác chia nhau 62 lần. **App vốn đã có một
màu nhấn chủ đạo mà chưa bao giờ dứt khoát chọn nó.**

Điều đó biến một nghi ngờ "phải viết lại 18 màn hình" thành "sửa một file cộng một đợt rà soát".

**Điều này đổi cách bạn làm việc:** khi một nhiệm vụ có vẻ vô hạn, hãy tìm thứ gì đếm được trong nó
trước khi bắt đầu.

### 2.8 Phát hành là một kỹ năng riêng, khác với xây dựng

Ba lần bị App Store từ chối (BUGS §3) đều là lỗi cấu hình: icon có kênh alpha, thiếu khai báo hướng
xoay cho iPad, chuỗi mô tả quyền riêng tư sai định dạng. Không lỗi nào lộ ra khi đang phát triển, và
mỗi lỗi tốn trọn một vòng archive-và-upload mới phát hiện được.

**Điều này đổi cách bạn làm việc:** mọi thứ mà trình biên dịch không kiểm tra được và simulator không
cho bạn thấy đều cần một checklist viết ra giấy, không phải cần "cẩn thận hơn".

---

## 3. "Bạn học được gì khi dùng AI để làm app này?"

Đây là câu có tiềm năng ăn điểm nhất hiện nay, vì đa số ứng viên trả lời dở — hoặc phòng thủ ("em chỉ
dùng cho phần code lặp lại"), hoặc ngây thơ ("nó như có một senior ngồi cạnh"). Bạn có bằng chứng
thật để trả lời hay hơn thế.

### Bản một câu

> **AI đã dời nút thắt từ chỗ viết code sang chỗ kiểm chứng code — và phần lớn thứ tôi học được là
> cách xây dựng việc kiểm chứng đủ vững trước những kết quả tự tin, hợp lý, nhưng sai.**

### 3.1 Kiểu lỗi không phải là code tệ. Mà là code **trông rất hợp lý**

Cụm lỗi ở Phần C chính là toàn bộ luận điểm. Lỗi nào cũng biên dịch được, qua được review, và chạy
được:

- `UIColor(Color).resolvedColor(with:)` — nhìn như đang ghim màu khi xuất ảnh vào một chế độ cố định.
  Thực ra nó âm thầm không làm gì cả, vì phép chuyển đổi đã làm phẳng màu động trước đó. Một tấm
  thiệp chia sẻ sẽ đi theo đúng chế độ sáng/tối mà máy người gửi tình cờ đang dùng.
- `Font.custom("Spectral-Regular")` — sẽ xoá sổ font serif khỏi mọi màn hình của app, vì
  `Font.custom` **âm thầm** quay về font hệ thống khi không tìm thấy tên font. Build xanh. Test pass.
  Không cảnh báo.

**Bài học:** hồ sơ rủi ro đã thay đổi. Code tệ theo kiểu truyền thống thì hỏng ầm ĩ — nó crash, nó
không biên dịch, nó ném lỗi. Code có AI hỗ trợ thường hỏng **trong im lặng**, vì nó đúng về mặt khuôn
mẫu. Nó trông y hệt đoạn code chạy đúng.

Nghĩa là "nó biên dịch được và nhìn đúng" không còn là bằng chứng cho bất cứ điều gì, và tôi phải
thay nó bằng phép đo.

### 3.2 Kế hoạch cũng sai một cách rất tự tin, và cách sửa là bằng chứng chứ không phải tranh luận

Kế hoạch Phần C — do chính tôi viết và duyệt trước khi làm — có hai lỗi:

1. *"Xoá chín màu nhấn thừa."* Chúng chính là hệ thống cảm xúc. `MoodType` gán sáu màu trong đó cho
   sáu cảm xúc; `rosewood` còn là màu cho hành động huỷ và `sage` là màu báo thành công. Xoá chúng đi
   là xoá luôn cái tính năng mà một bước sau đó có nhiệm vụ giữ lại.
2. *"Giữ các màu cố định để ảnh xuất ra luôn nhất quán."* Bất khả thi về mặt số học. Để đạt chuẩn AA
   trên nền gần đen, màu cần độ sáng ≥ 0,195; trên nền trắng thì ≤ 0,161. Hai khoảng không giao nhau.

Không lỗi nào được phát hiện bằng cách đọc lại kế hoạch. Cả hai đều được phát hiện bằng cách **đối
chiếu với codebase thật và với phép tính thật.**

**Bài học:** một kế hoạch tự tin không phải là một kế hoạch đã được kiểm chứng. Trước khi thực thi,
hãy kiểm tra các tuyên bố của nó ngay trên repo — grep xem thứ nó bảo là "không dùng nữa" có thật
không, tính xem thứ nó bảo là làm được có thật sự làm được không.

### 3.3 Hãy ghi các ràng buộc ra giấy, vì ngữ cảnh không tự tồn tại mãi

Dự án có một bộ quy tắc (`AGENTS.md`) ghi rõ những điều không bao giờ được đổi: ảnh không bao giờ rời
khỏi thiết bị, không có SDK phân tích hành vi, giá và ID quyền lợi phải được duyệt tường minh, không
làm tính năng thuộc giai đoạn sau.

Bộ quy tắc này tồn tại vì một phiên làm việc với AI không hề nhớ lập luận của hôm qua. Những ràng
buộc chỉ nằm trong đầu bạn sẽ bị phiên sau vi phạm một cách lặng lẽ, và phiên đó sẽ tạo ra thứ trông
rất hợp lý nhưng phá vỡ một quy tắc mà không ai nhắc lại.

Ví dụ cụ thể: khi Phần C đổi bảng màu, bộ quy tắc vẫn còn ghi *"Màu: trung tính ấm, tông phim"*. Dòng
đó đã được cập nhật **và quy tắc cũ được ghi lại là "đã bị thay thế" chứ không bị xoá đi**, để một
phiên sau này không thể khôi phục bảng màu cũ từ một tài liệu cũ rồi tưởng mình đang sửa lỗi hồi quy.

**Bài học:** khi có AI trong quy trình, ràng buộc không được ghi lại thì không phải là ràng buộc.
Viết quy tắc ra giấy là một phần của việc thực thi nó.

### 3.4 Đặc tả trước khi sinh code, nếu không phạm vi sẽ trôi

Mọi task đều bắt đầu bằng một bản đặc tả viết ra: nêu đích danh những file sẽ đụng tới, tiêu chí
thành công dạng đúng/sai, và mọi thứ cần phê duyệt đều được nêu **trước khi** viết code.

Không có nó, kiểu hỏng tự nhiên là một task cứ âm thầm phình ra — bạn xin sửa một lỗi và nhận về một
đợt refactor ba file lân cận, tất cả đều hợp lý, và không phần nào được yêu cầu.

**Bài học:** bản đặc tả là nơi bạn thể hiện phán đoán. Sinh code thì rẻ; quyết định **cái gì nên tồn
tại** thì không.

### 3.5 Khi việc thực thi rẻ đi, thứ đáng làm cũng thay đổi

Bộ test độ tương phản kiểm tra từng vai trò chữ trên từng bề mặt ở cả hai chế độ, cộng thêm ngưỡng
cho các màu, thứ tự thang nền, tính nhất quán khi xuất ảnh, và một chốt chặn khẳng định rằng màu
trắng thuần **sẽ** trượt chuẩn. Làm tay thì việc này đủ nhàm để hầu hết dự án chỉ kiểm vài màu rồi
thôi.

**Bài học:** khi việc thực thi rẻ đi, lượng kiểm chứng hợp lý phải **tăng lên**, không phải giảm đi.
Kết luận dễ rơi vào là "giờ mình làm được nhiều tính năng hơn". Kết luận hữu ích hơn là "giờ mình đủ
sức làm những thứ chỉn chu mà trước đây không khả thi".

### 3.6 Những gì AI không làm được, và điều đó làm sáng tỏ điều gì

Nên nói chính xác ở phần này, vì đây là phần thể hiện phán đoán:

- **Nó không biết app có "tĩnh" hay không.** Độ tương phản là số học và đã được chứng minh. Còn kết
  quả có ra đúng cái cảm giác mà sản phẩm cần hay không thì phải có người nhìn vào màn hình.
- **Nó không ra được các quyết định về sản phẩm.** Từ chối cơ chế game hoá của app tham khảo, chọn
  cột mốc thay vì streak, quyết định không gắn analytics — không cái nào là câu hỏi kỹ thuật, và tất
  cả đều định nghĩa app này là gì.
- **Nó không bắt được lỗi hiệu ứng hero** (BUGS §9.4). Build pass, kiểm tra kiểu pass, code hợp lệ.
  Phải dùng app trên máy thật mới thấy.

**Bài học:** phần việc còn lại cho con người là định hướng, phán đoán, và đối chiếu với thực tế. Đó
là phần nhỏ hơn xét theo số ký tự gõ ra, nhưng lớn hơn nhiều xét theo việc sản phẩm có tốt hay không.

---

## 4. "Bạn tự viết hay AI viết?"

Bạn chắc chắn sẽ gặp một biến thể của câu này. Hãy trả lời thẳng và không xin lỗi.

### Đừng làm thế này

**Đừng nói giảm** ("em chỉ dùng để gợi ý gõ code") — rất dễ bị bóc, và nó biến điều trung thực duy
nhất bạn nói thành điều sai.

**Cũng đừng ngả sang thái cực kia.** Nói "AI viết hết" là vứt bỏ toàn bộ những gì bạn thật sự đã làm.

### Cách nói trung thực và mạnh

> "Em dùng Claude Code như người thực thi, còn em là kỹ sư định hướng nó — em đặt ràng buộc, viết đặc
> tả, ra quyết định về sản phẩm, và kiểm chứng đầu ra. Phần cuối hoá ra chiếm phần lớn công việc, vì
> kiểu lỗi ở đây không phải code hỏng, mà là code biên dịch được, nhìn đúng, và âm thầm không làm gì
> cả."

Rồi đưa **một** ví dụ cụ thể. Lỗi `UIColor(Color)` làm phẳng màu là ví dụ tốt nhất, vì nó chứng minh
luận điểm trong ba mươi giây: bản sửa biên dịch được, nhìn đúng khi review, chạy không lỗi, và không
làm gì hết. Thứ bắt được nó là một test đo giá trị đầu ra thật.

### Vì sao câu trả lời này hiệu quả

Nó kiểm chứng được — repo có các bản đặc tả, bộ quy tắc, các bộ test, và những phần ghi lại chỗ kế
hoạch sai rồi được sửa. Và nó trả lời đúng cái câu hỏi mà người phỏng vấn thật sự đang hỏi, vốn không
phải "bạn có gõ từng ký tự không" mà là **"nếu codebase này hỏng, bạn sửa được không?"**

Bằng chứng cho thấy bạn sửa được: bạn tìm ra những lỗi mà công cụ không tìm ra, bạn bác bỏ hai kế
hoạch sai một cách tự tin, và bạn giải thích được mọi quyết định trong codebase xuống tận phép tính.

### Nếu họ có vẻ không thiện cảm với việc dùng AI

Đừng tranh luận xem dùng AI có "chính đáng" hay không. Hãy chuyển sang mảnh đất không ai tranh cãi
được:

> "Em hiểu ạ — cách em tự đánh giá là em có hiểu hệ thống đủ để thay đổi nó không. Anh/chị chọn bất
> kỳ file nào và hỏi em vì sao nó được xây như vậy."

Đó là lời mời mà rất ít ứng viên dám đưa ra một cách an toàn, và đưa ra được nó có giá trị hơn mọi
lời tranh luận.

---

## 5. Những câu khác nên chuẩn bị sẵn

### "Quyết định kỹ thuật khó nhất của bạn là gì?"

Cách đưa dữ liệu cho widget. Hai phương án: chuyển kho Core Data vào App Group để widget đọc dữ liệu
sống, hoặc ghi một file snapshot nhỏ cho widget đọc.

Chuyển kho dữ liệu thì sạch sẽ hơn về kiến trúc — một nguồn sự thật duy nhất, luôn mới. Nhưng nó cũng
đòi hỏi phải migrate **nhật ký của mọi người dùng hiện có**, mà một lỗi migrate trong app nhật ký thì
làm người ta mất kỷ niệm.

Phương án snapshot thắng, vì widget chỉ cần một cảm xúc, một thumbnail và một số ngày. Kiến trúc sạch
hơn không đổi lại được gì đáng kể ở đây, trong khi rủi ro thì không có giới hạn. **Kho dữ liệu không
hề bị di chuyển.**

Đây là câu trả lời tốt vì lập luận xoay quanh **rủi ro so với lợi ích**, không phải quanh chuyện
thiết kế nào đẹp hơn.

### "Bạn sẽ làm gì khác đi?"

Độ phủ test cho lớp giao diện, và làm sớm hơn. Phần bảng màu, export và logic cột mốc đã được phủ;
còn các view SwiftUI thì kiểm chứng bằng cách build lên và nhìn.

Cụm lỗi ở Phần C chính là thứ mà khoảng trống đó để lọt — một màu sai nhưng hợp lý trông vẫn ổn với
bất kỳ ai không biết trước nó phải như thế nào. Phản ứng là tự động hoá những gì tự động hoá được
thay vì hứa sẽ nhìn kỹ hơn, nhưng điều đó chỉ xảy ra sau khi ba vòng chỉnh tay trượt phép tính.

### "Bạn xử lý thế nào với một lỗi không tái hiện được?"

Dùng lỗi hiệu ứng hero (BUGS §9.4) — nó tái hiện được, nhưng phần chẩn đoán mới là phần thú vị. Manh
mối nằm ở **sự vắng mặt** của một thứ: hoàn toàn không có chuyển động nào. Một transition chỉ kết
thúc sai chỗ thì vẫn phải có chuyển động. Quan sát đó đã đổi hướng toàn bộ cuộc điều tra từ "tại sao
điểm đến sai" sang "rốt cuộc có transition nào đang chạy không?"

Ý tưởng áp dụng được: hãy chú ý tới thứ **thiếu vắng** trong biểu hiện của lỗi, không chỉ chú ý tới
thứ sai.

### "Bạn quyết định KHÔNG làm gì như thế nào?"

Có câu trả lời cụ thể sẵn: các tính năng xã hội và game hoá của app tham khảo, tất cả đều bị chủ động
loại bỏ khi lên kế hoạch v2, dù đó chính là những cơ chế dễ giữ chân người dùng nhất.

Phép thử được dùng là: tính năng đó có hợp với **mục đích** của sản phẩm không. Một cuốn nhật ký làm
bạn thấy có lỗi vì bỏ lỡ một ngày là đang đi ngược lại chính mục đích của nó, bất kể nó làm gì với
các chỉ số.

### "Kể về một lần bạn đã sai."

Phần C, sai hai lần trong cùng một task (xem §3.2 ở trên). Cả hai lỗi đều là của tôi, cả hai đều được
phát hiện bằng cách đo đạc chứ không bằng ý kiến, và cả hai đều được ghi vào tài liệu dự án chứ không
âm thầm sửa đi.

Phần cuối mới quan trọng — tài liệu ghi rõ *"kế hoạch nói X, và đây là lý do X sai."* Đó là thói quen
đáng thể hiện.

### "Bạn làm việc thế nào với người bất đồng ý kiến?"

Nếu bạn chưa có ví dụ làm việc nhóm, hãy trung thực và dùng thứ gần nhất có thật: khi kế hoạch và
bằng chứng mâu thuẫn nhau, bằng chứng thắng, và nó được ghi lại để lập luận sống lâu hơn cuộc bất
đồng.

Đừng bịa ra một mâu thuẫn với đồng đội. Một ví dụ bịa còn tệ hơn là không có ví dụ, và câu này thường
được nối tiếp bằng "rồi họ nói gì?".

### "Tại sao chúng tôi nên tuyển bạn?"

Đừng trả lời bằng tính từ. Hãy trả lời bằng hình dạng của việc bạn đã làm:

> "Em đã tự mình đưa một sản phẩm thật lên App Store — thiết kế, iOS, một lớp backend trung gian,
> phần đăng ký trả phí, và cả quy trình App Store. Và em có thể chỉ cho anh/chị đúng những chỗ em đã
> sai và em phát hiện ra bằng cách nào, thứ mà em nghĩ còn quan trọng hơn những phần chạy tốt."

---

## 6. Câu hỏi nên hỏi lại họ

Không hỏi gì cả tạo cảm giác bạn không quan tâm. Hãy hỏi hai ba câu — và thật sự **nghe** câu trả
lời, đừng chỉ chờ tới lượt mình nói.

- **"Ở đây công việc được kiểm chứng như thế nào ạ?"** Test, review, QA, staging? Giờ bạn có quan
  điểm thật về chuyện này và nó mở ra một cuộc trò chuyện thực chất.
- **"Quan điểm của team về việc dùng AI hỗ trợ lập trình thực tế ra sao ạ?"** Không phải hỏi "có cho
  phép không" — mà là quy trình review đã thay đổi thế nào, nếu có.
- **"Lỗi gần nhất khiến ai đó mất hơn một ngày là lỗi gì, và cái gì làm nó khó ạ?"** Câu này cho bạn
  biết về codebase nhiều hơn mọi câu hỏi về kiến trúc.
- **"Trong sáu tháng đầu em sẽ phụ trách phần nào ạ?"** Lọc ra vị trí thật khỏi những mô tả mơ hồ.
- **"Người làm tốt ở đây khác người chật vật ở điểm nào ạ?"** Câu này thường nhận được câu trả lời
  trung thực một cách bất ngờ.

---

## 7. Những cái bẫy nên tránh

**Đừng nói bạn làm app này mà không dùng AI.** Không cần thiết, dễ bị bóc, và nó biến một điểm mạnh
thành một lời nói dối.

**Đừng làm cho một cái lỗi có vẻ khó hơn thực tế.** Nếu bạn thổi phồng, các câu hỏi đào sâu sẽ nhanh
chóng khiến bạn khó xử. Lỗi giới hạn AI chỉ là một dòng — cứ nói vậy. Giá trị của nó nằm ở lập luận,
không nằm ở độ khó.

**Đừng nói "không có lỗi gì" hay "không có gì em muốn làm khác".** Bạn có bốn lỗi Phần C được ghi
chép đầy đủ và một câu trả lời trung thực về phần yếu nhất. Hãy dùng chúng. Ứng viên không có thất
bại nào thường bị đọc là thiếu kinh nghiệm, hoặc không quan tâm tới chính công việc của mình.

**Đừng đọc kiến trúc như một danh sách.** "SwiftUI, MVVM, Core Data, Supabase" chẳng nói lên điều gì.
"Core Data là nguồn sự thật vì một lỗi đồng bộ làm mất bài viết trong app nhật ký là điều không thể
tha thứ" mới cho họ thấy bạn tư duy thế nào.

**Đừng thổi phồng quy mô.** Đây là dự án một người: 78 file, ~14.100 dòng, một thư viện ngoài duy
nhất, đã lên App Store. Như vậy là thật sự đáng nể rồi. Thổi phồng chỉ chuốc thêm sự soi xét không
cần thiết.

**Đừng bỏ qua câu chuyện về quyền riêng tư.** Đó là điểm mạnh về mặt cấu trúc nhất của dự án — một
ràng buộc định hình rõ rệt năm quyết định không liên quan nhau — và nó rất dễ bị quên vì với bạn giờ
nó đã thành hiển nhiên.

---

## 8. Bản ba mươi giây

Nếu bạn chỉ có một cơ hội để mô tả dự án:

> "MemoryInk là một app nhật ký riêng tư trên iOS — bạn lưu một tấm ảnh và một cảm xúc, rồi AI viết
> một đoạn ngắn suy ngẫm về khoảnh khắc đó. Ràng buộc định hình cả sản phẩm là ảnh không bao giờ rời
> khỏi máy bạn, nên AI làm việc từ nhãn Vision chạy trên máy và metadata, không bao giờ từ tấm ảnh.
> App đã lên App Store, em tự làm một mình bằng SwiftUI với Core Data làm nguồn sự thật và một
> Supabase Edge Function để khoá API không bao giờ nằm trong app. Phần em thấy thú vị nhất để kể là
> những cái lỗi biên dịch được, nhìn đúng, mà chẳng làm gì cả."

Câu cuối là một cái mồi, và là mồi cho đúng cuộc trò chuyện mà bạn đã chuẩn bị rất kỹ.
