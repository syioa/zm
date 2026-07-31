pub const catppuccin_css = @import("assets/catppuccin.zig").catppuccin_css;

pub const css_styles =
    \\<style>

    // core
    \\:root {
    \\    color-scheme: light dark;
    \\    -webkit-text-size-adjust: 100%;
    \\}
    \\
    \\*,
    \\*::before,
    \\*::after {
    \\    box-sizing: border-box;
    \\    min-width: 0;
    \\}
    \\
    \\html {
    \\    scroll-behavior: smooth;
    \\    font-size: 100%;
    \\}
    \\
    \\body {
    \\    margin: 0;
    \\    min-width: 320px;
    \\
    \\    font-family:
    \\        Inter,
    \\        "SF Pro Text",
    \\        "Segoe UI",
    \\        Roboto,
    \\        sans-serif;
    \\
    \\    font-size: clamp(1rem, 0.95rem + 0.2vw, 1.125rem);
    \\    line-height: 1.7;
    \\
    \\    color: var(--ctp-text);
    \\    background: var(--ctp-base);
    \\
    \\    text-rendering: optimizeLegibility;
    \\    -webkit-font-smoothing: antialiased;
    \\    -webkit-text-size-adjust: 100%;
    \\
    \\    max-width: 75ch;
    \\    margin-inline: auto;
    \\    padding-inline: clamp(1rem, 2vw, 2rem);
    \\}
    \\
    \\::selection {
    \\    background: var(--ctp-blue);
    \\    color: var(--ctp-base);
    \\}
    \\
    \\p,
    \\li,
    \\blockquote,
    \\td,
    \\th {
    \\    font-size: inherit;
    \\    line-height: inherit;
    \\}
    \\
    \\a {
    \\    color: var(--ctp-blue);
    \\    text-decoration: none;
    \\    text-underline-offset: 0.15em;
    \\    transition: color 150ms ease;
    \\}
    \\
    \\a:hover {
    \\    color: var(--ctp-sapphire);
    \\    text-decoration: underline;
    \\}
    \\
    \\img,
    \\svg,
    \\video {
    \\    display: block;
    \\    max-width: 100%;
    \\    height: auto;
    \\}
    \\
    \\button,
    \\input,
    \\select,
    \\textarea {
    \\    font: inherit;
    \\}
    \\
    \\button {
    \\    cursor: pointer;
    \\    touch-action: manipulation;
    \\}
    \\
    \\hr {
    \\    margin-block: clamp(1.5rem, 4vw, 2.5rem);
    \\    border: none;
    \\    height: 2px;
    \\    background: var(--ctp-surface1);
    \\}

    // headings
    \\h1 {
    \\    font-size: clamp(2.2rem, 1.4rem + 2.6vw, 4rem);
    \\    line-height: 1.1;
    \\    letter-spacing: -0.04em;
    \\}
    \\
    \\h2 {
    \\    font-size: clamp(1.8rem, 1.3rem + 1.8vw, 3rem);
    \\    line-height: 1.15;
    \\    letter-spacing: -0.03em;
    \\}
    \\
    \\h3 {
    \\    font-size: clamp(1.5rem, 1.2rem + 1vw, 2.25rem);
    \\    line-height: 1.2;
    \\    letter-spacing: -0.02em;
    \\}
    \\
    \\h4 {
    \\    font-size: clamp(1.25rem, 1.1rem + 0.5vw, 1.75rem);
    \\    line-height: 1.3;
    \\}
    \\
    \\h5 {
    \\    font-size: clamp(1.1rem, 1.05rem + 0.25vw, 1.35rem);
    \\    line-height: 1.35;
    \\}
    \\
    \\h6 {
    \\    font-size: clamp(1rem, 0.95rem + 0.15vw, 1.15rem);
    \\    line-height: 1.4;
    \\    text-transform: uppercase;
    \\    letter-spacing: 0.08em;
    \\}

    // lists
    \\ul,
    \\ol {
    \\    padding-inline-start: 1.5em;
    \\}
    \\
    \\li + li {
    \\    margin-top: 0.35em;
    \\}

    // blockquote
    \\blockquote {
    \\    font-size: clamp(1.05rem, 1rem + 0.2vw, 1.2rem);
    \\    line-height: 1.7;
    \\}
    
    // unordered lists
    \\ul {
    \\    list-style: none;
    \\    margin: 1rem 0;
    \\    padding: 0;
    \\}
    \\
    \\ul > li {
    \\    --indent: 1.5rem;
    \\
    \\    position: relative;
    \\    padding: 0.25rem 0;
    \\    padding-left: calc(var(--level) * var(--indent) + 1.25rem);
    \\    line-height: 1.6;
    \\}
    \\
    \\ul > li::before {
    \\    content: "•";
    \\    position: absolute;
    \\    left: calc(var(--level) * var(--indent));
    \\    width: 1rem;
    \\    text-align: center;
    \\}

    // ordered lists
    \\ol {
    \\    list-style: none;
    \\    margin: 1rem 0;
    \\    padding: 0;
    \\}
    \\
    \\ol > li {
    \\    --indent: 1.5rem;
    \\
    \\    display: grid;
    \\    grid-template-columns: max-content 1fr;
    \\    column-gap: 0.75rem;
    \\
    \\    margin-left: calc(var(--level) * var(--indent));
    \\    padding: 0.25rem 0;
    \\    line-height: 1.6;
    \\}
    \\
    \\ol > li::before {
    \\    content: attr(data-path) ".";
    \\    font-variant-numeric: tabular-nums;
    \\    white-space: nowrap;
    \\}

    // toolbar
    \\.toolbar {
    \\    position: fixed;
    \\    top: 0;
    \\    left: 50%;
    \\
    \\    transform: translate(-50%, calc(-100% + 8px));
    \\
    \\    z-index: 1000;
    \\    overflow: visible;
    \\
    \\    transition: transform 180ms ease;
    \\}
    \\
    \\.toolbar:hover,
    \\.toolbar:focus-within,
    \\.toolbar.visible {
    \\    transform: translate(-50%, 0);
    \\}
    \\
    \\.toolbar-content {
    \\    display: flex;
    \\    align-items: center;
    \\    justify-content: center;
    \\
    \\    padding: 0.65rem 0.9rem;
    \\
    \\    background: color-mix(in srgb, var(--ctp-mantle) 92%, transparent);
    \\    backdrop-filter: blur(16px);
    \\
    \\    border: 1px solid var(--ctp-surface1);
    \\    border-top: none;
    \\
    \\    border-radius: 0 0 1rem 1rem;
    \\
    \\    box-shadow:
    \\        0 8px 24px rgb(0 0 0 / 0.18);
    \\}
    \\
    \\.toolbar::after {
    \\    content: "";
    \\
    \\    position: absolute;
    \\    left: 50%;
    \\    bottom: -8px;
    \\
    \\    translate: -50% 0;
    \\
    \\    width: 72px;
    \\    height: 4px;
    \\
    \\    border-radius: 999px;
    \\
    \\    background:
    \\        linear-gradient(
    \\            90deg,
    \\            var(--ctp-blue),
    \\            var(--ctp-lavender)
    \\        );
    \\
    \\    opacity: 0.4;
    \\
    \\    transition: opacity 150ms ease;
    \\
    \\    pointer-events: none;
    \\}
    \\
    \\.toolbar:hover::after {
    \\    opacity: 1;
    \\}
    \\
    \\.toolbar::before {
    \\    content: "";
    \\
    \\    position: absolute;
    \\
    \\    left: 50%;
    \\    bottom: -16px;
    \\
    \\    translate: -50% 0;
    \\
    \\    width: 120px;
    \\    height: 24px;
    \\}
    \\
    \\@media (prefers-reduced-motion: reduce) {
    \\    .toolbar {
    \\        transition: none;
    \\    }
    \\
    \\    .toolbar::after {
    \\        transition: none;
    \\    }
    \\}
    
    // theme switcher
    \\header {
    \\    display: flex;
    \\    align-items: center;
    \\}
    \\
    \\.theme-select-wrapper {
    \\    position: relative;
    \\    display: inline-block;
    \\    margin-left: auto;
    \\}
    \\
    \\#theme-select {
    \\    appearance: none;
    \\    -webkit-appearance: none;
    \\
    \\    min-width: 10rem;
    \\    padding: 0.55rem 2.5rem 0.55rem 0.9rem;
    \\
    \\    font: inherit;
    \\    line-height: 1.2;
    \\
    \\    color: var(--ctp-text);
    \\    background-color: var(--ctp-surface0);
    \\
    \\    border: 1px solid var(--ctp-surface2);
    \\    border-radius: 0.6rem;
    \\
    \\    cursor: pointer;
    \\    outline: none;
    \\
    \\    transition:
    \\        background-color 150ms ease,
    \\        border-color 150ms ease,
    \\        box-shadow 150ms ease,
    \\        color 150ms ease;
    \\}
    \\
    \\#theme-select:hover {
    \\    background-color: var(--ctp-surface1);
    \\    border-color: var(--ctp-overlay0);
    \\}
    \\
    \\#theme-select:focus-visible {
    \\    border-color: var(--ctp-blue);
    \\    box-shadow:
    \\        0 0 0 3px color-mix(in srgb, var(--ctp-blue) 25%, transparent);
    \\}
    \\
    \\#theme-select:active {
    \\    background-color: var(--ctp-surface2);
    \\}
    \\
    \\#theme-select option {
    \\    color: var(--ctp-text);
    \\    background-color: var(--ctp-base);
    \\}
    \\
    \\.theme-select-arrow {
    \\    position: absolute;
    \\    top: 50%;
    \\    right: 0.85rem;
    \\
    \\    transform: translateY(-50%);
    \\    pointer-events: none;
    \\
    \\    display: flex;
    \\    align-items: center;
    \\    justify-content: center;
    \\
    \\    color: var(--ctp-subtext0);
    \\
    \\    transition:
    \\        color 150ms ease,
    \\        transform 150ms ease;
    \\}
    \\
    \\.theme-select-wrapper:hover .theme-select-arrow {
    \\    color: var(--ctp-text);
    \\}
    \\
    \\#theme-select:focus-visible + .theme-select-arrow {
    \\    color: var(--ctp-blue);
    \\}
    \\
    \\.theme-select-arrow svg {
    \\    width: 0.9rem;
    \\    height: 0.9rem;
    \\    display: block;
    \\}

    // code
    \\code,
    \\kbd,
    \\samp {
    \\    font-size: 0.9em;
    \\}
    \\
    \\pre {
    \\    font-size: clamp(0.9rem, 0.88rem + 0.1vw, 1rem);
    \\    line-height: 1.6;
    \\}

    // spacing
    \\h1,
    \\h2,
    \\h3,
    \\h4,
    \\h5,
    \\h6 {
    \\    margin-block: clamp(1.5rem, 1rem + 1vw, 2.5rem)
    \\                  clamp(0.75rem, 0.5rem + 0.3vw, 1rem);
    \\    font-weight: 700;
    \\    scroll-margin-top: 5rem;
    \\}
    \\
    \\p,
    \\ul,
    \\ol,
    \\pre,
    \\blockquote,
    \\table {
    \\    margin-block: clamp(0.9rem, 0.7rem + 0.4vw, 1.4rem);
    \\}

    \\</style>
