/**
 * GRIP - Comprehensive UI Mockups Demo
 * Full walkthrough of all pages with visual interaction highlights
 * 
 * Viewport: 1280x720 (HD, less than Full HD)
 * Max step duration: 500ms
 */

const { chromium } = require('playwright');
const path = require('path');

const VIEWPORT = { width: 1280, height: 720 };
const STEP_DELAY = 400; // ms per step (under 500ms)
const SCROLL_DELAY = 300;
const HIGHLIGHT_DURATION = 250;

// All mockup pages organized by category
const PAGES = {
  core: [
    { name: 'Login', file: 'login.html', interactions: ['#email', '#password', 'button[type="submit"]'] },
    { name: 'Dashboard', file: 'dashboard.html', interactions: ['#sidebar nav a', '.bg-white.rounded-xl'] },
    { name: 'Audit Log', file: 'audit-log.html', interactions: ['table', 'input', 'select'] },
    { name: 'User Management', file: 'user-management.html', interactions: ['table', 'button'] },
    { name: 'Edit User Permissions', file: 'edit-user-permissions.html', interactions: ['input[type="checkbox"]', 'button'] },
  ],
  entity: [
    { name: 'Entity Search', file: 'entity-search.html', interactions: ['#entity-name-input', 'table', 'button'] },
    { name: 'Entity Detail', file: 'entity-detail.html', interactions: ['table', 'a', 'button'] },
    { name: 'Establish Entity', file: 'entity-establish.html', interactions: ['input', 'select', 'button'] },
    { name: 'Edit Entity', file: 'edit-entity.html', interactions: ['input', 'textarea', 'button'] },
    { name: 'Family Tree', file: 'view-family-tree.html', interactions: ['svg', 'button'] },
    { name: 'Upwards Tree', file: 'view-upwards-tree.html', interactions: ['svg', 'button'] },
  ],
  registry: [
    { name: 'Entity Resolution', file: 'entity-resolution.html', interactions: ['table', 'button', 'input'] },
    { name: 'Entity Evidence', file: 'entity-evidence.html', interactions: ['table', 'button'] },
    { name: 'Entity Review', file: 'entity-review.html', interactions: ['button', 'textarea'] },
  ],
  lineage: [
    { name: 'Lineage Overview', file: 'lineage-overview.html', interactions: ['table', 'button'] },
    { name: 'View Lineage', file: 'view-lineage.html', interactions: ['svg', 'button'] },
    { name: 'View Diff', file: 'view-diff.html', interactions: ['table', '.diff'] },
    { name: 'Task Queue', file: 'task-queue.html', interactions: ['table', 'select', 'button'] },
    { name: 'Manage Task', file: 'manage-task.html', interactions: ['textarea', 'button', 'select'] },
  ],
  config: [
    { name: 'DQ Rules', file: 'dq-rules.html', interactions: ['table', 'button'] },
    { name: 'Create DQ Rule Template', file: 'create-dq-rule-template.html', interactions: ['input', 'select', 'button'] },
    { name: 'Manage DQ Rule', file: 'manage-dq-rule.html', interactions: ['input', 'select', 'button'] },
    { name: 'ER Rules', file: 'er-rules.html', interactions: ['table', 'button'] },
    { name: 'Manage ER Rule', file: 'manage-er-rule.html', interactions: ['input', 'select', 'button'] },
    { name: 'Survivorship Rules', file: 'survivorship-rules.html', interactions: ['table', 'button'] },
    { name: 'Snapshot Export', file: 'snapshot-export.html', interactions: ['button', 'input'] },
  ],
  source: [
    { name: 'Source Detail (Registry Inventory)', file: 'source-detail.html', interactions: ['table', 'button', 'input'] },
    { name: 'Source Profile', file: 'source-profile.html', interactions: ['table', 'button'] },
    { name: 'Mapping Studio', file: 'mapping-studio.html', interactions: ['table', 'button', 'select'] },
  ]
};

