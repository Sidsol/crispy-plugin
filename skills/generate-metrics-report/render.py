#!/usr/bin/env python3
"""CRISPY metrics renderer.

Reads .metrics.jsonl files written by the crispy-metrics-record hook and emits
self-contained static HTML reports. No third-party dependencies.

Usage:
  python render.py --root <crispy-docs-dir> [--feature <rel>] [--open]

The 'crispy-docs-dir' is the directory NAMED 'crispy-docs', not its parent.
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import math
import os
import re
import sys
import webbrowser
from collections import defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------
# Premium-request multiplier table.
# Source: GitHub Copilot premium request multipliers (April 2026 snapshot).
# Multipliers change over time; users may override via .metrics-multipliers.json
# at the crispy-docs root. Format:
#   {"default": 1.0, "models": {"claude-opus-4.7": 7.5, ...}}
# Match is case-insensitive and tries: exact, then prefix, then "family"
# (text before the first dot).
# ---------------------------------------------------------------------------
DEFAULT_MULTIPLIERS = {
    "default": 1.0,
    "models": {
        "claude-opus-4.7":      7.5,
        "claude-opus-4.6-1m":   3.0,
        "claude-opus-4.6":      3.0,
        "claude-opus-4.5":      3.0,
        "claude-sonnet-4.6":    1.0,
        "claude-sonnet-4.5":    1.0,
        "claude-sonnet-4":      1.0,
        "claude-haiku-4.5":     0.33,
        "gpt-5.4":              1.0,
        "gpt-5.3-codex":        1.0,
        "gpt-5.2-codex":        1.0,
        "gpt-5.2":              1.0,
        "gpt-5.4-mini":         0.33,
        "gpt-5-mini":           0.33,
        "gpt-4.1":              0.0,  # included
    },
}

# Phase ordering for stable display.
FEATURE_PHASE_ORDER = [
    "Orchestration", "Clarify", "Research", "Intention",
    "Structure", "Plan", "Yield", "Implementation", "Utility",
]
PROJECT_PHASE_ORDER = [
    "Orchestration", "Vision", "Domain Research", "Architecture",
    "Feature Map", "Roadmap", "Yield", "Utility",
]

# ---------------------------------------------------------------------------
# Multiplier lookup
# ---------------------------------------------------------------------------

def load_multipliers(crispy_root: Path) -> dict:
    table = json.loads(json.dumps(DEFAULT_MULTIPLIERS))  # deep copy
    override = crispy_root / ".metrics-multipliers.json"
    if override.is_file():
        try:
            user = json.loads(override.read_text(encoding="utf-8"))
            if "default" in user:
                table["default"] = float(user["default"])
            if isinstance(user.get("models"), dict):
                for k, v in user["models"].items():
                    table["models"][k.lower()] = float(v)
        except Exception as exc:
            print(f"[crispy-metrics] WARN: bad multipliers file: {exc}",
                  file=sys.stderr)
    return table


def multiplier_for(model: str, table: dict) -> tuple[float, bool]:
    """Return (multiplier, is_default)."""
    if not model:
        return float(table["default"]), True
    m = model.strip().lower()
    models = table["models"]
    if m in models:
        return float(models[m]), False
    # Prefix match (e.g., "claude-sonnet-4.6-foo" -> "claude-sonnet-4.6")
    for k in sorted(models, key=len, reverse=True):
        if m.startswith(k):
            return float(models[k]), False
    return float(table["default"]), True


# ---------------------------------------------------------------------------
# Discovery + parsing
# ---------------------------------------------------------------------------

def find_metric_dirs(root: Path) -> list[Path]:
    """Return every directory under root that contains a .metrics.jsonl."""
    dirs: list[Path] = []
    for jsonl in root.rglob(".metrics.jsonl"):
        dirs.append(jsonl.parent)
    return dirs


def read_records(metrics_dir: Path) -> list[dict]:
    out = []
    f = metrics_dir / ".metrics.jsonl"
    if not f.is_file():
        return out
    for i, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except Exception as exc:
            print(f"[crispy-metrics] WARN: {f}:{i} skipped: {exc}",
                  file=sys.stderr)
    return out


# ---------------------------------------------------------------------------
# Folder classification
# ---------------------------------------------------------------------------

# Standalone feature: <root>/specs/NNN-...
# Project:            <root>/projects/NNN-...
# Project feature:    <root>/projects/NNN-.../features/MMM-...
RX_STANDALONE = re.compile(r"^specs/([0-9A-Za-z._-]+)$")
RX_PROJECT    = re.compile(r"^projects/([0-9A-Za-z._-]+)$")
RX_PROJ_FEAT  = re.compile(r"^projects/([0-9A-Za-z._-]+)/features/([0-9A-Za-z._-]+)$")


def classify_folder(rel: str) -> dict | None:
    rel = rel.replace("\\", "/")
    m = RX_PROJ_FEAT.match(rel)
    if m:
        return {"kind": "project_feature", "project": m.group(1),
                "feature": m.group(2)}
    m = RX_STANDALONE.match(rel)
    if m:
        return {"kind": "standalone", "feature": m.group(1)}
    m = RX_PROJECT.match(rel)
    if m:
        return {"kind": "project", "project": m.group(1)}
    return None


# ---------------------------------------------------------------------------
# Aggregation
# ---------------------------------------------------------------------------

def empty_agg() -> dict:
    return {
        "invocations": 0,
        "elapsed_s":   0.0,
        "in_tokens":   0,
        "out_tokens":  0,
        "premium":     0.0,
        "premium_default_share": 0.0,  # share of premium computed using default multiplier
        "model_breakdown": defaultdict(lambda: {"invocations": 0, "premium": 0.0}),
    }


def add_record(agg: dict, rec: dict, table: dict) -> None:
    invocations = int(rec.get("invocations") or 1)
    elapsed     = float(rec.get("elapsed_s") or 0)
    in_tok      = int(rec.get("approx_input_tokens") or 0)
    out_tok     = int(rec.get("approx_output_tokens") or 0)
    model       = (rec.get("model") or "").strip()
    mult, is_default = multiplier_for(model, table)
    premium = mult * invocations

    agg["invocations"] += invocations
    agg["elapsed_s"]   += elapsed
    agg["in_tokens"]   += in_tok
    agg["out_tokens"]  += out_tok
    agg["premium"]     += premium
    if is_default:
        agg["premium_default_share"] += premium

    label = model if model else "(unknown)"
    mb = agg["model_breakdown"][label]
    mb["invocations"] += invocations
    mb["premium"]     += premium


def aggregate_by_phase(records: list[dict], table: dict,
                       order_list: list[str]) -> list[tuple[str, dict]]:
    by_phase: dict[str, dict] = {}
    for rec in records:
        phase = rec.get("phase") or "Unknown"
        if phase not in by_phase:
            by_phase[phase] = empty_agg()
        add_record(by_phase[phase], rec, table)

    def sort_key(name: str) -> tuple[int, str]:
        try:
            return (order_list.index(name), name)
        except ValueError:
            return (len(order_list) + 1, name)

    return sorted(by_phase.items(), key=lambda kv: sort_key(kv[0]))


def total_agg(records: list[dict], table: dict) -> dict:
    t = empty_agg()
    for rec in records:
        add_record(t, rec, table)
    return t


# ---------------------------------------------------------------------------
# HTML rendering
# ---------------------------------------------------------------------------

CSS = """
:root {
  --bg:#0d1117; --fg:#e6edf3; --muted:#8b949e; --line:#30363d;
  --accent:#58a6ff; --warn:#d29922; --ok:#3fb950; --bad:#f85149;
  --card:#161b22; --row-alt:#0f141a;
}
@media (prefers-color-scheme: light) {
  :root { --bg:#ffffff; --fg:#1f2328; --muted:#656d76; --line:#d0d7de;
          --accent:#0969da; --warn:#9a6700; --ok:#1a7f37; --bad:#d1242f;
          --card:#f6f8fa; --row-alt:#fafbfc; }
}
* { box-sizing: border-box; }
html,body { margin:0; padding:0; background:var(--bg); color:var(--fg);
  font: 14px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,
        "Helvetica Neue",Arial,sans-serif; }
.wrap { max-width: 1200px; margin: 0 auto; padding: 24px; }
h1,h2,h3 { color: var(--fg); margin: 0.6em 0 0.4em; }
h1 { font-size: 24px; }
h2 { font-size: 18px; border-bottom: 1px solid var(--line);
     padding-bottom: 6px; margin-top: 28px; }
h3 { font-size: 15px; color: var(--muted); }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
.cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px,1fr));
         gap: 12px; margin: 16px 0 24px; }
