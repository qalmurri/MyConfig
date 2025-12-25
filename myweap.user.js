// ==UserScript==
// @name         Copy Judul
// @namespace    http://tampermonkey.net/
// @version      1.7
// @description  Untuk pribadi dan website tertentu 
// @match        *://*/*
// @grant        GM_setClipboard
// ==/UserScript==

(function () {
    'use strict';

    let shortcutsActive = false;
    let shortcutMap = {};
    let shortcutLabels = [];

    // buffer untuk shortcut multi-digit (a1, a2, dst)
    let keyBuffer = '';
    let bufferTimer = null;

    function notify(msg) {
        const n = document.createElement('div');
        n.textContent = msg;
        n.style.position = 'fixed';
        n.style.top = '10px';
        n.style.right = '10px';
        n.style.background = 'yellow';
        n.style.padding = '5px 10px';
        n.style.border = '1px solid black';
        n.style.zIndex = 9999;
        document.body.appendChild(n);
        setTimeout(() => n.remove(), 2000);
    }

    function generateShortcuts(n) {
        const chars = 'asdfghjklqwertyuiopzxcvbnm';
        let result = [];
        for (let i = 0; i < n; i++) {
            result.push(
                chars[i % chars.length] +
                (i >= chars.length ? Math.floor(i / chars.length) : '')
            );
        }
        return result;
    }

    function copyToClipboard(text) {
        GM_setClipboard(text);
        notify(`Copied: ${text}`);
    }

    function activateShortcuts() {
        if (shortcutsActive) return;
        shortcutsActive = true;

        const titles = document.querySelectorAll('#dataTable td.sorting_1 span');
        if (!titles.length) {
            notify("Tidak ada judul ditemukan!");
            shortcutsActive = false;
            return;
        }

        const shortcuts = generateShortcuts(titles.length);
        shortcutMap = {};
        shortcutLabels = [];

        titles.forEach((title, index) => {
            const shortcut = shortcuts[index];
            shortcutMap[shortcut] = title.innerText;

            const label = document.createElement('span');
            label.textContent = `[${shortcut}]`;
            label.style.color = 'red';
            label.style.fontWeight = 'bold';
            label.style.marginLeft = '5px';
            title.parentElement.appendChild(label);

            shortcutLabels.push(label);
        });

        document.addEventListener('keydown', handleKeydown);
        notify("Shortcut ON (Shift+C untuk OFF)");
    }

    function deactivateShortcuts() {
        shortcutsActive = false;
        shortcutMap = {};
        keyBuffer = '';

        shortcutLabels.forEach(label => label.remove());
        shortcutLabels = [];

        document.removeEventListener('keydown', handleKeydown);
        notify("Shortcut OFF (Shift+C untuk ON)");
    }

    function handleKeydown(e) {
        const activeTag = document.activeElement.tagName;
        if (activeTag === 'INPUT' || activeTag === 'TEXTAREA') return;

        const key = e.key.toLowerCase();

        // hanya terima huruf & angka
        if (!/^[a-z0-9]$/.test(key)) return;

        keyBuffer += key;

        clearTimeout(bufferTimer);
        bufferTimer = setTimeout(() => {
            if (shortcutMap[keyBuffer]) {
                copyToClipboard(shortcutMap[keyBuffer]);
            }
            keyBuffer = '';
        }, 300);
    }

    // Shift + C = toggle shortcut
    document.addEventListener('keydown', function (e) {
        const activeTag = document.activeElement.tagName;
        if (activeTag === 'INPUT' || activeTag === 'TEXTAREA') return;

        if (e.shiftKey && e.key.toLowerCase() === 'c') {
            observeTable(() => {
                shortcutsActive ? deactivateShortcuts() : activateShortcuts();
            });
        }
    });

    function observeTable(callback) {
        const table = document.querySelector('#dataTable');
        if (!table) {
            notify("Menunggu tabel muncul...");
            const obs = new MutationObserver((_, obs) => {
                if (document.querySelector('#dataTable')) {
                    obs.disconnect();
                    callback();
                }
            });
            obs.observe(document.body, { childList: true, subtree: true });
        } else {
            callback();
        }
    }

})();
