import { SetPlayQuality } from '../components/settings/SetPlayQuality'
import { SetApiUrl } from '../components/settings/SetApiUrl'
import { RemoveCache } from '../components/settings/RemoveCache'
import Constants from '../common/constants/Constants'
import { SongClickAction } from '../components/settings/SongClickAction'

/**
 * 设置页面
 */
@Component
export struct SettingsPage {
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0
  @StorageProp('topRectHeight') topRectHeight: number = 0
  @Consume('pageInfos') pageInfos: NavPathStack

  build() {
    NavDestination() {
      Stack() {
        Column({ space: 10 }) {
          List({ space: 10 }) {
            ListItem() {
              Column({ space: 20 }) {
                SetPlayQuality()
              }
              .padding(10)
            }.listItemStyle()
            ListItem() {
              Column({ space: 20 }) {
                SongClickAction()
                SetApiUrl()
              }
              .padding(10)
            }.listItemStyle()
            ListItem() { RemoveCache().padding({ left: 10, right: 10 }) }.listItemStyle()
            ListItem() { Divider().padding({ left: 20, right: 20 }) }
          }
          .scrollBar(BarState.Auto)
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .backgroundColor($r('app.color.background'))
    .title('设置')
  }

  @Styles listItemStyle() {
    .backgroundColor($r('app.color.main'))
    .borderRadius(Constants.RADIUS_CARD)
    .margin({ left: 20, right: 20 })
    .padding({ left: Constants.PADDING_EDGE_DEFAULT, right: Constants.PADDING_EDGE_DEFAULT })
    .constraintSize({
      minHeight: 60,
      maxHeight: '100%'
    })
  }
}

