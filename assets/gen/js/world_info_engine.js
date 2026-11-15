/* World-info activation engine for the browser generator. */
(function () {
    const CJK_RANGES = [
        [0x3000, 0x303f],
        [0x3040, 0x30ff],
        [0x3400, 0x4dbf],
        [0x4e00, 0x9fff],
        [0xac00, 0xd7af],
        [0xf900, 0xfaff],
    ];

    function isCjk(codePoint) {
        return CJK_RANGES.some(
            ([start, end]) => codePoint >= start && codePoint <= end
        );
    }

    function estimateTokens(text) {
        const value = String(text || '');
        if (!value) return 0;
        let cjk = 0;
        let other = 0;
        for (const char of value) {
            if (isCjk(char.codePointAt(0))) cjk++;
            else other++;
        }
        return cjk + Math.ceil(other / 4);
    }

    function runeLength(value) {
        return Array.from(String(value || '')).length;
    }

    function contains(text, key, caseSensitive) {
        if (!key) return false;
        if (caseSensitive) return text.includes(key);
        return text.toLowerCase().includes(key.toLowerCase());
    }

    function escapeRegExp(value) {
        return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }

    function matches(entry, key, scanText) {
        if (!key) return false;
        switch (entry.match) {
            case 'regex':
                try {
                    return new RegExp(
                        key,
                        entry.case_sensitive ? '' : 'i'
                    ).test(scanText);
                } catch (_) {
                    return false;
                }
            case 'word':
                if (/[^\x00-\x7F]/.test(key)) {
                    return contains(scanText, key, entry.case_sensitive);
                }
                try {
                    return new RegExp(
                        `\\b${escapeRegExp(key)}\\b`,
                        entry.case_sensitive ? '' : 'i'
                    ).test(scanText);
                } catch (_) {
                    return false;
                }
            case 'substring':
            default:
                return contains(scanText, key, entry.case_sensitive);
        }
    }

    function findMatchedKey(entry, keys, scanText) {
        let best = null;
        for (const key of keys || []) {
            if (!matches(entry, key, scanText)) continue;
            if (best === null || runeLength(key) > runeLength(best)) {
                best = key;
            }
        }
        return best;
    }

    function scanTiming(entry, messages) {
        let lastMatchIndex = null;
        let previousMatchIndex = null;
        let matchedKey = null;
        let hadPrimaryBeforeSecondary = false;

        messages.forEach((message, index) => {
            const primary = findMatchedKey(entry, entry.keys, message);
            if (primary === null) return;
            if (
                entry.secondary_keys &&
                entry.secondary_keys.length > 0 &&
                findMatchedKey(entry, entry.secondary_keys, message) === null
            ) {
                hadPrimaryBeforeSecondary = true;
                return;
            }
            previousMatchIndex = lastMatchIndex;
            lastMatchIndex = index;
            matchedKey = primary;
        });

        const distanceFromEnd =
            lastMatchIndex === null
                ? 1 << 30
                : messages.length - 1 - lastMatchIndex;
        const previousDistanceFromEnd =
            previousMatchIndex === null
                ? null
                : messages.length - 1 - previousMatchIndex;

        return {
            lastMatchIndex,
            matchedKey,
            distanceFromEnd,
            previousDistanceFromEnd,
            hadPrimaryBeforeSecondary,
        };
    }

    function isCoolingDown(entry, timing) {
        if ((entry.cooldown || 0) <= 0) return false;
        const previous = timing.previousDistanceFromEnd;
        if (previous === null) return false;
        return previous > 0 && previous <= entry.cooldown;
    }

    function stableRoll(value) {
        let hash = 0x811c9dc5;
        for (let i = 0; i < value.length; i++) {
            hash ^= value.charCodeAt(i);
            hash = Math.imul(hash, 0x01000193) >>> 0;
        }
        return hash;
    }

    function passesProbability(entry, seed) {
        const probability = entry.probability ?? 100;
        if (probability >= 100) return true;
        if (probability <= 0) return false;
        return stableRoll(`${entry.id}\u0000${seed}`) % 100 < probability;
    }

    function compareCandidates(a, b) {
        const byPriority = (b.entry.priority || 0) - (a.entry.priority || 0);
        if (byPriority !== 0) return byPriority;
        const byKeyLength =
            runeLength(b.matchedKey) - runeLength(a.matchedKey);
        if (byKeyLength !== 0) return byKeyLength;
        return String(a.entry.id).localeCompare(String(b.entry.id));
    }

    function activate(info, scanText, options = {}) {
        const entries = info.entries || [];
        const messages =
            !options.scanMessages || options.scanMessages.length === 0
                ? [scanText]
                : options.scanMessages;
        const reasons = new Map();
        const candidates = [];
        const candidateIds = new Set();

        for (const entry of entries) {
            if (entry.enabled === false) {
                reasons.set(entry.id, 'disabled');
                continue;
            }

            const directPrimary = findMatchedKey(entry, entry.keys, scanText);
            const directSecondaryMissing =
                entry.secondary_keys &&
                entry.secondary_keys.length > 0 &&
                findMatchedKey(entry, entry.secondary_keys, scanText) === null;

            const timing = scanTiming(entry, messages);
            const stickyActive =
                timing.lastMatchIndex !== null &&
                (entry.sticky || 0) > 0 &&
                timing.distanceFromEnd <= entry.sticky;

            if (directPrimary === null && !stickyActive) {
                reasons.set(
                    entry.id,
                    timing.hadPrimaryBeforeSecondary
                        ? 'missingSecondaryKey'
                        : 'noPrimaryKey'
                );
                continue;
            }
            if (
                directPrimary !== null &&
                directSecondaryMissing &&
                !stickyActive
            ) {
                reasons.set(entry.id, 'missingSecondaryKey');
                continue;
            }
            if (!stickyActive && isCoolingDown(entry, timing)) {
                reasons.set(entry.id, 'cooldown');
                continue;
            }
            if (!passesProbability(entry, scanText)) {
                reasons.set(entry.id, 'probability');
                continue;
            }

            const matchedKey =
                directPrimary || timing.matchedKey || entry.keys[0];
            candidates.push({
                entry,
                matchedKey,
                viaRecursion: false,
                recursionLevel: 0,
                viaSticky: stickyActive && directPrimary === null,
            });
            candidateIds.add(entry.id);
        }

        const recursionDepth = info.recursion_depth || 0;
        if (recursionDepth > 0 && candidates.length > 0) {
            let frontier = candidates.filter(
                (candidate) => candidate.entry.recursive
            );
            for (
                let level = 1;
                level <= recursionDepth && frontier.length > 0;
                level++
            ) {
                const nextFrontier = [];
                for (const parent of frontier) {
                    for (const entry of entries) {
                        if (
                            entry.enabled === false ||
                            candidateIds.has(entry.id)
                        ) {
                            continue;
                        }
                        const key = findMatchedKey(
                            entry,
                            entry.keys,
                            parent.entry.content || ''
                        );
                        if (key === null) continue;
                        if (
                            entry.secondary_keys &&
                            entry.secondary_keys.length > 0 &&
                            findMatchedKey(
                                entry,
                                entry.secondary_keys,
                                parent.entry.content || ''
                            ) === null
                        ) {
                            continue;
                        }
                        if (!passesProbability(entry, scanText)) {
                            reasons.set(entry.id, 'probability');
                            continue;
                        }
                        const candidate = {
                            entry,
                            matchedKey: key,
                            viaRecursion: true,
                            recursionLevel: level,
                            viaSticky: false,
                        };
                        candidates.push(candidate);
                        candidateIds.add(entry.id);
                        reasons.delete(entry.id);
                        if (entry.recursive) nextFrontier.push(candidate);
                    }
                }
                frontier = nextFrontier;
            }
        }

        const groups = new Map();
        for (const candidate of candidates) {
            const group = String(candidate.entry.group || '').trim();
            if (!group) continue;
            if (!groups.has(group)) groups.set(group, []);
            groups.get(group).push(candidate);
        }
        const groupLosers = new Set();
        for (const groupCandidates of groups.values()) {
            groupCandidates.sort(compareCandidates);
            for (const loser of groupCandidates.slice(1)) {
                groupLosers.add(loser.entry.id);
            }
        }
        if (groupLosers.size > 0) {
            const remaining = candidates.filter(
                (candidate) => !groupLosers.has(candidate.entry.id)
            );
            candidates.length = 0;
            candidates.push(...remaining);
            for (const id of groupLosers) reasons.set(id, 'group');
        }

        for (const entry of entries) {
            if (!candidateIds.has(entry.id) && !reasons.has(entry.id)) {
                reasons.set(entry.id, 'noPrimaryKey');
            }
        }

        candidates.sort(compareCandidates);
        const matched = [];
        let entryTokens = 0;
        const budget = info.budget_tokens ?? 1000;
        for (const candidate of candidates) {
            const tokens = estimateTokens(candidate.entry.content);
            if (entryTokens + tokens > budget) {
                reasons.set(candidate.entry.id, 'budget');
                continue;
            }
            entryTokens += tokens;
            matched.push({
                entry: candidate.entry,
                matchedKey: candidate.matchedKey,
                tokens,
                viaRecursion: candidate.viaRecursion,
                recursionLevel: candidate.recursionLevel,
                viaSticky: candidate.viaSticky,
            });
            reasons.delete(candidate.entry.id);
        }

        const skipped = entries
            .filter((entry) => reasons.has(entry.id))
            .map((entry) => ({ entry, reason: reasons.get(entry.id) }));
        const backgroundTokens = estimateTokens(info.background);

        return {
            matched,
            skipped,
            backgroundTokens,
            entryTokens,
            totalTokens: backgroundTokens + entryTokens,
        };
    }

    function activateWithExpansion(
        info,
        historyTexts,
        { currentContent = '', currentAlreadyInHistory = false } = {}
    ) {
        const history = Array.isArray(historyTexts) ? historyTexts : [];

        function partsForDepth(depth) {
            const recent =
                history.length > depth ? history.slice(history.length - depth) : history;
            const parts = recent.slice();
            if (currentContent.trim() && !currentAlreadyInHistory) {
                parts.push(currentContent);
            }
            return parts;
        }

        let timingWindow = 0;
        for (const entry of info.entries || []) {
            timingWindow = Math.max(
                timingWindow,
                entry.sticky || 0,
                entry.cooldown || 0
            );
        }

        let depth = info.scan_depth || 0;
        let activation = null;
        while (true) {
            const directParts = partsForDepth(depth);
            const timingDepth = Math.max(depth, timingWindow);
            const timingParts = partsForDepth(timingDepth);
            activation = activate(info, directParts.join('\n'), {
                scanMessages: timingParts,
            });
            if (
                activation.matched.length >= (info.min_activations || 0) ||
                depth >= history.length
            ) {
                break;
            }
            let nextDepth = depth === 0 ? 1 : depth * 2;
            if (nextDepth > history.length) nextDepth = history.length;
            if (nextDepth <= depth) break;
            depth = nextDepth;
        }

        return {
            ...activation,
            scanDepthUsed: depth,
            historyCount: history.length,
            currentIncluded:
                Boolean(currentContent.trim()) && !currentAlreadyInHistory,
        };
    }

    function entryTitle(entry) {
        return String(entry.title || '').trim() || entry.id;
    }

    function worldHeader(info) {
        const name = String(info.name || '').trim();
        return name ? `[世界书 · ${name}]` : '[世界书]';
    }

    function formatEntries(info, entries) {
        const lines = [worldHeader(info)];
        for (const item of entries) {
            lines.push('', `[${entryTitle(item.entry)}]`, String(item.entry.content || '').trim());
        }
        return lines.join('\n');
    }

    function formatPositionBlock(activation, position, includeBackground) {
        const info = activation.info || {};
        const background =
            includeBackground && String(info.background || '').trim();
        const entries = activation.matched.filter(
            (item) =>
                String(item.entry.content || '').trim() &&
                (position === null || item.entry.position === position)
        );
        if (!background && entries.length === 0) return '';

        const lines = [worldHeader(info)];
        if (background) {
            lines.push('[世界背景]', String(info.background).trim());
        }
        for (const item of entries) {
            lines.push(
                '',
                `[${entryTitle(item.entry)}]`,
                String(item.entry.content || '').trim()
            );
        }
        return lines.join('\n');
    }

    function buildInjection(info, activation) {
        const withInfo = { ...activation, info };
        const grouped = new Map();
        for (const item of withInfo.matched) {
            if (
                item.entry.position !== 'at_depth' ||
                !String(item.entry.content || '').trim()
            ) {
                continue;
            }
            const depth = item.entry.depth || 0;
            if (!grouped.has(depth)) grouped.set(depth, []);
            grouped.get(depth).push(item);
        }
        const depths = Array.from(grouped.keys()).sort((a, b) => b - a);
        return {
            systemBlock: formatPositionBlock(withInfo, 'system', true),
            beforePresetBlock: formatPositionBlock(
                withInfo,
                'before_preset',
                false
            ),
            afterPresetBlock: formatPositionBlock(
                withInfo,
                'after_preset',
                false
            ),
            atDepth: depths.map((depth) => ({
                depth,
                text: formatEntries(info, grouped.get(depth)),
            })),
        };
    }

    window.LFWorldInfoEngine = {
        estimateTokens,
        activate,
        activateWithExpansion,
        buildInjection,
        formatPositionBlock,
        entryTitle,
        worldHeader,
    };
})();
