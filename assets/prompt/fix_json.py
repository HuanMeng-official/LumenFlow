import json
import sys

def fix_control_chars(text):
    """Escape control characters in JSON strings."""
    result = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        result.append(ch)
        i += 1
    # This is a placeholder, we need to actually parse JSON
    return ''.join(result)

def fix_json_file(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    # Use a more robust method: try to parse with json.JSONDecoder
    # but we need to handle control characters.
    # Let's try to decode with strict=False? Not available.
    # Instead, we can replace control characters outside of strings?
    # We'll implement a simple state machine.
    output = []
    in_string = False
    escape_next = False
    for ch in content:
        if escape_next:
            output.append(ch)
            escape_next = False
        elif ch == '\\':
            output.append(ch)
            escape_next = True
        elif ch == '\"':
            output.append(ch)
            in_string = not in_string
        elif in_string and ch in '\n\r\t':
            # Escape control character
            if ch == '\n':
                output.append('\\n')
            elif ch == '\r':
                output.append('\\r')
            elif ch == '\t':
                output.append('\\t')
            else:
                # Should not happen
                output.append(ch)
        else:
            output.append(ch)

    new_content = ''.join(output)
    # Validate
    try:
        data = json.loads(new_content)
        print('JSON is now valid')
        # Write back
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print('File fixed')
    except json.JSONDecodeError as e:
        print('Still invalid:', e)
        sys.exit(1)

if __name__ == '__main__':
    fix_json_file('./presets.json')