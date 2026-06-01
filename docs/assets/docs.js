/* Thunderbird iOS docs — interactions: accordions, ToC scrollspy, theme, mobile drawer */
(function () {
  "use strict";

  /* ---------- Theme (persisted) ---------- */
  const root = document.documentElement;
  const stored = localStorage.getItem("tb-docs-theme");
  if (stored === "dark" || (!stored && window.matchMedia("(prefers-color-scheme: dark)").matches)) {
    root.classList.add("dark");
  }
  function toggleTheme() {
    root.classList.toggle("dark");
    localStorage.setItem("tb-docs-theme", root.classList.contains("dark") ? "dark" : "light");
    syncThemeIcon();
  }
  function syncThemeIcon() {
    const btn = document.getElementById("theme-toggle");
    if (btn) btn.textContent = root.classList.contains("dark") ? "☀" : "☾";
  }

  /* ---------- Accordions ---------- */
  function initAccordions() {
    document.querySelectorAll(".accordion-trigger").forEach((trigger) => {
      trigger.addEventListener("click", () => {
        const item = trigger.closest(".accordion-item");
        const willOpen = !item.classList.contains("open");
        item.classList.toggle("open", willOpen);
        if (willOpen && item.id) history.replaceState(null, "", "#" + item.id);
      });
    });
  }
  function expandAll() { document.querySelectorAll(".accordion-item").forEach((i) => i.classList.add("open")); }
  function collapseAll() { document.querySelectorAll(".accordion-item").forEach((i) => i.classList.remove("open")); }

  // Open accordion targeted by the URL hash (and scroll to it)
  function openHashTarget() {
    if (!location.hash) return;
    const el = document.querySelector(location.hash);
    if (!el) return;
    const item = el.closest ? el.closest(".accordion-item") : null;
    if (item) item.classList.add("open");
    else if (el.classList && el.classList.contains("accordion-item")) el.classList.add("open");
    setTimeout(() => el.scrollIntoView({ behavior: "smooth", block: "start" }), 60);
  }

  /* ---------- ToC scrollspy ---------- */
  function initScrollSpy() {
    const links = Array.from(document.querySelectorAll(".toc a[href^='#']"));
    if (!links.length) return;
    const map = new Map();
    links.forEach((l) => {
      const id = decodeURIComponent(l.getAttribute("href").slice(1));
      const target = document.getElementById(id);
      if (target) map.set(target, l);
    });
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            links.forEach((l) => l.classList.remove("active"));
            const link = map.get(entry.target);
            if (link) link.classList.add("active");
          }
        });
      },
      { rootMargin: "-72px 0px -70% 0px", threshold: 0 }
    );
    map.forEach((_, target) => observer.observe(target));
  }

  /* ---------- Mobile ToC drawer ---------- */
  function initTocToggle() {
    const btn = document.getElementById("toc-toggle");
    const toc = document.querySelector(".toc");
    if (!btn || !toc) return;
    btn.addEventListener("click", () => toc.classList.toggle("open"));
    toc.addEventListener("click", (e) => {
      if (e.target.tagName === "A" && window.innerWidth <= 1024) toc.classList.remove("open");
    });
  }

  document.addEventListener("DOMContentLoaded", () => {
    initAccordions();
    initScrollSpy();
    initTocToggle();
    syncThemeIcon();
    const tt = document.getElementById("theme-toggle");
    if (tt) tt.addEventListener("click", toggleTheme);
    const ea = document.getElementById("expand-all");
    if (ea) ea.addEventListener("click", expandAll);
    const ca = document.getElementById("collapse-all");
    if (ca) ca.addEventListener("click", collapseAll);
    openHashTarget();
  });
  window.addEventListener("hashchange", openHashTarget);
})();
