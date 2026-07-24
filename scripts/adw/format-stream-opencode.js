#!/usr/bin/env node
/**
 * Render `opencode run --format json` as readable, colorized live output.
 *
 * Reads OpenCode's JSON event stream (one JSON object per line) on stdin and
 * prints, as events arrive: orchestrator text, a compact one-liner per tool
 * call (with the tool result), framed subagent blocks, and errors. Output is
 * color-coded by tool kind so the viewer can tell at a glance who is doing
 * what.
 *
 * Used by scripts/adw/run.sh so the ADW loop (OpenCode engine) can be watched
 * live in the terminal while the raw jsonl is tee'd to a file for the
 * NO-MORE-TASKS grep — mirroring format-stream.py (Claude engine), plus color
 * and a structured subagent block.
 *
 * Note on subagents: OpenCode does NOT stream the inner steps of a `task`
 * tool call as separate events. The whole subagent run appears as a single
 * `tool_use` event whose `state.output` holds the final `<task_result>`
 * block and whose `state.metadata` carries the subagent's session id and
 * model. We render a framed block for `task` so the viewer sees which
 * subagent was spawned (type, description), its model, and what it returned
 * — even though its inner tool calls are not visible.
 */
"use strict";

const { EOL } = require("os");

// --- color setup -----------------------------------------------------------
// Respect NO_COLOR (https://no-color.org/) and non-TTY sinks (e.g. piped
// into a file). When colors are off, the codes collapse to "" and output
// stays plain. Force-on via CLICOLOR_FORCE=1 for piping into `less -R` etc.
function colorOn() {
  if (process.env.NO_COLOR) return false;
  if (process.env.CLICOLOR_FORCE) return true;
  return process.stdout.isTTY === true;
}

const COLORS = colorOn();
const C = COLORS
  ? {
      RESET: "\x1b[0m",
      DIM: "\x1b[2m",
      BOLD: "\x1b[1m",
      ORCH: "\x1b[38;5;39m",      // bright blue — orchestrator
      SUB: "\x1b[38;5;141m",      // purple — subagent block
      READ: "\x1b[38;5;108m",     // green — read/glob/grep (information in)
      WRITE: "\x1b[38;5;204m",    // pink/red — edit/write (mutation)
      BASH: "\x1b[38;5;215m",     // orange — bash (action)
      TODO: "\x1b[38;5;117m",     // light cyan — todowrite
      OTHER: "\x1b[38;5;250m",    // grey — anything else
      RESULT: "\x1b[38;5;245m",   // grey — result snippet
      STATUS: "\x1b[38;5;245m",
      STEP: "\x1b[38;5;240m",     // dark grey — step end
      ERROR: "\x1b[38;5;196m",    // red — error
      WARN: "\x1b[38;5;220m",     // yellow — non-JSON passthrough
    }
  : {
      RESET: "", DIM: "", BOLD: "",
      ORCH: "", SUB: "", READ: "", WRITE: "", BASH: "", TODO: "",
      OTHER: "", RESULT: "", STATUS: "", STEP: "", ERROR: "", WARN: "",
    };

// --- per-tool presentation -------------------------------------------------
// icon + label + color for each tool kind, so a glance distinguishes
// "information in" (read) vs "mutation" (edit) vs "action" (bash) vs
// "delegation" (task).
const TOOL_STYLE = {
  bash:      ["▶", "bash",   C.BASH],
  read:      ["▹", "read",   C.READ],
  glob:      ["▹", "glob",   C.READ],
  grep:      ["▹", "grep",   C.READ],
  edit:      ["✎", "edit",   C.WRITE],
  write:     ["✎", "write",  C.WRITE],
  task:      ["§", "task",   C.SUB],
  todowrite: ["☐", "todo",   C.TODO],
};

const styleFor = (tool) => TOOL_STYLE[tool] || ["•", tool, C.OTHER];

function brief(value, limit = 140) {
  const s = JSON.stringify(value);
  return s.length <= limit ? s : s.slice(0, limit - 1) + "…";
}

function summarizeInput(tool, state) {
  const inp = state.input || {};
  if (tool === "task") {
    const sa = inp.subagent_type || "";
    const desc = inp.description || "";
    return sa ? `${sa} · ${desc}` : brief(inp);
  }
  if (tool === "bash") return inp.command || brief(inp);
  if (tool === "read" || tool === "glob")
    return inp.filePath || inp.pattern || brief(inp);
  if (tool === "grep") return inp.pattern || brief(inp);
  if (tool === "edit" || tool === "write")
    return inp.filePath ? inp.filePath : brief(inp);
  if (tool === "todowrite") {
    const todos = inp.todos;
    if (Array.isArray(todos)) {
      const statuses = {};
      for (const t of todos) {
        const s = t && typeof t === "object" ? t.status || "?" : "?";
        statuses[s] = (statuses[s] || 0) + 1;
      }
      return Object.keys(statuses).length ? brief(statuses) : brief(inp);
    }
  }
  return brief(inp);
}

