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

interface RegisterResponse {
  code: number;
  message?: string;
  cookie?: string;
}

interface DialogResult {
  index: number;
}

/**
 * 注册页面
 */
@Component
export struct RegisterPage {
  @Consume('pageInfos') pageInfos: NavPathStack
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @State phone: string = ''
  @State captcha: string = ''
  @State password: string = ''
  @State nickname: string = ''
  @State countdown: number = 0
  @State isSendingCaptcha: boolean = false
  @State isRegistering: boolean = false
  @State currentStep: number = 1 // 1: 手机号验证码, 2: 设置密码和昵称
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
          Text('注册账号')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.reverse'))
            .padding({ top: 50, bottom: 20 })

          if (this.currentStep === 1) {
            // 第一步：手机号和验证码
            this.PhoneInput()
            this.CaptchaInput()

            Button('下一步')
              .width('80%')
              .height(50)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .backgroundColor($r('app.color.app_red'))
              .enabled(!this.isSendingCaptcha && this.phone.length === 11 && this.captcha.length === 4)
              .stateEffect(!this.isSendingCaptcha)
              .onClick(() => this.verifyPhoneAndCaptcha())
          } else {
            // 第二步：密码和昵称
            this.PasswordInput()
            this.NicknameInput()

            Button('注册')
              .width('80%')
              .height(50)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .backgroundColor($r('app.color.app_red'))
              .enabled(!this.isRegistering && this.password.length >= 6 && this.nickname.length > 0)
              .stateEffect(!this.isRegistering)
              .onClick(() => this.handleRegister())

            if (this.isRegistering) {
              LoadingProgress()
                .width(30)
                .height(30)
                .color($r('app.color.app_red'))
            }
          }

          // 网页登录选项
          Row() {
            Text('注册遇到问题？')
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
            Button(this.currentStep === 1 ? '返回' : '上一步')
              .backgroundColor(Color.Transparent)
              .fontColor($r('app.color.reverse'))
              .onClick(() => {
                if (this.currentStep === 1) {
                  this.pageInfos.pop()
                } else {
                  this.currentStep = 1
                }
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
    .title('注册')
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

  @Builder
  PasswordInput() {
    Column({ space: 10 }) {
      Text('设置密码')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.reverse'))
        .alignSelf(ItemAlign.Start)

      TextInput({ placeholder: '请设置登录密码（6-16位）' })
        .type(InputType.Password)
        .maxLength(16)
        .width('100%')
        .height(50)
        .borderRadius(10)
        .backgroundColor($r('app.color.main'))
        .onChange((value) => {
          this.password = value
        })
    }
    .width('80%')
  }

  @Builder
  NicknameInput() {
    Column({ space: 10 }) {
      Text('设置昵称')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.reverse'))
        .alignSelf(ItemAlign.Start)

      TextInput({ placeholder: '请设置您的昵称' })
        .maxLength(30)
        .width('100%')
        .height(50)
        .borderRadius(10)
        .backgroundColor($r('app.color.main'))
        .onChange((value) => {
          this.nickname = value
        })
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
   * 验证手机号和验证码
   */
  async verifyPhoneAndCaptcha() {
    if (this.phone.length !== 11) {
      ToastUtil.showToast('请输入正确的手机号码')
      return
    }

    if (this.captcha.length < 4) {
      ToastUtil.showToast('请输入验证码')
      return
    }

    try {
      const rootUrl = await getApiUrl()
      const url = `${rootUrl}/captcha/verify?phone=${this.phone}&captcha=${this.captcha}&timestamp=${new Date().getTime()}`
      const request = new HttpRequest(url)
      const data = await request.Request(false)

      // 验证验证码
      const response = data.result as CaptchaResponse

      if (response && response.code === 200) {
        // 验证码正确，进入下一步
        this.currentStep = 2
      } else {
        const errorMsg = response && response.message ? response.message : '未知错误'
        ToastUtil.showToast(`验证码错误: ${errorMsg}`)
      }
    } catch (error) {
      LogUtil.error('验证验证码出错: ' + JSON.stringify(error))
      ToastUtil.showToast('验证验证码出错，请检查网络连接')
    }
  }

  /**
   * 注册处理
   */
  async handleRegister() {
    if (this.password.length < 6) {
      ToastUtil.showToast('密码长度至少为6位')
      return
    }

    if (this.nickname.length === 0) {
      ToastUtil.showToast('请输入昵称')
      return
    }

    this.isRegistering = true

    try {
      const rootUrl = await getApiUrl()
      const url = `${rootUrl}/register/cellphone?phone=${this.phone}&password=${encodeURIComponent(this.password)}&captcha=${this.captcha}&nickname=${encodeURIComponent(this.nickname)}&timestamp=${new Date().getTime()}`
      const request = new HttpRequest(url)
      const data = await request.Request(false)

      // 安全地访问响应数据
      const response = data.result as RegisterResponse

      if (response && response.code === 200) {
        // 注册成功处理
        if (response.cookie) {
          let cookie = response.cookie
          cookie = extractCookie(cookie)
          cookie = cookie + '; OS=pc'
          AppStorage.setOrCreate(StorageConstants.COOKIE, cookie)
          const result = await getLoginStatus(cookie)
          if (result) {
            ToastUtil.showToast('注册成功并已登录!')
            this.pageInfos.pop()
          } else {
            ToastUtil.showToast('注册成功但登录状态获取失败，请手动登录')
            this.pageInfos.replacePathByName('PhoneLogin', null)
          }
        } else {
          ToastUtil.showToast('注册成功!请登录')
          this.pageInfos.replacePathByName('PhoneLogin', null)
        }
      } else {
        const errorMsg = response && response.message ? response.message : '未知错误'
        ToastUtil.showToast(`注册失败: ${errorMsg}`)

        // 如果提示有风险或者已被注册
        if(errorMsg.includes('已注册') || errorMsg.includes('被占用')) {
          // 提示去登录
          promptAction.showDialog({
            title: '注册提示',
            message: '该手机号已注册，是否直接登录？',
            buttons: [
              {
                text: '取消',
                color: '#808080'
              },
              {
                text: '去登录',
                color: '#ff176b81'
              }
            ]
          })
            .then((result: DialogResult) => {
              if(result.index === 1) {
                this.pageInfos.replacePathByName('PhoneLogin', null)
              }
            })
            .catch((err: Error) => {
              LogUtil.error('对话框显示错误: ' + err.message)
            })
        }
        // 增加对风险提示的处理
        else if(errorMsg.includes('风险') || errorMsg.includes('异常')) {
          // 提示尝试网页登录
          promptAction.showDialog({
            title: '注册提示',
            message: '当前注册存在风险，建议尝试使用网页注册',
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
      LogUtil.error('注册出错: ' + JSON.stringify(error))
      ToastUtil.showToast('注册出错，请检查网络连接')
    } finally {
      this.isRegistering = false
    }
  }
}