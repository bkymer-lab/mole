import re
import os
import glob

def make_public(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Very basic regex to add public. This is risky but might work for simple files.
    # We only want to match top-level or class/struct-level declarations, but let's just match lines starting with spaces or nothing followed by var, let, func, class, struct, enum
    
    lines = content.split('\n')
    new_lines = []
    
    for line in lines:
        stripped = line.lstrip()
        # skip private/fileprivate
        if "private " in line or "fileprivate " in line:
            new_lines.append(line)
            continue
            
        if stripped.startswith("class ") or stripped.startswith("struct ") or stripped.startswith("enum ") or stripped.startswith("protocol ") or stripped.startswith("extension "):
            if not stripped.startswith("public "):
                line = line.replace(stripped, "public " + stripped, 1)
        
        elif stripped.startswith("var ") or stripped.startswith("let ") or stripped.startswith("func ") or stripped.startswith("init("):
            # check if it's inside a function (indentation > 4 usually, but we can't reliably know)
            # as a hack, we can just replace all of them and fix any issues later
            if not stripped.startswith("public "):
                line = line.replace(stripped, "public " + stripped, 1)
                
        new_lines.append(line)

    with open(file_path, 'w') as f:
        f.write('\n'.join(new_lines))

for f in glob.glob('/Users/bilalyasinyaman/Desktop/mole-main/MacApp/Sources/MoleCore/*.swift'):
    make_public(f)
