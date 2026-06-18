import re
import os

PROVIDER_MAP = {
    'AuthProvider': 'auth',
    'BusinessProvider': 'business',
    'PartyProvider': 'party',
    'ItemProvider': 'item',
    'InvoiceProvider': 'invoice',
    'PaymentProvider': 'payment',
    'ExpenseProvider': 'expense',
    'DashboardProvider': 'dashboard',
    'ThemeProvider': 'settings',
    'LocaleProvider': 'settings',
}

CORE_IMPORT = "import 'package:vyaparsetu/core/Core.dart';"

# Matches Provider.of<XxxProvider>( ... )
# Group 1: provider name
# Group 2: the full parameters including parens
PATTERN = re.compile(r'Provider\.of<(\w+)>\(((?:[^()]|\([^()]*\))*)\)')

def replace_content(content):
    def replacer(m):
        provider_name = m.group(1)
        params = m.group(2)
        module_name = PROVIDER_MAP.get(provider_name)
        if not module_name:
            return m.group(0)
        has_listen_false = 'listen: false' in params
        if has_listen_false:
            return f'context.read<Core>().{module_name}'
        else:
            return f'context.watch<Core>().{module_name}'
    
    return PATTERN.sub(replacer, content)

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if not any(p in content for p in PROVIDER_MAP.keys()):
        return
    
    original = content
    content = replace_content(content)
    
    # Add Core import after last import or at top
    if CORE_IMPORT not in content:
        lines = content.split('\n')
        insert_pos = 0
        for idx, line in enumerate(lines):
            if line.startswith('import '):
                insert_pos = idx + 1
        # Skip if already added
        needs_import = True
        for line in lines[:insert_pos]:
            if CORE_IMPORT in line:
                needs_import = False
                break
        if needs_import:
            lines.insert(insert_pos, CORE_IMPORT)
        content = '\n'.join(lines)
    
    # Remove provider imports
    content = re.sub(r"import 'package:vyaparsetu/providers/\w+\.dart';\n?", '', content)
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f'Updated: {filepath}')

def main():
    lib_dir = '/Users/jaydeepsarvaiya/Desktop/PlayStore/vyaparsetu/lib'
    for root, dirs, files in os.walk(lib_dir):
        for f in files:
            if f.endswith('.dart') and not f.endswith('.g.dart'):
                filepath = os.path.join(root, f)
                process_file(filepath)

if __name__ == '__main__':
    main()
