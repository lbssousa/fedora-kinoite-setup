// user-overrides.js — Personal arkenfox overrides
//
// Applied on top of the base arkenfox user.js.
// See: https://github.com/arkenfox/user.js/wiki/3.1-Overrides

// Blank new tab page
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.startup.homepage", "about:blank");

// Restore previous session on startup
user_pref("browser.startup.page", 3);

// Disable Pocket
user_pref("extensions.pocket.enabled", false);
