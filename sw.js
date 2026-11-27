/* Mon budget : service worker (version 5).
   - L'appli s'ouvre tout de suite avec la copie gardée sur le téléphone, même sans réseau.
   - En arrière-plan, la page et config.js sont redemandés à Internet ; si une nouvelle version
     est en ligne, l'appli affiche « Une nouvelle version est prête » (un toucher pour l'installer).
   - Les échanges avec Supabase (vos données) ne passent jamais par ici. */
const CACHE = "mon-budget-v5";
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

const META = () => new URL("__maj", self.registration.scope).href; // « une nouvelle version attend »
async function tellUpdate(){
  const cs = await self.clients.matchAll({type:"window", includeUncontrolled:true});
  cs.forEach(c => c.postMessage({type:"update"}));
}

self.addEventListener("fetch", e => {
  const req = e.request, url = new URL(req.url);
  if (req.method !== "GET" || url.origin !== self.location.origin) return;
  const isPage = req.mode === "navigate" || /\/(index\.html)?$/.test(url.pathname);
  const isCfg = url.pathname.endsWith("/config.js");
  if (isPage || isCfg){
    const key = isPage ? new URL("index.html", self.registration.scope).href : url.origin + url.pathname;
    e.respondWith((async () => {
      const cache = await caches.open(CACHE);
      if (req.mode === "navigate") await cache.delete(META()); // cette ouverture affiche la dernière version gardée
      const hit = await cache.match(key), oldText = hit ? hit.clone().text() : null;
      // en arrière-plan : la version en ligne (sans passer par le cache du navigateur)
      const fresh = fetch(new Request(key, {cache:"no-cache", credentials:"same-origin"})).then(async r => {
        if (!r || !r.ok) return r;
        const txt = await r.clone().text(), old = oldText ? await oldText : null;
        await cache.put(key, r.clone());
        if (old !== null && old !== txt){ await cache.put(META(), new Response("1")); await tellUpdate(); }
        return r;
      });
      if (hit){ e.waitUntil(fresh.catch(() => {})); return hit; }
      try { return await fresh; } catch(err){ return (await cache.match(new URL("index.html", self.registration.scope).href)) || Response.error(); }
    })());
    return;
  }
  // le reste (police, icônes, photos, lecteur de tickets) : la copie si elle existe, sinon Internet puis on la garde
  e.respondWith((async () => {
    const cache = await caches.open(CACHE), hit = await cache.match(req, {ignoreSearch:true});
    if (hit) return hit;
    const r = await fetch(req);
    if (r && r.ok && r.type === "basic") cache.put(req, r.clone());
    return r;
  })());
});

// la page demande, une fois chargée, si une nouvelle version attend
self.addEventListener("message", e => {
  if (!e.data || e.data.type !== "check") return;
  e.waitUntil(caches.open(CACHE).then(c => c.match(META())).then(m => { if (m && e.source) e.source.postMessage({type:"update"}); }));
});
