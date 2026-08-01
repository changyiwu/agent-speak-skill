# 交接檔（handoff.md）

> 任何 Agent、任何電腦接手前**必讀**；收工時**必更新**。本檔只放交接必需的精簡資訊，詳細脈絡放 Obsidian。

## ⏯️ 目前做到哪

已完成 `speak` Skill 的安全性修正、依賴安裝、實際播放、預設聲音調整、四 Agent 全域同步，以及 L1 本地、L2 GitHub、L3 Obsidian 專案初始化。

## 🚦 目前狀態

- L1 本地初始化檔已建立，Git 分支為 `main`。
- Skill validator、PowerShell 語法解析、四個 Python 隔離情境、PowerShell `-Check` 測試、BOM 與敏感資料掃描均通過。
- 本機語音依賴已就緒：PowerShell 7.6.4、Python 3.13.14、`edge-tts` 7.2.8、FFmpeg/ffplay 8.1.2。
- `STREAM_READY=True`、`FILE_READY=True`、`SAPI_READY=True`；Edge-TTS 線上生成 16,704 bytes 暫存 MP3 成功並已清理。
- Codex 一般沙箱看不到 WindowsApps 與使用者層 Python/FFmpeg PATH；需經批准在主機使用者環境執行，不能把沙箱結果誤判為未安裝。
- 已實際播放語音笑話，並完成第二、第三個台灣中文聲音的試聽比較。
- 使用者試聽後選擇第二個聲音；預設已改為 `zh-TW-HsiaoChenNeural`（小陳女聲），並加入跨 PowerShell/Python 預設值檢查。
- 公開 GitHub repo：`https://github.com/changyiwu/agent-speak-skill`。
- Obsidian：`agent-speak-skill/專案工作流程.md`。
- 四個 Agent 全域目錄均已首次安裝 `speak`；每份 4 個檔案，缺漏、差異、額外檔案皆為 0，frontmatter 與 UTF-8 BOM 驗證通過。

## ➡️ 下一步

1. 下次修改請以本 repo 的 `speak/` 為唯一來源，不要直接改四個全域副本。
2. 修改後重新執行測試，再用 `sync-skills` 同步並逐檔驗證四份副本。
3. 在其他電腦使用前，需各自安裝 PowerShell 7、Python、`edge-tts` 與 FFmpeg/ffplay。

## ⚠️ 注意事項

- 不要把使用者提供的講稿直接插入 shell 命令字串；Agent 預設應使用 UTF-8 暫存文字檔與 `-File`。
- Codex 沙箱若看不到主機依賴，應經批准改用主機使用者環境執行，不要重複安裝。

## 🕐 最後更新

- 時間：2026-08-01 19:45 +08:00
- 更新者：Codex @ PC-YI-FY
- Git push：⏳ 待本次收工 commit 與 push
