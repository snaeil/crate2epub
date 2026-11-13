#!/bin/sh
set -e

CRATE="$1"
VERSION="$2"

if [ -z "$CRATE" ]; then
    echo -e "Usage: $0 <crate-name> [version]\n\nExamples:\n  ./crate2epub.sh axum\n  ./crate2epub.sh axum 0.8.9\n\nPrerequisites:\n  - cargo\n  - pandoc" >&2
    exit 1
fi

if ! command -v cargo >/dev/null 2>&1
then
    echo "cargo could not be found"
    exit 1
fi
if ! command -v pandoc >/dev/null 2>&1
then
    echo "pandoc could not be found"
    exit 1
fi

MOD_NAME=$(printf '%s' "$CRATE" | tr '-' '_')
PKG_SPEC="$CRATE"
[ -n "$VERSION" ] && PKG_SPEC="${CRATE}@${VERSION}"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

cargo init --lib "$WORK_DIR" --name doc_builder --quiet
cargo add "$PKG_SPEC" --manifest-path "$WORK_DIR/Cargo.toml" --quiet

cargo doc --manifest-path "$WORK_DIR/Cargo.toml" -p "$CRATE" --no-deps --quiet

cat << 'EOF' > "$WORK_DIR/clean.lua"
local function norm_path(base, target)
    if target:match("^https?://") or target:match("^mailto:") or target:match("^#") then
        return nil
    end
    local path, hash = target:match("^([^#]*)(#?.*)$")
    if path == "" then return nil end

    local dir = base:match("^(.*)/[^/]+$") or ""
    local combined = (dir ~= "" and (dir .. "/" .. path) or path)

    local parts = {}
    for part in combined:gmatch("[^/]+") do
        if part == ".." then
            table.remove(parts)
        elseif part ~= "." then
            table.insert(parts, part)
        end
    end
    local resolved = table.concat(parts, "/")
    if resolved == "" then resolved = "index.html" end
    return resolved, hash
end

local function path_to_id(path)
    return "doc-" .. path:gsub("[^%w]", "-")
end

function Pandoc(doc)
    local current_file = PANDOC_STATE.input_files[1] or "index.html"
    local file_idx = 1

    for i, blk in ipairs(doc.blocks) do
        if blk.t == "Header" and blk.level == 1 then
            local fname = PANDOC_STATE.input_files[file_idx]
            if fname then
                blk.identifier = path_to_id(fname)
                current_file = fname
                file_idx = file_idx + 1
            end
        end
    end

    local active_file = "index.html"
    local idx = 1
    doc.blocks = doc.blocks:walk({
        Header = function(el)
            if el.level == 1 and PANDOC_STATE.input_files[idx] then
                active_file = PANDOC_STATE.input_files[idx]
                idx = idx + 1
            end
            el.content = el.content:walk({
                Link = function(l)
                    if l.classes:includes("anchor") or pandoc.utils.stringify(l) == "§" then
                        return {}
                    end
                end
            })
            return el
        end,
        Link = function(l)
            local resolved, hash = norm_path(active_file, l.target)
            if resolved and resolved:match("%.html$") then
                if hash ~= "" and hash ~= "#" then
                    l.target = hash
                else
                    l.target = "#" .. path_to_id(resolved)
                end
                return l
            end
        end
    })
    return doc
end
EOF

OUT_FILE="$PWD/${CRATE}${VERSION:+-$VERSION}-docs.epub"
DOC_DIR="$WORK_DIR/target/doc/$MOD_NAME"
cd "$DOC_DIR"

FILES=$(find . -name "*.html" \
    ! -path "./index.html" \
    ! -name "all.html" \
    ! -name "sidebar-items.html" | sed 's|^\./||' | sort)

pandoc "index.html" $FILES \
    -f html-native_divs-native_spans \
    -o "$OUT_FILE" \
    --lua-filter="$WORK_DIR/clean.lua" \
    --toc \
    --toc-depth=2 \
    --split-level=1 \
    --metadata title="$CRATE ${VERSION:-latest} Documentation"

echo "Created: $OUT_FILE"
