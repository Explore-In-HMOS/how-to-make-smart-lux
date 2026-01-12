// Index.ets
import { sensor } from '@kit.SensorServiceKit';
import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State lux: number = 0;
  @StorageLink('context') context: common.UIAbilityContext | undefined = undefined;

  aboutToAppear(): void {
    if (!this.context) {
      console.error('Context is not available');
      return;
    }

    this.startBackgroundRunning();
    this.initializeSensor();
  }

  aboutToDisappear(): void {
    this.stopBackgroundRunning();
    this.stopSensor();
  }

  private initializeSensor(): void {
    try {
      sensor.on(sensor.SensorId.AMBIENT_LIGHT, (data: sensor.LightResponse) => {
        this.lux = data.intensity;
        console.info('Lux value:', this.lux);

        let brightness = Math.round((this.lux / 1000) * 100);
        brightness = Math.max(10, Math.min(100, brightness));

        console.info(`Calculated Brightness: ${brightness}%`);
      }, { interval: 1000000 });

      console.info('Ambient light sensor started successfully');
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      console.error(`Failed to initialize sensor: ${e.code} - ${e.message}`);
    }
  }

  private stopSensor(): void {
    try {
      sensor.off(sensor.SensorId.AMBIENT_LIGHT);
      console.info('Ambient light sensor stopped');
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      console.error(`Failed to stop sensor: ${e.code} - ${e.message}`);
    }
  }

private async startBackgroundRunning(): Promise<void> {
  if (!this.context) {
      return;
  } 

  const wantAgentInfo: wantAgent.WantAgentInfo = {
    wants: [
      {
        bundleName: this.context.abilityInfo.bundleName,
        abilityName: this.context.abilityInfo.name
      }
    ],
    actionType: wantAgent.OperationType.START_ABILITY,
    requestCode: 0,
    wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
  };

  try {
    const agent = await wantAgent.getWantAgent(wantAgentInfo);
    await backgroundTaskManager.startBackgroundRunning(
      this.context,
      backgroundTaskManager.BackgroundMode.DATA_TRANSFER,
      agent
    );
  } catch (error) {
    const e = error as BusinessError;
    console.error(`Failed: ${e.code} - ${e.message}`);
  }
}


  private async stopBackgroundRunning(): Promise<void> {
    if (!this.context) {
      console.error('Context is undefined, cannot stop background running');
      return;
    }

    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
      console.info('Background running stopped successfully');
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      console.error(`Failed to stop background running: ${e.code} - ${e.message}`);
    }
  }

  private getThemeColor(): Color {
    if (this.lux < 50) {
      return Color.Black;
    } else if (this.lux < 500) {
       return Color.Gray;
    } else {
      return Color.White;
    }
  }

private getTextMessage(): string {
  if (this.lux < 50) {
    return '🌑 Dark environment...';
  } else if (this.lux < 500) {
    return '🌤️ Moderate light level.';
  } else {
    return '☀️ As bright as daylight!';
  }
}


  build() {
    Column() {
        Text(`💡 Ambient Light: ${this.lux.toFixed(1)} lux`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.lux < 50 ? Color.White : Color.Black)
        .margin({ top: 40, bottom: 20 })

      Text(this.getTextMessage())
        .fontSize(20)
        .fontColor(this.lux < 50 ? Color.White : Color.Black)
        .margin({ bottom: 10 })

      Text(`Brightness Level: ${Math.round((this.lux / 1000) * 100)}%`)
        .fontSize(16)
        .fontColor(this.lux < 50 ? Color.White : Color.Black)
        .opacity(0.8)
    }
    .backgroundColor(this.getThemeColor())
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}