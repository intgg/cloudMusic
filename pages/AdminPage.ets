import { promptAction } from '@kit.ArkUI';
import { ToastUtil, LogUtil } from '@pura/harmony-utils';
import Constants from '../common/constants/Constants';
import UserService, { AdminUser } from '../common/utils/DB/UserService';
import SongService, { AdminSong } from '../common/utils/DB/SongService';


@Component
export struct AdminPage {
  @Consume('pageInfos') pageInfos: NavPathStack
  private tabsController: TabsController = new TabsController()

  // 调试状态
  @State isLoaded: boolean = false
  @State errorMessage: string = ''

  // 用户管理状态
  @State users: AdminUser[] = []
  @State filteredUsers: AdminUser[] = []
  @State searchKeyword: string = ''
  @State isEditing: boolean = false
  @State isViewing: boolean = false
  @State newUser: AdminUser = { id: '', username: '', password: '', status: 'active', createdAt: '' }
  @State currentUser: AdminUser = { id: '', username: '', password: '', status: 'active', createdAt: '' }

  // 对话框控制器
  userDialogController: CustomDialogController = new CustomDialogController({
    builder: this.UserDialogBuilder,
    autoCancel: true
  })

  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: this.DeleteDialogBuilder,
    autoCancel: true
  })

  // 用户服务实例
  private userService: UserService = new UserService(getContext(this));


  async aboutToAppear() {
    try {
      // 从数据库加载用户
      this.isLoaded = false;
      this.users = await this.userService.getAllUsers();
      this.filteredUsers = this.users.slice();
      this.isLoaded = true;

      // 显示加载成功提示
      promptAction.showToast({
        message: "管理员页面加载成功",
        duration: 3000
      });
    } catch(error) {
      this.errorMessage = "初始化失败：" + JSON.stringify(error);
      promptAction.showToast({
        message: "页面加载出错",
        duration: 3000
      });
    }
  }

  build() {
    NavDestination() {
      // 添加错误检查和状态检查
      if (this.errorMessage) {
        Column() {
          Text("加载错误")
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .padding(20)

          Text(this.errorMessage)
            .fontSize(16)
            .padding(20)
            .width('90%')

          Button("返回")
            .onClick(() => {
              this.pageInfos.pop()
            })
            .margin(20)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
      } else if (!this.isLoaded) {
        // 加载状态
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)

          Text("加载中...")
            .fontSize(16)
            .padding(20)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.background'))
      } else {
        // 正常内容
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
              // 用户管理标签页内容
              Scroll() {
                Column({ space: 15 }) {
                  // 搜索和操作栏
                  Row({ space: 10 }) {
                    Search({ placeholder: '搜索用户...', value: this.searchKeyword })
                      .width('70%')
                      .height(40)
                      .onChange((value) => {
                        this.searchKeyword = value
                        this.filterUsers()
                      })

                    Button('添加用户')
                      .height(40)
                      .backgroundColor($r('app.color.app_red'))
                      .width('25%')
                      .onClick(() => this.openAddUserDialog())
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .padding({ bottom: 10 })

                  // 用户列表
                  Column() {
                    // 表头
                    Row() {
                      Text('ID').width('15%').fontWeight(FontWeight.Bold)
                      Text('用户名').width('30%').fontWeight(FontWeight.Bold)
                      Text('状态').width('20%').fontWeight(FontWeight.Bold)
                      Text('操作').width('35%').fontWeight(FontWeight.Bold)
                    }
                    .width('100%')
                    .padding(10)
                    .backgroundColor($r('app.color.main'))
                    .borderRadius(5)

                    // 用户列表项
                    List() {
                      ForEach(this.filteredUsers, (user: AdminUser) => {
                        ListItem() {
                          Row() {
                            Text(user.id).width('15%')
                            Text(user.username).width('30%')
                            Text(this.getStatusText(user.status))
                              .width('20%')
                              .fontColor(this.getStatusColor(user.status))
                            Row({ space: 8 }) {
                              Button('查看')
                                .height(30)
                                .fontSize(12)
                                .backgroundColor(Color.Blue)
                                .onClick(() => this.viewUser(user))
                              Button('编辑')
                                .height(30)
                                .fontSize(12)
                                .backgroundColor(Color.Orange)
                                .onClick(() => this.editUser(user))
                              Button('删除')
                                .height(30)
                                .fontSize(12)
                                .backgroundColor(Color.Red)
                                .onClick(() => this.confirmDeleteUser(user.id))
                            }
                            .width('35%')
                          }
                          .width('100%')
                          .padding(10)
                          .borderRadius(8)
                          .backgroundColor($r('app.color.background'))
                          .margin({ bottom: 8 })
                        }
                      })
                    }
                    .width('100%')

                    if (this.filteredUsers.length === 0) {
                      Text('没有找到匹配的用户')
                        .padding(20)
                        .fontColor(Color.Gray)
                    }
                  }
                  .width('100%')
                }
                .width('100%')
                .padding(15)
              }
              .width('100%')
              .height('100%')
            }.tabBar("用户管理")

            TabContent() {
              // 内容管理标签页
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
    }
    .title('管理员控制台')
    .backgroundColor($r('app.color.background'))
  }

  // 用户对话框构建器
  @Builder UserDialogBuilder() {
    Column({ space: 15 }) {
      Text(this.isEditing ? '编辑用户' : (this.isViewing ? '查看用户' : '添加用户'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Column({ space: 10 }) {
        Text('ID').fontSize(14).alignSelf(ItemAlign.Start)
        TextInput({ text: this.isEditing || this.isViewing ? this.currentUser.id : this.newUser.id })
          .width('100%')
          .enabled(false)
      }

      Column({ space: 10 }) {
        Text('用户名').fontSize(14).alignSelf(ItemAlign.Start)
        TextInput({ text: this.isEditing || this.isViewing ? this.currentUser.username : this.newUser.username })
          .width('100%')
          .enabled(!this.isViewing)
          .onChange((value: string) => {
            if (this.isEditing) {
              this.currentUser.username = value
            } else {
              this.newUser.username = value
            }
          })
      }

      Column({ space: 10 }) {
        Text('密码').fontSize(14).alignSelf(ItemAlign.Start)
        TextInput({ text: this.isEditing || this.isViewing ? this.currentUser.password : this.newUser.password })
          .width('100%')
          .type(InputType.Password)
          .enabled(!this.isViewing)
          .onChange((value: string) => {
            if (this.isEditing) {
              this.currentUser.password = value
            } else {
              this.newUser.password = value
            }
          })
      }

      if (this.isEditing || !this.isViewing) {
        Column({ space: 10 }) {
          Text('状态').fontSize(14).alignSelf(ItemAlign.Start)
          Select([
            { value: '活跃' },
            { value: '未激活' },
            { value: '已禁用' }
          ])
            .selected(this.getStatusIndex(this.isEditing ? this.currentUser.status : this.newUser.status))
            .value(this.getStatusText(this.isEditing ? this.currentUser.status : this.newUser.status))
            .width('100%')
            .onSelect((index: number) => {
              const status = this.getStatusFromIndex(index)
              if (this.isEditing) {
                this.currentUser.status = status
              } else {
                this.newUser.status = status
              }
            })
        }
      } else {
        Column({ space: 10 }) {
          Text('状态').fontSize(14).alignSelf(ItemAlign.Start)
          Text(this.getStatusText(this.currentUser.status))
            .fontColor(this.getStatusColor(this.currentUser.status))
            .fontSize(16)
            .width('100%')
        }
      }

      Row({ space: 20 }) {
        Button('取消')
          .width('45%')
          .onClick(() => {
            this.userDialogController.close()
          })

        if (this.isViewing) {
          Button('确定')
            .width('45%')
            .backgroundColor($r('app.color.app_red'))
            .onClick(() => {
              this.userDialogController.close()
            })
        } else {
          Button('保存')
            .width('45%')
            .backgroundColor($r('app.color.app_red'))
            .onClick(() => {
              this.saveUser()
            })
        }
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('90%')
    .padding(20)
    .backgroundColor($r('app.color.background'))
    .borderRadius(10)
  }

  // 删除确认对话框构建器
  @Builder DeleteDialogBuilder() {
    Column({ space: 15 }) {
      Text('确认删除')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Text('确定要删除这个用户吗？此操作不可撤销。')
        .fontSize(16)
        .margin({ top: 10, bottom: 20 })

      Row({ space: 20 }) {
        Button('取消')
          .width('45%')
          .onClick(() => {
            this.deleteDialogController.close()
          })

        Button('删除')
          .width('45%')
          .backgroundColor(Color.Red)
          .onClick(() => {
            this.deleteUser()
          })
      }
      .width('100%')
    }
    .width('90%')
    .padding(20)
    .backgroundColor($r('app.color.background'))
    .borderRadius(10)
  }

  // 用户管理辅助方法
  filterUsers(): void {
    if (!this.searchKeyword) {
      this.filteredUsers = this.users.slice()
      return
    }

    const keyword = this.searchKeyword.toLowerCase()
    this.filteredUsers = this.users.filter(user =>
    user.id.toLowerCase().includes(keyword) ||
    user.username.toLowerCase().includes(keyword)
    )
  }

  getStatusText(status: string): string {
    switch(status) {
      case 'active': return '活跃'
      case 'inactive': return '未激活'
      case 'banned': return '已禁用'
      default: return status
    }
  }

  getStatusColor(status: string): ResourceColor | Color {
    switch(status) {
      case 'active': return Color.Green
      case 'inactive': return Color.Orange
      case 'banned': return Color.Red
      default: return $r('app.color.reverse')
    }
  }

  openAddUserDialog(): void {
    // 生成新ID (简单实现，数据库会自动生成)
    this.newUser = {
      id: '',
      username: '',
      password: '',
      status: 'active',
      createdAt: new Date().toISOString().split('T')[0]
    }
    this.isEditing = false
    this.isViewing = false

    // 使用控制器打开对话框
    this.userDialogController = new CustomDialogController({
      builder: this.UserDialogBuilder,
      autoCancel: true
    })
    this.userDialogController.open()
  }

  viewUser(user: AdminUser): void {
    // 复制用户对象 - 不使用展开运算符
    this.currentUser.id = user.id;
    this.currentUser.username = user.username;
    this.currentUser.password = user.password;
    this.currentUser.status = user.status;
    this.currentUser.createdAt = user.createdAt;

    this.isEditing = false
    this.isViewing = true

    // 使用控制器打开对话框
    this.userDialogController = new CustomDialogController({
      builder: this.UserDialogBuilder,
      autoCancel: true
    })
    this.userDialogController.open()
  }

  editUser(user: AdminUser): void {
    // 复制用户对象 - 不使用展开运算符
    this.currentUser.id = user.id;
    this.currentUser.username = user.username;
    this.currentUser.password = user.password;
    this.currentUser.status = user.status;
    this.currentUser.createdAt = user.createdAt;

    this.isEditing = true
    this.isViewing = false

    // 使用控制器打开对话框
    this.userDialogController = new CustomDialogController({
      builder: this.UserDialogBuilder,
      autoCancel: true
    })
    this.userDialogController.open()
  }

  confirmDeleteUser(userId: string): void {
    // 保存要删除的用户ID
    const foundUser = this.users.find(user => user.id === userId);
    if (foundUser) {
      this.currentUser.id = foundUser.id;
      this.currentUser.username = foundUser.username;
      this.currentUser.password = foundUser.password;
      this.currentUser.status = foundUser.status;
      this.currentUser.createdAt = foundUser.createdAt;
    }

    // 使用控制器打开确认对话框
    this.deleteDialogController = new CustomDialogController({
      builder: this.DeleteDialogBuilder,
      autoCancel: true
    })
    this.deleteDialogController.open()
  }

  // 明确声明返回类型
  async deleteUser(): Promise<void> {
    try {
      const success = await this.userService.deleteUser(this.currentUser.id);
      if (success) {
        // 删除用户并更新列表
        this.users = this.users.filter(user => user.id !== this.currentUser.id);
        this.filterUsers();
        this.deleteDialogController.close();
        ToastUtil.showToast('用户已从数据库中删除');
      } else {
        ToastUtil.showToast('删除用户失败');
      }
    } catch (e) {
      LogUtil.error('删除用户出错: ' + JSON.stringify(e));
      ToastUtil.showToast('删除用户失败: ' + e.message);
    }
  }

  // 明确声明返回类型
  async saveUser(): Promise<void> {
    if (this.isEditing) {
      // 编辑现有用户
      if (!this.validateUser(this.currentUser)) return;

      try {
        const success = await this.userService.updateUser(this.currentUser);
        if (success) {
          const index = this.users.findIndex(u => u.id === this.currentUser.id);
          if (index !== -1) {
            // 不使用展开运算符，直接赋值
            this.users[index].id = this.currentUser.id;
            this.users[index].username = this.currentUser.username;
            this.users[index].password = this.currentUser.password;
            this.users[index].status = this.currentUser.status;
            this.users[index].createdAt = this.currentUser.createdAt;
          }
          this.filterUsers();
          this.userDialogController.close();
          ToastUtil.showToast('用户信息已更新并保存到数据库');
        } else {
          ToastUtil.showToast('更新用户失败');
        }
      } catch (e) {
        LogUtil.error('更新用户出错: ' + JSON.stringify(e));
        ToastUtil.showToast('更新用户失败: ' + e.message);
      }
    } else {
      // 添加新用户
      if (!this.validateUser(this.newUser)) return;

      try {
        const newId = await this.userService.addUser(this.newUser);
        if (newId) {
          this.newUser.id = newId;
          // 不使用展开运算符，创建新对象
          const userToAdd: AdminUser = {
            id: this.newUser.id,
            username: this.newUser.username,
            password: this.newUser.password,
            status: this.newUser.status,
            createdAt: this.newUser.createdAt
          };
          this.users.push(userToAdd);
          this.filterUsers();
          this.userDialogController.close();
          ToastUtil.showToast('新用户已添加并保存到数据库');
        } else {
          ToastUtil.showToast('添加用户失败');
        }
      } catch (e) {
        LogUtil.error('添加用户出错: ' + JSON.stringify(e));
        ToastUtil.showToast('添加用户失败: ' + e.message);
      }
    }
  }

  validateUser(user: AdminUser): boolean {
    if (!user.username) {
      ToastUtil.showToast('用户名不能为空')
      return false
    }

    if (!user.password) {
      ToastUtil.showToast('密码不能为空')
      return false
    }

    if (!this.isEditing && this.users.some(u => u.username === user.username)) {
      ToastUtil.showToast('用户名已存在')
      return false
    }

    return true
  }

  getStatusIndex(status: string): number {
    switch(status) {
      case 'active': return 0
      case 'inactive': return 1
      case 'banned': return 2
      default: return 0
    }
  }

  getStatusFromIndex(index: number): 'active' | 'inactive' | 'banned' {
    switch(index) {
      case 0: return 'active'
      case 1: return 'inactive'
      case 2: return 'banned'
      default: return 'active'
    }
  }

  // 内容管理Builder方法
  @Builder ContentManagement() {
    Column({ space: 15 }) {
      // 精选歌单管理
      Column() {
        Text("精选歌单管理")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)
          .fontColor($r('app.color.reverse'))

        // 其它内容...
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

        // 其它内容...
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


}