.card { background: var(--card); border: 1px solid var(--line);
        border-radius: 6px; padding: 14px 16px; }
.card .label { color: var(--muted); font-size: 12px; text-transform: uppercase;
               letter-spacing: 0.04em; }
.card .value { font-size: 22px; font-weight: 600; margin-top: 4px; }
.card .sub { color: var(--muted); font-size: 12px; margin-top: 4px; }
table { width: 100%; border-collapse: collapse; margin: 8px 0 18px;
        font-variant-numeric: tabular-nums; }
th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--line); }
th { color: var(--muted); font-weight: 600; font-size: 12px;
     text-transform: uppercase; letter-spacing: 0.04em; cursor: pointer; }
th.num, td.num { text-align: right; }
tbody tr:nth-child(even) { background: var(--row-alt); }
.bar { height: 6px; background: var(--line); border-radius: 3px; overflow: hidden;
       margin-top: 4px; }
.bar > span { display: block; height: 100%; background: var(--accent); }
.badge { display: inline-block; padding: 2px 8px; border-radius: 999px;
         font-size: 11px; background: var(--card); border: 1px solid var(--line);
         color: var(--muted); }
.badge.warn { color: var(--warn); border-color: var(--warn); }
.badge.ok { color: var(--ok); border-color: var(--ok); }
.note { color: var(--muted); font-size: 12px; margin: 6px 0 16px;
        padding: 10px 12px; border-left: 3px solid var(--line);
        background: var(--card); border-radius: 0 4px 4px 0; }
