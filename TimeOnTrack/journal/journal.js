"use strict";

/* TimeOnTrack journal — all data is embedded, everything below runs offline.
   Filter/sort/aggregate are pure functions over `jobs`, and the DOM work is confined to
   the init/render half, so the logic can be exercised headlessly (see the export at the
   bottom and the DOM guard at the boot section). */

function scriptJson(id) {
  if (typeof document === "undefined") return null;
  const node = document.getElementById(id);
  return node ? JSON.parse(node.textContent) : null;
}

const I18N = scriptJson("tot-i18n") || {};
const RAW = scriptJson("tot-data") || [];

const t = (key) => I18N[key] || key;

const MINUTE = 60;
const HOUR = 3600;
/* Entries shorter than this are visual noise (148 of them exist). Shown dimmed rather
   than hidden, so nothing silently disappears from the totals. */
const MINOR_SECONDS = 60;

/* ---------- data shaping ---------- */

function buildJobs(raw) {
  return raw.map((job, index) => {
    const entries = (job.e || []).map((e) => ({
      start: e.s,
      end: e.e,
      name: e.n || null,
      seconds: e.e - e.s,
    })).sort((a, b) => a.start - b.start);

    const total = entries.reduce((sum, e) => sum + e.seconds, 0);
    return {
      index,
      name: job.n || "",
      archived: job.a === 1,
      entries,
      total,
      count: entries.length,
      first: entries.length ? entries[0].start : null,
      last: entries.length ? entries[entries.length - 1].end : null,
      avg: entries.length ? total / entries.length : 0,
      /* Lowercased haystack: job name plus every entry name, so searching "briefing"
         finds the job that has an entry called that. */
      haystack: (job.n + " " + entries.map((e) => e.name || "").join(" ")).toLowerCase(),
    };
  });
}

const JOBS = buildJobs(RAW);

/* ---------- pure filtering ---------- */

function entryMatches(entry, filters) {
  if (filters.from && entry.end < filters.from) return false;
  if (filters.to && entry.start > filters.to) return false;
  if (entry.seconds < filters.minDuration) return false;
  return true;
}

/* Returns jobs with their entry lists narrowed to the matching entries, and totals
   recomputed. A job is kept when it still has at least one matching entry. */
function applyFilters(jobs, filters) {
  const needle = (filters.query || "").trim().toLowerCase();
  const out = [];

  for (const job of jobs) {
    if (job.archived && !filters.showArchived) continue;
    if (!job.archived && !filters.showActive) continue;
    if (needle && !job.haystack.includes(needle)) continue;

    const entries = job.entries.filter((e) => entryMatches(e, filters));
    if (!entries.length) continue;

    const total = entries.reduce((sum, e) => sum + e.seconds, 0);
    out.push({
      ...job,
      entries,
      total,
      count: entries.length,
      first: entries[0].start,
      last: entries[entries.length - 1].end,
      avg: total / entries.length,
      /* Distinct days, used for the table's period column. */
      months: [...new Set(entries.map((e) => monthKey(e.start)))].sort(),
    });
  }
  return out;
}

function summarize(jobs) {
  return {
    jobs: jobs.length,
    entries: jobs.reduce((sum, j) => sum + j.count, 0),
    total: jobs.reduce((sum, j) => sum + j.total, 0),
  };
}

/* ---------- grouping ---------- */

