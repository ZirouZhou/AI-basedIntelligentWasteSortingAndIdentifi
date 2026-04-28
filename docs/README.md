# EcoSort AI Landing Page (GitHub Pages)

This folder contains the app promotion landing page for final presentation.

## Files

- `index.html` - landing page structure and content
- `styles.css` - visual design
- `assets/screenshots/*` - app screenshots
- `assets/demo.mp4` - optional app demo video (you should add this file)

## How to add your 3-minute demo

1. Export your video/GIF (max 3 minutes).
2. Put the file at `docs/assets/demo.mp4`.
3. If you use a GIF instead, replace the `<video>` block in `index.html` with `<img src="assets/demo.gif" ...>`.

## Publish to GitHub Pages

### Option A: Root + /docs

1. Commit and push this repository.
2. In GitHub repo: **Settings -> Pages**.
3. Under **Build and deployment**:
   - Source: `Deploy from a branch`
   - Branch: `main` (or your active branch)
   - Folder: `/docs`
4. Save and wait for deployment.
5. Your page URL will appear in the Pages settings.

### Option B: GitHub Actions (optional)

If your instructor requires Actions-based deploy, you can add a Pages workflow, but for this project `/docs` deploy is usually enough.

## Presentation Mapping to Marking Rubric

- Video/GIF showcase section: `#demo`
- Landing page showcase: full page
- Overview of app (design, UX, data, integration):
  - `#problem-solution`
  - `#features`
  - `#ux`
  - `#data`
  - `#integration`
- Conclusion / future improvements: `#improvements`
- 15-minute structure: `#presentation-plan`
