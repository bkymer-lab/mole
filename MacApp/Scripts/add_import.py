import glob
import os

def add_import(file_path, module_name):
    with open(file_path, 'r') as f:
        content = f.read()
    
    if f"import {module_name}" not in content:
        # insert after the first import, or at the top
        lines = content.split('\n')
        new_lines = []
        inserted = False
        for line in lines:
            if line.startswith("import ") and not inserted:
                new_lines.append(line)
                new_lines.append(f"import {module_name}")
                inserted = True
            else:
                new_lines.append(line)
                
        if not inserted:
            new_lines.insert(0, f"import {module_name}")
            
        with open(file_path, 'w') as f:
            f.write('\n'.join(new_lines))

for f in glob.glob('/Users/bilalyasinyaman/Desktop/mole-main/MacApp/Sources/MoleUI/*.swift'):
    add_import(f, "MoleCore")
    
for f in glob.glob('/Users/bilalyasinyaman/Desktop/mole-main/MacApp/Sources/MoleApp/*.swift'):
    add_import(f, "MoleCore")
    add_import(f, "MoleUI")
    add_import(f, "MoleXPC")