footer { color: var(--muted); font-size: 11px; margin-top: 40px;
         padding-top: 16px; border-top: 1px solid var(--line); }
.empty { color: var(--muted); padding: 24px; text-align: center;
         background: var(--card); border-radius: 6px; border: 1px dashed var(--line); }
"""

SORT_JS = """
<script>
document.querySelectorAll('table.sortable').forEach(t => {
  t.querySelectorAll('th').forEach((h, i) => {
    h.addEventListener('click', () => {
      const tb = t.tBodies[0];
      const rows = Array.from(tb.rows);
      const num = h.classList.contains('num');
      const dir = h.dataset.dir === 'asc' ? 'desc' : 'asc';
      h.dataset.dir = dir;
      rows.sort((a,b) => {
        let av = a.cells[i].dataset.sort ?? a.cells[i].textContent.trim();
        let bv = b.cells[i].dataset.sort ?? b.cells[i].textContent.trim();
        if (num) { av = parseFloat(av)||0; bv = parseFloat(bv)||0; }
        return (av < bv ? -1 : av > bv ? 1 : 0) * (dir === 'asc' ? 1 : -1);
      });
      rows.forEach(r => tb.appendChild(r));
    });
  });
});
</script>
"""


def fmt_seconds(s: float) -> str:
    if s < 1: return f"{s*1000:.0f} ms"
    if s < 60: return f"{s:.1f} s"
    m, sec = divmod(s, 60)
    if m < 60: return f"{int(m)}m {sec:.0f}s"
    h, m = divmod(m, 60)
    return f"{int(h)}h {int(m)}m"


def fmt_num(n: float) -> str:
    if n >= 1000:
        return f"{n:,.0f}" if n == int(n) else f"{n:,.1f}"
    if n == int(n):
        return f"{int(n)}"
    return f"{n:.2f}"


def fmt_premium(n: float) -> str:
    if n == 0: return "0"
    if n < 1: return f"{n:.2f}"
    return f"{n:,.1f}" if n != int(n) else f"{int(n):,}"


def page_skeleton(title: str, body: str, footer_extra: str = "") -> str:
    now = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{html.escape(title)}</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
{body}
<footer>
  Generated {now} by <code>generate-metrics-report</code>.
  <strong>Premium Requests</strong> = invocations × per-model multiplier
  (per <a href="https://docs.github.com/en/copilot/how-tos/manage-and-track-spending/monitor-premium-requests">GitHub billing docs</a>);
  this is a <em>lower bound</em> because each sub-agent makes many internal LLM
  turns the hook cannot observe. Cross-check the authoritative number at
  <a href="https://github.com/settings/billing">github.com/settings/billing</a> →
  Premium Request Analytics. <strong>Approx tokens</strong> are estimated as
  <code>chars/4</code> from prompt and result text — not used for billing.
  Multipliers are overridable via <code>crispy-docs/.metrics-multipliers.json</code>.
  {footer_extra}
</footer>
</div>
{SORT_JS}
</body>
</html>
"""


