# kora_sound agent guide

`kora_sound` is a Kora sound resource (a `kora_lib` rebuild of `interact-sound`): server and client exports and legacy net events play bundled `.ogg` files through a Howler NUI page, with area falloff, categories, loops and a cooldown. Layout: `fxmanifest.lua`, `config.lua` (volumes, categories, helpers), `client/main.lua` (exports, events, NUI messages), `server/main.lua` (exports, validated legacy events, loop tracking), `client/html/` (NUI page and sounds), `test/` (offline client and NUI tests).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first for an overview of features, configuration, exports and events.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.
