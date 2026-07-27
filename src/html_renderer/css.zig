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

