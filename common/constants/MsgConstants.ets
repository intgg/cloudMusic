/**
 * 消息内容常量
 */
export class MsgConstants {
  /**
   * 网络请求 HTTP Request 错误
   */
  static readonly HTTP_ERROR: string = '网络请求发生错误，请检查\n网络连接和API服务器是否正常'

  /**
   * 功能开发中的提示
   */
  static readonly DEVELOPING: string = '该功能正在开发中，敬请期待。'
  /**
   * 正在缓存提示
   */
  static readonly DOWNLOADING: string = '正在下载'
  /**
   * 下载完成提示
   */
  static readonly DOWNLOAD_COMPLETE: string = '下载完成'
}