#!/usr/bin/env node
const chokidar = require('chokidar');
const isPhpFile = require('picomatch')('**/**.php');
const log = console.log.bind(console)

const watcher = chokidar.watch(['.', '/opt/packages'], {
  ignore: ['storage/', 'bootstrap/cache/'],
  ignoreInitial: true,
  awaitWriteFinish: {
    stabilityThreshold: 2500,
    pollInterval: 250,
  },
});

log('File watcher started');
watcher.on('all', (event, path) => {
  if (isPhpFile(path)) {
    log(`${event}: ${path}`);
    process.exit(0)
  }
});
