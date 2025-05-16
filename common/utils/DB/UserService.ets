import { LogUtil } from '@pura/harmony-utils';
import { DatabaseHelper } from './DatabaseHelper';

const TAG = '[UserService] ';

export interface AdminUser {
  id: string;
  username: string;
  password: string;
  status: 'active' | 'inactive' | 'banned';
  createdAt: string;
}

export class UserService {
  private dbHelper: DatabaseHelper;

  constructor(context: Context) {
    this.dbHelper = new DatabaseHelper(context);
  }

  // 获取所有用户
  async getAllUsers(): Promise<AdminUser[]> {
    try {
      const db = await this.dbHelper.getRdbStore();
      const resultSet = await db.querySql('SELECT * FROM user');

      const users: AdminUser[] = [];
      while (resultSet.goToNextRow()) {
        users.push({
          id: resultSet.getString(resultSet.getColumnIndex('user_id')),
          username: resultSet.getString(resultSet.getColumnIndex('username')),
          password: resultSet.getString(resultSet.getColumnIndex('password')),
          status: this.mapStatusFromDB(
            Number(resultSet.getLong(resultSet.getColumnIndex('user_status')))
          ),
          createdAt: resultSet.getString(resultSet.getColumnIndex('last_login')) || new Date().toISOString().split('T')[0]
        });
      }
      resultSet.close();
      return users;
    } catch (error) {
      LogUtil.error(TAG + `获取用户列表失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 添加用户
  async addUser(user: AdminUser): Promise<string> {
    try {
      const db = await this.dbHelper.getRdbStore();
      const statusValue = this.mapStatusToDB(user.status);

      const sql = `INSERT INTO user (username, password, user_status, last_login)
                   VALUES (?, ?, ?, ?)`;
      const bindArgs = [user.username, user.password, statusValue, user.createdAt];

      await db.executeSql(sql, bindArgs);

      // 获取新插入的ID
      const idResult = await db.querySql('SELECT last_insert_rowid() as id');
      idResult.goToFirstRow();
      const newId = idResult.getString(idResult.getColumnIndex('id'));
      idResult.close();

      return newId;
    } catch (error) {
      LogUtil.error(TAG + `添加用户失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 更新用户
  async updateUser(user: AdminUser): Promise<boolean> {
    try {
      const db = await this.dbHelper.getRdbStore();
      const statusValue = this.mapStatusToDB(user.status);

      const sql = `UPDATE user SET
                   username = ?,
                   password = ?,
                   user_status = ?
                   WHERE user_id = ?`;
      const bindArgs = [user.username, user.password, statusValue, user.id];

      await db.executeSql(sql, bindArgs);
      return true;
    } catch (error) {
      LogUtil.error(TAG + `更新用户失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 删除用户
  async deleteUser(userId: string): Promise<boolean> {
    try {
      const db = await this.dbHelper.getRdbStore();
      const sql = `DELETE FROM user WHERE user_id = ?`;
      const bindArgs = [userId];

      await db.executeSql(sql, bindArgs);
      return true;
    } catch (error) {
      LogUtil.error(TAG + `删除用户失败: ${error}`);
      throw new Error(String(error));
    }
  }

  // 将数据库状态值转换为应用中使用的状态
  private mapStatusFromDB(status: number): 'active' | 'inactive' | 'banned' {
    switch (status) {
      case 1: return 'active';
      case 0: return 'inactive';
      case -1: return 'banned';
      default: return 'active';
    }
  }

  // 将应用中使用的状态转换为数据库状态值
  private mapStatusToDB(status: string): number {
    switch (status) {
      case 'active': return 1;
      case 'inactive': return 0;
      case 'banned': return -1;
      default: return 1;
    }
  }
}

export default UserService;