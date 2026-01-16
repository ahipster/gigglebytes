import random
import datetime

def parse_markdown_table(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()

    # Skip header and separator
    data_lines = lines[2:]
    
    registries = []
    
    for line in data_lines:
        if not line.strip():
            continue
            
        # Split by pipe and strip whitespace
        cols = [c.strip() for c in line.split('|')]
        
        # Markdown table lines usually start and end with |, so we slice [1:-1]
        if len(cols) >= 14: # ensure enough columns
            clean_cols = cols[1:-1]
            registries.append({
                'country': clean_cols[0],
                'name': clean_cols[1],
                'type': clean_cols[2],
                'entity_types': clean_cols[3],
                'url': clean_cols[4]
            })
            
    return registries

def generate_html_rows(registries):
    html = ""
    
    statuses = [
        {'label': 'Active', 'color': 'bg-emerald-100 text-emerald-700', 'dot': 'bg-emerald-500'},
        {'label': 'Partial', 'color': 'bg-amber-100 text-amber-700', 'dot': 'bg-amber-500'},
        {'label': 'Error', 'color': 'bg-red-100 text-red-700', 'dot': 'bg-red-500'},
        {'label': 'Not Integrated', 'color': 'bg-gray-100 text-gray-600', 'dot': 'bg-gray-400'}
    ]
    
    for idx, reg in enumerate(registries):
        # Deterministic-ish random for stability
        is_integrated = idx % 5 != 0 # 80% integrated
        
        if is_integrated:
            status = statuses[idx % 3] # Active, Partial, or Error
            dq_score = random.randint(70, 100)
            if status['label'] == 'Error':
                dq_score = random.randint(40, 60)
            
            # Random date in last 24h
            hours_ago = random.randint(0, 24)
            last_ingest = f"{hours_ago}h ago"
        else:
            status = statuses[3] # Not Integrated
            dq_score = 0
            last_ingest = "-"
            
        dq_color = "text-emerald-600"
        if dq_score < 70: dq_color = "text-amber-600"
        if dq_score < 50: dq_color = "text-red-600"
        
        if dq_score == 0: dq_color = "text-gray-400"
        
        # Link to details page
        # Passing mock ID and name parameters
        row_onclick = f"window.location.href='source-detail.html?id={idx}&country={reg['country']}&name={reg['name']}'"
        
        html += f"""
        <tr class="hover:bg-gray-50 transition-colors cursor-pointer group" onclick="{row_onclick}">
            <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-bold text-gray-900">{reg['country']}</div>
            </td>
            <td class="px-6 py-4">
                <div class="text-sm font-semibold text-blue-600 group-hover:underline">{reg['name']}</div>
                <div class="text-xs text-gray-500 mt-0.5">{reg['type']}</div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {status['color']}">
                    <span class="w-1.5 h-1.5 {status['dot']} rounded-full mr-1.5"></span>
                    {status['label']}
                </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 font-mono">
                {last_ingest}
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                    <div class="w-16 bg-gray-200 rounded-full h-1.5 mr-2">
                        <div class="bg-blue-600 h-1.5 rounded-full" style="width: {dq_score}%"></div>
                    </div>
                    <span class="text-xs font-bold {dq_color}">{dq_score}%</span>
                </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <span class="text-gray-400 group-hover:text-blue-500 transition-colors">→</span>
            </td>
        </tr>
        """
        
    return html

if __name__ == "__main__":
    registries = parse_markdown_table("req/registries_table.md")
    html = generate_html_rows(registries)
    
    # Write to a partial file or print
    with open("registries_rows.html", "w") as f:
        f.write(html)
        
    print(f"Generated {len(registries)} rows to registries_rows.html")
