# agent-speak-skill（專案藍圖）

> 本檔為跨 Agent 通用的專案藍圖（AGENTS.md 開放標準）。任何 Agent 的每個 session 都應先讀本檔＋`handoff.md`。
> Claude Code 不讀 `agents.md`，改由 `CLAUDE.md` 的 `@agents.md` import 本檔；Claude 專屬規範寫在 `CLAUDE.md`。

## 專案簡介

建立可供 Claude Code、Codex、OpenCode、Antigravity 共用的 Windows 台灣中文語音回覆 Skill，以 Edge-TTS 串流播放為主，並提供整檔播放與 Windows SAPI 備援。

## 關鍵時程

目前沒有固定時程。

## 目標與路線圖

- [x] 階段一：完成安全傳參、跨 Agent 相容性、錯誤處理與暫存檔修正
- [x] 階段二：通過 Skill validator、語法解析與隔離式失敗情境測試
- [x] 階段三：完成 GitHub 與 Obsidian 初始化
- [x] 階段四：同步到四個 Agent 全域技能目錄，並完成逐檔 SHA-256、額外檔案與 UTF-8 BOM 驗證

## 資料夾結構

```text
agent-speak-skill/
├── speak/                 # 可安裝的 Skill 來源目錄
│   ├── agents/            # Codex UI metadata
│   ├── SKILL.md           # 觸發條件與 Agent 執行流程
│   ├── speak.ps1          # Windows 主控、播放與備援腳本
│   └── speak_stream.py    # Edge-TTS 串流播放器
├── tests/                 # 不連網、不播放聲音的隔離測試
├── agents.md              # 跨 Agent 專案藍圖
├── handoff.md             # 跨工作階段交接
├── CLAUDE.md              # Claude Code 橋接
├── .gitattributes         # 固定文字檔為 LF，避免跨電腦 hash 漂移
├── README.md              # 專案安裝與使用說明
├── LICENSE                # MIT 授權
└── .gitignore             # 本機與敏感檔排除規則
```

## 同步層級（本專案初始化至第 3 層級）

| 層級 | 平台 | 位置 | 讀取時機 |
|------|------|------|---------|
| L1 | 本地（GDrive） | `agents.md`＋`handoff.md`＋`CLAUDE.md`（橋接） | 每個 session |
| L2 | GitHub | [changyiwu/agent-speak-skill](https://github.com/changyiwu/agent-speak-skill)（公開） | 指定時 |
| L3 | Obsidian | `agent-speak-skill/專案工作流程.md` | 有需要時 |

## 工作約定

- 任何 Agent、任何電腦：**開工先讀 `handoff.md`，收工必更新 `handoff.md`**
- 修改共用檔案前先讀最新內容，避免覆蓋其他 Agent 的變更
- 所有回應與文件使用繁體中文
- 修改前先確認計畫，優先保留原有資料結構
- 全域技能目錄、Git commit、push 與部署必須取得使用者授權；專案初始化請求僅授權本專案的初始化流程
- 本專案 GitHub repo 為公開；commit 前必須掃描敏感資料與不應公開的素材
- 四個 Agent 的安裝來源固定為 `speak/`，安裝名稱由 frontmatter `name: speak` 決定
- 同步前先確認 Git 來源可信；同步後逐一比對檔案清單、SHA-256 與 UTF-8 BOM

## 全域技能同步狀態

2026-08-01 已完成 `speak` 首次安裝；四份副本各 4 個檔案，與專案來源的相對檔案清單及 SHA-256 完全一致，沒有額外檔案，且 `SKILL.md` 均無 UTF-8 BOM。

- Claude Code：`C:\Users\chang\.claude\skills\speak`
- Codex：`C:\Users\chang\.agents\skills\speak`
- OpenCode：`C:\Users\chang\.config\opencode\skills\speak`
- Antigravity：`C:\Users\chang\.gemini\config\skills\speak`
