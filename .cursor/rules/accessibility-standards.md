---
description: Vue MFE accessibility standards — WCAG 2.1 AA, aria attributes, keyboard navigation, Propulsion component usage
globs: ["**/*.vue"]
alwaysApply: false
type: "auto"
---

# Accessibility Standards

Target: **WCAG 2.1 AA**. Propulsion components handle accessibility internally when used correctly — the gaps arise in custom interactive elements and dynamic content.

## Interactive Elements Without Visible Text

Any button, icon, or control that has no visible label must have an `aria-label`:

```vue
<!-- BAD — icon button with no label -->
<p-button icon="close" @click="dismiss" />

<!-- GOOD -->
<p-button icon="close" :aria-label="t('actions.dismiss')" @click="dismiss" />
```

## Custom Interactive Elements

If you build a custom interactive element that isn't a native `<button>` or `<a>`, add explicit role and keyboard handling:

```vue
<!-- BAD -->
<div @click="select">Option A</div>

<!-- GOOD — or better, use a <button> -->
<div role="button" tabindex="0" @click="select" @keydown.enter="select" @keydown.space.prevent="select">
  Option A
</div>
```

Prefer native elements (`<button>`, `<a>`, `<input>`) over `div` with role — native elements get keyboard behaviour for free.

## Dynamic Content

Screen readers do not automatically announce dynamic state changes. Use `aria-live` for content that updates without a page navigation:

```vue
<div aria-live="polite" aria-atomic="true">
  {{ statusMessage }}
</div>
```

Use `aria-live="assertive"` only for critical errors or interruptions.

## Form Fields

Every input must have an associated label — either visible or via `aria-label`/`aria-labelledby`:

```vue
<!-- GOOD — Propulsion handles association when label prop is used -->
<p-input :label="t('fields.email')" v-model="email" />

<!-- GOOD — explicit association for custom inputs -->
<label :for="inputId">{{ t('fields.email') }}</label>
<input :id="inputId" type="email" v-model="email" />
```

Link validation errors to their field with `aria-describedby`:

```vue
<input :id="inputId" :aria-describedby="errorId" :aria-invalid="!!errorMessage" />
<p :id="errorId" role="alert">{{ errorMessage }}</p>
```

## Images and Icons

- Decorative images: `alt=""` or `aria-hidden="true"`
- Informative images: descriptive `alt` text
- Icon-only controls: `aria-label` on the control (not the icon itself)

## Focus Management

- Modal/drawer open → move focus to the first focusable element inside
- Modal/drawer close → return focus to the element that triggered it
- Propulsion `PModal` and `PDrawer` handle this automatically

## Review Checklist

- [ ] All icon-only buttons have `aria-label`
- [ ] Custom interactive elements have `role` and keyboard handlers
- [ ] Form inputs have associated labels
- [ ] Validation errors linked via `aria-describedby`
- [ ] Dynamic status messages use `aria-live`
- [ ] Focus returns to trigger after modal/drawer close
- [ ] Tab order follows visual reading order
