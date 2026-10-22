# Humming Bird App Brand Guideline

## Brand Position

Humming Bird is a messaging and scheduling app. The product should feel fast, calm, reliable, and personal. It is not a social media feed or a marketing site; it is a daily communication tool where users need clarity, trust, and quick action.

## Design Principles

- Keep communication first. Messages, contacts, groups, and schedules should always be easier to scan than decorative UI.
- Use calm confidence. Prefer clean spacing, readable contrast, and controlled color over loud effects.
- Make actions obvious. Sending, scheduling, attaching, searching, editing, and deleting should have familiar icons and predictable placement.
- Design for repeated use. Avoid oversized empty surfaces where users need dense lists, chat history, or fast controls.
- Respect mobile constraints. Long names, group titles, messages, and timestamps must ellipsize or wrap cleanly without overflow.

## Color Palette

### Primary

- Primary Blue: `#2489C3`
  - Use for primary actions, outgoing message bubbles, active tabs, selected states, and send buttons.
- Dark Primary Blue: `#006493`
  - Use for app bars, strong headers, focused controls, and dark brand surfaces.
- Light Primary Blue: `#E2EDF9`
  - Use for soft icon button backgrounds, selected list accents, and calm secondary surfaces.
- Ultra Light Primary: `#F6FBFF`
  - Use for main app backgrounds and message-list surfaces.
- Header Tint: `#EEF5FF`
  - Use for subtle screen headers or quiet background bands.

### Secondary

- Deep Ink: `#201634`
  - Use for dark composer bars, strong text, and high-emphasis UI surfaces.
- Muted Purple: `#65587B`
  - Use sparingly for secondary badges or legacy surfaces. Do not let it dominate screens.
- Soft Lavender: `#EBDCFF`
  - Use only as a soft accent when needed.
- White: `#FFFFFF`
  - Use for cards, incoming message bubbles, modal surfaces, and text on dark headers.

### Feedback

- Danger Red: `#BA1A1A`
  - Use only for destructive actions such as delete, block, remove, and exit group.
- Light Danger/Info Tint: `#E2F4FC`
  - Use for gentle alerts or neutral informational backgrounds.

### Neutral

- Ultra Light Background: `#F5F5F5`
- Light Background: `#F1F1F1`
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border/Subtle Divider: black with `0.06` alpha
- Soft Shadow: black with `0.05` to `0.14` alpha

## Color Usage Rules

- Do not build screens from only one hue. Pair blue brand elements with white, ink, and neutral surfaces.
- Use Dark Primary Blue for major app bars and chat headers.
- Use Primary Blue for high-value actions like send, create group, save, and active states.
- Use white cards on light blue backgrounds for readable list and chat surfaces.
- Use red only for destructive decisions. Never use red for general attention.
- Avoid heavy purple gradients. Purple should be secondary, not the visual identity.

## Typography

Primary font: `Poppins` through `GoogleFonts.poppins`.

### Type Scale

- Screen title: `20sp` to `24sp`, weight `600` or `700`
- App bar title: `15sp` to `17sp`, weight `600`
- Section title: `16sp` to `18sp`, weight `600`
- List item title: `15sp` to `16sp`, weight `600`
- Body/message text: `14sp` to `15sp`, weight `400`
- Supporting text: `12sp` to `13sp`, weight `400`
- Metadata/timestamp: `9sp` to `11sp`, weight `400` or `500`

### Text Rules

- Use sentence case for labels and actions.
- Keep labels short: `Create group`, `Clear chat`, `Share contact`.
- Long titles must use `maxLines: 1` and `TextOverflow.ellipsis`.
- Do not use negative letter spacing.
- Do not scale font size directly with viewport width.

## Layout And Spacing

### Spacing Scale

- Tiny: `4`
- Small: `8`
- Medium: `12`
- Standard: `16`
- Large: `24`
- Section: `32`

### Layout Rules

- Use `Expanded` or `Flexible` for text areas in rows.
- Do not place cards inside other cards.
- Use stable dimensions for avatars, icon buttons, message controls, and counters.
- Icon buttons should generally be `40` to `44` logical pixels.
- Lists should be dense but breathable, with `8` to `12` vertical item padding.
- Chat bubbles should have max widths around `72%` to `76%` of screen width.

## Shape And Radius

- App bars and major bottom composer surfaces: `20` to `24`
- Cards and list tiles: `12` to `16`
- Message bubbles: `18`, with one smaller corner around `5` for direction
- Icon buttons: `12` to `14`
- Inputs: `16`
- Avoid overly rounded pill shapes unless the element is clearly a chip, tab, or compact badge.

## Iconography

- Use familiar Material icons already available in Flutter.
- Prefer icons over text for common chat tools:
  - Back: `chevron_left`
  - Attach: `add_rounded`
  - Emoji: `emoji_emotions_outlined`
  - Schedule: `schedule_outlined`
  - Send: `send`
  - Voice: `mic_rounded`
  - Delete: `delete_outline`
  - Group: `group`
