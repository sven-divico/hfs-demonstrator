// Wires sidebar list buttons to the matrix
document.querySelectorAll(".list-item").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".list-item").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    const matrix = document.getElementById("matrix-view");
    matrix.setAttribute("data-list", btn.dataset.list);
  });
});
