/* Growth Character Card editor, validator, and artwork manager for LumenFlow Generator. */
(function () {
    const SLUG_PATTERN = /^[a-z][a-z0-9_]{0,31}$/;
    const MAX_METRICS = 4;
    const MAX_STAGES = 20;
    const MAX_TRANSITIONS = 8;

    let onChange = function () {};
    const collapsedMetrics = new Set();
    const collapsedStages = new Set();

    function defaultStage(index, isInitial) {
        return {
            id: isInitial ? 'stage_1' : `stage_${index + 1}`,
            name: isInitial ? '初遇阶段' : `阶段 ${index + 1}`,
            summary: '',
            isInitial: Boolean(isInitial),
            isEnding: false,
            promptOverlay: '',
            transitions: [],
        };
    }

    function createBlankState() {
        return {
            enabled: false,
            intimacyLabel: '',
            intimacyDescription: '',
            initialIntimacy: 20,
            maxIntimacyGain: 8,
            maxIntimacyLoss: 12,
            metrics: [],
            stages: [defaultStage(0, true)],
            stageImages: {},
        };
    }

    let state = createBlankState();

    function dict() {
        return (window.LF_I18N && window.LF_I18N[window.LF_CURRENT_LANG || 'zh']) || {};
    }

    function escapeHtml(value) {
        return String(value ?? '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function parseConditionsLines(text) {
        const result = [];
        const errors = [];
        const lines = String(text || '').split(/\r?\n/);
        for (const raw of lines) {
            const line = raw.trim();
            if (!line) continue;
            const match = /^([a-z][a-z0-9_]{0,31})\s*(>=|<=|>|<)\s*(-?\d+)$/.exec(line);
            if (!match) {
                errors.push(line);
                continue;
            }
            result.push({
                metric: match[1],
                op: match[2],
                value: Math.trunc(Number(match[3])),
            });
        }
        return { conditions: result, errors };
    }

    function formatConditionsLines(conditions) {
        if (!Array.isArray(conditions)) return '';
        return conditions
            .filter(
                (c) =>
                    c &&
                    typeof c.metric === 'string' &&
                    typeof c.op === 'string' &&
                    Number.isFinite(Number(c.value))
            )
            .map((c) => `${c.metric} ${c.op} ${Math.trunc(Number(c.value))}`)
            .join('\n');
    }

    function clampInt(val, min, max, fallback) {
        const n = Number(val);
        if (!Number.isFinite(n)) return fallback;
        return Math.min(max, Math.max(min, Math.trunc(n)));
    }

    function autoResizeTextarea(el) {
        if (!el || el.tagName !== 'TEXTAREA') return;
        el.style.height = 'auto';
        if (el.scrollHeight > 0) {
            el.style.height = `${el.scrollHeight}px`;
        }
    }

    function autoResizeAllGrowthTextareas() {
        const panel = document.getElementById('panel-growth');
        if (!panel) return;
        panel.querySelectorAll('textarea').forEach(autoResizeTextarea);
    }

    function syncTransitionTargetSelects() {
        const container = document.getElementById('GrowthStagesList');
        if (!container) return;
        container.querySelectorAll('[data-trans-index]').forEach((card) => {
            const sIdx = Number(card.dataset.stageIndex);
            const tIdx = Number(card.dataset.transIndex);
            const stage = state.stages[sIdx];
            const trans = stage?.transitions?.[tIdx];
            const select = card.querySelector('select[data-gt-field="toStageId"]');
            if (!stage || !trans || !select) return;
            const selectedTarget = trans.toStageId || '';
            const opts = state.stages
                .filter((other) => other.id && other.id !== stage.id)
                .map(
                    (other) =>
                        `<option value="${escapeHtml(other.id)}" ${
                            other.id === selectedTarget ? 'selected' : ''
                        }>${escapeHtml(other.name || other.id)} (${escapeHtml(other.id)})</option>`
                )
                .join('');
            select.innerHTML = `<option value="">—</option>${opts}`;
            select.value = selectedTarget;
        });
        if (window.LFSelect && typeof window.LFSelect.refreshAll === 'function') {
            window.LFSelect.refreshAll();
        }
    }

    async function normalizePngFile(file, maxDim, maxBytes) {
        if (!file || (file.type && file.type !== 'image/png' && !file.name.toLowerCase().endsWith('.png'))) {
            throw new Error(dict().AvatarInvalid || 'PNG required');
        }
        const rawUrl = await new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(String(reader.result || ''));
            reader.onerror = () => reject(reader.error);
            reader.readAsDataURL(file);
        });
        const img = await new Promise((resolve, reject) => {
            const image = new Image();
            image.onload = () => resolve(image);
            image.onerror = () => reject(new Error(dict().AvatarInvalid || 'Invalid PNG'));
            image.src = rawUrl;
        });

        let scale = 1;
        const longest = Math.max(img.width, img.height);
        if (longest > maxDim) scale = maxDim / longest;

        for (let attempt = 0; attempt < 4; attempt++) {
            const w = Math.max(1, Math.round(img.width * scale));
            const h = Math.max(1, Math.round(img.height * scale));
            const canvas = document.createElement('canvas');
            canvas.width = w;
            canvas.height = h;
            const ctx = canvas.getContext('2d');
            ctx.drawImage(img, 0, 0, w, h);
            const dataUrl = canvas.toDataURL('image/png');
            const approxBytes = Math.floor(((dataUrl.length - dataUrl.indexOf(',') - 1) * 3) / 4);
            if (approxBytes <= maxBytes) return dataUrl;
            scale *= 0.75;
        }
        throw new Error(dict().AvatarTooLarge || 'PNG too large');
    }

    function buildPayload() {
        const metrics = state.metrics.map((m) => {
            const min = clampInt(m.min, -10000, 10000, 0);
            const max = clampInt(m.max, min + 1, 100000, 100);
            const span = Math.max(1, max - min);
            const item = {
                id: String(m.id || '').trim(),
                name: String(m.name || '').trim(),
                min,
                max,
                initial: clampInt(m.initial, min, max, min),
                max_gain: clampInt(m.maxGain, 1, span, Math.min(10, span)),
                max_loss: clampInt(m.maxLoss, 1, span, Math.min(10, span)),
            };
            if (String(m.description || '').trim()) {
                item.description = String(m.description).trim();
            }
            if (m.hidden) item.hidden = true;
            return item;
        });

        const stages = state.stages.map((s) => {
            const sid = String(s.id || '').trim();
            const imgs = state.stageImages[sid] || {};
            const stageObj = {
                id: sid,
                name: String(s.name || '').trim(),
            };
            if (String(s.summary || '').trim()) {
                stageObj.summary = String(s.summary).trim();
            }
            if (s.isInitial) stageObj.is_initial = true;
            if (s.isEnding) stageObj.is_ending = true;
            if (String(s.promptOverlay || '').trim()) {
                stageObj.prompt_overlay = String(s.promptOverlay).trim();
            }
            if (imgs.avatarDataUrl) {
                stageObj.avatar_file = `stages/${sid}/avatar.png`;
            }
            if (imgs.illustrationDataUrl) {
                stageObj.illustration_file = `stages/${sid}/illustration.png`;
            }
            if (Array.isArray(s.transitions) && s.transitions.length > 0) {
                stageObj.transitions = s.transitions.map((t) => {
                    const parsed = parseConditionsLines(t.conditionsText);
                    const tr = {
                        id: String(t.id || '').trim(),
                        to_stage_id: String(t.toStageId || '').trim(),
                        priority: clampInt(t.priority, -1000, 1000, 100),
                    };
                    if (t.reversible) tr.reversible = true;
                    if (parsed.conditions.length > 0) {
                        tr.conditions = parsed.conditions;
                    }
                    if (String(t.narrativeTrigger || '').trim()) {
                        tr.narrative_trigger = String(t.narrativeTrigger).trim();
                    }
                    if (String(t.transitionBeat || '').trim()) {
                        tr.transition_beat = String(t.transitionBeat).trim();
                    }
                    if (String(t.milestoneTitle || '').trim()) {
                        tr.milestone_title = String(t.milestoneTitle).trim();
                    }
                    return tr;
                });
            }
            return stageObj;
        });

        const payload = {
            _format: 'lumenflow_character_growth',
            _version: 1,
            initial_intimacy: clampInt(state.initialIntimacy, 0, 100, 20),
            max_intimacy_gain: clampInt(state.maxIntimacyGain, 1, 50, 8),
            max_intimacy_loss: clampInt(state.maxIntimacyLoss, 1, 50, 12),
            stages,
        };
        if (String(state.intimacyLabel || '').trim()) {
            payload.intimacy_label = String(state.intimacyLabel).trim();
        }
        if (String(state.intimacyDescription || '').trim()) {
            payload.intimacy_description = String(state.intimacyDescription).trim();
        }
        if (metrics.length > 0) {
            payload.metrics = metrics;
        }
        return payload;
    }

    function validateAll() {
        const d = dict();
        if (!state.enabled) return [];
        const errors = [];

        if (state.metrics.length > MAX_METRICS) {
            errors.push(d.GrowthErrTooManyMetrics || 'Max 4 metrics');
        }
        const metricIds = new Set(['intimacy']);
        const seenMetrics = new Set();
        for (const m of state.metrics) {
            const id = String(m.id || '').trim();
            if (!SLUG_PATTERN.test(id)) {
                errors.push((d.GrowthErrBadSlug || 'Bad ID: {id}').replace('{id}', id || '(empty)'));
            } else if (id === 'intimacy') {
                errors.push(d.GrowthErrReservedMetric || 'Reserved metric id intimacy');
            } else if (seenMetrics.has(id)) {
                errors.push((d.GrowthErrDupId || 'Duplicate ID: {id}').replace('{id}', id));
            } else {
                seenMetrics.add(id);
                metricIds.add(id);
            }
            if (!String(m.name || '').trim()) {
                errors.push((d.GrowthErrMetricName || 'Missing metric name: {id}').replace('{id}', id || '?'));
            }
            const min = Number(m.min);
            const max = Number(m.max);
            const init = Number(m.initial);
            if (!Number.isFinite(min) || !Number.isFinite(max) || min >= max || !Number.isFinite(init) || init < min || init > max) {
                errors.push((d.GrowthErrMetricRange || 'Invalid range: {id}').replace('{id}', id || '?'));
            }
        }

        if (!state.stages.length || state.stages.length > MAX_STAGES) {
            errors.push(d.GrowthErrNoStages || 'Need 1..20 stages');
            return errors;
        }

        const stageIds = new Set();
        let initialCount = 0;
        for (const s of state.stages) {
            const sid = String(s.id || '').trim();
            if (!SLUG_PATTERN.test(sid)) {
                errors.push((d.GrowthErrBadSlug || 'Bad ID: {id}').replace('{id}', sid || '(empty)'));
            } else if (stageIds.has(sid)) {
                errors.push((d.GrowthErrDupId || 'Duplicate ID: {id}').replace('{id}', sid));
            } else {
                stageIds.add(sid);
            }
            if (!String(s.name || '').trim()) {
                errors.push((d.GrowthErrStageName || 'Missing stage name: {id}').replace('{id}', sid || '?'));
            }
            if (s.isInitial) initialCount++;
        }
        if (initialCount !== 1) {
            errors.push(d.GrowthErrInitialCount || 'Need exactly 1 initial stage');
        }

        const transitionIds = new Set();
        for (const s of state.stages) {
            const sid = String(s.id || '').trim();
            for (const t of s.transitions || []) {
                const tid = String(t.id || '').trim();
                if (!SLUG_PATTERN.test(tid)) {
                    errors.push((d.GrowthErrBadSlug || 'Bad ID: {id}').replace('{id}', tid || '(empty)'));
                } else if (transitionIds.has(tid)) {
                    errors.push((d.GrowthErrDupId || 'Duplicate ID: {id}').replace('{id}', tid));
                } else {
                    transitionIds.add(tid);
                }
                const target = String(t.toStageId || '').trim();
                if (!stageIds.has(target) || target === sid) {
                    errors.push((d.GrowthErrTransTarget || 'Bad target in {id}').replace('{id}', tid || '?'));
                }
                const parsed = parseConditionsLines(t.conditionsText);
                for (const badLine of parsed.errors) {
                    errors.push(
                        (d.GrowthErrCondSyntax || 'Bad condition in {id}: {line}')
                            .replace('{id}', tid || '?')
                            .replace('{line}', badLine)
                    );
                }
                for (const cond of parsed.conditions) {
                    if (!metricIds.has(cond.metric)) {
                        errors.push(
                            (d.GrowthErrCondMetric || 'Unknown metric in {id}: {metric}')
                                .replace('{id}', tid || '?')
                                .replace('{metric}', cond.metric)
                        );
                    }
                }
                if (parsed.conditions.length === 0 && !String(t.narrativeTrigger || '').trim()) {
                    errors.push((d.GrowthErrTransEmpty || 'Empty transition {id}').replace('{id}', tid || '?'));
                }
            }
        }
        return errors;
    }

    function renderValidation() {
        const panel = document.getElementById('GrowthValidation');
        if (!panel) return;
        const errors = validateAll();
        if (!errors.length) {
            panel.hidden = true;
            panel.innerHTML = '';
            return;
        }
        const d = dict();
        panel.hidden = false;
        panel.innerHTML = `
            <div class="validation-header">
                <span>${escapeHtml(d.TabGrowth || '成长系统')} · ${errors.length}</span>
            </div>
            <div class="validation-list">
                ${errors
                    .map(
                        (msg) => `
                    <div class="validation-issue growth-validation-row">
                        <span class="validation-dot"></span>
                        <span class="validation-message">${escapeHtml(msg)}</span>
                    </div>`
                    )
                    .join('')}
            </div>`;
    }

    function render() {
        const d = dict();
        const enabledToggle = document.getElementById('GrowthEnabled');
        const body = document.getElementById('GrowthEditorBody');
        if (enabledToggle) enabledToggle.checked = state.enabled;
        if (body) body.hidden = !state.enabled;

        const setVal = (id, val) => {
            const el = document.getElementById(id);
            if (el && el.value !== String(val ?? '')) el.value = String(val ?? '');
        };
        setVal('GrowthIntimacyLabel', state.intimacyLabel);
        setVal('GrowthIntimacyDesc', state.intimacyDescription);
        setVal('GrowthInitialIntimacy', state.initialIntimacy);
        setVal('GrowthMaxIntimacyGain', state.maxIntimacyGain);
        setVal('GrowthMaxIntimacyLoss', state.maxIntimacyLoss);

        renderMetrics(d);
        renderStages(d);
        renderValidation();
    }

    function renderMetrics(d) {
        const container = document.getElementById('GrowthMetricsList');
        const addBtn = document.getElementById('btn-AddGrowthMetric');
        if (addBtn) addBtn.disabled = state.metrics.length >= MAX_METRICS;
        if (!container) return;

        if (!state.metrics.length) {
            container.innerHTML = `<div class="wi-empty">${escapeHtml(d.GrowthMetricsTitle || '自定义成长指标（最多 4 个）')} · 0 / ${MAX_METRICS}</div>`;
            return;
        }

        container.innerHTML = state.metrics
            .map((m, idx) => {
                const collapsed = collapsedMetrics.has(idx);
                return `
                <div class="wi-entry growth-entry${collapsed ? ' is-collapsed' : ''}" data-metric-index="${idx}">
                    <div class="wi-entry-head">
                        <input type="text" class="growth-head-title" data-gm-field="name" value="${escapeHtml(m.name)}"
                            placeholder="${escapeHtml(d.GrowthMetricName || '指标名称')}">
                        <span class="wi-entry-tokens">${escapeHtml(m.id || `metric_${idx + 1}`)} · ${Number(m.min) || 0}–${Number(m.max) || 100}</span>
                        <div class="wi-entry-actions">
                            <button type="button" class="wi-action wi-collapse${collapsed ? ' is-collapsed' : ''}"
                                data-toggle-metric="${idx}" aria-expanded="${!collapsed}"
                                title="${escapeHtml(collapsed ? (d.ExpandEntry || '展开') : (d.CollapseEntry || '折叠'))}">
                                <span></span>
                            </button>
                            <button type="button" class="wi-remove" data-remove-metric="${idx}"
                                title="${escapeHtml(d.GrowthRemove || '删除')}">×</button>
                        </div>
                    </div>
                    <div class="wi-entry-body">
                        <div class="form-grid">
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthMetricId || 'ID')}</label>
                                <input type="text" data-gm-field="id" value="${escapeHtml(m.id)}" placeholder="guard">
                            </div>
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthInitial || '初始值')}</label>
                                <input type="number" data-gm-field="initial" value="${Number(m.initial) || 0}">
                            </div>
                        </div>
                        <div class="form-grid">
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthMetricMin || '最小值')}</label>
                                <input type="number" data-gm-field="min" value="${Number(m.min) || 0}">
                            </div>
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthMetricMax || '最大值')}</label>
                                <input type="number" data-gm-field="max" value="${Number(m.max) || 100}">
                            </div>
                        </div>
                        <div class="form-grid">
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthMaxGain || '单次最大增幅')}</label>
                                <input type="number" min="1" data-gm-field="maxGain" value="${Number(m.maxGain) || 10}">
                            </div>
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthMaxLoss || '单次最大降幅')}</label>
                                <input type="number" min="1" data-gm-field="maxLoss" value="${Number(m.maxLoss) || 10}">
                            </div>
                        </div>
                        <div class="form-group">
                            <label>${escapeHtml(d.GrowthMetricDesc || '指标说明')}</label>
                            <input type="text" data-gm-field="description" value="${escapeHtml(m.description)}">
                        </div>
                        <div class="form-group wi-flag-row">
                            <label>
                                <input type="checkbox" data-gm-field="hidden" ${m.hidden ? 'checked' : ''}>
                                ${escapeHtml(d.GrowthMetricHidden || '在界面中隐藏')}
                            </label>
                        </div>
                    </div>
                </div>`;
            })
            .join('');
    }

    function renderStages(d) {
        const container = document.getElementById('GrowthStagesList');
        const addBtn = document.getElementById('btn-AddGrowthStage');
        if (addBtn) addBtn.disabled = state.stages.length >= MAX_STAGES;
        if (!container) return;

        container.innerHTML = state.stages
            .map((s, sIdx) => {
                const collapsed = collapsedStages.has(sIdx);
                const imgs = state.stageImages[s.id] || {};
                const hasMedia = Boolean(imgs.avatarDataUrl || imgs.illustrationDataUrl);
                const transCount = (s.transitions || []).length;

                const transitionsHtml = (s.transitions || [])
                    .map((t, tIdx) => {
                        const selectedTarget = t.toStageId || '';
                        const opts = state.stages
                            .filter((other) => other.id && other.id !== s.id)
                            .map(
                                (other) =>
                                    `<option value="${escapeHtml(other.id)}" ${
                                        other.id === selectedTarget ? 'selected' : ''
                                    }>${escapeHtml(other.name || other.id)} (${escapeHtml(other.id)})</option>`
                            )
                            .join('');
                        return `
                        <div class="growth-transition-card" data-stage-index="${sIdx}" data-trans-index="${tIdx}">
                            <div class="growth-transition-head">
                                <span class="growth-transition-title">→ ${escapeHtml(t.milestoneTitle || t.id || `transition_${tIdx + 1}`)}</span>
                                <button type="button" class="wi-remove" data-remove-trans="${sIdx}:${tIdx}"
                                    title="${escapeHtml(d.GrowthRemove || '删除')}">×</button>
                            </div>
                            <div class="form-grid">
                                <div class="form-group">
                                    <label>${escapeHtml(d.GrowthTransId || '跃迁 ID')}</label>
                                    <input type="text" data-gt-field="id" value="${escapeHtml(t.id)}">
                                </div>
                                <div class="form-group">
                                    <label>${escapeHtml(d.GrowthTransTarget || '目标阶段')}</label>
                                    <select data-gt-field="toStageId">
                                        <option value="">—</option>
                                        ${opts}
                                    </select>
                                </div>
                            </div>
                            <div class="form-grid">
                                <div class="form-group">
                                    <label>${escapeHtml(d.GrowthTransMilestone || '里程碑标题')}</label>
                                    <input type="text" data-gt-field="milestoneTitle" value="${escapeHtml(t.milestoneTitle)}">
                                </div>
                                <div class="form-group">
                                    <label>${escapeHtml(d.GrowthTransPriority || '优先级')}</label>
                                    <input type="number" data-gt-field="priority" value="${Number(t.priority) || 100}">
                                </div>
                            </div>
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthTransConditions || '数值门槛')}</label>
                                <textarea class="compact" data-gt-field="conditionsText" placeholder="intimacy >= 40">${escapeHtml(t.conditionsText || '')}</textarea>
                            </div>
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthTransNarrative || '叙事事件触发描述')}</label>
                                <input type="text" data-gt-field="narrativeTrigger" value="${escapeHtml(t.narrativeTrigger)}">
                            </div>
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthTransBeat || '跃迁过渡表现指引')}</label>
                                <input type="text" data-gt-field="transitionBeat" value="${escapeHtml(t.transitionBeat)}">
                            </div>
                            <div class="form-group wi-flag-row">
                                <label>
                                    <input type="checkbox" data-gt-field="reversible" ${t.reversible ? 'checked' : ''}>
                                    ${escapeHtml(d.GrowthTransReversible || '可逆分支')}
                                </label>
                            </div>
                        </div>`;
                    })
                    .join('');

                return `
                <div class="wi-entry growth-entry${collapsed ? ' is-collapsed' : ''}" data-stage-index="${sIdx}">
                    <div class="wi-entry-head">
                        <input type="text" class="growth-head-title" data-gs-field="name" value="${escapeHtml(s.name)}"
                            placeholder="${escapeHtml(d.GrowthStageName || '阶段名称')}">
                        ${s.isInitial ? `<span class="growth-pill">${escapeHtml(d.GrowthStageInitial || '初始')}</span>` : ''}
                        ${s.isEnding ? `<span class="growth-pill is-ending">${escapeHtml(d.GrowthStageEnding || '结局')}</span>` : ''}
                        <span class="wi-entry-tokens">${escapeHtml(s.id || `stage_${sIdx + 1}`)}${transCount ? ` · →${transCount}` : ''}</span>
                        <div class="wi-entry-actions">
                            <button type="button" class="wi-action wi-collapse${collapsed ? ' is-collapsed' : ''}"
                                data-toggle-stage="${sIdx}" aria-expanded="${!collapsed}"
                                title="${escapeHtml(collapsed ? (d.ExpandEntry || '展开') : (d.CollapseEntry || '折叠'))}">
                                <span></span>
                            </button>
                            ${
                                state.stages.length > 1
                                    ? `<button type="button" class="wi-remove" data-remove-stage="${sIdx}"
                                        title="${escapeHtml(d.GrowthRemove || '删除')}">×</button>`
                                    : ''
                            }
                        </div>
                    </div>
                    <div class="wi-entry-body">
                        <div class="form-grid">
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthStageId || '阶段 ID')}</label>
                                <input type="text" data-gs-field="id" value="${escapeHtml(s.id)}">
                            </div>
                            <div class="form-group">
                                <label>${escapeHtml(d.GrowthStageSummary || '阶段概述')}</label>
                                <input type="text" data-gs-field="summary" value="${escapeHtml(s.summary)}">
                            </div>
                        </div>
                        <div class="form-group wi-flag-row">
                            <label>
                                <input type="checkbox" data-gs-field="isInitial" ${s.isInitial ? 'checked' : ''}>
                                ${escapeHtml(d.GrowthStageInitial || '初始阶段')}
                            </label>
                            <label>
                                <input type="checkbox" data-gs-field="isEnding" ${s.isEnding ? 'checked' : ''}>
                                ${escapeHtml(d.GrowthStageEnding || '结局阶段')}
                            </label>
                        </div>
                        <div class="form-group">
                            <label>${escapeHtml(d.GrowthStageOverlay || '阶段行为叠加指令')}</label>
                            <span class="hint">${escapeHtml(d.GrowthStageOverlayHint || '')}</span>
                            <textarea data-gs-field="promptOverlay">${escapeHtml(s.promptOverlay)}</textarea>
                        </div>
                        <details class="wi-unlock-details"${hasMedia ? ' open' : ''}>
                            <summary>${escapeHtml(d.GrowthStageMedia || '阶段差分图（可选）')}</summary>
                            <div class="wi-unlock-body">
                                <div class="growth-media-grid">
                                    <div class="growth-media-item">
                                        <div class="growth-stage-avatar-preview">${
                                            imgs.avatarDataUrl
                                                ? `<img src="${imgs.avatarDataUrl}" alt="avatar">`
                                                : '<span class="avatar-placeholder">PNG</span>'
                                        }</div>
                                        <div class="button-row">
                                            <button type="button" class="secondary" data-pick-stage-img="${sIdx}:avatar">${escapeHtml(d.GrowthStageAvatar || '阶段头像')}</button>
                                            ${
                                                imgs.avatarDataUrl
                                                    ? `<button type="button" class="wi-text-button danger" data-clear-stage-img="${sIdx}:avatar">${escapeHtml(d.GrowthRemove || '删除')}</button>`
                                                    : ''
                                            }
                                        </div>
                                    </div>
                                    <div class="growth-media-item">
                                        <div class="growth-stage-illustration-preview">${
                                            imgs.illustrationDataUrl
                                                ? `<img src="${imgs.illustrationDataUrl}" alt="illustration">`
                                                : '<span class="illustration-placeholder">PNG</span>'
                                        }</div>
                                        <div class="button-row">
                                            <button type="button" class="secondary" data-pick-stage-img="${sIdx}:illustration">${escapeHtml(d.GrowthStageIllustration || '阶段立绘')}</button>
                                            ${
                                                imgs.illustrationDataUrl
                                                    ? `<button type="button" class="wi-text-button danger" data-clear-stage-img="${sIdx}:illustration">${escapeHtml(d.GrowthRemove || '删除')}</button>`
                                                    : ''
                                            }
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </details>
                        <div class="growth-transitions-wrap">
                            <div class="growth-subhead">
                                <span>${escapeHtml(d.GrowthTransitionsTitle || '出边跃迁规则')}</span>
                                <button type="button" class="secondary" data-add-trans="${sIdx}" ${
                                    transCount >= MAX_TRANSITIONS || state.stages.length < 2
                                        ? 'disabled'
                                        : ''
                                }>${escapeHtml(d.GrowthAddTransition || '添加跃迁')}</button>
                            </div>
                            ${transitionsHtml}
                        </div>
                    </div>
                </div>`;
            })
            .join('');

        if (window.LFSelect && typeof window.LFSelect.enhanceAll === 'function') {
            window.LFSelect.enhanceAll(container);
        }
        autoResizeAllGrowthTextareas();
    }

    function notifyChange() {
        renderValidation();
        onChange();
    }

    function bind() {
        const panel = document.getElementById('panel-growth');
        if (!panel) return;

        let pendingImageTarget = null;
        const stageImgInput = document.getElementById('GrowthStageImageInput');
        if (stageImgInput) {
            stageImgInput.addEventListener('change', async (event) => {
                const file = event.target.files[0];
                event.target.value = '';
                if (!file || !pendingImageTarget) return;
                const { stageIndex, kind } = pendingImageTarget;
                pendingImageTarget = null;
                const stage = state.stages[stageIndex];
                if (!stage || !stage.id) return;
                try {
                    const dataUrl = await normalizePngFile(
                        file,
                        kind === 'avatar' ? 1024 : 2048,
                        kind === 'avatar' ? 2 * 1024 * 1024 : 8 * 1024 * 1024
                    );
                    if (!state.stageImages[stage.id]) state.stageImages[stage.id] = {};
                    if (kind === 'avatar') state.stageImages[stage.id].avatarDataUrl = dataUrl;
                    else state.stageImages[stage.id].illustrationDataUrl = dataUrl;
                    renderStages(dict());
                    notifyChange();
                } catch (err) {
                    if (window.alert) alert(err.message || 'Invalid PNG');
                }
            });
        }

        document.getElementById('GrowthEnabled')?.addEventListener('change', (e) => {
            state.enabled = Boolean(e.target.checked);
            if (state.enabled && state.stages.length === 0) {
                state.stages = [defaultStage(0, true)];
            }
            render();
            notifyChange();
        });

        const bindTop = (id, key, isNum, min, max, fallback) => {
            document.getElementById(id)?.addEventListener('input', (e) => {
                state[key] = isNum
                    ? clampInt(e.target.value, min, max, fallback)
                    : e.target.value;
                notifyChange();
            });
        };
        bindTop('GrowthIntimacyLabel', 'intimacyLabel', false);
        bindTop('GrowthIntimacyDesc', 'intimacyDescription', false);
        bindTop('GrowthInitialIntimacy', 'initialIntimacy', true, 0, 100, 20);
        bindTop('GrowthMaxIntimacyGain', 'maxIntimacyGain', true, 1, 50, 8);
        bindTop('GrowthMaxIntimacyLoss', 'maxIntimacyLoss', true, 1, 50, 12);

        document.getElementById('btn-AddGrowthMetric')?.addEventListener('click', () => {
            if (state.metrics.length >= MAX_METRICS) return;
            const n = state.metrics.length + 1;
            state.metrics.push({
                id: `metric_${n}`,
                name: `指标 ${n}`,
                description: '',
                min: 0,
                max: 100,
                initial: 0,
                maxGain: 10,
                maxLoss: 10,
                hidden: false,
            });
            collapsedMetrics.delete(state.metrics.length - 1);
            renderMetrics(dict());
            notifyChange();
        });

        document.getElementById('btn-AddGrowthStage')?.addEventListener('click', () => {
            if (state.stages.length >= MAX_STAGES) return;
            state.stages.push(defaultStage(state.stages.length, state.stages.length === 0));
            collapsedStages.delete(state.stages.length - 1);
            renderStages(dict());
            notifyChange();
        });

        const growthImportInput = document.getElementById('GrowthFileInput');
        document.getElementById('btn-ImportGrowth')?.addEventListener('click', () => {
            growthImportInput?.click();
        });
        growthImportInput?.addEventListener('change', async (e) => {
            const file = e.target.files[0];
            e.target.value = '';
            if (!file) return;
            try {
                const raw = JSON.parse(await file.text());
                if (raw._format !== 'lumenflow_character_growth') {
                    throw new Error(dict().GrowthInvalidJson || 'Invalid growth.json');
                }
                setData(raw, {});
                notifyChange();
            } catch (err) {
                alert(err.message || dict().GrowthInvalidJson || 'Invalid growth.json');
            }
        });
        document.getElementById('btn-ExportGrowth')?.addEventListener('click', () => {
            if (!state.enabled) return;
            const blob = new Blob([JSON.stringify(buildPayload(), null, 2)], {
                type: 'application/json;charset=utf-8',
            });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'growth.json';
            a.click();
            setTimeout(() => URL.revokeObjectURL(url), 1000);
        });

        panel.addEventListener('input', (event) => {
            const target = event.target;
            if (target.tagName === 'TEXTAREA') {
                autoResizeTextarea(target);
            }
            const gmField = target.dataset.gmField;
            if (gmField) {
                const card = target.closest('[data-metric-index]');
                const idx = Number(card?.dataset.metricIndex);
                const m = state.metrics[idx];
                if (!m) return;
                if (['min', 'max', 'initial', 'maxGain', 'maxLoss'].includes(gmField)) {
                    m[gmField] = Number(target.value);
                } else {
                    m[gmField] = target.value;
                }
                const badge = card?.querySelector('.wi-entry-tokens');
                if (badge) {
                    badge.textContent = `${m.id || `metric_${idx + 1}`} · ${Number(m.min) || 0}–${Number(m.max) || 100}`;
                }
                notifyChange();
                return;
            }
            const gsField = target.dataset.gsField;
            if (gsField && gsField !== 'isInitial' && gsField !== 'isEnding') {
                const card = target.closest('[data-stage-index]');
                const idx = Number(card?.dataset.stageIndex);
                const s = state.stages[idx];
                if (!s) return;
                if (gsField === 'id') {
                    const oldId = s.id;
                    const newId = target.value.trim();
                    if (oldId && newId && oldId !== newId) {
                        if (state.stageImages[oldId]) {
                            state.stageImages[newId] = state.stageImages[oldId];
                            delete state.stageImages[oldId];
                        }
                        for (const st of state.stages) {
                            for (const tr of st.transitions || []) {
                                if (tr.toStageId === oldId) tr.toStageId = newId;
                            }
                        }
                    }
                    s.id = newId;
                    const badge = card?.querySelector('.wi-entry-tokens');
                    if (badge) {
                        const tc = (s.transitions || []).length;
                        badge.textContent = `${s.id || `stage_${idx + 1}`}${tc ? ` · →${tc}` : ''}`;
                    }
                    syncTransitionTargetSelects();
                } else {
                    s[gsField] = target.value;
                    if (gsField === 'name') {
                        syncTransitionTargetSelects();
                    }
                }
                notifyChange();
                return;
            }
            const gtField = target.dataset.gtField;
            if (gtField && gtField !== 'reversible') {
                const card = target.closest('[data-trans-index]');
                const sIdx = Number(card?.dataset.stageIndex);
                const tIdx = Number(card?.dataset.transIndex);
                const t = state.stages[sIdx]?.transitions?.[tIdx];
                if (!t) return;
                t[gtField] = gtField === 'priority' ? Number(target.value) : target.value;
                if (gtField === 'milestoneTitle' || gtField === 'id') {
                    const headTitle = card?.querySelector('.growth-transition-title');
                    if (headTitle) {
                        headTitle.textContent = `→ ${t.milestoneTitle || t.id || `transition_${tIdx + 1}`}`;
                    }
                }
                notifyChange();
            }
        });

        panel.addEventListener('change', (event) => {
            const target = event.target;
            if (target.dataset.gmField === 'hidden') {
                const idx = Number(target.closest('[data-metric-index]')?.dataset.metricIndex);
                if (state.metrics[idx]) {
                    state.metrics[idx].hidden = Boolean(target.checked);
                    notifyChange();
                }
                return;
            }
            if (target.dataset.gsField === 'isInitial') {
                const idx = Number(target.closest('[data-stage-index]')?.dataset.stageIndex);
                if (state.stages[idx]) {
                    state.stages.forEach((st, i) => {
                        st.isInitial = i === idx ? Boolean(target.checked) : false;
                    });
                    renderStages(dict());
                    notifyChange();
                }
                return;
            }
            if (target.dataset.gsField === 'isEnding') {
                const idx = Number(target.closest('[data-stage-index]')?.dataset.stageIndex);
                if (state.stages[idx]) {
                    state.stages[idx].isEnding = Boolean(target.checked);
                    renderStages(dict());
                    notifyChange();
                }
                return;
            }
            if (target.dataset.gtField === 'toStageId') {
                const card = target.closest('[data-trans-index]');
                const sIdx = Number(card?.dataset.stageIndex);
                const tIdx = Number(card?.dataset.transIndex);
                if (state.stages[sIdx]?.transitions?.[tIdx]) {
                    state.stages[sIdx].transitions[tIdx].toStageId = target.value;
                    notifyChange();
                }
                return;
            }
            if (target.dataset.gtField === 'reversible') {
                const card = target.closest('[data-trans-index]');
                const sIdx = Number(card?.dataset.stageIndex);
                const tIdx = Number(card?.dataset.transIndex);
                if (state.stages[sIdx]?.transitions?.[tIdx]) {
                    state.stages[sIdx].transitions[tIdx].reversible = Boolean(target.checked);
                    notifyChange();
                }
            }
        });

        panel.addEventListener('click', (event) => {
            const toggleMetric = event.target.closest('[data-toggle-metric]');
            if (toggleMetric) {
                const idx = Number(toggleMetric.dataset.toggleMetric);
                if (collapsedMetrics.has(idx)) collapsedMetrics.delete(idx);
                else collapsedMetrics.add(idx);
                renderMetrics(dict());
                return;
            }
            const toggleStage = event.target.closest('[data-toggle-stage]');
            if (toggleStage) {
                const idx = Number(toggleStage.dataset.toggleStage);
                if (collapsedStages.has(idx)) collapsedStages.delete(idx);
                else collapsedStages.add(idx);
                renderStages(dict());
                return;
            }
            const removeMetric = event.target.closest('[data-remove-metric]');
            if (removeMetric) {
                collapsedMetrics.clear();
                state.metrics.splice(Number(removeMetric.dataset.removeMetric), 1);
                renderMetrics(dict());
                notifyChange();
                return;
            }
            const removeStage = event.target.closest('[data-remove-stage]');
            if (removeStage) {
                const idx = Number(removeStage.dataset.removeStage);
                const removed = state.stages[idx];
                if (removed && state.stageImages[removed.id]) {
                    delete state.stageImages[removed.id];
                }
                collapsedStages.clear();
                state.stages.splice(idx, 1);
                if (state.stages.length > 0 && !state.stages.some((s) => s.isInitial)) {
                    state.stages[0].isInitial = true;
                }
                renderStages(dict());
                notifyChange();
                return;
            }
            const addTrans = event.target.closest('[data-add-trans]');
            if (addTrans) {
                const sIdx = Number(addTrans.dataset.addTrans);
                const stage = state.stages[sIdx];
                if (!stage || (stage.transitions || []).length >= MAX_TRANSITIONS) return;
                const fallbackTarget = state.stages.find((other) => other.id !== stage.id);
                stage.transitions = stage.transitions || [];
                stage.transitions.push({
                    id: `${stage.id}_to_${stage.transitions.length + 1}`,
                    toStageId: fallbackTarget ? fallbackTarget.id : '',
                    priority: 100,
                    reversible: false,
                    conditionsText: 'intimacy >= 40',
                    narrativeTrigger: '',
                    transitionBeat: '',
                    milestoneTitle: '',
                });
                renderStages(dict());
                notifyChange();
                return;
            }
            const removeTrans = event.target.closest('[data-remove-trans]');
            if (removeTrans) {
                const [sIdx, tIdx] = removeTrans.dataset.removeTrans.split(':').map(Number);
                if (state.stages[sIdx]?.transitions) {
                    state.stages[sIdx].transitions.splice(tIdx, 1);
                    renderStages(dict());
                    notifyChange();
                }
                return;
            }
            const pickImg = event.target.closest('[data-pick-stage-img]');
            if (pickImg && stageImgInput) {
                const [sIdxStr, kind] = pickImg.dataset.pickStageImg.split(':');
                pendingImageTarget = { stageIndex: Number(sIdxStr), kind };
                stageImgInput.click();
                return;
            }
            const clearImg = event.target.closest('[data-clear-stage-img]');
            if (clearImg) {
                const [sIdxStr, kind] = clearImg.dataset.clearStageImg.split(':');
                const stage = state.stages[Number(sIdxStr)];
                if (stage && state.stageImages[stage.id]) {
                    if (kind === 'avatar') delete state.stageImages[stage.id].avatarDataUrl;
                    else delete state.stageImages[stage.id].illustrationDataUrl;
                    renderStages(dict());
                    notifyChange();
                }
            }
        });
    }

    function setData(raw, stageImages) {
        collapsedMetrics.clear();
        collapsedStages.clear();
        if (!raw || typeof raw !== 'object' || !Array.isArray(raw.stages) || raw.stages.length === 0) {
            state = createBlankState();
            render();
            return;
        }
        state = {
            enabled: true,
            intimacyLabel: String(raw.intimacy_label || raw.intimacyLabel || ''),
            intimacyDescription: String(raw.intimacy_description || raw.intimacyDescription || ''),
            initialIntimacy: clampInt(raw.initial_intimacy ?? raw.initialIntimacy, 0, 100, 20),
            maxIntimacyGain: clampInt(raw.max_intimacy_gain ?? raw.maxIntimacyGain, 1, 50, 8),
            maxIntimacyLoss: clampInt(raw.max_intimacy_loss ?? raw.maxIntimacyLoss, 1, 50, 12),
            metrics: Array.isArray(raw.metrics)
                ? raw.metrics.slice(0, MAX_METRICS).map((m) => ({
                      id: String(m.id || ''),
                      name: String(m.name || ''),
                      description: String(m.description || ''),
                      min: Number.isFinite(Number(m.min)) ? Math.trunc(Number(m.min)) : 0,
                      max: Number.isFinite(Number(m.max)) ? Math.trunc(Number(m.max)) : 100,
                      initial: Number.isFinite(Number(m.initial)) ? Math.trunc(Number(m.initial)) : 0,
                      maxGain: Number.isFinite(Number(m.max_gain ?? m.maxGain))
                          ? Math.trunc(Number(m.max_gain ?? m.maxGain))
                          : 10,
                      maxLoss: Number.isFinite(Number(m.max_loss ?? m.maxLoss))
                          ? Math.trunc(Number(m.max_loss ?? m.maxLoss))
                          : 10,
                      hidden: Boolean(m.hidden),
                  }))
                : [],
            stages: raw.stages.slice(0, MAX_STAGES).map((s) => ({
                id: String(s.id || ''),
                name: String(s.name || ''),
                summary: String(s.summary || ''),
                isInitial: Boolean(s.is_initial ?? s.isInitial),
                isEnding: Boolean(s.is_ending ?? s.isEnding),
                promptOverlay: String(s.prompt_overlay ?? s.promptOverlay ?? ''),
                transitions: Array.isArray(s.transitions)
                    ? s.transitions.slice(0, MAX_TRANSITIONS).map((t) => ({
                          id: String(t.id || ''),
                          toStageId: String(t.to_stage_id || t.toStageId || ''),
                          priority: Number.isFinite(Number(t.priority)) ? Math.trunc(Number(t.priority)) : 100,
                          reversible: Boolean(t.reversible),
                          conditionsText: formatConditionsLines(t.conditions),
                          narrativeTrigger: String(t.narrative_trigger ?? t.narrativeTrigger ?? ''),
                          transitionBeat: String(t.transition_beat ?? t.transitionBeat ?? ''),
                          milestoneTitle: String(t.milestone_title ?? t.milestoneTitle ?? ''),
                      }))
                    : [],
            })),
            stageImages: stageImages && typeof stageImages === 'object' ? JSON.parse(JSON.stringify(stageImages)) : {},
        };
        render();
    }

    function getDraftState() {
        return {
            enabled: state.enabled,
            data: state.enabled ? buildPayload() : null,
            stageImages: state.stageImages,
        };
    }

    function setDraftState(draft) {
        if (!draft || !draft.enabled || !draft.data) {
            state = createBlankState();
            render();
            return;
        }
        setData(draft.data, draft.stageImages || {});
    }

    function refreshLanguage() {
        const d = dict();
        const setText = (id, text) => {
            const el = document.getElementById(id);
            if (el && text) el.textContent = text;
        };
        setText('lbl-GrowthEnable', d.GrowthEnable);
        setText('hint-GrowthEnable', d.GrowthEnableHint);
        setText('lbl-GrowthIntimacySection', d.GrowthIntimacySection);
        setText('lbl-GrowthIntimacyLabel', d.GrowthIntimacyLabel);
        setText('lbl-GrowthIntimacyDesc', d.GrowthIntimacyDesc);
        setText('lbl-GrowthInitialIntimacy', d.GrowthInitial);
        setText('lbl-GrowthMaxIntimacyGain', d.GrowthMaxGain);
        setText('lbl-GrowthMaxIntimacyLoss', d.GrowthMaxLoss);
        setText('lbl-GrowthMetricsTitle', d.GrowthMetricsTitle);
        setText('btn-AddGrowthMetric', d.GrowthAddMetric);
        setText('lbl-GrowthStagesTitle', d.GrowthStagesTitle);
        setText('btn-AddGrowthStage', d.GrowthAddStage);
        setText('btn-ImportGrowth', d.ImportWorldInfo || d.GrowthImportJson);
        setText('btn-ExportGrowth', d.ExportWorldInfo || d.GrowthExportJson);

        const labelEl = document.getElementById('GrowthIntimacyLabel');
        if (labelEl && d.GrowthIntimacyLabelPlaceholder) {
            labelEl.placeholder = d.GrowthIntimacyLabelPlaceholder;
        }
        const descEl = document.getElementById('GrowthIntimacyDesc');
        if (descEl && d.GrowthIntimacyDescPlaceholder) {
            descEl.placeholder = d.GrowthIntimacyDescPlaceholder;
        }
        render();
    }

    window.LFGrowth = {
        init(callback) {
            onChange = typeof callback === 'function' ? callback : function () {};
            bind();
            render();
        },
        hasContent() {
            return state.enabled && state.stages.length > 0;
        },
        getData() {
            return state.enabled ? buildPayload() : null;
        },
        getStageImages() {
            return state.stageImages;
        },
        setData,
        getDraftState,
        setDraftState,
        validate() {
            const errors = validateAll();
            return errors.length ? errors[0] : null;
        },
        validateAll,
        reset() {
            collapsedMetrics.clear();
            collapsedStages.clear();
            state = createBlankState();
            render();
        },
        refreshLanguage,
    };
})();
