/* Styled select controls for the LumenFlow generator. */
(function () {
    const OPEN_CLASS = 'is-open';
    const UP_CLASS = 'is-up';
    const SELECTED_CLASS = 'is-selected';
    const ACTIVE_CLASS = 'is-active';
    const OPTION_HEIGHT = 280;

    let nextId = 1;
    let openWrapper = null;

    function closeMenu(wrapper, focusTrigger) {
        if (!wrapper || !wrapper.classList.contains(OPEN_CLASS)) return;
        wrapper.classList.remove(OPEN_CLASS);
        const trigger = wrapper.querySelector('.lf-select-trigger');
        if (trigger) {
            trigger.setAttribute('aria-expanded', 'false');
            trigger.removeAttribute('aria-activedescendant');
            if (focusTrigger) trigger.focus();
        }
        if (openWrapper === wrapper) openWrapper = null;
    }

    function closeOtherMenus(nextWrapper) {
        if (openWrapper && openWrapper !== nextWrapper) {
            closeMenu(openWrapper, false);
        }
    }

    function enhance(select) {
        if (select.dataset.lfEnhanced === 'true') return;
        select.dataset.lfEnhanced = 'true';

        const baseId = 'lf-select-' + nextId++;
        const wrapper = document.createElement('div');
        wrapper.className = 'lf-select';
        select.parentNode.insertBefore(wrapper, select);
        wrapper.appendChild(select);

        select.classList.add('lf-select-native');
        select.setAttribute('tabindex', '-1');
        select.setAttribute('aria-hidden', 'true');

        const trigger = document.createElement('div');
        trigger.className = 'lf-select-trigger';
        trigger.setAttribute('role', 'combobox');
        trigger.setAttribute('tabindex', '0');
        trigger.setAttribute('aria-haspopup', 'listbox');
        trigger.setAttribute('aria-expanded', 'false');
        trigger.setAttribute('aria-controls', baseId + '-menu');

        const label = select.closest('.form-group')?.querySelector('label');
        const selectLabel = select.getAttribute('aria-label');
        if (label && label.id) {
            trigger.setAttribute('aria-labelledby', label.id);
        } else if (label && label.textContent.trim()) {
            trigger.setAttribute('aria-label', label.textContent.trim());
        }
        if (selectLabel) trigger.setAttribute('aria-label', selectLabel);

        const value = document.createElement('span');
        value.className = 'lf-select-value';
        const arrow = document.createElement('span');
        arrow.className = 'lf-select-arrow';
        arrow.setAttribute('aria-hidden', 'true');
        trigger.append(value, arrow);

        const menu = document.createElement('div');
        menu.className = 'lf-select-menu';
        menu.id = baseId + '-menu';
        menu.setAttribute('role', 'listbox');

        wrapper.append(trigger, menu);

        let optionNodes = [];
        let activeIndex = 0;

        const selectedOption = () => {
            const index = select.selectedIndex;
            return index >= 0 ? select.options[index] : null;
        };

        function updateActive() {
            optionNodes.forEach((item, index) => {
                item.classList.toggle(ACTIVE_CLASS, index === activeIndex);
            });
            const active = optionNodes[activeIndex];
            if (active) {
                trigger.setAttribute('aria-activedescendant', active.id);
                if (wrapper.classList.contains(OPEN_CLASS)) {
                    active.scrollIntoView({ block: 'nearest' });
                }
            } else {
                trigger.removeAttribute('aria-activedescendant');
            }
        }

        function sync() {
            const option = selectedOption();
            value.textContent = option ? option.textContent : '';
            trigger.classList.toggle(
                'is-placeholder',
                !option || option.value === ''
            );
            const selectedIndex = select.selectedIndex;
            optionNodes.forEach((item, index) => {
                const current = select.options[index];
                if (!current) return;
                item.textContent = current.textContent;
                const isSelected = index === selectedIndex;
                item.classList.toggle(SELECTED_CLASS, isSelected);
                item.setAttribute('aria-selected', String(isSelected));
            });
            if (wrapper.classList.contains(OPEN_CLASS)) {
                activeIndex = selectedIndex >= 0 ? selectedIndex : 0;
                updateActive();
            }
        }

        function choose(index) {
            const option = select.options[index];
            if (!option) return;
            select.value = option.value;
            select.dispatchEvent(new Event('input', { bubbles: true }));
            select.dispatchEvent(new Event('change', { bubbles: true }));
            closeMenu(wrapper, true);
        }

        function openMenu() {
            if (select.disabled) return;
            closeOtherMenus(wrapper);
            openWrapper = wrapper;
            wrapper.classList.add(OPEN_CLASS);
            wrapper.classList.remove(UP_CLASS);
            trigger.setAttribute('aria-expanded', 'true');
            activeIndex = select.selectedIndex >= 0 ? select.selectedIndex : 0;
            updateActive();
            requestAnimationFrame(() => {
                if (!wrapper.classList.contains(OPEN_CLASS)) return;
                const rect = trigger.getBoundingClientRect();
                const menuHeight = Math.min(menu.scrollHeight, OPTION_HEIGHT);
                if (
                    rect.bottom + menuHeight + 12 > window.innerHeight &&
                    rect.top - menuHeight - 12 > 0
                ) {
                    wrapper.classList.add(UP_CLASS);
                }
                updateActive();
            });
        }

        function toggleMenu() {
            if (wrapper.classList.contains(OPEN_CLASS)) {
                closeMenu(wrapper, false);
            } else {
                openMenu();
            }
        }

        function rebuildOptions() {
            menu.textContent = '';
            optionNodes = Array.from(select.options).map((option, index) => {
                const item = document.createElement('div');
                item.className = 'lf-select-option';
                item.id = baseId + '-option-' + index;
                item.setAttribute('role', 'option');
                item.textContent = option.textContent;
                item.addEventListener('mouseenter', () => {
                    activeIndex = index;
                    updateActive();
                });
                item.addEventListener('click', (event) => {
                    event.preventDefault();
                    event.stopPropagation();
                    choose(index);
                });
                menu.appendChild(item);
                return item;
            });
            sync();
        }

        trigger.addEventListener('click', (event) => {
            event.stopPropagation();
            trigger.focus();
            toggleMenu();
        });

        trigger.addEventListener('keydown', (event) => {
            const key = event.key;
            const isOpen = wrapper.classList.contains(OPEN_CLASS);
            if (key === 'Escape') {
                if (isOpen) {
                    event.preventDefault();
                    closeMenu(wrapper, true);
                }
                return;
            }
            if (key === 'Tab') {
                if (isOpen) closeMenu(wrapper, false);
                return;
            }
            if (key === 'ArrowDown' || key === 'ArrowUp') {
                event.preventDefault();
                if (!isOpen) {
                    openMenu();
                    return;
                }
                if (optionNodes.length === 0) return;
                const direction = key === 'ArrowDown' ? 1 : -1;
                activeIndex =
                    (activeIndex + direction + optionNodes.length) %
                    optionNodes.length;
                updateActive();
                return;
            }
            if (key === 'Home' || key === 'End') {
                event.preventDefault();
                if (!isOpen) openMenu();
                if (optionNodes.length === 0) return;
                activeIndex = key === 'Home' ? 0 : optionNodes.length - 1;
                updateActive();
                return;
            }
            if (key === 'Enter' || key === ' ') {
                event.preventDefault();
                if (!isOpen) {
                    openMenu();
                } else {
                    choose(activeIndex);
                }
            }
        });

        select.addEventListener('change', sync);

        const valueDescriptor = Object.getOwnPropertyDescriptor(
            HTMLSelectElement.prototype,
            'value'
        );
        if (valueDescriptor && valueDescriptor.get && valueDescriptor.set) {
            Object.defineProperty(select, 'value', {
                configurable: true,
                get() {
                    return valueDescriptor.get.call(select);
                },
                set(next) {
                    valueDescriptor.set.call(select, next);
                    sync();
                },
            });
        }

        wrapper._lfRefresh = rebuildOptions;
        rebuildOptions();
    }

    function refreshAll() {
        document.querySelectorAll('.lf-select').forEach((wrapper) => {
            if (typeof wrapper._lfRefresh === 'function') {
                wrapper._lfRefresh();
            }
        });
    }

    function enhanceAll(root) {
        const scope = root || document;
        scope
            .querySelectorAll('select:not([data-lf-enhanced="true"])')
            .forEach(enhance);
    }

    document.addEventListener('click', (event) => {
        if (openWrapper && !openWrapper.contains(event.target)) {
            closeMenu(openWrapper, false);
        }
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && openWrapper) {
            closeMenu(openWrapper, true);
        }
    });

    window.addEventListener('resize', () => {
        if (openWrapper) closeMenu(openWrapper, false);
    });

    window.LFSelect = { enhanceAll, refreshAll };
    enhanceAll(document);
})();
