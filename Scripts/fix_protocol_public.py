import glob

def fix_protocol_public(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    in_protocol = False
    
    for line in lines:
        stripped = line.lstrip()
        
        if stripped.startswith("protocol ") or stripped.startswith("@objc protocol ") or stripped.startswith("public protocol ") or stripped.startswith("public @objc protocol "):
            in_protocol = True
            
        if in_protocol and stripped.startswith("}"):
            in_protocol = False
            
        if in_protocol and stripped.startswith("public "):
            indent_len = len(line) - len(stripped)
            line = line[:indent_len] + stripped[7:]
            
        new_lines.append(line)
        
    with open(file_path, 'w') as f:
        f.writelines(new_lines)

for f in glob.glob('/Users/bilalyasinyaman/Desktop/mole-main/Sources/MoleCore/*.swift'):
    fix_protocol_public(f)
