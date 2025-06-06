import { LogUtil, ToastUtil } from "@pura/harmony-utils"
import { StorageConstants } from "../../constants/StorageConstants"
import PreferencesUtils from "../../utils/data/PreferencesUtils"
/**
 * 设置项
 */
const TAG = '[settings] '

/**
 * 初始化应用设置
 */
export async function initSettings() {
  const SetPerf = StorageConstants.SET_PERF

  // 并行处理无依赖的配置项
  await Promise.all([
    // API地址
    (async () => {
      const exists = await PreferencesUtils.hasPreferenceValue(SetPerf, StorageConstants.API_URL)
      const value = exists
        ? await PreferencesUtils.getPreferenceValue(SetPerf, StorageConstants.API_URL, 'https://api-ncm.chenlvin.cc')
        : 'https://api-ncm.chenlvin.cc'
      if (!exists) await PreferencesUtils.putPreferenceValue(SetPerf, StorageConstants.API_URL, '')
      AppStorage.setOrCreate(StorageConstants.API_URL, value)
    })(),

    // 默认主页
    (async () => {
      const exists = await PreferencesUtils.hasPreferenceValue(SetPerf, StorageConstants.DEFAULT_PAGE_INDEX)
      const value = exists
        ? await PreferencesUtils.getPreferenceValue(SetPerf, StorageConstants.DEFAULT_PAGE_INDEX, 0)
        : 0
      if (!exists) await PreferencesUtils.putPreferenceValue(SetPerf, StorageConstants.DEFAULT_PAGE_INDEX, 0)
      AppStorage.setOrCreate(StorageConstants.DEFAULT_PAGE_INDEX, value)
    })(),

    // 播放质量
    (async () => {
      const exists = await PreferencesUtils.hasPreferenceValue(SetPerf, StorageConstants.PLAY_QUALITY)
      const value = exists
        ? await PreferencesUtils.getPreferenceValue(SetPerf, StorageConstants.PLAY_QUALITY, 0)
        : 0
      if (!exists) await PreferencesUtils.putPreferenceValue(SetPerf, StorageConstants.PLAY_QUALITY, 0)
      AppStorage.setOrCreate(StorageConstants.PLAY_QUALITY, value)
    })(),

    // 播放卡片操作
    (async () => {
      const exists = await PreferencesUtils.hasPreferenceValue(SetPerf, StorageConstants.SONG_CLICK_ACTION)
      const value = exists
        ? await PreferencesUtils.getPreferenceValue(SetPerf, StorageConstants.SONG_CLICK_ACTION, 0)
        : 0
      if (!exists) await PreferencesUtils.putPreferenceValue(SetPerf, StorageConstants.SONG_CLICK_ACTION, 0)
      AppStorage.setOrCreate(StorageConstants.SONG_CLICK_ACTION, value)
    })()

  ])

  // 处理关联配置项（自定义API URL）
  const results = await Promise.all([
    PreferencesUtils.hasPreferenceValue(SetPerf, StorageConstants.IS_CUSTOM_COOKIE),
    PreferencesUtils.hasPreferenceValue(SetPerf, StorageConstants.MIX_WITH_OTHERS)
  ])
  const isCustomCookieExist = results[0]
  const isMixExist = results[1]

  // 自定义Cookie设置
  if (!isCustomCookieExist) {
    await Promise.all([
      PreferencesUtils.putPreferenceValue(SetPerf, StorageConstants.IS_CUSTOM_COOKIE, false),
      PreferencesUtils.putPreferenceValue(SetPerf, StorageConstants.CUSTOM_COOKIE, 'MUSIC_U=')
    ])
    AppStorage.setOrCreate(StorageConstants.IS_CUSTOM_COOKIE, false)
    AppStorage.setOrCreate(StorageConstants.CUSTOM_COOKIE, 'MUSIC_U=')
  } else {
    const customResults = await Promise.all([
      PreferencesUtils.getPreferenceValue(SetPerf, StorageConstants.IS_CUSTOM_COOKIE, false),
      PreferencesUtils.getPreferenceValue(SetPerf, StorageConstants.CUSTOM_COOKIE, 'MUSIC_U=')
    ])
    const isCustom = customResults[0]
    const cookie = customResults[1]
    AppStorage.setOrCreate(StorageConstants.IS_CUSTOM_COOKIE, isCustom)
    AppStorage.setOrCreate(StorageConstants.CUSTOM_COOKIE, cookie)
  }

  // 混音设置
  if (!isMixExist) {
    await PreferencesUtils.putPreferenceValue(SetPerf, StorageConstants.MIX_WITH_OTHERS, false)
    AppStorage.setOrCreate(StorageConstants.MIX_WITH_OTHERS, false)
  } else {
    const mixValue = await PreferencesUtils.getPreferenceValue(SetPerf, StorageConstants.MIX_WITH_OTHERS, false)
    AppStorage.setOrCreate(StorageConstants.MIX_WITH_OTHERS, mixValue)
  }
}

export async function changeSettings(name: string, value: number | boolean) {
  try {
    await PreferencesUtils.putPreferenceValue(StorageConstants.SET_PERF, name, value)
    AppStorage.setOrCreate(name, value)
  } catch (e) {
    ToastUtil.showToast('更改设置失败')
    LogUtil.error(TAG + 'Error while changing settings: ' + e.message)
  }
}