// CSS for visual highlights injected into pages
const HIGHLIGHT_CSS = `
  .demo-highlight {
    position: relative;
    z-index: 9999;
  }
  .demo-highlight::before {
    content: '';
    position: absolute;
    top: -4px;
    left: -4px;
    right: -4px;
    bottom: -4px;
    border: 3px solid #3B82F6;
    border-radius: 8px;
    animation: demo-pulse 0.3s ease-in-out;
    pointer-events: none;
    z-index: 9999;
  }
  @keyframes demo-pulse {
    0% { transform: scale(1); opacity: 0; }
    50% { transform: scale(1.02); opacity: 1; }
    100% { transform: scale(1); opacity: 1; }
  }
  .demo-click-indicator {
    position: fixed;
    width: 30px;
    height: 30px;
    border-radius: 50%;
    background: rgba(59, 130, 246, 0.5);
    border: 3px solid #3B82F6;
    pointer-events: none;
    z-index: 99999;
    animation: demo-click 0.4s ease-out forwards;
  }
  @keyframes demo-click {
    0% { transform: translate(-50%, -50%) scale(0); opacity: 1; }
    100% { transform: translate(-50%, -50%) scale(2); opacity: 0; }
  }
  .demo-page-transition {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(99, 102, 241, 0.1));
    z-index: 99998;
    animation: demo-fade 0.3s ease-out forwards;
    pointer-events: none;
  }
  @keyframes demo-fade {
    0% { opacity: 1; }
    100% { opacity: 0; }
  }
  .demo-label {
    position: fixed;
    top: 16px;
    right: 16px;
    background: linear-gradient(135deg, #3B82F6, #6366F1);
    color: white;
    padding: 8px 16px;
    border-radius: 8px;
    font-family: 'Inter', sans-serif;
    font-size: 14px;
    font-weight: 600;
    z-index: 99999;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
    animation: demo-slide-in 0.3s ease-out;
  }
  @keyframes demo-slide-in {
    0% { transform: translateX(100px); opacity: 0; }
    100% { transform: translateX(0); opacity: 1; }
  }
  .demo-progress-bar {
    position: fixed;
    bottom: 0;
    left: 0;
    height: 4px;
    background: linear-gradient(90deg, #3B82F6, #6366F1);
    z-index: 99999;
    transition: width 0.3s ease-out;
  }
  .demo-section-banner {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: linear-gradient(135deg, #1E293B, #334155);
    color: white;
    padding: 24px 48px;
    border-radius: 16px;
    font-family: 'Inter', sans-serif;
    z-index: 99999;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
    text-align: center;
    animation: demo-banner-pop 0.4s ease-out;
  }
  .demo-section-banner h2 {
    font-size: 24px;
    font-weight: 700;
    margin-bottom: 8px;
  }
  .demo-section-banner p {
    font-size: 14px;
    opacity: 0.7;
  }
  @keyframes demo-banner-pop {
    0% { transform: translate(-50%, -50%) scale(0.8); opacity: 0; }
    100% { transform: translate(-50%, -50%) scale(1); opacity: 1; }
  }
`;

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function injectStyles(page) {
  await page.addStyleTag({ content: HIGHLIGHT_CSS });
}

async function showPageLabel(page, text) {
  await page.evaluate((label) => {
    const existing = document.querySelector('.demo-label');
    if (existing) existing.remove();
    
    const div = document.createElement('div');
    div.className = 'demo-label';
    div.textContent = label;
    document.body.appendChild(div);
  }, text);
}

async function showProgress(page, percent) {
  await page.evaluate((p) => {
    let bar = document.querySelector('.demo-progress-bar');
    if (!bar) {
      bar = document.createElement('div');
      bar.className = 'demo-progress-bar';
      document.body.appendChild(bar);
    }
    bar.style.width = `${p}%`;
  }, percent);
}

async function showSectionBanner(page, title, subtitle) {
  await page.evaluate(({ title, subtitle }) => {
    const banner = document.createElement('div');
    banner.className = 'demo-section-banner';
    banner.innerHTML = `<h2>${title}</h2><p>${subtitle}</p>`;
    document.body.appendChild(banner);
    setTimeout(() => banner.remove(), 800);
  }, { title, subtitle });
  await sleep(900);
}

async function showPageTransition(page) {
  await page.evaluate(() => {
    const overlay = document.createElement('div');
    overlay.className = 'demo-page-transition';
    document.body.appendChild(overlay);
    setTimeout(() => overlay.remove(), 300);
  });
}

async function showClickAt(page, x, y) {
  await page.evaluate(({ x, y }) => {
    const indicator = document.createElement('div');
    indicator.className = 'demo-click-indicator';
    indicator.style.left = `${x}px`;
    indicator.style.top = `${y}px`;
    document.body.appendChild(indicator);
    setTimeout(() => indicator.remove(), 400);
  }, { x, y });
}

async function highlightElement(page, selector) {
  try {
    const element = await page.$(selector);
    if (element) {
      await element.evaluate(el => {
        el.classList.add('demo-highlight');
        setTimeout(() => el.classList.remove('demo-highlight'), 300);
      });
      await sleep(HIGHLIGHT_DURATION);
    }
  } catch (e) {
    // Element not found, skip
  }
}

async function highlightAndClick(page, selector) {
  try {
    const element = await page.$(selector);
    if (element) {
      const box = await element.boundingBox();
      if (box) {
        await highlightElement(page, selector);
        const x = box.x + box.width / 2;
        const y = box.y + box.height / 2;
        await showClickAt(page, x, y);
        await sleep(150);
      }
    }
  } catch (e) {
    // Skip if element not interactable
  }
}

