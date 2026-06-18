import re, os

MODULE_NAMES = [
    'auth', 'business', 'party', 'item', 'invoice',
    'payment', 'expense', 'dashboard', 'settings',
]

def fix_line(line):
    """Fix a broken provider migration line."""
    stripped = line.rstrip()
    indent = line[:len(line) - len(line.lstrip())]

    for accessor in ['context.read<Core>()', 'context.watch<Core>()']:
        if accessor not in stripped:
            continue

        # Find the module name after accessor
        for mod in MODULE_NAMES:
            patterns = [
                f'{accessor}.{mod}er>(',
                f'{accessor}.{mod}ider>(',
            ]
            for pat in patterns:
                if pat in stripped:
                    # Split: everything before accessor, then the rest
                    idx = stripped.index(accessor)
                    prefix = stripped[:idx]
                    # The suffix after the pat: skip past the broken params
                    # pat = e.g. "context.read<Core>().businesser>("
                    # We need to skip everything until the closing paren of (context, listen: false)
                    rest_start = stripped.index(pat)
                    after_pat = stripped[rest_start + len(pat):]
                    # Find the matching closing paren - it's the first )
                    depth = 1
                    paren_end = 0
                    for ci, ch in enumerate(after_pat):
                        if ch == '(':
                            depth += 1
                        elif ch == ')':
                            depth -= 1
                            if depth == 0:
                                paren_end = ci
                                break
                    rest = after_pat[paren_end + 1:]  # everything after the closing )
                    
                    # Determine variable name from prefix
                    # Prefix has: "final xxx" possibly mangled
                    # Get the variable name by checking "final " and everything after
                    prefix_stripped = prefix.strip()
                    correct_varname = None
                    
                    if 'final ' in prefix_stripped:
                        after_final = prefix_stripped.split('final ', 1)[1]
                        # This is the mangled varname
                        # Look ahead in the file to find the correct variable name
                        # For now, use heuristics:
                        varname_prefixes = {
                            'auth': 'authProvider',
                            'business': 'business',
                            'party': 'partyProvider',
                            'item': 'item',
                            'invoice': 'provider',
                            'payment': 'provider',
                            'expense': 'expenseProvider',
                            'dashboard': 'dashboardProvider',
                            'settings': 'settings',
                        }
                        
                        suggested = varname_prefixes.get(mod, f'{mod}Provider')
                        # Use the suggested name
                        correct_varname = suggested
                    else:
                        correct_varname = f'{mod}Provider'
                    
                    new_line = f'{indent}final {correct_varname} = {accessor}.{mod}{rest}\n'
                    return new_line

    return line

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    new_lines = []
    changed = False
    for line in lines:
        fixed = fix_line(line)
        if fixed != line:
            changed = True
        new_lines.append(fixed)

    if changed:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        print(f'Fixed: {filepath}')

def main():
    lib_dir = '/Users/jaydeepsarvaiya/Desktop/PlayStore/vyaparsetu/lib'
    for root, dirs, files in os.walk(lib_dir):
        for f in files:
            if f.endswith('.dart') and not f.endswith('.g.dart'):
                filepath = os.path.join(root, f)
                process_file(filepath)

if __name__ == '__main__':
    main()
