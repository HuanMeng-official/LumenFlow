## *LumenFlow 格式解析文档*

### 概述
Lumenflow 格式是 LumenFlow 应用的自定义设置文件格式，专为应用设置导出/导入功能设计。它在 JSON格式基础上增加了元数据层，提供了更好的版本控制和兼容性管理。

> 版本：1.0  
> 扩展名：.lumenflow  
> 类型：application/json

### 文件结构
```json
{
    "_format": "lumenflow",       // 格式标识
    "_version": "1.0",            // 格式版本
    "_created": "2025-12-31T10:30:00.000Z",  // 创建时间（UTC ISO 8601）
    "_app_version": "1.9.0",      // 应用版本

    "settings": {
      // 原有的所有设置键值对
        "api_endpoint": "https://api.openai.com/v1",
        "api_key": "sk-...",
        "model": "gpt-5",
        "temperature": 0.7,
        "max_tokens": 1000,
        "enable_history": true,
        "history_context_length": 100,
        "custom_system_prompt": "",
        "api_type": "openai",
        "dark_mode": false,
        "follow_system_theme": true,
        "app_theme": "light",
        "thinking_mode": false,
        "prompt_preset_enabled": false,
        "prompt_preset_id": "",
        "auto_title_enabled": true,
        "auto_title_rounds": 3,
        "locale": "zh",
        "ai_platforms": "[{\"id\":\"openai\",\"name\":\"OpenAI\",...}]",
        "current_platform_id": "openai"
    }
  }
  ```

  ### 字段说明
  元数据字段（以 _ 开头）

  | 字段名       | 类型   | 必需 | 说明                         |
  | ------------ | ------ | ---- | ---------------------------- |
  | _format      | string | YES  | 格式标识，固定为 "lumenflow" |
  | _version     | string | YES  | 格式版本，当前为 "1.0"       |
  | _created     | string | YES  | 创建时间戳（UTC ISO 8601）   |
  | _app_version | string | YES  | 导出时应用的版本号           |

  设置数据字段

  | 字段名   | 类型   | 必需 | 说明                         |
  | -------- | ------ | ---- | ---------------------------- |
  | settings | object | YES  | 包含所有应用设置的 JSON 对象 |

### 注意事项
1. 安全性
    - 敏感信息：api_key 等敏感信息会包含在导出的文件中
    - 存储安全：用户应妥善保管 .lumenflow 文件，避免泄露
    - 本地处理：所有解析都在设备本地完成，无网络传输
2. 文件管理
    - 命名规范：lumenflow_settings_YYYY-MM-DD.lumenflow
    - 文件大小：通常小于 10KB

### 开发指导
```python
# Python 示例
import json

  def parse_lumenflow(file_path):
      """
      解析 Lumenflow 格式文件
      Args:
          file_path: Lumenflow 文件路径
      Returns:
          dict: 解析后的设置数据
      Raises:
          ValueError: 如果不是有效的 Lumenflow 格式
          FileNotFoundError: 文件不存在
          json.JSONDecodeError: JSON 解析错误
      """
      with open(file_path, 'r', encoding='utf-8') as f:
          data = json.load(f)

      # 验证必需字段
      required_fields = ['_format', '_version', '_created', '_app_version', 'settings']
      for field in required_fields:
          if field not in data:
              raise ValueError(f'无效的 Lumenflow 格式：缺少 {field} 字段')

      # 验证格式标识
      if data['_format'] != 'lumenflow':
          raise ValueError(f'无效的格式标识：{data["_format"]}，应为 "lumenflow"')

      # 验证版本
      if data['_version'] != '1.0':
          print(f'警告：不支持的 Lumenflow 版本 {data["_version"]}，当前支持 v1.0')

      # 提取元数据
      metadata = {
          'format': data['_format'],
          'version': data['_version'],
          'created': data['_created'],
          'app_version': data['_app_version']
      }

      # 返回设置数据和元数据
      return {
          'metadata': metadata,
          'settings': data['settings']
      }

  # 使用示例
  try:
      result = parse_lumenflow('lumenflow_settings_2025-12-31.lumenflow')
      print(f"应用版本: {result['metadata']['app_version']}")
      print(f"创建时间: {result['metadata']['created']}")
      print(f"API 端点: {result['settings'].get('api_endpoint', '未设置')}")
  except ValueError as e:
      print(f"格式错误: {e}")
  except json.JSONDecodeError as e:
      print(f"JSON 解析错误: {e}")
  except FileNotFoundError:
      print("文件不存在")
```

```javascript
// JavaScript 示例

/**
 * @param {string|File} input - Lumenflow JSON 字符串 或 File 对象
 * @returns {Promise<Object>} 包含元数据和设置的对象
 */
async function parseLumenflow(input) {
    let jsonData;

    // 处理不同类型的输入
    if (typeof input === 'string') {
      // 直接解析 JSON 字符串
      jsonData = JSON.parse(input);
    } else if (input instanceof File) {
      // 读取文件内容
      const text = await input.text();
      jsonData = JSON.parse(text);
    } else {
      throw new Error('无效的输入类型，应为字符串或 File 对象');
    }

    // 验证必需字段
    const required = ['_format', '_version', '_created', '_app_version', 'settings'];
    for (const field of required) {
      if (!(field in jsonData)) {
        throw new Error(`无效的 Lumenflow 格式：缺少 ${field} 字段`);
      }
    }

    // 验证格式标识
    if (jsonData._format !== 'lumenflow') {
      throw new Error(`无效的格式标识：${jsonData._format}，应为 "lumenflow"`);
    }

    // 返回结构化数据
    return {
      metadata: {
        format: jsonData._format,
        version: jsonData._version,
        created: jsonData._created,
        appVersion: jsonData._app_version
      },
      settings: jsonData.settings
    };
  }

  // 使用示例 - 从文件输入读取
  document.getElementById('lumenflowFile').addEventListener('change', async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    try {
      const result = await parseLumenflow(file);
      console.log('元数据:', result.metadata);
      console.log('设置数量:', Object.keys(result.settings).length);

      // 显示在页面上
      document.getElementById('appVersion').textContent = result.metadata.appVersion;
      document.getElementById('createdTime').textContent = new Date(result.metadata.created).toLocaleString();
    } catch (error) {
      console.error('解析失败:', error);
      alert(`解析失败: ${error.message}`);
    }
  });

  // 使用示例 - 从字符串解析
  const lumenflowString = `{
    "_format": "lumenflow",
    "_version": "1.0",
    "_created": "2025-12-31T10:30:00.000Z",
    "_app_version": "1.9.0",
    "settings": {
      "api_endpoint": "https://api.openai.com/v1",
      "model": "gpt-5"
    }
  }`;

  try {
    const result = parseLumenflow(lumenflowString);
    console.log('解析成功:', result);
  } catch (error) {
    console.error('解析失败:', error);
  }
  ```

  ---
  最后更新：2025/12/31  
  维护者：幻梦official  
  文档版本：1.0