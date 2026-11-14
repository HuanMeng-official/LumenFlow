/* LumenFlow generator application. */
(function () {
    const UI = window.LF_I18N;
    const STORAGE_KEY = 'lumenflow_generator_v2';
    const LEGACY_STORAGE_KEY = 'lumenflow_autosave_data';
    const MAX_AVATAR_BYTES = 2 * 1024 * 1024;

    let currentLang = 'zh';
    let saveTimeout = null;
    let hideIndicatorTimeout = null;
    let toastTimeout = null;
    let clearConfirmPending = false;
    let clearConfirmTimeout = null;
    let avatarDataUrl = '';
    let activeTab = 'character';

    function dict() {
        return UI[currentLang] || UI.zh;
    }

    function showToast(message) {
        const toastEl = document.getElementById('toast');
        toastEl.innerText = message;
        toastEl.classList.add('show');
        clearTimeout(toastTimeout);
        toastTimeout = setTimeout(() => toastEl.classList.remove('show'), 2500);
    }

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

    function switchTab(name) {
        activeTab = name;
        document.querySelectorAll('.tab-button').forEach((button) => {
            button.classList.toggle('active', button.dataset.tab === name);
        });
        document.querySelectorAll('.tab-panel').forEach((panel) => {
            panel.classList.toggle('active', panel.dataset.panel === name);
        });
        if (name === 'export') {
            updateTokenCount();
            document.getElementById('preview-section').classList.add('active');
        }
        triggerAutoSave();
    }

    function collectCharacterFields() {
        const fields = [
            'RoleName', 'RoleNameEN', 'Identity', 'Philosophy', 'Appearance',
            'Personality', 'Addressing', 'Linguistic', 'Behavior', 'Interaction',
            'InternalMonologue', 'EmotionalDepth', 'KnowledgeFilter',
            'NegativeConstraints', 'Example', 'FileName', 'MetaAuthor',
            'MetaVersion', 'MetaLanguage', 'MetaTags', 'MetaIcon'
        ];
        const data = {};
        fields.forEach((field) => {
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
            if (['character', 'worldinfo', 'meta', 'export'].includes(data.tab)) {
                activeTab = data.tab;
            }
            if (data.InternalMonologue || data.EmotionalDepth ||
                data.KnowledgeFilter || data.NegativeConstraints) {
                document.getElementById('AdvancedOptionsPanel').open = true;
            }
            syncMetaName();
            renderAvatar();
        } catch (error) {
            console.error('Failed to load local storage data:', error);
        }
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
        localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
        const indicator = document.getElementById('save-indicator');
        indicator.classList.add('show');
        clearTimeout(hideIndicatorTimeout);
        hideIndicatorTimeout = setTimeout(
            () => indicator.classList.remove('show'),
            2000
        );
    }

    function triggerAutoSave() {
        clearTimeout(saveTimeout);
        saveTimeout = setTimeout(saveToLocalStorage, 1000);
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
        document.getElementById('FileName').value = '';
        document.getElementById('AdvancedOptionsPanel').open = false;
        window.LFWorldInfo.reset();
        clearAvatar(false);
        syncMetaName();
        updateTokenCount();
        saveToLocalStorage();
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

    function updateTokenCount() {
        const xmlText = buildXMLString();
        const preview = document.getElementById('xml-output');
        if (preview) preview.innerText = xmlText;

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

    function clearAvatar(save = true) {
        avatarDataUrl = '';
        renderAvatar();
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

    async function handleAvatarFile(file) {
        const d = dict();
        try {
            const bytes = new Uint8Array(await file.arrayBuffer());
            if (!isPng(bytes)) {
                showToast(d.AvatarInvalid);
                return;
            }
            const bitmap = await createImageBitmap(new Blob([bytes], { type: 'image/png' }));
            const longest = Math.max(bitmap.width, bitmap.height);
            const caps = [1024, 768, 512];
            let accepted = null;
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
                if (blob && blob.size <= MAX_AVATAR_BYTES) {
                    accepted = blob;
                    break;
                }
            }
            if (!accepted) {
                showToast(d.AvatarTooLarge);
                return;
            }
            const acceptedBytes = new Uint8Array(await accepted.arrayBuffer());
            avatarDataUrl = await bytesToDataUrl(acceptedBytes, 'image/png');
            renderAvatar();
            triggerAutoSave();
        } catch (error) {
            console.error(error);
            showToast(d.AvatarInvalid);
        }
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
            XmlTooLarge: 'El XML del personaje supera 200 KB y no se puede importar'
        }
    };

    function worldInfoErrorText(error) {
        const table = WI_ERRORS[currentLang] || WI_ERRORS.en;
        return (table[error.code] || error.code) + (error.title || '');
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
            showToast(worldInfoErrorText(wiError));
            return;
        }

        try {
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
                icon:
                    document.getElementById('MetaIcon').value || 'person.fill'
            };
            const language = document.getElementById('MetaLanguage').value;
            if (language) meta.language = language;

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
                _language: language || currentLang,
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

            const avatarFile = zip.file('character/avatar.png');
            if (avatarFile) {
                const bytes = await avatarFile.async('uint8array');
                avatarDataUrl = isPng(bytes)
                    ? await bytesToDataUrl(bytes, 'image/png')
                    : '';
            } else {
                avatarDataUrl = '';
            }
            renderAvatar();
            document.getElementById('FileName').value = safeFileName(
                (meta && meta.name) || document.getElementById('RoleName').value
            );
            autoResizeAllTextareas();
            updateTokenCount();
            saveToLocalStorage();
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
        setText('lbl-WorldInfoEntries', d.WorldInfoEntries);
        setText('lbl-MetaName', d.MetaName);
        setText('lbl-MetaAuthor', d.MetaAuthor);
        setText('lbl-MetaVersion', d.MetaVersion);
        setText('lbl-MetaLanguage', d.MetaLanguage);
        setText('lbl-MetaTags', d.MetaTags);
        setText('lbl-MetaIcon', d.MetaIcon);
        setText('lbl-Avatar', d.Avatar);
        setText('hint-Avatar', d.AvatarHint);
        setText('hint-Export', d.ExportHint);
        setText('hint-WorldInfoOptional', d.WorldInfoOptional);
        setText('tab-character', d.TabCharacter);
        setText('tab-worldinfo', d.TabWorldInfo);
        setText('tab-meta', d.TabMeta);
        setText('tab-export', d.TabExport);
        setText('btn-AddEntry', d.AddEntry);
        setText('btn-ChooseAvatar', d.ChooseAvatar);
        setText('btn-RemoveAvatar', d.RemoveAvatar);
        setText('btn-DownloadLumenflow', d.ExportLumenflow);
        setText('btn-ImportLumenflow', d.ImportLumenflow);
        setText('btn-ExportXml', d.ExportXml);
        setText('btn-DownloadXml', d.DownloadXml);
        setText('btn-Clear', d.BtnClear);
        setText('btn-Copy', d.BtnCopy || '复制内容');
        document.getElementById('btn-Clear').title = d.BtnClear;
        document.getElementById('btn-RemoveAvatar').disabled = !avatarDataUrl;
        window.LFWorldInfo.refreshLanguage();
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

    function init() {
        currentLang = 'zh';
        window.LF_CURRENT_LANG = currentLang;
        window.LFWorldInfo.init(triggerAutoSave);

        loadFromLocalStorage();
        if (UI[currentLang]) {
            document.getElementById('lang-selector').value = currentLang;
            window.LF_CURRENT_LANG = currentLang;
        }

        document.querySelectorAll('.tab-button').forEach((button) => {
            button.addEventListener('click', () => switchTab(button.dataset.tab));
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
        applyLanguageUI();
        switchTab(activeTab);
        autoResizeAllTextareas();
        updateTokenCount();
        syncMetaName();
    }

    function copyToClipboard() {
        const xml = buildXMLString();
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
                .writeText(xml)
                .then(() => showToast(d.Copied))
                .catch(() => fallbackCopy(xml));
        } else {
            fallbackCopy(xml);
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

    init();
})();
