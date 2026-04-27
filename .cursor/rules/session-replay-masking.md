---
description: Session replay sensitive data masking — data-session-replay-mask attribute for PII, payment, and tax fields
globs: ["**/*.vue", "**/*.html"]
alwaysApply: false
type: "auto"
---

# Session Replay Sensitive Data Masking

Per ADR 00085. Session replay tools (currently Pendo) record DOM activity. Native masking covers `type="password"` and `type="email"` — it does **not** cover payment information, tax identifiers, or other sensitive fields. You must mark these explicitly.

## The Attribute

```html
data-session-replay-mask
```

Add this attribute to any input, textarea, or container div that displays or accepts sensitive data. The attribute name is vendor-agnostic and will work with any replay tool.

## What Requires Masking

- **Payment information** — card numbers, expiry, CVC, bank account numbers, routing numbers
- **Tax identifiers** — SSN, EIN, VAT numbers, ABN
- **PII not covered by input type** — any field classified as sensitive that isn't `type="password"` or `type="email"`

## Usage

**Single input:**
```vue
<input type="text" name="cardNumber" data-session-replay-mask />
```

**Wrapper (masks the entire area including labels and hints):**
```vue
<div data-session-replay-mask>
  <label for="ssn">Social Security Number</label>
  <input type="text" id="ssn" v-model="ssn" />
  <span class="hint">Format: XXX-XX-XXXX</span>
</div>
```

**Third-party iframes (e.g. Stripe Elements)** — you cannot annotate the iframe's internal inputs, so mask the wrapper:
```vue
<div data-session-replay-mask class="stripe-card-element">
  <div id="card-element"><!-- Stripe injects here --></div>
</div>
```

## Propulsion Components

When using Propulsion form components for sensitive fields, wrap the component:

```vue
<div data-session-replay-mask>
  <p-input :label="t('fields.cardNumber')" v-model="cardNumber" />
</div>
```

Or check whether the Propulsion component passes through arbitrary attributes to its underlying input — if so, add the attribute directly:

```vue
<p-input data-session-replay-mask :label="t('fields.cardNumber')" v-model="cardNumber" />
```

## Review Checklist

- [ ] All card number, expiry, and CVC inputs are masked
- [ ] All bank account and routing number inputs are masked
- [ ] All tax identifier inputs (SSN, EIN, VAT) are masked
- [ ] Third-party payment iframes have their wrapper masked
- [ ] Containers that display sensitive data (not just inputs) are masked
