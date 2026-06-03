import { http } from '@kit.NetworkKit'
import { preferences } from '@kit.ArkData'

export class StreamEvent {
  static readonly THINKING = 'thinking'
  static readonly CHUNK = 'chunk'
  static readonly DONE = 'done'
  static readonly ERROR = 'error'
  type: string = ''
  delta: string = ''
  fullText: string = ''
  message: string = ''
}

export class ParsedResponse {
  mode: string = 'chat'
  reply: string = ''
  rawText: string = ''
}

export const MODELS: Array<{ name: string, endpoint: string, provider: string }> = [
  { name: 'deepseek-chat', endpoint: 'https://api.deepseek.com', provider: 'DeepSeek' },
  { name: 'deepseek-reasoner', endpoint: 'https://api.deepseek.com', provider: 'DeepSeek' },
  { name: 'gpt-4o-mini', endpoint: 'https://api.openai.com', provider: 'OpenAI' },
  { name: 'gpt-4o', endpoint: 'https://api.openai.com', provider: 'OpenAI' },
  { name: 'claude-3.5-haiku', endpoint: 'https://api.anthropic.com', provider: 'Anthropic' },
  { name: 'claude-sonnet-4-6', endpoint: 'https://api.anthropic.com', provider: 'Anthropic' },
  { name: 'gemini-2.0-flash', endpoint: 'https://generativelanguage.googleapis.com', provider: 'Google' }
]

export class StreamingLLMClient {
  private prefs: preferences.Preferences | null = null
  private model: string = 'deepseek-chat'
  private apiKey: string = ''

  async init(context: Context): Promise<void> {
    this.prefs = await preferences.getPreferences(context, 'agent_prefs')
    this.model = await this.prefs.get('model_name', 'deepseek-chat') as string
    this.apiKey = await this.prefs.get('api_key', '') as string
    // 加载模型专属 Key
    const modelKey = await this.prefs.get('api_key_' + this.model, '') as string
    if (modelKey) this.apiKey = modelKey
  }

  setModel(name: string) { this.model = name }

  async loadModelKey(name: string): Promise<void> {
    if (!this.prefs) return
    const key = await this.prefs.get('api_key_' + name, '') as string
    if (key) this.apiKey = key
  }

  setApiKey(key: string) { this.apiKey = key }

  async streamChat(userMsg: string, history: Array<[string, string]>,
                   callback: (event: StreamEvent) => void): Promise<void> {
    if (!this.apiKey) {
      callback({ type: StreamEvent.ERROR, message: '未配置API Key' } as StreamEvent)
      return
    }

    const modelInfo = MODELS.find(m => m.name === this.model) || MODELS[0]
    const sysPrompt = '你是智能手机助手，能聊天也能帮执行手机任务。用中文回复，支持Markdown。'

    let msgs = `{"role":"system","content":"${sysPrompt}"}`
    const recentHistory = history.length > 10 ? history.slice(history.length - 10) : history
    for (const [role, content] of recentHistory) {
      const esc = content.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n')
      msgs += `,{"role":"${role}","content":"${esc}"}`
    }
    const escUser = userMsg.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n')
    msgs += `,{"role":"user","content":"${escUser}"}`
    const body = `{"model":"${this.model}","messages":[${msgs}],"stream":false}`

    callback({ type: StreamEvent.THINKING } as StreamEvent)

    const req = http.createHttp()
    try {
      const resp = await req.request(`${modelInfo.endpoint}/v1/chat/completions`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${this.apiKey}` },
        extraData: body,
        expectDataType: http.HttpDataType.STRING
      })

      if (resp.responseCode !== 200) {
        const errMsg = `API ${resp.responseCode}: ${(resp.result as string).substring(0, 200)}`
        callback({ type: StreamEvent.ERROR, message: errMsg } as StreamEvent)
        return
      }

      // 非流式：解析完整响应
      const text = resp.result as string
      try {
        const obj = JSON.parse(text)
        const content = obj.choices?.[0]?.message?.content || ''
        if (content) {
          // 模拟逐字显示
          let displayed = ''
          for (let i = 0; i < content.length; i++) {
            displayed += content[i]
            if (i % 3 === 0 || i === content.length - 1) {
              callback({ type: StreamEvent.CHUNK, delta: content[i], fullText: displayed } as StreamEvent)
            }
          }
          callback({ type: StreamEvent.CHUNK, delta: '', fullText: displayed } as StreamEvent)
          const parsed = parseResponse(content)
          callback({ type: StreamEvent.DONE, fullText: content, delta: parsed.reply } as StreamEvent)
        } else {
          callback({ type: StreamEvent.ERROR, message: '空响应' } as StreamEvent)
        }
      } catch (_) {
        // 非 JSON 响应，直接当文本
        if (text) {
          callback({ type: StreamEvent.CHUNK, delta: text, fullText: text } as StreamEvent)
          callback({ type: StreamEvent.DONE, fullText: text, delta: text } as StreamEvent)
        } else {
          callback({ type: StreamEvent.ERROR, message: '空响应' } as StreamEvent)
        }
      }
    } catch (e) {
      callback({ type: StreamEvent.ERROR, message: `请求失败: ${e.message}` } as StreamEvent)
    } finally {
      req.destroy()
    }
  }
}

function parseResponse(text: string): ParsedResponse {
  const modeM = text.match(/"mode"\s*:\s*"(chat|task)"/)
  if (modeM) {
    const replyM = text.match(/"reply"\s*:\s*"((?:[^"\\]|\\.)*)"/)
    return { mode: modeM[1], reply: replyM?.[1]?.replace(/\\n/g, '\n') || text, rawText: text }
  }
  return { mode: 'chat', reply: text, rawText: text }
}
