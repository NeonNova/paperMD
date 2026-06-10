/* paperMD preview renderer. Exposes three functions called from Swift:
 *   renderMarkdown(text)  – render markdown into #content
 *   setThemeVars(vars)    – set CSS custom properties + toggle hljs theme
 *   setBaseDir(href)      – resolve relative image paths against the file's dir
 */
"use strict";

mermaid.initialize({ startOnLoad: false, securityLevel: "strict" });

const md = window
  .markdownit({ html: false, linkify: true, breaks: false, typographer: true })
  .use(window.markdownitFootnote)
  .use(window.markdownitTaskLists, { enabled: false, label: true });

/* Wikilinks: render [[Name]] / [[Name|Alias]] as styled (non-clickable) text. */
md.inline.ruler.before("link", "wikilink", (state, silent) => {
  const src = state.src, pos = state.pos;
  if (src.charCodeAt(pos) !== 0x5b || src.charCodeAt(pos + 1) !== 0x5b) return false;
  const end = src.indexOf("]]", pos + 2);
  if (end < 0) return false;
  if (!silent) {
    const inner = src.slice(pos + 2, end);
    const label = inner.includes("|") ? inner.split("|").pop() : inner;
    const token = state.push("wikilink", "", 0);
    token.content = label.trim();
  }
  state.pos = end + 2;
  return true;
});
md.renderer.rules.wikilink = (tokens, i) =>
  `<span class="wikilink">${md.utils.escapeHtml(tokens[i].content)}</span>`;

/* Syntax highlighting for normal code fences (mermaid handled separately). */
md.options.highlight = (str, lang) => {
  if (lang === "mermaid") return "";
  if (lang && hljs.getLanguage(lang)) {
    try { return hljs.highlight(str, { language: lang }).value; } catch (e) {}
  }
  return "";
};

/* Replace ```mermaid fences with a placeholder carrying a content hash. */
const defaultFence = md.renderer.rules.fence.bind(md.renderer.rules);
md.renderer.rules.fence = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  if (token.info.trim() === "mermaid") {
    const h = hash(token.content);
    return `<div class="mermaid-block" data-hash="${h}" ` +
           `data-src="${encodeURIComponent(token.content)}"></div>`;
  }
  return defaultFence(tokens, idx, options, env, self);
};

/* Cache rendered diagrams by content hash so unchanged ones don't re-render
 * (avoids flicker while typing elsewhere). */
const mermaidCache = new Map();
let mermaidSeq = 0;

async function renderMermaid() {
  const blocks = document.querySelectorAll(".mermaid-block");
  for (const el of blocks) {
    const h = el.dataset.hash;
    if (mermaidCache.has(h)) { el.innerHTML = mermaidCache.get(h); continue; }
    try {
      const src = decodeURIComponent(el.dataset.src);
      const { svg } = await mermaid.render("mmd-" + mermaidSeq++, src);
      mermaidCache.set(h, svg);
      el.innerHTML = svg;
    } catch (e) {
      el.innerHTML = `<pre class="mermaid-error">${md.utils.escapeHtml(String(e))}</pre>`;
    }
  }
}

window.renderMarkdown = function (text) {
  const scrollY = window.scrollY;
  // Safe by construction: markdown-it runs with html:false (any raw HTML in the
  // source is escaped, not executed), Mermaid uses securityLevel:"strict", and
  // the input is the user's own local file — not untrusted remote content. No
  // sanitizer dependency is warranted for this single-user, local-file app.
  document.getElementById("content").innerHTML = md.render(text || "");
  renderMathInElement(document.getElementById("content"), {
    delimiters: [
      { left: "$$", right: "$$", display: true },
      { left: "$", right: "$", display: false },
      { left: "\\(", right: "\\)", display: false },
      { left: "\\[", right: "\\]", display: true },
    ],
    throwOnError: false,
  });
  renderMermaid();
  window.scrollTo(0, scrollY);
};

window.setThemeVars = function (vars) {
  const root = document.documentElement;
  for (const [k, v] of Object.entries(vars)) root.style.setProperty("--" + k, v);
  // Swap highlight.js stylesheet to match light/dark themes.
  const dark = vars["is-dark"] === "1";
  document.getElementById("hljs-light").disabled = dark;
  document.getElementById("hljs-dark").disabled = !dark;
};

window.setBaseDir = function (href) {
  let base = document.querySelector("base");
  if (!base) { base = document.createElement("base"); document.head.appendChild(base); }
  base.href = href;
};

/* Scroll a heading (nth, 0-based) into view — used by the outline in preview. */
window.scrollToHeading = function (index) {
  const headings = document.querySelectorAll("h1,h2,h3,h4,h5,h6");
  if (headings[index]) headings[index].scrollIntoView({ behavior: "auto", block: "start" });
};

function hash(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0;
  return h.toString(36);
}