function monthKey(ts) {
  const d = new Date(ts * 1000);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

function groupByMonth(jobs) {
  const groups = new Map();
  for (const job of jobs) {
    /* A job is filed under every month it has entries in, so a job spanning months
       appears in each of them with only that month's time. */
    for (const entry of job.entries) {
      const key = monthKey(entry.start);
      if (!groups.has(key)) groups.set(key, new Map());
      const bucket = groups.get(key);
      if (!bucket.has(job.index)) {
        bucket.set(job.index, { ...job, entries: [], total: 0, count: 0, avg: 0 });
      }
      const gj = bucket.get(job.index);
      gj.entries.push(entry);
      gj.total += entry.seconds;
      gj.count += 1;
      gj.avg = gj.total / gj.count;
    }
  }

  return [...groups.entries()]
    .sort((a, b) => b[0].localeCompare(a[0]))
    .map(([key, bucket]) => {
      const monthJobs = [...bucket.values()].sort((a, b) => b.total - a.total);
      return {
        key,
        label: formatMonth(key),
        jobs: monthJobs,
        total: monthJobs.reduce((sum, j) => sum + j.total, 0),
        count: monthJobs.reduce((sum, j) => sum + j.count, 0),
      };
    });
}

/* ---------- sorting ---------- */

function sortJobs(jobs, key, asc) {
  const dir = asc ? 1 : -1;
  const pick = {
    name: (j) => j.name.toLowerCase(),
    period: (j) => j.first,
    entries: (j) => j.count,
    total: (j) => j.total,
    avg: (j) => j.avg,
    status: (j) => (j.archived ? 1 : 0),
  }[key] || ((j) => j.total);

  return [...jobs].sort((a, b) => {
    const x = pick(a), y = pick(b);
    if (x < y) return -1 * dir;
    if (x > y) return 1 * dir;
    return a.name.localeCompare(b.name);
  });
}

/* ---------- formatting ---------- */

function formatDuration(seconds) {
  const s = Math.max(0, Math.round(seconds));
  const h = Math.floor(s / HOUR);
  const m = Math.floor((s % HOUR) / MINUTE);
  const sec = s % 60;
  return `${h}:${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
}

/* Compact form for charts and chips: 3:20 h, 45 min */
function formatCompact(seconds) {
  if (seconds >= HOUR) {
    const h = seconds / HOUR;
    return `${h.toFixed(h >= 10 ? 0 : 1)} h`;
  }
  if (seconds >= MINUTE) return `${Math.round(seconds / MINUTE)} min`;
  return `${Math.round(seconds)} s`;
}

function formatMonth(key) {
  const [y, m] = key.split("-").map(Number);
  return new Date(y, m - 1, 1).toLocaleDateString(document.documentElement.lang, {
    month: "long", year: "numeric",
  });
}

function formatDate(ts) {
  return new Date(ts * 1000).toLocaleDateString(document.documentElement.lang, {
    day: "2-digit", month: "2-digit", year: "2-digit",
  });
}

function formatTime(ts) {
  return new Date(ts * 1000).toLocaleTimeString(document.documentElement.lang, {
    hour: "2-digit", minute: "2-digit",
  });
}

function formatDateTime(ts) {
  return new Date(ts * 1000).toLocaleString(document.documentElement.lang, {
    day: "2-digit", month: "2-digit", year: "2-digit",
    hour: "2-digit", minute: "2-digit",
  });
}

function relativeAge(seconds) {
  if (seconds < 90) return "just now";
  if (seconds < 3600) return `${Math.round(seconds / MINUTE)} min`;
  if (seconds < 86400) return `${Math.round(seconds / HOUR)} h`;
  return `${Math.round(seconds / 86400)} d`;
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

/* ---------- state ---------- */

const STALE_AFTER = 60; /* seconds; the page offers a reload once older than this */

const state = {
  query: "",
  from: null,
  to: null,
  year: "",
  month: "",
  minDuration: 0,
  showActive: true,
  showArchived: true,
  view: "time",
  sort: "total",
  sortAsc: false,
  openGroups: new Set(),
  openJobs: new Set(),
};

function readFiltersFromState() {
  return {
    query: state.query,
    from: state.from,
    to: state.to,
    minDuration: state.minDuration,
    showActive: state.showActive,
    showArchived: state.showArchived,
  };
}

/* The year/month dropdowns narrow via `from`/`to` on top of any explicit date range. */
function filtersWithPeriod(base) {
  let from = base.from;
  let to = base.to;
  if (state.year) {
    const y = Number(state.year);
    if (state.month) {
      const m = Number(state.month);
      const start = new Date(y, m - 1, 1).getTime() / 1000;
      const end = new Date(y, m, 1).getTime() / 1000 - 1;
      from = Math.max(from || 0, start);
      to = Math.min(to || Infinity, end);
    } else {
      from = Math.max(from || 0, new Date(y, 0, 1).getTime() / 1000);
      to = Math.min(to || Infinity, new Date(y + 1, 0, 1).getTime() / 1000 - 1);
    }
  }
  return { ...base, from: from || null, to: to === Infinity ? null : to };
}

/* ---------- charts ---------- */

function renderBars(container, rows, { minorThreshold } = {}) {
  container.replaceChildren();
  if (!rows.length) return;
  const max = Math.max(...rows.map((r) => r.value)) || 1;

  for (const row of rows) {
    const wrap = el("div", "bar-row");
    if (minorThreshold !== undefined && row.value < minorThreshold) wrap.classList.add("is-minor");

    wrap.append(el("div", "bar-label", row.label));
    const track = el("div", "bar-track");
    const fill = el("div", "bar-fill");
    fill.style.width = `${Math.max(1, (row.value / max) * 100)}%`;
    track.append(fill);
    wrap.append(track);
    wrap.append(el("div", "bar-value", row.valueText));
    container.append(wrap);
  }
}

function renderCharts(jobs) {
  /* Hours per month across the filtered set. */
  const byMonth = new Map();
  for (const job of jobs) {
    for (const entry of job.entries) {
      const key = monthKey(entry.start);
      byMonth.set(key, (byMonth.get(key) || 0) + entry.seconds);
    }
  }
  const monthRows = [...byMonth.entries()]
    .sort((a, b) => b[0].localeCompare(a[0]))
    .slice(0, 18)
    .reverse()
    .map(([key, seconds]) => ({
      label: formatMonth(key).replace(/\s\d{4}$/, ""),
      value: seconds,
      valueText: formatCompact(seconds),
    }));

  /* Top jobs, capped so the panel stays readable. */
  const jobRows = [...jobs]
    .sort((a, b) => b.total - a.total)
    .slice(0, 12)
    .map((job) => ({ label: job.name, value: job.total, valueText: formatCompact(job.total) }));

  document.getElementById("chart-month-title").textContent = t("journal.by_month");
  document.getElementById("chart-jobs-title").textContent = t("journal.top_jobs");
  renderBars(document.getElementById("bars-month"), monthRows);
  renderBars(document.getElementById("bars-jobs"), jobRows);
}

/* ---------- by-time view ---------- */

function entryRow(entry) {
  const row = el("div", "entry-row");
  if (entry.seconds < MINOR_SECONDS) row.classList.add("is-minor");
  row.append(el("span", "entry-date", formatDate(entry.start)));
  row.append(el("span", "entry-time", `${formatTime(entry.start)} – ${formatTime(entry.end)}`));
  if (entry.name) row.append(el("span", "entry-name", entry.name));
  row.append(el("span", "entry-dur", formatDuration(entry.seconds)));
  return row;
}

function jobBlock(job, { nest }) {
  const wrap = el("div", "job");
  const head = el("button", "job-head");
  head.type = "button";
  head.append(el("span", "disclosure", "▶"));
  head.append(el("span", "grow", job.name));
  head.append(el("span", "meta", `${job.count} ${t("journal.entries").toLowerCase()}`));
  head.append(el("span", "dur", formatDuration(job.total)));
  wrap.append(head);

  const body = el("div", "job-body");
  for (const entry of job.entries) body.append(entryRow(entry));
  wrap.append(body);

  if (state.openJobs.has(`${nest}:${job.index}`)) wrap.classList.add("is-open");
  head.addEventListener("click", () => {
    wrap.classList.toggle("is-open");
    const key = `${nest}:${job.index}`;
    if (wrap.classList.contains("is-open")) state.openJobs.add(key);
    else state.openJobs.delete(key);
  });
  return wrap;
}

function renderByTime(jobs) {
  const host = document.getElementById("groups");
  host.replaceChildren();
  renderCharts(jobs);

  const groups = groupByMonth(jobs);
  for (const group of groups) {
    const wrap = el("div", "group");
    const head = el("button", "group-head");
    head.type = "button";
    head.append(el("span", "disclosure", "▶"));
    head.append(el("span", "grow", group.label));
    head.append(el("span", "meta", `${group.jobs.length} ${t("journal.summary.jobs")} · ${group.count} ${t("journal.summary.entries")}`));
    head.append(el("span", "dur", formatDuration(group.total)));
    wrap.append(head);

    const body = el("div", "group-body");
    for (const job of group.jobs) body.append(jobBlock(job, { nest: group.key }));
    wrap.append(body);

    /* The newest month is open on first load so the page is not a wall of headers. */
    if (state.openGroups.has(group.key) || (!state.openGroups.size && group === groups[0])) {
      wrap.classList.add("is-open");
    }
    head.addEventListener("click", () => {
      wrap.classList.toggle("is-open");
      if (wrap.classList.contains("is-open")) state.openGroups.add(group.key);
      else state.openGroups.delete(group.key);
    });
    host.append(wrap);
  }
}

/* ---------- table view ---------- */

function periodText(job) {
  const a = formatDate(job.first);
  const b = formatDate(job.last);
  return a === b ? a : `${a} – ${b}`;
}

function renderTable(jobs) {
  const tbody = document.getElementById("tbody");
  tbody.replaceChildren();

  const sorted = sortJobs(jobs, state.sort, state.sortAsc);
  for (const job of sorted) {
    const tr = el("tr", "row");
    tr.append(el("td", "job-name", job.name));
    tr.append(el("td", "meta", periodText(job)));
    tr.append(el("td", "num", String(job.count)));
    tr.append(el("td", "num", formatDuration(job.total)));
    tr.append(el("td", "num meta", formatDuration(job.avg)));
    const badge = el("span", "badge" + (job.archived ? "" : " is-active"),
      job.archived ? t("journal.filter.archived") : t("journal.filter.active"));
    const td = el("td");
    td.append(badge);
    tr.append(td);

    const detail = el("tr", "detail-row");
    detail.hidden = !state.openJobs.has(`t:${job.index}`);
    const wrapTd = el("td");
    wrapTd.colSpan = 6;
    const wrap = el("div", "detail-wrap");
    for (const entry of job.entries) wrap.append(entryRow(entry));
    wrapTd.append(wrap);
    detail.append(wrapTd);

    tr.addEventListener("click", () => {
      detail.hidden = !detail.hidden;
      const key = `t:${job.index}`;
      if (detail.hidden) state.openJobs.delete(key); else state.openJobs.add(key);
    });

    tbody.append(tr, detail);
  }

  /* Reflect sort state in the header. */
  document.querySelectorAll(".th-sort").forEach((th) => {
    const on = th.dataset.sort === state.sort;
    th.classList.toggle("is-sorted", on);
    th.classList.toggle("is-asc", on && state.sortAsc);
  });
}

/* ---------- summary + empty state ---------- */

function renderSummary(jobs) {
  const sum = summarize(jobs);
  const host = document.getElementById("sum-numbers");
  host.replaceChildren();

  if (!sum.jobs) return;

  const add = (value, label) => {
    host.append(el("b", null, value));
    host.append(document.createTextNode(" " + label));
  };
  add(String(sum.jobs), t("journal.summary.jobs"));
  host.append(el("span", "sep", "·"));
  add(String(sum.entries), t("journal.summary.entries"));
  host.append(el("span", "sep", "·"));
  add(formatDuration(sum.total), t("journal.summary.total"));
  host.append(el("span", "sep", "·"));
  add(formatCompact(sum.total / Math.max(1, sum.jobs)), t("journal.summary.avg"));
}

/* ---------- CSV export ---------- */

function csvEscape(value) {
  const s = String(value);
  return /[",\n;]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function buildCsv(jobs) {
  const sep = ";"; /* semicolon: Numbers/Excel in DE locale expect this */
  const rows = [[
    "job", "status", "entry_start", "entry_end", "entry_seconds", "entry_name",
  ]];
  for (const job of jobs) {
    for (const entry of job.entries) {
      rows.push([
        job.name,
        job.archived ? "archived" : "active",
        new Date(entry.start * 1000).toISOString(),
        new Date(entry.end * 1000).toISOString(),
        entry.seconds,
        entry.name || "",
      ]);
    }
  }
  return rows.map((r) => r.map(csvEscape).join(sep)).join("\n") + "\n";
}

function downloadCsv(jobs) {
  const blob = new Blob([buildCsv(jobs)], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = el("a");
  a.href = url;
  a.download = `TimeOnTrack-${new Date().toISOString().slice(0, 10)}.csv`;
  document.body.append(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

/* ---------- rendering ---------- */

function currentJobs() {
  return applyFilters(JOBS, filtersWithPeriod(readFiltersFromState()));
}

function render() {
  const jobs = currentJobs();

  document.getElementById("empty").hidden = jobs.length > 0;
  document.getElementById("empty").textContent = t("journal.summary.none");

  renderSummary(jobs);
  renderByTime(jobs);
  renderTable(jobs);
}

/* ---------- wiring ---------- */

function fillSelect(select, options, placeholder) {
  select.replaceChildren();
  const first = el("option", null, placeholder);
  first.value = "";
  select.append(first);
  for (const { value, label } of options) {
    const opt = el("option", null, label);
    opt.value = value;
    select.append(opt);
  }
}

function initStaticText() {
  document.querySelector(".title-text").textContent = t("journal.title");
  document.documentElement.lang = document.documentElement.lang || "en";

  const q = document.getElementById("q");
  q.placeholder = t("journal.filter.search");

  document.getElementById("lbl-from").textContent = t("journal.filter.from");
  document.getElementById("lbl-to").textContent = t("journal.filter.to");
  document.getElementById("lbl-year").textContent = t("journal.filter.year");
  document.getElementById("lbl-month").textContent = t("journal.filter.month");
  document.getElementById("lbl-min").textContent = t("journal.filter.min_duration");
  document.getElementById("view-time").textContent = t("journal.filter.view_time");
  document.getElementById("view-table").textContent = t("journal.filter.view_table");
  document.getElementById("reset").textContent = t("journal.filter.reset");
  document.getElementById("export").textContent = t("journal.export.csv");
  document.querySelector('[data-sort="name"]').textContent = t("journal.title") && "Job";
  document.querySelector('[data-sort="period"]').textContent = t("journal.period");
  document.querySelector('[data-sort="entries"]').textContent = t("journal.entries");
  document.querySelector('[data-sort="total"]').textContent = t("journal.job.total");
  document.querySelector('[data-sort="avg"]').textContent = t("journal.summary.avg");
  document.querySelector('[data-sort="status"]').textContent = t("journal.status");
  document.querySelector('input#f-active + span').textContent = t("journal.filter.active");
  document.querySelector('input#f-archived + span').textContent = t("journal.filter.archived");
  document.getElementById("min-duration").options[0].textContent = t("journal.filter.all");

  const reload = document.getElementById("reload");
  reload.title = t("journal.refresh");
  /* NOTE: the `refreshplugin` endpoint requires SwiftBar >= 2.1.2. On 2.1.1 it does not
     exist, so this link is inert — the browser accepts the navigation and SwiftBar ignores
     it. Nothing else needs changing once 2.1.2 ships; see the note in TimeOnTrack.1s.rb. */
  reload.href = `swiftbar://refreshplugin?name=${encodeURIComponent(TOT_PLUGIN_FILE)}&journal=regen`;

  document.getElementById("empty").textContent = t("journal.summary.none");
  document.getElementById("foot").textContent = `${t("journal.title")} · ${TOT_PLUGIN_FILE}`;
}

/* ---------- age display ---------- */

function refreshAgeDisplay() {
  const age = Math.max(0, Date.now() / 1000 - TOT_GENERATED);
  const stale = age > STALE_AFTER;

  const stamp = document.getElementById("stamp");
  stamp.textContent = `${t("journal.generated")}: ${TOT_GENERATED_TEXT} (${relativeAge(age)})`;
  stamp.title = formatDateTime(TOT_GENERATED);

  /* The banner appears on its own once the page crosses the stale threshold, without
     needing a reload. */
  const banner = document.getElementById("stale");
  banner.hidden = !stale;
  if (stale) {
    banner.querySelector(".stale-label").textContent = t("journal.stale");
    banner.querySelector(".stale-hint").textContent = t("journal.staleHint");
  }

  /* Emphasise the reload button while the data is stale. */
  const reload = document.getElementById("reload");
  reload.classList.toggle("is-stale", stale);
}

function initFilters() {
  const years = [...new Set(JOBS.flatMap((j) => j.entries.map((e) => new Date(e.start * 1000).getFullYear())))]
    .sort((a, b) => b - a);
  fillSelect(
    document.getElementById("year"),
    years.map((y) => ({ value: String(y), label: String(y) })),
    t("journal.filter.all"),
  );

  const months = Array.from({ length: 12 }, (_, i) => ({
    value: String(i + 1),
    label: new Date(2000, i, 1).toLocaleDateString(document.documentElement.lang, { month: "long" }),
  }));
  fillSelect(document.getElementById("month"), months, t("journal.filter.all"));

  const q = document.getElementById("q");
  q.addEventListener("input", () => { state.query = q.value; state.openGroups.clear(); render(); });

  document.getElementById("from").addEventListener("change", (e) => {
    state.from = e.target.value ? Math.floor(new Date(e.target.value + "T00:00:00").getTime() / 1000) : null;
    state.openGroups.clear(); render();
  });
  document.getElementById("to").addEventListener("change", (e) => {
    state.to = e.target.value ? Math.floor(new Date(e.target.value + "T23:59:59").getTime() / 1000) : null;
    state.openGroups.clear(); render();
  });
  document.getElementById("year").addEventListener("change", (e) => {
    state.year = e.target.value;
    state.month = "";
    document.getElementById("month").value = "";
    state.openGroups.clear(); render();
  });
  document.getElementById("month").addEventListener("change", (e) => {
    state.month = e.target.value;
    state.openGroups.clear(); render();
  });
  document.getElementById("min-duration").addEventListener("change", (e) => {
    state.minDuration = Number(e.target.value);
    state.openGroups.clear(); render();
  });
  document.getElementById("f-active").addEventListener("change", (e) => {
    state.showActive = e.target.checked; render();
  });
  document.getElementById("f-archived").addEventListener("change", (e) => {
    state.showArchived = e.target.checked; render();
  });

  document.getElementById("reset").addEventListener("click", () => {
    state.query = ""; state.from = null; state.to = null;
    state.year = ""; state.month = ""; state.minDuration = 0;
    state.showActive = true; state.showArchived = true;
    state.openGroups.clear(); state.openJobs.clear();
    document.getElementById("q").value = "";
    document.getElementById("from").value = "";
    document.getElementById("to").value = "";
    document.getElementById("year").value = "";
    document.getElementById("month").value = "";
    document.getElementById("min-duration").value = "0";
    document.getElementById("f-active").checked = true;
    document.getElementById("f-archived").checked = true;
    render();
  });

  const setView = (view) => {
    state.view = view;
    document.getElementById("pane-time").hidden = view !== "time";
    document.getElementById("pane-table").hidden = view !== "table";
    document.getElementById("view-time").classList.toggle("is-on", view === "time");
    document.getElementById("view-table").classList.toggle("is-on", view === "table");
    document.getElementById("view-time").setAttribute("aria-selected", String(view === "time"));
    document.getElementById("view-table").setAttribute("aria-selected", String(view === "table"));
  };
  document.getElementById("view-time").addEventListener("click", () => setView("time"));
  document.getElementById("view-table").addEventListener("click", () => setView("table"));

  document.querySelectorAll(".th-sort").forEach((th) => {
    th.addEventListener("click", () => {
      const key = th.dataset.sort;
      if (state.sort === key) state.sortAsc = !state.sortAsc;
      else { state.sort = key; state.sortAsc = key === "name"; }
      render();
    });
  });

  document.getElementById("export").addEventListener("click", () => downloadCsv(currentJobs()));

  /* "/" focuses the search box */
  document.addEventListener("keydown", (e) => {
    if (e.key === "/" && document.activeElement !== q) { e.preventDefault(); q.focus(); }
  });
}

/* ---------- sticky offsets ---------- */

/* The controls card wraps to a different height depending on width, so its bottom edge
   (where the sticky table header must stop) cannot be a fixed number. Measure it. */
function updateStickyOffsets() {
  const bar = document.querySelector(".bar");
  const controls = document.querySelector(".controls");
  if (!bar || !controls) return;

  const root = document.documentElement.style;
  root.setProperty("--bar-height", `${Math.round(bar.getBoundingClientRect().height)}px`);

  /* Only reserve room while the controls are actually sticky (wide screens). On narrow
     ones they scroll away, so the header should stick to the top instead. */
  const sticky = getComputedStyle(controls).position === "sticky";
  const bottom = sticky
    ? Math.round(controls.getBoundingClientRect().height) + Math.round(bar.getBoundingClientRect().height)
    : 0;
  root.setProperty("--controls-bottom", `${bottom}px`);
}

/* ---------- regenerating ---------- */

/* Ask SwiftBar to rewrite this file from current data. */
function requestRegen() {
  const url = document.getElementById("reload").href;
  /* A hidden iframe is the most reliable way to trigger a custom scheme from a page
     without navigating away; an <img> works too but is treated as an image load by some
     browsers and dropped. */
  const frame = document.createElement("iframe");
  frame.style.display = "none";
  frame.src = url;
  document.body.append(frame);
  setTimeout(() => frame.remove(), 4000);
}

/* The reload button has to do two things: tell SwiftBar to regenerate (a custom-scheme
   navigation, which the browser handles out of band) and then re-read this file — the
   browser will not pick up an external rewrite on its own. A short delay gives SwiftBar
   time to write before the reload. */
function initReloadButton() {
  const reload = document.getElementById("reload");
  reload.addEventListener("click", (event) => {
    event.preventDefault();
    reload.classList.add("is-busy");
    requestRegen();
    setTimeout(() => window.location.reload(), 900);
  });
}

/* On load, if the page is already stale, regenerate once automatically. Best effort:
   browsers may refuse a custom scheme without a user gesture, in which case the banner
   and the button are the fallback. Never reloads on its own — a reload loop would be
   worse than slightly old numbers. */
function initStaleness() {
  refreshAgeDisplay(); /* also sets the banner and the stale emphasis */
  if (Date.now() / 1000 - TOT_GENERATED > STALE_AFTER) requestRegen();
}

/* ---------- boot ---------- */

/* Only touch the DOM when there is one — this keeps the module importable in Node so the
   filtering/grouping/export logic is testable without a browser. */
if (typeof document !== "undefined" && document.getElementById("groups")) {
  initStaticText();
  initFilters();
  initReloadButton();
  initStaleness();
  render();

  /* Keep "generated … (5 min)" ticking, and let the banner appear on its own if the page
     is left open long enough to go stale. */
  setInterval(refreshAgeDisplay, 15000);

  /* Sticky header offsets depend on rendered heights, so measure after layout and again
     whenever the viewport changes (the filter row wraps at narrow widths). */
  updateStickyOffsets();
  window.addEventListener("resize", updateStickyOffsets);
  if (window.ResizeObserver) {
    new ResizeObserver(updateStickyOffsets).observe(document.querySelector(".controls"));
  }
}

/* Exposed so the filter/sort/aggregate logic can be tested without a browser. */
if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    buildJobs, applyFilters, summarize, groupByMonth, sortJobs,
    buildCsv, formatDuration, formatCompact, monthKey,
  };
}