def cards(total: dict) -> str:
    unknown_share = (total["premium_default_share"] / total["premium"] * 100
                     if total["premium"] > 0 else 0)
    unk_badge = ""
    if unknown_share > 0:
        cls = "warn" if unknown_share >= 25 else ""
        unk_badge = (f'<div class="sub"><span class="badge {cls}">'
                     f'{unknown_share:.0f}% est. via default multiplier</span></div>')
    return f"""
<div class="cards">
  <div class="card">
    <div class="label">Premium Requests (est.)</div>
    <div class="value">{fmt_premium(total['premium'])}</div>
    {unk_badge}
  </div>
  <div class="card">
    <div class="label">Wall-clock Time</div>
    <div class="value">{fmt_seconds(total['elapsed_s'])}</div>
    <div class="sub">across {total['invocations']} sub-agent invocation{'s' if total['invocations'] != 1 else ''}</div>
  </div>
  <div class="card">
    <div class="label">Approx Tokens In / Out</div>
    <div class="value">{fmt_num(total['in_tokens'])} / {fmt_num(total['out_tokens'])}</div>
    <div class="sub">~ chars / 4 — not billing</div>
  </div>
</div>
"""


def phase_table(phases: list[tuple[str, dict]], total: dict) -> str:
    if not phases:
        return '<div class="empty">No CRISPY sub-agent invocations recorded yet for this scope.</div>'
    rows = []
    tot_premium = max(total["premium"], 1e-9)
    tot_elapsed = max(total["elapsed_s"], 1e-9)
    for name, agg in phases:
        share_premium = agg["premium"] / tot_premium * 100
        share_time    = agg["elapsed_s"] / tot_elapsed * 100
        rows.append(f"""
<tr>
  <td>{html.escape(name)}</td>
  <td class="num" data-sort="{agg['invocations']}">{agg['invocations']}</td>
  <td class="num" data-sort="{agg['premium']:.4f}">
    {fmt_premium(agg['premium'])}
    <div class="bar"><span style="width:{share_premium:.1f}%"></span></div>
  </td>
  <td class="num" data-sort="{agg['elapsed_s']:.4f}">
    {fmt_seconds(agg['elapsed_s'])}
    <div class="bar"><span style="width:{share_time:.1f}%"></span></div>
  </td>
  <td class="num" data-sort="{agg['in_tokens']}">{fmt_num(agg['in_tokens'])}</td>
  <td class="num" data-sort="{agg['out_tokens']}">{fmt_num(agg['out_tokens'])}</td>
</tr>""")
    return f"""
<table class="sortable">
<thead>
<tr>
  <th>Phase</th>
  <th class="num">Invocations</th>
  <th class="num">Premium Req. (est.)</th>
  <th class="num">Time</th>
  <th class="num">~Tokens In</th>
  <th class="num">~Tokens Out</th>
</tr>
</thead>
<tbody>
{''.join(rows)}
</tbody>
</table>
"""


