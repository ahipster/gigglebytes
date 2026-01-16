import os
import re

NAV_TEMPLATE = """<nav class="space-y-1">
                <a href="dashboard.html"
                    class="flex items-center px-3 py-2 text-sm font-medium {dashboard_class} rounded-lg group transition-colors">
                    <span class="mr-3 text-xl">📊</span> Dashboard
                </a>
                <a href="entity-search.html"
                    class="flex items-center px-3 py-2 text-sm font-medium {entity_class} rounded-lg group transition-colors">
                    <span class="mr-3 text-xl">🔍</span> Entity Search
                </a>
                <a href="lineage-overview.html"
                    class="flex items-center px-3 py-2 text-sm font-medium {lineage_class} rounded-lg group transition-colors">
                    <span class="mr-3 text-xl">🌲</span> Lineage Mapping
                </a>
                <a href="task-queue.html"
                    class="flex items-center px-3 py-2 text-sm font-medium {task_class} rounded-lg group transition-colors">
                    <span class="mr-3 text-xl">📋</span> Task Queue
                    <span
                        class="ml-auto bg-blue-600 text-white py-0.5 px-2 rounded-full text-[10px] font-bold">12</span>
                </a>

                <div class="pt-4 pb-2">
                    <p class="px-3 text-xs font-semibold text-slate-500 uppercase tracking-wider font-bold">
                        Configuration</p>
                </div>

                <a href="source-detail.html"
                    class="flex items-center px-3 py-2 text-sm font-medium {source_class} rounded-lg group transition-colors">
                    <span class="mr-3 text-xl">💚</span> Sources
                </a>
                <a href="dq-rules.html"
                    class="flex items-center px-3 py-2 text-sm font-medium {dq_class} rounded-lg group transition-colors">
                    <span class="mr-3 text-xl">✅</span> DQ Rules
                </a>
            </nav>"""

ACTIVE_CLASS = "bg-slate-800 text-white"
INACTIVE_CLASS = "text-slate-300 hover:bg-slate-800 hover:text-white"

FILES_MAP = {
    "dashboard.html": "dashboard",
    "entity-search.html": "entity",
    "entity-detail.html": "entity",
    "entity-establish.html": "entity",
    "edit-entity.html": "entity",
    "entity-resolution.html": "entity",
    "entity-review.html": "entity",
    "entity-evidence.html": "entity",
    "view-diff.html": "entity",
    "view-family-tree.html": "entity",
    "view-upwards-tree.html": "entity",
    "lineage-overview.html": "lineage",
    "lineage-view.html": "lineage",
    "view-lineage.html": "lineage",
    "task-queue.html": "task",
    "manage-task.html": "task",
    "source-detail.html": "source",
    "source-profile.html": "source",
    "dq-rules.html": "dq",
}

DIR = "mockups/pages"

def update_file(filename):
    if filename not in FILES_MAP:
        # print(f"Skipping {filename} (no mapping)")
        return

    key = FILES_MAP[filename]
    
    dashboard_cls = ACTIVE_CLASS if key == "dashboard" else INACTIVE_CLASS
    entity_cls = ACTIVE_CLASS if key == "entity" else INACTIVE_CLASS
    lineage_cls = ACTIVE_CLASS if key == "lineage" else INACTIVE_CLASS
    task_cls = ACTIVE_CLASS if key == "task" else INACTIVE_CLASS
    source_cls = ACTIVE_CLASS if key == "source" else INACTIVE_CLASS
    dq_cls = ACTIVE_CLASS if key == "dq" else INACTIVE_CLASS

    new_nav = NAV_TEMPLATE.format(
        dashboard_class=dashboard_cls,
        entity_class=entity_cls,
        lineage_class=lineage_cls,
        task_class=task_cls,
        source_class=source_cls,
        dq_class=dq_cls
    )

    path = os.path.join(DIR, filename)
    try:
        with open(path, "r") as f:
            content = f.read()
        
        # Regex to find the nav block
        # Looking for <nav class="space-y-1"> ... </nav>
        # Dotall to match newlines
        pattern = re.compile(r'<nav class="space-y-1">.*?</nav>', re.DOTALL)
        
        if pattern.search(content):
            new_content = pattern.sub(new_nav, content)
            with open(path, "w") as f:
                f.write(new_content)
            print(f"Updated {filename}")
        else:
            print(f"Nav not found in {filename}")

    except Exception as e:
        print(f"Error updating {filename}: {e}")

if __name__ == "__main__":
    print("Starting sidebar updates...")
    for f in os.listdir(DIR):
        if f.endswith(".html"):
            update_file(f)
    print("Done.")
