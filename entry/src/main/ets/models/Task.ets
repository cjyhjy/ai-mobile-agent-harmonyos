/**
 * 领域模型：AI 任务。
 * 镜像 Android 端 com.example.aimobileagent.domain.model.Task
 */
export enum TaskStatus {
  PLANNING = 'PLANNING',
  READY = 'READY',
  RUNNING = 'RUNNING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED'
}

export enum StepStatus {
  PENDING = 'PENDING',
  RUNNING = 'RUNNING',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  SKIPPED = 'SKIPPED'
}

export interface Step {
  id: string
  taskId: string
  orderIndex: number
  actionType: string       // open_app | tap | type | swipe | search | share_to | confirm
  targetApp?: string
  targetElement?: string
  params: Record<string, string>
  status: StepStatus
  errorMessage?: string
  executionDurationMs?: number
}

export interface Task {
  id: string
  userCommand: string
  llmRawResponse: string
  intent: string
  confidence: number
  steps: Step[]
  status: TaskStatus
  createdAt: number
  completedAt?: number
  appsInvolved: string[]
}

export interface ExecutionResult {
  success: boolean
  completedSteps?: number
  totalDurationMs?: number
  error?: string
}

export function createTask(command: string): Task {
  return {
    id: generateId(),
    userCommand: command,
    llmRawResponse: '',
    intent: '',
    confidence: 0,
    steps: [],
    status: TaskStatus.PLANNING,
    createdAt: Date.now(),
    appsInvolved: []
  }
}

export function generateId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0
    const v = c === 'x' ? r : (r & 0x3 | 0x8)
    return v.toString(16)
  })
}
