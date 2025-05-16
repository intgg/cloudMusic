import { ToastUtil } from "@pura/harmony-utils"
import Constants from "../../common/constants/Constants"
import { createPlayList, getPlayLists } from "../../api/playListApi"
import { StorageConstants } from "../../common/constants/StorageConstants"

@CustomDialog
export struct AddPlayListDialog {
  @State isPrivacy: boolean = false
  @State name: string = ''
  @State isCreating: boolean = false
  @StorageProp(StorageConstants.IS_LOGGED) isLogged: boolean = false
  controller: CustomDialogController
  onSuccess?: () => void

  private async handleCreate() {
    if(!this.isLogged) {
      ToastUtil.showToast('请先登录')
      this.controller.close()
      return
    }

    if(this.name == '') {
      ToastUtil.showToast('歌单名不能为空')
      return
    } else if(this.name.length > 40) {
      ToastUtil.showToast('歌单名长度不能超过 40')
      return
    }

    this.isCreating = true
    try {
      const result = await createPlayList(this.name, this.isPrivacy)
      if(result) {
        ToastUtil.showToast('歌单创建成功')
        // 刷新歌单列表
        await getPlayLists(0)
        if(this.onSuccess) {
          this.onSuccess()
        }
        this.controller.close()
      } else {
        ToastUtil.showToast('歌单创建失败')
      }
    } catch(e) {
      ToastUtil.showToast('创建歌单出错: ' + e.message)
    } finally {
      this.isCreating = false
    }
  }

  build() {
    Scroll() {
      Column({ space: 30 }) {
        Text('新建歌单')
          .width('100%')
          .textAlign(TextAlign.Start)
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Medium)

        TextInput({
          placeholder: '请输入歌单名'
        })
          .width('100%')
          .onChange((value) => {
            this.name = value
          })

        Row() {
          Text('设为隐私歌单')
            .fontSize(Constants.FONT_SIZE_COMMON)
            .fontColor($r('app.color.reverse'))
          Toggle({ type: ToggleType.Switch, isOn: this.isPrivacy })
            .selectedColor($r('app.color.app_red'))
            .onChange((value) => {
              this.isPrivacy = value
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        if(this.isCreating) {
          Button() {
            Row({ space: 10 }) {
              LoadingProgress().width(20).color(Color.White)
              Text('创建中').fontColor(Color.White)
            }
          }
          .backgroundColor($r('app.color.app_red'))
          .width('100%')
        } else {
          Button('创 建')
            .backgroundColor($r('app.color.app_red'))
            .width('100%')
            .onClick(() => {
              this.handleCreate()
            })
        }
      }
      .padding(Constants.PADDING_EDGE_TEXT)
    }
    .width('100%')
    .constraintSize({
      maxWidth: 500,
      minHeight: 100,
      maxHeight: 800
    })
  }
}