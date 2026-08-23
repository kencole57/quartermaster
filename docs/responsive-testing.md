# Mobile And Responsive Testing

Quartermaster should work well on a desktop, Surface Pro, tablet, and phone. Many real cataloging sessions will happen away from a desk while checking shelves, folders, drives, or printed material.

## Core Responsive Principle

Desktop and Surface layouts can be denser and table-oriented. Phone layouts should prioritize quick lookup, quick capture, and clear touch targets.

Where practical, data-heavy screens should support two view modes:

- Table mode for dense review and management.
- List mode for mobile-friendly scanning and capture.

## Chrome DevTools Viewports To Check

Use Chrome Developer Tools device mode while developing UI changes.

### Narrow Phone

Example targets:

- iPhone SE
- 360 px wide Android viewport

Check:

- No horizontal page overflow.
- Top app bar remains usable.
- Navigation drawer opens and closes cleanly.
- Search fields and selects stack cleanly.
- Buttons and chips remain readable.
- Text wraps without overlapping nearby controls.
- Touch targets are comfortable.

### Standard Phone

Example targets:

- iPhone 14/15 style viewport
- Pixel style viewport

Check:

- List mode feels natural for catalog items.
- Add/search workflows are reachable without excess scrolling.
- Cards do not become overly tall.
- Important metadata remains visible.

### Landscape Phone

Check:

- Top app bar does not consume too much vertical space.
- Forms remain usable with limited height.
- Temporary drawer does not feel oversized.
- Dialogs and menus fit within the viewport.

### Small Tablet

Example targets:

- iPad Mini
- Surface Duo style narrow tablet widths

Check:

- Drawer behavior still makes sense.
- Table/list toggle remains visible.
- Grids do not create awkward narrow columns.
- Filters are easy to manipulate by touch.

### Surface Pro / Large Tablet

Check:

- Permanent navigation is acceptable only when there is enough usable content width.
- Table mode is comfortable.
- Search/filter controls can sit in rows without crowding.
- Cards and panels do not feel oversized.

### Desktop

Check:

- Layout uses width efficiently.
- Tables remain readable.
- Side navigation supports repeated admin-style work.
- Dense views do not feel sparse.

## Feature-Specific Checks

### Navigation

- Permanent drawer on desktop-sized layouts.
- Temporary drawer behind a hamburger button on mobile/tablet layouts.
- Current section is visually clear.

### Search And Filters

- Search should remain prominent on every viewport.
- Filters should stack on mobile.
- Labels should not truncate important meaning.

### Data Views

- Table mode should support horizontal scrolling if needed.
- List mode should avoid cramming too many fields into one row.
- The active mode should be obvious.

### Forms

- Inputs should stack on mobile.
- Primary action should be easy to reach.
- Long labels, filenames, ISBNs, paths, and URLs should wrap or scroll safely.

### Location Data

Location screens are especially important on phones because users may update records while standing near a shelf, external drive, NAS, or archive box.

Check:

- Local path text remains readable.
- Location labels are prominent.
- Found/missing/verified actions are touch-friendly.

## Regression Rule

Before merging meaningful UI changes, run at least:

- One narrow phone check.
- One standard phone check.
- One Surface/tablet-width check.
- One desktop check.

Record any known responsive compromise in the pull request or commit notes.
