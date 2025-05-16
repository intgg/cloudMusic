import { ToastUtil } from '@pura/harmony-utils';
import Constants from '../../common/constants/Constants';

@Component
export struct AdminLoginPage {
  @Consume('pageInfos') pageInfos: NavPathStack
  @State username: string = ''
  @State password: string = ''
  @State isLoggingIn: boolean = false

  // 简单的管理员验证逻辑 - 实际应用中应使用更安全的验证方式
  private validateAdmin(): boolean {
    return this.username === 'admin' && this.password === 'admin123';
  }

  build() {
    NavDestination() {
      Column({ space: 30 }) {
        Text('管理员登录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.reverse'))
          .padding({ top: 50, bottom: 20 })

        Image($r('app.media.ic_user_portrait'))
          .width(80)
          .height(80)
          .fillColor($r('app.color.app_red'))

        // 用户名输入
        Column({ space: 10 }) {
          Text('用户名')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.reverse'))
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: '请输入管理员用户名' })
            .width('100%')
            .height(50)
            .borderRadius(10)
            .backgroundColor($r('app.color.main'))
            .onChange((value) => {
              this.username = value
            })
        }
        .width('80%')

        // 密码输入
        Column({ space: 10 }) {
          Text('密码')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.reverse'))
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: '请输入管理员密码' })
            .type(InputType.Password)
            .width('100%')
            .height(50)
            .borderRadius(10)
            .backgroundColor($r('app.color.main'))
            .onChange((value) => {
              this.password = value
            })
        }
        .width('80%')

        Button('登录')
          .width('80%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('app.color.app_red'))
          .enabled(!this.isLoggingIn)
          .stateEffect(!this.isLoggingIn)
          .onClick(() => {
            this.handleLogin()
          })

        if (this.isLoggingIn) {
          LoadingProgress()
            .width(30)
            .height(30)
            .color($r('app.color.app_red'))
        }

        // 返回按钮
        Row() {
          Button('返回')
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.reverse'))
            .onClick(() => {
              this.pageInfos.pop()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 20 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
      .backgroundColor($r('app.color.background'))
    }
    .title('管理员登录')
    .backgroundColor($r('app.color.background'))
  }

  handleLogin() {
    this.isLoggingIn = true;

    // 模拟登录延迟
    setTimeout(() => {
      if (this.validateAdmin()) {
        ToastUtil.showToast('管理员登录成功');
        // 导航到管理员控制台
        this.pageInfos.pushPathByName('AdminPage', null);
      } else {
        ToastUtil.showToast('用户名或密码错误');
      }
      this.isLoggingIn = false;
    }, 1000);
  }
}