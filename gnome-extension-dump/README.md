# gnome-extension-dump

A one-shot script to capture all GNOME extension settings from a running
desktop, formatted for pasting back into Claude to fill in
`install/extension-prefs.sh`.

---

## Quick start

Copy this directory to the target Bazzite machine, then:

```bash
bash dump-gnome-extension-settings.sh > extension-settings.txt
```

Open `extension-settings.txt` and paste it into a new Claude conversation
with the prompt below.

---

## Claude prompt template

Paste this as your message, with the dump output appended after it:

---

> I'm working on a Fedora Silverblue/Bazzite setup script. Below is a dump of
> all GNOME extension settings from a fully configured desktop. The extensions
> installed are:
>
> - `gsconnect@andyholmes.github.io`
> - `just-perfection-desktop@just-perfection`
> - `caffeine@patapon.info`
> - `space-bar@luchrioh`
> - `Vitals@CoreCoding.com`
> - `rectangle@acristoffers.me`
> - `display-brightness-ddcutil@themightydeity.github.com`
> - `hotedge@jonathan.jdoda.ca`
>
> Please do the following:
>
> 1. **For each extension**, identify every dconf key that is set to a
>    non-default value and explain what it controls.
>
> 2. **Produce a complete `install/extension-prefs.sh`** that uses `dconf write`
>    to apply all meaningful non-default settings. Just Perfection is already
>    configured — preserve those lines and add the rest. Group by extension with
>    comments.
>
> 3. **Update `FEATURES.md`** — fill in the "Extension Configuration (dconf)"
>    table rows for Vitals, Space Bar, Caffeine, Hot Edge, Rectangle, GSConnect,
>    and Display Brightness with human-readable descriptions of what each
>    setting does.
>
> 4. **Flag anything worth discussing** — settings that seem unusual, anything
>    that might not apply to a fresh install, or keys that are better set via
>    `gsettings` than `dconf write`.
>
> Here is the dump:
>
> ```
> [PASTE DUMP OUTPUT HERE]
> ```

---

## What the script captures

| Section | What it collects |
|---|---|
| Installed / enabled / disabled extensions | Quick status check |
| Full dconf dump — `/org/gnome/shell/extensions/` | All keys at once |
| Per-extension dconf dump | Same data split by UUID for easier reading |
| gsettings list-recursively | Schema-aware view with types |
| Hot Edge additional search | Catches non-standard dconf locations |
| Keyboard shortcuts | Custom bindings, mutter, shell keybindings |

---

## Files

| File | Purpose |
|---|---|
| `dump-gnome-extension-settings.sh` | Run on the target Bazzite machine |
| `README.md` | This file — instructions and Claude prompt |

---

## Target files in silverblue-setup

Once Claude produces updated content, apply it here:

| Output | Destination |
|---|---|
| Updated `extension-prefs.sh` | `install/extension-prefs.sh` |
| Updated extension config table | `FEATURES.md` — "Extension Configuration (dconf)" section |

---

## Notes

- Run as your normal desktop user (not root) — dconf is per-user.
- The machine should have all extensions **enabled** and configured the way
  you want them before running the dump.
- If an extension shows `(no dconf keys set — using extension defaults)`, it
  either hasn't been configured yet or stores settings elsewhere (rare).
- GSConnect stores most of its state in `~/.local/share/gnome-shell/extensions/gsconnect/`
  rather than dconf — the dump will capture whatever dconf keys it does use.
