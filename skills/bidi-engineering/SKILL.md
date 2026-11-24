---
name: bidi-engineering
description: |
  Bidirectional (BiDi) UI engineering and RTL support for Hebrew-English interfaces.
  Use when: (1) Implementing RTL layouts, (2) Fixing mixed Hebrew/English text display,
  (3) Handling numbers/punctuation in RTL contexts, (4) Reviewing BiDi accessibility,
  (5) Converting physical CSS to logical properties, (6) Debugging text direction issues,
  (7) Building forms with mixed LTR/RTL fields, (8) Icon mirroring decisions.
  Triggers: RTL, BiDi, Hebrew UI, right-to-left, text direction, logical properties,
  dir attribute, bdi tag, mixed-direction content.
---

# BiDi Engineering & RTL Support

True RTL support is "BiDi support"—seamless handling of mixed-direction content.

## Unicode Bidirectional Algorithm (UBA) Essentials

| Character Type | Examples | Behavior |
|----------------|----------|----------|
| Strong RTL | Hebrew (א-ת) | Defines RTL flow |
| Strong LTR | Latin (A-Z) | Defines LTR flow |
| Weak | Numbers (0-9) | Follows preceding strong |
| Neutral | `. ! - ? ( )` spaces | Inherits from context |

**Critical:** Neutrals at boundaries cause "spillover"—a period after English in RTL jumps to the wrong side.

## CSS Logical Properties

Always use logical properties:

```css
/* Physical → Logical */
margin-left      → margin-inline-start
margin-right     → margin-inline-end
padding-left     → padding-inline-start
padding-right    → padding-inline-end
left/right       → inset-inline-start/end
text-align: left → text-align: start
border-right     → border-inline-end
```

## HTML Rules

```html
<!-- Root declaration -->
<html dir="rtl" lang="he">

<!-- Isolate dynamic content -->
<bdi>{{ username }}</bdi>
<bdi>{{ title }}</bdi>

<!-- Force LTR for specific data types -->
<input type="email" dir="ltr">
<input type="tel" dir="ltr">
<input type="url" dir="ltr">
```

## Icon Mirroring

**Mirror:** Navigation arrows, progress steppers, text alignment icons, undo/redo
**Do NOT Mirror:** Play/pause, clocks, physical objects (magnifier, scissors), logos

## Typography

- **No `letter-spacing`** on Hebrew (detaches Niqqud)
- **Unitless `line-height: 1.5`** (Hebrew glyphs extend vertically)
- Use `flex-direction: row` (never `row-reverse` for layout—`dir="rtl"` handles flow)

## Testing Strings

1. `בדיקה 123-456 בדיקה` — Numbers should NOT flip to 456-123
2. `בדיקה English.` — Period should stay after "English"
3. `(בדיקה)` vs `(Testing)` — Brackets correct
4. `10 + 20 = 30` — Math stays LTR

## Anti-Patterns

- `text-align: right` instead of `direction: rtl`
- Mixing physical and logical properties
- CSS transforms to flip UI (breaks focus order)
- Missing `dir="ltr"` on email/phone/URL inputs
