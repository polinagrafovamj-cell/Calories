// Service worker: кэширует файлы приложения, чтобы оно открывалось без интернета.
// При изменении файлов увеличьте версию, чтобы пользователи получили обновление.
const CACHE = 'calorie-counter-v4';
// Модель распознавания (~14 МБ) не входит в список: она кэшируется при первом использовании.
const APP_SHELL = [
  './',
  'index.html',
  'styles.css',
  'app.js',
  'food-recognition.js',
  'recognized-foods.json',
  'capybara.svg',
  'manifest.webmanifest',
  'icons/icon-192.png',
  'icons/icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(APP_SHELL)));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  // Запросы к Open Food Facts и другим сайтам не кэшируем.
  if (event.request.method !== 'GET' || url.origin !== self.location.origin) return;

  // Сначала сеть (чтобы получать обновления), при её отсутствии — кэш.
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE).then((cache) => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request, { ignoreSearch: true })),
  );
});
