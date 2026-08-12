// Minimal service worker — just enough to satisfy PWA installability
// checks. No offline caching (the app needs a live Supabase connection
// anyway), so it simply passes every request straight through.
self.addEventListener('install', (e) => { self.skipWaiting(); });
self.addEventListener('activate', (e) => { self.clients.claim(); });
self.addEventListener('fetch', (e) => {
  // Pass-through — no caching, always hit the network.
});
