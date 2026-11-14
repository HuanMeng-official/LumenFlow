/* World info editor for the LumenFlow generator. */
(function () {
    const CATEGORIES = ['character', 'location', 'item', 'rule', 'event', 'lore', 'other'];
    const MATCHES = ['substring', 'word', 'regex'];
    const POSITIONS = ['system', 'before_preset', 'after_preset', 'at_depth'];

    const state = {
        name: '',
        description: '',
        background: '',
        scanDepth: 4,
        budgetTokens: 1000,
        minActivations: 0,
        recursionDepth: 0,
        entries: [],
        activeEntryId: ''
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
            depth: 0,
            group: '',
            probability: 100,
            recursive: false,
            sticky: 0,
            cooldown: 0
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

    function positionLabel(value) {
        const d = dict();
        return {
            system: d.PositionSystem,
            before_preset: d.PositionBeforePreset,
            after_preset: d.PositionAfterPreset,
            at_depth: d.PositionAtDepth
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
        <div class="wi-entry${entry.id === state.activeEntryId ? ' is-active' : ''}" data-entry-index="${index}">
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
            <div class="form-grid">
                <div class="form-group">
                    <label>${escapeHtml(d.EntryPosition)}</label>
                    <select data-wi-field="position">${option(POSITIONS, entry.position, positionLabel)}</select>
                </div>
                <div class="form-group">
                    <label>${escapeHtml(d.EntryDepth)}</label>
                    <input type="number" min="0" max="1000" data-wi-field="depth"
                        value="${Number(entry.depth) || 0}">
                </div>
            </div>
            <div class="form-grid">
                <div class="form-group">
                    <label>${escapeHtml(d.EntryGroup)}</label>
                    <input type="text" data-wi-field="group" value="${escapeHtml(entry.group)}">
                </div>
                <div class="form-group">
                    <label>${escapeHtml(d.EntryProbability)}</label>
                    <input type="number" min="0" max="100" data-wi-field="probability"
                        value="${Number(entry.probability) || 0}">
                </div>
            </div>
            <div class="form-group">
                <label>${escapeHtml(d.EntryTags)}</label>
                <input type="text" data-wi-field="tags" value="${escapeHtml(entry.tags.join(', '))}">
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
                <div class="form-group">
                    <label>${escapeHtml(d.EntrySticky)}</label>
                    <input type="number" min="0" max="1000" data-wi-field="sticky"
                        value="${Number(entry.sticky) || 0}">
                </div>
            </div>
            <div class="form-grid">
                <div class="form-group">
                    <label>${escapeHtml(d.EntryCooldown)}</label>
                    <input type="number" min="0" max="1000" data-wi-field="cooldown"
                        value="${Number(entry.cooldown) || 0}">
                </div>
                <div class="form-group wi-enabled">
                    <label>
                        <input type="checkbox" data-wi-field="enabled" ${entry.enabled ? 'checked' : ''}>
                        ${escapeHtml(d.EntryEnabled)}
                    </label>
                </div>
            </div>
            <div class="form-group wi-flag-row">
                <label>
                    <input type="checkbox" data-wi-field="caseSensitive" ${entry.caseSensitive ? 'checked' : ''}>
                    ${escapeHtml(d.EntryCaseSensitive)}
                </label>
                <label>
                    <input type="checkbox" data-wi-field="recursive" ${entry.recursive ? 'checked' : ''}>
                    ${escapeHtml(d.EntryRecursive)}
                </label>
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
        if (window.LFSelect) window.LFSelect.enhanceAll(container);
    }

    function syncActiveEntryClasses() {
        document
            .querySelectorAll('#WorldInfoEntries .wi-entry')
            .forEach((card) => {
                const index = Number(card.dataset.entryIndex);
                card.classList.toggle(
                    'is-active',
                    state.entries[index]?.id === state.activeEntryId
                );
            });
    }

    function selectEntry(index, notify) {
        const entry = state.entries[index];
        const nextId = entry ? entry.id : '';
        if (state.activeEntryId === nextId) return;
        state.activeEntryId = nextId;
        syncActiveEntryClasses();
        if (notify !== false) onChange();
    }

    function clearActiveEntry() {
        if (!state.activeEntryId) return;
        state.activeEntryId = '';
        syncActiveEntryClasses();
    }

    function readEntryField(card, field, target) {
        const index = Number(card.dataset.entryIndex);
        const entry = state.entries[index];
        if (!entry) return;
        if (field === 'keys' || field === 'secondaryKeys' || field === 'tags') {
            entry[field] = splitKeys(target.value);
        } else if (
            ['priority', 'depth', 'probability', 'sticky', 'cooldown'].includes(field)
        ) {
            entry[field] = Math.max(0, Math.trunc(Number(target.value) || 0));
        } else if (['enabled', 'caseSensitive', 'recursive'].includes(field)) {
            entry[field] = Boolean(target.checked);
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
        const minActivations = document.getElementById('WorldInfoMinActivations');
        const recursionDepth = document.getElementById('WorldInfoRecursionDepth');
        const entries = document.getElementById('WorldInfoEntries');
        const add = document.getElementById('btn-AddEntry');

        const bindGlobalInput = (element, update) => {
            if (!element) return;
            element.addEventListener('input', () => {
                clearActiveEntry();
                update();
                onChange();
            });
        };

        bindGlobalInput(background, () => {
            state.background = background.value;
        });
        bindGlobalInput(name, () => {
            state.name = name.value;
        });
        bindGlobalInput(description, () => {
            state.description = description.value;
        });
        bindGlobalInput(scanDepth, () => {
            state.scanDepth = Math.max(0, Number(scanDepth.value) || 0);
        });
        bindGlobalInput(budget, () => {
            state.budgetTokens = Math.max(0, Number(budget.value) || 0);
        });
        bindGlobalInput(minActivations, () => {
            state.minActivations = Math.min(
                50,
                Math.max(0, Math.trunc(Number(minActivations.value) || 0))
            );
        });
        bindGlobalInput(recursionDepth, () => {
            state.recursionDepth = Math.min(
                10,
                Math.max(0, Math.trunc(Number(recursionDepth.value) || 0))
            );
        });

        if (add) {
            add.addEventListener('click', () => {
                const entry = newEntry();
                state.entries.push(entry);
                state.activeEntryId = entry.id;
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
            entries.addEventListener('focusin', (event) => {
                const card = event.target.closest('[data-entry-index]');
                if (card) selectEntry(Number(card.dataset.entryIndex));
            });
            entries.addEventListener('click', (event) => {
                const remove = event.target.closest('[data-remove-entry]');
                if (remove) {
                    const card = remove.closest('[data-entry-index]');
                    const index = Number(card.dataset.entryIndex);
                    const wasActive =
                        state.entries[index]?.id === state.activeEntryId;
                    state.entries.splice(index, 1);
                    if (wasActive) {
                        state.activeEntryId =
                            state.entries[
                                Math.min(index, state.entries.length - 1)
                            ]?.id || '';
                    }
                    renderEntries();
                    onChange();
                    return;
                }
                const card = event.target.closest('[data-entry-index]');
                if (card) selectEntry(Number(card.dataset.entryIndex));
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
        set('WorldInfoMinActivations', state.minActivations);
        set('WorldInfoRecursionDepth', state.recursionDepth);
        renderEntries();
    }

    function setData(data) {
        if (!data || typeof data !== 'object') return;
        state.name = typeof data.name === 'string' ? data.name : '';
        state.description = typeof data.description === 'string' ? data.description : '';
        state.background = typeof data.background === 'string' ? data.background : '';
        state.scanDepth = Number.isFinite(Number(data.scan_depth)) ? Math.max(0, Number(data.scan_depth)) : 4;
        state.budgetTokens = Number.isFinite(Number(data.budget_tokens)) ? Math.max(0, Number(data.budget_tokens)) : 1000;
        state.minActivations = Number.isFinite(Number(data.min_activations))
            ? Math.min(50, Math.max(0, Math.trunc(Number(data.min_activations))))
            : 0;
        state.recursionDepth = Number.isFinite(Number(data.recursion_depth))
            ? Math.min(10, Math.max(0, Math.trunc(Number(data.recursion_depth))))
            : 0;
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
            entry.position = POSITIONS.includes(raw.position) ? raw.position : 'system';
            entry.depth = Number.isFinite(Number(raw.depth))
                ? Math.min(1000, Math.max(0, Math.trunc(Number(raw.depth))))
                : 0;
            entry.group = typeof raw.group === 'string' ? raw.group : '';
            entry.probability = Number.isFinite(Number(raw.probability))
                ? Math.min(100, Math.max(0, Math.trunc(Number(raw.probability))))
                : 100;
            entry.recursive = Boolean(raw.recursive);
            entry.sticky = Number.isFinite(Number(raw.sticky))
                ? Math.min(1000, Math.max(0, Math.trunc(Number(raw.sticky))))
                : 0;
            entry.cooldown = Number.isFinite(Number(raw.cooldown))
                ? Math.min(1000, Math.max(0, Math.trunc(Number(raw.cooldown))))
                : 0;
            return entry;
        });
        if (!state.entries.some((entry) => entry.id === state.activeEntryId)) {
            state.activeEntryId = state.entries[0]?.id || '';
        }
        fillForm();
    }

    function serializeEntry(entry) {
        return {
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
            depth: Math.min(1000, Math.max(0, Math.trunc(Number(entry.depth) || 0))),
            group: (entry.group || '').trim(),
            probability: Math.min(
                100,
                Math.max(0, Math.trunc(Number(entry.probability) || 0))
            ),
            recursive: Boolean(entry.recursive),
            sticky: Math.min(1000, Math.max(0, Math.trunc(Number(entry.sticky) || 0))),
            cooldown: Math.min(
                1000,
                Math.max(0, Math.trunc(Number(entry.cooldown) || 0))
            )
        };
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
            min_activations: Math.min(
                50,
                Math.max(0, Math.trunc(Number(state.minActivations) || 0))
            ),
            recursion_depth: Math.min(
                10,
                Math.max(0, Math.trunc(Number(state.recursionDepth) || 0))
            ),
            entries: state.entries.map(serializeEntry)
        };
    }

    function hasContent() {
        return state.background.trim().length > 0 || state.entries.length > 0;
    }

    function validate() {
        if (state.entries.length > 500) {
            return { code: 'TooManyEntries' };
        }
        if (
            !Number.isFinite(Number(state.minActivations)) ||
            state.minActivations < 0 ||
            state.minActivations > 50
        ) {
            return { code: 'MinActivationsTooHigh' };
        }
        if (
            !Number.isFinite(Number(state.recursionDepth)) ||
            state.recursionDepth < 0 ||
            state.recursionDepth > 10
        ) {
            return { code: 'RecursionDepthTooHigh' };
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
            if (!POSITIONS.includes(entry.position)) {
                return { code: 'InvalidPosition', title: entry.title };
            }
            if (
                entry.depth < 0 ||
                entry.depth > 1000 ||
                entry.sticky < 0 ||
                entry.sticky > 1000 ||
                entry.cooldown < 0 ||
                entry.cooldown > 1000
            ) {
                return { code: 'InvalidTiming', title: entry.title };
            }
            if (entry.probability < 0 || entry.probability > 100) {
                return { code: 'InvalidProbability', title: entry.title };
            }
            if ((entry.group || '').length > 64) {
                return { code: 'GroupTooLong', title: entry.title };
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
        state.minActivations = 0;
        state.recursionDepth = 0;
        state.entries = [];
        state.activeEntryId = '';
        fillForm();
    }

    function getSelectedEntry() {
        if (!state.activeEntryId) return null;
        const entry = state.entries.find(
            (item) => item.id === state.activeEntryId
        );
        return entry ? serializeEntry(entry) : null;
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
        getSelectedEntry,
        hasContent,
        validate,
        importLegacyBackground,
        reset,
        render: renderEntries
    };
})();