async function scrollPage(page) {
  const scrollHeight = await page.evaluate(() => document.body.scrollHeight);
  const viewportHeight = VIEWPORT.height;
  
  if (scrollHeight > viewportHeight) {
    const steps = Math.ceil((scrollHeight - viewportHeight) / (viewportHeight * 0.6));
    for (let i = 0; i < steps; i++) {
      await page.evaluate((y) => window.scrollBy({ top: y, behavior: 'smooth' }), viewportHeight * 0.6);
      await sleep(SCROLL_DELAY);
    }
    // Scroll back to top
    await page.evaluate(() => window.scrollTo({ top: 0, behavior: 'smooth' }));
    await sleep(SCROLL_DELAY);
  }
}

async function interactWithPage(page, interactions) {
  for (const selector of interactions) {
    try {
      const elements = await page.$$(selector);
      // Interact with first 2-3 elements of each type
      const count = Math.min(elements.length, 2);
      for (let i = 0; i < count; i++) {
        const el = elements[i];
        const box = await el.boundingBox();
        if (box && box.y < VIEWPORT.height) {
          await highlightAndClick(page, `${selector}:nth-of-type(${i + 1})`);
        }
      }
    } catch (e) {
      // Skip if selector fails
    }
  }
}

async function visitPage(page, basePath, pageInfo, progress, total) {
  const url = `file:///${basePath}/${pageInfo.file}`;
  
  console.log(`  📄 ${pageInfo.name}`);
  
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await injectStyles(page);
  await showPageTransition(page);
  await showPageLabel(page, `${pageInfo.name}`);
  await showProgress(page, (progress / total) * 100);
  
  await sleep(STEP_DELAY);
  
  // Interact with key elements
  await interactWithPage(page, pageInfo.interactions);
  
  // Scroll through page content
  await scrollPage(page);
  
  await sleep(STEP_DELAY);
}

async function runDemo() {
  console.log('\n🎬 GRIP UI MOCKUPS - COMPREHENSIVE DEMO\n');
  console.log(`   Viewport: ${VIEWPORT.width}x${VIEWPORT.height}`);
  console.log(`   Step Delay: ${STEP_DELAY}ms\n`);
  
  const browser = await chromium.launch({
    headless: false,
    args: ['--start-maximized']
  });
  
  const context = await browser.newContext({
    viewport: VIEWPORT,
    recordVideo: {
      dir: path.resolve(__dirname, '../videos'), // Directory to save videos
      size: VIEWPORT // Match the viewport size
    }
  });
  
  const page = await context.newPage();
  
  const basePath = path.resolve(__dirname, '../mockups/pages').replace(/\\/g, '/');
  const indexPath = path.resolve(__dirname, '../mockups/index.html').replace(/\\/g, '/');
  
  // Count total pages
  const totalPages = Object.values(PAGES).flat().length + 1; // +1 for index
  let currentPage = 0;
  
  try {
    // Start with index page
    console.log('📋 MOCKUPS INDEX\n');
    await page.goto(`file:///${indexPath}`, { waitUntil: 'domcontentloaded' });
    await injectStyles(page);
    await showPageLabel(page, 'GRIP Mockups Index');
    await showProgress(page, 0);
    await sleep(STEP_DELAY);
    
    // Highlight category cards
    const cards = await page.$$('.group.bg-white.rounded-2xl');
    for (let i = 0; i < Math.min(cards.length, 6); i++) {
      await highlightAndClick(page, `.group.bg-white.rounded-2xl:nth-of-type(${i + 1})`);
    }
    
    await scrollPage(page);
    currentPage++;
    
    // Visit each category
    const categories = [
      { key: 'core', title: 'Core Screens', subtitle: 'Authentication & Administration' },
      { key: 'entity', title: 'Entity Management', subtitle: 'Search, View & Manage Entities' },
      { key: 'registry', title: 'Registry Onboarding', subtitle: 'Resolution & Evidence' },
      { key: 'lineage', title: 'Lineage & Governance', subtitle: 'Data Provenance & Quality' },
      { key: 'config', title: 'Configuration & Rules', subtitle: 'DQ, ER & Survivorship' },
      { key: 'source', title: 'Source Connectivity', subtitle: 'Registry Integration' },
    ];
    
    for (const category of categories) {
      console.log(`\n🏷️  ${category.title.toUpperCase()}\n`);
      
      // Show section banner
      await showSectionBanner(page, category.title, category.subtitle);
      
      for (const pageInfo of PAGES[category.key]) {
        currentPage++;
        await visitPage(page, basePath, pageInfo, currentPage, totalPages);
      }
    }
    
    // Final summary
    console.log('\n\n✅ DEMO COMPLETE!\n');
    console.log(`   Total pages visited: ${totalPages}`);
    
    await page.goto(`file:///${indexPath}`, { waitUntil: 'domcontentloaded' });
    await injectStyles(page);
    await showProgress(page, 100);
    await showPageLabel(page, '✓ Demo Complete');
    
    await sleep(2000);
    
  } catch (error) {
    console.error('Demo error:', error);
  } finally {
    await browser.close();
  }
}

// Run the demo
runDemo().catch(console.error);
