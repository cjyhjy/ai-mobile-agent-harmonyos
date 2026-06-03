import { StreamingLLMClient, StreamEvent, MODELS } from '../data/StreamingLLMClient'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'

interface ChatMessage {
  text: string
  isUser: boolean
  isThinking: boolean
  isStreaming: boolean
}

@Entry
@Component
struct ChatPage {
  @State inputText: string = ''
  @State messages: ChatMessage[] = []
  @State isProcessing: boolean = false
  @State errorMsg: string = ''
  @State selectedModel: string = 'deepseek-chat'
  @State showModelPicker: boolean = false
  @State showApiKeyDialog: boolean = false
  @State apiKeyInput: string = ''

  private client: StreamingLLMClient = new StreamingLLMClient()
  private history: Array<[string, string]> = []

  async aboutToAppear() {
    await this.client.init(getContext(this))
    const p = await preferences.getPreferences(getContext(this), 'agent_prefs')
    const saved = await p.get('model_name', 'deepseek-chat') as string
    this.selectedModel = saved
  }

  build() {
    Stack() {
      Column() {
        // Top Bar
        Row() {
          Text('🤖 AI 手机智能体').fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
          Blank()
          Row() {
            Text(this.selectedModel.substring(0, 12)).fontSize(11).fontColor(Color.White).maxLines(1)
            Text(' ▼').fontSize(10).fontColor(Color.White)
          }
          .onClick(() => { this.showModelPicker = true })
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(12).backgroundColor('#FFFFFF20')
        }
        .width('100%').height(56).backgroundColor('#6366F1').padding({ left: 16, right: 16 })

        // Messages
        List() {
          if (this.messages.length === 0) {
            ListItem() {
              Text('👋 你好！我是你的手机智能助手。\n\n可以聊天提问、执行手机任务。')
                .fontSize(14).fontColor('#94A3B8').padding(16)
            }
          }
          ForEach(this.messages, (msg: ChatMessage, idx: number) => {
            ListItem() {
              Row() {
                if (!msg.isUser) { Text('🤖').fontSize(16).margin({ right: 8 }) }
                Column() {
                  if (msg.isThinking) {
                    Text('thinking...').fontSize(12).fontColor('#64748B').fontStyle(FontStyle.Italic)
                  } else {
                    Text(msg.text || '...')
                      .fontSize(14).fontColor(msg.isUser ? Color.White : '#E2E8F0')
                      .padding(12).borderRadius(12)
                      .backgroundColor(msg.isUser ? '#6366F1' : '#1E293B')
                      .constraintSize({ maxWidth: '80%' })
                    if (msg.isStreaming) { Text('▌').fontSize(14).fontColor('#6366F1') }
                  }
                }
                if (msg.isUser) { Text('👤').fontSize(16).margin({ left: 8 }) }
              }
              .width('100%')
              .justifyContent(msg.isUser ? FlexAlign.End : FlexAlign.Start)
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            }
          }, (msg: ChatMessage, idx: number) => idx.toString())
        }
        .layoutWeight(1).backgroundColor('#0F172A')

        // Error
        if (this.errorMsg) {
          Row() {
            Text(this.errorMsg).fontSize(12).fontColor(Color.White).layoutWeight(1)
            Button('关闭').fontSize(12).backgroundColor(Color.Transparent)
              .onClick(() => { this.errorMsg = '' })
          }
          .padding(12).backgroundColor('#EF4444').margin(8).borderRadius(8)
        }

        // Input
        Row() {
          TextInput({ placeholder: '告诉我你想做什么...', text: this.inputText })
            .layoutWeight(1).height(44).backgroundColor('#1E293B').borderRadius(8)
            .onChange((v: string) => { this.inputText = v }).enabled(!this.isProcessing)

          if (this.isProcessing) {
            Button('⏹').fontSize(16).fontColor(Color.White)
              .backgroundColor('#EF4444').width(44).height(44).borderRadius(22)
              .onClick(() => { this.isProcessing = false })
          } else {
            Button('➤').fontSize(16).fontColor(Color.White)
              .backgroundColor('#6366F1').width(44).height(44).borderRadius(22)
              .onClick(() => { this.sendCommand() })
          }
        }
        .width('100%').padding(12)
      }
      .width('100%').height('100%').backgroundColor('#0F172A')

      // Model Picker
      if (this.showModelPicker) {
        Column() {
          Column() {
            Text('选择模型').fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White).padding(16)
            List() {
              ForEach(MODELS, (m: { name: string, provider: string, endpoint: string }) => {
                ListItem() {
                  Row() {
                    Radio({ value: m.name, group: 'model' }).checked(m.name === this.selectedModel)
                    Column() {
                      Text(m.name).fontSize(14).fontColor(Color.White)
                      Text(`${m.provider} · ${m.endpoint}`).fontSize(10).fontColor('#64748B')
                    }.margin({ left: 8 }).layoutWeight(1)
                  }
                  .padding(12)
                  .onClick(() => { this.selectModel(m.name) })
                }
              }, (m: { name: string }) => m.name)
            }
            .layoutWeight(1)
            Button('关闭').onClick(() => { this.showModelPicker = false }).margin(16)
          }
          .width('100%').height('55%').backgroundColor('#1E293B')
          .borderRadius({ topLeft: 16, topRight: 16 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.End)
        .onClick(() => { this.showModelPicker = false })
      }

      // API Key Dialog
      if (this.showApiKeyDialog) {
        Column() {
          Column() {
            Text('配置 API Key').fontSize(18).fontColor(Color.White).padding(24)
            Text(`为 ${this.selectedModel} 配置`).fontSize(12).fontColor('#94A3B8').padding({ bottom: 12 })
            TextInput({ placeholder: '输入 API Key', text: this.apiKeyInput })
              .width('100%').height(44).backgroundColor('#334155').borderRadius(8)
              .onChange((v: string) => { this.apiKeyInput = v })
            Row() {
              Button('取消').onClick(() => { this.showApiKeyDialog = false })
              Button('保存').onClick(() => { this.saveApiKey() }).margin({ left: 16 })
            }.margin({ top: 24 })
          }
          .width('80%').padding(16).backgroundColor('#1E293B').borderRadius(16)
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
        .backgroundColor('#00000080')
        .onClick(() => { this.showApiKeyDialog = false })
      }
    }
    .width('100%').height('100%')
  }

  sendCommand() {
    const cmd = this.inputText.trim()
    if (!cmd) return
    this.history.push(['user', cmd])
    this.messages.push({ text: cmd, isUser: true, isThinking: false, isStreaming: false })
    this.messages.push({ text: '', isUser: false, isThinking: true, isStreaming: false })
    this.inputText = ''
    this.isProcessing = true; this.errorMsg = ''
    this.client.setModel(this.selectedModel)

    this.client.streamChat(cmd, this.history, (event: StreamEvent) => {
      if (event.type === StreamEvent.CHUNK) {
        const idx = this.messages.findIndex(m => m.isThinking || m.isStreaming)
        if (idx >= 0) this.messages[idx] = {
          text: event.fullText, isUser: false, isThinking: false, isStreaming: true
        }
      }
      if (event.type === StreamEvent.DONE) {
        this.isProcessing = false
        this.history.push(['assistant', event.delta])
        const di = this.messages.findIndex(m => m.isThinking || m.isStreaming)
        if (di >= 0) this.messages[di] = {
          text: event.delta, isUser: false, isThinking: false, isStreaming: false
        }
      }
      if (event.type === StreamEvent.ERROR) {
        this.isProcessing = false; this.errorMsg = event.message
        this.messages = this.messages.filter(m => !m.isThinking && !m.isStreaming)
      }
    })
  }

  selectModel(name: string) {
    this.showModelPicker = false
    if (name !== 'deepseek-chat') {
      this.selectedModel = name
      this.showApiKeyDialog = true
    } else {
      this.selectedModel = name
      this.client.setModel(name)
    }
  }

  async saveApiKey() {
    if (this.apiKeyInput) {
      this.client.setApiKey(this.apiKeyInput)
      this.client.setModel(this.selectedModel)
      const p = await preferences.getPreferences(getContext(this), 'agent_prefs')
      await p.put('api_key_' + this.selectedModel, this.apiKeyInput)
      await p.put('api_key', this.apiKeyInput)
      await p.put('model_name', this.selectedModel)
      await p.flush()
      promptAction.showToast({ message: `${this.selectedModel} 已配置` })
    }
    this.showApiKeyDialog = false
  }
}
