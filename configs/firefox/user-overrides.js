// user-overrides.js — Personal arkenfox overrides
//
// These are applied on top of the base arkenfox user.js.
// See: https://github.com/arkenfox/user.js/wiki/3.1-Overrides
//
// Syntax: user_pref("preference.name", value);

// Blank new tab page
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "about:blank");

// Keep browsing history (arkenfox clears it; override to retain)
// user_pref("privacy.clearOnShutdown.history", false);
// user_pref("privacy.clearOnShutdown.formdata", false);

// Allow saving passwords (arkenfox disables; re-enable if not using Bitwarden)
// user_pref("signon.rememberSignons", false);

// Restore session on startup
user_pref("browser.startup.page", 3);

// Enable userChrome.css customizations
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Compact density UI
user_pref("browser.uidensity", 1);

// Smooth scrolling
user_pref("general.smoothScroll", true);

// Don't warn when closing multiple tabs
user_pref("browser.tabs.warnOnClose", false);

// Disable Pocket
user_pref("extensions.pocket.enabled", false);
