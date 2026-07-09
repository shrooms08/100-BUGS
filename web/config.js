// Single source of truth for the API base URL.
//
// This is the ONLY place the API endpoint is configured. Both wallet.js
// (browser) and solana_manager.gd (via JavaScriptBridge) read it from
// window.API_CONFIG.BASE_URL.
//
// - Local testing: the game (python http.server) and the API both run on
//   http://localhost, so there is no scheme mismatch. Point BASE_URL at
//   the API's port (default below).
// - Production (itch.io): itch serves the game over HTTPS. Browsers block
//   an HTTPS page from calling an http:// API (mixed content), so BASE_URL
//   MUST be an https:// URL there. A same-origin "" only works if the API
//   is reverse-proxied under the same host as the game, which itch.io does
//   not allow — so a public HTTPS API URL is required for the live build.
window.API_CONFIG = {
  BASE_URL: "http://localhost:3100",
};
