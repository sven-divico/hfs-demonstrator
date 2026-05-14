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
          align-items: flex-end;
          /* No fixed height — strip auto-sizes to the tab button plus the
             padding-top below, so the active tab fills the strip and reads
             as a single block (≈ 1.5× table-row height). */
          padding: 8px var(--hfs-space-md, 16px) 0;
          gap: 4px;
          overflow-x: auto;
          scrollbar-width: none;
        }
        nav::-webkit-scrollbar { display: none; }
        ::slotted(button[slot="tab"]) {
          background: transparent;
          border: 1px solid transparent;              /* reserved space so active state doesn't shift */
          border-bottom: none;
          border-radius: 4px 4px 0 0;
          padding: 16px 22px;                         /* tab visible height ≈ 1.5× table row */
          margin-bottom: -1px;                        /* overlap the host border */
          cursor: pointer;
          font-family: var(--hfs-font, system-ui, sans-serif);
          font-size: 13px;
          color: var(--hfs-color-text-muted, #5b6770);
          white-space: nowrap;
          flex-shrink: 0;
          transition: background 0.12s, color 0.12s, border-color 0.12s;
        }
        ::slotted(button[slot="tab"]:hover) {
          color: var(--hfs-color-primary, #1f8476);
          background: rgba(31, 132, 118, 0.04);
        }
        /* Active tab — register-card look: distinctly darker bg, a small
           top accent and subtle shadow that lift it off the strip; the -1px
           bottom margin lets the host's bottom border pass BEHIND it so
           it reads as one continuous surface with the page below. */
        ::slotted(button[slot="tab"].active) {
          color: var(--hfs-color-text, #1b2734);
          background: var(--hfs-color-tab-active, #dde3eb);
          border-color: var(--hfs-color-border, #d8dde3);
          font-weight: 600;
          box-shadow:
            inset 0 2px 0 0 var(--hfs-color-primary, #1f8476),
            0 -1px 2px rgba(27, 39, 52, 0.04);
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
