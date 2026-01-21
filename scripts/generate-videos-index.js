const fs = require('fs');
const path = require('path');

const videosDir = path.join(process.cwd(), 'videos');
const outFile = path.join(videosDir, 'list.json');

function guessType(file) {
  const ext = path.extname(file).toLowerCase();
  if (ext === '.mp4') return 'video/mp4';
  if (ext === '.webm') return 'video/webm';
  if (ext === '.ogg' || ext === '.ogv') return 'video/ogg';
  return 'application/octet-stream';
}

if (!fs.existsSync(videosDir)) {
  console.error('videos directory does not exist:', videosDir);
  process.exit(1);
}

const files = fs.readdirSync(videosDir)
  .filter(f => ['.mp4', '.webm', '.ogg', '.ogv'].includes(path.extname(f).toLowerCase()))
  .map(f => ({ file: f, type: guessType(f), title: path.parse(f).name }))
  .sort((a,b) => a.title.localeCompare(b.title, undefined, { sensitivity: 'base' }));

fs.writeFileSync(outFile, JSON.stringify(files, null, 2), 'utf8');
console.log('Wrote', outFile, 'with', files.length, 'entries');
