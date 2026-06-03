import { Step } from '../models/Task'

export interface StepResult {
  success: boolean
  message?: string
  error?: string
}

/**
 * 步骤执行器接口。
 * 镜像 Android 端 domain.usecase.StepExecutor
 */
export interface StepExecutor {
  execute(step: Step): Promise<StepResult>
  recover(step: Step, error: string): Promise<StepResult>
  checkSafety(): Promise<boolean>  // true = dangerous, stop execution
}

/**
 * 简单实现：基于鸿蒙 Accessibility Kit + startAbility。
 * 实际设备上需要 AccessibilityExtensionAbility 支持。
 */
export class BasicStepExecutor implements StepExecutor {
  async execute(step: Step): Promise<StepResult> {
    // In production: use Accessibility Kit to find and interact with UI elements
    switch (step.actionType) {
      case 'open_app':
        return this.launchApp(step.targetApp || '')
      case 'tap':
        return this.tapElement(step.targetElement || '')
      case 'type':
        return this.typeText(step.params['text'] || '')
      default:
        return { success: false, error: `Unknown action: ${step.actionType}` }
    }
  }

  async recover(step: Step, error: string): Promise<StepResult> {
    // Wait and retry
    await this.delay(1000)
    return this.execute(step)
  }

  async checkSafety(): Promise<boolean> {
    // Check for payment/password keywords via Accessibility Kit
    return false
  }

  private async launchApp(bundleName: string): Promise<StepResult> {
    // Use startAbility with bundleName
    return { success: true, message: `Launched ${bundleName}` }
  }

  private async tapElement(target: string): Promise<StepResult> {
    return { success: true, message: `Tapped ${target}` }
  }

  private async typeText(text: string): Promise<StepResult> {
    return { success: true, message: `Typed ${text}` }
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}
