#!/usr/bin/env node
/**
 * Render Claude Code's `--output-format stream-json` as readable, colorized
 * live output.
 *
 * Reads stream-json events on stdin (one JSON object per line) and prints, as
 * they arrive: orchestrator text, a compact one-liner per tool call (with the
 * tool result), framed subagent blocks, and the final result/cost. Output is
 * color-coded by tool kind so the viewer can tell at a glance who is doing
 * what. Unparseable lines are passed through untouched.
 *
 * Used by scripts/adw/run.sh so the ADW loop (Claude engine) can be watched
 * live in the terminal while the raw jsonl is tee'd to a file for the
 * NO-MORE-TASKS grep — mirroring format-stream-opencode.js, with the same
 * color scheme and subagent-block treatment, adapted to Claude's event shape.
 *
 * Claude stream-json shape:
 *   - {type:"assistant", message:{content:[{type:"text"|"tool_use", ...}]}}
 *   - {type:"user",      message:{content:[{type:"tool_result", tool_use_id, content}]}}
 *   - {type:"result",    subtype, total_cost_usd}
 *   - {type:"system",    subtype}
 *
 * tool_use and tool_result arrive in separate events, correlated by
 * tool_use_id. We buffer each tool_use's {name, input} by id and render the
 * line/block when the matching tool_result lands — that keeps a tool's call
 * and its result together (and lets the framed task block show the full
 * <task_result> body).
 */
"use strict";

const { EOL } = require("os");

// --- color setup (same palette as format-stream-opencode.js) ---------------
function colorOn() {
  if (process.env.NO_COLOR) return false;
  if (process.env.CLICOLOR_FORCE) return true;
  return process.stdout.isTTY === true;
}
const COLORS = colorOn();
const C = COLORS
  ? {
      RESET: "\x1b[0m", DIM: "\x1b[2m", BOLD: "\x1b[1m",
      ORCH: "\x1b[38;5;39m", SUB: "\x1b[38;5;141m",
      READ: "\x1b[38;5;108m", WRITE: "\x1b[38;5;204m",
      BASH: "\x1b[38;5;215m", TODO: "\x1b[38;5;117m",
      OTHER: "\x1b[38;5;250m", RESULT: "\x1b[38;5;245m",
      STATUS: "\x1b[38;5;245m", STEP: "\x1b[38;5;240m",
      ERROR: "\x1b[38;5;196m", WARN: "\x1b[38;5;220m",
      SYS: "\x1b[38;5;240m",
    }
  : {
      RESET: "", DIM: "", BOLD: "", ORCH: "", SUB: "", READ: "", WRITE: "",
      BASH: "", TODO: "", OTHER: "", RESULT: "", STATUS: "", STEP: "",
      ERROR: "", WARN: "", SYS: "",
    };

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

function summarizeInput(tool, input) {
  const inp = input || {};
  if (tool === "task") {
    const sa = inp.subagent_type || "";
    const desc = inp.description || "";
    return sa ? `${sa} · ${desc}` : brief(inp);
  }
  if (tool === "bash") return inp.command || brief(inp);
  if (tool === "read" || tool === "glob")
    return inp.file_path || inp.filePath || inp.pattern || brief(inp);
  if (tool === "grep") return inp.pattern || brief(inp);
  if (tool === "edit" || tool === "write")
    return inp.file_path || inp.filePath || brief(inp);
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

// Flatten a tool_result content (string OR array of {type,text} blocks) to text.
function resultToText(content) {
  if (content == null) return "";
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .map((c) => (c && typeof c === "object" ? c.text || "" : String(c)))
      .join(" ");
  }
  return String(content);
}

const out = (s) => process.stdout.write(s + EOL);

// Pending tool_use calls, keyed by tool_use_id, awaiting their tool_result.
const pending = new Map();

function renderToolResult(toolUse, resultText) {
  const tool = toolUse.name || "?";
  const input = toolUse.input || {};

  if (tool === "task") {
    const sa = input.subagent_type || "?";
    const desc = input.description || "";
    let header = `${C.SUB}${C.BOLD}§ subagent · ${sa}${C.RESET}`;
    if (desc) header += `${C.SUB} — ${desc}${C.RESET}`;
    out(`${C.SUB}┌─${C.RESET} ${header}`);
    const body = extractTaskResult(resultText);
    if (body) {
      const trimmed = body.length <= 400 ? body : body.slice(0, 399) + "…";
      const lines = trimmed.split(/\r?\n/);
      out(`${C.SUB}│ ${C.RESET}${C.SUB}↳ returned:${C.RESET}`);
      for (const l of lines.slice(0, 6)) out(`${C.SUB}│   ${C.RESET}${l}`);
      if (lines.length > 6)
        out(`${C.SUB}│   ${C.DIM}… (+${lines.length - 6} more lines)${C.RESET}`);
    }
    out(`${C.SUB}└─${C.RESET}`);
    return;
  }

  const [icon, label, color] = styleFor(tool);
  out(`  ${color}${icon} ${label}${C.RESET}${color}(${summarizeInput(tool, input)})${C.RESET}`);
  const snippet = resultText.trim().replace(/\n/g, " ");
  if (snippet) out(`    ${C.RESULT}↳ ${snippet.slice(0, 240)}${C.RESET}`);
}

// --- main loop -------------------------------------------------------------
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
    out(`${C.WARN}${line}${C.RESET}`);
    return;
  }

  const etype = event.type;

  if (etype === "assistant" || etype === "user") {
    const message = event.message || {};
    const blocks = message.content || [];
    for (const block of blocks) {
      if (!block || typeof block !== "object") continue;
      const btype = block.type;

      if (btype === "text") {
        const text = (block.text || "").trim();
        if (text)
          out(`${C.ORCH}${C.BOLD}orchestrator${C.RESET}${C.ORCH} ▸${C.RESET} ${text}`);
      } else if (btype === "tool_use") {
        // Buffer; render when the matching tool_result arrives so call+result
        // stay together. (Claude emits them in adjacent events.)
        pending.set(block.id, { name: block.name, input: block.input });
      } else if (btype === "tool_result") {
        const tu = pending.get(block.tool_use_id);
        const text = resultToText(block.content);
        if (tu) {
          renderToolResult(tu, text);
          pending.delete(block.tool_use_id);
        } else {
          // Result without a seen tool_use — render a bare result line.
          const snippet = text.trim().replace(/\n/g, " ");
          if (snippet) out(`    ${C.RESULT}↳ ${snippet.slice(0, 240)}${C.RESET}`);
        }
      }
    }
  } else if (etype === "result") {
    const subtype = event.subtype || "";
    const cost = event.total_cost_usd;
    const tail = typeof cost === "number" ? ` ($${cost.toFixed(4)})` : "";
    out(`${C.SYS}[result: ${subtype}]${tail}${C.RESET}`);
  } else if (etype === "system") {
    const subtype = event.subtype || "";
    if (subtype && subtype !== "init")
      out(`${C.SYS}[system: ${subtype}]${C.RESET}`);
  }
}