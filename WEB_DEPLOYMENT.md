# PLAKORO Adventures — Web Deployment

This build targets desktop browsers first (16:9 UI). Mobile responsive changes are intentionally not included.

## Godot Web export

1. Use Godot 4.7 with the Web export templates installed.
2. Open **Project > Export > Web**.
3. Keep **Thread Support disabled**. This avoids COOP/COEP requirements on itch.io and GitHub Pages.
4. Export as **Release** to `web/index.html`. Do not rename the generated `.html`, `.js`, `.wasm`, or `.pck` files afterward.
5. Test through HTTP/HTTPS. Do **not** double-click `index.html` using `file://`.

Local test from the project directory:

```bash
python -m http.server 8060 -d web
```

Then open `http://localhost:8060/`.

## Fullscreen

Web builds show a **Fullscreen** button on the main menu. Browser security requires fullscreen to be entered from a user click/key event, so the game does not force fullscreen automatically. Once entered, fullscreen remains active through scene changes until the player exits it (usually Escape).

## itch.io

1. Export the Web release.
2. ZIP the **contents inside `web/`**, so `index.html` is at the root of the ZIP.
3. Create/edit an itch.io project and choose **HTML** as the project kind.
4. Upload the ZIP and mark it as playable in browser.
5. Recommended embedded viewport: **1280 × 720** (or 960 × 540 for a smaller page).
6. Enable itch.io's fullscreen control if desired. The in-game Fullscreen button is also available.

## GitHub Pages

1. Export the Web release.
2. Publish the **contents of `web/`** at the Pages root (root of the branch or `/docs`, depending on repository settings).
3. Ensure the deployed page is HTTPS. GitHub Pages provides this automatically.
4. No custom COOP/COEP headers are required because this preset is single-threaded.

## Save data (`user://`)

Godot Web stores `user://` in browser storage (IndexedDB). Persistence can be unavailable in private/incognito sessions or when browser storage is blocked. Embedded itch.io games can also be affected by third-party storage restrictions. GitHub Pages is first-party storage for its own site and is generally simpler for persistence.

## If the page says `NetworkError when attempting to fetch resource`

Check that:

- the page is being served by HTTP/HTTPS, not `file://`;
- `index.html`, generated `.js`, `.wasm`, and `.pck` files were uploaded together;
- generated files were not renamed after export;
- browser DevTools > Network shows no 404 responses.
