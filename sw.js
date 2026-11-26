/* Mon budget : service worker (fonctionnement hors connexion).
   - Garde une copie de l'application sur le téléphone pour pouvoir l'ouvrir sans réseau.
   - La page et config.js sont toujours demandés d'abord à Internet (pour recevoir les mises à jour),
     avec la copie en secours si le réseau ne répond pas.
   - Les échanges avec Supabase (vos données) ne passent jamais par ici. */
const CACHE = "mon-budget-v4";
const CORE = [
  "./", "index.html", "config.js", "manifest.webmanifest",
  "vendor/supabase.js", "vendor/fonts/manrope-latin.woff2", "vendor/fonts/manrope-latin-ext.woff2",
  "icons/icon-192.png", "icons/apple-touch-icon.png"
];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => Promise.all(CORE.map(u => c.add(new Request(u, {cache:"reload"})).catch(() => {})))).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k.startsWith("mon-budget-") && k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});

function fromNetwork(req, ms){
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error("lent")), ms);
    fetch(req).then(r => { clearTimeout(t); resolve(r); }, err => { clearTimeout(t); reject(err); });
  });
}

self.addEventListener("fetch", e => {
  const req = e.request, url = new URL(req.url);
  if (req.method !== "GET" || url.origin !== self.location.origin) return;
  const fresh = req.mode === "navigate" || /\/(index\.html|config\.js)?$/.test(url.pathname) || url.pathname.endsWith("/config.js") || url.pathname.endsWith("/sw.js");
  if (fresh){
    // d'abord Internet (4 s maximum), sinon la copie gardée sur le téléphone
    e.respondWith((async () => {
      const cache = await caches.open(CACHE);
      try {
        const r = await fromNetwork(req, 4000);
        if (r && r.ok) cache.put(req.mode === "navigate" ? "index.html" : req, r.clone());
        return r;
      } catch(err){
        return (await cache.match(req, {ignoreSearch:true})) || (await cache.match("index.html")) || Response.error();
      }
    })());
    return;
  }
  // le reste (police, icônes, photos, lecteur de tickets) : la copie si elle existe, sinon Internet puis on la garde
  e.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const hit = await cache.match(req, {ignoreSearch:true});
    if (hit) return hit;
    const r = await fetch(req);
    if (r && r.ok && r.type === "basic") cache.put(req, r.clone());
    return r;
  })());
});
