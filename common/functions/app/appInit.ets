import { AppUtil, LogUtil, ToastUtil } from "@pura/harmony-utils"
import { getAnnouncement } from "../../../api/chenlvinApi"
import { Song, SongClass } from "../../entities/SongsResult"
import PlayQueueUtils from "../../utils/play/PlayQueueUtils"
import PreferencesUtils from "../../utils/data/PreferencesUtils"
import { StorageConstants } from "../../constants/StorageConstants"
import { notificationManager } from "@kit.NotificationKit"
import { resourceManager } from "@kit.LocalizationKit"
import { initSettings } from "./settings"
import { getLoginStatus } from "../../../api/loginApi"
import { PlayingPlayList, PlayList } from "../../entities/PlayList"
import { TopListItem } from "../../entities/TopList"
import { getLikeList } from "../../../api/songApi"
import { PersonalListItem } from "../../entities/Personalized"
import { pauseMusic, playQueue } from "../play/playControl"

/**
 * App初始化
 */
const TAG = '[appInit] '

export async function appInit() {
  AppStorage.setOrCreate(StorageConstants.APP_LOADING, true)
  await initSettings()
  await initPlayQueue()
  loadSavedSong()
  initPermission()
  initLocalData()
  getAnnouncement()
  await initUserInfo()
  AppStorage.setOrCreate(StorageConstants.APP_LOADING, false)
}

async function initPermission() {
  notificationManager.requestEnableNotification(AppUtil.getContext()).then(() => {
  })
}

export async function initUserInfo() {
  const cookie = await PreferencesUtils.getPreferenceValue<string>(StorageConstants.USER_PREF, StorageConstants.COOKIE, '')
  AppStorage.setOrCreate(StorageConstants.COOKIE, cookie)
  let isLogged = await getLoginStatus(cookie)
  if(!isLogged && cookie) {
    ToastUtil.showToast('登录状态失效')
  } else {
    getLikeList()
  }
}

async function initLocalData() {
  let userLikeList: string[] = []
  AppStorage.setOrCreate(StorageConstants.USER_LIKELIST, userLikeList)
  const playInfo: PlayingPlayList = {
    id: -1,
    count: -1
  }
  AppStorage.setOrCreate(StorageConstants.LAST_PLAYED_LIST, playInfo)

  const results = await Promise.all([
    getDeviceTypeInfo(),
    PreferencesUtils.getPreferenceValue<PlayList[]>(StorageConstants.USER_PREF, StorageConstants.USER_PLAYLISTS, []),
    PreferencesUtils.getPreferenceValue<TopListItem[]>(StorageConstants.USER_PREF, StorageConstants.TOPLISTS, []),
    PreferencesUtils.getPreferenceValue<PersonalListItem[]>(StorageConstants.USER_PREF, StorageConstants.PERSONALIZED_LIST, []),
    PreferencesUtils.getPreferenceValue<string[]>(StorageConstants.USER_PREF, StorageConstants.SEARCH_HISTORY, [])
  ])

  AppStorage.setOrCreate(StorageConstants.DEVICE_TYPE, results[0])
  AppStorage.setOrCreate(StorageConstants.USER_PLAYLISTS, results[1])
  AppStorage.setOrCreate(StorageConstants.TOPLISTS, results[2])
  AppStorage.setOrCreate(StorageConstants.PERSONALIZED_LIST, results[3])
  AppStorage.setOrCreate(StorageConstants.SEARCH_HISTORY, results[4])
}

/**
 * 初始化播放列表
 */
async function initPlayQueue() {
  await PlayQueueUtils.init()
}

/**
 * 加载上一次的播放内容
 */
async function loadSavedSong() {
  let has = await PreferencesUtils.getPreferenceValue<boolean>('Play','hasCurrentSong', false)
  let song: Song = {
    id: 0,
    name: "暂无播放",
    artists: [],
    duration: 0,
    alias: [],
    fee: 0
  }
  let artists = '选择一首歌曲播放吧'
  let picUrl: string = ''
  let playMode: number = 0

  if(has) {
    song = await PreferencesUtils.getPreferenceValue<Song>('Play', 'CurrentSong', SongClass)
    playMode = await PreferencesUtils.getPreferenceValue<number>('Play', 'PlayMode', 1)
    artists = await PreferencesUtils.getPreferenceValue<string>('Play', 'CurrentArtists', '')
    picUrl = await PreferencesUtils.getPreferenceValue<string>('Play', 'CurrentImage', '')
    let currentIndex = await PreferencesUtils.getPreferenceValue<number>('Play', 'CurrentQueueIndex', 0)
    await PlayQueueUtils.setIndex(currentIndex)
  }
  AppStorage.setOrCreate(StorageConstants.PLAY_MODE, playMode)
  AppStorage.setOrCreate(StorageConstants.PLAY_SONG, song)
  AppStorage.setOrCreate(StorageConstants.PLAY_ARTISTS, artists)
  AppStorage.setOrCreate(StorageConstants.PIC_URL, picUrl)
}

/**
 * 获取当前设备类型
 */
async function getDeviceTypeInfo(): Promise<resourceManager.DeviceType> {
  let deviceType = resourceManager.DeviceType.DEVICE_TYPE_PHONE
  try {
    deviceType = getContext().resourceManager.getDeviceCapabilitySync().deviceType
  } catch (e) {
    LogUtil.error(TAG + 'Failed to get device type: ' + e.message)
  }
  return deviceType
}
