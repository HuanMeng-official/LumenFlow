/* IndexedDB draft storage for the LumenFlow generator. */
(function () {
    const DB_NAME = 'lumenflow_generator';
    const DB_VERSION = 1;
    const DRAFTS = 'drafts';
    const SETTINGS = 'settings';

    let databasePromise = null;

    function openDatabase() {
        if (databasePromise) return databasePromise;
        databasePromise = new Promise((resolve, reject) => {
            if (!window.indexedDB) {
                reject(new Error('IndexedDB is not available'));
                return;
            }
            const request = indexedDB.open(DB_NAME, DB_VERSION);
            request.onupgradeneeded = () => {
                const database = request.result;
                if (!database.objectStoreNames.contains(DRAFTS)) {
                    database.createObjectStore(DRAFTS, { keyPath: 'id' });
                }
                if (!database.objectStoreNames.contains(SETTINGS)) {
                    database.createObjectStore(SETTINGS, { keyPath: 'key' });
                }
            };
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
        return databasePromise;
    }

    async function listDrafts() {
        const database = await openDatabase();
        return new Promise((resolve, reject) => {
            const tx = database.transaction(DRAFTS, 'readonly');
            const request = tx.objectStore(DRAFTS).getAll();
            request.onsuccess = () => {
                const drafts = (request.result || []).sort(
                    (a, b) => (a.createdAt || 0) - (b.createdAt || 0)
                );
                resolve(
                    drafts.map((draft) => ({
                        id: draft.id,
                        name: draft.name || '',
                        createdAt: draft.createdAt || 0,
                        updatedAt: draft.updatedAt || 0,
                    }))
                );
            };
            request.onerror = () => reject(request.error);
        });
    }

    async function getDraft(id) {
        const database = await openDatabase();
        return new Promise((resolve, reject) => {
            const tx = database.transaction(DRAFTS, 'readonly');
            const request = tx.objectStore(DRAFTS).get(id);
            request.onsuccess = () => resolve(request.result || null);
            request.onerror = () => reject(request.error);
        });
    }

    async function putDraft(draft) {
        const database = await openDatabase();
        return new Promise((resolve, reject) => {
            const tx = database.transaction(DRAFTS, 'readwrite');
            tx.objectStore(DRAFTS).put(draft);
            tx.oncomplete = () => resolve();
            tx.onerror = () => reject(tx.error);
            tx.onabort = () => reject(tx.error);
        });
    }

    async function deleteDraft(id) {
        const database = await openDatabase();
        return new Promise((resolve, reject) => {
            const tx = database.transaction(DRAFTS, 'readwrite');
            tx.objectStore(DRAFTS).delete(id);
            tx.oncomplete = () => resolve();
            tx.onerror = () => reject(tx.error);
            tx.onabort = () => reject(tx.error);
        });
    }

    async function getSetting(key) {
        const database = await openDatabase();
        return new Promise((resolve, reject) => {
            const tx = database.transaction(SETTINGS, 'readonly');
            const request = tx.objectStore(SETTINGS).get(key);
            request.onsuccess = () =>
                resolve(request.result ? request.result.value : null);
            request.onerror = () => reject(request.error);
        });
    }

    async function setSetting(key, value) {
        const database = await openDatabase();
        return new Promise((resolve, reject) => {
            const tx = database.transaction(SETTINGS, 'readwrite');
            tx.objectStore(SETTINGS).put({ key, value });
            tx.oncomplete = () => resolve();
            tx.onerror = () => reject(tx.error);
            tx.onabort = () => reject(tx.error);
        });
    }

    window.LFDraftStore = {
        open: openDatabase,
        list: listDrafts,
        get: getDraft,
        put: putDraft,
        remove: deleteDraft,
        getSetting,
        setSetting,
    };
})();
