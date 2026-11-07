---
name: clickable-elements
description: Use for ANY frontend or UI work in any stack (React, Next, Vue, Nuxt, Svelte, Angular, Astro, Solid, plain HTML/CSS, Tailwind or not): building or editing pages, components, buttons, links, nav, cards, menus, or reviewing UI code.
---

# Clickable elements must look and act clickable

Apply these rules silently to every frontend task, even if the user did not mention them. Fix violations in code you touch, and mention any you find elsewhere in one line at the end. First identify the project's stack (package.json, file extensions, config files) and use its idioms from the table below.

## 1. The universal rule

| What happens on click | Must render as | Never |
|---|---|---|
| Goes to another page/route/URL | a real `<a href>` (via the framework's link component) | a click handler that calls the router / sets `location` |
| Does something on this page (submit, toggle, open modal) | a real `<button type="button">` (or `type="submit"` in forms) | `div`/`span`/`li`/`img` with a click handler |
| Looks like a button but navigates | a link styled as a button | a link wrapped around a button, or a button wrapped around a link |

Why: only a real `<a href>` supports middle-click, Cmd/Ctrl+click, open in new tab, copy link, the hover URL preview, prefetching and SEO. Only a real `<button>` gets keyboard focus, Enter/Space and correct screen reader semantics.

Programmatic navigation is fine only as a side effect (after submit, after login, redirects), not as the primary action of a clickable element.

## 2. Stack idioms

| Stack | Link | Avoid as a click action | Button-styled link |
|---|---|---|---|
| React / Next | `<Link href>` | `router.push` in `onClick` | shadcn: `<Button asChild><Link/></Button>` |
| React Router / Remix | `<Link to>` | `navigate()` in `onClick` | style the `<Link>` |
| Vue / Nuxt | `<RouterLink to>` / `<NuxtLink to>` | `router.push` / `navigateTo` in `@click` | style the link, or the UI lib's `to`/`href` prop (e.g. `<UButton to>`) |
| Svelte / SvelteKit | `<a href>` | `goto()` in `onclick` / `on:click` | style the `<a>` |
| Angular | `<a routerLink>` | `router.navigate` in `(click)` | `<a mat-button routerLink>` |
| Astro / plain HTML | `<a href>` | `location.href =` in a handler | style the `<a>` |
| Solid | `<A href>` | `navigate()` in `onClick` | style the `<A>` |

If the UI library's button component has an `href`, `to` or `as`/`asChild` prop, use it so it renders an `<a>`.

## 3. Cursor

Browsers default buttons to the arrow cursor, and Tailwind v4 no longer overrides that. Check the global stylesheet (whatever is loaded on every page: `globals.css`, `app.css`, `main.css`, `styles.scss`, `src/app.css`, the layout's `<style is:global>`, etc.). If no equivalent rule exists, add it once:

```css
button:not(:disabled),
[role="button"]:not([aria-disabled="true"]),
summary,
label[for],
select {
  cursor: pointer;
}
button:disabled,
[aria-disabled="true"] {
  cursor: not-allowed;
}
```

With Tailwind, wrap it in `@layer base { ... }`. Any other custom clickable element (a card, a row, an icon wrapper) that is not a button or link gets `cursor: pointer` (or `cursor-pointer`) explicitly.

## 4. Clickable cards and rows

If a whole card or row navigates, make it a real link: wrap it in the link component, or put a link inside with a stretched pseudo-element (`position: relative` on the card, `a::after { content: ""; position: absolute; inset: 0; }`). Don't attach a click handler + router call to the container.

## 5. Visible feedback

Every interactive element needs a hover state and a visible keyboard focus state (`:focus-visible` outline/ring). Don't remove outlines without a replacement.

## 6. Check before finishing

Before saying a frontend task is done, scan the files you changed (or the whole project if asked to audit). Adjust extensions to the stack:

```bash
EXT='--include=*.tsx --include=*.jsx --include=*.vue --include=*.svelte --include=*.astro --include=*.html'
# non-interactive elements with click handlers (React, Vue, Svelte, Angular syntaxes)
grep -rnE "<(div|span|li|img|tr|td)[^>]*(onClick|@click|v-on:click|on:click|onclick|\(click\))" $EXT . | grep -v node_modules
# navigation inside click handlers
grep -rnE "(onClick|@click|on:click|onclick|\(click\))[^>]*(router\.(push|replace|navigate)|navigate\(|navigateTo|goto\(|location\.href)" $EXT . | grep -v node_modules
# global cursor rule present?
grep -rn "cursor: *pointer" --include=*.css --include=*.scss --include=*.vue --include=*.svelte --include=*.astro . | grep -v node_modules
```

Fix anything these find in code you own for this task.
