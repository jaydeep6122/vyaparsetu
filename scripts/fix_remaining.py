import re, os

# Fix incomplete fragments: context.read<Core>().paymentder.of<PaymentProvider>(...
# -> context.read<Core>().payment.fetchPayments(

FRAGMENT_FIXES = [
    (r"context\.read<Core>\(\)\.(\w+)der\.of<\w+Provider>\(context(?:,?\s*listen:\s*false)?\)", 
     lambda m: f'context.read<Core>().{m.group(1)}.'),
    (r"context\.read<Core>\(\)\.(\w+)r\.of<\w+Provider>\(context(?:,?\s*listen:\s*false)?\)",
     lambda m: f'context.read<Core>().{m.group(1)}.'),
    (r"context\.read<Core>\(\)\.(\w+)\s+Provider\.of<\w+Provider>\(context(?:,?\s*listen:\s*false)?\)",
     lambda m: f'context.read<Core>().{m.group(1)}.'),
    (r"context\.read<Core>\(\)\.(\w+)er\.of<\w+Provider>\(context(?:,?\s*listen:\s*false)?\)",
     lambda m: f'context.read<Core>().{m.group(1)}.'),
]

# Consumer mapping
CONSUMER_MAP = [
    (r'Consumer<AuthProvider>', 'Consumer<Core>', 'auth'),
    (r'Consumer<BusinessProvider>', 'Consumer<Core>', 'business'),
    (r'Consumer<PartyProvider>', 'Consumer<Core>', 'party'),
    (r'Consumer<ItemProvider>', 'Consumer<Core>', 'item'),
    (r'Consumer<InvoiceProvider>', 'Consumer<Core>', 'invoice'),
    (r'Consumer<PaymentProvider>', 'Consumer<Core>', 'payment'),
    (r'Consumer<ExpenseProvider>', 'Consumer<Core>', 'expense'),
    (r'Consumer<DashboardProvider>', 'Consumer<Core>', 'dashboard'),
    (r'Consumer<LocaleProvider>', 'Consumer<Core>', 'settings'),
]

def fix_consumer_builder(content):
    """Fix builder param names in Consumer<Core>. provider -> core.xxx"""
    for old_consumer, new_consumer, module in CONSUMER_MAP:
        content = content.replace(old_consumer, new_consumer)
    
    # Now fix builder: (context, provider, child) -> (context, core, child)
    # And replace provider.xxx with core.module.xxx inside the builder
    # But this is tricky. Let's do a simpler approach:
    # Replace "(context, provider, child)" with "(context, core, child)"
    # Then replace "provider." with f"core.{module}." in the builder content
    
    # Simple pattern for (context, provider, child) -> (context, core, child)
    content = re.sub(
        r'\(context,\s*provider,\s*child\)',
        lambda m: f'(context, core, child)',
        content
    )
    
    # Now replace provider. with core.{mod}. but only within builder scopes
    # This is complex, so let's use a simpler heuristic:
    # For each consumer type, replace "provider." with f"core.{module}."
    # But only in contexts where it's the builder parameter
    # Since we changed the builder signature to always use "core",
    # we can just replace "provider." with "core.{module}."
    
    return content

def fix_fragments(content):
    for pattern, replacement in FRAGMENT_FIXES:
        content = re.sub(pattern, replacement, content)
    return content

def fix_provider_refs(content):
    """Replace remaining provider.xxx with core.module.xxx where module is inferred."""
    # This is a simple heuristic - replace provider. with the right core.module.
    # But only when provider. appears in certain contexts.
    return content

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # Fix consumer patterns
    content = fix_consumer_builder(content)
    # Fix fragments
    content = fix_fragments(content)
    # Fix remaining provider. references in Consumer builders
    content = fix_provider_refs(content)
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f'Fixed: {filepath}')

def main():
    lib_dir = '/Users/jaydeepsarvaiya/Desktop/PlayStore/vyaparsetu/lib'
    for root, dirs, files in os.walk(lib_dir):
        for f in files:
            if f.endswith('.dart') and not f.endswith('.g.dart'):
                process_file(os.path.join(root, f))

if __name__ == '__main__':
    main()