def model_table(total: dict) -> str:
    mb = total["model_breakdown"]
    if not mb:
        return ""
    rows = []
    for model in sorted(mb, key=lambda k: -mb[k]["premium"]):
        d = mb[model]
        is_unknown = (model == "(unknown)")
        badge = '<span class="badge warn">default mult</span>' if is_unknown else ''
        rows.append(f"""
<tr>
  <td><code>{html.escape(model)}</code> {badge}</td>
  <td class="num" data-sort="{d['invocations']}">{d['invocations']}</td>
  <td class="num" data-sort="{d['premium']:.4f}">{fmt_premium(d['premium'])}</td>
</tr>""")
    return f"""
<h3>Model breakdown</h3>
<table class="sortable">
<thead>
<tr><th>Model</th><th class="num">Invocations</th><th class="num">Premium Req. (est.)</th></tr>
</thead>
<tbody>
{''.join(rows)}
</tbody>
</table>
"""


def invocation_log(records: list[dict], table: dict, limit: int = 200) -> str:
    if not records:
        return ""
    recs = sorted(records, key=lambda r: r.get("ts_start_ms", 0))[-limit:]
    rows = []
    for r in recs:
        ts = r.get("ts_start_ms", 0)
        when = dt.datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d %H:%M:%S") if ts else ""
        model = r.get("model") or "(unknown)"
        mult, is_default = multiplier_for(r.get("model") or "", table)
        prem = mult * int(r.get("invocations") or 1)
        result = r.get("result") or "?"
        cls = "ok" if result == "success" else ("bad" if result == "failure" else "")
        rows.append(f"""
<tr>
  <td data-sort="{ts}">{when}</td>
  <td>{html.escape(r.get('phase',''))}</td>
  <td><code>{html.escape(r.get('agent',''))}</code></td>
  <td><code>{html.escape(model)}</code></td>
  <td class="num" data-sort="{r.get('elapsed_s',0)}">{fmt_seconds(float(r.get('elapsed_s') or 0))}</td>
  <td class="num" data-sort="{prem:.4f}">{fmt_premium(prem)}</td>
  <td><span class="badge {cls}">{html.escape(result)}</span></td>
</tr>""")
    suffix = "" if len(records) <= limit else f" (showing last {limit} of {len(records)})"
    return f"""
<h3>Invocation log{suffix}</h3>
<table class="sortable">
<thead>
<tr><th>When</th><th>Phase</th><th>Agent</th><th>Model</th>
    <th class="num">Time</th><th class="num">Premium Req.</th><th>Result</th></tr>
</thead>
<tbody>
{''.join(rows)}
</tbody>
</table>
"""


# ---------------------------------------------------------------------------
# Page builders
# ---------------------------------------------------------------------------

def render_feature_page(name: str, records: list[dict], table: dict,
                         scope: str = "feature") -> str:
    title = f"CRISPY metrics — {name}"
    total = total_agg(records, table)
    phases = aggregate_by_phase(records, table, FEATURE_PHASE_ORDER)
    body = f"""
<h1>{html.escape(name)}</h1>
<div class="note">Scope: <strong>{html.escape(scope)}</strong> · {total['invocations']} sub-agent invocation{'s' if total['invocations'] != 1 else ''} captured.</div>
{cards(total)}
<h2>By CRISPY phase</h2>
{phase_table(phases, total)}
{model_table(total)}
{invocation_log(records, table)}
"""
    return page_skeleton(title, body)


