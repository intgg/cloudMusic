import { ToastUtil } from '@pura/harmony-utils';
import Constants from '../common/constants/Constants';  // 修正了路径

@Component
export struct AdminPage {
  @Consume('pageInfos') pageInfos: NavPathStack
  private tabsController: TabsController = new TabsController()
  @State scrollOffset: number = 0

  build() {
    NavDestination() {
      Column() {
        // 顶部标题
        Text("管理员控制台")
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.reverse'))
          .padding({top: 20, bottom: 20})

        // 主要功能区域
        Tabs({ controller: this.tabsController }) {
          TabContent() {
            // 使用Scroll包裹Column，而不是给Column设置scrollable属性
            Scroll() {
              this.UserManagement()
            }
          }.tabBar("用户管理")

          TabContent() {
            // 使用Scroll包裹Column，而不是给Column设置scrollable属性
            Scroll() {
              this.ContentManagement()
            }
          }.tabBar("内容管理")
        }
        .barMode(BarMode.Fixed)
        .barWidth('100%')
        .barHeight(50)
        .animationDuration(300)
        .layoutWeight(1)
      }
      .width('100%')
      .backgroundColor($r('app.color.background'))
    }
    .title('管理员控制台')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  UserManagement() {
    Column({ space: 15 }) {
      // 用户统计卡片
      Column() {
        Text("用户统计")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .fontColor($r('app.color.reverse'))

        Row() {
          this.StatCard("注册用户", "1,245", $r('app.color.app_red'))
          this.StatCard("活跃用户", "876", Color.Green)
        }
        .width('100%')
        .padding({top: 10})

        // 活跃度分析
        Column({ space: 10 }) {
          Text("活跃度分析")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .fontColor($r('app.color.reverse'))

          Row() {
            Column() {
              Text("每日活跃")
                .fontSize(14)
                .fontColor(Color.Gray)
              Text("312")
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.reverse'))
            }
            .layoutWeight(1)

            Column() {
              Text("周活跃")
                .fontSize(14)
                .fontColor(Color.Gray)
              Text("756")
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.reverse'))
            }
            .layoutWeight(1)

            Column() {
              Text("月活跃")
                .fontSize(14)
                .fontColor(Color.Gray)
              Text("876")
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.reverse'))
            }
            .layoutWeight(1)
          }
        }
        .width('100%')
        .padding({top: 15})

        // 用户行为分析
        Column({ space: 10 }) {
          Text("用户行为")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .fontColor($r('app.color.reverse'))

          Row() {
            this.BehaviorCard("播放量", "8,756", "↑12%", true)
            this.BehaviorCard("搜索次数", "2,134", "↓5%", false)
          }
          .width('100%')

          Row() {
            this.BehaviorCard("歌单创建", "342", "↑7%", true)
            this.BehaviorCard("下载歌曲", "1,542", "↑15%", true)
          }
          .width('100%')
        }
        .width('100%')
        .padding({top: 15})
      }
      .padding(15)
      .borderRadius(10)
      .backgroundColor($r('app.color.main'))
      .width('90%')

      // 操作按钮
      Button("刷新数据")
        .backgroundColor($r('app.color.app_red'))
        .width('90%')
        .height(50)
        .fontSize(16)
        .onClick(() => {
          ToastUtil.showToast("数据刷新中...")
        })
    }
    .width('100%')
    .padding(15)
  }

  @Builder
  ContentManagement() {
    Column({ space: 15 }) {
      // 精选歌单管理
      Column() {
        Text("精选歌单管理")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .fontColor($r('app.color.reverse'))

        // 现有精选歌单
        Column({ space: 10 }) {
          Text("当前精选歌单")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .fontColor($r('app.color.reverse'))
            .padding({top: 10, bottom: 5})

          this.PlaylistItem("流行热歌榜", "编辑时间: 2025-05-10", true)
          this.PlaylistItem("经典民谣", "编辑时间: 2025-05-08", true)
          this.PlaylistItem("独立音乐精选", "编辑时间: 2025-05-05", false)
        }
        .width('100%')

        // 操作按钮
        Row({ space: 10 }) {
          Button("添加歌单")
            .backgroundColor(Color.Green)
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .onClick(() => {
              ToastUtil.showToast("添加歌单功能开发中...")
            })

          Button("推送更新")
            .backgroundColor($r('app.color.app_red'))
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .onClick(() => {
              ToastUtil.showToast("推送更新功能开发中...")
            })
        }
        .width('100%')
        .padding({top: 15})
      }
      .padding(15)
      .borderRadius(10)
      .backgroundColor($r('app.color.main'))
      .width('90%')

      // 歌单推荐系统设置
      Column() {
        Text("推荐系统设置")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .fontColor($r('app.color.reverse'))

        Column({ space: 15 }) {
          Row() {
            Text("启用每日推荐")
              .fontSize(14)
              .fontColor($r('app.color.reverse'))
            Toggle({ type: ToggleType.Switch, isOn: true })
              .selectedColor($r('app.color.app_red'))
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            Text("推荐歌单数量")
              .fontSize(14)
              .fontColor($r('app.color.reverse'))
            Counter() {
              Text('6')
                .fontSize(14)
                .fontColor($r('app.color.reverse'))
            }
            .onInc(() => {})
            .onDec(() => {})
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .padding({top: 10})
      }
      .padding(15)
      .borderRadius(10)
      .backgroundColor($r('app.color.main'))
      .width('90%')

      // 保存按钮
      Button("保存设置")
        .backgroundColor($r('app.color.app_red'))
        .width('90%')
        .height(50)
        .fontSize(16)
        .onClick(() => {
          ToastUtil.showToast("设置已保存")
        })
    }
    .width('100%')
    .padding(15)
  }

  @Builder
  StatCard(title: string, value: string, color: ResourceColor | Color) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor(Color.Gray)
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .layoutWeight(1)
    .padding(10)
    .borderRadius(8)
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  BehaviorCard(title: string, value: string, change: string, isIncrease: boolean) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor(Color.Gray)
      Row({ space: 5 }) {
        Text(value)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.reverse'))
        Text(change)
          .fontSize(14)
          .fontColor(isIncrease ? Color.Green : Color.Red)
      }
    }
    .layoutWeight(1)
    .padding(10)
    .borderRadius(8)
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  PlaylistItem(title: string, subtitle: string, isPublished: boolean) {
    Row() {
      Column({ space: 5 }) {
        Text(title)
          .fontSize(16)
          .fontColor($r('app.color.reverse'))
        Text(subtitle)
          .fontSize(12)
          .fontColor(Color.Gray)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row({ space: 10 }) {
        Text(isPublished ? "已推送" : "未推送")
          .fontSize(12)
          .fontColor(isPublished ? Color.Green : Color.Gray)

        Button({ type: ButtonType.Circle }) {
          // 修改为使用现有的图标
          Image($r('app.media.ic_public_settings_filled'))
            .width(18)
            .height(18)
            .fillColor($r('app.color.reverse'))
        }
        .backgroundColor(Color.Transparent)
        .width(30)
        .height(30)
        .onClick(() => {
          ToastUtil.showToast("编辑功能开发中...")
        })
      }
    }
    .width('100%')
    .padding(10)
    .borderRadius(8)
    .backgroundColor($r('app.color.background'))
  }
}