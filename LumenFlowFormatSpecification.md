## *LumenFlow Format Specification Document*

### Overview
Lumenflow format is a custom settings file format for the LumenFlow application, designed specifically for exporting/importing application settings. It adds a metadata layer on top of JSON format, providing better version control and compatibility management.

> Version: 1.0  
> Extension: .lumenflow  
> Type: application/json

### File Structure
```json
{
    "_format": "lumenflow",       // Format identifier
    "_version": "1.0",            // Format version
    "_created": "2025-12-31T10:30:00.000Z",  // Creation time (UTC ISO 8601)
    "_app_version": "1.9.0",      // Application version

    "settings": {
      // All original setting key-value pairs
        "api_endpoint": "https://api.openai.com/v1",
        "api_key": "sk-...",
        "model": "gpt-5",
        "temperature": 0.7,
        "max_tokens": 8192,
        "enable_history": true,
        "history_context_length": 30,
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

### Field Description
Metadata fields (prefixed with _)

| Field name   | Type   | Required | Description                                 |
| ------------ | ------ | -------- | ------------------------------------------- |
| _format      | string | YES      | Format identifier, fixed as "lumenflow"     |
| _version     | string | YES      | Format version, currently "1.0"             |
| _created     | string | YES      | Creation timestamp (UTC ISO 8601)           |
| _app_version | string | YES      | Application version at export time          |

Settings data fields

| Field name | Type   | Required | Description                                 |
| ---------- | ------ | -------- | ------------------------------------------- |
| settings   | object | YES      | JSON object containing all application settings |

### Notes
1. Security
    - Sensitive information: api_key and other sensitive information will be included in the exported file
    - Storage security: Users should properly store .lumenflow files to avoid leakage
    - Local processing: All parsing is done locally on the device, no network transmission
2. File management
    - Naming convention: lumenflow_settings_YYYY-MM-DD.lumenflow
    - File size: Typically less than 10KB

### Development Guide
```python
# Python example
import json

def parse_lumenflow(file_path):
    """
    Parse Lumenflow format file
    Args:
        file_path: Lumenflow file path
    Returns:
        dict: Parsed settings data
    Raises:
        ValueError: If not a valid Lumenflow format
        FileNotFoundError: File does not exist
        json.JSONDecodeError: JSON parsing error
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Validate required fields
    required_fields = ['_format', '_version', '_created', '_app_version', 'settings']
    for field in required_fields:
        if field not in data:
            raise ValueError(f'Invalid Lumenflow format: missing {field} field')

    # Validate format identifier
    if data['_format'] != 'lumenflow':
        raise ValueError(f'Invalid format identifier: {data["_format"]}, expected "lumenflow"')

    # Validate version
    if data['_version'] != '1.0':
        print(f'Warning: Unsupported Lumenflow version {data["_version"]}, currently supports v1.0')

    # Extract metadata
    metadata = {
        'format': data['_format'],
        'version': data['_version'],
        'created': data['_created'],
        'app_version': data['_app_version']
    }

    # Return settings data and metadata
    return {
        'metadata': metadata,
        'settings': data['settings']
    }

# Usage example
try:
    result = parse_lumenflow('lumenflow_settings_2025-12-31.lumenflow')
    print(f"Application version: {result['metadata']['app_version']}")
    print(f"Creation time: {result['metadata']['created']}")
    print(f"API endpoint: {result['settings'].get('api_endpoint', 'Not set')}")
except ValueError as e:
    print(f"Format error: {e}")
except json.JSONDecodeError as e:
    print(f"JSON parsing error: {e}")
except FileNotFoundError:
    print("File does not exist")
```

```javascript
// JavaScript example

/**
 * @param {string|File} input - Lumenflow JSON string or File object
 * @returns {Promise<Object>} Object containing metadata and settings
 */
async function parseLumenflow(input) {
    let jsonData;

    // Handle different input types
    if (typeof input === 'string') {
        // Directly parse JSON string
        jsonData = JSON.parse(input);
    } else if (input instanceof File) {
        // Read file content
        const text = await input.text();
        jsonData = JSON.parse(text);
    } else {
        throw new Error('Invalid input type, expected string or File object');
    }

    // Validate required fields
    const required = ['_format', '_version', '_created', '_app_version', 'settings'];
    for (const field of required) {
        if (!(field in jsonData)) {
            throw new Error(`Invalid Lumenflow format: missing ${field} field`);
        }
    }

    // Validate format identifier
    if (jsonData._format !== 'lumenflow') {
        throw new Error(`Invalid format identifier: ${jsonData._format}, expected "lumenflow"`);
    }

    // Return structured data
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

// Usage example - reading from file input
document.getElementById('lumenflowFile').addEventListener('change', async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    try {
        const result = await parseLumenflow(file);
        console.log('Metadata:', result.metadata);
        console.log('Number of settings:', Object.keys(result.settings).length);

        // Display on page
        document.getElementById('appVersion').textContent = result.metadata.appVersion;
        document.getElementById('createdTime').textContent = new Date(result.metadata.created).toLocaleString();
    } catch (error) {
        console.error('Parsing failed:', error);
        alert(`Parsing failed: ${error.message}`);
    }
});

// Usage example - parsing from string
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
    console.log('Parsing successful:', result);
} catch (error) {
    console.error('Parsing failed:', error);
}
```

---

## Conversation Export Variant

Conversation packages use the same metadata envelope with `_type: "conversation"` and a `conversation` object. Since 2026-11, `conversation.memory` carries the rolling memory used to preserve long-conversation continuity:

```json
{
  "_format": "lumenflow",
  "_version": "1.0",
  "_type": "conversation",
  "_created": "2026-11-12T10:30:00.000Z",
  "_app_version": "3.1.0",
  "conversation": {
    "id": "conversation_id",
    "title": "Conversation title",
    "messages": [],
    "memory": {
      "summary": "Story so far...",
      "emotionalState": "Current relationship and mood...",
      "facts": [],
      "rejected": [],
      "coveredUntilMessageId": "message_id",
      "fingerprint": "sha256",
      "updatedAt": 1730000000000
    },
    "memory_notes": [
      {
        "id": "note_id",
        "conversationId": "conversation_id",
        "kind": "agreement",
        "text": "Be back at camp before sunset",
        "quote": "We agreed to be back before sunset",
        "reason": null,
        "sourceMessageId": "message_id",
        "createdAt": 1730000000000,
        "status": "pending"
      }
    ]
  }
}
```

- `memory` is optional and additive; files without it remain valid and will rebuild memory from messages when needed.
- `memory_notes` contains pending active notes that have not yet been merged into `memory`. Processed notes are omitted. On import, note IDs are regenerated and `sourceMessageId` is remapped.
- The app also accepts a raw conversation JSON export (the `conversation` object itself, without the LumenFlow metadata envelope); a file containing `id` and `messages` is treated as a conversation export.
- On import, message IDs are regenerated. Implementations must remap `coveredUntilMessageId` and each fact/rejected `sourceMessageId` to the new IDs, then recompute `fingerprint` from the imported messages.
- If the boundary cannot be mapped, keep the memory content but clear coverage/fingerprint; the app rebuilds lazily on the next send.

---

Last updated: 2026/11/13  
Maintainer: 幻梦official  
Document version: 1.0