import { Task, Step, TaskStatus, StepStatus, ExecutionResult } from '../models/Task'
import { TaskStore } from '../data/TaskStore'
import { StepExecutor } from '../execution/StepExecutor'

/**
 * Agent 循环：Observe→Think→Act→Verify
 * 镜像 Android 端 ExecuteTaskUseCase
 */
export class ExecuteTaskUseCase {
  private taskStore: TaskStore

  constructor(taskStore: TaskStore) {
    this.taskStore = taskStore
  }

  async execute(taskId: string, executor: StepExecutor): Promise<ExecutionResult> {
    const task = await this.taskStore.getById(taskId)
    if (!task) return { success: false, error: 'Task not found' }

    task.status = TaskStatus.RUNNING
    await this.taskStore.save(task)

    const sortedSteps = [...task.steps].sort((a, b) => a.orderIndex - b.orderIndex)
    const startTime = Date.now()

    for (const step of sortedSteps) {
      step.status = StepStatus.RUNNING
      await this.updateStep(task, step)

      // OBSERVE + THINK - Safety check for dangerous operations
      if (['confirm', 'share_to'].includes(step.actionType)) {
        // Safety gate: check for payment screens
        const dangerous = await executor.checkSafety()
        if (dangerous) {
          step.status = StepStatus.FAILED
          step.errorMessage = 'Safety stop: payment/private screen detected'
          await this.updateStep(task, step)
          return { success: false, error: step.errorMessage }
        }
      }

      // ACT
      const stepStart = Date.now()
      let result = await executor.execute(step)
      let retries = 0

      while (!result.success && retries < 2) {
        retries++
        await executor.recover(step, result.error || 'unknown')
        result = await executor.execute(step)
      }

      // VERIFY
      if (result.success) {
        step.status = StepStatus.SUCCESS
        step.executionDurationMs = Date.now() - stepStart
      } else {
        step.status = StepStatus.FAILED
        step.errorMessage = result.error
        await this.updateStep(task, step)
        // Skip remaining
        for (const remaining of sortedSteps.filter(s => s.orderIndex > step.orderIndex)) {
          remaining.status = StepStatus.SKIPPED
          await this.updateStep(task, remaining)
        }
        task.status = TaskStatus.FAILED
        task.completedAt = Date.now()
        await this.taskStore.save(task)
        return { success: false, error: result.error }
      }

      await this.updateStep(task, step)
    }

    task.status = TaskStatus.COMPLETED
    task.completedAt = Date.now()
    await this.taskStore.save(task)

    return {
      success: true,
      completedSteps: sortedSteps.length,
      totalDurationMs: Date.now() - startTime
    }
  }

  private async updateStep(task: Task, step: Step): Promise<void> {
    const idx = task.steps.findIndex(s => s.id === step.id)
    if (idx >= 0) task.steps[idx] = step
    await this.taskStore.save(task)
  }
}
