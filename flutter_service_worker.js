'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "a50e6fb7570fde3209596c34c41393f4",
".git/config": "9bc5d3e1b5435907cdb2e6b30736e8c2",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "baac45fbd564c4160aa2f28b55355190",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "56f5cf1f6d612711266d5f1c48d44a30",
".git/logs/refs/heads/main": "1b2056e282e67363f04fb78fb4c98d98",
".git/logs/refs/remotes/origin/gh-pages": "548b5793c70cc43a64cfa43ea995a2b2",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/12/2e72fbe0fc7538bdea09a79e0b9818650fda70": "b8f9bcda49fba6420006b3bb54326b0b",
".git/objects/16/b5d2fa08cd0830c0cf834e2320eef42f2be94c": "a5bc65b8e72ebfd8583f68e7c2916f95",
".git/objects/16/e454f0b586694227a2fb9208fb1cb715db94e6": "bd9d50dc7d21d4b680030d4b80140311",
".git/objects/26/2c1246603747e56aef1efbdd5e6d05ff559a97": "615468f36b7cb12bdf8c0b64d2bd8b52",
".git/objects/2a/6d148478e50c2ae5bb0594c85bebf987bc9530": "1666ed963bfcefd793feace27f451d4a",
".git/objects/32/0cabeb0f6338529633b2cd417b3ba1fe9b7bac": "eadf705873e23fe588bc45afc803ff50",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/40/8202cd190f26af209cd2b650a5c8c759dced68": "b34d4409b19c88ddf1c48c1147bae22f",
".git/objects/46/49918a2a5d7862a0c9e83f632edb5ba0da18b2": "7d024a5dfc990a44b9d743df39302bb4",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/4a/99a0d52240ed8c1b5204b2b9a050fd3ac7167f": "df7f58062fad5a16fc4c19d1bc184368",
".git/objects/4a/a32d95dd92be59dfabf956d21cfdaf708835e9": "3af1113e279a419c1f87820eb9c01d46",
".git/objects/4c/b120f3d6877cc7cc8cf1aed83d82bf3771fa2f": "7421a1ee2d89b1385f5bacf741c680ef",
".git/objects/4f/886a0030d62f02bc040b38a23e8edc2c2ad668": "44a7ce2fd4f71dc0ee9b394356753d36",
".git/objects/50/34817e7f67fe0de10eb10f11a1b5c1d65a811b": "7c6c192fe7074c68546e589f7fb4696a",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/63/d89de6a63dc4b7f7d9396f65c9d6f93a780e56": "156393fc687a272d8e5264b57cb2c8bc",
".git/objects/67/81746184caedaf80280fd3e88a0afb1ff30bfc": "26a88fc96f521f1d5e6d7c4be98361ff",
".git/objects/67/e6eaf807cbd105f79c925ae033c820154256e9": "d1e15285939afb866618fc58d174cace",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/75/3475c37032fc7ec0cdb5a0a9fe833dbb2ce65a": "130ad3551d46e1da4dcd060bd4ecd220",
".git/objects/75/d0f9d50553b0fd37d09a5bf5b7b50cbc51b6e9": "3ba79d10dea7740e82df570d4e73832f",
".git/objects/76/cde146771599125f58f0d16085ddf9d05711b2": "dd502a87abba5004febb6e78420ace36",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/9a/158cfb2e849c4153b57455c5e35be3ca36b46b": "d2d08dc961601cdfc68a2c06d34069fe",
".git/objects/9a/4a47478131724f95b9f748bb97a2c5ccf4ba04": "64a8cea56819f843c32e6f6db41b07dc",
".git/objects/a6/75062e0b5312fbc7f2a48e6cb80c1ca2ef4067": "63d869c2c91a7b2337d03653af2d3ff9",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/ad/d273212d24f1fd0252aa8802e3f1ed8a7f72a6": "b6831ec1104683b4508023d2582984e2",
".git/objects/b2/0c6de56dec552447ef538d2da5fc8c31afb23b": "00e54a98d7cff75a8a19256ee16d71f0",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/c4/d2577d8c037900f0bfa115798b7d080df42581": "6fea158490e680bff09caba14d51b419",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d7/f680b06d546b991eefc40f0f5f5249d7c46c4a": "d2f31d4da34c9e71895455cf907d7cc2",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/dd/3bf87522f0ad488111fe4fc9665e192dbe64fa": "c8588d96a2fd223b4c415a4e61bfef08",
".git/objects/e5/dcc123904992991bab90cd63e1d61b1bfdc3db": "fc12ab03d5fa91b043945443c4d781cf",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/ff/09890368db590ac5f5d0d4ddc569bcef0ef583": "a5f731b18a405aabf67cbe655c85ccbc",
".git/refs/heads/main": "2289074d6012da8645a3cfd2d06b8ff3",
".git/refs/remotes/origin/gh-pages": "2289074d6012da8645a3cfd2d06b8ff3",
"ads.txt": "0d8fc0a7ca47a91149c4163c5d9bbf42",
"app-ads.txt": "0d8fc0a7ca47a91149c4163c5d9bbf42",
"assets/AssetManifest.bin": "63f3459bd7f2a7fc6c54a5cec27504a5",
"assets/AssetManifest.bin.json": "8c9fcb1b20ced6409ca52f7ea84cc958",
"assets/assets/images/1.png": "c11f5d872827913984ce31ab74afc5ed",
"assets/assets/images/logo.png": "14020b660781c66f05d04108a08c3641",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "2621bfd7400f3bb556937db92e0df21a",
"assets/NOTICES": "979e4d6e4071c2c0b2c196969149cd4c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"CNAME": "daa689d02d45063d7140fc882efe016f",
"favicon.ico": "137ec420174551b0fa6c10ba2a849fa3",
"favicon.png": "9f3eb9c9d35aaeec0ba499367c2ba94a",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "f74adda9c1eb96a25174112cd1541352",
"icons/favicon.ico": "137ec420174551b0fa6c10ba2a849fa3",
"icons/Icon-192.png": "b21120f171acff65cbe65457fca4c910",
"icons/Icon-512.png": "ae738b3b6b02b376bd8c96a7cdc3241d",
"icons/Icon-maskable-192.png": "b21120f171acff65cbe65457fca4c910",
"icons/Icon-maskable-512.png": "ae738b3b6b02b376bd8c96a7cdc3241d",
"index.html": "278cddd31c8ee55b44ff620bf677cf07",
"/": "278cddd31c8ee55b44ff620bf677cf07",
"main.dart.js": "acfbeb4a93f3e15b3d40b0304d820db4",
"manifest.json": "7a066b828ecb89129ea76947f66305ca",
"privacidad.html": "366dcb6ae0775df6a6d3e5cdef14e3f1",
"robots.txt": "61ed65d7b1b5f09bbbc8b43f747878dd",
"sitemap.xml": "9552ce9bf6de6e2ee73d80edb4a8c560",
"version.json": "fbe3d2497d47b5a561c116ee08e885a3"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
