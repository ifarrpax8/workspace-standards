---
description: EditorConfig and editor setup standards — trailing newlines, line endings, indentation
globs: ["**/*"]
alwaysApply: false
type: "auto"
---

# Editor Standards

All repositories include an `.editorconfig` file that is the single source of truth for formatting at the file level. **EditorConfig support must be enabled** in every developer's editor or IDE.

## Universal Settings

These apply to all file types:

| Setting | Value | Why |
|---|---|---|
| `insert_final_newline` | `true` | POSIX standard; prevents "no newline at end of file" diff noise |
| `end_of_line` | `lf` | Consistent across macOS, Linux, and CI — avoid CRLF commits |
| `charset` | `utf-8` | |
| `indent_style` | `space` | |

## Trailing Newlines

**Every file must end with exactly one newline.** This is enforced by `insert_final_newline = true` in `.editorconfig`.

Common sources of trailing newline conflicts:
- Editor without EditorConfig plugin/support — install the plugin and enable it
- Git auto-converting line endings — ensure `git config core.autocrlf false` on macOS/Linux
- Copy-pasting content from tools that strip the newline — your editor will re-add it on save

## Setting Up Your Editor

| Editor | EditorConfig support |
|---|---|
| IntelliJ IDEA / WebStorm | Built-in — enabled by default |
| VS Code | Install [EditorConfig for VS Code](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig) |
| Cursor | Same as VS Code (built-in) |
| Vim/Neovim | `editorconfig-vim` plugin |

## Language-Specific Indentation

Language overrides in `.editorconfig` take precedence over the universal settings:

| File type | Indent size |
|---|---|
| `.kt`, `.java`, `.groovy` | 4 spaces |
| `.ts`, `.js`, `.vue` | 4 spaces |
| `.json`, `.yaml`, `.yml` | 2 or 4 spaces (per repo `.editorconfig`) |
| `.tf`, `.hcl` | 2 spaces |
| `.md` | 2 spaces |

## Static Analysis Enforcement

Kotlin projects use **Spotless** to enforce EditorConfig settings on CI. A Spotless failure is a build failure — fix formatting before pushing:

```bash
./gradlew spotlessApply   # auto-fix
./gradlew check           # verify (includes Spotless + Detekt)
```

Frontend projects use **Prettier** and **ESLint** for equivalent enforcement:

```bash
npm run prettier:w        # auto-fix
npm run check-for-errors  # verify
```
