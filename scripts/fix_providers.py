import re, os

# Fix the broken patterns from the previous migration
# pattern: context.read<Core>().businesser>(context, listen: false)
# should be: context.read<Core>().business
# pattern: context.watch<Core>().settingser>(context)
# should be: context.watch<Core>().settings

READ_PATTERN = re.compile(r"context\.read<Core>\(\)\.(\w+)er>\(context(?:,?\s*listen:\s*false)?\)")
WATCH_PATTERN = re.compile(r"context\.watch<Core>\(\)\.(\w+)er>\(context\)")

READ_PATTERN2 = re.compile(r"context\.read<Core>\(\)\.(\w+)ider>\(context(?:,?\s*listen:\s*false)?\)")
WATCH_PATTERN2 = re.compile(r"context\.watch<Core>\(\)\.(\w+)ider>\(context\)")

# Also handle the partial broken patterns
# e.g. read<Core>().businesser>(context, listen: false) -- missing parens etc.
BROKEN_READ = re.compile(r"context\.read<Core>\(\)\.\w+er>\(context(?:,?\s*listen:\s*false)?\)\s*")
BROKEN_WATCH = re.compile(r"context\.watch<Core>\(\)\.\w+er>\(context\)\s*")
BROKEN_READ2 = re.compile(r"context\.read<Core>\(\)\.\w+ider>\(context(?:,?\s*listen:\s*false)?\)\s*")
BROKEN_WATCH2 = re.compile(r"context\.watch<Core>\(\)\.\w+ider>\(context\)\s*")

PROVIDER_MAP = {
    'auth': 'auth', 'business': 'business', 'party': 'party',
    'item': 'item', 'invoice': 'invoice', 'payment': 'payment',
    'expense': 'expense', 'dashboard': 'dashboard', 'settings': 'settings',
}

def fix_broken(content):
    # First, find all broken patterns and fix them
    # Broken: "context.read<Core>().businesser>(context, listen: false)"
    # Fixed:  "context.read<Core>().business"
    
    # Fix read patterns ending in "er>"
    def fix_read_er(m):
        mod = m.group(1)
        return f'context.read<Core>().{mod}'
    def fix_watch_er(m):
        mod = m.group(1)
        return f'context.watch<Core>().{mod}'
    def fix_read_ider(m):
        mod = m.group(1)
        return f'context.read<Core>().{mod}'
    def fix_watch_ider(m):
        mod = m.group(1)
        return f'context.watch<Core>().{mod}'
    
    # Generic catch-all for any broken pattern with er>( or ider>(
    content = re.sub(
        r"context\.read<Core>\(\)\.(\w+?)(?:er|ider)>\(context(?:,?\s*listen:\s*false)?\)",
        lambda m: f'context.read<Core>().{m.group(1)}{m.group(2) if m.group(2)=="" else ""}',
        content
    )
    content = re.sub(
        r"context\.watch<Core>\(\)\.(\w+?)(?:er|ider)>\(context\)",
        lambda m: f'context.watch<Core>().{m.group(1)}{m.group(2) if m.group(2)=="" else ""}',
        content
    )
    
    # More specific fixes
    content = re.sub(
        r'context\.read<Core>\(\)\.(\w+)(?:er|ider)>\(context(?:,?\s*listen:\s*false)?\)\s*',
        lambda m: f'context.read<Core>().{m.group(1)} ',
        content
    )
    content = re.sub(
        r'context\.watch<Core>\(\)\.(\w+)(?:er|ider)>\(context\)\s*',
        lambda m: f'context.watch<Core>().{m.group(1)} ',
        content
    )
    
    return content

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if 'context.read<Core>()' not in content and 'context.watch<Core>()' not in content:
        return
    
    original = content
    content = fix_broken(content)
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
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
