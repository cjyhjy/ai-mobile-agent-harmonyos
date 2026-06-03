import { ProcessCommandUseCase } from '../usecases/ProcessCommandUseCase'
import { ExecuteTaskUseCase } from '../usecases/ExecuteTaskUseCase'
import { LLMRepository } from '../data/LLMRepository'
import { TaskStore } from '../data/TaskStore'
import { BasicStepExecutor } from '../execution/StepExecutor'
import { Task, TaskStatus } from '../models/Task'

/**
 * 主聊天页面 — 用户输入命令，展示计划，确认执行。
 * 镜像 Android 端 ChatScreen
 */
@Entry
@Component
struct ChatPage {
  @State inputText: string = ''
  @State messages: Message[] = []
  @State currentTask: Task | null = null
  @State isProcessing: boolean = false
  @State errorMsg: string = ''

  private processUseCase: ProcessCommandUseCase | null = null
  private executeUseCase: ExecuteTaskUseCase | null = null

  aboutToAppear() {
    const store = new TaskStore()
    const llm = new LLMRepository()
    this.processUseCase = new ProcessCommandUseCase(llm, store)
    this.executeUseCase = new ExecuteTaskUseCase(store)
  }

  build() {
    Column() {
      // Top bar
      Row() {
        Text('🤖 AI 手机智能体')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#6366F1')
      .padding({ left: 16, right: 16 })

      // Messages
      List() {
        ForEach(this.messages, (msg: Message) => {
          ListItem() {
            Row() {
              Text(msg.text)
                .fontSize(14)
                .fontColor(msg.isFromUser ? Color.White : Color.Black)
                .padding(12)
                .borderRadius(12)
                .backgroundColor(msg.isFromUser ? '#6366F1' : '#E2E8F0')
                .constraintSize({ maxWidth: '80%' })
            }
            .width('100%')
            .justifyContent(msg.isFromUser ? FlexAlign.End : FlexAlign.Start)
            .padding({ left: 16, right: 16, top: 4, bottom: 4 })
          }
        })

        // Task plan card
        if (this.currentTask) {
          ListItem() {
            Column() {
              Text(`📋 计划: ${this.currentTask.intent}`)
                .fontSize(14).fontWeight(FontWeight.Medium)
              Text(`${this.currentTask.steps.length} 步 | 置信度 ${Math.round(this.currentTask.confidence * 100)}%`)
                .fontSize(12).fontColor('#64748B')
              Button('确认执行')
                .margin({ top: 8 })
                .onClick(() => this.executeTask())
            }
            .padding(16)
            .backgroundColor('#F1F5F9')
            .borderRadius(12)
            .margin({ left: 16, right: 16 })
          }
        }
      }
      .layoutWeight(1)

      // Input bar
      Row() {
        TextInput({ placeholder: '告诉我你想做什么...', text: this.inputText })
          .layoutWeight(1)
          .height(48)
          .onChange((value: string) => { this.inputText = value })
        Button('发送')
          .margin({ left: 8 })
          .onClick(() => this.sendCommand())
          .enabled(!this.isProcessing)
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0F172A')
  }

  sendCommand() {
    const cmd = this.inputText.trim()
    if (!cmd || !this.processUseCase) return

    this.messages.push({ text: cmd, isFromUser: true })
    this.inputText = ''
    this.isProcessing = true

    this.processUseCase.execute(cmd, ['com.tencent.mm', 'com.android.gallery3d'])
      .then(task => {
        this.currentTask = task
        this.isProcessing = false
        this.messages.push({ text: `✅ 计划生成完毕，共 ${task.steps.length} 步`, isFromUser: false })
      })
      .catch(err => {
        this.errorMsg = err.message
        this.isProcessing = false
        this.messages.push({ text: `❌ ${err.message}`, isFromUser: false })
      })
  }

  executeTask() {
    if (!this.currentTask || !this.executeUseCase) return
    const executor = new BasicStepExecutor()
    this.executeUseCase.execute(this.currentTask.id, executor)
      .then(result => {
        const msg = result.success
          ? `✅ 任务完成！${result.completedSteps} 步，${result.totalDurationMs}ms`
          : `❌ 执行失败: ${result.error}`
        this.messages.push({ text: msg, isFromUser: false })
        this.currentTask = null
      })
  }
}

interface Message {
  text: string
  isFromUser: boolean
}
