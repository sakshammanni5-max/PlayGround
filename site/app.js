// Renders the build stamp produced by start.sh into the landing page.
(async function () {
  try {
    const res = await fetch("build-info.json", { cache: "no-store" });
    if (!res.ok) throw new Error("HTTP " + res.status);
    const info = await res.json();
    document.getElementById("build-status").textContent =
      "built " + (info.built_at || "unknown");
    document.getElementById("build-time").textContent =
      (info.commit || "no-commit") + " · " + (info.built_at || "");
  } catch (err) {
    document.getElementById("build-status").textContent = "preview (no stamp)";
  }
})();
