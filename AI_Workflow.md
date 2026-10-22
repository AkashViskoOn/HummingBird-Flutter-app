# AI Workflow — Feature Development Guide

## Purpose

Standard procedure for AI agents adding or modifying features in the Humming Bird Flutter app. Follow these steps in order.

---

## Step 1: Understand Context

- Read `AGENTS.md` (root) for project-wide conventions.
- Read `plan.md` (flutter dir) for current improvement roadmap.
- Read `project_plan.md` (root) for full architecture.
- Identify which component(s) the change touches (Flutter, backend, socket).
- Check existing files in the target area to match code style.

## Step 2: Inspect Related Code

- Read existing files that implement similar functionality.
- Read the file you need to modify (if it exists).
- Read imports and dependencies used by related files.
- Read theme/design files (`res/colors.dart`, `main.dart` theme) to match styling.

## Step 3: Plan the Change

- Document the specific changes needed (create `AI_Workflow.md` if it doesn't exist).
- Check for cross-component impacts (socket events, API endpoints, models).
- Verify import paths are case-correct (Windows hides case issues).

## Step 4: Implement

- Follow existing code patterns (GetX controllers, Obx/GetBuilder, screenutil, Poppins font).
- Use `CustomColor` from `res/colors.dart` — do not hardcode colors.
- Use `flutter_screenutil` (`.sp`, `.w`, `.h`, `.r`) for responsive sizing.
- Use `google_fonts` Poppins for text styling.
- Use GetX navigation (`Get.to()`, `Get.back()`) — never `Navigator.push()`.
- Add `const` constructors where possible.
- Do not add comments unless the logic is non-obvious.

## Step 5: Verify

- Run `flutter analyze` to catch lint errors.
- Check all imports resolve correctly (especially case-sensitive paths).
- Verify navigation works end-to-end.
- Confirm no existing functionality is broken.

## Step 6: Document

- Update `plan.md` if the change adds or removes planned work.
- Update `project_plan.md` if architecture changes.

---

## Current Task: Terms & Conditions Page

### Objective
Replace placeholder "Lorem ipsum" text in `term_and_condition.dart` with real terms & conditions content, and restyle the page to match the app's Material 3 design system.

### Design Constraints
- Background: `CustomColor.k2LightsecondaryColor`
- Header bar: `CustomColor.kLightPrimaryColor` with chevron-left back button
- Font: Poppins via `google_fonts`
- Sizing: `flutter_screenutil` (`.sp`, `.w`, `.h`)
- Navigation: `Get.to()` / `Get.back()` — not `Navigator`
- Sections: Use `ExpansionTile` or scrollable sections for clean layout
- No Accept/Cancel buttons (this is an information page, not an onboarding step)

### Files to Modify
- `lib/pages/setting/account/term_and_condition.dart` — rewrite content and styling
- `lib/components/sidebar_drawer_menu.dart` — fix import path case if needed

### Validation
- `flutter analyze` passes
- Sidebar → Terms & Help navigates correctly
- Back button works
- Content renders properly on different screen sizes
