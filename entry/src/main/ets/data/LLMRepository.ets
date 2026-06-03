import { http } from '@kit.NetworkKit'
import { Task } from '../models/Task'

/**
 * LLM API 仓库（直连 DeepSeek，兼容 OpenAI 格式）。
 * 镜像 Android 端 LLMRepositoryImpl
 */
interface TaskPlanDto {
  intent: string
  confidence: number
  steps: { order: number; action: string; target?: string; params?: Record<string, string> }[]
}

const SYSTEM_PROMPT = `你是一个手机任务规划助手。将用户的自然语言命令分解为有序执行步骤。
可用动作: open_app, tap, type, swipe, search, share_to, confirm, wait, go_back, go_home
输出格式: {"intent":"...", "confidence":0.95, "steps":[{"order":1, "action":"open_app", "target":"com.example.app"}]}`

export class LLMRepository {
  private apiKey: string = '<API_KEY>'
  private baseUrl: string = 'https://api.deepseek.com'

  setApiKey(key: string) { this.apiKey = key }
  setBaseUrl(url: string) { this.baseUrl = url }

  async planTask(command: string, availableApps: string[]): Promise<TaskPlanDto> {
    const request = http.createHttp()
    try {
      const response = await request.request(
        `${this.baseUrl}/v1/chat/completions`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          extraData: JSON.stringify({
            model: 'deepseek-chat',
            messages: [
              { role: 'system', content: SYSTEM_PROMPT },
              { role: 'user', content: command }
            ],
            response_format: { type: 'json_object' },
            temperature: 0.1,
            max_tokens: 2000
          })
        }
      )

      const body = JSON.parse(response.result as string)
      const content = body.choices?.[0]?.message?.content || '{}'
      // Extract JSON from possible markdown wrapper
      const jsonMatch = content.match(/\{[\s\S]*\}/)
      const json = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(content)

      return {
        intent: json.intent || 'unknown',
        confidence: json.confidence || 0,
        steps: json.steps || []
      }
    } finally {
      request.destroy()
    }
  }
}
