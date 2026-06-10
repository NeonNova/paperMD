#!/bin/bash
# Downloads the pinned preview JS/CSS assets into the app bundle's resources.
# These files are committed to git so the app works fully offline and builds
# never depend on the network. Re-run only to bump versions.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
V="$ROOT/Sources/paperMD/Resources/Preview/vendor"
FONTS="$V/fonts"
mkdir -p "$FONTS"

JSDELIVR="https://cdn.jsdelivr.net/npm"

dl() { # url -> dest
    curl -fsSL "$1" -o "$2"
    # Guard against CDNs returning an HTML error page instead of the asset.
    if head -c 200 "$2" | grep -qi "<!doctype html"; then
        echo "ERROR: $2 looks like an HTML error page, not an asset" >&2
        exit 1
    fi
    echo "✓ $(basename "$2") ($(wc -c < "$2" | tr -d ' ') bytes)"
}

echo "==> markdown-it + plugins"
dl "$JSDELIVR/markdown-it@14.1.0/dist/markdown-it.min.js"                       "$V/markdown-it.min.js"
dl "$JSDELIVR/markdown-it-footnote@4.0.0/dist/markdown-it-footnote.min.js"      "$V/markdown-it-footnote.min.js"
dl "$JSDELIVR/markdown-it-task-lists@2.1.1/dist/markdown-it-task-lists.min.js"  "$V/markdown-it-task-lists.min.js"

echo "==> highlight.js (cdnjs UMD browser build; jsdelivr lib/ paths are CJS)"
dl "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.10.0/highlight.min.js"      "$V/highlight.min.js"
dl "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.10.0/styles/github.min.css" "$V/highlight-github.min.css"
dl "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.10.0/styles/github-dark.min.css" "$V/highlight-github-dark.min.css"

echo "==> KaTeX"
dl "$JSDELIVR/katex@0.16.11/dist/katex.min.js"                  "$V/katex.min.js"
dl "$JSDELIVR/katex@0.16.11/dist/katex.min.css"                 "$V/katex.min.css"
dl "$JSDELIVR/katex@0.16.11/dist/contrib/auto-render.min.js"    "$V/katex-auto-render.min.js"

echo "==> KaTeX fonts (referenced by katex.min.css)"
# Parse the font filenames KaTeX references and fetch each into fonts/.
grep -oE "fonts/KaTeX_[A-Za-z0-9_-]+\.woff2" "$V/katex.min.css" | sort -u | while read -r f; do
    dl "$JSDELIVR/katex@0.16.11/dist/$f" "$V/$f"
done

echo "==> Mermaid"
dl "$JSDELIVR/mermaid@11.4.0/dist/mermaid.min.js"               "$V/mermaid.min.js"

echo ""
echo "Done. Vendored into $V"
