import re, os

MODULE_PROPERTY_VAR_MAP = {
    ('business', 'selectedBusiness'): 'business',
    ('business', 'selectedBusiness?.id'): 'businessId',
    ('item', 'items'): 'items',
    ('party', 'parties'): 'parties',
    ('invoice', ''): 'provider',
    ('payment', ''): 'paymentProvider',
    ('expense', ''): 'expenseProvider',
    ('dashboard', ''): 'dashboardProvider',
}

# Module accessors
READ = r'context\.read<Core>\(\)'
WATCH = r'context\.watch<Core>\(\)'
ACCESSOR = f'({READ}|{WATCH})'

# Match broken patterns: context.read<Core>().moduleer>(params) or context.read<Core>().moduleider>(params)
BROKEN_PAT = re.compile(
    rf'({ACCESSOR})\.(\w+?)(?:er|ider)>'
    r'\(context(?:,?\s*listen:\s*false)?\)\s*'
)

def fix_line(line, filepath):
    m = BROKEN_PAT.search(line)
    if not m:
        return line

    accessor = m.group(2)  # 'context.read<Core>()' or 'context.watch<Core>()'
    module = m.group(3)    # 'business', 'invoice', 'item', etc.

    # Text after the matching paren
    rest = line[m.end():]

    # Determine if it's a value assignment or module assignment
    stripped_rest = rest.strip()

    # The correct variable name based on module + rest pattern
    is_listen = 'watch' in accessor

    if stripped_rest.startswith('.') or stripped_rest.startswith('?.'):
        # Property access - get the property name
        prop_part = stripped_rest.lstrip('.?')
        prop_name = prop_part.split('(')[0].split('?')[0].split('.')[0].split('[')[0]
        
        # Determine variable name from module + property
        var_name = None
        # Try exact mapping
        for (mod, prop), varname in MODULE_PROPERTY_VAR_MAP.items():
            if mod == module and prop_name == prop:
                var_name = varname
                break
        
        if not var_name:
            # Heuristic: use the property name as-is (camelCase)
            # e.g., .items -> items, .parties -> parties
            var_name = prop_name

        if is_listen:
            expr = f'{accessor}.{module}{rest.rstrip()}'
        else:
            expr = f'{accessor}.{module}{rest.rstrip()}'
    else:
        # Module assignment (no property access) or method call
        if stripped_rest.startswith('(') or stripped_rest.startswith('.'):
            # Method or further chaining already handled
            expr = f'{accessor}.{module}{rest.rstrip()}'
            # This is inline, no variable needed - return as-is after fixing
            prefix = line[:m.start()]
            return f'{prefix}{expr}\n'
        else:
            # Module assignment: final xxx = context.read<Core>().module;
            var_name = MODULE_PROPERTY_VAR_MAP.get((module, ''), f'{module}Provider')
            rest_clean = rest.rstrip()
            expr = f'{accessor}.{module}{rest_clean}'

    # Reconstruct the prefix
    prefix_before = line[:m.start()]
    prefix_stripped = prefix_before.strip()
    
    if 'final ' in prefix_stripped:
        after_final = prefix_stripped.split('final ', 1)[1]
        # This is the mangled variable name (potentially incomplete)
        # We know the correct name from our mapping
        # Replace with correct variable name
        indent = line[:len(line) - len(line.lstrip())]
        fix = f'{indent}final {var_name} = {expr}\n'
        return fix
    else:
        # Inline usage (no variable)
        return f'{prefix_before}{expr}\n'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
        lines = content.split('\n')

    new_lines = []
    changed = False
    for line in lines:
        fixed = fix_line(line, filepath)
        if fixed != line:
            changed = True
        new_lines.append(fixed)

    if changed:
        with open(filepath, 'w') as f:
            f.write('\n'.join(new_lines))
        print(f'Fixed: {filepath}')

def main():
    lib_dir = '/Users/jaydeepsarvaiya/Desktop/PlayStore/vyaparsetu/lib'
    for root, dirs, files in os.walk(lib_dir):
        for f in files:
            if f.endswith('.dart') and not f.endswith('.g.dart'):
                process_file(os.path.join(root, f))

if __name__ == '__main__':
    main()
