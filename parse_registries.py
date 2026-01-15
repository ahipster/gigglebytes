#!/usr/bin/env python3
"""
Script to parse the registries.md file and convert it into a proper markdown table.
The file contains 13 columns repeated line by line.
"""

import re

# Define the 13 column headers
HEADERS = [
    "Country",
    "Identifier / Registry Name",
    "Registry Type",
    "Legal Forms / Entity Types Covered",
    "Lookup URL",
    "Programmatic Access",
    "Manual Lookup",
    "Programmatic Access — Cost & Access",
    "Manual Access — Cost & Access",
    "API/Interface Type",
    "Change/Updates Access",
    "Data Model Docs",
    "Notes/Legal"
]

def parse_registries(input_file):
    """Parse the registries file and return structured data."""
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split by "Works cited" to separate data from citations
    parts = content.split("Works cited")
    data_section = parts[0].strip()
    
    # Split into lines
    lines = [line.strip() for line in data_section.split('\n')]
    
    # Skip the first 13 lines (headers) and filter out empty lines from data
    data_lines = lines[13:]
    data_lines = [line for line in data_lines if line.strip()]
    
    # Group lines into rows of 13 items
    rows = []
    current_row = []
    
    for line in data_lines:
        current_row.append(line)
        if len(current_row) == 13:
            rows.append(current_row)
            current_row = []
    
    # If there's an incomplete row at the end, add it anyway
    if current_row:
        rows.append(current_row)
    
    return rows

def escape_pipe(text):
    """Escape pipe characters in text for markdown tables."""
    return text.replace('|', '\\|')

def create_markdown_table(rows):
    """Create a markdown table from parsed rows."""
    # Escape pipes in header
    escaped_headers = [escape_pipe(h) for h in HEADERS]
    
    # Start with header
    table = "| " + " | ".join(escaped_headers) + " |\n"
    table += "|" + "|".join(["---"] * len(HEADERS)) + "|\n"
    
    # Add rows
    for row in rows:
        if len(row) == 13:
            escaped_row = [escape_pipe(cell) for cell in row]
            table += "| " + " | ".join(escaped_row) + " |\n"
    
    return table

def main():
    input_file = "/Users/agge/code/gigglebytes/research/registries.md"
    output_file = "/Users/agge/code/gigglebytes/research/registries_table.md"
    
    print("Parsing registries file...")
    rows = parse_registries(input_file)
    print(f"Found {len(rows)} rows of data")
    
    print("Creating markdown table...")
    table = create_markdown_table(rows)
    
    # Write to output file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(table)
    
    print(f"Table saved to {output_file}")
    print(f"\nFirst few rows of table:\n{chr(10).join(table.split(chr(10))[:5])}")

if __name__ == "__main__":
    main()
