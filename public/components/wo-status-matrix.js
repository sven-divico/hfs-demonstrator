/**
 * <wo-status-matrix> — Pivoted Work Order × Task status table
 *
 * Attributes:
 *   data-endpoint   URL prefix, e.g. /api/work-orders/matrix
 *   data-list       "legacy" | "attention"  (observed — refetches on change)
 *
 * Events dispatched on document (bubbles: true, composed: true):
 *   wo:open   {woId, woNumber}
 *   task:open {woId, woNumber, taskName}
 */

/** Map task state string → CSS class name */
function stateClass(state) {
  switch (state) {
    case "Draft":              return "open";
    case "Pending Dispatch":
    case "Assigned":           return "pending";
    case "Scheduled":
    case "Work In Progress":   return "scheduled";
    case "Done":               return "done";
    case "Problem":            return "problem";
    case "not applicable":     return "na";
    default:                   return "open";
  }
}

/** Map construction_status → inline colour for the dot in that cell */
function constructionStatusColor(status) {
  switch (status) {
    case "Completed":                  return "var(--hfs-status-done, #10b981)";
    case "in progress":                return "var(--hfs-status-scheduled, #3b82f6)";
    case "Fallout":                    return "var(--hfs-status-problem, #dc2626)";
    case "Open":
    case "Cancellation in progress":
    default:                           return "var(--hfs-status-open, #9aa5b1)";
  }
}

/** Dispatch a CustomEvent on document so it crosses any shadow boundary */
function dispatch(type, detail) {
  document.dispatchEvent(new CustomEvent(type, { detail, bubbles: true, composed: true }));
}

class WoStatusMatrix extends HTMLElement {
  static get observedAttributes() { return ["data-list"]; }

  connectedCallback() {
    this._shadow = this.attachShadow({ mode: "open" });
    this._shadow.innerHTML = `
      <style>
        :host {
          display: block;
          overflow: auto;
          height: 100%;
          font-family: var(--hfs-font, system-ui, sans-serif);
          font-size: 11px;
          color: var(--hfs-color-text, #1b2734);
        }
        .loading, .error {
          padding: 32px;
          color: var(--hfs-color-text-muted, #5b6770);
          font-size: 13px;
        }
        .error { color: var(--hfs-status-problem, #dc2626); }

        table {
          border-collapse: collapse;
          width: max-content;
          min-width: 100%;
        }
        th, td {
          padding: 6px 8px;
          border-bottom: 1px solid var(--hfs-color-border, #d8dde3);
          border-right: 1px solid var(--hfs-color-border, #d8dde3);
          white-space: nowrap;
          vertical-align: middle;
          text-align: left;
        }
        th {
          font-weight: 600;
          font-size: 11px;
          color: var(--hfs-color-text-muted, #5b6770);
          background: var(--hfs-color-bg, #f4f5f7);
        }
        /* Sticky thead */
        thead th {
          position: sticky;
          top: 0;
          z-index: 2;
        }
        /* Sticky first five columns */
        td.sticky, th.sticky {
          position: sticky;
          background: var(--hfs-color-surface, #fff);
          z-index: 1;
        }
        thead th.sticky { z-index: 3; background: var(--hfs-color-bg, #f4f5f7); }
        td.sticky:nth-child(1), th.sticky:nth-child(1) { left: 0; }
        td.sticky:nth-child(2), th.sticky:nth-child(2) { left: 100px; }
        td.sticky:nth-child(3), th.sticky:nth-child(3) { left: 160px; }
        td.sticky:nth-child(4), th.sticky:nth-child(4) { left: 210px; }
        td.sticky:nth-child(5), th.sticky:nth-child(5) { left: 310px; }

        tr:hover td { background: #f0f9f7; }
        tr:hover td.sticky { background: #f0f9f7; }

        /* ORDER link */
        a.wo-link {
          color: var(--hfs-color-primary, #1f8476);
          text-decoration: none;
          font-weight: 600;
          cursor: pointer;
        }
        a.wo-link:hover { text-decoration: underline; }

        /* Construction-status dot + label */
        .cstatus {
          display: flex;
          align-items: center;
          gap: 5px;
        }
        .cstatus-dot {
          display: inline-block;
          width: 8px;
          height: 8px;
          border-radius: 50%;
          flex-shrink: 0;
        }

        /* Task-state dots */
        .dot {
          display: inline-block;
          width: 10px;
          height: 10px;
          border-radius: 50%;
          vertical-align: middle;
          cursor: pointer;
        }
        .dot.open     { background: transparent; border: 1.5px solid var(--hfs-status-open, #9aa5b1); }
        .dot.pending  { background: var(--hfs-status-pending,  #f59e0b); border: none; }
        .dot.scheduled{ background: var(--hfs-status-scheduled,#3b82f6); border: none; }
        .dot.done     { background: var(--hfs-status-done,     #10b981); border: none; }
        .dot.problem  { background: var(--hfs-status-problem,  #dc2626); border: none; }
        .dot.na {
          display: inline;
          width: auto; height: auto;
          border-radius: 0;
          background: none; border: none;
          color: var(--hfs-color-text-muted, #5b6770);
          font-size: 12px;
          cursor: default;
        }
        .dot.na::before { content: "—"; }
      </style>
      <div class="loading">Loading…</div>
    `;

    this._fetch();
  }