- Use text labels only when the action may be unclear, such as `AI`.
- Keep icon color tied to surface contrast. White icons on dark surfaces, brand blue icons on light surfaces.

## App Header Pattern

- Use Dark Primary Blue for chat and important workflow headers.
- Header height should be around `72` to `80`.
- Use white title text and semi-transparent white subtitle text.
- Avatar should have a subtle white ring on dark headers.
- Back button should sit in a soft translucent square with a `12` to `14` radius.
- Keep the right side actions compact so title text has room.

## Home And Sidebar Pattern

- Home should prioritize chat, group, and schedule workflows.
- Use search near the top, but do not let it overpower content.
- Tabs should be easy to scan and clearly show active state with Primary Blue.
- Sidebar should feel like account navigation: profile first, then grouped menu actions.
- Destructive account actions should be visually separated and red.

## Chat Screen Pattern

### Message Area

- Use a light blue or off-white background.
- Keep message spacing consistent: `8` vertical padding per row.
- Incoming messages:
  - White bubble
  - Subtle border and shadow
  - Dark text
  - Timestamp in grey
- Outgoing messages:
  - Primary Blue bubble
  - White text
  - Timestamp in white at reduced opacity
  - Subtle blue shadow
- Media bubbles may use black or dark surfaces when the media requires contrast.
- Group chats should show sender names above incoming content.

### Composer

- Composer surface should feel distinct from the message area.
- Use Deep Ink or white depending on screen mood; if dark, use white input field.
- Attach and mic buttons should be fixed-size square buttons.
- Text input should be rounded, readable, and capped at 3 lines.
- Send and schedule actions should remain inside or next to the input for fast access.
- Reply preview should sit directly above the composer and visually connect to it.

## Lists And Cards

- Chat list items should use:
  - `48` avatar
  - title on first line
  - last message preview on second line
  - timestamp and unread badge on the right
  - optional schedule button at far right
- The middle text column must be `Expanded`.
- Last message previews must use ellipsis.
- Unread badge should use Primary Blue with white text.
- Selected list items may use a light primary background.

## Components

### Buttons

- Primary button: Primary Blue background, white text/icon.
- Secondary button: Light Primary Blue background, Dark Primary Blue text/icon.
- Destructive button: Danger Red background or Danger Red text.
- Disabled button: neutral grey background, muted text.

### Inputs

- Use rounded `16` radius.
- Focus border should use Dark Primary Blue at reduced opacity.
- Placeholder text should be grey and concise.
- Inputs should never shrink so much that hint text or typed text is clipped.

### Bottom Sheets

- Use white surface, drag handle when appropriate, and `20` to `24` top radius.
- List options should use clear icons and short labels.
- Keep destructive options separated or colored red.

### Badges

- Use Primary Blue for unread counters.
- Use soft tints for neutral status.
- Keep badge text short and centered.

## Motion And Feedback

- Use subtle transitions only.
- Loading should use adaptive progress indicators.
- Upload progress should be visible on the attach button or media preview.
- Avoid heavy animations in core chat workflows.
- Typing animation should stay compact and not push content aggressively.

## Accessibility

- Maintain strong contrast on headers, buttons, and message bubbles.
- Tap targets should be at least `40` logical pixels.
- Do not rely on color alone for destructive actions; use icons and labels.
- Message text should remain readable at normal mobile sizes.
- Avoid overlapping UI when keyboard, emoji panel, or reply preview is open.

## Voice And Copy

Tone should be clear, helpful, and calm.

### Preferred

- `Type a message...`
- `Create group`
- `Share contact`
- `Clear chat`
- `You are not in any group`
- `Typing...`

### Avoid

- Long instructions inside core screens
- Technical words in user-facing copy
- All-caps labels except very short features such as `AI`
- Decorative text that explains obvious UI behavior

## Implementation Notes For Flutter

- Keep shared colors in `lib/res/colors.dart`.
- Prefer `GoogleFonts.poppins` for app text until a formal theme is created.
- Use `ScreenUtil` carefully for spacing and icon sizes, but avoid viewport-based text scaling.
- Prefer reusable widgets for:
  - app headers
  - chat bubbles
  - icon buttons
  - list tiles
  - bottom sheet rows
- Before finalizing UI changes, run:
  - `dart format`
  - `flutter analyze`
  - `flutter build apk --debug`

## Do And Do Not

### Do

- Use clear hierarchy.
- Let content breathe without wasting space.
- Keep repeated workflows predictable.
- Use ellipsis for long names and previews.
- Use familiar icons for common actions.

### Do Not

- Use oversized marketing-style hero sections inside the app.
- Use many gradients or decorative blobs.
- Let text overflow horizontally.
- Use red for anything except danger.
- Add cards inside cards.
- Hide primary chat actions behind unclear controls.