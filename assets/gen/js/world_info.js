/* World info editor for the LumenFlow generator. */
(function () {
    const CATEGORIES = ['character', 'location', 'item', 'rule', 'event', 'lore', 'other'];
    const MATCHES = ['substring', 'word', 'regex'];

    const state = {
        name: '',
        description: '',
        background: '',
        scanDepth: 4,
        budgetTokens: 1000,
        entries: []
    };

    let onChange = function () {};
    let nextId = 1;

    function dict() {
        return window.LF_I18N[window.LF_CURRENT_LANG || 'zh'] || window.LF_I18N.zh;
    }

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function splitKeys(value) {
        return String(value || '')
            .split(/[,，]/)
            .map((item) => item.trim())
            .filter((item) => item.length > 0);
    }

    function newEntry() {
        let id;
        do {
            id = 'entry-' + Date.now().toString(36) + '-' + (nextId++).toString(36);
        } while (state.entries.some((entry) => entry.id === id));
        return {
            id,
            title: '',
            category: 'other',
            tags: [],
            keys: [],
            secondaryKeys: [],
            match: 'substring',
            caseSensitive: false,
            content: '',
            priority: 0,
            enabled: true,
            position: 'system',
            depth: 0
        };
    }

    function categoryLabel(value) {
        const d = dict();
        return {
            character: d.CategoryCharacter,
            location: d.CategoryLocation,
            item: d.CategoryItem,
            rule: d.CategoryRule,
            event: d.CategoryEvent,
            lore: d.CategoryLore,
            other: d.CategoryOther
        }[value] || value;
    }

    function matchLabel(value) {
        const d = dict();
        return {
            substring: d.MatchSubstring,
            word: d.MatchWord,
            regex: d.MatchRegex
        }[value] || value;
    }

    function entryTemplate(entry, index) {
        const d = dict();
        const option = (values, selected, labelFn) =>
            values
                .map(
                    (value) =>
                        `<option value="${value}" ${value === selected ? 'selected' : ''}>${escapeHtml(
                            labelFn(value)
                        )}</option>`
                )
                .join('');
        return `
        <div class="wi-entry" data-entry-index="${index}">
            <div class="wi-entry-head">
                <input type="text" data-wi-field="title" value="${escapeHtml(entry.title)}"
                    placeholder="${escapeHtml(d.EntryTitle)}">
                <button type="button" class="wi-remove" data-remove-entry title="${escapeHtml(d.DeleteEntry)}">×</button>
            </div>
            <div class="form-grid">
                <div class="form-group">
                    <label>${escapeHtml(d.EntryCategory)}</label>
                    <select data-wi-field="category">${option(CATEGORIES, entry.category, categoryLabel)}</select>
                </div>
                <div class="form-group">
                    <label>${escapeHtml(d.EntryMatch)}</label>
                    <select data-wi-field="match">${option(MATCHES, entry.match, matchLabel)}</select>
                </div>
            </div>
            <div class="form-group">
                <label>${escapeHtml(d.EntryKeys)}</label>
                <input type="text" data-wi-field="keys" value="${escapeHtml(entry.keys.join(', '))}">
            </div>
            <div class="form-group">
                <label>${escapeHtml(d.EntrySecondaryKeys)}</label>
                <input type="text" data-wi-field="secondaryKeys" value="${escapeHtml(
                    entry.secondaryKeys.join(', ')
                )}">
            </div>
            <div class="form-grid">
                <div class="form-group">
                    <label>${escapeHtml(d.EntryPriority)}</label>
                    <input type="number" data-wi-field="priority" value="${Number(entry.priority) || 0}">
                </div>
                <div class="form-group wi-enabled">
                    <label>
                        <input type="checkbox" data-wi-field="enabled" ${entry.enabled ? 'checked' : ''}>
                        ${escapeHtml(d.EntryEnabled)}
                    </label>
                </div>
            </div>
            <div class="form-group">
                <label>${escapeHtml(d.EntryContent)}</label>
                <textarea data-wi-field="content">${escapeHtml(entry.content)}</textarea>
            </div>
        </div>`;
    }

    function renderEntries() {
        const container = document.getElementById('WorldInfoEntries');
        if (!container) return;
        const d = dict();
        if (state.entries.length === 0) {
            container.innerHTML = `<p class="wi-empty">${escapeHtml(d.NoEntries)}</p>`;
            return;
        }
        container.innerHTML = state.entries
            .map((entry, index) => entryTemplate(entry, index))
            .join('');
    }

    function readEntryField(card, field, target) {
        const index = Number(card.dataset.entryIndex);
        const entry = state.entries[index];
        if (!entry) return;
        if (field === 'keys' || field === 'secondaryKeys') {
            entry[field] = splitKeys(target.value);
        } else if (field === 'priority') {
            entry.priority = Number(target.value) || 0;
        } else if (field === 'enabled') {
            entry.enabled = Boolean(target.checked);
        } else {
            entry[field] = target.value;
        }
        onChange();
    }

    function bind() {
        const background = document.getElementById('WorldInfoBackground');
        const name = document.getElementById('WorldInfoName');
        const description = document.getElementById('WorldInfoDescription');
        const scanDepth = document.getElementById('WorldInfoScanDepth');
        const budget = document.getElementById('WorldInfoBudget');
        const entries = document.getElementById('WorldInfoEntries');
        const add = document.getElementById('btn-AddEntry');

        if (background) {
            background.addEventListener('input', () => {
                state.background = background.value;
                onChange();
            });
        }
        if (name) {
            name.addEventListener('input', () => {
                state.name = name.value;
                onChange();
            });
        }
        if (description) {
            description.addEventListener('input', () => {
                state.description = description.value;
                onChange();
            });
        }
        if (scanDepth) {
            scanDepth.addEventListener('input', () => {
                state.scanDepth = Math.max(0, Number(scanDepth.value) || 0);
                onChange();
            });
        }
        if (budget) {
            budget.addEventListener('input', () => {
                state.budgetTokens = Math.max(0, Number(budget.value) || 0);
                onChange();
            });
        }
        if (add) {
            add.addEventListener('click', () => {
                state.entries.push(newEntry());
                renderEntries();
                onChange();
                const cards = document.querySelectorAll('.wi-entry');
                const last = cards[cards.length - 1];
                if (last) {
                    const input = last.querySelector('[data-wi-field="title"]');
                    if (input) input.focus();
                }
            });
        }
        if (entries) {
            entries.addEventListener('input', (event) => {
                const card = event.target.closest('[data-entry-index]');
                const field = event.target.dataset.wiField;
                if (card && field) readEntryField(card, field, event.target);
            });
            entries.addEventListener('change', (event) => {
                const card = event.target.closest('[data-entry-index]');
                const field = event.target.dataset.wiField;
                if (card && field) readEntryField(card, field, event.target);
            });
            entries.addEventListener('click', (event) => {
                const remove = event.target.closest('[data-remove-entry]');
                if (!remove) return;
                const card = remove.closest('[data-entry-index]');
                const index = Number(card.dataset.entryIndex);
                state.entries.splice(index, 1);
                renderEntries();
                onChange();
            });
        }
    }

    function fillForm() {
        const set = (id, value) => {
            const el = document.getElementById(id);
            if (el) el.value = value;
        };
        set('WorldInfoName', state.name);
        set('WorldInfoDescription', state.description);
        set('WorldInfoBackground', state.background);
        set('WorldInfoScanDepth', state.scanDepth);
        set('WorldInfoBudget', state.budgetTokens);
        renderEntries();
    }

    function setData(data) {
        if (!data || typeof data !== 'object') return;
        state.name = typeof data.name === 'string' ? data.name : '';
        state.description = typeof data.description === 'string' ? data.description : '';
        state.background = typeof data.background === 'string' ? data.background : '';
        state.scanDepth = Number.isFinite(Number(data.scan_depth)) ? Math.max(0, Number(data.scan_depth)) : 4;
        state.budgetTokens = Number.isFinite(Number(data.budget_tokens)) ? Math.max(0, Number(data.budget_tokens)) : 1000;
        const entries = Array.isArray(data.entries) ? data.entries : [];
        state.entries = entries.map((raw) => {
            const entry = newEntry();
            entry.id = typeof raw.id === 'string' && raw.id ? raw.id : entry.id;
            entry.title = typeof raw.title === 'string' ? raw.title : '';
            entry.category = CATEGORIES.includes(raw.category) ? raw.category : 'other';
            const cleanStrings = (value) =>
                Array.isArray(value)
                    ? value
                        .filter((item) => typeof item === 'string' && item.trim())
                        .map((item) => item.trim())
                    : [];
            entry.tags = cleanStrings(raw.tags);
            entry.keys = cleanStrings(raw.keys);
            entry.secondaryKeys = cleanStrings(raw.secondary_keys);
            entry.match = MATCHES.includes(raw.match) ? raw.match : 'substring';
            entry.caseSensitive = Boolean(raw.case_sensitive);
            entry.content = typeof raw.content === 'string' ? raw.content : '';
            entry.priority = Number.isFinite(Number(raw.priority)) ? Number(raw.priority) : 0;
            entry.enabled = raw.enabled !== false;
            entry.position = typeof raw.position === 'string' ? raw.position : 'system';
            entry.depth = Number.isFinite(Number(raw.depth)) ? Math.max(0, Number(raw.depth)) : 0;
            return entry;
        });
        fillForm();
    }

    function getData() {
        return {
            _format: 'lumenflow_world_info',
            _version: 1,
            name: state.name.trim(),
            description: state.description.trim(),
            background: state.background.trim(),
            scan_depth: Math.max(0, Math.trunc(Number(state.scanDepth) || 0)),
            budget_tokens: Math.max(0, Math.trunc(Number(state.budgetTokens) || 0)),
            entries: state.entries.map((entry) => ({
                id: entry.id,
                title: entry.title.trim(),
                category: entry.category,
                tags: entry.tags.filter((tag) => tag.trim()).map((tag) => tag.trim()),
                keys: entry.keys.filter((key) => key.trim()).map((key) => key.trim()),
                secondary_keys: entry.secondaryKeys
                    .filter((key) => key.trim())
                    .map((key) => key.trim()),
                match: entry.match,
                case_sensitive: entry.caseSensitive,
                content: entry.content.trim(),
                priority: Math.trunc(Number(entry.priority) || 0),
                enabled: entry.enabled,
                position: entry.position || 'system',
                depth: Math.max(0, Math.trunc(Number(entry.depth) || 0))
            }))
        };
    }

    function hasContent() {
        return state.background.trim().length > 0 || state.entries.length > 0;
    }

    function validate() {
        if (state.entries.length > 500) {
            return { code: 'TooManyEntries' };
        }
        const ids = new Set();
        for (const entry of state.entries) {
            if (ids.has(entry.id)) {
                return { code: 'DuplicateId', title: entry.title };
            }
            ids.add(entry.id);
            if (entry.keys.length === 0) {
                return { code: 'MissingKeys', title: entry.title };
            }
            if (entry.keys.length > 20 || entry.secondaryKeys.length > 20) {
                return { code: 'TooManyKeys', title: entry.title };
            }
            if (entry.match === 'regex') {
                for (const key of entry.keys.concat(entry.secondaryKeys)) {
                    if (key.length > 200) return { code: 'RegexTooLong', title: entry.title };
                    try {
                        new RegExp(key, entry.caseSensitive ? '' : 'i');
                    } catch (_) {
                        return { code: 'InvalidRegex', title: entry.title };
                    }
                }
            }
            if (entry.content.length > 4000) {
                return { code: 'ContentTooLong', title: entry.title };
            }
        }
        return null;
    }

    function importLegacyBackground(background) {
        if (!background || !background.trim()) return false;
        state.background = background.trim();
        fillForm();
        onChange();
        return true;
    }

    function reset() {
        state.name = '';
        state.description = '';
        state.background = '';
        state.scanDepth = 4;
        state.budgetTokens = 1000;
        state.entries = [];
        fillForm();
    }

    function init(callback) {
        if (typeof callback === 'function') onChange = callback;
        bind();
        fillForm();
    }

    function refreshLanguage() {
        renderEntries();
    }

    window.LFWorldInfo = {
        init,
        refreshLanguage,
        setData,
        getData,
        hasContent,
        validate,
        importLegacyBackground,
        reset,
        render: renderEntries
    };
})();
