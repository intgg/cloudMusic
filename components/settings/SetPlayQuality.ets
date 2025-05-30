import Constants from "../../common/constants/Constants"
import { PlayConstants } from "../../common/constants/PlayConstants"
import { StorageConstants } from "../../common/constants/StorageConstants"
import { QualityType } from "../../common/entities/SongDownload"
import PreferencesUtils from "../../common/utils/data/PreferencesUtils"

/**
 * 设置播放音质
 */
@Component
export struct SetPlayQuality {
  @StorageLink(StorageConstants.PLAY_QUALITY) playQuality:QualityType = "standard"
  @State selected:number | undefined = 0

  async aboutToAppear(): Promise<void> {
    this.selected = await AppStorage.get(StorageConstants.PLAY_QUALITY)
  }
  build() {
    Row() {
      Text('在线播放音质').LeftText()
      Select([{ value: '标准' }, { value: '高' }, { value: '极高' }, { value: '无损' }])
        .selectedOptionFontColor($r('app.color.app_red'))
        .selected(this.selected)
        .value(this.selected ? PlayConstants.QUALITY_NAME[this.selected] : '标准')
        .width(100)
        .height(Constants.HEIGHT_SELECT)
        .onSelect((index: number) => {
          AppStorage.setOrCreate(StorageConstants.PLAY_QUALITY,index)
          PreferencesUtils.putPreferenceValue('Settings', StorageConstants.PLAY_QUALITY, index)
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

@Extend(Text) function LeftText() {
  .fontSize(Constants.FONT_SIZE_COMMON)
  .fontWeight(FontWeight.Bold)
}