/* LumenFlow generator application. */
(function () {
    const UI = window.LF_I18N;
    const STORAGE_KEY = 'lumenflow_generator_v2';
    const LEGACY_STORAGE_KEY = 'lumenflow_autosave_data';
    const MAX_AVATAR_BYTES = 2 * 1024 * 1024;
    const MAX_ILLUSTRATION_BYTES = 8 * 1024 * 1024;
    const CHARACTER_FIELD_IDS = [
        'RoleName', 'RoleNameEN', 'Identity', 'Philosophy', 'Appearance',
        'Personality', 'Addressing', 'Linguistic', 'Behavior', 'Interaction',
        'InternalMonologue', 'EmotionalDepth', 'KnowledgeFilter',
        'NegativeConstraints', 'Example', 'FileName', 'MetaAuthor',
        'MetaVersion', 'MetaLanguage', 'MetaTags', 'MetaIcon',
    ];

    let currentLang = 'zh';
    let saveTimeout = null;
    let hideIndicatorTimeout = null;
    let toastTimeout = null;
    let clearConfirmPending = false;
    let clearConfirmTimeout = null;
    let avatarDataUrl = '';
    let illustrationDataUrl = '';
    let avatarMeta = null;
    let illustrationMeta = null;
    let activeTab = 'character';
    let previewMode = 'source';
    let drafts = [];
    let activeDraftId = '';
    let draftStoreAvailable = true;
    let draftSaveQueue = Promise.resolve();
    let deleteDraftPending = false;
    let deleteDraftTimeout = null;
    let testInputTimeout = null;
    let pendingWorldInfoImportMode = 'replace';

    function dict() {
        return UI[currentLang] || UI.zh;
    }

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function formatBytes(bytes) {
        const value = Number(bytes) || 0;
        if (value < 1024) return `${value} B`;
        if (value < 1024 * 1024) return `${(value / 1024).toFixed(1)} KB`;
        return `${(value / (1024 * 1024)).toFixed(1)} MB`;
    }

    function dataUrlBytes(dataUrl) {
        const base64 = String(dataUrl || '').split(',')[1] || '';
        if (!base64) return 0;
        const padding = base64.endsWith('==') ? 2 : base64.endsWith('=') ? 1 : 0;
        return Math.max(0, Math.floor((base64.length * 3) / 4) - padding);
    }

    const META_ICONS = [
        {
            name: 'person.fill',
            svg: '<circle cx="12" cy="8" r="4" fill="currentColor"/><path d="M4.5 20c.8-4 4.1-6 7.5-6s6.7 2 7.5 6" fill="currentColor"/>',
        },
        {
            name: 'person.crop.circle',
            svg: '<circle cx="12" cy="12" r="8.5" fill="none" stroke="currentColor" stroke-width="1.6"/><circle cx="12" cy="9.5" r="3" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M6.8 18c1-2.8 3-4.2 5.2-4.2s4.2 1.4 5.2 4.2" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>',
        },
        {
            name: 'sparkles',
            svg: '<path d="M12 3l1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5L12 3z" fill="currentColor"/><path d="M18.5 14l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8.8-2.2z" fill="currentColor"/>',
        },
        {
            name: 'wand.and.stars',
            svg: '<path d="M4 20L14 10" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M16 4l.7 2.3L19 7l-2.3.7L16 10l-.7-2.3L13 7l2.3-.7L16 4z" fill="currentColor"/><path d="M7 3l.5 1.7L9 5.5l-1.5.5L7 7.7l-.5-1.7L5 5.5l1.5-.5L7 3z" fill="currentColor"/>',
        },
        {
            name: 'heart.fill',
            svg: '<path d="M12 20s-7-4.3-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.7-7 10-7 10z" fill="currentColor"/>',
        },
        {
            name: 'flame.fill',
            svg: '<path d="M13 2c.8 3.2-3.7 5-3.7 9.2A3.7 3.7 0 0013 15c1.6 0 2.7-1.1 2.7-2.6 0-1.3-.6-2.2-1.3-3.3 2.8 1.6 4.6 4.2 4.6 7 0 3.2-2.8 5.9-7 5.9s-7-2.5-7-6.2C5 10.2 9.8 7.2 13 2z" fill="currentColor"/>',
        },
        {
            name: 'moon.stars',
            svg: '<path d="M20 14.5A8.5 8.5 0 1110 4a7 7 0 0010 10.5z" fill="currentColor"/><path d="M17.5 3l.6 1.9 1.9.6-1.9.6-.6 1.9-.6-1.9-1.9-.6 1.9-.6.6-1.9z" fill="currentColor"/>',
        },
        {
            name: 'sun.max',
            svg: '<circle cx="12" cy="12" r="4" fill="currentColor"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        },
        {
            name: 'star.fill',
            svg: '<path d="M12 3l2.7 5.5 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1-4.4-4.3 6.1-.9L12 3z" fill="currentColor"/>',
        },
        {
            name: 'bolt.fill',
            svg: '<path d="M13 2L4 14h6l-1 8 9-12h-6l1-8z" fill="currentColor"/>',
        },
        {
            name: 'globe',
            svg: '<circle cx="12" cy="12" r="8.5" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M3.5 12h17M12 3.5c2.2 2.4 3.3 5.3 3.3 8.5s-1.1 6.1-3.3 8.5M12 3.5c-2.2 2.4-3.3 5.3-3.3 8.5s1.1 6.1 3.3 8.5" fill="none" stroke="currentColor" stroke-width="1.4"/>',
        },
        {
            name: 'pencil',
            svg: '<path d="M4.2 19.8l3.7-.8L19.2 7.7a2.1 2.1 0 000-3l-.9-.9a2.1 2.1 0 00-3 0L4 15.9l-.8 3.7 1 1z" fill="currentColor"/>',
        },
    ];

    function showToast(message) {
        const toastEl = document.getElementById('toast');
        toastEl.innerText = message;
        toastEl.classList.add('show');
        clearTimeout(toastTimeout);
        toastTimeout = setTimeout(() => toastEl.classList.remove('show'), 2500);
    }
    window.LFShowToast = showToast;

    function autoResizeTextarea(el) {
        if (!el || el.tagName !== 'TEXTAREA') return;
        el.style.height = 'auto';
        const minH = el.classList.contains('compact') ? 52 : 120;
        el.style.height = Math.max(el.scrollHeight, minH) + 'px';
    }

    function autoResizeAllTextareas() {
        document.querySelectorAll('textarea').forEach(autoResizeTextarea);
    }

    function unindent(text) {
        if (!text) return '';
        const lines = text.split('\n');
        const indents = lines
            .filter((line) => line.trim() !== '')
            .map((line) => line.match(/^[ \t]*/)[0].length);
        const margin = indents.length ? Math.min(...indents) : 0;
        return lines
            .map((line) => (line.trim() === '' ? '' : line.substring(margin)))
            .join('\n')
            .trim();
    }

    function escapeBareAmpersands(text) {
        return String(text || '').replace(
            /&(?!(?:#\d+|#x[0-9a-fA-F]+|[A-Za-z_][\w.:-]*);)/g,
            '&amp;'
        );
    }

    function formatFieldContent(rawText) {
        if (!rawText) return '';
        const text = String(rawText).replace(/\r\n/g, '\n');
        const withAmp = escapeBareAmpersands(text);
        const parser = new DOMParser();
        const testDoc = parser.parseFromString(`<root>${withAmp}</root>`, 'text/xml');
        if (testDoc.getElementsByTagName('parsererror').length === 0) {
            return withAmp;
        }
        return withAmp.replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    function readInnerMarkup(node) {
        return Array.from(node.childNodes)
            .map((child) => {
                if (child.nodeType === Node.ELEMENT_NODE) {
                    return new XMLSerializer().serializeToString(child);
                }
                if (
                    child.nodeType === Node.TEXT_NODE ||
                    child.nodeType === Node.CDATA_SECTION_NODE
                ) {
                    return child.nodeValue;
                }
                return '';
            })
            .join('');
    }

    function syncMetaName() {
        const roleName = document.getElementById('RoleName').value.trim();
        document.getElementById('MetaName').value = roleName;
    }

    function splitTags(value) {
        return String(value || '')
            .split(/[,，]/)
            .map((item) => item.trim())
            .filter((item) => item.length > 0);
    }

    function renderTagChips() {
        const hidden = document.getElementById('MetaTags');
        const container = document.getElementById('MetaTagsChips');
        if (!hidden || !container) return;
        const d = dict();
        const tags = splitTags(hidden.value);
        container.innerHTML = tags
            .map(
                (tag, index) => `
                <span class="tag-chip">${escapeHtml(tag)}
                    <button type="button" data-remove-tag="${index}"
                        aria-label="${escapeHtml(d.RemoveTag)}">×</button>
                </span>`
            )
            .join('');
    }

    function addMetaTag(rawValue) {
        const hidden = document.getElementById('MetaTags');
        const input = document.getElementById('MetaTagInput');
        if (!hidden || !input) return;
        const value = String(rawValue || '').trim();
        if (!value) return;
        const tags = splitTags(hidden.value);
        if (!tags.includes(value)) {
            tags.push(value);
            hidden.value = tags.join(', ');
        }
        input.value = '';
        renderTagChips();
        updatePreview();
        triggerAutoSave();
    }

    function removeMetaTag(index) {
        const hidden = document.getElementById('MetaTags');
        if (!hidden) return;
        const tags = splitTags(hidden.value);
        if (index < 0 || index >= tags.length) return;
        tags.splice(index, 1);
        hidden.value = tags.join(', ');
        renderTagChips();
        updatePreview();
        triggerAutoSave();
    }

    function renderIconGrid() {
        const hidden = document.getElementById('MetaIcon');
        const grid = document.getElementById('MetaIconGrid');
        const label = document.getElementById('MetaIconValue');
        if (!hidden || !grid) return;
        const d = dict();
        const current = hidden.value || 'person.fill';
        grid.innerHTML = META_ICONS.map(
            (icon) => `
            <button type="button" class="icon-choice${
                icon.name === current ? ' is-active' : ''
            }" data-icon="${icon.name}" role="radio"
                aria-checked="${icon.name === current}"
                title="${escapeHtml(`${d.MetaIcon} ${icon.name}`)}">
                <svg viewBox="0 0 24 24" aria-hidden="true">${icon.svg}</svg>
            </button>`
        ).join('');
        if (label) label.textContent = current;
    }

    function switchTab(name) {
        activeTab = name;
        document.querySelectorAll('.tab-button').forEach((button) => {
            button.classList.toggle('active', button.dataset.tab === name);
        });
        document.querySelectorAll('.tab-panel').forEach((panel) => {
            panel.classList.toggle('active', panel.dataset.panel === name);
        });
        document.getElementById('preview-section').classList.add('active');
        if (name === 'export') {
            updateTokenCount();
        } else {
            updatePreview();
        }
        triggerAutoSave();
    }

    function collectCharacterFields() {
        const data = {};
        CHARACTER_FIELD_IDS.forEach((field) => {
            const el = document.getElementById(field);
            if (el) data[field] = el.value;
        });
        return data;
    }

    function loadFromLocalStorage() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY) ||
                localStorage.getItem(LEGACY_STORAGE_KEY);
            if (!raw) return;
            const data = JSON.parse(raw);
            if (data.lang && UI[data.lang]) {
                currentLang = data.lang;
                document.getElementById('lang-selector').value = data.lang;
            }
            Object.keys(data).forEach((key) => {
                const el = document.getElementById(key);
                if (el && typeof data[key] === 'string') el.value = data[key];
            });
            if (typeof data.Worldview === 'string' && data.Worldview.trim()) {
                window.LFWorldInfo.importLegacyBackground(data.Worldview);
            }
            if (data.worldInfo) {
                window.LFWorldInfo.setData(data.worldInfo);
            }
            if (typeof data.avatarDataUrl === 'string' &&
                data.avatarDataUrl.startsWith('data:image/png')) {
                avatarDataUrl = data.avatarDataUrl;
            }
            if (typeof data.illustrationDataUrl === 'string' &&
                data.illustrationDataUrl.startsWith('data:image/png')) {
                illustrationDataUrl = data.illustrationDataUrl;
            }
            if (['character', 'worldinfo', 'meta', 'export'].includes(data.tab)) {
                activeTab = data.tab;
            }
            if (data.InternalMonologue || data.EmotionalDepth ||
                data.KnowledgeFilter || data.NegativeConstraints) {
                document.getElementById('AdvancedOptionsPanel').open = true;
            }
            syncMetaName();
            renderTagChips();
            renderIconGrid();
            renderAvatar();
            renderIllustration();
            renderMediaMeta();
            ensureImageMeta('avatar');
            ensureImageMeta('illustration');
        } catch (error) {
            console.error('Failed to load local storage data:', error);
        }
    }

    function showSavedIndicator() {
        const indicator = document.getElementById('save-indicator');
        if (!indicator) return;
        indicator.classList.add('show');
        clearTimeout(hideIndicatorTimeout);
        hideIndicatorTimeout = setTimeout(
            () => indicator.classList.remove('show'),
            2000
        );
    }

    function saveToLocalStorage() {
        const data = Object.assign(
            { lang: currentLang, tab: activeTab },
            collectCharacterFields(),
            { worldInfo: window.LFWorldInfo.getData() }
        );
        if (avatarDataUrl && avatarDataUrl.length < 800000) {
            data.avatarDataUrl = avatarDataUrl;
        }
        // 立绘通常较大，超过 localStorage 安全阈值时不自动保存，避免写满配额。
        if (illustrationDataUrl && illustrationDataUrl.length < 1500000) {
            data.illustrationDataUrl = illustrationDataUrl;
        }
        localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
        showSavedIndicator();
    }

    function draftNameFromData(data) {
        const fields = (data && data.fields) || {};
        return String(fields.RoleName || '').trim();
    }

    function blankDraftData() {
        return {
            lang: currentLang || 'zh',
            tab: 'character',
            previewMode: 'source',
            advancedOpen: false,
            fields: {},
            worldInfo: null,
            avatarDataUrl: '',
            illustrationDataUrl: '',
            avatarMeta: null,
            illustrationMeta: null,
        };
    }

    function collectDraftData() {
        return {
            lang: currentLang,
            tab: activeTab,
            previewMode,
            advancedOpen: !!document.getElementById('AdvancedOptionsPanel')?.open,
            fields: collectCharacterFields(),
            worldInfo: window.LFWorldInfo.getData(),
            avatarDataUrl,
            illustrationDataUrl,
            avatarMeta,
            illustrationMeta,
        };
    }

    function readLegacyDraftData() {
        try {
            const raw =
                localStorage.getItem(STORAGE_KEY) ||
                localStorage.getItem(LEGACY_STORAGE_KEY);
            if (!raw) return null;
            const legacy = JSON.parse(raw);
            const fields = {};
            CHARACTER_FIELD_IDS.forEach((id) => {
                if (typeof legacy[id] === 'string') fields[id] = legacy[id];
            });
            let worldInfo = legacy.worldInfo || null;
            if (
                !worldInfo &&
                typeof legacy.Worldview === 'string' &&
                legacy.Worldview.trim()
            ) {
                worldInfo = {
                    _format: 'lumenflow_world_info',
                    _version: 1,
                    name: '',
                    description: '',
                    background: legacy.Worldview.trim(),
                    scan_depth: 4,
                    budget_tokens: 1000,
                    min_activations: 0,
                    recursion_depth: 0,
                    entries: [],
                };
            }
            return {
                lang: UI[legacy.lang] ? legacy.lang : 'zh',
                tab: ['character', 'worldinfo', 'meta', 'export'].includes(
                    legacy.tab
                )
                    ? legacy.tab
                    : 'character',
                previewMode: 'source',
                advancedOpen:
                    ['InternalMonologue', 'EmotionalDepth', 'KnowledgeFilter',
                        'NegativeConstraints'].some((id) =>
                        String(fields[id] || '').trim()
                    ),
                fields,
                worldInfo,
                avatarDataUrl:
                    typeof legacy.avatarDataUrl === 'string'
                        ? legacy.avatarDataUrl
                        : '',
                illustrationDataUrl:
                    typeof legacy.illustrationDataUrl === 'string'
                        ? legacy.illustrationDataUrl
                        : '',
                avatarMeta: null,
                illustrationMeta: null,
            };
        } catch (error) {
            console.error('Failed to migrate legacy generator draft:', error);
            return null;
        }
    }

    function applyDraftData(data) {
        const draft = data && typeof data === 'object' ? data : {};
        if (draft.lang && UI[draft.lang]) currentLang = draft.lang;
        window.LF_CURRENT_LANG = currentLang;
        document.getElementById('lang-selector').value = currentLang;

        const fields =
            draft.fields && typeof draft.fields === 'object'
                ? draft.fields
                : {};
        const defaults = {
            MetaVersion: 'v1.0',
            MetaIcon: 'person.fill',
        };
        CHARACTER_FIELD_IDS.forEach((id) => {
            const element = document.getElementById(id);
            if (!element) return;
            element.value =
                typeof fields[id] === 'string'
                    ? fields[id]
                    : defaults[id] || '';
        });

        window.LFWorldInfo.setData(draft.worldInfo || {});
        avatarDataUrl =
            typeof draft.avatarDataUrl === 'string' &&
            draft.avatarDataUrl.startsWith('data:image/png')
                ? draft.avatarDataUrl
                : '';
        illustrationDataUrl =
            typeof draft.illustrationDataUrl === 'string' &&
            draft.illustrationDataUrl.startsWith('data:image/png')
                ? draft.illustrationDataUrl
                : '';
        avatarMeta = draft.avatarMeta || null;
        illustrationMeta = draft.illustrationMeta || null;

        activeTab = ['character', 'worldinfo', 'meta', 'export'].includes(
            draft.tab
        )
            ? draft.tab
            : 'character';
        previewMode = ['source', 'card', 'test'].includes(draft.previewMode)
            ? draft.previewMode
            : 'source';
        document.getElementById('AdvancedOptionsPanel').open =
            !!draft.advancedOpen ||
            ['InternalMonologue', 'EmotionalDepth', 'KnowledgeFilter',
                'NegativeConstraints'].some((id) =>
                String(fields[id] || '').trim()
            );

        const tagInput = document.getElementById('MetaTagInput');
        if (tagInput) tagInput.value = '';
        syncMetaName();
        renderTagChips();
        renderIconGrid();
        renderAvatar();
        renderIllustration();
        renderMediaMeta();
        ensureImageMeta('avatar');
        ensureImageMeta('illustration');
    }

    async function refreshAfterDraftLoad() {
        applyLanguageUI();
        switchTab(activeTab);
        autoResizeAllTextareas();
        updateTokenCount();
        updateWorldInfoValidation();
        syncMetaName();
    }

    function createDraftId() {
        return `draft-${Date.now().toString(36)}-${Math.random()
            .toString(36)
            .slice(2, 8)}`;
    }

    async function initializeDrafts() {
        try {
            if (!window.LFDraftStore) throw new Error('Draft store missing');
            await window.LFDraftStore.open();
            drafts = await window.LFDraftStore.list();
            let data;
            if (drafts.length === 0) {
                data = readLegacyDraftData() || blankDraftData();
                const now = Date.now();
                const draft = {
                    id: createDraftId(),
                    name: draftNameFromData(data),
                    createdAt: now,
                    updatedAt: now,
                    data,
                };
                await window.LFDraftStore.put(draft);
                activeDraftId = draft.id;
                await window.LFDraftStore.setSetting(
                    'activeDraftId',
                    activeDraftId
                );
                drafts = await window.LFDraftStore.list();
            } else {
                let storedId = await window.LFDraftStore.getSetting(
                    'activeDraftId'
                );
                if (!drafts.some((draft) => draft.id === storedId)) {
                    storedId = drafts[0].id;
                }
                activeDraftId = storedId;
                const active = await window.LFDraftStore.get(activeDraftId);
                data = active?.data || blankDraftData();
                await window.LFDraftStore.setSetting(
                    'activeDraftId',
                    activeDraftId
                );
            }
            return data;
        } catch (error) {
            console.error('Draft storage unavailable:', error);
            draftStoreAvailable = false;
            const bar = document.getElementById('DraftBar');
            if (bar) bar.hidden = true;
            return null;
        }
    }

    function renderDraftTimestamp() {
        const element = document.getElementById('DraftUpdated');
        if (!element) return;
        const d = dict();
        const draft = drafts.find((item) => item.id === activeDraftId);
        if (!draft || !draft.updatedAt) {
            element.textContent = '';
            return;
        }
        const locale = currentLang === 'zh' ? 'zh-CN' : currentLang;
        const time = new Intl.DateTimeFormat(locale, {
            month: 'numeric',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
        }).format(new Date(draft.updatedAt));
        element.textContent = d.DraftLastEdited.replace('{time}', time);
    }

    function renderDraftPicker() {
        const select = document.getElementById('DraftSelect');
        if (!select) return;
        const d = dict();
        select.innerHTML = drafts
            .map(
                (draft) =>
                    `<option value="${escapeHtml(draft.id)}">${escapeHtml(
                        draft.name || d.UntitledDraft
                    )}</option>`
            )
            .join('');
        if (drafts.some((draft) => draft.id === activeDraftId)) {
            select.value = activeDraftId;
        }
        select.setAttribute('aria-label', d.Draft);
        const wrapper = select.closest('.lf-select');
        if (wrapper && typeof wrapper._lfRefresh === 'function') {
            wrapper._lfRefresh();
        }
        renderDraftTimestamp();
    }

    function queueDraftSave() {
        if (!draftStoreAvailable) {
            saveToLocalStorage();
            return Promise.resolve();
        }
        if (!activeDraftId) return Promise.resolve();
        const draftId = activeDraftId;
        const data = collectDraftData();
        const name = draftNameFromData(data);
        const task = draftSaveQueue.then(async () => {
            const existing = drafts.find((draft) => draft.id === draftId);
            const now = Date.now();
            const draft = {
                id: draftId,
                name,
                createdAt: existing?.createdAt || now,
                updatedAt: now,
                data,
            };
            await window.LFDraftStore.put(draft);
            const index = drafts.findIndex((item) => item.id === draftId);
            const metadata = {
                id: draftId,
                name,
                createdAt: draft.createdAt,
                updatedAt: now,
            };
            const nameChanged = !existing || existing.name !== name;
            if (index >= 0) drafts[index] = metadata;
            else drafts.push(metadata);
            showSavedIndicator();
            renderDraftTimestamp();
            if (nameChanged) renderDraftPicker();
        });
        draftSaveQueue = task.catch((error) => {
            console.error('Failed to save draft:', error);
            showToast(dict().DraftSaveFailed || 'Draft save failed');
        });
        return draftSaveQueue;
    }

    async function flushDraftSave() {
        clearTimeout(saveTimeout);
        saveTimeout = null;
        await queueDraftSave();
        await draftSaveQueue;
    }

    async function switchDraft(id) {
        if (!draftStoreAvailable || !id || id === activeDraftId) return;
        await flushDraftSave();
        activeDraftId = id;
        await window.LFDraftStore.setSetting('activeDraftId', id);
        const draft = await window.LFDraftStore.get(id);
        applyDraftData(draft?.data || blankDraftData());
        await refreshAfterDraftLoad();
    }

    async function createNewDraft() {
        if (!draftStoreAvailable) return;
        await flushDraftSave();
        const now = Date.now();
        const draft = {
            id: createDraftId(),
            name: '',
            createdAt: now,
            updatedAt: now,
            data: blankDraftData(),
        };
        await window.LFDraftStore.put(draft);
        activeDraftId = draft.id;
        await window.LFDraftStore.setSetting('activeDraftId', activeDraftId);
        drafts = await window.LFDraftStore.list();
        applyDraftData(draft.data);
        await refreshAfterDraftLoad();
        showToast(dict().DraftCreated);
    }

    async function duplicateCurrentDraft() {
        if (!draftStoreAvailable) return;
        await flushDraftSave();
        const current = await window.LFDraftStore.get(activeDraftId);
        const data = JSON.parse(
            JSON.stringify(current?.data || collectDraftData())
        );
        const now = Date.now();
        const suffix = dict().CopySuffix || '(copy)';
        const draft = {
            id: createDraftId(),
            name: current?.name ? `${current.name} ${suffix}` : '',
            createdAt: now,
            updatedAt: now,
            data,
        };
        await window.LFDraftStore.put(draft);
        activeDraftId = draft.id;
        await window.LFDraftStore.setSetting('activeDraftId', activeDraftId);
        drafts = await window.LFDraftStore.list();
        applyDraftData(draft.data);
        await refreshAfterDraftLoad();
        showToast(dict().DraftDuplicated);
    }

    async function deleteCurrentDraft() {
        if (!draftStoreAvailable || !activeDraftId) return;
        const button = document.getElementById('btn-DeleteDraft');
        if (!deleteDraftPending) {
            deleteDraftPending = true;
            if (button) button.classList.add('pending');
            showToast(dict().ConfirmDeleteDraft);
            clearTimeout(deleteDraftTimeout);
            deleteDraftTimeout = setTimeout(() => {
                deleteDraftPending = false;
                if (button) button.classList.remove('pending');
            }, 2000);
            return;
        }
        clearTimeout(deleteDraftTimeout);
        deleteDraftPending = false;
        if (button) button.classList.remove('pending');
        clearTimeout(saveTimeout);
        saveTimeout = null;
        await draftSaveQueue;
        await window.LFDraftStore.remove(activeDraftId);
        drafts = await window.LFDraftStore.list();
        if (drafts.length === 0) {
            const now = Date.now();
            const draft = {
                id: createDraftId(),
                name: '',
                createdAt: now,
                updatedAt: now,
                data: blankDraftData(),
            };
            await window.LFDraftStore.put(draft);
            activeDraftId = draft.id;
            drafts = await window.LFDraftStore.list();
            applyDraftData(draft.data);
        } else {
            activeDraftId = drafts[0].id;
            const draft = await window.LFDraftStore.get(activeDraftId);
            applyDraftData(draft?.data || blankDraftData());
        }
        await window.LFDraftStore.setSetting('activeDraftId', activeDraftId);
        await refreshAfterDraftLoad();
    }

    function triggerAutoSave() {
        clearTimeout(saveTimeout);
        saveTimeout = setTimeout(() => {
            queueDraftSave();
        }, 1000);
    }

    function clearForm() {
        const btnClear = document.getElementById('btn-Clear');
        if (!clearConfirmPending) {
            clearConfirmPending = true;
            btnClear.classList.add('pending');
            showToast(dict().ConfirmClear);
            clearConfirmTimeout = setTimeout(() => {
                clearConfirmPending = false;
                btnClear.classList.remove('pending');
            }, 2000);
            return;
        }

        clearTimeout(clearConfirmTimeout);
        clearConfirmPending = false;
        btnClear.classList.remove('pending');

        document
            .querySelectorAll('#panel-character input[type="text"], #panel-character textarea')
            .forEach((el) => {
                el.value = '';
                el.style.height = '';
            });
        document.getElementById('MetaAuthor').value = '';
        document.getElementById('MetaVersion').value = 'v1.0';
        document.getElementById('MetaLanguage').value = '';
        document.getElementById('MetaTags').value = '';
        document.getElementById('MetaIcon').value = 'person.fill';
        const clearTagInput = document.getElementById('MetaTagInput');
        if (clearTagInput) clearTagInput.value = '';
        renderTagChips();
        renderIconGrid();
        document.getElementById('FileName').value = '';
        document.getElementById('AdvancedOptionsPanel').open = false;
        window.LFWorldInfo.reset();
        clearAvatar(false);
        clearIllustration(false);
        syncMetaName();
        updateTokenCount();
        queueDraftSave();
        showToast(dict().Cleared);
    }

    function estimateTokens(text) {
        if (!text) return 0;
        const cjkRegex = /[一-龥぀-ヿ가-힯]/g;
        const cjkMatch = text.match(cjkRegex);
        const cjkCount = cjkMatch ? cjkMatch.length : 0;
        const nonCjkText = text.replace(cjkRegex, '');
        const nonCjkCount = Math.ceil(nonCjkText.length / 3.8);
        return Math.ceil(cjkCount * 0.75) + nonCjkCount;
    }

    function formatIndentedBlock(text, indentSpaces = 6) {
        if (!text) return '';
        const indent = ' '.repeat(indentSpaces);
        return text
            .split('\n')
            .map((line) => (line.trim() === '' ? '' : indent + line))
            .join('\n');
    }

    function buildXMLString() {
        const read = (id) => {
            const el = document.getElementById(id);
            return el ? formatFieldContent(el.value) : '';
        };
        const roleName = read('RoleName') || 'Unknown';
        const roleNameEN = read('RoleNameEN');
        const identity = read('Identity');
        const philosophy = read('Philosophy');
        const appearance = formatIndentedBlock(read('Appearance'));
        const personality = formatIndentedBlock(read('Personality'));
        const addressing = formatIndentedBlock(read('Addressing'));
        const linguistic = formatIndentedBlock(read('Linguistic'));
        const behavior = formatIndentedBlock(read('Behavior'));
        const interaction = formatIndentedBlock(read('Interaction'));
        const internalMonologueRaw = read('InternalMonologue');
        const emotionalDepthRaw = read('EmotionalDepth');
        const knowledgeFilterRaw = read('KnowledgeFilter');
        const negativeConstraintsRaw = read('NegativeConstraints');

        let advancedXML = '';
        if (internalMonologueRaw.trim() !== '') {
            advancedXML += `\n   <internal_monologue>\n${formatIndentedBlock(internalMonologueRaw)}\n   </internal_monologue>\n`;
        }
        if (emotionalDepthRaw.trim() !== '') {
            advancedXML += `\n   <emotional_depth>\n${formatIndentedBlock(emotionalDepthRaw)}\n   </emotional_depth>\n`;
        }
        if (knowledgeFilterRaw.trim() !== '') {
            advancedXML += `\n   <knowledge_filter>\n${formatIndentedBlock(knowledgeFilterRaw)}\n   </knowledge_filter>\n`;
        }
        if (negativeConstraintsRaw.trim() !== '') {
            advancedXML += `\n   <negative_constraints>\n${formatIndentedBlock(negativeConstraintsRaw)}\n   </negative_constraints>\n`;
        }

        const example = formatIndentedBlock(read('Example'));
        const metaField = (tag, value) => {
            const text = value.trim();
            if (text === '') return `      <${tag}></${tag}>`;
            if (!text.includes('\n')) return `      <${tag}>${text}</${tag}>`;
            return `      <${tag}>\n${formatIndentedBlock(text, 9)}\n      </${tag}>`;
        };

        return `<system_instruction>
   <meta>
${metaField('role_name', roleName + (roleNameEN ? '（' + roleNameEN + '）' : ''))}
${metaField('identity', identity)}
${metaField('core_philosophy', philosophy)}
   </meta>

   <appearance_traits>
${appearance}
   </appearance_traits>

   <personality_logic>
${personality}
   </personality_logic>

   <addressing_protocol>
${addressing}
   </addressing_protocol>

   <linguistic_style>
${linguistic}
   </linguistic_style>

   <behavior_narrative_rules>
${behavior}
   </behavior_narrative_rules>

   <interaction_strategy>
${interaction}
   </interaction_strategy>
${advancedXML}

   <example_dialogue>
${example}
   </example_dialogue>
</system_instruction>`;
    }

    function buildPreviewState() {
        const d = dict();
        let text;
        let context;
        if (activeTab === 'worldinfo' && window.LFWorldInfo) {
            const selected = window.LFWorldInfo.getSelectedEntry();
            const data = selected || window.LFWorldInfo.getData();
            text = JSON.stringify(data, null, 2);
            context =
                selected && selected.title
                    ? `${d.TabWorldInfo} · ${selected.title}`
                    : d.TabWorldInfo;
        } else if (activeTab === 'meta') {
            text = JSON.stringify(buildMetaPayload(), null, 2);
            context = d.TabMeta;
        } else if (activeTab === 'export') {
            text = buildXMLString();
            context = d.TabExport;
        } else {
            text = buildXMLString();
            context = d.TabCharacter;
        }
        if (previewMode === 'card') context = d.PreviewCard;
        else if (previewMode === 'test') context = d.PreviewTest;
        return { text, context };
    }

    function buildPreviewText() {
        return buildPreviewState().text;
    }

    function positionLabel(position) {
        const d = dict();
        return {
            system: d.PositionSystem,
            before_preset: d.PositionBeforePreset,
            after_preset: d.PositionAfterPreset,
            at_depth: d.PositionAtDepth,
        }[position] || position;
    }

    function worldCategoryLabel(value) {
        const d = dict();
        return {
            character: d.CategoryCharacter,
            location: d.CategoryLocation,
            item: d.CategoryItem,
            rule: d.CategoryRule,
            event: d.CategoryEvent,
            lore: d.CategoryLore,
            other: d.CategoryOther,
        }[value] || value;
    }

    function skipReasonLabel(reason) {
        const d = dict();
        return {
            disabled: d.SkipDisabled,
            noPrimaryKey: d.SkipNoPrimaryKey,
            missingSecondaryKey: d.SkipMissingSecondaryKey,
            cooldown: d.SkipCooldown,
            probability: d.SkipProbability,
            group: d.SkipGroup,
            budget: d.SkipBudget,
        }[reason] || reason;
    }

    function renderCardPreview(container) {
        const d = dict();
        const value = (id) => document.getElementById(id)?.value || '';
        const meta = buildMetaPayload();
        const worldInfo = window.LFWorldInfo
            ? window.LFWorldInfo.getData()
            : { background: '', entries: [] };
        const stats = window.LFWorldInfo
            ? window.LFWorldInfo.getStats()
            : {
                  entries: 0,
                  backgroundTokens: 0,
                  entryTokens: 0,
                  totalTokens: 0,
              };
        const name = value('RoleName').trim() || meta.name;
        const nameEn = value('RoleNameEN').trim();
        const tags = meta.tags || [];
        const languageSelect = document.getElementById('MetaLanguage');
        const languageCode = languageSelect?.value || '';
        const languageLabel = languageCode
            ? languageSelect?.selectedOptions?.[0]?.textContent?.trim() || ''
            : '';
        const metaParts = [meta.author, meta.version, languageLabel].filter(
            (part) => part && part.trim()
        );
        const identity = value('Identity').trim();
        const philosophy = value('Philosophy').trim();
        const appearance = value('Appearance').trim();
        const personality = value('Personality').trim();
        const example = value('Example').trim();
        const background = String(worldInfo.background || '').trim();
        const hasContent =
            name !== 'Character' ||
            nameEn ||
            tags.length > 0 ||
            metaParts.length > 0 ||
            identity ||
            philosophy ||
            appearance ||
            personality ||
            example ||
            background ||
            stats.entries > 0 ||
            avatarDataUrl ||
            illustrationDataUrl;
        if (!hasContent) {
            container.innerHTML = `<div class="card-empty">${escapeHtml(
                d.CardPreviewEmpty
            )}</div>`;
            return;
        }

        const initial = (name.trim().charAt(0) || '?').toUpperCase();
        const avatar = avatarDataUrl
            ? `<img src="${avatarDataUrl}" alt="">`
            : `<span class="card-avatar-placeholder">${escapeHtml(initial)}</span>`;
        const illustration = illustrationDataUrl
            ? `<img src="${illustrationDataUrl}" alt="">`
            : `<span class="card-illustration-placeholder">PNG</span>`;
        const sections = [
            [d.Identity, identity],
            [d.Philosophy, philosophy],
            [d.Appearance_L, appearance],
            [d.Personality_L, personality],
            [d.Example_L, example],
            [d.WorldInfoBackground, background],
        ].filter(([, body]) => body);
        const worldEntriesHtml = (worldInfo.entries || [])
            .map((entry) => {
                const meta = [
                    worldCategoryLabel(entry.category),
                    entry.keys.join(' · '),
                    d.EntryTokenCount.replace(
                        '{count}',
                        window.LFWorldInfoEngine
                            ? window.LFWorldInfoEngine.estimateTokens(
                                  entry.content
                              )
                            : 0
                    ),
                ]
                    .filter(Boolean)
                    .join(' · ');
                return `
                <div class="card-world-entry">
                    <div class="card-world-entry-title">${escapeHtml(
                        entry.title || entry.id
                    )}</div>
                    <div class="card-world-entry-meta">${escapeHtml(meta)}</div>
                    ${
                        entry.content
                            ? `<div class="card-world-entry-content">${escapeHtml(
                                  entry.content
                              )}</div>`
                            : ''
                    }
                </div>`;
            })
            .join('');
        const statsChips = [
            d.CharacterXmlTokens.replace(
                '{count}',
                estimateTokens(buildXMLString())
            ),
            d.WorldInfoTokenSummary.replace('{count}', stats.totalTokens),
            `${d.WorldInfoEntries} ${stats.entries}`,
        ];
        if (avatarDataUrl) {
            const sizeText = avatarMeta
                ? `${avatarMeta.width}×${avatarMeta.height} · ${formatBytes(
                      avatarMeta.bytes
                  )}`
                : formatBytes(dataUrlBytes(avatarDataUrl));
            statsChips.push(d.AvatarMedia.replace('{size}', sizeText));
        }
        if (illustrationDataUrl) {
            const sizeText = illustrationMeta
                ? `${illustrationMeta.width}×${illustrationMeta.height} · ${formatBytes(
                      illustrationMeta.bytes
                  )}`
                : formatBytes(dataUrlBytes(illustrationDataUrl));
            statsChips.push(d.IllustrationMedia.replace('{size}', sizeText));
        }

        container.innerHTML = `
        <div class="card-sheet">
            <div class="card-hero">
                <div class="card-illustration">${illustration}</div>
                <div class="card-identity">
                    <div class="card-avatar">${avatar}</div>
                    <div>
                        <h2 class="card-name">${escapeHtml(name || 'Character')}</h2>
                        ${nameEn ? `<div class="card-name-en">${escapeHtml(nameEn)}</div>` : ''}
                    </div>
                    ${
                        metaParts.length
                            ? `<div class="card-meta">${escapeHtml(
                                  metaParts.join(' · ')
                              )}</div>`
                            : ''
                    }
                    ${
                        tags.length
                            ? `<div class="card-tags">${tags
                                  .map(
                                      (tag) =>
                                          `<span class="card-tag">${escapeHtml(tag)}</span>`
                                  )
                                  .join('')}</div>`
                            : ''
                    }
                </div>
            </div>
            ${
                sections.length
                    ? sections
                          .map(
                              ([title, body]) => `
                <div class="card-section">
                    <div class="card-section-title">${escapeHtml(title)}</div>
                    <div class="card-section-body">${escapeHtml(body)}</div>
                </div>`
                          )
                          .join('')
                    : ''
            }
            ${
                (worldInfo.entries || []).length
                    ? `<div class="card-section">
                        <div class="card-section-title">${escapeHtml(
                            d.WorldInfoEntries
                        )}</div>
                        <div class="card-world-entries">${worldEntriesHtml}</div>
                    </div>`
                    : ''
            }
            <div class="card-stats">${statsChips
                .map(
                    (text) =>
                        `<span class="card-stat">${escapeHtml(text)}</span>`
                )
                .join('')}</div>
        </div>`;
    }

    function renderActivationTest() {
        const results = document.getElementById('WorldInfoTestResults');
        const input = document.getElementById('WorldInfoTestInput');
        if (!results || !input) return;
        const d = dict();
        const lines = input.value
            .split(/\r?\n/)
            .map((line) => line.trim())
            .filter(Boolean);
        if (lines.length === 0) {
            results.innerHTML = `<div class="test-empty">${escapeHtml(
                d.TestNeedsText
            )}</div>`;
            return;
        }
        if (!window.LFWorldInfo || !window.LFWorldInfoEngine) {
            results.innerHTML = `<div class="test-empty">${escapeHtml(
                d.TestNeedsText
            )}</div>`;
            return;
        }

        const current = lines[lines.length - 1];
        const history = lines.slice(0, -1);
        const info = window.LFWorldInfo.getData();
        const activation = window.LFWorldInfoEngine.activateWithExpansion(
            info,
            history,
            { currentContent: current }
        );
        const injection = window.LFWorldInfoEngine.buildInjection(
            info,
            activation
        );
        const tokenStats = `
            <div class="test-card">
                <div class="test-card-body">
                    <div class="test-stat-row">
                        <span class="test-stat">${escapeHtml(
                            d.TestBackgroundTokens.replace(
                                '{count}',
                                activation.backgroundTokens
                            )
                        )}</span>
                        <span class="test-stat">${escapeHtml(
                            d.TestEntryTokens.replace(
                                '{count}',
                                activation.entryTokens
                            )
                        )}</span>
                        <span class="test-stat">${escapeHtml(
                            d.TestTotalTokens.replace(
                                '{count}',
                                activation.totalTokens
                            )
                        )}</span>
                        <span class="test-stat">${escapeHtml(
                            d.TestBudget.replace(
                                '{count}',
                                info.budget_tokens ?? 1000
                            )
                        )}</span>
                    </div>
                </div>
            </div>`;
        const matchedEntries = activation.matched
            .map((item) => {
                const entry = item.entry;
                const meta = [
                    positionLabel(entry.position),
                    entry.position === 'at_depth' ? entry.depth : '',
                    d.EntryTokenCount.replace('{count}', item.tokens),
                    item.viaSticky ? d.EntrySticky : '',
                    item.viaRecursion
                        ? `${d.EntryRecursive} ${item.recursionLevel}`
                        : '',
                ]
                    .filter(Boolean)
                    .join(' · ');
                return `
                <div class="test-entry">
                    <div class="test-entry-head">
                        <span class="test-entry-title">${escapeHtml(
                            window.LFWorldInfoEngine.entryTitle(entry)
                        )}</span>
                        <span class="test-entry-meta">${escapeHtml(meta)}</span>
                    </div>
                    <div class="test-entry-meta">${escapeHtml(
                        item.matchedKey
                    )}</div>
                    <div class="test-entry-content">${escapeHtml(
                        entry.content
                    )}</div>
                </div>`;
            })
            .join('');
        const matched = `
            <div class="test-card">
                <div class="test-card-header">${escapeHtml(
                    d.MatchedCount.replace('{count}', activation.matched.length)
                )}</div>
                ${
                    matchedEntries ||
                    `<div class="test-empty">${escapeHtml(
                        d.NoMatchedEntries
                    )}</div>`
                }
            </div>`;
        const skippedEntries = activation.skipped
            .map(
                ({ entry, reason }) => `
                <div class="test-entry">
                    <div class="test-entry-head">
                        <span class="test-entry-title">${escapeHtml(
                            window.LFWorldInfoEngine.entryTitle(entry)
                        )}</span>
                        <span class="test-entry-meta">${escapeHtml(
                            skipReasonLabel(reason)
                        )}</span>
                    </div>
                </div>`
            )
            .join('');
        const skipped = `
            <div class="test-card">
                <div class="test-card-header">${escapeHtml(
                    d.SkippedCount.replace('{count}', activation.skipped.length)
                )}</div>
                ${
                    skippedEntries ||
                    `<div class="test-empty">${escapeHtml(
                        d.NoSkippedEntries
                    )}</div>`
                }
            </div>`;
        const injectionBlocks = [];
        if (injection.systemBlock) {
            injectionBlocks.push(`
                <div class="test-card">
                    <div class="test-card-header">${escapeHtml(
                        d.PositionSystem
                    )}</div>
                    <div class="test-card-body"><pre>${escapeHtml(
                        injection.systemBlock
                    )}</pre></div>
                </div>`);
        }
        if (injection.beforePresetBlock) {
            injectionBlocks.push(`
                <div class="test-card">
                    <div class="test-card-header">${escapeHtml(
                        d.PositionBeforePreset
                    )}</div>
                    <div class="test-card-body"><pre>${escapeHtml(
                        injection.beforePresetBlock
                    )}</pre></div>
                </div>`);
        }
        if (injection.afterPresetBlock) {
            injectionBlocks.push(`
                <div class="test-card">
                    <div class="test-card-header">${escapeHtml(
                        d.PositionAfterPreset
                    )}</div>
                    <div class="test-card-body"><pre>${escapeHtml(
                        injection.afterPresetBlock
                    )}</pre></div>
                </div>`);
        }
        for (const block of injection.atDepth) {
            injectionBlocks.push(`
                <div class="test-card">
                    <div class="test-card-header">${escapeHtml(
                        `${d.PositionAtDepth} ${block.depth}`
                    )}</div>
                    <div class="test-card-body"><pre>${escapeHtml(
                        block.text
                    )}</pre></div>
                </div>`);
        }
        const injectionHtml = `
            <div class="test-card">
                <div class="test-card-header">${escapeHtml(
                    d.InjectionPreview
                )}</div>
                <div class="test-card-body">
                    ${
                        injectionBlocks.length
                            ? `<div class="test-injection">${injectionBlocks.join(
                                  ''
                              )}</div>`
                            : `<div class="test-empty">${escapeHtml(
                                  d.NoInjection
                              )}</div>`
                    }
                </div>
            </div>`;
        results.innerHTML = tokenStats + matched + skipped + injectionHtml;
    }

    function updatePreview() {
        const preview = document.getElementById('xml-output');
        const card = document.getElementById('card-preview');
        const test = document.getElementById('activation-test');
        const copy = document.getElementById('btn-Copy');
        const state = buildPreviewState();
        if (preview) {
            preview.innerText = state.text;
            preview.hidden = previewMode !== 'source';
        }
        const context = document.getElementById('preview-context');
        if (context) context.textContent = state.context;
        document.querySelectorAll('.preview-mode').forEach((button) => {
            button.classList.toggle(
                'active',
                button.dataset.previewMode === previewMode
            );
        });
        if (copy) copy.hidden = previewMode !== 'source';
        if (card) {
            card.hidden = previewMode !== 'card';
            if (previewMode === 'card') renderCardPreview(card);
        }
        if (test) {
            test.hidden = previewMode !== 'test';
            if (previewMode === 'test') renderActivationTest();
        }
    }

    function setPreviewMode(mode) {
        if (!['source', 'card', 'test'].includes(mode)) return;
        previewMode = mode;
        updatePreview();
        triggerAutoSave();
    }

    function renderTokenBreakdown(tokens) {
        const container = document.getElementById('TokenBreakdown');
        if (!container || container.hidden || !window.LFWorldInfo) return;
        const d = dict();
        const stats = window.LFWorldInfo.getStats();
        const labelOf = (template) =>
            String(template || '').split('{')[0].trim();
        const row = (label, value) =>
            `<div class="token-popover-row"><span>${escapeHtml(
                label
            )}</span><strong>${escapeHtml(value)}</strong></div>`;
        const rows = [
            row(labelOf(d.CharacterXmlTokens), tokens.toLocaleString()),
            row(
                labelOf(d.TestBackgroundTokens),
                stats.backgroundTokens.toLocaleString()
            ),
            row(labelOf(d.TestEntryTokens), stats.entryTokens.toLocaleString()),
            row(d.WorldInfoEntries, stats.entries.toLocaleString()),
        ];
        if (avatarDataUrl) {
            const value = avatarMeta
                ? `${avatarMeta.width}×${avatarMeta.height} · ${formatBytes(
                      avatarMeta.bytes
                  )}`
                : formatBytes(dataUrlBytes(avatarDataUrl));
            rows.push(row(labelOf(d.AvatarMedia), value));
        }
        if (illustrationDataUrl) {
            const value = illustrationMeta
                ? `${illustrationMeta.width}×${illustrationMeta.height} · ${formatBytes(
                      illustrationMeta.bytes
                  )}`
                : formatBytes(dataUrlBytes(illustrationDataUrl));
            rows.push(row(labelOf(d.IllustrationMedia), value));
        }
        container.innerHTML = rows.join('');
    }

    function toggleTokenBreakdown(show) {
        const container = document.getElementById('TokenBreakdown');
        const tokenBox = document.getElementById('token-box');
        if (!container || !tokenBox) return;
        const next = show === undefined ? container.hidden : show;
        container.hidden = !next;
        tokenBox.setAttribute('aria-expanded', String(next));
        if (next) renderTokenBreakdown(estimateTokens(buildXMLString()));
    }

    function updateTokenCount() {
        const xmlText = buildXMLString();

        const tokens = estimateTokens(xmlText);
        const tokenValEl = document.getElementById('token-val');
        const tokenBox = document.getElementById('token-box');
        const d = dict();
        tokenValEl.innerText = tokens.toLocaleString();
        tokenBox.classList.remove('safe', 'warning', 'danger');
        if (tokens > 8000) {
            tokenBox.classList.add('danger');
            tokenBox.title = d.TokenTipDanger;
        } else if (tokens > 4000) {
            tokenBox.classList.add('warning');
            tokenBox.title = d.TokenTipWarn;
        } else {
            tokenBox.classList.add('safe');
            tokenBox.title = d.TokenTipSafe;
        }
        renderTokenBreakdown(tokens);
        updatePreview();
        updateWorldInfoValidation();
    }

    function buildExportableXML() {
        const xml = buildXMLString();
        const doc = new DOMParser().parseFromString(xml, 'text/xml');
        if (doc.getElementsByTagName('parsererror').length > 0) {
            showToast(dict().ExportInvalid);
            return null;
        }
        return xml;
    }

    function parseAndFillXML(xmlString, filename, silent) {
        const d = dict();
        try {
            const source = String(xmlString || '').replace(/^﻿/, '');
            if (source.trim() === '') throw { code: 'Empty' };
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(source, 'text/xml');
            if (xmlDoc.getElementsByTagName('parsererror').length > 0) {
                throw { code: 'Syntax' };
            }
            const root = xmlDoc.documentElement;
            if (!root || root.tagName !== 'system_instruction') {
                throw { code: 'Root', tag: root ? root.tagName : '' };
            }

            const wrapper = Array.from(root.children).find((el) =>
                ['meta', 'mate'].includes(el.tagName)
            );
            const parents = wrapper ? [wrapper, root] : [root];
            const findSection = (tag) => {
                for (const parent of parents) {
                    const node = Array.from(parent.children).find(
                        (el) => el.tagName === tag
                    );
                    if (node) return node;
                }
                return null;
            };
            const getText = (tag) => {
                const node = findSection(tag);
                return node ? readInnerMarkup(node) : '';
            };

            const sectionTags = [
                'role_name', 'identity', 'core_philosophy',
                'worldview_background', 'appearance_traits', 'personality_logic',
                'addressing_protocol', 'linguistic_style',
                'behavior_narrative_rules', 'interaction_strategy',
                'internal_monologue', 'emotional_depth', 'knowledge_filter',
                'negative_constraints', 'example_dialogue'
            ];
            const seen = new Set();
            const ignored = [];
            Array.from(root.children).forEach((el) => {
                const tag = el.tagName;
                if (['meta', 'mate', 'user_info'].includes(tag)) return;
                if (!sectionTags.includes(tag) || seen.has(tag)) {
                    if (!ignored.includes(tag)) ignored.push(tag);
                    return;
                }
                seen.add(tag);
            });
            if (!sectionTags.some((tag) => findSection(tag) !== null)) {
                throw { code: 'NoSections' };
            }

            const fullRoleName = getText('role_name').replace(/\s+/g, ' ').trim();
            const nameMatch = fullRoleName.match(/^(.*?)\s*[（(]([^（）()]+)[）)]$/);
            if (nameMatch) {
                document.getElementById('RoleName').value = nameMatch[1].trim();
                document.getElementById('RoleNameEN').value = nameMatch[2].trim();
            } else {
                document.getElementById('RoleName').value = fullRoleName;
                document.getElementById('RoleNameEN').value = '';
            }

            document.getElementById('Identity').value = unindent(getText('identity'));
            document.getElementById('Philosophy').value = unindent(getText('core_philosophy'));
            document.getElementById('Appearance').value = unindent(getText('appearance_traits'));
            document.getElementById('Personality').value = unindent(getText('personality_logic'));
            document.getElementById('Addressing').value = unindent(getText('addressing_protocol'));
            document.getElementById('Linguistic').value = unindent(getText('linguistic_style'));
            document.getElementById('Behavior').value = unindent(getText('behavior_narrative_rules'));
            document.getElementById('Interaction').value = unindent(getText('interaction_strategy'));

            const advanced = {
                InternalMonologue: unindent(getText('internal_monologue')),
                EmotionalDepth: unindent(getText('emotional_depth')),
                KnowledgeFilter: unindent(getText('knowledge_filter')),
                NegativeConstraints: unindent(getText('negative_constraints'))
            };
            Object.entries(advanced).forEach(([id, value]) => {
                document.getElementById(id).value = value;
            });
            if (Object.values(advanced).some(Boolean)) {
                document.getElementById('AdvancedOptionsPanel').open = true;
            }

            document.getElementById('Example').value = unindent(getText('example_dialogue'));
            if (filename) {
                document.getElementById('FileName').value = filename.replace(/\.xml$/i, '');
            }
            syncMetaName();
            autoResizeAllTextareas();
            updateTokenCount();
            triggerAutoSave();

            if (!silent) {
                if (ignored.length > 0) {
                    showToast(
                        d.ImportSuccessIgnored
                            .replace('{n}', ignored.length)
                            .replace('{list}', ignored.join(d.ListSep))
                    );
                } else {
                    showToast(d.ImportSuccess);
                }
            }
            return unindent(getText('worldview_background'));
        } catch (error) {
            console.error('XML Parsing Error:', error);
            if (!silent) {
                const code = error && error.code;
                if (code === 'Empty') showToast(d.ImportErrEmpty);
                else if (code === 'Syntax') showToast(d.ImportErrSyntax);
                else if (code === 'Root') {
                    showToast(
                        d.ImportErrRoot.replace('{tag}', (error && error.tag) || '?')
                    );
                } else if (code === 'NoSections') {
                    showToast(d.ImportErrNoSections);
                } else {
                    showToast(d.ImportError);
                }
            }
            return null;
        }
    }

    function applyMeta(meta) {
        if (!meta || typeof meta !== 'object') return;
        if (typeof meta.name === 'string' && meta.name.trim()) {
            document.getElementById('RoleName').value = meta.name.trim();
        }
        if (typeof meta.author === 'string') {
            document.getElementById('MetaAuthor').value = meta.author;
        }
        if (typeof meta.version === 'string' && meta.version.trim()) {
            document.getElementById('MetaVersion').value = meta.version;
        }
        document.getElementById('MetaLanguage').value =
            typeof meta.language === 'string' ? meta.language : '';
        document.getElementById('MetaTags').value = Array.isArray(meta.tags)
            ? meta.tags.join(', ')
            : '';
        document.getElementById('MetaIcon').value =
            typeof meta.icon === 'string' && meta.icon
                ? meta.icon
                : 'person.fill';
        renderTagChips();
        renderIconGrid();
        syncMetaName();
    }

    function renderAvatar() {
        const preview = document.getElementById('AvatarPreview');
        if (!preview) return;
        if (avatarDataUrl) {
            preview.innerHTML = `<img src="${avatarDataUrl}" alt="avatar">`;
        } else {
            preview.innerHTML = '<span class="avatar-placeholder">PNG</span>';
        }
        const remove = document.getElementById('btn-RemoveAvatar');
        if (remove) remove.disabled = !avatarDataUrl;
    }

    function renderIllustration() {
        const preview = document.getElementById('IllustrationPreview');
        if (!preview) return;
        if (illustrationDataUrl) {
            preview.innerHTML = `<img src="${illustrationDataUrl}" alt="illustration">`;
        } else {
            preview.innerHTML = '<span class="illustration-placeholder">PNG</span>';
        }
        const remove = document.getElementById('btn-RemoveIllustration');
        if (remove) remove.disabled = !illustrationDataUrl;
    }

    function renderMediaMeta() {
        const d = dict();
        const setMeta = (id, dataUrl, meta) => {
            const element = document.getElementById(id);
            if (!element) return;
            if (!dataUrl) {
                element.textContent = '';
                return;
            }
            if (meta && meta.width && meta.height) {
                element.textContent = d.ImageMeta
                    .replace('{width}', meta.width)
                    .replace('{height}', meta.height)
                    .replace(
                        '{size}',
                        formatBytes(meta.bytes || dataUrlBytes(dataUrl))
                    );
            } else {
                element.textContent = formatBytes(dataUrlBytes(dataUrl));
            }
        };
        setMeta('AvatarMeta', avatarDataUrl, avatarMeta);
        setMeta('IllustrationMeta', illustrationDataUrl, illustrationMeta);
    }

    function measureDataUrl(dataUrl) {
        return new Promise((resolve) => {
            const image = new Image();
            image.onload = () =>
                resolve({
                    width: image.naturalWidth,
                    height: image.naturalHeight,
                    bytes: dataUrlBytes(dataUrl),
                });
            image.onerror = () => resolve(null);
            image.src = dataUrl;
        });
    }

    async function ensureImageMeta(kind) {
        if (kind === 'avatar' && avatarDataUrl && !avatarMeta) {
            avatarMeta = await measureDataUrl(avatarDataUrl);
            renderMediaMeta();
            updateTokenCount();
        }
        if (kind === 'illustration' && illustrationDataUrl && !illustrationMeta) {
            illustrationMeta = await measureDataUrl(illustrationDataUrl);
            renderMediaMeta();
            updateTokenCount();
        }
    }

    function clearAvatar(save = true) {
        avatarDataUrl = '';
        avatarMeta = null;
        renderAvatar();
        renderMediaMeta();
        updateTokenCount();
        if (save) triggerAutoSave();
    }

    function clearIllustration(save = true) {
        illustrationDataUrl = '';
        illustrationMeta = null;
        renderIllustration();
        renderMediaMeta();
        updateTokenCount();
        if (save) triggerAutoSave();
    }

    function dataUrlToBytes(dataUrl) {
        const base64 = dataUrl.split(',')[1] || '';
        const binary = atob(base64);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
        return bytes;
    }

    function bytesToDataUrl(bytes, mime) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = reject;
            reader.readAsDataURL(new Blob([bytes], { type: mime }));
        });
    }

    function isPng(bytes) {
        const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
        return signature.every((value, index) => bytes[index] === value);
    }

    function canvasToPngBlob(canvas) {
        return new Promise((resolve) => canvas.toBlob(resolve, 'image/png'));
    }

    async function processPngFile(file, caps, maxBytes, invalidMessage, tooLargeMessage) {
        try {
            const bytes = new Uint8Array(await file.arrayBuffer());
            if (!isPng(bytes)) {
                showToast(invalidMessage);
                return null;
            }
            const bitmap = await createImageBitmap(
                new Blob([bytes], { type: 'image/png' })
            );
            const longest = Math.max(bitmap.width, bitmap.height);
            let accepted = null;
            let acceptedWidth = 0;
            let acceptedHeight = 0;
            for (const cap of caps) {
                const scale = longest > cap ? cap / longest : 1;
                const width = Math.max(1, Math.round(bitmap.width * scale));
                const height = Math.max(1, Math.round(bitmap.height * scale));
                const canvas = document.createElement('canvas');
                canvas.width = width;
                canvas.height = height;
                const context = canvas.getContext('2d');
                context.drawImage(bitmap, 0, 0, width, height);
                const blob = await canvasToPngBlob(canvas);
                if (blob && blob.size <= maxBytes) {
                    accepted = blob;
                    acceptedWidth = width;
                    acceptedHeight = height;
                    break;
                }
            }
            if (!accepted) {
                showToast(tooLargeMessage);
                return null;
            }
            const acceptedBytes = new Uint8Array(await accepted.arrayBuffer());
            return {
                dataUrl: await bytesToDataUrl(acceptedBytes, 'image/png'),
                width: acceptedWidth,
                height: acceptedHeight,
                bytes: accepted.size,
            };
        } catch (error) {
            console.error(error);
            showToast(invalidMessage);
            return null;
        }
    }

    async function handleAvatarFile(file) {
        const d = dict();
        const dataUrl = await processPngFile(
            file,
            [1024, 768, 512],
            MAX_AVATAR_BYTES,
            d.AvatarInvalid,
            d.AvatarTooLarge
        );
        if (!dataUrl) return;
        avatarDataUrl = dataUrl.dataUrl;
        avatarMeta = {
            width: dataUrl.width,
            height: dataUrl.height,
            bytes: dataUrl.bytes,
        };
        renderAvatar();
        renderMediaMeta();
        updateTokenCount();
        triggerAutoSave();
    }

    async function handleIllustrationFile(file) {
        const d = dict();
        const dataUrl = await processPngFile(
            file,
            [2048, 1024, 768, 512],
            MAX_ILLUSTRATION_BYTES,
            d.IllustrationInvalid,
            d.IllustrationTooLarge
        );
        if (!dataUrl) return;
        illustrationDataUrl = dataUrl.dataUrl;
        illustrationMeta = {
            width: dataUrl.width,
            height: dataUrl.height,
            bytes: dataUrl.bytes,
        };
        renderIllustration();
        renderMediaMeta();
        updateTokenCount();
        triggerAutoSave();
    }

    async function sha256Hex(bytes) {
        if (!window.crypto || !window.crypto.subtle) {
            throw new Error(dict().CryptoUnavailable);
        }
        const digest = await window.crypto.subtle.digest('SHA-256', bytes);
        return Array.from(new Uint8Array(digest))
            .map((byte) => byte.toString(16).padStart(2, '0'))
            .join('');
    }

    function textBytes(text) {
        return new TextEncoder().encode(text);
    }

    function safeFileName(name) {
        const cleaned = String(name || '')
            .replace(/[\\/:*?"<>|]/g, '')
            .trim();
        return cleaned || 'character';
    }

    function downloadBlob(blob, fileName) {
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    }

    const WI_ERRORS = {
        zh: {
            DuplicateId: '条目 ID 重复：',
            MissingKeys: '条目缺少主关键词：',
            TooManyEntries: '世界书条目超过 500 条',
            TooManyKeys: '条目关键词超过 20 个：',
            InvalidRegex: '正则表达式无效：',
            RegexTooLong: '正则表达式超过 200 字符：',
            ContentTooLong: '条目内容超过 4000 字符：',
            InvalidPosition: '注入位置无效：',
            InvalidTiming: '深度、粘滞或冷却超出 0-1000：',
            InvalidProbability: '激活概率必须在 0-100：',
            GroupTooLong: '包含组名超过 64 字符：',
            MinActivationsTooHigh: '最小激活条目数必须在 0-50',
            RecursionDepthTooHigh: '递归深度必须在 0-10',
            EmptyTitle: '条目标题为空：',
            EmptyContent: '条目内容为空：',
            DuplicateEntryKeys: '条目内有重复关键词：',
            DuplicateKeysAcrossEntries: '关键词与其他条目重复：',
            GroupConflict: '包含组与其他条目冲突：',
            EntryBudgetExceeded: '世界书条目总 token 超过预算；运行时将按优先级截断',
            XmlTooLarge: '角色 XML 超过 200 KB，无法导入应用'
        },
        en: {
            DuplicateId: 'Duplicate entry id: ',
            MissingKeys: 'Entry has no primary keys: ',
            TooManyEntries: 'World info has more than 500 entries',
            TooManyKeys: 'Entry has more than 20 keys: ',
            InvalidRegex: 'Invalid regex: ',
            RegexTooLong: 'Regex is over 200 characters: ',
            ContentTooLong: 'Entry content is over 4000 characters: ',
            InvalidPosition: 'Invalid injection position: ',
            InvalidTiming: 'Depth, sticky, or cooldown is outside 0-1000: ',
            InvalidProbability: 'Probability must be between 0 and 100: ',
            GroupTooLong: 'Inclusion group is over 64 characters: ',
            MinActivationsTooHigh: 'Minimum activations must be between 0 and 50',
            RecursionDepthTooHigh: 'Recursion depth must be between 0 and 10',
            EmptyTitle: 'Entry title is empty: ',
            EmptyContent: 'Entry content is empty: ',
            DuplicateEntryKeys: 'Duplicate keys in this entry: ',
            DuplicateKeysAcrossEntries: 'Keys also used by another entry: ',
            GroupConflict: 'Inclusion group overlaps another entry: ',
            EntryBudgetExceeded: 'World info entries exceed the token budget; lower-priority entries will be skipped at runtime',
            XmlTooLarge: 'Character XML is over 200 KB and cannot be imported'
        },
        ja: {
            DuplicateId: '項目 ID が重複しています：',
            MissingKeys: '項目に主キーがありません：',
            TooManyEntries: 'ワールド情報の項目が 500 を超えています',
            TooManyKeys: '項目のキーが 20 を超えています：',
            InvalidRegex: '正規表現が無効です：',
            RegexTooLong: '正規表現が 200 文字を超えています：',
            ContentTooLong: '項目の内容が 4000 文字を超えています：',
            InvalidPosition: '注入位置が無効です：',
            InvalidTiming: '深度・スティッキー・クールダウンは 0〜1000 の範囲です：',
            InvalidProbability: '確率は 0〜100 の範囲です：',
            GroupTooLong: '包含グループ名が 64 文字を超えています：',
            MinActivationsTooHigh: '最小発動数は 0〜50 の範囲です',
            RecursionDepthTooHigh: '再帰深度は 0〜10 の範囲です',
            EmptyTitle: '項目タイトルが空です：',
            EmptyContent: '項目の内容が空です：',
            DuplicateEntryKeys: '項目内に重複キーがあります：',
            DuplicateKeysAcrossEntries: '他の項目と同じキーがあります：',
            GroupConflict: '包含グループが他の項目と重複しています：',
            EntryBudgetExceeded: 'ワールド情報の合計トークンが予算を超えています。実行時は優先度順に切り捨てられます',
            XmlTooLarge: 'キャラクター XML が 200 KB を超えています'
        },
        ko: {
            DuplicateId: '항목 ID가 중복됩니다: ',
            MissingKeys: '항목에 주 키워드가 없습니다: ',
            TooManyEntries: '세계관 항목이 500개를 넘습니다',
            TooManyKeys: '항목 키워드가 20개를 넘습니다: ',
            InvalidRegex: '정규식이 잘못되었습니다: ',
            RegexTooLong: '정규식이 200자를 넘습니다: ',
            ContentTooLong: '항목 내용이 4000자를 넘습니다: ',
            InvalidPosition: '주입 위치가 잘못되었습니다: ',
            InvalidTiming: '깊이, 유지, 재사용 대기는 0~1000 범위여야 합니다: ',
            InvalidProbability: '확률은 0~100 범위여야 합니다: ',
            GroupTooLong: '포함 그룹 이름이 64자를 넘습니다: ',
            MinActivationsTooHigh: '최소 활성화 수는 0~50 범위여야 합니다',
            RecursionDepthTooHigh: '재귀 깊이는 0~10 범위여야 합니다',
            EmptyTitle: '항목 제목이 비어 있습니다: ',
            EmptyContent: '항목 내용이 비어 있습니다: ',
            DuplicateEntryKeys: '항목 내에 중복 키가 있습니다: ',
            DuplicateKeysAcrossEntries: '다른 항목과 키가 겹칩니다: ',
            GroupConflict: '포함 그룹이 다른 항목과 겹칩니다: ',
            EntryBudgetExceeded: '세계관 항목의 총 토큰이 예산을 초과했습니다. 실행 시 우선순위에 따라 잘립니다',
            XmlTooLarge: '캐릭터 XML이 200 KB를 넘어 가져올 수 없습니다'
        },
        es: {
            DuplicateId: 'ID de entrada duplicado: ',
            MissingKeys: 'La entrada no tiene claves principales: ',
            TooManyEntries: 'La información del mundo supera 500 entradas',
            TooManyKeys: 'La entrada supera 20 claves: ',
            InvalidRegex: 'Regex no válido: ',
            RegexTooLong: 'El regex supera 200 caracteres: ',
            ContentTooLong: 'El contenido supera 4000 caracteres: ',
            InvalidPosition: 'Posición de inyección no válida: ',
            InvalidTiming: 'La profundidad, permanencia o recarga deben estar entre 0 y 1000: ',
            InvalidProbability: 'La probabilidad debe estar entre 0 y 100: ',
            GroupTooLong: 'El grupo de inclusión supera 64 caracteres: ',
            MinActivationsTooHigh: 'El mínimo de activaciones debe estar entre 0 y 50',
            RecursionDepthTooHigh: 'La profundidad de recursión debe estar entre 0 y 10',
            EmptyTitle: 'El título de la entrada está vacío: ',
            EmptyContent: 'El contenido de la entrada está vacío: ',
            DuplicateEntryKeys: 'Hay claves duplicadas en esta entrada: ',
            DuplicateKeysAcrossEntries: 'Las claves también se usan en otra entrada: ',
            GroupConflict: 'El grupo de inclusión coincide con otra entrada: ',
            EntryBudgetExceeded: 'Las entradas del mundo superan el presupuesto de tokens; las de menor prioridad se omitirán al ejecutar',
            XmlTooLarge: 'El XML del personaje supera 200 KB y no se puede importar'
        }
    };

    function worldInfoErrorText(error) {
        const table = WI_ERRORS[currentLang] || WI_ERRORS.en;
        return (table[error.code] || error.code) + (error.title || '');
    }

    function updateWorldInfoValidation() {
        const panel = document.getElementById('WorldInfoValidation');
        if (!panel || !window.LFWorldInfo) return;
        const d = dict();
        const table = WI_ERRORS[currentLang] || WI_ERRORS.en;

        document
            .querySelectorAll('#WorldInfoEntries .wi-entry')
            .forEach((card) => {
                card.classList.remove('has-error', 'has-warning');
                const status = card.querySelector('[data-entry-status]');
                if (status) {
                    status.textContent = '';
                    status.className = 'wi-entry-status';
                    status.title = '';
                }
            });

        const issues = window.LFWorldInfo.validateAll();
        const entryCount = window.LFWorldInfo.getData().entries.length;
        if (issues.length === 0 && entryCount === 0) {
            panel.hidden = true;
            return;
        }

        panel.hidden = false;
        if (issues.length === 0) {
            panel.innerHTML = `<div class="validation-header is-pass">✓ ${escapeHtml(
                d.ValidationPass
            )}</div>`;
            return;
        }

        const errors = issues.filter((issue) => issue.severity === 'error');
        const warnings = issues.filter((issue) => issue.severity === 'warning');
        const byEntry = new Map();
        for (const issue of issues) {
            if (issue.entryIndex === null || issue.entryIndex === undefined) {
                continue;
            }
            const existing = byEntry.get(issue.entryIndex);
            if (!existing || issue.severity === 'error') {
                byEntry.set(issue.entryIndex, issue);
            }
        }
        byEntry.forEach((issue, index) => {
            const card = document.querySelector(
                `#WorldInfoEntries .wi-entry[data-entry-index="${index}"]`
            );
            if (!card) return;
            const isError = issue.severity === 'error';
            card.classList.add(isError ? 'has-error' : 'has-warning');
            const status = card.querySelector('[data-entry-status]');
            if (status) {
                status.textContent = isError
                    ? d.ValidationError
                    : d.ValidationWarning;
                status.className = `wi-entry-status ${
                    isError ? 'is-error' : 'is-warning'
                }`;
                status.title = (table[issue.code] || issue.code) +
                    (issue.entryTitle || '');
            }
        });

        const rows = issues
            .map((issue) => {
                const base = table[issue.code] || issue.code;
                const title = issue.entryTitle
                    ? `<span class="validation-entry-name">${escapeHtml(
                          issue.entryTitle
                      )}</span>`
                    : '';
                const content = `<span class="validation-dot"></span>
                    <span class="validation-message">${escapeHtml(base)}${
                        title ? ` ${title}` : ''
                    }</span>`;
                if (issue.entryIndex === null || issue.entryIndex === undefined) {
                    return `<div class="validation-issue ${
                        issue.severity === 'warning' ? 'warning' : ''
                    }">${content}</div>`;
                }
                return `<button type="button" class="validation-issue ${
                    issue.severity === 'warning' ? 'warning' : ''
                }" data-entry-index="${issue.entryIndex}">${content}</button>`;
            })
            .join('');

        panel.innerHTML = `
            <div class="validation-header">
                <span>${escapeHtml(
                    d.ValidationIssueCount.replace('{count}', issues.length)
                )}</span>
                <span class="validation-entry-name">${errors.length} ${escapeHtml(
                    d.ValidationError
                )} · ${warnings.length} ${escapeHtml(d.ValidationWarning)}</span>
            </div>
            <div class="validation-list">${rows}</div>`;

        panel.querySelectorAll('[data-entry-index]').forEach((button) => {
            button.addEventListener('click', () => {
                window.LFWorldInfo.focusEntry(
                    Number(button.dataset.entryIndex)
                );
            });
        });
    }

    function buildMetaPayload() {
        const meta = {
            _format: 'lumenflow_character_meta',
            _version: 1,
            name:
                document.getElementById('MetaName').value.trim() ||
                document.getElementById('RoleName').value.trim() ||
                'Character',
            description: document.getElementById('Identity').value.trim(),
            author: document.getElementById('MetaAuthor').value.trim(),
            version:
                document.getElementById('MetaVersion').value.trim() || 'v1.0',
            tags: splitTags(document.getElementById('MetaTags').value),
            icon: document.getElementById('MetaIcon').value || 'person.fill',
        };
        const language = document.getElementById('MetaLanguage').value;
        if (language) meta.language = language;
        return meta;
    }

    async function exportArchive() {
        const d = dict();
        const xml = buildExportableXML();
        if (xml === null) return;
        if (textBytes(xml).length > 200 * 1024) {
            showToast(dict().XmlTooLarge);
            return;
        }
        const wiError = window.LFWorldInfo.validate();
        if (wiError) {
            switchTab('worldinfo');
            updateWorldInfoValidation();
            if (wiError.entryIndex !== null && wiError.entryIndex !== undefined) {
                window.LFWorldInfo.focusEntry(wiError.entryIndex);
            }
            showToast(worldInfoErrorText(wiError));
            return;
        }

        try {
            const meta = buildMetaPayload();

            const files = [
                {
                    path: 'character/meta.json',
                    role: 'meta',
                    bytes: textBytes(JSON.stringify(meta, null, 2))
                },
                {
                    path: 'character/character.xml',
                    role: 'character',
                    bytes: textBytes(xml)
                }
            ];

            const worldInfo = window.LFWorldInfo.getData();
            if (!worldInfo.name) worldInfo.name = meta.name;
            if (window.LFWorldInfo.hasContent()) {
                files.push({
                    path: 'character/world_info.json',
                    role: 'world_info',
                    bytes: textBytes(JSON.stringify(worldInfo, null, 2))
                });
            }

            let avatarBytes = null;
            if (avatarDataUrl) avatarBytes = dataUrlToBytes(avatarDataUrl);
            if (avatarBytes) {
                files.push({
                    path: 'character/avatar.png',
                    role: 'avatar',
                    bytes: avatarBytes
                });
            }

            let illustrationBytes = null;
            if (illustrationDataUrl) {
                illustrationBytes = dataUrlToBytes(illustrationDataUrl);
            }
            if (illustrationBytes) {
                files.push({
                    path: 'character/illustration.png',
                    role: 'illustration',
                    bytes: illustrationBytes
                });
            }

            for (const file of files) {
                file.size = file.bytes.length;
                file.sha256 = await sha256Hex(file.bytes);
            }

            const manifest = {
                _format: 'lumenflow',
                _version: '2.0',
                _type: 'character_card',
                _created: new Date().toISOString(),
                _app_version: 'web-generator',
                _min_reader_version: '2.0',
                _title: meta.name,
                _language: meta.language || currentLang,
                _contains_secrets: false,
                includes_character: true,
                files: files.map(({ path, role, size, sha256 }) => ({
                    path,
                    role,
                    size,
                    sha256
                }))
            };

            const zip = new JSZip();
            zip.file('manifest.json', JSON.stringify(manifest, null, 2));
            for (const file of files) {
                zip.file(file.path, file.bytes);
            }
            const blob = await zip.generateAsync({
                type: 'blob',
                compression: 'DEFLATE'
            });
            const outputName =
                document.getElementById('FileName').value.trim() || meta.name;
            downloadBlob(blob, `${safeFileName(outputName)}.lumenflow`);
            showToast(`${d.ExportLumenflow} ✓`);
        } catch (error) {
            console.error(error);
            showToast(error.message || d.ExportFailed);
        }
    }

    async function importArchive(arrayBuffer) {
        const d = dict();
        try {
            if (!window.JSZip) throw new Error(d.ImportInvalidArchive);
            const zip = await JSZip.loadAsync(arrayBuffer);
            const manifestFile = zip.file('manifest.json');
            if (!manifestFile) throw new Error(d.ImportInvalidArchive);
            const manifest = JSON.parse(await manifestFile.async('string'));
            if (
                manifest._format !== 'lumenflow' ||
                !String(manifest._version || '').startsWith('2.') ||
                manifest._type !== 'character_card'
            ) {
                throw new Error(d.ImportInvalidArchive);
            }

            const entries = Array.isArray(manifest.files) ? manifest.files : [];
            for (const entry of entries) {
                if (
                    !entry ||
                    typeof entry.path !== 'string' ||
                    entry.path.includes('..') ||
                    entry.path.startsWith('/') ||
                    entry.path.includes('\\')
                ) {
                    throw new Error(d.ImportInvalidArchive);
                }
                const zipped = zip.file(entry.path);
                if (!zipped) throw new Error(d.ImportHashMismatch);
                const bytes = await zipped.async('uint8array');
                if (bytes.length !== entry.size) {
                    throw new Error(d.ImportHashMismatch);
                }
                if ((await sha256Hex(bytes)) !== entry.sha256) {
                    throw new Error(d.ImportHashMismatch);
                }
            }

            const xmlFile = zip.file('character/character.xml');
            if (!xmlFile) throw new Error(d.ImportInvalidArchive);
            const xml = await xmlFile.async('string');
            const legacyBackground = parseAndFillXML(xml, null, true);
            if (legacyBackground === null) throw new Error(d.ImportInvalidArchive);

            const metaFile = zip.file('character/meta.json');
            let meta = null;
            if (metaFile) {
                meta = JSON.parse(await metaFile.async('string'));
                applyMeta(meta);
                if (meta.description &&
                    !document.getElementById('Identity').value.trim()) {
                    document.getElementById('Identity').value = meta.description;
                }
            }

            window.LFWorldInfo.reset();
            const worldInfoFile = zip.file('character/world_info.json');
            if (worldInfoFile) {
                window.LFWorldInfo.setData(
                    JSON.parse(await worldInfoFile.async('string'))
                );
            } else if (legacyBackground) {
                window.LFWorldInfo.importLegacyBackground(legacyBackground);
            }

            avatarMeta = null;
            illustrationMeta = null;
            const avatarFile = zip.file('character/avatar.png');
            if (avatarFile) {
                const bytes = await avatarFile.async('uint8array');
                avatarDataUrl = isPng(bytes)
                    ? await bytesToDataUrl(bytes, 'image/png')
                    : '';
            } else {
                avatarDataUrl = '';
            }
            const illustrationFile = zip.file('character/illustration.png');
            if (illustrationFile) {
                const bytes = await illustrationFile.async('uint8array');
                illustrationDataUrl = isPng(bytes)
                    ? await bytesToDataUrl(bytes, 'image/png')
                    : '';
            } else {
                illustrationDataUrl = '';
            }
            renderAvatar();
            renderIllustration();
            renderMediaMeta();
            ensureImageMeta('avatar');
            ensureImageMeta('illustration');
            document.getElementById('FileName').value = safeFileName(
                (meta && meta.name) || document.getElementById('RoleName').value
            );
            autoResizeAllTextareas();
            updateTokenCount();
            queueDraftSave();
            switchTab('character');
            showToast(d.ImportSuccess);
        } catch (error) {
            console.error(error);
            showToast(error.message || d.ImportInvalidArchive);
        }
    }

    function handleFileImport(event) {
        const file = event.target.files[0];
        if (!file) return;
        const isArchive = file.name.toLowerCase().endsWith('.lumenflow');
        if (isArchive) {
            const reader = new FileReader();
            reader.onload = (e) => importArchive(e.target.result);
            reader.readAsArrayBuffer(file);
        } else {
            const reader = new FileReader();
            reader.onload = (e) => {
                const legacy = parseAndFillXML(e.target.result, file.name, false);
                if (legacy && legacy.trim()) {
                    window.LFWorldInfo.reset();
                    window.LFWorldInfo.importLegacyBackground(legacy);
                    const roleName = document.getElementById('RoleName').value.trim();
                    const nameEl = document.getElementById('WorldInfoName');
                    if (roleName && !nameEl.value.trim()) {
                        nameEl.value = roleName;
                        nameEl.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                    showToast(dict().LegacyBackgroundImported);
                } else if (legacy !== null) {
                    window.LFWorldInfo.reset();
                }
            };
            reader.readAsText(file);
        }
        event.target.value = '';
    }

    function applyLanguageUI() {
        const d = dict();
        document.documentElement.lang =
            currentLang === 'zh' ? 'zh-CN' : currentLang;
        const setText = (id, value) => {
            const el = document.getElementById(id);
            if (el) el.innerText = value;
        };
        setText('ui-title', d.Title);
        setText('lbl-TokenCount', d.TokenCount);
        setText('save-indicator', d.AutoSaved);
        setText('lbl-RoleName', d.RoleName);
        setText('lbl-RoleNameEN', d.RoleNameEN);
        setText('lbl-Identity', d.Identity);
        setText('lbl-Philosophy', d.Philosophy);
        setText('lbl-OutputFile', d.OutputFile);
        setText('lbl-Appearance', d.Appearance_L);
        setText('hint-Appearance', d.Appearance_H);
        setText('lbl-Personality', d.Personality_L);
        setText('hint-Personality', d.Personality_H);
        setText('lbl-Addressing', d.Addressing_L);
        setText('hint-Addressing', d.Addressing_H);
        setText('lbl-Linguistic', d.Linguistic_L);
        setText('hint-Linguistic', d.Linguistic_H);
        setText('lbl-Behavior', d.Behavior_L);
        setText('hint-Behavior', d.Behavior_H);
        setText('lbl-Interaction', d.Interaction_L);
        setText('hint-Interaction', d.Interaction_H);
        setText('lbl-AdvancedOptions', d.AdvancedOptions);
        setText('lbl-InternalMonologue', d.InternalMonologue_L);
        setText('hint-InternalMonologue', d.InternalMonologue_H);
        setText('lbl-EmotionalDepth', d.EmotionalDepth_L);
        setText('hint-EmotionalDepth', d.EmotionalDepth_H);
        setText('lbl-KnowledgeFilter', d.KnowledgeFilter_L);
        setText('hint-KnowledgeFilter', d.KnowledgeFilter_H);
        setText('lbl-NegativeConstraints', d.NegativeConstraints_L);
        setText('hint-NegativeConstraints', d.NegativeConstraints_H);
        setText('lbl-Example', d.Example_L);
        setText('hint-Example', d.Example_H);
        setText('ui-done', d.Done);
        setText('lbl-WorldInfoName', d.WorldInfoName);
        setText('lbl-WorldInfoDescription', d.WorldInfoDescription);
        setText('lbl-WorldInfoBackground', d.WorldInfoBackground);
        setText('hint-WorldInfoBackground', d.WorldInfoBackgroundHint);
        setText('lbl-WorldInfoScanDepth', d.WorldInfoScanDepth);
        setText('lbl-WorldInfoBudget', d.WorldInfoBudget);
        setText('lbl-WorldInfoMinActivations', d.WorldInfoMinActivations);
        setText('lbl-WorldInfoRecursionDepth', d.WorldInfoRecursionDepth);
        setText('lbl-WorldInfoEntries', d.WorldInfoEntries);
        setText('lbl-MetaName', d.MetaName);
        setText('lbl-MetaAuthor', d.MetaAuthor);
        setText('lbl-MetaVersion', d.MetaVersion);
        setText('lbl-MetaLanguage', d.MetaLanguage);
        setText('lbl-MetaTags', d.MetaTags);
        setText('lbl-MetaIcon', d.MetaIcon);
        setText('lbl-Avatar', d.Avatar);
        setText('hint-Avatar', d.AvatarHint);
        setText('lbl-Illustration', d.Illustration);
        setText('hint-Illustration', d.IllustrationHint);
        setText('hint-Export', d.ExportHint);
        setText('hint-WorldInfoOptional', d.WorldInfoOptional);
        setText('tab-character', d.TabCharacter);
        setText('tab-worldinfo', d.TabWorldInfo);
        setText('tab-meta', d.TabMeta);
        setText('tab-export', d.TabExport);
        setText('btn-AddEntry', d.AddEntry);
        setText('btn-ChooseAvatar', d.ChooseAvatar);
        setText('btn-RemoveAvatar', d.RemoveAvatar);
        setText('btn-ChooseIllustration', d.ChooseIllustration);
        setText('btn-RemoveIllustration', d.RemoveIllustration);
        setText('btn-DownloadLumenflow', d.ExportLumenflow);
        setText('btn-ImportLumenflow', d.ImportLumenflow);
        setText('btn-ExportXml', d.ExportXml);
        setText('btn-DownloadXml', d.DownloadXml);
        setText('btn-Clear', d.BtnClear);
        setText('btn-Copy', d.BtnCopy || '复制内容');
        setText('lbl-Draft', d.Draft);
        setText('btn-NewDraft', d.NewDraft);
        setText('btn-DuplicateDraft', d.DuplicateDraft);
        setText('btn-DeleteDraft', d.DeleteDraft);
        setText('btn-ImportWorldInfo', d.ImportWorldInfo);
        setText('btn-MergeWorldInfo', d.MergeWorldInfo);
        setText('btn-ExportWorldInfo', d.ExportWorldInfo);
        setText('lbl-WorldInfoTest', d.PreviewTest);
        setText('hint-WorldInfoTest', d.TestHint);
        setText('btn-RunWorldInfoTest', d.RunTest);
        setText('btn-SelectVisible', d.SelectVisible);
        setText('btn-ClearSelection', d.ClearSelection);
        setText('btn-EnableAll', d.EnableAll);
        setText('btn-DisableAll', d.DisableAll);
        setText('btn-EnableSelected', d.EnableSelected);
        setText('btn-DisableSelected', d.DisableSelected);
        setText('btn-DeleteSelected', d.DeleteSelected);
        const testInput = document.getElementById('WorldInfoTestInput');
        if (testInput) testInput.placeholder = d.TestPlaceholder;
        document.querySelectorAll('.preview-mode').forEach((button) => {
            const labels = {
                source: d.PreviewSource,
                card: d.PreviewCard,
                test: d.PreviewTest,
            };
            button.textContent = labels[button.dataset.previewMode] || '';
        });
        document.getElementById('btn-Clear').title = d.BtnClear;
        document.getElementById('btn-RemoveAvatar').disabled = !avatarDataUrl;
        document.getElementById('btn-RemoveIllustration').disabled =
            !illustrationDataUrl;
        const tagInput = document.getElementById('MetaTagInput');
        if (tagInput) tagInput.placeholder = d.TagInputPlaceholder;
        renderTagChips();
        renderIconGrid();
        window.LFWorldInfo.refreshLanguage();
        renderDraftPicker();
        updateTokenCount();
    }

    function handleLangChange() {
        currentLang = document.getElementById('lang-selector').value;
        window.LF_CURRENT_LANG = currentLang;
        applyLanguageUI();
        triggerAutoSave();
    }
    window.handleLangChange = handleLangChange;

    function initDragAndDrop() {
        window.addEventListener('dragover', (event) => {
            event.preventDefault();
            document.body.classList.add('drag-over');
        });
        window.addEventListener('dragleave', (event) => {
            if (event.clientX === 0 && event.clientY === 0) {
                document.body.classList.remove('drag-over');
            }
        });
        window.addEventListener('drop', (event) => {
            event.preventDefault();
            document.body.classList.remove('drag-over');
            const files = event.dataTransfer && event.dataTransfer.files;
            if (!files || files.length === 0) return;
            const file = files[0];
            const lower = file.name.toLowerCase();
            if (lower.endsWith('.lumenflow')) {
                const reader = new FileReader();
                reader.onload = (e) => importArchive(e.target.result);
                reader.readAsArrayBuffer(file);
            } else if (lower.endsWith('.xml')) {
                const reader = new FileReader();
                reader.onload = (e) => {
                    const legacy = parseAndFillXML(e.target.result, file.name, false);
                    if (legacy && legacy.trim()) {
                        window.LFWorldInfo.reset();
                        window.LFWorldInfo.importLegacyBackground(legacy);
                        const roleName = document.getElementById('RoleName').value.trim();
                        const nameEl = document.getElementById('WorldInfoName');
                        if (roleName && !nameEl.value.trim()) {
                            nameEl.value = roleName;
                            nameEl.dispatchEvent(new Event('input', { bubbles: true }));
                        }
                        showToast(dict().LegacyBackgroundImported);
                    } else if (legacy !== null) {
                        window.LFWorldInfo.reset();
                    }
                };
                reader.readAsText(file);
            }
        });
    }

    function handleWorldInfoFile(file, mode) {
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (event) => {
            try {
                const data = JSON.parse(String(event.target.result || ''));
                if (
                    !data ||
                    data._format !== 'lumenflow_world_info' ||
                    !Array.isArray(data.entries)
                ) {
                    throw new Error('invalid');
                }
                if (mode === 'merge') {
                    const count = window.LFWorldInfo.mergeData(data);
                    showToast(
                        dict().WorldInfoMerged.replace('{count}', count)
                    );
                } else {
                    window.LFWorldInfo.replaceData(data);
                    showToast(
                        dict().WorldInfoImported.replace(
                            '{count}',
                            data.entries.length
                        )
                    );
                }
            } catch (error) {
                console.error(error);
                showToast(dict().WorldInfoImportInvalid);
            }
        };
        reader.readAsText(file);
    }

    function downloadWorldInfo() {
        const data = window.LFWorldInfo.getData();
        const blob = new Blob([JSON.stringify(data, null, 2)], {
            type: 'application/json;charset=utf-8',
        });
        const rawName = String(data.name || '').trim();
        const name = rawName
            ? `${safeFileName(rawName)}.world_info.json`
            : 'world_info.json';
        downloadBlob(blob, name);
    }

    async function init() {
        currentLang = 'zh';
        window.LF_CURRENT_LANG = currentLang;
        window.LFWorldInfo.init(() => {
            triggerAutoSave();
            updateTokenCount();
        });

        document.querySelectorAll('.tab-button').forEach((button) => {
            button.addEventListener('click', () => switchTab(button.dataset.tab));
        });

        document.querySelectorAll('.preview-mode').forEach((button) => {
            button.addEventListener('click', () =>
                setPreviewMode(button.dataset.previewMode)
            );
        });
        document.getElementById('DraftSelect')?.addEventListener('change', (event) => {
            switchDraft(event.target.value);
        });
        document.getElementById('btn-NewDraft')?.addEventListener('click', createNewDraft);
        document.getElementById('btn-DuplicateDraft')?.addEventListener(
            'click',
            duplicateCurrentDraft
        );
        document.getElementById('btn-DeleteDraft')?.addEventListener(
            'click',
            deleteCurrentDraft
        );
        const tokenBox = document.getElementById('token-box');
        tokenBox?.addEventListener('click', (event) => {
            event.stopPropagation();
            toggleTokenBreakdown();
        });
        tokenBox?.addEventListener('keydown', (event) => {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                toggleTokenBreakdown();
            }
        });
        document.addEventListener('click', (event) => {
            const popover = document.getElementById('TokenBreakdown');
            if (
                popover &&
                !popover.hidden &&
                !popover.contains(event.target) &&
                !tokenBox?.contains(event.target)
            ) {
                toggleTokenBreakdown(false);
            }
        });
        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') toggleTokenBreakdown(false);
        });
        const testInput = document.getElementById('WorldInfoTestInput');
        if (testInput) {
            testInput.addEventListener('input', () => {
                clearTimeout(testInputTimeout);
                testInputTimeout = setTimeout(() => {
                    if (previewMode === 'test') renderActivationTest();
                }, 400);
            });
        }
        const runTest = document.getElementById('btn-RunWorldInfoTest');
        if (runTest) {
            runTest.addEventListener('click', () => {
                if (previewMode !== 'test') {
                    setPreviewMode('test');
                } else {
                    renderActivationTest();
                }
            });
        }

        const worldInfoFile = document.getElementById('WorldInfoFileInput');
        document.getElementById('btn-ImportWorldInfo')?.addEventListener(
            'click',
            () => {
                pendingWorldInfoImportMode = 'replace';
                worldInfoFile?.click();
            }
        );
        document.getElementById('btn-MergeWorldInfo')?.addEventListener(
            'click',
            () => {
                pendingWorldInfoImportMode = 'merge';
                worldInfoFile?.click();
            }
        );
        document
            .getElementById('btn-ExportWorldInfo')
            ?.addEventListener('click', downloadWorldInfo);
        worldInfoFile?.addEventListener('change', (event) => {
            const file = event.target.files[0];
            if (file) {
                handleWorldInfoFile(file, pendingWorldInfoImportMode);
            }
            event.target.value = '';
        });

        const tagChips = document.getElementById('MetaTagsChips');
        tagChips?.addEventListener('click', (event) => {
            const remove = event.target.closest('[data-remove-tag]');
            if (remove) {
                removeMetaTag(Number(remove.dataset.removeTag));
            }
        });
        const tagInput = document.getElementById('MetaTagInput');
        tagInput?.addEventListener('keydown', (event) => {
            if (event.key === 'Enter' || event.key === ',') {
                event.preventDefault();
                addMetaTag(tagInput.value);
            } else if (
                event.key === 'Backspace' &&
                !tagInput.value &&
                splitTags(document.getElementById('MetaTags').value).length
            ) {
                removeMetaTag(
                    splitTags(document.getElementById('MetaTags').value).length - 1
                );
            }
        });
        tagInput?.addEventListener('blur', () => {
            if (tagInput.value.trim()) addMetaTag(tagInput.value);
        });
        const iconGrid = document.getElementById('MetaIconGrid');
        iconGrid?.addEventListener('click', (event) => {
            const choice = event.target.closest('[data-icon]');
            if (!choice) return;
            document.getElementById('MetaIcon').value = choice.dataset.icon;
            renderIconGrid();
            updatePreview();
            triggerAutoSave();
        });

        document.querySelectorAll('#panel-character input, #panel-character textarea, #panel-meta input, #panel-meta select, #panel-meta textarea')
            .forEach((element) => {
                element.addEventListener('input', () => {
                    if (element.tagName === 'TEXTAREA') autoResizeTextarea(element);
                    if (element.id === 'RoleName') syncMetaName();
                    updateTokenCount();
                    triggerAutoSave();
                });
            });
        document.getElementById('FileName').addEventListener('input', triggerAutoSave);
        document.getElementById('lang-selector').addEventListener('change', handleLangChange);
        document.getElementById('btn-Clear').addEventListener('click', clearForm);
        document.getElementById('btn-Copy').addEventListener('click', copyToClipboard);
        document.getElementById('btn-ExportXml').addEventListener('click', () => {
            const preview = document.getElementById('preview-section');
            preview.classList.add('active');
            preview.scrollIntoView({ behavior: 'smooth' });
            updateTokenCount();
        });
        document.getElementById('btn-DownloadXml').addEventListener('click', downloadXml);
        document.getElementById('btn-DownloadLumenflow').addEventListener('click', exportArchive);
        document.getElementById('btn-ImportLumenflow').addEventListener('click', () => {
            document.getElementById('file-import').click();
        });
        document.getElementById('file-import').addEventListener('change', handleFileImport);
        document.getElementById('btn-ChooseAvatar').addEventListener('click', () => {
            document.getElementById('AvatarInput').click();
        });
        document.getElementById('AvatarInput').addEventListener('change', (event) => {
            const file = event.target.files[0];
            if (file) handleAvatarFile(file);
            event.target.value = '';
        });
        document.getElementById('btn-RemoveAvatar').addEventListener('click', () => clearAvatar());
        document.getElementById('btn-ChooseIllustration').addEventListener('click', () => {
            document.getElementById('IllustrationInput').click();
        });
        document.getElementById('IllustrationInput').addEventListener('change', (event) => {
            const file = event.target.files[0];
            if (file) handleIllustrationFile(file);
            event.target.value = '';
        });
        document.getElementById('btn-RemoveIllustration').addEventListener('click', () =>
            clearIllustration()
        );

        document
            .getElementById('AdvancedOptionsPanel')
            ?.addEventListener('toggle', triggerAutoSave);

        // World info fields also autosave and live-preview.
        ['WorldInfoName', 'WorldInfoDescription', 'WorldInfoBackground',
            'WorldInfoScanDepth', 'WorldInfoBudget'].forEach((id) => {
            const el = document.getElementById(id);
            if (el) {
                el.addEventListener('input', () => {
                    if (el.tagName === 'TEXTAREA') autoResizeTextarea(el);
                    triggerAutoSave();
                });
            }
        });

        initDragAndDrop();
        const loadedDraft = await initializeDrafts();
        if (loadedDraft) {
            applyDraftData(loadedDraft);
        } else {
            loadFromLocalStorage();
        }
        await refreshAfterDraftLoad();
    }

    function copyToClipboard() {
        const content = buildPreviewText();
        const d = dict();
        const fallbackCopy = (text) => {
            const textarea = document.createElement('textarea');
            textarea.value = text;
            textarea.style.position = 'fixed';
            textarea.style.left = '-9999px';
            document.body.appendChild(textarea);
            textarea.focus();
            textarea.select();
            try {
                showToast(document.execCommand('copy') ? d.Copied : d.CopyFail);
            } catch (_) {
                showToast(d.CopyFail);
            }
            document.body.removeChild(textarea);
        };
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard
                .writeText(content)
                .then(() => showToast(d.Copied))
                .catch(() => fallbackCopy(content));
        } else {
            fallbackCopy(content);
        }
    }

    function downloadXml() {
        const xml = buildExportableXML();
        if (xml === null) return;
        let fileName = document.getElementById('FileName').value.trim();
        if (!fileName) fileName = safeFileName(document.getElementById('MetaName').value);
        fileName = fileName.replace(/\.(xml|lumenflow)$/i, '') + '.xml';
        downloadBlob(new Blob([xml], { type: 'text/xml;charset=utf-8' }), fileName);
    }

    init().catch((error) => {
        console.error('Generator init failed:', error);
        showToast(error.message || 'Generator init failed');
    });
})();
