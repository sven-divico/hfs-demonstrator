// Wires sidebar list buttons to the matrix
document.querySelectorAll(".list-item").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".list-item").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    const matrix = document.getElementById("matrix-view");
    matrix.setAttribute("data-list", btn.dataset.list);
  });
});

// Transient toast pill at bottom-right; used by the "Schedule Appointment"
// button to acknowledge the demo-only click.
document.addEventListener("ui:toast", e => {
  const message = e.detail?.message ?? "";
  let host = document.getElementById("toast-host");
  if (!host) {
    host = document.createElement("div");
    host.id = "toast-host";
    host.style.cssText = "position:fixed;bottom:24px;right:24px;z-index:9999;display:flex;flex-direction:column;gap:8px;";
    document.body.appendChild(host);
  }
  const pill = document.createElement("div");
  pill.textContent = message;
  pill.style.cssText = [
    "background:#1b2734","color:#fff","padding:10px 16px","border-radius:6px",
    "font:13px system-ui,sans-serif","box-shadow:0 4px 12px rgba(0,0,0,0.2)",
    "opacity:0","transform:translateY(8px)","transition:opacity .2s,transform .2s",
  ].join(";");
  host.appendChild(pill);
  requestAnimationFrame(() => { pill.style.opacity = "1"; pill.style.transform = "translateY(0)"; });
  setTimeout(() => {
    pill.style.opacity = "0";
    pill.style.transform = "translateY(8px)";
    setTimeout(() => pill.remove(), 250);
  }, 2400);
});
