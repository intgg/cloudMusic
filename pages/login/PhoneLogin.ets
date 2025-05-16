import { promptAction } from '@kit.ArkUI';
import { LogUtil, ToastUtil } from '@pura/harmony-utils';
import { HttpRequest } from '../../common/utils/request/HttpRequestUtils';
import { StorageConstants } from '../../common/constants/StorageConstants';
import { getApiUrl } from '../../common/functions/common/get';
import { getLoginStatus } from '../../api/loginApi';
import { extractCookie } from '../../common/functions/common/convert';
import Constants from '../../common/constants/Constants';

// 接口定义
interface CaptchaResponse {
  code: number;
  message?: string;
}

interface LoginResponse {
  code: number;
  cookie?: string;
  message?: string;
}

// 对话框结果接口
interface DialogResult {
  index: number;
}

/**
 * 手机验证码登录页面
 */
@Component
export struct PhoneLogin {
  @Consume('pageInfos') pageInfos: NavPathStack
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @State phone: string = ''
  @State captcha: string = ''
  @State countdown: number = 0
  @State isSendingCaptcha: boolean = false
  @State isLoggingIn: boolean = false
  private countdownTimer: number = -1

  aboutToDisappear() {
    // 清除倒计时
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column({ space: 30 }) {
          Text('手机号登录')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.reverse'))
            .padding({ top: 50, bottom: 20 })

          this.PhoneInput()
          this.CaptchaInput()

          Button('登录')
            .width('80%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.app_red'))
            .enabled(!this.isLoggingIn)
            .stateEffect(this.isLoggingIn ? false : true)
            .onClick(() => this.handleLogin())

          if (this.isLoggingIn) {
            LoadingProgress()
              .width(30)
              .height(30)
              .color($r('app.color.app_red'))
          }

          // 网页登录选项
          Row() {
            Text('遇到登录问题？')
              .fontSize(14)
              .fontColor(Color.Gray)

            Button('使用网页登录')
              .fontSize(14)
              .backgroundColor(Color.Transparent)
              .fontColor($r('app.color.app_red'))
              .onClick(() => {
                this.pageInfos.replacePathByName('WebLogin', null)
              })
          }
          .width('80%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 20 })

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
          .margin({ top: 10 })

        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20 })
      }
      .height('100%')
      .width('100%')
      .backgroundColor($r('app.color.background'))
    }
    .title('手机登录')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  PhoneInput() {
    Column({ space: 10 }) {
      Text('手机号')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.reverse'))
        .alignSelf(ItemAlign.Start)

      TextInput({ placeholder: '请输入手机号码' })
        .type(InputType.Number)
        .maxLength(11)
        .width('100%')
        .height(50)
        .borderRadius(10)
        .backgroundColor($r('app.color.main'))
        .onChange((value) => {
          this.phone = value
        })
    }
    .width('80%')
  }

  @Builder
  CaptchaInput() {
    Column({ space: 10 }) {
      Text('验证码')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.reverse'))
        .alignSelf(ItemAlign.Start)

      Row({ space: 10 }) {
        TextInput({ placeholder: '请输入验证码' })
          .type(InputType.Number)
          .maxLength(4)
          .width('60%')
          .height(50)
          .borderRadius(10)
          .backgroundColor($r('app.color.main'))
          .onChange((value) => {
            this.captcha = value
          })

        Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
          .width('40%')
          .height(50)
          .borderRadius(10)
          .fontSize(14)
          .backgroundColor(this.countdown > 0 ? Color.Gray : $r('app.color.app_red'))
          .enabled(this.countdown === 0 && !this.isSendingCaptcha && this.phone.length === 11)
          .stateEffect(this.countdown === 0 && !this.isSendingCaptcha)
          .onClick(() => this.sendCaptcha())
      }
      .width('100%')
    }
    .width('80%')
  }

  /**
   * 发送验证码
   */
  async sendCaptcha() {
    if (this.phone.length !== 11) {
      ToastUtil.showToast('请输入正确的手机号码')
      return
    }

    this.isSendingCaptcha = true

    try {
      const rootUrl = await getApiUrl()
      const url = `${rootUrl}/captcha/sent?phone=${this.phone}&timestamp=${new Date().getTime()}`
      const request = new HttpRequest(url)
      const data = await request.Request(false)

      // 安全地访问响应数据
      const response = data.result as CaptchaResponse

      if (response && response.code === 200) {
        ToastUtil.showToast('验证码已发送')
        // 开始倒计时60秒
        this.countdown = 60
        this.countdownTimer = setInterval(() => {
          this.countdown--
          if (this.countdown <= 0) {
            clearInterval(this.countdownTimer)
          }
        }, 1000)
      } else {
        const errorMsg = response && response.message ? response.message : '未知错误'
        ToastUtil.showToast(`发送失败: ${errorMsg}`)
      }
    } catch (error) {
      LogUtil.error('发送验证码出错: ' + JSON.stringify(error))
      ToastUtil.showToast('发送验证码出错，请检查网络连接')
    } finally {
      this.isSendingCaptcha = false
    }
  }

  /**
   * 验证码登录
   */
  async handleLogin() {
    if (this.phone.length !== 11) {
      ToastUtil.showToast('请输入正确的手机号码')
      return
    }

    if (this.captcha.length < 4) {
      ToastUtil.showToast('请输入验证码')
      return
    }

    this.isLoggingIn = true

    try {
      const rootUrl = await getApiUrl()
      const url = `${rootUrl}/login/cellphone?phone=${this.phone}&captcha=${this.captcha}&timestamp=${new Date().getTime()}`
      const request = new HttpRequest(url)
      const data = await request.Request(false)

      // 安全地访问响应数据
      const response = data.result as LoginResponse

      if (response && response.code === 200) {
        // 登录成功处理
        if (response.cookie) {
          let cookie = response.cookie
          cookie = extractCookie(cookie)
          cookie = cookie + '; OS=pc'
          AppStorage.setOrCreate(StorageConstants.COOKIE, cookie)
          const result = await getLoginStatus(cookie)
          if (result) {
            ToastUtil.showToast('登录成功!')
            this.pageInfos.pop()
          } else {
            ToastUtil.showToast('获取登录状态失败')
          }
        } else {
          ToastUtil.showToast('登录成功但未获取到Cookie')
        }
      } else {
        const errorMsg = response && response.message ? response.message : '未知错误'
        ToastUtil.showToast(`登录失败: ${errorMsg}`)

        // 如果提示有风险，建议使用网页登录
        if(errorMsg.includes('风险')) {
          // 使用对话框
          promptAction.showDialog({
            title: '登录提示',
            message: '当前登录存在风险，建议尝试使用网页登录',
            buttons: [
              {
                text: '取消',
                color: '#808080'
              },
              {
                text: '去网页登录',
                color: '#ff176b81'
              }
            ]
          })
            .then((result: DialogResult) => {
              if(result.index === 1) {
                this.pageInfos.replacePathByName('WebLogin', null)
              }
            })
            .catch((err: Error) => {
              LogUtil.error('对话框显示错误: ' + err.message)
            })
        }
      }
    } catch (error) {
      LogUtil.error('登录出错: ' + JSON.stringify(error))
      ToastUtil.showToast('登录出错，请检查网络连接')
    } finally {
      this.isLoggingIn = false
    }
  }
}