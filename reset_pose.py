import re
import sys

def main():
    file_path = "Scenes/PlayerVisual.tscn"
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    pattern = re.compile(r'^bones/\d+/(position|rotation|scale|enabled)\s*=')
    for line in lines:
        if not pattern.match(line):
            new_lines.append(line)

    with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
        f.writelines(new_lines)
    print("Pose reset successfully!")

if __name__ == "__main__":
    main()