function extractTaskResult(out) {
  let text = String(out);
  const marker = "<task_result>";
  const open = text.indexOf(marker);
  if (open === -1) return text.trim();
  const close = text.lastIndexOf("</task_result>");
  const bodyStart = open + marker.length;
  const bodyEnd = close === -1 ? text.length : close;
  return text.slice(bodyStart, bodyEnd).trim();
}

function summarizeOutput(tool, state, limit = 240) {
  const out = state.output;
  if (tool === "task") return extractTaskResult(out);
  return String(out || "").trim().replace(/\n/g, " ");
}

function taskMeta(state) {
  const meta = state.metadata || {};
  const model = meta.model || {};
  const mid = model.modelID || model.id || "";
  let sid = String(meta.sessionId || "").replace("ses_", "");
  const parts = [];
  if (mid) parts.push(`model=${mid}`);
  if (sid) parts.push(`session=${sid.slice(0, 12)}`);
  return parts.join("  ");
}

// --- output helpers --------------------------------------------------------
const out = (s) => process.stdout.write(s + EOL);

function renderToolUse(part) {
  const tool = part.tool || "?";
  const state = part.state || {};
  const status = state.status || "";

  if (tool === "task") {
    // Subagent spawn: framed block so it reads as its own unit.
    const inp = state.input || {};
    const sa = inp.subagent_type || "?";
    const desc = inp.description || "";
    let header = `${C.SUB}${C.BOLD}§ subagent · ${sa}${C.RESET}`;
    if (desc) header += `${C.SUB} — ${desc}${C.RESET}`;
    out(`${C.SUB}┌─${C.RESET} ${header}`);
    const meta = taskMeta(state);
    if (meta) out(`${C.SUB}│ ${C.DIM}${meta}${C.RESET}`);
    const body = extractTaskResult(state.output || "");
    if (body) {
      const trimmed = body.length <= 400 ? body : body.slice(0, 399) + "…";
      const lines = trimmed.split(/\r?\n/);
      out(`${C.SUB}│ ${C.RESET}${C.SUB}↳ returned:${C.RESET}`);
      for (const l of lines.slice(0, 6)) out(`${C.SUB}│   ${C.RESET}${l}`);
      if (lines.length > 6)
        out(`${C.SUB}│   ${C.DIM}… (+${lines.length - 6} more lines)${C.RESET}`);
    }
    out(`${C.SUB}└─${C.RESET}`);
    if (status && status !== "completed")
      out(`  ${C.STATUS}· status=${status}${C.RESET}`);
    return;
  }

  const [icon, label, color] = styleFor(tool);
  out(`  ${color}${icon} ${label}${C.RESET}${color}(${summarizeInput(tool, state)})${C.RESET}`);
  const snippet = summarizeOutput(tool, state);
  if (snippet) out(`    ${C.RESULT}↳ ${snippet.slice(0, 240)}${C.RESET}`);
  if (status && status !== "completed")
    out(`    ${C.STATUS}· status=${status}${C.RESET}`);
}

// --- main loop: line-buffered stdin ----------------------------------------
let buf = "";
process.stdin.setEncoding("utf8");

process.stdin.on("data", (chunk) => {
  buf += chunk;
  let nl;
  while ((nl = buf.indexOf("\n")) !== -1) {
    const raw = buf.slice(0, nl).replace(/\r$/, "");
    buf = buf.slice(nl + 1);
    handleLine(raw);
  }
});

process.stdin.on("end", () => {
  if (buf.length) handleLine(buf.replace(/\r$/, ""));
});

function handleLine(raw) {
  const line = raw.replace(/\n$/, "");
  if (!line.trim()) return;

  let event;
  try {
    event = JSON.parse(line);
  } catch {
    // Non-JSON line (e.g. the "agent not found" warning) — pass through, dimmed.
    out(`${C.WARN}${line}${C.RESET}`);
    return;
  }

  const etype = event.type;

  if (etype === "text") {
    const part = event.part || {};
    const text = (part.text || "").trim();
    if (text)
      out(`${C.ORCH}${C.BOLD}orchestrator${C.RESET}${C.ORCH} ▸${C.RESET} ${text}`);
  } else if (etype === "tool_use") {
    renderToolUse(event.part || {});
  } else if (etype === "error") {
    const err = event.error || {};
    const data = err.data || {};
    const msg = data.message || err.name || "unknown error";
    out(`${C.ERROR}${C.BOLD}[error]${C.RESET} ${C.ERROR}${msg}${C.RESET}`);
  } else if (etype === "step_finish") {
    const part = event.part || {};
    const reason = part.reason || "";
    if (reason && reason !== "stop")
      out(`  ${C.STEP}· step end: ${reason}${C.RESET}`);
  }
  // step_start and others: intentionally ignored to keep output terse.
}