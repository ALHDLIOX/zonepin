#!/usr/bin/env node

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const packageRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const appName = 'ZonePin.app';
const bundleId = 'com.epsaliox.WorldMenuClock'; // Retained to preserve existing clock preferences.

function run(command, args, options = {}) {
  const result = spawnSync(command, args, { encoding: 'utf8', ...options });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    const output = [result.stderr, result.stdout].filter(Boolean).join('\n').trim();
    throw new Error(`${command} failed${output ? `: ${output}` : ''}`);
  }
  return `${result.stdout || ''}${result.stderr || ''}`;
}

function identifierOf(appPath) {
  return run('/usr/libexec/PlistBuddy', [
    '-c', 'Print CFBundleIdentifier', path.join(appPath, 'Contents', 'Info.plist')
  ]).trim();
}

function main() {
  const args = process.argv.slice(2);
  if (args.length === 1 && (args[0] === '--help' || args[0] === '-h')) {
    console.log('Usage: npx zonepin [--no-open]\nBuilds ZonePin from source and installs it in ~/Applications.');
    return;
  }
  if (args.some(arg => arg !== '--no-open') || args.length > 1) {
    throw new Error('Unknown option. Use --help for usage.');
  }
  if (process.platform !== 'darwin' || !['arm64', 'x64'].includes(process.arch)) {
    throw new Error('ZonePin requires macOS on Apple silicon or Intel.');
  }
  const macVersion = run('/usr/bin/sw_vers', ['-productVersion']).trim();
  if (Number(macVersion.split('.')[0]) < 13) {
    throw new Error('ZonePin requires macOS 13 or later.');
  }
  try {
    run('/usr/bin/xcrun', ['--sdk', 'macosx', '--show-sdk-path']);
  } catch {
    throw new Error('Install Xcode Command Line Tools first: xcode-select --install');
  }

  const applications = path.join(os.homedir(), 'Applications');
  const destination = path.join(applications, appName);
  if (fs.existsSync(destination) && identifierOf(destination) !== bundleId) {
    throw new Error(`${destination} belongs to another app. Move it yourself before retrying.`);
  }
  const running = spawnSync('/usr/bin/pgrep', ['-x', 'ZonePin'], { stdio: 'ignore' });
  if (running.status === 0) {
    throw new Error('Quit ZonePin from its menu before installing or updating it.');
  }

  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), 'zonepin-build-'));
  let staging;
  try {
    fs.cpSync(path.join(packageRoot, 'app'), path.join(workspace, 'app'), { recursive: true });
    fs.mkdirSync(path.join(workspace, 'scripts'));
    fs.copyFileSync(path.join(packageRoot, 'scripts', 'build.sh'), path.join(workspace, 'scripts', 'build.sh'));
    console.log('Building ZonePin for Apple silicon and Intel…');
    run('/bin/zsh', [path.join(workspace, 'scripts', 'build.sh')]);

    const builtApp = path.join(workspace, 'dist', appName);
    if (identifierOf(builtApp) !== bundleId) {
      throw new Error('The build produced an unexpected app.');
    }
    run('/usr/bin/codesign', ['--verify', '--deep', '--strict', builtApp]);

    fs.mkdirSync(applications, { recursive: true });
    staging = fs.mkdtempSync(path.join(applications, '.zonepin-'));
    const stagedApp = path.join(staging, appName);
    run('/usr/bin/ditto', [builtApp, stagedApp]);
    let backup;
    if (fs.existsSync(destination)) {
      backup = path.join(staging, 'previous.app');
      fs.renameSync(destination, backup);
    }
    try {
      fs.renameSync(stagedApp, destination);
    } catch (error) {
      if (backup) fs.renameSync(backup, destination);
      throw error;
    }
    console.log(`Installed ZonePin in ${destination}`);
    if (!args.includes('--no-open')) {
      try {
        run('/usr/bin/open', [destination]);
      } catch (error) {
        console.warn(`The app is installed, but could not open automatically: ${error.message}`);
      }
    }
  } finally {
    fs.rmSync(workspace, { recursive: true, force: true });
    if (staging) fs.rmSync(staging, { recursive: true, force: true });
  }
}

try {
  main();
} catch (error) {
  console.error(`zonepin: ${error.message}`);
  process.exitCode = 1;
}
