import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('AI Mobile Agent - EntryAbility onCreate')
  }

  onDestroy(): void {
    console.info('EntryAbility onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/ChatPage', (err) => {
      if (err.code) {
        console.error(`Failed to load content: ${JSON.stringify(err)}`)
        return
      }
      console.info('Content loaded successfully')
    })
  }

  onWindowStageDestroy(): void {
    console.info('WindowStage destroyed')
  }
}
