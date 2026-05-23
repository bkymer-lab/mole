import glob

def fix_public(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    for line in lines:
        stripped = line.lstrip()
        indent_len = len(line) - len(stripped)
        
        # If it's indented by 8 or more spaces, it's inside a function/method
        # or if it's inside a guard statement, remove 'public '
        if indent_len >= 8 and stripped.startswith('public '):
            line = line[:indent_len] + stripped[7:]
            
        new_lines.append(line)
        
    with open(file_path, 'w') as f:
        f.writelines(new_lines)

for f in glob.glob('/Users/bilalyasinyaman/Desktop/mole-main/Sources/MoleCore/*.swift'):
    fix_public(f)
