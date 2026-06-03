import { Task, TaskStatus, Step, createTask, generateId } from '../models/Task'
import { LLMRepository } from '../data/LLMRepository'
import { TaskStore } from '../data/TaskStore'

/**
 * 核心用例：处理用户命令，调用 LLM 生成任务计划。
 * 镜像 Android 端 ProcessCommandUseCase
 */
export class ProcessCommandUseCase {
  private llmRepo: LLMRepository
  private taskStore: TaskStore

  constructor(llmRepo: LLMRepository, taskStore: TaskStore) {
    this.llmRepo = llmRepo
    this.taskStore = taskStore
  }

  async execute(command: string, availableApps: string[]): Promise<Task> {
    // 1. 创建 PLANNING 状态的任务
    const task = createTask(command)
    await this.taskStore.save(task)

    // 2. 调用 LLM 生成计划
    const planDto = await this.llmRepo.planTask(command, availableApps)

    // 3. 转换为 Domain 模型
    const steps: Step[] = planDto.steps.map((dto, index) => ({
      id: generateId(),
      taskId: task.id,
      orderIndex: dto.order,
      actionType: dto.action,
      targetApp: dto.target,
      targetElement: dto.target,
      params: dto.params || {}
    }))

    const readyTask: Task = {
      ...task,
      llmRawResponse: JSON.stringify(planDto),
      intent: planDto.intent,
      confidence: planDto.confidence,
      steps: steps,
      status: TaskStatus.READY,
      appsInvolved: [...new Set(steps.map(s => s.targetApp || '').filter(Boolean))]
    }

    await this.taskStore.save(readyTask)
    return readyTask
  }
}
