// common/utils/DB/SongService.ets
import { LogUtil } from '@pura/harmony-utils';
import { DatabaseHelper } from './DatabaseHelper';

const TAG = '[SongService] ';

export interface AdminSong {
  id: string;
  name: string;
  artist: string;
  album: string;
  duration?: string;
  status?: 'active' | 'hidden';
  addTime?: string;
}

export class SongService {
  private dbHelper: DatabaseHelper;

  constructor(context: Context) {
    this.dbHelper = new DatabaseHelper(context);
  }

  // 获取所有歌曲
  async getAllSongs(): Promise<AdminSong[]> {
    try {
      const db = await this.dbHelper.getRdbStore();
      const resultSet = await db.querySql('SELECT * FROM song');

      const songs: AdminSong[] = [];
      while (resultSet.goToNextRow()) {
        songs.push({
          id: resultSet.getString(resultSet.getColumnIndex('song_id')),
          name: resultSet.getString(resultSet.getColumnIndex('song_name')),
          artist: resultSet.getString(resultSet.getColumnIndex('artist')),
          album: resultSet.getString(resultSet.getColumnIndex('album')),
          duration: resultSet.getString(resultSet.getColumnIndex('duration')),
          status: this.mapStatusFromDB(
            Number(resultSet.getLong(resultSet.getColumnIndex('song_status')))
          ),
          addTime: resultSet.getString(resultSet.getColumnIndex('add_time')) || new Date().toISOString().split('T')[0]
        });
      }
      resultSet.close();
      return songs;
    } catch (error) {
      LogUtil.error(TAG + `获取歌曲列表失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 添加歌曲
  async addSong(song: AdminSong): Promise<string> {
    try {
      const db = await this.dbHelper.getRdbStore();
      const statusValue = this.mapStatusToDB(song.status || 'active');
      const currentTime = new Date().toISOString().split('T')[0];

      const sql = `INSERT INTO song (song_name, artist, album, duration, song_status, add_time)
                   VALUES (?, ?, ?, ?, ?, ?)`;
      const bindArgs = [song.name, song.artist, song.album, song.duration || '0:00', statusValue, currentTime];

      await db.executeSql(sql, bindArgs);

      // 获取新插入的ID
      const idResult = await db.querySql('SELECT last_insert_rowid() as id');
      idResult.goToFirstRow();
      const newId = idResult.getString(idResult.getColumnIndex('id'));
      idResult.close();

      return newId;
    } catch (error) {
      LogUtil.error(TAG + `添加歌曲失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 更新歌曲
  async updateSong(song: AdminSong): Promise<boolean> {
    try {
      const db = await this.dbHelper.getRdbStore();
      const statusValue = this.mapStatusToDB(song.status || 'active');

      const sql = `UPDATE song SET
                   song_name = ?,
                   artist = ?,
                   album = ?,
                   duration = ?,
                   song_status = ?
                   WHERE song_id = ?`;
      const bindArgs = [song.name, song.artist, song.album, song.duration, statusValue, song.id];

      await db.executeSql(sql, bindArgs);
      return true;
    } catch (error) {
      LogUtil.error(TAG + `更新歌曲失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 删除歌曲
  async deleteSong(songId: string): Promise<boolean> {
    try {
      const db = await this.dbHelper.getRdbStore();
      const sql = `DELETE FROM song WHERE song_id = ?`;
      const bindArgs = [songId];

      await db.executeSql(sql, bindArgs);
      return true;
    } catch (error) {
      LogUtil.error(TAG + `删除歌曲失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 导入默认歌曲
  async importDefaultSongs(): Promise<boolean> {
    try {
      const db = await this.dbHelper.getRdbStore();

      // 开始事务
      await db.beginTransaction();

      try {
        // 检查歌曲表是否为空
        const countResult = await db.querySql('SELECT COUNT(*) as count FROM song');
        countResult.goToFirstRow();
        const count = Number(countResult.getLong(countResult.getColumnIndex('count')));
        countResult.close();

        // 如果已有歌曲，不再导入
        if (count > 0) {
          await db.commit();
          return true;
        }

        // 导入50首常见歌曲
        for (const song of DEFAULT_SONGS) {
          const sql = `INSERT INTO song (song_name, artist, album, duration, song_status)
                     VALUES (?, ?, ?, ?, ?)`;
          const bindArgs = [song.name, song.artist, song.album, song.duration, 1];
          await db.executeSql(sql, bindArgs);
        }

        // 提交事务
        await db.commit();
        return true;
      } catch (error) {
        // 回滚事务
        await db.rollBack();
        throw new Error(String(error));
      }
    } catch (error) {
      LogUtil.error(TAG + `导入默认歌曲失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 将数据库状态值转换为应用中使用的状态
  private mapStatusFromDB(status: number): 'active' | 'hidden' {
    switch (status) {
      case 1: return 'active';
      case 0: return 'hidden';
      default: return 'active';
    }
  }

  // 将应用中使用的状态转换为数据库状态值
  private mapStatusToDB(status: string): number {
    switch (status) {
      case 'active': return 1;
      case 'hidden': return 0;
      default: return 1;
    }
  }
}

// 50首常见歌曲数据
const DEFAULT_SONGS: AdminSong[] = [
  { id: '', name: '晴天', artist: '周杰伦', album: '叶惠美', duration: '4:29' },
  { id: '', name: '告白气球', artist: '周杰伦', album: '周杰伦的床边故事', duration: '3:35' },
  { id: '', name: '稻香', artist: '周杰伦', album: '魔杰座', duration: '3:42' },
  { id: '', name: '青花瓷', artist: '周杰伦', album: '我很忙', duration: '3:59' },
  { id: '', name: '不能说的秘密', artist: '周杰伦', album: '不能说的秘密', duration: '4:56' },
  { id: '', name: '七里香', artist: '周杰伦', album: '七里香', duration: '5:03' },
  { id: '', name: '爱你', artist: '陈芳语', album: '爱你', duration: '4:03' },
  { id: '', name: '泡沫', artist: '邓紫棋', album: 'Xposed', duration: '4:19' },
  { id: '', name: '光年之外', artist: '邓紫棋', album: '新的心跳', duration: '3:55' },
  { id: '', name: '倒数', artist: '邓紫棋', album: '倒数', duration: '3:50' },
  { id: '', name: '句号', artist: '邓紫棋', album: '句号', duration: '4:13' },
  { id: '', name: '红玫瑰', artist: '陈奕迅', album: '不想放手', duration: '3:54' },
  { id: '', name: '白玫瑰', artist: '陈奕迅', album: '不想放手', duration: '3:59' },
  { id: '', name: '浮夸', artist: '陈奕迅', album: 'U87', duration: '4:41' },
  { id: '', name: '十年', artist: '陈奕迅', album: '黑白灰', duration: '3:50' },
  { id: '', name: '富士山下', artist: '陈奕迅', album: '一切还好', duration: '4:18' },
  { id: '', name: '认真的雪', artist: '薛之谦', album: '意外', duration: '4:14' },
  { id: '', name: '演员', artist: '薛之谦', album: '绅士', duration: '4:21' },
  { id: '', name: '丑八怪', artist: '薛之谦', album: '意外', duration: '4:08' },
  { id: '', name: '刚刚好', artist: '薛之谦', album: '初学者', duration: '4:10' },
  { id: '', name: '那些你很冒险的梦', artist: '林俊杰', album: '她说', duration: '4:46' },
  { id: '', name: '可惜没如果', artist: '林俊杰', album: '新地球', duration: '4:58' },
  { id: '', name: '修炼爱情', artist: '林俊杰', album: '因你而在', duration: '4:46' },
  { id: '', name: '不为谁而作的歌', artist: '林俊杰', album: '新地球', duration: '4:24' },
  { id: '', name: '醉清风', artist: '刘珂矣', album: '醉清风', duration: '4:39' },
  { id: '', name: '半壶纱', artist: '刘珂矣', album: '半壶纱', duration: '4:22' },
  { id: '', name: '远走高飞', artist: '金志文', album: '远走高飞', duration: '4:13' },
  { id: '', name: '最美的期待', artist: '周笔畅', album: '最美的期待', duration: '4:14' },
  { id: '', name: '光辉岁月', artist: 'Beyond', album: '光辉岁月', duration: '4:54' },
  { id: '', name: '海阔天空', artist: 'Beyond', album: '海阔天空', duration: '5:26' },
  { id: '', name: '真的爱你', artist: 'Beyond', album: '继续革命', duration: '4:29' },
  { id: '', name: '春天里', artist: '汪峰', album: '生无所求', duration: '5:13' },
  { id: '', name: '像风一样', artist: '薛之谦', album: '像风一样', duration: '4:18' },
  { id: '', name: '多远都要在一起', artist: 'G.E.M.邓紫棋', album: '新的心跳', duration: '4:01' },
  { id: '', name: '夜空中最亮的星', artist: '逃跑计划', album: '世界', duration: '4:13' },
  { id: '', name: '小幸运', artist: '田馥甄', album: '小幸运', duration: '4:22' },
  { id: '', name: '暧昧', artist: '薛之谦', album: '暧昧', duration: '5:20' },
  { id: '', name: '后来', artist: '刘若英', album: '后来', duration: '5:44' },
  { id: '', name: '你的答案', artist: '阿冗', album: '你的答案', duration: '3:55' },
  { id: '', name: '起风了', artist: '买辣椒也用券', album: '起风了', duration: '5:23' },
  { id: '', name: '可能否', artist: '木小雅', album: '可能否', duration: '3:50' },
  { id: '', name: '说散就散', artist: '袁娅维', album: '说散就散', duration: '4:02' },
  { id: '', name: '年少有为', artist: '李荣浩', album: '耳朵', duration: '4:40' },
  { id: '', name: '成都', artist: '赵雷', album: '无法长大', duration: '5:28' },
  { id: '', name: '李白', artist: '李荣浩', album: '模特', duration: '3:31' },
  { id: '', name: '消愁', artist: '毛不易', album: '明日之子第一季', duration: '4:07' },
  { id: '', name: '来自天堂的魔鬼', artist: '邓紫棋', album: '新的心跳', duration: '4:11' },
  { id: '', name: '追光者', artist: '岑宁儿', album: '追光者', duration: '3:55' },
  { id: '', name: '天下', artist: '张杰', album: '明天过后', duration: '4:19' },
  { id: '', name: '凉凉', artist: '杨宗纬/张碧晨', album: '三生三世十里桃花', duration: '5:00' }
];

export default SongService;