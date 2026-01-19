const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    recordVideo: { dir: 'videos/' } // Save videos in the 'videos/' directory
  });

  // Start tracing
  await context.tracing.start({ screenshots: true, snapshots: true });

  // ensure videos directory exists
  const videosDir = path.join(process.cwd(), 'videos');
  if (!fs.existsSync(videosDir)) fs.mkdirSync(videosDir, { recursive: true });

  // We'll create one page per file so Playwright finalizes each video's file when the page is closed

  // Get all HTML files in mockups/pages/
  const pagesDir = path.join(process.cwd(), 'mockups/pages');
  const files = fs.readdirSync(pagesDir).filter(file => file.endsWith('.html'));

  for (const file of files) {
    const filePath = `file://${path.join(pagesDir, file).replace(/\\/g, '/')}`;
    console.log(`Opening ${filePath}`);

    try {
      // create a fresh page so Playwright writes a separate video file for each
      const page = await context.newPage();
      // Navigate to the page
      await page.goto(filePath, { waitUntil: 'load' });

      // Scroll through the page
      await page.evaluate(() => {
        window.scrollTo(0, 0);
        const scrollHeight = document.body.scrollHeight;
        let scrollY = 0;
        const step = 200;
        return new Promise(resolve => {
          const interval = setInterval(() => {
            scrollY += step;
            window.scrollTo(0, scrollY);
            if (scrollY >= scrollHeight) {
              clearInterval(interval);
              resolve();
            }
          }, 100);
        });
      });

      // Highlight interactions (e.g., clicking links)
      const links = await page.$$('a');
      for (const link of links) {
        try {
          if (await link.isVisible()) {
            await link.hover();
            await page.waitForTimeout(500);
            console.log(`Hovered over link: ${await link.getAttribute('href')}`);
          } else {
            console.log('Skipped invisible link');
          }
        } catch (hoverError) {
          console.error(`Error hovering over link: ${hoverError.message}`);
        }
      }

      console.log(`Finished demo for ${file}`);

      // close the page to finalize the video file and move it to a readable name
      try {
        const video = page.video();
        await page.close();
        if (video) {
          const tmpPath = await video.path();
          const base = path.parse(file).name;
          const dest = path.join(videosDir, `${base}.webm`);

          // helper: wait until file size is stable (file finished writing)
          const waitForFileReady = (filePath, timeout = 5000) => {
            const start = Date.now();
            let lastSize = -1;
            return new Promise((resolve, reject) => {
              const check = () => {
                try {
                  const st = fs.statSync(filePath);
                  const size = st.size;
                  if (size === lastSize && size > 0) return resolve();
                  lastSize = size;
                } catch (err) {
                  // file may not exist yet
                }
                if (Date.now() - start > timeout) return resolve();
                setTimeout(check, 200);
              };
              check();
            });
          };

          try {
            await waitForFileReady(tmpPath, 5000);
            try {
              fs.renameSync(tmpPath, dest);
              console.log(`Saved video: ${dest}`);
            } catch (renameErr) {
              // On Windows rename may fail if file is locked. Try copy+unlink as fallback.
              try {
                fs.copyFileSync(tmpPath, dest);
                fs.unlinkSync(tmpPath);
                console.log(`Saved video via copy: ${dest}`);
              } catch (copyErr) {
                console.error(`Failed to move or copy video to ${dest}: ${copyErr.message}`);
              }
            }
          } catch (waitErr) {
            console.error(`Timed out waiting for video file ${tmpPath}: ${waitErr?.message || waitErr}`);
          }
        }
      } catch (closeErr) {
        console.error(`Error finalizing video for ${file}: ${closeErr.message}`);
      }
    } catch (pageError) {
      console.error(`Error processing ${file}: ${pageError.message}`);
    }
  }

  // Stop tracing and save the trace to trace.zip
  await context.tracing.stop({ path: 'trace.zip' });

  await browser.close();
  console.log('Demo completed for all pages. Videos saved in the "videos/" directory and trace saved as "trace.zip".');
})();
