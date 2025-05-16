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

  // 歌曲管理状态
  @State songs: AdminSong[] = []
  @State filteredSongs: AdminSong[] = []
  @State songSearchKeyword: string = ''
  @State isEditingSong: boolean = false
  @State isViewingSong: boolean = false
  @State newSong: AdminSong = { id: '', name: '', artist: '', album: '', duration: '0:00', status: 'active' }
  @State currentSong: AdminSong = { id: '', name: '', artist: '', album: '', duration: '0:00', status: 'active' }

  // 对话框控制器 - 用户管理
  userDialogController: CustomDialogController = new CustomDialogController({
    builder: this.UserDialogBuilder,
    autoCancel: true
  })

  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: this.DeleteDialogBuilder,
    autoCancel: true
  })

  // 对话框控制器 - 歌曲管理
  songDialogController: CustomDialogController = new CustomDialogController({
    builder: this.SongDialogBuilder,
    autoCancel: true
  })

  deleteSongDialogController: CustomDialogController = new CustomDialogController({
    builder: this.DeleteSongDialogBuilder,
    autoCancel: true
  })

  // 服务实例
  private userService: UserService = new UserService(getContext(this));
  private songService: SongService = new SongService(getContext(this));


  async aboutToAppear() {
    try {
      // 从数据库加载用户和歌曲
      this.isLoaded = false;

      const results = await Promise.all([
        this.userService.getAllUsers(),
        this.songService.getAllSongs()
      ]);
      const users = results[0];
      const songs = results[1];

      // 然后继续使用这些变量
      this.users = users;
      this.filteredUsers = users.slice();
      this.songs = songs;
      this.filteredSongs = songs.slice();
      this.users = users;
      this.filteredUsers = users.slice();

      this.songs = songs;
      this.filteredSongs = songs.slice();

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

  // 歌曲对话框构建器
  @Builder SongDialogBuilder() {
    Column({ space: 15 }) {
      Text(this.isEditingSong ? '编辑歌曲' : (this.isViewingSong ? '查看歌曲' : '添加歌曲'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Column({ space: 10 }) {
        Text('ID').fontSize(14).alignSelf(ItemAlign.Start)
        TextInput({ text: this.isEditingSong || this.isViewingSong ? this.currentSong.id : this.newSong.id })
          .width('100%')
          .enabled(false)
      }

      Column({ space: 10 }) {
        Text('歌曲名').fontSize(14).alignSelf(ItemAlign.Start)
        TextInput({ text: this.isEditingSong || this.isViewingSong ? this.currentSong.name : this.newSong.name })
          .width('100%')
          .enabled(!this.isViewingSong)
          .onChange((value: string) => {
            if (this.isEditingSong) {
              this.currentSong.name = value
            } else {
              this.newSong.name = value
            }
          })
      }

      Column({ space: 10 }) {
        Text('歌手').fontSize(14).alignSelf(ItemAlign.Start)
        TextInput({ text: this.isEditingSong || this.isViewingSong ? this.currentSong.artist : this.newSong.artist })
          .width('100%')
          .enabled(!this.isViewingSong)
          .onChange((value: string) => {
            if (this.isEditingSong) {
              this.currentSong.artist = value
            } else {
              this.newSong.artist = value
            }
          })
      }

      Column({ space: 10 }) {
        Text('专辑').fontSize(14).alignSelf(ItemAlign.Start)
        TextInput({ text: this.isEditingSong || this.isViewingSong ? this.currentSong.album : this.newSong.album })
          .width('100%')
          .enabled(!this.isViewingSong)
          .onChange((value: string) => {
            if (this.isEditingSong) {
              this.currentSong.album = value
            } else {
              this.newSong.album = value
            }
          })
      }

      Column({ space: 10 }) {
        Text('时长').fontSize(14).alignSelf(ItemAlign.Start)
        TextInput({ text: this.isEditingSong || this.isViewingSong ? this.currentSong.duration : this.newSong.duration })
          .width('100%')
          .enabled(!this.isViewingSong)
          .onChange((value: string) => {
            if (this.isEditingSong) {
              this.currentSong.duration = value
            } else {
              this.newSong.duration = value
            }
          })
      }

      if (this.isEditingSong || !this.isViewingSong) {
        Column({ space: 10 }) {
          Text('状态').fontSize(14).alignSelf(ItemAlign.Start)
          Select([
            { value: '活跃' },
            { value: '隐藏' }
          ])
            .selected(this.getSongStatusIndex(this.isEditingSong ? (this.currentSong.status ?? 'active') : (this.newSong.status ?? 'active')))
            .value(this.getSongStatusText(this.isEditingSong ? (this.currentSong.status ?? 'active') : (this.newSong.status ?? 'active')))
            .width('100%')
            .onSelect((index: number) => {
              const status = this.getSongStatusFromIndex(index)
              if (this.isEditingSong) {
                this.currentSong.status = status
              } else {
                this.newSong.status = status
              }
            })
        }
      } else {
        Column({ space: 10 }) {
          Text('状态').fontSize(14).alignSelf(ItemAlign.Start)
          Text(this.getSongStatusText(this.currentSong.status ?? 'active'))
            .fontColor(this.getSongStatusColor(this.currentSong.status ?? 'active'))
            .fontSize(16)
            .width('100%')
        }
      }

      Row({ space: 20 }) {
        Button('取消')
          .width('45%')
          .onClick(() => {
            this.songDialogController.close()
          })

        if (this.isViewingSong) {
          Button('确定')
            .width('45%')
            .backgroundColor($r('app.color.app_red'))
            .onClick(() => {
              this.songDialogController.close()
            })
        } else {
          Button('保存')
            .width('45%')
            .backgroundColor($r('app.color.app_red'))
            .onClick(() => {
              this.saveSong()
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

  // 删除用户确认对话框构建器
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

  // 删除歌曲确认对话框构建器
  @Builder DeleteSongDialogBuilder() {
    Column({ space: 15 }) {
      Text('确认删除')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Text('确定要删除这首歌曲吗？此操作不可撤销。')
        .fontSize(16)
        .margin({ top: 10, bottom: 20 })

      Row({ space: 20 }) {
        Button('取消')
          .width('45%')
          .onClick(() => {
            this.deleteSongDialogController.close()
          })

        Button('删除')
          .width('45%')
          .backgroundColor(Color.Red)
          .onClick(() => {
            this.deleteSong()
          })
      }
      .width('100%')
    }
    .width('90%')
    .padding(20)
    .backgroundColor($r('app.color.background'))
    .borderRadius(10)
  }

  // 内容管理Builder方法
  @Builder ContentManagement() {
    Column({ space: 15 }) {
      // 搜索和操作栏
      Row({ space: 10 }) {
        Search({ placeholder: '搜索歌曲...', value: this.songSearchKeyword })
          .width('70%')
          .height(40)
          .onChange((value) => {
            this.songSearchKeyword = value
            this.filterSongs()
          })

        Button('添加歌曲')
          .height(40)
          .backgroundColor($r('app.color.app_red'))
          .width('25%')
          .onClick(() => this.openAddSongDialog())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ bottom: 10 })

      // 歌曲列表
      Column() {
        // 表头
        Row() {
          Text('ID').width('10%').fontWeight(FontWeight.Bold)
          Text('歌曲名').width('25%').fontWeight(FontWeight.Bold)
          Text('歌手').width('20%').fontWeight(FontWeight.Bold)
          Text('专辑').width('20%').fontWeight(FontWeight.Bold)
          Text('操作').width('25%').fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding(10)
        .backgroundColor($r('app.color.main'))
        .borderRadius(5)

        // 歌曲列表项
        List() {
          ForEach(this.filteredSongs, (song: AdminSong) => {
            ListItem() {
              Row() {
                Text(song.id).width('10%').textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(song.name).width('25%').textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(song.artist).width('20%').textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(song.album).width('20%').textOverflow({ overflow: TextOverflow.Ellipsis })
                Row({ space: 8 }) {
                  Button('查看')
                    .height(30)
                    .fontSize(12)
                    .backgroundColor(Color.Blue)
                    .onClick(() => this.viewSong(song))
                  Button('编辑')
                    .height(30)
                    .fontSize(12)
                    .backgroundColor(Color.Orange)
                    .onClick(() => this.editSong(song))
                  Button('删除')
                    .height(30)
                    .fontSize(12)
                    .backgroundColor(Color.Red)
                    .onClick(() => this.confirmDeleteSong(song.id))
                }
                .width('25%')
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

        if (this.filteredSongs.length === 0) {
          Text('没有找到匹配的歌曲')
            .padding(20)
            .fontColor(Color.Gray)
        }
      }
      .width('100%')

      // 导入默认歌曲按钮
      Button("导入默认歌曲")
        .backgroundColor($r('app.color.app_red'))
        .width('90%')
        .height(50)
        .fontSize(16)
        .onClick(() => {
          this.importDefaultSongs()
        })
    }
    .width('100%')
    .padding(15)
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

  // 歌曲管理辅助方法
  filterSongs(): void {
    if (!this.songSearchKeyword) {
      this.filteredSongs = this.songs.slice()
      return
    }

    const keyword = this.songSearchKeyword.toLowerCase()
    this.filteredSongs = this.songs.filter(song =>
    song.id.toString().includes(keyword) ||
    song.name.toLowerCase().includes(keyword) ||
    song.artist.toLowerCase().includes(keyword) ||
    song.album.toLowerCase().includes(keyword)
    )
  }

  getSongStatusText(status: string): string {
    switch(status) {
      case 'active': return '活跃'
      case 'hidden': return '隐藏'
      default: return status
    }
  }

  getSongStatusColor(status: string): ResourceColor | Color {
    switch(status) {
      case 'active': return Color.Green
      case 'hidden': return Color.Gray
      default: return $r('app.color.reverse')
    }
  }

  openAddSongDialog(): void {
    this.newSong = {
      id: '',
      name: '',
      artist: '',
      album: '',
      duration: '0:00',
      status: 'active'
    }
    this.isEditingSong = false
    this.isViewingSong = false

    this.songDialogController = new CustomDialogController({
      builder: this.SongDialogBuilder,
      autoCancel: true
    })
    this.songDialogController.open()
  }

  viewSong(song: AdminSong): void {
    this.currentSong.id = song.id;
    this.currentSong.name = song.name;
    this.currentSong.artist = song.artist;
    this.currentSong.album = song.album;
    this.currentSong.duration = song.duration || '0:00';
    this.currentSong.status = song.status || 'active';

    this.isEditingSong = false
    this.isViewingSong = true

    this.songDialogController = new CustomDialogController({
      builder: this.SongDialogBuilder,
      autoCancel: true
    })
    this.songDialogController.open()
  }

  editSong(song: AdminSong): void {
    this.currentSong.id = song.id;
    this.currentSong.name = song.name;
    this.currentSong.artist = song.artist;
    this.currentSong.album = song.album;
    this.currentSong.duration = song.duration || '0:00';
    this.currentSong.status = song.status || 'active';

    this.isEditingSong = true
    this.isViewingSong = false

    this.songDialogController = new CustomDialogController({
      builder: this.SongDialogBuilder,
      autoCancel: true
    })
    this.songDialogController.open()
  }

  confirmDeleteSong(songId: string): void {
    const foundSong = this.songs.find(song => song.id === songId);
    if (foundSong) {
      this.currentSong.id = foundSong.id;
      this.currentSong.name = foundSong.name;
      this.currentSong.artist = foundSong.artist;
      this.currentSong.album = foundSong.album;
      this.currentSong.duration = foundSong.duration || '0:00';
      this.currentSong.status = foundSong.status || 'active';
    }

    this.deleteSongDialogController = new CustomDialogController({
      builder: this.DeleteSongDialogBuilder,
      autoCancel: true
    })
    this.deleteSongDialogController.open()
  }

  async deleteSong(): Promise<void> {
    try {
      const success = await this.songService.deleteSong(this.currentSong.id);
      if (success) {
        this.songs = this.songs.filter(song => song.id !== this.currentSong.id);
        this.filterSongs();
        this.deleteSongDialogController.close();
        ToastUtil.showToast('歌曲已从数据库中删除');
      } else {
        ToastUtil.showToast('删除歌曲失败');
      }
    } catch (e) {
      LogUtil.error('删除歌曲出错: ' + JSON.stringify(e));
      ToastUtil.showToast('删除歌曲失败: ' + e.message);
    }
  }

  async saveSong(): Promise<void> {
    if (this.isEditingSong) {
      if (!this.validateSong(this.currentSong)) return;

      try {
        const success = await this.songService.updateSong(this.currentSong);
        if (success) {
          const index = this.songs.findIndex(s => s.id === this.currentSong.id);
          if (index !== -1) {
            this.songs[index].name = this.currentSong.name;
            this.songs[index].artist = this.currentSong.artist;
            this.songs[index].album = this.currentSong.album;
            this.songs[index].duration = this.currentSong.duration;
            this.songs[index].status = this.currentSong.status;
          }
          this.filterSongs();
          this.songDialogController.close();
          ToastUtil.showToast('歌曲信息已更新并保存到数据库');
        } else {
          ToastUtil.showToast('更新歌曲失败');
        }
      } catch (e) {
        LogUtil.error('更新歌曲出错: ' + JSON.stringify(e));
        ToastUtil.showToast('更新歌曲失败: ' + e.message);
      }
    } else {
      if (!this.validateSong(this.newSong)) return;

      try {
        const newId = await this.songService.addSong(this.newSong);
        if (newId) {
          this.newSong.id = newId;
          const songToAdd: AdminSong = {
            id: this.newSong.id,
            name: this.newSong.name,
            artist: this.newSong.artist,
            album: this.newSong.album,
            duration: this.newSong.duration,
            status: this.newSong.status
          };
          this.songs.push(songToAdd);
          this.filterSongs();
          this.songDialogController.close();
          ToastUtil.showToast('新歌曲已添加并保存到数据库');
        } else {
          ToastUtil.showToast('添加歌曲失败');
        }
      } catch (e) {
        LogUtil.error('添加歌曲出错: ' + JSON.stringify(e));
        ToastUtil.showToast('添加歌曲失败: ' + e.message);
      }
    }
  }

  validateSong(song: AdminSong): boolean {
    if (!song.name) {
      ToastUtil.showToast('歌曲名不能为空')
      return false
    }

    if (!song.artist) {
      ToastUtil.showToast('歌手不能为空')
      return false
    }

    return true
  }

  getSongStatusIndex(status: string): number {
    switch(status) {
      case 'active': return 0
      case 'hidden': return 1
      default: return 0
    }
  }

  getSongStatusFromIndex(index: number): 'active' | 'hidden' {
    switch(index) {
      case 0: return 'active'
      case 1: return 'hidden'
      default: return 'active'
    }
  }

  async importDefaultSongs(): Promise<void> {
    try {
      ToastUtil.showToast('开始导入默认歌曲...');
      const success = await this.songService.importDefaultSongs();
      if (success) {
        // 重新加载歌曲列表
        this.songs = await this.songService.getAllSongs();
        this.filteredSongs = this.songs.slice();
        ToastUtil.showToast('默认歌曲导入成功');
      } else {
        ToastUtil.showToast('导入默认歌曲失败');
      }
    } catch (e) {
      LogUtil.error('导入默认歌曲出错: ' + JSON.stringify(e));
      ToastUtil.showToast('导入默认歌曲失败: ' + e.message);
    }
  }
}