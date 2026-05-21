# TASK_TEMPLATE.md
> Format chuẩn cho mọi task từ Claude (PM) → Codex (Dev)
> Codex phải đọc AGENTS.md trước khi đọc file này.

---

## Cách dùng

Claude Code (PM) copy template này vào `tasks/current-task.md` và điền đầy đủ.
Codex đọc `tasks/current-task.md` và thực hiện. Không hỏi lại nếu spec đã rõ.

---

```markdown
# Task: [Tên ngắn gọn, động từ đầu — ví dụ: "Implement RevenueCat purchase flow"]

**Date:** YYYY-MM-DD  
**Phase:** Phase 3 — Monetization & Sync  
**Priority:** High / Medium / Low  
**Estimated scope:** Small (1–2 files) / Medium (3–5 files) / Large (6+ files)

---

## Context

[1–3 câu giải thích TẠI SAO task này cần làm bây giờ.
Ví dụ: "SubscriptionManager hiện chỉ mock entitlement. Cần kết nối thật với RevenueCat SDK
để paywall hiển thị đúng trạng thái premium."]

---

## Objective

[1 câu mô tả kết quả khi task hoàn thành.
Ví dụ: "User có thể mua subscription monthly/yearly, entitlement `premium` được cập nhật real-time."]

---

## Files to modify

| File | Action | Reason |
|------|--------|--------|
| `MemoryInk/Services/RevenueCatService.swift` | modify | Wire real purchase calls |
| `MemoryInk/Features/Subscription/SubscriptionView.swift` | modify | Handle loading/error states |
| `MemoryInk/Models/SubscriptionPlan.swift` | read-only | Reference only, do not modify |

**Do NOT touch:** [List files Codex must not modify]

---

## Implementation spec

### Step 1: [Tên bước]
[Mô tả cụ thể cần làm gì. Đủ chi tiết để không cần đoán.]

```swift
// Ví dụ code pattern nếu cần định hướng — không bắt buộc
```

### Step 2: [Tên bước]
[...]

### Step 3: [Tên bước]
[...]

---

## Constraints (từ AGENTS.md — nhắc lại cho task này)

- [ ] Không thêm Swift Package mới
- [ ] Không thay đổi giá subscription hoặc entitlement ID
- [ ] Paywall chỉ hiện sau first emotional moment, không hiện khi launch
- [ ] Không gọi production API trực tiếp trong preview/test
- [ ] [Constraint bổ sung nếu có]

---

## Success criteria

Codex báo task hoàn thành khi TẤT CẢ các điều kiện sau đúng:

- [ ] [Điều kiện 1 — binary, có thể kiểm tra được]
- [ ] [Điều kiện 2]
- [ ] [Điều kiện 3]
- [ ] Xcode compile không có error
- [ ] Preview chạy đúng với mock data

---

## Out of scope for this task

[Những thứ liên quan nhưng KHÔNG làm trong task này.
Ví dụ: "Restore purchases, manage subscription — task riêng sau."]

---

## Expected Codex response format

Codex phải trả lời theo format trong AGENTS.md:

```
### Planned Changes
- [Filename] [create / modify / delete] — short reason

### Code
[Code here]

### Summary
- Files changed: [explicit list]
- Behavior change: [1–2 sentence description]
- Not verified: [anything not tested or confirmed]
- Needs human approval for next step: [yes / no + reason if yes]
```
```

---

## Ví dụ task đã điền (để tham khảo)

```markdown
# Task: Wire RevenueCat entitlement check into SubscriptionManager

**Date:** 2026-05-20  
**Phase:** Phase 3 — Monetization & Sync  
**Priority:** High  
**Estimated scope:** Small (2 files)

---

## Context

SubscriptionManager.swift hiện trả về mock `isPremium = false` hardcoded.
RevenueCat SDK đã được cài (Package.resolved). Cần kết nối thật để app
đọc đúng entitlement state khi user đã mua hoặc đang trial.

---

## Objective

`SubscriptionManager.isPremium` phản ánh đúng trạng thái entitlement `premium`
từ RevenueCat, cập nhật khi app foreground.

---

## Files to modify

| File | Action | Reason |
|------|--------|--------|
| `MemoryInk/Services/RevenueCatService.swift` | modify | Add real entitlement fetch |
| `MemoryInk/Services/SubscriptionManager.swift` | modify | Replace mock with real check |

**Do NOT touch:** SubscriptionView.swift, pricing values, entitlement IDs

---

## Implementation spec

### Step 1: RevenueCatService — fetch current entitlement
Gọi `Purchases.shared.getCustomerInfo()` async, kiểm tra
`customerInfo.entitlements["premium"]?.isActive == true`.
Không cache — luôn fetch fresh khi được gọi.

### Step 2: SubscriptionManager — expose isPremium
`@Published var isPremium: Bool` được update từ RevenueCatService.
Gọi refresh khi app enters foreground (NotificationCenter observer).

---

## Constraints

- [ ] Không thêm Swift Package mới (RevenueCat đã có)
- [ ] Entitlement ID phải là string literal `"premium"` — không thay đổi
- [ ] Không gọi purchase flow trong task này

---

## Success criteria

- [ ] `SubscriptionManager.isPremium` trả về `true` khi mock CustomerInfo có entitlement active
- [ ] `SubscriptionManager.isPremium` trả về `false` khi mock không có entitlement
- [ ] Xcode compile không có error
- [ ] Không có hardcoded `isPremium = false` còn sót lại

---

## Out of scope

Purchase flow, restore purchases, paywall display logic — task riêng.
```
