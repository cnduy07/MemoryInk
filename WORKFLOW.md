# WORKFLOW.md
> Hướng dẫn sử dụng Claude Code (PM) + Codex CLI (Dev) cho MemoryInk
> Không cần copy-paste. Hai tool trao đổi qua file system.

---

## Setup một lần duy nhất

### 1. Copy các file vào root của project

```bash
cp CLAUDE.md /path/to/MemoryInk/
cp TASK_TEMPLATE.md /path/to/MemoryInk/
mkdir -p /path/to/MemoryInk/tasks/completed
```

Cấu trúc sau khi setup:
```
MemoryInk/              ← root repo
├── CLAUDE.md           ← Claude Code tự đọc khi khởi động
├── AGENTS.md           ← Codex tự đọc khi khởi động  
├── TASK_TEMPLATE.md    ← Template để Claude điền
├── tasks/
│   ├── current-task.md ← Task đang active (Claude viết, Codex đọc)
│   └── completed/      ← Archive sau khi done
└── MemoryInk/          ← Xcode project
```

### 2. Cài Claude Code CLI (nếu chưa có)

```bash
npm install -g @anthropic-ai/claude-code
```

### 3. Verify Codex CLI đã có

```bash
codex --version
```

---

## Workflow mỗi task

### Bước 1 — Mở Claude Code trong repo (Terminal A)

```bash
cd /path/to/MemoryInk
claude
```

Claude Code tự đọc `CLAUDE.md` → biết mình là PM, biết Phase 3, biết cấu trúc project.

**Nói với Claude Code:**
```
Tôi muốn implement [yêu cầu của bạn]. 
Hãy viết task spec vào tasks/current-task.md.
```

Claude Code sẽ:
- Kiểm tra scope (Phase 3 không?)
- Flag nếu cần approval
- Viết spec chi tiết vào `tasks/current-task.md`

---

### Bước 2 — Mở Codex CLI trong repo (Terminal B)

```bash
cd /path/to/MemoryInk
codex
```

Codex tự đọc `AGENTS.md` → biết toàn bộ coding rules.

**Nói với Codex:**
```
Read tasks/current-task.md and implement it.
Follow AGENTS.md for all coding rules.
```

Codex sẽ:
- Đọc task spec
- Viết code trực tiếp vào các file được chỉ định
- In ra summary theo format AGENTS.md

---

### Bước 3 — Review với Claude Code (Terminal A)

Quay lại Terminal A (Claude Code vẫn đang chạy):

```
Codex đã xong. Summary:
[paste summary từ Codex]

Hãy review và cho biết có vấn đề gì không, 
và task tiếp theo là gì.
```

Claude Code sẽ:
- Check summary vs spec
- Báo lỗi nếu có
- Viết task tiếp theo vào `tasks/current-task.md` nếu ổn

---

### Bước 4 — Archive task hoàn thành

```bash
# Chạy trong Terminal bất kỳ
mv tasks/current-task.md tasks/completed/$(date +%Y-%m-%d)-task-name.md
```

---

## Sơ đồ tổng quan

```
[Bạn nói yêu cầu]
       ↓
[Terminal A — claude]
  Đọc CLAUDE.md
  Viết tasks/current-task.md
       ↓ (file được ghi xuống disk)
[Terminal B — codex]
  Đọc AGENTS.md (auto)
  Đọc tasks/current-task.md
  Sửa code trực tiếp trong repo
  In ra summary
       ↓ (bạn paste summary)
[Terminal A — claude]
  Review summary
  Approve hoặc tạo correction task
       ↓
  Lặp lại hoặc archive
```

**Bạn chỉ làm 2 việc:**
1. Nói yêu cầu với Claude Code
2. Paste summary của Codex lại cho Claude Code review

---

## Tips tiết kiệm token

### Chỉ share file liên quan, không share toàn bộ repo

```bash
# Khi hỏi Claude về 1 file cụ thể
claude "Review Services/SyncService.swift"

# Không làm thế này — tốn token
claude "Here is my entire codebase: [paste repomix]"
```

### Dùng repomix chỉ khi bắt đầu project mới hoặc onboard context lớn

```bash
# Tạo repomix chỉ cho thư mục liên quan
npx repomix --include "MemoryInk/Services/**,MemoryInk/Models/**"
```

### Giữ tasks/current-task.md ngắn và rõ

Task spec tốt = 50–150 dòng. Dài hơn → Codex bị nhiễu, tốn token cả hai bên.

### Bắt đầu session mới với context tối thiểu

```bash
cd /path/to/MemoryInk
claude "CLAUDE.md đã có context. Task hôm nay: [mô tả ngắn]"
```

Không cần paste lại toàn bộ history — CLAUDE.md đã có đủ context cố định.

---

## Xử lý khi Codex hỏi ngược lại

Nếu Codex hỏi "Should I also update X?" hoặc không chắc → quay lại Terminal A:

```
Codex hỏi: "[câu hỏi của Codex]"
Trả lời thế nào?
```

Claude Code sẽ ra quyết định → bạn paste câu trả lời vào Terminal B.

---

## Khi cần approval (human-in-the-loop)

AGENTS.md đã định nghĩa rõ khi nào phải hỏi bạn. Khi Claude Code flag một approval:

```
⚠️ APPROVAL REQUIRED
[Lý do]
Bạn có muốn tiếp tục không?
```

Bạn quyết định → Claude Code mới viết task.

---

## Checklist setup

- [ ] `CLAUDE.md` đã copy vào root repo
- [ ] `AGENTS.md` đã có trong root repo (✅ đã có)
- [ ] `TASK_TEMPLATE.md` đã copy vào root repo
- [ ] Thư mục `tasks/` và `tasks/completed/` đã tạo
- [ ] Claude Code CLI đã cài (`claude --version`)
- [ ] Codex CLI đã cài (`codex --version`)
- [ ] Test: chạy `claude` trong repo, hỏi "What phase is MemoryInk in?" → phải trả lời Phase 3
