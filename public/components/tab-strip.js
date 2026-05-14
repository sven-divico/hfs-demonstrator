/**
 * <tab-strip> — Workspace tab bar
 *
 * Listens on document for:
 *   wo:open   {woId, woNumber}         → opens / activates a wo-detail-tab pane
 *   task:open {woId, woNumber, taskName} → opens / activates a task-detail-tab pane
 *   tab:close {tabId}                  → removes the tab + pane, falls back to matrix
 *
 * The "matrix" tab (data-tab-id="matrix") is permanent / non-closeable.
 * Tab buttons are slotted into light DOM so they pick up ::slotted styles.
 */
class TabStrip extends HTMLElement {
  constructor() {
    super();
    this.tabs = new Map(); // tabId -> { button, pane }
  }

  connectedCallback() {
    this.attachShadow({ mode: "open" });
    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
          background: var(--hfs-color-surface, #fff);
          border-bottom: 1px solid var(--hfs-color-border, #d8dde3);
          flex-shrink: 0;
        }
        nav {
          display: flex;
          padding: 0 var(--hfs-space-md, 16px);
          overflow-x: auto;
          scrollbar-width: none;
        }
        nav::-webkit-scrollbar { display: none; }
        ::slotted(button[slot="tab"]) {
          background: none;
          border: none;
          border-bottom: 2px solid transparent;
          padding: 10px 16px;
          cursor: pointer;
          font-family: var(--hfs-font, system-ui, sans-serif);
          font-size: 13px;
          color: var(--hfs-color-text-muted, #5b6770);
          white-space: nowrap;
          flex-shrink: 0;
          transition: color 0.12s, border-color 0.12s;
        }
        ::slotted(button[slot="tab"]:hover) {
          color: var(--hfs-color-primary, #1f8476);
        }
        ::slotted(button[slot="tab"].active) {
          color: var(--hfs-color-primary, #1f8476);
          border-bottom-color: var(--hfs-color-primary, #1f8476);
          font-weight: 600;
        }
      </style>
      <nav><slot name="tab"></slot></nav>
    `;

    // Listen for custom events on document — bubbles + composed crosses shadow DOM
    document.addEventListener("wo:open",   e => this.openWoTab(e.detail));
    document.addEventListener("task:open", e => this.openTaskTab(e.detail));
    document.addEventListener("tab:close", e => this.closeTab(e.detail.tabId));

    // Delegate clicks on the slotted tab buttons (they are light DOM, so we
    // listen on `this` rather than shadowRoot)
    this.addEventListener("click", e => {
      const btn = e.target.closest("button[data-tab-id]");
      if (btn) this.activate(btn.dataset.tabId);
    });
  }

  /**
   * Show the pane for tabId, hide all others.
   * Also marks the matching slot button as .active.
   */
  activate(tabId) {
    // Update tab button classes (light DOM)
    for (const btn of this.querySelectorAll("button[slot='tab']")) {
      btn.classList.toggle("active", btn.dataset.tabId === tabId);
    }
    // Show/hide panes — panes are in .content in light DOM
    document.querySelectorAll("[data-tab-pane]").forEach(pane => {
      pane.hidden = pane.dataset.tabPane !== tabId;
    });
  }

  closeTab(tabId) {
    if (tabId === "matrix") return; // permanent tab
    const t = this.tabs.get(tabId);
    if (!t) return;
    t.button.remove();
    t.pane.remove();
    this.tabs.delete(tabId);
    this.activate("matrix"); // fall back to matrix
  }

  openWoTab({ woId, woNumber }) {
    const id = `wo-${woId}`;
    if (!this.tabs.has(id)) {
      const button = this._mkTabButton(id, woNumber);
      const pane   = document.createElement("wo-detail-tab");
      pane.setAttribute("data-wo-id",     woId);
      pane.setAttribute("data-wo-number", woNumber);
      pane.setAttribute("data-tab-pane",  id);
      document.querySelector(".content").appendChild(pane);
      this.tabs.set(id, { button, pane });
    }
    this.activate(id);
  }

  openTaskTab({ woId, woNumber, taskName }) {
    // Sanitise taskName into a safe DOM id segment (replace spaces + special chars)
    const safeName = taskName.replace(/[^a-zA-Z0-9\-_]/g, "_");
    const id = `task-${woId}-${safeName}`;
    if (!this.tabs.has(id)) {
      const button = this._mkTabButton(id, `${woNumber} · ${taskName}`);
      const pane   = document.createElement("task-detail-tab");
      pane.setAttribute("data-wo-id",     woId);
      pane.setAttribute("data-wo-number", woNumber);
      pane.setAttribute("data-task-name", taskName);
      pane.setAttribute("data-tab-pane",  id);
      document.querySelector(".content").appendChild(pane);
      this.tabs.set(id, { button, pane });
    }
    this.activate(id);
  }

  _mkTabButton(tabId, label) {
    const b = document.createElement("button");
    b.slot = "tab";
    b.dataset.tabId = tabId;
    b.textContent = label;
    this.appendChild(b);
    return b;
  }
}

customElements.define("tab-strip", TabStrip);