  attributeChangedCallback(name, oldVal, newVal) {
    if (name === "data-list" && oldVal !== null && oldVal !== newVal && this._shadow) {
      this._fetch();
    }
  }

  async _fetch() {
    const endpoint = this.dataset.endpoint ?? "/api/work-orders/matrix";
    const list     = this.dataset.list     ?? "legacy";

    this._shadow.querySelector(".loading, .error, table")?.remove?.();
    const loading = document.createElement("div");
    loading.className = "loading";
    loading.textContent = "Loading…";
    this._shadow.appendChild(loading);

    try {
      const res = await fetch(`${endpoint}?list=${encodeURIComponent(list)}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      loading.remove();
      this._render(data);
    } catch (err) {
      loading.className = "error";
      loading.textContent = `Failed to load matrix: ${err.message}`;
    }
  }

  _render({ columns, rows }) {
    // Remove any previous table
    this._shadow.querySelector("table")?.remove();

    const table = document.createElement("table");

    // --- THEAD ---
    const thead = table.createTHead();
    const hRow  = thead.insertRow();

    // Five fixed headers — each sticky
    for (const [i, label] of ["ORDER", "Status", "City", "Address", "Construction"].entries()) {
      const th = document.createElement("th");
      th.className = "sticky";
      th.textContent = label;
      hRow.appendChild(th);
    }

    // One header per column from API
    for (const col of columns) {
      const th = document.createElement("th");
      th.textContent = col.short;
      th.title = col.name; // hover tooltip = full German name
      hRow.appendChild(th);
    }

    // --- TBODY ---
    const tbody = table.createTBody();
    for (const row of rows) {
      const tr = tbody.insertRow();

      // 1. ORDER cell — clickable link
      const tdOrder = tr.insertCell();
      tdOrder.className = "sticky";
      const a = document.createElement("a");
      a.className = "wo-link";
      a.href = "#";
      a.textContent = row.number;
      a.addEventListener("click", e => {
        e.preventDefault();
        dispatch("wo:open", { woId: row.sys_id, woNumber: row.number });
      });
      tdOrder.appendChild(a);

      // 2. Status code cell
      const tdStatus = tr.insertCell();
      tdStatus.className = "sticky";
      tdStatus.textContent = row.status_code ?? "";

      // 3. City cell
      const tdCity = tr.insertCell();
      tdCity.className = "sticky";
      tdCity.textContent = row.city ?? "";

      // 4. Address cell
      const tdAddr = tr.insertCell();
      tdAddr.className = "sticky";
      tdAddr.textContent = row.address ?? "";

      // 5. Construction status cell — coloured dot + text
      const tdConstr = tr.insertCell();
      tdConstr.className = "sticky";
      const cDiv = document.createElement("div");
      cDiv.className = "cstatus";
      const cDot = document.createElement("span");
      cDot.className = "cstatus-dot";
      cDot.style.background = constructionStatusColor(row.construction_status);
      cDiv.appendChild(cDot);
      cDiv.appendChild(document.createTextNode(row.construction_status ?? ""));
      tdConstr.appendChild(cDiv);

      // 6. One cell per task column
      for (const col of columns) {
        const state = row.tasks?.[col.name] ?? "not applicable";
        const cls   = stateClass(state);
        const td    = tr.insertCell();
        td.style.textAlign = "center";

        const dot = document.createElement("span");
        dot.className = `dot ${cls}`;
        dot.title = `${state} · updated ${row.tasks?.[col.name + "_updated"] ?? ""}`;

        // Build a richer title from the state itself
        const updated = row.sys_updated_on ?? "";
        dot.title = `${col.name}: ${state}`;

        if (cls !== "na") {
          dot.addEventListener("click", () => {
            dispatch("task:open", { woId: row.sys_id, woNumber: row.number, taskName: col.name });
          });
        }

        td.appendChild(dot);
      }

      tbody.appendChild(tr);
    }

    this._shadow.appendChild(table);
  }
}

customElements.define("wo-status-matrix", WoStatusMatrix);