;

pub const frontmatter_js =
    \\<script type="module">
    \\function resolve(path, obj) {
    \\    let current = obj;
    \\
    \\    for (const segment of path.split('.')) {
    \\        if (current == null) return undefined;
    \\
    \\        if (Array.isArray(current)) {
    \\            const index = Number(segment);
    \\            if (!Number.isInteger(index)) return undefined;
    \\            current = current[index];
    \\        } else {
    \\            current = current[segment];
    \\        }
    \\    }
    \\
    \\    return current;
    \\}
    \\
    \\function renderVariables(root = document) {
    \\    const missing = new Set();
    \\
    \\    for (const el of document.querySelectorAll("zm-var")) {
    \\        const path = el.getAttribute("path");
    \\        const value = resolve(path, window.vars);
    \\    
    \\        if (value === undefined || value === null) {
    \\            missing.add(path);
    \\            el.replaceWith(document.createTextNode(""));
    \\        } else {
    \\            el.replaceWith(document.createTextNode(String(value)));
    \\        }
    \\    }
    \\
    \\    if (missing.size > 0) {
    \\        const div = document.createElement("div");
    \\        div.id = "zm-errors";
    \\
    \\        Object.assign(div.style, {
    \\            margin: "1rem",
    \\            padding: "1rem",
    \\            border: "1px solid #d97706",
    \\            borderRadius: "6px",
    \\            background: "#fff7ed",
    \\            color: "#7c2d12",
    \\            fontFamily: "system-ui, sans-serif",
    \\            fontSize: "14px",
    \\        });
    \\    
    \\        div.innerHTML = `
    \\            <strong>Undefined frontmatter variables</strong>
    \\            <ul>
    \\                ${[...missing].map(v => `<li>${v}</li>`).join("")}
    \\            </ul>
    \\        `;
    \\
    \\        Object.assign(div.children[0].style, {
    \\            display: "block",
    \\            marginBottom: "0.5rem",
    \\        });
    \\
    \\        document.body.prepend(div);
    \\    }
    \\}
    \\
    \\renderVariables();
    \\</script>
