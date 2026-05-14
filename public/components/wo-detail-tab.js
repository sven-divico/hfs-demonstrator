/**
 * <wo-detail-tab> — Work Order detail pane
 *
 * Attributes:
 *   data-wo-id      sys_id of the work order (e.g. "ord-0012867")
 *   data-wo-number  human-readable WO number (e.g. "ORD0012867")
 *   data-tab-pane   tab identifier for tab:close (matches the tab button's data-tab-id)
 *
 * Events dispatched on document (bubbles: true, composed: true):
 *   task:open  {woId, woNumber, taskName}   — when a task row is clicked
 *   tab:close  {tabId}                      — when the × button is clicked
 */

/** Map task state string → CSS class name (shared mapping across all components) */
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

function dispatch(type, detail) {
  document.dispatchEvent(new CustomEvent(type, { detail, bubbles: true, composed: true }));
}

class WoDetailTab extends HTMLElement {
  connectedCallback() {
    this._shadow = this.attachShadow({ mode: "open" });
    this._shadow.innerHTML = `
      <style>
        :host {
          display: block;
          padding: var(--hfs-space-md, 16px);
          font-family: var(--hfs-font, system-ui, sans-serif);
          font-size: 13px;
          color: var(--hfs-color-text, #1b2734);
          height: 100%;
          overflow: auto;
          box-sizing: border-box;
        }
        .loading, .error {
          color: var(--hfs-color-text-muted, #5b6770);
          padding: 16px 0;
        }
        .error { color: var(--hfs-status-problem, #dc2626); }

        /* Header card */
        .header-card {
          background: var(--hfs-color-surface, #fff);
          border: 1px solid var(--hfs-color-border, #d8dde3);
          border-radius: 6px;
          padding: var(--hfs-space-md, 16px);
          margin-bottom: var(--hfs-space-md, 16px);
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          gap: var(--hfs-space-md, 16px);
        }
        .header-info h2 {
          font-size: 16px;
          font-weight: 700;
          color: var(--hfs-color-primary, #1f8476);
          margin-bottom: 6px;
        }
        .header-meta {
          display: flex;
          flex-wrap: wrap;
          gap: 8px 20px;
          font-size: 12px;
          color: var(--hfs-color-text-muted, #5b6770);
        }
        .header-meta span strong {
          color: var(--hfs-color-text, #1b2734);
        }
        .close-btn {
          background: none;
          border: 1px solid var(--hfs-color-border, #d8dde3);
          border-radius: 4px;
          width: 28px;
          height: 28px;
          cursor: pointer;
          font-size: 16px;
          color: var(--hfs-color-text-muted, #5b6770);
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
          transition: background 0.12s, color 0.12s;
        }
        .close-btn:hover {
          background: #fef2f2;
          color: var(--hfs-status-problem, #dc2626);
          border-color: var(--hfs-status-problem, #dc2626);
        }

        /* Task table */
        table {
          width: 100%;
          border-collapse: collapse;
          font-size: 12px;
          background: var(--hfs-color-surface, #fff);
          border: 1px solid var(--hfs-color-border, #d8dde3);
          border-radius: 6px;
          overflow: hidden;
        }
        th, td {
          padding: 7px 10px;
          border-bottom: 1px solid var(--hfs-color-border, #d8dde3);
          text-align: left;
          vertical-align: middle;
        }
        th {
          font-size: 11px;
          font-weight: 700;
          letter-spacing: 0.04em;
          text-transform: uppercase;
          color: var(--hfs-color-text-muted, #5b6770);
          background: var(--hfs-color-bg, #f4f5f7);
        }
        tbody tr {
          cursor: pointer;
          transition: background 0.1s;
        }
        tbody tr:hover td { background: #f0f9f7; }
        tbody tr:last-child td { border-bottom: none; }

        /* State dots */
        .dot {
          display: inline-block;
          width: 9px;
          height: 9px;
          border-radius: 50%;
          vertical-align: middle;
          margin-right: 6px;
        }
        .dot.open      { background: transparent; border: 1.5px solid var(--hfs-status-open, #9aa5b1); }
        .dot.pending   { background: var(--hfs-status-pending,   #f59e0b); border: none; }
        .dot.scheduled { background: var(--hfs-status-scheduled, #3b82f6); border: none; }
        .dot.done      { background: var(--hfs-status-done,      #10b981); border: none; }
        .dot.problem   { background: var(--hfs-status-problem,   #dc2626); border: none; }
        .dot.na {
          display: inline;
          width: auto; height: auto;
          border-radius: 0;
          background: none; border: none;
          color: var(--hfs-color-text-muted, #5b6770);
          margin-right: 4px;
        }
        .dot.na::before { content: "—"; }
      </style>
      <div class="loading">Loading…</div>
    `;

    this._load();
  }