def render_project_page(name: str, project_records: list[dict],
                         child_features: list[tuple[str, dict, list[dict]]],
                         table: dict) -> str:
    """child_features: list of (feature_name, total_agg, records)."""
    title = f"CRISPY metrics — project {name}"
    # Combine project-level records + every child feature's records.
    all_records = list(project_records)
    for _, _, recs in child_features:
        all_records.extend(recs)
    total = total_agg(all_records, table)
    phases = aggregate_by_phase(all_records, table, PROJECT_PHASE_ORDER + FEATURE_PHASE_ORDER)

    feature_rows = []
    for fname, fagg, _ in sorted(child_features, key=lambda x: x[0]):
        feature_rows.append(f"""
<tr>
  <td><a href="features/{html.escape(fname)}/metrics.html">{html.escape(fname)}</a></td>
  <td class="num" data-sort="{fagg['invocations']}">{fagg['invocations']}</td>
  <td class="num" data-sort="{fagg['premium']:.4f}">{fmt_premium(fagg['premium'])}</td>
  <td class="num" data-sort="{fagg['elapsed_s']:.4f}">{fmt_seconds(fagg['elapsed_s'])}</td>
  <td class="num" data-sort="{fagg['in_tokens']}">{fmt_num(fagg['in_tokens'])}</td>
  <td class="num" data-sort="{fagg['out_tokens']}">{fmt_num(fagg['out_tokens'])}</td>
</tr>""")
    if feature_rows:
        features_html = f"""
<h2>Features</h2>
<table class="sortable">
<thead><tr>
  <th>Feature</th><th class="num">Invocations</th>
  <th class="num">Premium Req.</th><th class="num">Time</th>
  <th class="num">~Tokens In</th><th class="num">~Tokens Out</th>
</tr></thead>
<tbody>{''.join(feature_rows)}</tbody>
</table>
"""
    else:
        features_html = '<div class="empty">No features captured under this project yet.</div>'

    body = f"""
<h1>Project: {html.escape(name)}</h1>
<div class="note">Scope: <strong>project</strong> (rolls up project-level phases + every child feature).</div>
{cards(total)}
<h2>By CRISPY phase (project + features combined)</h2>
{phase_table(phases, total)}
{features_html}
{model_table(total)}
"""
    return page_skeleton(title, body)


