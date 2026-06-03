import { relationalStore } from '@kit.ArkData'
import { Task, TaskStatus } from '../models/Task'

/**
 * 任务本地存储（基于 RelationalStore / 鸿蒙 Room 等价物）。
 * 镜像 Android 端 TaskRepositoryImpl
 */
const DB_NAME = 'agent_store.db'
const TABLE_TASKS = 'tasks'

export class TaskStore {
  private store: relationalStore.RdbStore | null = null

  async init(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }
    this.store = await relationalStore.getRdbStore(context, config)
    await this.createTable()
  }

  private async createTable(): Promise<void> {
    if (!this.store) return
    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_TASKS} (
        id TEXT PRIMARY KEY,
        user_command TEXT NOT NULL,
        llm_raw_response TEXT,
        intent TEXT,
        confidence REAL,
        status TEXT,
        created_at INTEGER,
        completed_at INTEGER,
        apps_involved TEXT,
        steps_json TEXT
      )
    `)
  }

  async save(task: Task): Promise<void> {
    if (!this.store) return
    const valueBucket: relationalStore.ValuesBucket = {
      'id': task.id,
      'user_command': task.userCommand,
      'llm_raw_response': task.llmRawResponse,
      'intent': task.intent,
      'confidence': task.confidence,
      'status': task.status,
      'created_at': task.createdAt,
      'completed_at': task.completedAt || null,
      'apps_involved': task.appsInvolved.join(','),
      'steps_json': JSON.stringify(task.steps)
    }
    await this.store.insert(TABLE_TASKS, valueBucket,
      relationalStore.ConflictResolution.REPLACE)
  }

  async getById(id: string): Promise<Task | null> {
    if (!this.store) return null
    const predicates = new relationalStore.RdbPredicates(TABLE_TASKS)
    predicates.equalTo('id', id)
    const result = await this.store.query(predicates)
    if (!result.goToFirstRow()) return null

    const task = this.rowToTask(result)
    result.close()
    return task
  }

  async getAll(): Promise<Task[]> {
    if (!this.store) return []
    const predicates = new relationalStore.RdbPredicates(TABLE_TASKS)
    predicates.orderByDesc('created_at')
    const result = await this.store.query(predicates)

    const tasks: Task[] = []
    while (result.goToNextRow()) {
      tasks.push(this.rowToTask(result))
    }
    result.close()
    return tasks
  }

  private rowToTask(row: relationalStore.ResultSet): Task {
    const stepsJson = row.getString(row.getColumnIndex('steps_json')) || '[]'
    return {
      id: row.getString(row.getColumnIndex('id')),
      userCommand: row.getString(row.getColumnIndex('user_command')),
      llmRawResponse: row.getString(row.getColumnIndex('llm_raw_response')),
      intent: row.getString(row.getColumnIndex('intent')),
      confidence: row.getDouble(row.getColumnIndex('confidence')),
      steps: JSON.parse(stepsJson),
      status: row.getString(row.getColumnIndex('status')) as TaskStatus,
      createdAt: row.getLong(row.getColumnIndex('created_at')),
      completedAt: row.getLong(row.getColumnIndex('completed_at')),
      appsInvolved: (row.getString(row.getColumnIndex('apps_involved')) || '').split(',').filter(Boolean)
    }
  }
}
