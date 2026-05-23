import glob
import re

def process_file(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
        
    new_lines = []
    
    for line in lines:
        stripped = line.lstrip()
        indent = len(line) - len(stripped)
        
        if (indent == 0 or indent == 4) and not stripped.startswith('//'):
            if ('private ' in stripped) or ('fileprivate ' in stripped) or ('override ' in stripped):
                new_lines.append(line)
                continue
                
            is_decl = False
            for kw in ['class ', 'struct ', 'enum ', 'protocol ', 'extension ', 'final class ', 'var ', 'let ', 'func ', 'init']:
                if stripped.startswith(kw):
                    is_decl = True
                    break
                    
            if is_decl and not stripped.startswith('public '):
                line = ' ' * indent + 'public ' + stripped
                    
        new_lines.append(line)
        
    with open(file_path, 'w') as f:
        f.writelines(new_lines)

for f in glob.glob('/Users/bilalyasinyaman/Desktop/mole-main/Sources/MoleCore/*.swift'):
    process_file(f)
