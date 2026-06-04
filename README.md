# 🤖 AI Mobile Agent (HarmonyOS)

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0-red?logo=harmonyos)](https://developer.huawei.com/consumer/cn/harmonyos/)
[![ArkTS](https://img.shields.io/badge/ArkTS-5.0-blue)](https://developer.huawei.com/consumer/cn/arkts/)
[![API](https://img.shields.io/badge/API%20Level-12-orange)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/harmonyos-overview-V5)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

An AI-powered mobile automation assistant for HarmonyOS — control your phone with natural language commands, backed by **Large Language Models**.

> This project is the HarmonyOS counterpart of [ai-mobile-agent-android](https://github.com/cjyhjy/ai-mobile-agent-android), sharing the same architecture and feature set, rebuilt in **ArkTS** for the HarmonyOS ecosystem.

---

## 📱 What It Does

Describe what you want in natural language, and the AI agent plans and executes it:

> "打开微信，给李四发消息说明天见"  
> "帮我在设置里打开蓝牙"  
> "搜索附近的咖啡店"

---

## 🧠 Architecture

```
┌─────────────────────────────────────────────┐
│                 USER INPUT                   │
│          (Natural Language / Chat)           │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │  ProcessCommand     │  ── LLM → structured Task (JSON)
        │    UseCase          │
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────┐
        │   ExecuteTask       │  ── OTAV Agent Loop ──
        │     UseCase         │     Observe → Think → Act → Verify
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────┐
        │   StepExecutor      │  ── Accessibility Kit ──
        │   (Stub → WIP)      │     launchApp, tap, type, swipe...
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────┐
        │   HarmonyOS NEXT     │
        └──────────────────────┘
```

**Clean Architecture** in ArkTS:

```
entry/src/main/ets/
├── entryability/       # UIAbility lifecycle
├── models/             # Domain models (Task, Step, enums)
├── usecases/           # ProcessCommand, ExecuteTask
├── data/               # LLMRepository, TaskStore, StreamingLLM
├── execution/          # StepExecutor (interface + stub)
└── pages/              # ChatPage (ArkUI declarative UI)
```

---

## ✨ Features

| Feature | Status | Description |
|---------|--------|-------------|
| 💬 **Chat Interface** | ✅ Done | Natural language input with streaming response UI |
| 🧠 **Multi-Model** | ✅ Done | DeepSeek / OpenAI / Anthropic / Google (7 models) |
| 📋 **Task Planning** | ✅ Done | LLM parses commands into structured step-by-step plans |
| 🔄 **OTAV Loop** | ✅ Done | Observe → Think → Act → Verify execution engine |
| 🛡️ **Safety Check** | ✅ Done | Payment/password screen detection before sensitive ops |
| 💾 **Local Persistence** | ✅ Done | SQLite via `relationalStore` for task history |
| 🔑 **API Key Mgmt** | ✅ Done | Per-model keys persisted via `preferences` |
| ⚡ **Real Automation** | 🚧 Stub | `BasicStepExecutor` prints logs — Accessibility Kit integration pending |
| 🎨 **Dark Theme** | ✅ Done | Slate + Indigo, consistent with Android version |

---

## 🛠 Tech Stack

| Category | Technology |
|----------|-----------|
| **Language** | ArkTS (TypeScript for HarmonyOS) |
| **UI** | ArkUI declarative framework (`@Component`, `@State`) |
| **SDK** | HarmonyOS 5.0.0 (API 12) |
| **API Mode** | Stage mode (`UIAbility`) |
| **Network** | `@kit.NetworkKit` (`http` module) |
| **Database** | `@kit.ArkData` (`relationalStore` — SQLite) |
| **KV Storage** | `@kit.ArkData` (`preferences`) |
| **LLM APIs** | DeepSeek Chat/Reasoner, GPT-4o/mini, Claude 3.5/4.6, Gemini 2.0 Flash |

---

## 🚀 Getting Started

### Prerequisites

- [DevEco Studio](https://developer.huawei.com/consumer/cn/download/) (5.0+)
- HarmonyOS device or emulator running API 12+
- API key from [DeepSeek](https://platform.deepseek.com/) (or OpenAI / Anthropic / Google)

### Build & Run

```bash
# 1. Clone the repository
git clone https://github.com/cjyhjy/ai-mobile-agent-harmonyos.git
cd ai-mobile-agent-harmonyos

# 2. Open in DevEco Studio
#    - File → Open → select the project directory

# 3. Let the IDE auto-generate hvigor build files

# 4. Build & deploy
#    - Connect device / start emulator
#    - Click Run (or Ctrl+F5)
```

### Setup After Install

1. **Configure API Key** — Open app → tap model selector → gear icon → enter your key
2. **Choose Model** — Select from DeepSeek / OpenAI / Anthropic / Google
3. **Start Chatting** — Type a command or chat naturally

---

## 📂 Project Structure

```
ai-mobile-agent-harmonyos/
├── build-profile.json5              # Root build config (SDK 5.0.0)
├── entry/
│   ├── build-profile.json5          # Module build config (stageMode)
│   └── src/main/
│       ├── module.json5             # Module manifest + Accessibility ability decl.
│       ├── resources/
│       │   └── base/
│       │       ├── element/         # color.json, string.json
│       │       └── profile/
│       │           └── main_pages.json   # Page routes
│       └── ets/
│           ├── entryability/
│           │   └── EntryAbility.ets      # App lifecycle entry
│           ├── models/
│           │   └── Task.ets              # Task, Step, enums, helpers
│           ├── usecases/
│           │   ├── ProcessCommandUseCase.ets  # LLM → structured task plan
│           │   └── ExecuteTaskUseCase.ets     # OTAV execution loop
│           ├── data/
│           │   ├── LLMRepository.ets          # LLM API calls + parsing
│           │   ├── StreamingLLMClient.ets      # Multi-model chat client
│           │   └── TaskStore.ets               # SQLite persistence
│           ├── execution/
│           │   └── StepExecutor.ets            # Interface + BasicStub
│           └── pages/
│               └── ChatPage.ets               # Main chat UI
```

---

## 🔄 Relationship to Android Version

| Aspect | Android | HarmonyOS |
|--------|---------|-----------|
| **Language** | Kotlin | ArkTS |
| **UI** | Jetpack Compose | ArkUI |
| **DI** | Dagger Hilt | Manual instantiation |
| **DB** | Room | relationalStore |
| **Network** | Retrofit + OkHttp | @kit.NetworkKit http |
| **Automation** | AccessibilityService ✅ | Accessibility Kit 🚧 (stub) |
| **Modules** | 5 Gradle modules | Single module (entry) |
| **Models** | Sealed classes | TypeScript interfaces |

Both versions share the same:
- OTAV agent loop design
- Prompt templates and few-shot examples
- Task/Step model structure
- Multi-model API configuration
- Dark theme color palette

---

## 🚧 In Progress

- [ ] **Accessibility Kit integration** — Replace `BasicStepExecutor` stub with real UI automation
- [ ] **App icon assets** — `$media:app_icon` currently missing
- [ ] **Voice input** — Port Android's `SpeechRecognizer` equivalent
- [ ] **App management screen** — UI for registering controllable apps
- [ ] **Navigation** — Multi-page routing beyond single `ChatPage`

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

*Built with ❤️ by [cjyhjy](https://github.com/cjyhjy)*
