pub const css_styles =
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
