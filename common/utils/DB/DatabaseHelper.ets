import data from '@ohos.data.relationalStore';
import { LogUtil } from '@pura/harmony-utils';

const TAG = '[DatabaseHelper] ';

/**
 * 数据库帮助类，用于创建、升级数据库
 */
export class DatabaseHelper {
  private context: Context;
  private rdbStore: data.RdbStore | null = null;

  // 数据库配置
  private static readonly STORE_CONFIG: data.StoreConfig = {
    name: "cloud_music.db",
    securityLevel: data.SecurityLevel.S1
  };

  // 数据库版本
  private static readonly DB_VERSION: number = 1;

  constructor(context: Context) {
    this.context = context;
  }

  /**
   * 获取数据库连接
   */
  async getRdbStore(): Promise<data.RdbStore> {
    if (this.rdbStore != null) {
      return this.rdbStore;
    }

    try {
      this.rdbStore = await data.getRdbStore(this.context, DatabaseHelper.STORE_CONFIG);
      await this.initDatabase();
      return this.rdbStore;
    } catch (error) {
      LogUtil.error(TAG + `Failed to get RdbStore: ${error}`);
      throw new Error(String(error));  // ✅ 显式转为 Error 类型
    }
  }

    /**
   * 初始化数据库
   */
  private async initDatabase(): Promise<void> {
    if (this.rdbStore == null) {
      LogUtil.error(TAG + 'RdbStore is null when initializing database');
      return;
    }

    // 创建用户表
    const createUserTable = `
      CREATE TABLE IF NOT EXISTS user (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(50) NOT NULL,
        password VARCHAR(100) NOT NULL,
        gender VARCHAR(10),
        phone VARCHAR(20),
        email VARCHAR(50),
        last_login DATETIME,
        is_admin INTEGER DEFAULT 0,
        user_status INTEGER DEFAULT 1
      )
    `;

    // 创建歌曲表
    const createSongTable = `
  CREATE TABLE IF NOT EXISTS song (
    song_id INTEGER PRIMARY KEY AUTOINCREMENT,
    song_name VARCHAR(100) NOT NULL,
    artist VARCHAR(100),
    album VARCHAR(100),
    duration VARCHAR(10),
    lyrics TEXT,
    download_url VARCHAR(255),
    song_status INTEGER DEFAULT 1,
    add_time DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`;

    // 创建歌单表
    const createPlaylistTable = `
      CREATE TABLE IF NOT EXISTS playlist (
        playlist_id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_name VARCHAR(100) NOT NULL,
        create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
        description TEXT,
        cover_url VARCHAR(255),
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES user(user_id)
      )
    `;

    // 创建歌单歌曲关系表(歌单包含)
    const createPlaylistSongTable = `
      CREATE TABLE IF NOT EXISTS playlist_song (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER,
        song_id INTEGER,
        add_time DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (playlist_id) REFERENCES playlist(playlist_id),
        FOREIGN KEY (song_id) REFERENCES song(song_id)
      )
    `;

    // 创建下载记录表
    const createDownloadTable = `
      CREATE TABLE IF NOT EXISTS download (
        download_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        download_time DATETIME DEFAULT CURRENT_TIMESTAMP,
        download_status INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES user(user_id)
      )
    `;

    // 创建下载详情表
    const createDownloadDetailTable = `
      CREATE TABLE IF NOT EXISTS download_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        download_id INTEGER,
        song_id INTEGER,
        file_path VARCHAR(255),
        file_size INTEGER,
        FOREIGN KEY (download_id) REFERENCES download(download_id),
        FOREIGN KEY (song_id) REFERENCES song(song_id)
      )
    `;

    // 创建用户收藏表
    const createFavoriteTable = `
      CREATE TABLE IF NOT EXISTS favorite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        song_id INTEGER,
        favorite_time DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES user(user_id),
        FOREIGN KEY (song_id) REFERENCES song(song_id)
      )
    `;

    // 创建播放记录表
    const createPlayHistoryTable = `
      CREATE TABLE IF NOT EXISTS play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        song_id INTEGER,
        play_time DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES user(user_id),
        FOREIGN KEY (song_id) REFERENCES song(song_id)
      )
    `;

    // 创建插入初始管理员账户的语句
    const insertAdminUser = `
      INSERT INTO user (username, password, is_admin, user_status)
      VALUES ('admin', 'admin123', 1, 1)
    `;

    try {
      // 执行创建表SQL
      await this.rdbStore.executeSql(createUserTable);
      await this.rdbStore.executeSql(createSongTable);
      await this.rdbStore.executeSql(createPlaylistTable);
      await this.rdbStore.executeSql(createPlaylistSongTable);
      await this.rdbStore.executeSql(createDownloadTable);
      await this.rdbStore.executeSql(createDownloadDetailTable);
      await this.rdbStore.executeSql(createFavoriteTable);
      await this.rdbStore.executeSql(createPlayHistoryTable);

      // 检查是否已存在管理员账户，如果不存在则创建
      const adminQuery = await this.rdbStore.querySql("SELECT user_id FROM user WHERE username = 'admin'");
      if (adminQuery.rowCount === 0) {
        await this.rdbStore.executeSql(insertAdminUser);
      }
      LogUtil.info(TAG + 'Database initialized successfully');
    } catch (error) {
      LogUtil.error(TAG + `Failed to initialize database: ${error}`);
      throw new Error(String(error));
    }
  }

  /**
   * 关闭数据库
   */
  async closeDatabase(): Promise<void> {
    if (this.rdbStore != null) {
      try {
        await this.rdbStore.close();
        this.rdbStore = null;
      } catch (error) {
        LogUtil.error(TAG + `Failed to close database: ${error}`);
        throw new Error(String(error));
      }
    }
  }
}