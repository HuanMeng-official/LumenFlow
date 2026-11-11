/// 根据围栏语言选择下载文件的扩展名。
String codeFileExtension(String language) {
  const extensions = {
    'dart': 'dart',
    'python': 'py',
    'javascript': 'js',
    'typescript': 'ts',
    'csharp': 'cs',
    'java': 'java',
    'kotlin': 'kt',
    'swift': 'swift',
    'go': 'go',
    'rust': 'rs',
    'ruby': 'rb',
    'php': 'php',
    'html': 'html',
    'css': 'css',
    'scss': 'scss',
    'json': 'json',
    'yaml': 'yaml',
    'bash': 'sh',
    'shell': 'sh',
    'sql': 'sql',
    'markdown': 'md',
    'xml': 'xml',
  };
  return extensions[language.toLowerCase()] ?? 'txt';
}
