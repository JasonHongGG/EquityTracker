# EquityTracker

EquityTracker 是一個使用 Flutter 打造的高質感、現代化記帳與資產追蹤應用程式。本專案致力於提供最流暢的動畫交互體驗（如 3D 卡片、角子老虎機滾輪特效）以及直覺的操作流程。

---

## 核心功能與特色
* **Premium Dashboard**：具備彈性滑動與數字滾輪特效的資產儀表板。
* **Swipe to Obliterate**：高度客製化、帶有物理彈簧與震動回饋的滑動解鎖/刪除元件。
* **GitHub 自動更新模組**：內建完全解耦的自動更新檢查器（讀取 `pubspec.yaml` 進行版本比對）。
* **AI 記帳與對話**：支援與 AI 助理對話來快速記帳或查詢收支。

---

## 開發與編譯指南

### 1. 基礎環境設定
請確保您的開發環境已安裝最新版本的 Flutter (>= 3.10.0)。
```bash
# 取得依賴套件
flutter pub get

# 執行應用程式
flutter run
```

### 2. 打包發布 (Release Build)
#### Android APK 最佳化打包 (推薦)
為了解決 Flutter 預設打包 APK 時檔案過大（包含所有架構指令集）的問題，強烈建議在打包時使用 `--split-per-abi` 參數。這會將不同 CPU 架構 (如 `arm64-v8a`, `armeabi-v7a`, `x86_64`) 拆分成獨立的 APK，**大幅度縮減單一 APK 的檔案大小**，提供給使用者更輕量的下載體驗。

```bash
# 打包出按指令集拆分的最佳化 APK (並關閉圖示 tree-shake 以支援動態類別圖示)
flutter build apk --split-per-abi --no-tree-shake-icons
```
*打包後的檔案會生成於：`build/app/outputs/flutter-apk/`*
*(通常現代 Android 手機只需分發 `app-arm64-v8a-release.apk` 即可)*

#### 🍎 iOS 打包
```bash
flutter build ipa
```

### 3. 版本更新流程 (GitHub Auto Updater)
本專案內建了基於 GitHub Releases 的自動更新機制。若要發布新版本給使用者：
1. **更新版號**：修改 `pubspec.yaml` 中的 `version` 欄位（例如：`1.0.1+3`）。
2. **打包 APK**：執行上述的 `flutter build apk --split-per-abi` 指令。
3. **建立 Release**：至 GitHub Repository 建立一個新的 Release。
4. **命名 Tag**：Tag 名稱必須大於前一個版本（例如 `v1.0.1`）。
5. **上傳檔案**：將打包好的 APK 檔案拖曳至 Release 的附檔區。
6. **發布**：按下 Publish。使用者的 App 下次啟動或點擊檢查更新時，即會自動跳出更新提示。