  async _load() {
    const woId     = this.dataset.woId;
    const woNumber = this.dataset.woNumber;

    try {
      const res = await fetch(`/api/work-orders/${encodeURIComponent(woId)}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      this._shadow.querySelector(".loading")?.remove();
      this._render(data, woNumber);
    } catch (err) {
      const el = this._shadow.querySelector(".loading");
      if (el) { el.className = "error"; el.textContent = `Error: ${err.message}`; }
    }
  }

  _render(data, woNumber) {
    const woId   = this.dataset.woId;
    const tabId  = this.dataset.tabPane;

    // --- Header card ---
    const card = document.createElement("div");
    card.className = "header-card";

    const info = document.createElement("div");
    info.className = "header-info";
    info.innerHTML = `
      <h2>${data.number}</h2>
      <div class="header-meta">
        <span><strong>Account:</strong> ${data.account ?? "—"}</span>
        <span><strong>Address:</strong> ${data.address ?? "—"}, ${data.city ?? ""}</span>
        <span><strong>Construction:</strong> ${data.construction_status ?? "—"}</span>
        <span><strong>Set:</strong> ${data.set_name ?? "—"}</span>
      </div>
    `;

    const closeBtn = document.createElement("button");
    closeBtn.className = "close-btn";
    closeBtn.textContent = "×";
    closeBtn.title = "Close tab";
    closeBtn.addEventListener("click", () => {
      dispatch("tab:close", { tabId });
    });

    card.appendChild(info);
    card.appendChild(closeBtn);
    this._shadow.appendChild(card);

    // --- Task table ---
    const table  = document.createElement("table");
    const thead  = table.createTHead();
    const hRow   = thead.insertRow();
    for (const label of ["Task", "State", "Assignment Group", "Last Updated"]) {
      const th = document.createElement("th");
      th.textContent = label;
      hRow.appendChild(th);
    }

    const tbody = table.createTBody();
    const tasks = data.tasks ?? [];
    for (const task of tasks) {
      const tr = tbody.insertRow();
      tr.title = `Click to open ${task.short_description}`;
      tr.addEventListener("click", () => {
        dispatch("task:open", {
          woId,
          woNumber: woNumber ?? data.number,
          taskName: task.short_description
        });
      });

      // Task name
      const tdName = tr.insertCell();
      tdName.textContent = task.short_description;

      // State with dot
      const tdState = tr.insertCell();
      const dot  = document.createElement("span");
      const cls  = stateClass(task.state);
      dot.className = `dot ${cls}`;
      tdState.appendChild(dot);
      tdState.appendChild(document.createTextNode(task.state));

      // Assignment group
      const tdGroup = tr.insertCell();
      tdGroup.textContent = task.assignment_group ?? "—";

      // Last updated
      const tdUpdated = tr.insertCell();
      tdUpdated.textContent = task.sys_updated_on ?? "—";
    }

    this._shadow.appendChild(table);
  }
}

customElements.define("wo-detail-tab", WoDetailTab);