def render_index(crispy_root: Path, standalones: list[tuple[str, dict]],
                  projects: list[tuple[str, dict, int]], table: dict) -> str:
    """standalones: (name, total_agg). projects: (name, total_agg, n_features)."""
    grand = empty_agg()
    for _, agg in standalones:
        for k in ("invocations","elapsed_s","in_tokens","out_tokens",
                  "premium","premium_default_share"):
            grand[k] += agg[k]
    for _, agg, _ in projects:
        for k in ("invocations","elapsed_s","in_tokens","out_tokens",
                  "premium","premium_default_share"):
            grand[k] += agg[k]

    def row(link: str, name: str, agg: dict, extra: str = "") -> str:
        return f"""
<tr>
  <td><a href="{html.escape(link)}">{html.escape(name)}</a>{extra}</td>
  <td class="num" data-sort="{agg['invocations']}">{agg['invocations']}</td>
  <td class="num" data-sort="{agg['premium']:.4f}">{fmt_premium(agg['premium'])}</td>
  <td class="num" data-sort="{agg['elapsed_s']:.4f}">{fmt_seconds(agg['elapsed_s'])}</td>
  <td class="num" data-sort="{agg['in_tokens']}">{fmt_num(agg['in_tokens'])}</td>
  <td class="num" data-sort="{agg['out_tokens']}">{fmt_num(agg['out_tokens'])}</td>
</tr>"""

    s_rows = "".join(row(f"standalone/{n}.html", n, a) for n, a in sorted(standalones))
    p_rows = "".join(
        row(f"projects/{n}.html", n, a,
            extra=f' <span class="badge">{nf} feature{"s" if nf != 1 else ""}</span>')
        for n, a, nf in sorted(projects))

    standalone_section = (f"""
<h2>Standalone features</h2>
<table class="sortable">
<thead><tr>
  <th>Feature</th><th class="num">Invocations</th><th class="num">Premium Req.</th>
  <th class="num">Time</th><th class="num">~Tokens In</th><th class="num">~Tokens Out</th>
</tr></thead>
<tbody>{s_rows}</tbody>
</table>
""" if standalones else "")

    project_section = (f"""
<h2>Projects</h2>
<table class="sortable">
<thead><tr>
  <th>Project</th><th class="num">Invocations</th><th class="num">Premium Req.</th>
  <th class="num">Time</th><th class="num">~Tokens In</th><th class="num">~Tokens Out</th>
</tr></thead>
<tbody>{p_rows}</tbody>
</table>
""" if projects else "")

    if not standalones and not projects:
        empty = '<div class="empty">No <code>.metrics.jsonl</code> files were found under <code>crispy-docs/</code>. Run a CRISPY phase first; the post-tool hook will start recording.</div>'
    else:
        empty = ""

    body = f"""
<h1>CRISPY Metrics</h1>
<div class="note">Root: <code>{html.escape(str(crispy_root))}</code></div>
{cards(grand)}
{empty}
{standalone_section}
{project_section}
"""
    return page_skeleton("CRISPY Metrics", body)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True,
                    help="Path to the crispy-docs directory.")
    ap.add_argument("--feature", default=None,
                    help="Optional: regenerate just one feature/project (relative path).")
    ap.add_argument("--open", dest="open_after", action="store_true",
                    help="Open the index in the default browser when done.")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir() or root.name != "crispy-docs":
        print(f"[crispy-metrics] ERROR: --root must point to a directory named "
              f"'crispy-docs'; got {root}", file=sys.stderr)
        return 2

    table = load_multipliers(root)

    metric_dirs = find_metric_dirs(root)
    # Don't treat reports/ as a metrics source.
    metric_dirs = [d for d in metric_dirs if "reports" not in d.relative_to(root).parts]

    if args.feature:
        wanted = (root / args.feature).resolve()
        metric_dirs = [d for d in metric_dirs if d == wanted]

    standalones: list[tuple[str, dict]] = []           # (name, total_agg)
    projects_data: dict[str, dict] = {}                # name -> {"records":[...], "features":{name:{records,total}}}

    for d in metric_dirs:
        rel = d.relative_to(root).as_posix()
        cls = classify_folder(rel)
        if not cls:
            continue
        records = read_records(d)
        if cls["kind"] == "standalone":
            html_doc = render_feature_page(cls["feature"], records, table,
                                            scope="standalone feature")
            write(d / "metrics.html", html_doc)
            write(root / "reports" / "standalone" / f"{cls['feature']}.html", html_doc)
            standalones.append((cls["feature"], total_agg(records, table)))
        elif cls["kind"] == "project_feature":
            html_doc = render_feature_page(cls["feature"], records, table,
                                            scope=f"feature in project {cls['project']}")
            write(d / "metrics.html", html_doc)
            p = projects_data.setdefault(cls["project"],
                                         {"records": [], "features": {}})
            p["features"][cls["feature"]] = {
                "records": records,
                "total":   total_agg(records, table),
            }
        elif cls["kind"] == "project":
            p = projects_data.setdefault(cls["project"],
                                         {"records": [], "features": {}})
            p["records"].extend(records)

    # If a project has features but no metric_dir of its own, ensure entry exists.
    project_summaries: list[tuple[str, dict, int]] = []
    for pname, pdata in projects_data.items():
        children = [(fname, f["total"], f["records"])
                    for fname, f in pdata["features"].items()]
        html_doc = render_project_page(pname, pdata["records"], children, table)
        proj_dir = root / "projects" / pname
        write(proj_dir / "metrics.html", html_doc)
        write(root / "reports" / "projects" / f"{pname}.html", html_doc)
        all_recs = list(pdata["records"])
        for _, _, recs in children:
            all_recs.extend(recs)
        project_summaries.append((pname, total_agg(all_recs, table), len(children)))

    index_html = render_index(root, standalones, project_summaries, table)
    index_path = root / "reports" / "index.html"
    write(index_path, index_html)

    print(f"[crispy-metrics] Wrote {len(standalones)} standalone feature page(s), "
          f"{len(project_summaries)} project page(s).")
    print(f"[crispy-metrics] Index: {index_path}")

    if args.open_after:
        try:
            webbrowser.open(index_path.as_uri())
        except Exception as exc:
            print(f"[crispy-metrics] Could not open browser: {exc}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
