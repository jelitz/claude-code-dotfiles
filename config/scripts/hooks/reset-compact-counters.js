#!/usr/bin/env node
/**
 * Strategic Compact - post-compaction counter reset
 *
 * Runs on PostCompact. The suggest-compact.js hook tracks two per-session
 * signals in temp-dir state files: a tool-call counter and a context-size
 * "bucket" high-water mark. Neither resets when the conversation is
 * compacted (manual /compact or Claude Code's own auto-compact), because
 * Claude Code keeps the same session_id across a compaction.
 *
 * Left alone this causes two symptoms:
 * - The tool-call counter keeps climbing past the compact boundary, so the
 *   "N calls reached" nudge keeps firing on the old schedule even though
 *   the conversation is now much smaller.
 * - The context-size bucket keeps its pre-compact high-water mark, so if
 *   context grows back up to the threshold later, the (lower) recomputed
 *   bucket compares <= the stale mark and the signal stays silent when it
 *   should fire again.
 *
 * Deleting both state files after a compaction lets both signals start
 * fresh against the post-compaction context, matching reality.
 */

const fs = require('fs');
const path = require('path');
const { getTempDir, readStdinJson, log } = require('../lib/utils');

const COUNTER_FILE_PREFIX = 'claude-tool-count-';
const CONTEXT_BUCKET_FILE_PREFIX = 'claude-context-bucket-';

async function main() {
  let input = {};
  try {
    input = await readStdinJson({ timeoutMs: 1000 });
  } catch {
    input = {};
  }

  const rawSessionId = (input && typeof input.session_id === 'string' && input.session_id)
    ? input.session_id
    : (process.env.CLAUDE_SESSION_ID || 'default');
  const sessionId = rawSessionId.replace(/[^a-zA-Z0-9_-]/g, '') || 'default';

  const tempDir = getTempDir();
  const files = [
    path.join(tempDir, `${COUNTER_FILE_PREFIX}${sessionId}`),
    path.join(tempDir, `${CONTEXT_BUCKET_FILE_PREFIX}${sessionId}`)
  ];

  for (const file of files) {
    try {
      fs.rmSync(file, { force: true });
    } catch (err) {
      log(`[StrategicCompact] Failed to reset ${file}: ${err.message}`);
    }
  }

  process.exit(0);
}

main().catch(err => {
  console.error('[StrategicCompact] Error:', err.message);
  process.exit(0);
});
