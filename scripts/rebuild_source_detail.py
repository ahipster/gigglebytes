
import os
import re

def rebuild():
    # Paths
    dashboard_path = "mockups/pages/dashboard.html"
    rows_path = "registries_rows.html"
    output_path = "mockups/pages/source-detail.html"

    # Read Dashboard Template
    with open(dashboard_path, "r") as f:
        template = f.read()

    # Read Rows
    with open(rows_path, "r") as f:
        rows = f.read()

    # Fix Rows Links
    rows = rows.replace("source-detail.html?", "source-profile.html?")

    # Customize Template
    # 1. Title
    template = template.replace("<title>Dashboard - GRIP</title>", "<title>Sources - GRIP</title>")
    template = template.replace('<h1 class="text-xl font-semibold text-gray-900">Dashboard</h1>', '<h1 class="text-xl font-semibold text-gray-900">Sources</h1>')

    # 2. Main Content
    # We want to replace everything inside <main ...> ... </main> with our table
    # But dashboard.html main has specific stats grid. Let's find the main block.
    
    # Construct the table HTML
    table_html = f"""
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50">
                    <div>
                        <h3 class="font-bold text-gray-900">Global Registries</h3>
                        <p class="text-sm text-gray-500">Monitoring 350+ data sources</p>
                    </div>
                    <div class="flex space-x-2">
                        <input type="text" placeholder="Search sources..." class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                        <button class="px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm text-gray-600 hover:bg-gray-50">Filter</button>
                    </div>
                </div>
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Country</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Registry Name</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Integration</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Ingest</th>
                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">DQ Score</th>
                            <th scope="col" class="relative px-6 py-3"><span class="sr-only">View</span></th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        {rows}
                    </tbody>
                </table>
            </div>
    """

    # Regex to replace inner HTML of main
    # <main class="flex-1 overflow-y-auto p-8 bg-gray-50"> ... </main>
    pattern = re.compile(r'(<mainclass="flex-1 overflow-y-auto p-8 bg-gray-50">)(.*?)(</main>)', re.DOTALL)
    # The dashboard might have spaces in attributes differently than my regex strictness
    # Let's try to match slightly looser or just find the main tag indices
    
    start_marker = '<!-- Scrollable Content -->'
    end_marker = '</body>' 
    # This is risky if markers change.
    
    # Better approach: Replace the whole main tag using a known unique string from dashboard.html
    # In dashboard.html we saw: <main class="flex-1 overflow-y-auto p-8 bg-gray-50">
    
    new_main_tag = f'<main class="flex-1 overflow-y-auto p-8 bg-gray-50">{table_html}</main>'
    
    # Since we verified dashboard.html content, we can regex replace the main block
    content_pattern = re.compile(r'<main class="flex-1 overflow-y-auto p-8 bg-gray-50">.*?</main>', re.DOTALL)
    
    if content_pattern.search(template):
        final_html = content_pattern.sub(new_main_tag, template)
    else:
        # Fallback if regex fails (e.g. whitespace diffs), just rewrite body inner
        # But regex should work given we just read it.
        print("Regex failed to find main block, aborting to avoid corruption.")
        return

    # 3. Sidebar Active State (will be handled by update_sidebars.py, but good to have correct base)
    # We leave that to the other script which is proven to work on sidebars.

    with open(output_path, "w") as f:
        f.write(final_html)
    
    print(f"Successfully rebuilt {output_path}")

if __name__ == "__main__":
    rebuild()