;

pub const theme_toggle =
    \\<header class="toolbar">
    \\  <div class"toolbar-content">
    \\    <div class="theme-select-wrapper">
    \\        <select id="theme-select">
    \\            <option value="latte">Latte</option>
    \\            <option value="frappe">Frappé</option>
    \\            <option value="macchiato">Macchiato</option>
    \\            <option value="mocha">Mocha</option>
    \\        </select>
    \\        <span class="theme-select-arrow" aria-hidden="true">
    \\            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
    \\                <path
    \\                    d="M4 6.5L8 10.5L12 6.5"
    \\                    stroke="currentColor"
    \\                    stroke-width="1.75"
    \\                    stroke-linecap="round"
    \\                    stroke-linejoin="round"
    \\                />
    \\            </svg>
    \\        </span>
    \\    </div>
    \\  </div>
    \\</header>
    \\
    \\<script id="theme-toggle toolbar">
    \\const THEME_KEY = "theme";
    \\
    \\const select = document.getElementById("theme-select");
    \\const root = document.documentElement;
    \\
    \\function applyTheme(theme) {
    \\    root.dataset.theme = theme;
    \\}
    \\
    \\let theme = localStorage.getItem(THEME_KEY);
    \\
    \\if (theme === null) {
    \\    theme = window.matchMedia("(prefers-color-scheme: dark)").matches
    \\        ? "macchiato"
    \\        : "latte";
    \\}
    \\
    \\applyTheme(theme);
    \\select.value = theme;
    \\
    \\select.addEventListener("change", () => {
    \\    const theme = select.value;
    \\
    \\    applyTheme(theme);
    \\    localStorage.setItem(THEME_KEY, theme);
    \\});
    \\
    \\const toolbar = document.querySelector(".toolbar");
    \\
    \\let hideTimer;
    \\
    \\toolbar.addEventListener("mouseenter", () => {
    \\    clearTimeout(hideTimer);
    \\    toolbar.classList.add("visible");
    \\});
    \\
    \\toolbar.addEventListener("mouseleave", () => {
    \\    hideTimer = setTimeout(() => {
    \\        toolbar.classList.remove("visible");
    \\    }, 150);
    \\});
    \\</script>
;
