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
        activeEntryId: '',
        searchQuery: '',
        categoryFilter: 'all',
        collapsedEntryIds: new Set(),
        selectedEntryIds: new Set(),
    };

    let onChange = function () {};
    let nextId = 1;
    let bulkDeletePending = false;
    let bulkDeleteTimeout = null;

    function dict() {
        return window.LF_I18N[window.LF_CURRENT_LANG || 'zh'] || window.LF_I18N.zh;
    }

    function toast(message) {
        if (window.LFShowToast) window.LFShowToast(message);
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

    function runeLength(value) {
        return Array.from(String(value || '')).length;
    }

    function tokenCount(value) {
        if (window.LFWorldInfoEngine) {
            return window.LFWorldInfoEngine.estimateTokens(value);
        }
        return Math.ceil(String(value || '').length / 4);
    }

    function tokenLabel(value) {
        const d = dict();
        const template = d.EntryTokenCount || '{count} tokens';
        return template.replace('{count}', tokenCount(value));
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
            cooldown: 0,
            unlockStageIds: [],
            unlockMinIntimacy: '',
            unlockMaxIntimacy: '',
            unlockMetricsText: '',
            unlockHidden: false,
        };
    }

    function parseMetricConditionsText(text) {
        const list = [];
        const lines = String(text || '').split(/\r?\n/);
        for (const raw of lines) {
            const line = raw.trim();
            if (!line) continue;
            const match = /^([a-z][a-z0-9_]{0,31})\s*(>=|<=|>|<)\s*(-?\d+)$/.exec(line);
            if (!match) continue;
            list.push({
                metric: match[1],
                op: match[2],
                value: Math.trunc(Number(match[3])),
            });
        }
        return list;
    }

    function formatMetricConditionsText(conditions) {
        if (!Array.isArray(conditions)) return '';
        return conditions
            .filter((c) => c && typeof c.metric === 'string' && typeof c.op === 'string' && Number.isFinite(Number(c.value)))
            .map((c) => `${c.metric} ${c.op} ${Math.trunc(Number(c.value))}`)
            .join('\n');
    }

    function entryFromRaw(raw) {
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
        const unlock = raw.unlock && typeof raw.unlock === 'object' ? raw.unlock : null;
        if (unlock) {
            entry.unlockStageIds = cleanStrings(unlock.stage_ids || unlock.stageIds);
            const minInt = unlock.min_intimacy ?? unlock.minIntimacy;
            const maxInt = unlock.max_intimacy ?? unlock.maxIntimacy;
            entry.unlockMinIntimacy = Number.isFinite(Number(minInt)) && minInt !== '' && minInt !== null
                ? String(Math.trunc(Number(minInt)))
                : '';
            entry.unlockMaxIntimacy = Number.isFinite(Number(maxInt)) && maxInt !== '' && maxInt !== null
                ? String(Math.trunc(Number(maxInt)))
                : '';
            entry.unlockMetricsText = formatMetricConditionsText(
                unlock.metric_conditions || unlock.metricConditions
            );
            entry.unlockHidden = Boolean(
                unlock.hidden_until_unlocked ?? unlock.hiddenUntilUnlocked
            );
        }
        return entry;
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
            other: d.CategoryOther,
        }[value] || value;
    }

    function matchLabel(value) {
        const d = dict();
        return {
            substring: d.MatchSubstring,
            word: d.MatchWord,
            regex: d.MatchRegex,
        }[value] || value;
    }

    function positionLabel(value) {
        const d = dict();
        return {
            system: d.PositionSystem,
            before_preset: d.PositionBeforePreset,
            after_preset: d.PositionAfterPreset,
            at_depth: d.PositionAtDepth,
        }[value] || value;
    }

    function entryTemplate(entry, index) {
        const d = dict();
        const collapsed = state.collapsedEntryIds.has(entry.id);
        const selected = state.selectedEntryIds.has(entry.id);
        const option = (values, current, labelFn) =>
            values
                .map(
                    (value) =>
                        `<option value="${value}" ${value === current ? 'selected' : ''}>${escapeHtml(
                            labelFn(value)
                        )}</option>`
                )
                .join('');
        return `
        <div class="wi-entry${entry.id === state.activeEntryId ? ' is-active' : ''}${
            collapsed ? ' is-collapsed' : ''
        }${entry.enabled ? '' : ' is-disabled'}" data-entry-index="${index}">
            <div class="wi-entry-head">
                <input type="checkbox" class="wi-select" data-select-entry ${
                    selected ? 'checked' : ''
                } title="${escapeHtml(d.SelectEntry)}">
                <input type="text" data-wi-field="title" value="${escapeHtml(entry.title)}"
                    placeholder="${escapeHtml(d.EntryTitle)}">
                <span class="wi-entry-tokens" data-entry-tokens>${escapeHtml(
                    tokenLabel(entry.content)
                )}</span>
                <span class="wi-entry-status" data-entry-status></span>
                <div class="wi-entry-actions">
                    <button type="button" class="wi-action wi-collapse${
                        collapsed ? ' is-collapsed' : ''
                    }" data-toggle-entry title="${escapeHtml(
                        collapsed ? d.ExpandEntry : d.CollapseEntry
                    )}" aria-expanded="${!collapsed}">
                        <span></span>
                    </button>
                    <button type="button" class="wi-action wi-duplicate" data-duplicate-entry
                        title="${escapeHtml(d.DuplicateEntry)}">
                        <span></span>
                    </button>
                    <button type="button" class="wi-remove" data-remove-entry title="${escapeHtml(
                        d.DeleteEntry
                    )}">×</button>
                </div>
            </div>
            <div class="wi-entry-body">
                <div class="form-grid">
                    <div class="form-group">
                        <label>${escapeHtml(d.EntryCategory)}</label>
                        <select data-wi-field="category">${option(
                            CATEGORIES,
                            entry.category,
                            categoryLabel
                        )}</select>
                    </div>
                    <div class="form-group">
                        <label>${escapeHtml(d.EntryMatch)}</label>
                        <select data-wi-field="match">${option(
                            MATCHES,
                            entry.match,
                            matchLabel
                        )}</select>
                    </div>
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label>${escapeHtml(d.EntryPosition)}</label>
                        <select data-wi-field="position">${option(
                            POSITIONS,
                            entry.position,
                            positionLabel
                        )}</select>
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
                        <input type="text" data-wi-field="group" value="${escapeHtml(
                            entry.group
                        )}">
                    </div>
                    <div class="form-group">
                        <label>${escapeHtml(d.EntryProbability)}</label>
                        <input type="number" min="0" max="100" data-wi-field="probability"
                            value="${Number(entry.probability) || 0}">
                    </div>
                </div>
                <div class="form-group">
                    <label>${escapeHtml(d.EntryTags)}</label>
                    <input type="text" data-wi-field="tags" value="${escapeHtml(
                        entry.tags.join(', ')
                    )}">
                </div>
                <div class="form-group">
                    <label>${escapeHtml(d.EntryKeys)}</label>
                    <input type="text" data-wi-field="keys" value="${escapeHtml(
                        entry.keys.join(', ')
                    )}">
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
                        <input type="number" data-wi-field="priority" value="${
                            Number(entry.priority) || 0
                        }">
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
                            <input type="checkbox" data-wi-field="enabled" ${
                                entry.enabled ? 'checked' : ''
                            }>
                            ${escapeHtml(d.EntryEnabled)}
                        </label>
                    </div>
                </div>
                <div class="form-group wi-flag-row">
                    <label>
                        <input type="checkbox" data-wi-field="caseSensitive" ${
                            entry.caseSensitive ? 'checked' : ''
                        }>
                        ${escapeHtml(d.EntryCaseSensitive)}
                    </label>
                    <label>
                        <input type="checkbox" data-wi-field="recursive" ${
                            entry.recursive ? 'checked' : ''
                        }>
                        ${escapeHtml(d.EntryRecursive)}
                    </label>
                </div>
                <div class="form-group">
                    <label>${escapeHtml(d.EntryContent)}</label>
                    <textarea data-wi-field="content">${escapeHtml(entry.content)}</textarea>
                </div>
                <details class="wi-unlock-details"${
                    (entry.unlockStageIds && entry.unlockStageIds.length) ||
                    entry.unlockMinIntimacy !== '' ||
                    entry.unlockMaxIntimacy !== '' ||
                    (entry.unlockMetricsText && entry.unlockMetricsText.trim()) ||
                    entry.unlockHidden
                        ? ' open'
                        : ''
                }>
                    <summary>${escapeHtml(d.UnlockTitle || '成长解锁门控（可选）')}</summary>
                    <div class="wi-unlock-body">
                        <div class="form-group">
                            <label>${escapeHtml(d.UnlockStages || '允许解锁的阶段 ID（逗号分隔）')}</label>
                            <input type="text" data-wi-field="unlockStageIds" value="${escapeHtml(
                                (entry.unlockStageIds || []).join(', ')
                            )}" placeholder="white_noise, unguarded_trust">
                        </div>
                        <div class="form-grid">
                            <div class="form-group">
                                <label>${escapeHtml(d.UnlockMinIntimacy || '最低亲密度')}</label>
                                <input type="number" min="0" max="100" data-wi-field="unlockMinIntimacy"
                                    value="${escapeHtml(entry.unlockMinIntimacy ?? '')}" placeholder="0-100">
                            </div>
                            <div class="form-group">
                                <label>${escapeHtml(d.UnlockMaxIntimacy || '最高亲密度')}</label>
                                <input type="number" min="0" max="100" data-wi-field="unlockMaxIntimacy"
                                    value="${escapeHtml(entry.unlockMaxIntimacy ?? '')}" placeholder="0-100">
                            </div>
                        </div>
                        <div class="form-group">
                            <label>${escapeHtml(d.UnlockMetrics || '自定义指标门槛（每行一条：guard <= 50）')}</label>
                            <textarea class="compact" data-wi-field="unlockMetricsText"
                                placeholder="guard <= 50">${escapeHtml(entry.unlockMetricsText || '')}</textarea>
                        </div>
                        <div class="form-group wi-flag-row">
                            <label>
                                <input type="checkbox" data-wi-field="unlockHidden" ${
                                    entry.unlockHidden ? 'checked' : ''
                                }>
                                ${escapeHtml(d.UnlockHidden || '未解锁前对玩家隐藏（防剧透）')}
                            </label>
                        </div>
                    </div>
                </details>
            </div>
        </div>`;
    }

    function renderCategoryFilter() {
        const container = document.getElementById('WorldInfoCategoryFilter');
        if (!container) return;
        const d = dict();
        const values = ['all', ...CATEGORIES];
        container.innerHTML = values
            .map((value) => {
                const active = state.categoryFilter === value;
                const label =
                    value === 'all' ? d.AllCategories : categoryLabel(value);
                return `<button type="button" class="wi-filter-chip${
                    active ? ' is-active' : ''
                }" data-category="${value}" aria-pressed="${active}">${escapeHtml(
                    label
                )}</button>`;
            })
            .join('');
    }

    function applyEntryFilter() {
        const cards = document.querySelectorAll('#WorldInfoEntries .wi-entry');
        const query = state.searchQuery.trim().toLowerCase();
        let visible = 0;
        cards.forEach((card) => {
            const index = Number(card.dataset.entryIndex);
            const entry = state.entries[index];
            if (!entry) return;
            const categoryText = categoryLabel(entry.category);
            const haystack = [
                entry.title,
                entry.category,
                categoryText,
                entry.content,
                entry.group,
                ...entry.tags,
                ...entry.keys,
                ...entry.secondaryKeys,
            ]
                .join(' ')
                .toLowerCase();
            const matchesSearch = !query || haystack.includes(query);
            const matchesCategory =
                state.categoryFilter === 'all' ||
                entry.category === state.categoryFilter;
            const isVisible = matchesSearch && matchesCategory;
            card.classList.toggle('is-filtered-out', !isVisible);
            if (isVisible) visible++;
        });

        const total = state.entries.length;
        const count = document.getElementById('WorldInfoFilterCount');
        if (count) count.textContent = `${visible} / ${total}`;
        const empty = document.getElementById('WorldInfoFilterEmpty');
        if (empty) {
            const showEmpty = total > 0 && visible === 0;
            empty.hidden = !showEmpty;
            empty.textContent = dict().NoMatchingEntries;
        }
        const hasEntries = total > 0;
        const tools = document.getElementById('WorldInfoTools');
        const chips = document.getElementById('WorldInfoCategoryFilter');
        const bulk = document.getElementById('WorldInfoBulkBar');
        if (tools) tools.hidden = !hasEntries;
        if (chips) chips.hidden = !hasEntries;
        if (bulk) bulk.hidden = !hasEntries;
    }

    function syncSelectionCheckboxes() {
        document
            .querySelectorAll('#WorldInfoEntries .wi-entry')
            .forEach((card) => {
                const index = Number(card.dataset.entryIndex);
                const entry = state.entries[index];
                const checkbox = card.querySelector('[data-select-entry]');
                if (entry && checkbox) {
                    checkbox.checked = state.selectedEntryIds.has(entry.id);
                }
            });
    }

    function allEntriesCollapsed() {
        return (
            state.entries.length > 0 &&
            state.entries.every((entry) =>
                state.collapsedEntryIds.has(entry.id)
            )
        );
    }

    function updateBulkBar() {
        const d = dict();
        const bar = document.getElementById('WorldInfoBulkBar');
        const count = state.selectedEntryIds.size;
        if (bar) bar.classList.toggle('has-selection', count > 0);
        const label = document.getElementById('WorldInfoSelectionCount');
        if (label) {
            label.textContent = (d.SelectedCount || '已选 {count} 项').replace(
                '{count}',
                count
            );
        }
        const ids = [
            'btn-EnableSelected',
            'btn-DisableSelected',
            'btn-DeleteSelected',
            'btn-ClearSelection',
        ];
        ids.forEach((id) => {
            const button = document.getElementById(id);
            if (button) button.disabled = count === 0;
        });
        const collapse = document.getElementById('btn-ToggleCollapseAll');
        if (collapse) {
            collapse.textContent = allEntriesCollapsed()
                ? d.ExpandAll || '展开全部'
                : d.CollapseAll || '折叠全部';
        }
    }

    function renderEntries() {
        const container = document.getElementById('WorldInfoEntries');
        if (!container) return;
        const d = dict();
        if (state.entries.length === 0) {
            container.innerHTML = `<p class="wi-empty">${escapeHtml(
                d.NoEntries
            )}</p>`;
        } else {
            container.innerHTML = state.entries
                .map((entry, index) => entryTemplate(entry, index))
                .join('');
            if (window.LFSelect) window.LFSelect.enhanceAll(container);
        }
        renderCategoryFilter();
        applyEntryFilter();
        syncSelectionCheckboxes();
        updateBulkBar();
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

    function updateEntryTokenBadge(card, entry) {
        const badge = card.querySelector('[data-entry-tokens]');
        if (badge) badge.textContent = tokenLabel(entry.content);
    }

    function readEntryField(card, field, target) {
        const index = Number(card.dataset.entryIndex);
        const entry = state.entries[index];
        if (!entry) return;
        if (field === 'keys' || field === 'secondaryKeys' || field === 'tags' || field === 'unlockStageIds') {
            entry[field] = splitKeys(target.value);
        } else if (
            ['priority', 'depth', 'probability', 'sticky', 'cooldown'].includes(field)
        ) {
            entry[field] = Math.max(0, Math.trunc(Number(target.value) || 0));
        } else if (['enabled', 'caseSensitive', 'recursive', 'unlockHidden'].includes(field)) {
            entry[field] = Boolean(target.checked);
        } else if (field === 'unlockMinIntimacy' || field === 'unlockMaxIntimacy') {
            const raw = String(target.value || '').trim();
            entry[field] = raw === '' ? '' : String(Math.min(100, Math.max(0, Math.trunc(Number(raw) || 0))));
        } else {
            entry[field] = target.value;
        }
        if (field === 'content') updateEntryTokenBadge(card, entry);
        onChange();
    }

    function toggleSelection(index, selected) {
        const entry = state.entries[index];
        if (!entry) return;
        if (selected) state.selectedEntryIds.add(entry.id);
        else state.selectedEntryIds.delete(entry.id);
        syncSelectionCheckboxes();
        updateBulkBar();
    }

    function toggleCollapse(index) {
        const entry = state.entries[index];
        if (!entry) return;
        if (state.collapsedEntryIds.has(entry.id)) {
            state.collapsedEntryIds.delete(entry.id);
        } else {
            state.collapsedEntryIds.add(entry.id);
        }
        const card = document.querySelector(
            `#WorldInfoEntries .wi-entry[data-entry-index="${index}"]`
        );
        if (card) {
            const collapsed = state.collapsedEntryIds.has(entry.id);
            card.classList.toggle('is-collapsed', collapsed);
            const button = card.querySelector('[data-toggle-entry]');
            if (button) {
                button.classList.toggle('is-collapsed', collapsed);
                button.setAttribute('aria-expanded', String(!collapsed));
                button.title = collapsed
                    ? dict().ExpandEntry
                    : dict().CollapseEntry;
            }
        }
        updateBulkBar();
    }

    function duplicateEntry(index) {
        const entry = state.entries[index];
        if (!entry) return;
        const copy = {
            ...entry,
            id: newEntry().id,
            title: entry.title.trim()
                ? `${entry.title.trim()} ${dict().CopySuffix || '(copy)'}`
                : dict().CopySuffix || '(copy)',
            tags: [...entry.tags],
            keys: [...entry.keys],
            secondaryKeys: [...entry.secondaryKeys],
            unlockStageIds: [...(entry.unlockStageIds || [])],
        };
        state.entries.splice(index + 1, 0, copy);
        state.activeEntryId = copy.id;
        renderEntries();
        onChange();
        const card = document.querySelector(
            `#WorldInfoEntries .wi-entry[data-entry-index="${index + 1}"]`
        );
        if (card) {
            const input = card.querySelector('[data-wi-field="title"]');
            if (input) input.focus();
            card.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }
    }

    function removeEntry(index) {
        const entry = state.entries[index];
        if (!entry) return;
        const wasActive = entry.id === state.activeEntryId;
        state.selectedEntryIds.delete(entry.id);
        state.collapsedEntryIds.delete(entry.id);
        state.entries.splice(index, 1);
        if (wasActive) {
            state.activeEntryId =
                state.entries[Math.min(index, state.entries.length - 1)]?.id ||
                '';
        }
        renderEntries();
        onChange();
    }

    function visibleEntryIds() {
        return Array.from(
            document.querySelectorAll(
                '#WorldInfoEntries .wi-entry:not(.is-filtered-out)'
            )
        )
            .map((card) =>
                state.entries[Number(card.dataset.entryIndex)]?.id
            )
            .filter(Boolean);
    }

    function setSelected(ids, selected) {
        ids.forEach((id) => {
            if (selected) state.selectedEntryIds.add(id);
            else state.selectedEntryIds.delete(id);
        });
        syncSelectionCheckboxes();
        updateBulkBar();
    }

    function setEntriesEnabled(indexes, enabled) {
        indexes.forEach((index) => {
            const entry = state.entries[index];
            if (entry) entry.enabled = enabled;
        });
        renderEntries();
        onChange();
    }

    function deleteSelectedEntries() {
        if (state.selectedEntryIds.size === 0) return;
        if (!bulkDeletePending) {
            bulkDeletePending = true;
            const button = document.getElementById('btn-DeleteSelected');
            if (button) button.classList.add('pending');
            toast(dict().ConfirmDeleteSelected);
            clearTimeout(bulkDeleteTimeout);
            bulkDeleteTimeout = setTimeout(() => {
                bulkDeletePending = false;
                if (button) button.classList.remove('pending');
            }, 2000);
            return;
        }
        clearTimeout(bulkDeleteTimeout);
        bulkDeletePending = false;
        const button = document.getElementById('btn-DeleteSelected');
        if (button) button.classList.remove('pending');
        const selected = new Set(state.selectedEntryIds);
        state.entries = state.entries.filter(
            (entry) => !selected.has(entry.id)
        );
        state.selectedEntryIds.clear();
        if (!state.entries.some((entry) => entry.id === state.activeEntryId)) {
            state.activeEntryId = state.entries[0]?.id || '';
        }
        selected.forEach((id) => state.collapsedEntryIds.delete(id));
        renderEntries();
        onChange();
    }

    function toggleCollapseAll() {
        if (allEntriesCollapsed()) {
            state.collapsedEntryIds.clear();
        } else {
            state.collapsedEntryIds = new Set(
                state.entries.map((entry) => entry.id)
            );
        }
        renderEntries();
        onChange();
    }

    function focusEntry(index) {
        const entry = state.entries[index];
        if (!entry) return;
        state.searchQuery = '';
        state.categoryFilter = 'all';
        state.collapsedEntryIds.delete(entry.id);
        const search = document.getElementById('WorldInfoSearch');
        if (search) search.value = '';
        renderEntries();
        const previousActive = state.activeEntryId;
        selectEntry(index);
        if (previousActive === state.activeEntryId) onChange();
        const card = document.querySelector(
            `#WorldInfoEntries .wi-entry[data-entry-index="${index}"]`
        );
        if (!card) return;
        card.scrollIntoView({ behavior: 'smooth', block: 'center' });
        card.classList.add('is-issue-focus');
        setTimeout(() => card.classList.remove('is-issue-focus'), 2200);
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
        const search = document.getElementById('WorldInfoSearch');
        const chips = document.getElementById('WorldInfoCategoryFilter');

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

        if (search) {
            search.addEventListener('input', () => {
                state.searchQuery = search.value;
                applyEntryFilter();
            });
        }
        if (chips) {
            chips.addEventListener('click', (event) => {
                const button = event.target.closest('[data-category]');
                if (!button) return;
                state.categoryFilter = button.dataset.category;
                renderCategoryFilter();
                applyEntryFilter();
            });
        }
        if (add) {
            add.addEventListener('click', () => {
                const entry = newEntry();
                state.entries.push(entry);
                state.activeEntryId = entry.id;
                state.searchQuery = '';
                state.categoryFilter = 'all';
                if (search) search.value = '';
                renderEntries();
                onChange();
                const card = document.querySelector(
                    `#WorldInfoEntries .wi-entry[data-entry-index="${
                        state.entries.length - 1
                    }"]`
                );
                if (card) {
                    const input = card.querySelector('[data-wi-field="title"]');
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
                if (!card) return;
                if (event.target.matches('[data-select-entry]')) {
                    toggleSelection(
                        Number(card.dataset.entryIndex),
                        event.target.checked
                    );
                    return;
                }
                const field = event.target.dataset.wiField;
                if (field) readEntryField(card, field, event.target);
            });
            entries.addEventListener('focusin', (event) => {
                if (event.target.matches('[data-select-entry]')) return;
                const card = event.target.closest('[data-entry-index]');
                if (card) selectEntry(Number(card.dataset.entryIndex));
            });
            entries.addEventListener('click', (event) => {
                if (event.target.matches('[data-select-entry]')) return;
                const card = event.target.closest('[data-entry-index]');
                if (!card) return;
                const index = Number(card.dataset.entryIndex);
                if (event.target.closest('[data-remove-entry]')) {
                    removeEntry(index);
                    return;
                }
                if (event.target.closest('[data-duplicate-entry]')) {
                    duplicateEntry(index);
                    return;
                }
                if (event.target.closest('[data-toggle-entry]')) {
                    toggleCollapse(index);
                    return;
                }
                selectEntry(index);
            });
        }

        const bulkHandlers = {
            'btn-SelectVisible': () => setSelected(visibleEntryIds(), true),
            'btn-ClearSelection': () => setSelected([...state.selectedEntryIds], false),
            'btn-ToggleCollapseAll': toggleCollapseAll,
            'btn-EnableAll': () => setEntriesEnabled(state.entries.map((_, i) => i), true),
            'btn-DisableAll': () => setEntriesEnabled(state.entries.map((_, i) => i), false),
            'btn-EnableSelected': () =>
                setEntriesEnabled(
                    state.entries
                        .map((entry, index) => ({ entry, index }))
                        .filter(({ entry }) => state.selectedEntryIds.has(entry.id))
                        .map(({ index }) => index),
                    true
                ),
            'btn-DisableSelected': () =>
                setEntriesEnabled(
                    state.entries
                        .map((entry, index) => ({ entry, index }))
                        .filter(({ entry }) => state.selectedEntryIds.has(entry.id))
                        .map(({ index }) => index),
                    false
                ),
            'btn-DeleteSelected': deleteSelectedEntries,
        };
        Object.entries(bulkHandlers).forEach(([id, handler]) => {
            const button = document.getElementById(id);
            if (button) button.addEventListener('click', handler);
        });
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

    function resetViewState() {
        state.searchQuery = '';
        state.categoryFilter = 'all';
        state.collapsedEntryIds.clear();
        state.selectedEntryIds.clear();
        const search = document.getElementById('WorldInfoSearch');
        if (search) search.value = '';
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
        const rawEntries = Array.isArray(data.entries) ? data.entries : [];
        state.entries = rawEntries.map(entryFromRaw);
        resetViewState();
        state.activeEntryId = state.entries[0]?.id || '';
        fillForm();
    }

    function replaceData(data) {
        setData(data);
        onChange();
    }

    function mergeData(data) {
        if (!data || typeof data !== 'object') return 0;
        if (!state.name && typeof data.name === 'string') state.name = data.name;
        if (!state.description && typeof data.description === 'string') {
            state.description = data.description;
        }
        if (!state.background && typeof data.background === 'string') {
            state.background = data.background;
        }
        const rawEntries = Array.isArray(data.entries) ? data.entries : [];
        const existingIds = new Set(state.entries.map((entry) => entry.id));
        const added = [];
        for (const raw of rawEntries) {
            const entry = entryFromRaw(raw);
            while (existingIds.has(entry.id)) {
                entry.id = newEntry().id;
            }
            existingIds.add(entry.id);
            state.entries.push(entry);
            added.push(entry);
        }
        resetViewState();
        if (added.length > 0) state.activeEntryId = added[0].id;
        fillForm();
        onChange();
        return added.length;
    }

    function serializeEntry(entry) {
        const serialized = {
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
            ),
        };
        const stageIds = (entry.unlockStageIds || [])
            .map((s) => s.trim())
            .filter(Boolean);
        const minStr = String(entry.unlockMinIntimacy ?? '').trim();
        const maxStr = String(entry.unlockMaxIntimacy ?? '').trim();
        const metricConditions = parseMetricConditionsText(entry.unlockMetricsText);
        const hasUnlock =
            stageIds.length > 0 ||
            minStr !== '' ||
            maxStr !== '' ||
            metricConditions.length > 0 ||
            Boolean(entry.unlockHidden);
        if (hasUnlock) {
            const unlock = {};
            if (stageIds.length > 0) unlock.stage_ids = stageIds;
            if (minStr !== '' && Number.isFinite(Number(minStr))) {
                unlock.min_intimacy = Math.min(100, Math.max(0, Math.trunc(Number(minStr))));
            }
            if (maxStr !== '' && Number.isFinite(Number(maxStr))) {
                unlock.max_intimacy = Math.min(100, Math.max(0, Math.trunc(Number(maxStr))));
            }
            if (metricConditions.length > 0) {
                unlock.metric_conditions = metricConditions;
            }
            if (entry.unlockHidden) {
                unlock.hidden_until_unlocked = true;
            }
            serialized.unlock = unlock;
        }
        return serialized;
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
            entries: state.entries.map(serializeEntry),
        };
    }

    function hasContent() {
        return state.background.trim().length > 0 || state.entries.length > 0;
    }

    function validateAll() {
        const issues = [];
        const add = (code, severity, entryIndex = null, entryTitle = '') => {
            issues.push({ code, severity, entryIndex, entryTitle });
        };
        if (state.entries.length > 500) {
            add('TooManyEntries', 'error');
        }
        if (
            !Number.isFinite(Number(state.minActivations)) ||
            state.minActivations < 0 ||
            state.minActivations > 50
        ) {
            add('MinActivationsTooHigh', 'error');
        }
        if (
            !Number.isFinite(Number(state.recursionDepth)) ||
            state.recursionDepth < 0 ||
            state.recursionDepth > 10
        ) {
            add('RecursionDepthTooHigh', 'error');
        }

        const ids = new Set();
        const keyOwners = new Map();
        const groupOwners = new Map();
        state.entries.forEach((entry, index) => {
            const title = entry.title.trim() || entry.id;
            if (ids.has(entry.id)) {
                add('DuplicateId', 'error', index, title);
            }
            ids.add(entry.id);
            if (entry.keys.length === 0) {
                add('MissingKeys', 'error', index, title);
            }
            if (entry.keys.length > 20 || entry.secondaryKeys.length > 20) {
                add('TooManyKeys', 'error', index, title);
            }
            if (!POSITIONS.includes(entry.position)) {
                add('InvalidPosition', 'error', index, title);
            }
            if (
                entry.depth < 0 ||
                entry.depth > 1000 ||
                entry.sticky < 0 ||
                entry.sticky > 1000 ||
                entry.cooldown < 0 ||
                entry.cooldown > 1000
            ) {
                add('InvalidTiming', 'error', index, title);
            }
            if (entry.probability < 0 || entry.probability > 100) {
                add('InvalidProbability', 'error', index, title);
            }
            if (runeLength(entry.group) > 64) {
                add('GroupTooLong', 'error', index, title);
            }
            if (entry.match === 'regex') {
                for (const key of entry.keys.concat(entry.secondaryKeys)) {
                    if (runeLength(key) > 200) {
                        add('RegexTooLong', 'error', index, title);
                        continue;
                    }
                    try {
                        new RegExp(key, entry.caseSensitive ? '' : 'i');
                    } catch (_) {
                        add('InvalidRegex', 'error', index, title);
                    }
                }
            }
            if (runeLength(entry.content) > 4000) {
                add('ContentTooLong', 'error', index, title);
            }

            if (!entry.enabled) return;
            if (!entry.title.trim()) {
                add('EmptyTitle', 'warning', index, title);
            }
            if (!entry.content.trim()) {
                add('EmptyContent', 'warning', index, title);
            }
            const localKeys = new Set();
            for (const key of entry.keys) {
                const normalized = entry.caseSensitive
                    ? key.trim()
                    : key.trim().toLowerCase();
                if (localKeys.has(normalized)) {
                    add('DuplicateEntryKeys', 'warning', index, title);
                    break;
                }
                localKeys.add(normalized);
                if (!keyOwners.has(normalized)) keyOwners.set(normalized, []);
                keyOwners.get(normalized).push(index);
            }
            const group = entry.group.trim();
            if (group) {
                if (!groupOwners.has(group)) groupOwners.set(group, []);
                groupOwners.get(group).push(index);
            }
        });

        for (const indexes of keyOwners.values()) {
            if (indexes.length > 1) {
                indexes.forEach((index) => {
                    add(
                        'DuplicateKeysAcrossEntries',
                        'warning',
                        index,
                        state.entries[index].title.trim() ||
                            state.entries[index].id
                    );
                });
            }
        }
        for (const indexes of groupOwners.values()) {
            if (indexes.length > 1) {
                indexes.forEach((index) => {
                    add(
                        'GroupConflict',
                        'warning',
                        index,
                        state.entries[index].title.trim() ||
                            state.entries[index].id
                    );
                });
            }
        }
        const enabledTokens = state.entries
            .filter((entry) => entry.enabled)
            .reduce((sum, entry) => sum + tokenCount(entry.content), 0);
        if (
            state.entries.length > 0 &&
            enabledTokens > Number(state.budgetTokens || 0)
        ) {
            add('EntryBudgetExceeded', 'warning');
        }

        const severityRank = { error: 0, warning: 1 };
        return issues.sort((a, b) => {
            const bySeverity =
                severityRank[a.severity] - severityRank[b.severity];
            if (bySeverity !== 0) return bySeverity;
            const aIndex = a.entryIndex ?? -1;
            const bIndex = b.entryIndex ?? -1;
            return aIndex - bIndex;
        });
    }

    function validate() {
        const issue = validateAll().find((item) => item.severity === 'error');
        if (!issue) return null;
        return {
            code: issue.code,
            title: issue.entryTitle || '',
            entryIndex: issue.entryIndex,
            entryTitle: issue.entryTitle,
        };
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
        resetViewState();
        fillForm();
    }

    function getSelectedEntry() {
        if (!state.activeEntryId) return null;
        const entry = state.entries.find(
            (item) => item.id === state.activeEntryId
        );
        return entry ? serializeEntry(entry) : null;
    }

    function getStats() {
        const info = getData();
        const backgroundTokens = tokenCount(info.background);
        const entryTokens = info.entries.reduce(
            (sum, entry) => sum + tokenCount(entry.content),
            0
        );
        return {
            entries: info.entries.length,
            enabledEntries: info.entries.filter((entry) => entry.enabled).length,
            backgroundTokens,
            entryTokens,
            totalTokens: backgroundTokens + entryTokens,
        };
    }

    function init(callback) {
        if (typeof callback === 'function') onChange = callback;
        bind();
        fillForm();
    }

    function refreshLanguage() {
        const d = dict();
        const search = document.getElementById('WorldInfoSearch');
        if (search) search.placeholder = d.SearchEntries || 'Search entries';
        const empty = document.getElementById('WorldInfoFilterEmpty');
        if (empty) empty.textContent = d.NoMatchingEntries || 'No matching entries';
        renderCategoryFilter();
        renderEntries();
    }

    window.LFWorldInfo = {
        init,
        refreshLanguage,
        setData,
        replaceData,
        mergeData,
        getData,
        getSelectedEntry,
        getStats,
        hasContent,
        validate,
        validateAll,
        focusEntry,
        importLegacyBackground,
        reset,
        render: renderEntries,
    };
})();
