/* =========================================================
   SOVEX GARAGE NUI - app.js (fixed buttons + keyboard)
   ========================================================= */

let vehicles = [];
let selected = 0;

let TEXT = {
    vehiclesStored: 'Tus vehículos guardados',
    hint: '↑↓ / rueda: seleccionar • Enter: sacar • ESC: cerrar',
    stored: 'GUARDADO',
    out: 'FUERA',
    take: 'SACAR VEHÍCULO',
    close: 'CERRAR',
    fuel: 'Fuel',
    engine: 'Motor',
    body: 'Carrocería',
    tagExcellent: 'EXCELENTE',
    tagGood: 'BUENO',
    tagMedium: 'MEDIO',
    tagBad: 'MALO',
};

const ui = document.getElementById('ui');
const garageTitle = document.getElementById('garageTitle');
const listEl = document.getElementById('vehList');

// Siempre empieza cerrado
window.addEventListener('DOMContentLoaded', () => {
    ui.classList.add('hidden');
});

// -------------------------
// NUI POST helper
// -------------------------
function postNui(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
}

// -------------------------
// Helpers
// -------------------------
function clamp(v) {
    v = Number(v) || 0;
    return Math.max(0, Math.min(100, v));
}

function getCss(varName) {
    return getComputedStyle(document.documentElement).getPropertyValue(varName).trim();
}

function color(p) {
    if (p >= 75) return getCss('--good');
    if (p >= 45) return getCss('--warn');
    return getCss('--bad');
}

function tag(p) {
    if (p >= 75) return TEXT.tagExcellent || 'EXCELENTE';
    if (p >= 45) return TEXT.tagGood || 'BUENO';
    if (p >= 25) return TEXT.tagMedium || 'MEDIO';
    return TEXT.tagBad || 'MALO';
}

function applyTheme(t) {
    const r = document.documentElement.style;
    if (!t) return;

    if (t.primary) r.setProperty('--primary', t.primary);
    if (t.bg) r.setProperty('--bg', t.bg);
    if (t.border) r.setProperty('--border', t.border);
    if (t.text) r.setProperty('--text', t.text);
    if (t.muted) r.setProperty('--muted', t.muted);
    if (t.good) r.setProperty('--good', t.good);
    if (t.warn) r.setProperty('--warn', t.warn);
    if (t.bad) r.setProperty('--bad', t.bad);
}

function escapeHtml(str) {
    return String(str ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

// -------------------------
// SVGs
// -------------------------
function vehSvgIcon() {
    return `
    <svg viewBox="0 0 24 24" class="iconSvg" fill="none" aria-hidden="true">
      <path d="M12 2l7 4v6c0 5-3 9-7 10-4-1-7-5-7-10V6l7-4Z" stroke="currentColor" stroke-width="2" />
      <path d="M9.5 12.5l1.8 1.8L15.5 10" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
  `;
}

function svgIcon(kind) {
    if (kind === 'fuel') {
        return `
      <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path d="M7 3h8v6H7V3Z" stroke="currentColor" stroke-width="2" />
        <path d="M6 9h10v12H6V9Z" stroke="currentColor" stroke-width="2" />
        <path d="M16 6h2l2 2v11a2 2 0 0 1-2 2h-2" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      </svg>
    `;
    }
    if (kind === 'engine') {
        return `
      <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path d="M7 10V8h4l1-2h4v2h2v4h-2v3a3 3 0 0 1-3 3H9a3 3 0 0 1-3-3v-2H4v-3h2V10h1Z"
          stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
      </svg>
    `;
    }
    return `
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M7 15l1-5h8l1 5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      <path d="M6 15h12v4H6v-4Z" stroke="currentColor" stroke-width="2"/>
      <path d="M8 19v2M16 19v2" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
    </svg>
  `;
}

// -------------------------
// Render
// -------------------------
function miniStat(kind, label, pct) {
    const p = clamp(pct);
    const c = color(p);
    const t = tag(p);

    return `
    <div class="miniStat">
      <div class="miniRow">
        <div class="miniLabel">
          ${svgIcon(kind)}
          <span>${escapeHtml(label)}</span>
        </div>
      </div>

      <div class="miniBar">
        <div class="miniFill" style="width:${p}%;background:${c}"></div>
      </div>

      <div class="miniTag">${escapeHtml(t)}</div>
    </div>
  `;
}

function renderList() {
    listEl.innerHTML = '';

    vehicles.forEach((v, i) => {
        const div = document.createElement('div');
        div.className = 'item' + (i === selected ? ' selected' : '');

        const storedText = v.stored ? (TEXT.stored || 'GUARDADO') : (TEXT.out || 'FUERA');

        const detailsHtml =
            i === selected
                ? `
          <div class="details">
            <div class="statsRow">
              ${miniStat('fuel', TEXT.fuel || 'Fuel', clamp(v.fuel))}
              ${miniStat('engine', TEXT.engine || 'Motor', clamp(v.engine))}
              ${miniStat('body', TEXT.body || 'Carrocería', clamp(v.body))}
            </div>

            <div class="itemActions">
              <button class="btn primary" data-action="take">${TEXT.take || 'SACAR VEHÍCULO'}</button>
              <button class="btn" data-action="close">${TEXT.close || 'CERRAR'}</button>
            </div>
          </div>
        `
                : '';

        div.innerHTML = `
      <div class="vehIcon">${vehSvgIcon()}</div>

      <div class="main">
        <div class="top">
          <div>
            <div class="name">${escapeHtml(v.name || 'Vehículo')}</div>
            <div class="meta">
              <span>[${escapeHtml(v.plate || '????')}]</span>
              <span class="badge">${storedText}</span>
            </div>
          </div>
        </div>
        ${detailsHtml}
      </div>
    `;

        // Click en item (NO en botones) = seleccionar
        div.addEventListener('click', (ev) => {
            if (ev.target.closest('button[data-action]')) return;
            select(i);
        });

        // ✅ Listeners DIRECTOS a los botones (esto evita 100% el problema)
        const takeBtn = div.querySelector('button[data-action="take"]');
        const closeBtn = div.querySelector('button[data-action="close"]');

        if (takeBtn) {
            takeBtn.addEventListener('click', (ev) => {
                ev.preventDefault();
                ev.stopPropagation();
                console.log('[NUI] CLICK TAKE', { index: selected });
                takeVehicle();
            });
        }
        if (closeBtn) {
            closeBtn.addEventListener('click', (ev) => {
                ev.preventDefault();
                ev.stopPropagation();
                console.log('[NUI] CLICK CLOSE');
                closeUI();
            });
        }

        listEl.appendChild(div);
    });
}

// -------------------------
// Selection / Actions
// -------------------------
function select(i) {
    if (i < 0 || i >= vehicles.length) return;
    selected = i;
    renderList();

    console.log('[NUI] SELECT', { index: selected });

    postNui('selectVehicle', { index: selected }).catch(() => { });
}

function closeUI() {
    console.log('[NUI] POST close');
    postNui('close').catch(() => { });
}

function takeVehicle() {
    console.log('[NUI] POST takeVehicle', { index: selected });
    postNui('takeVehicle', { index: selected }).catch(() => { });
}

// -------------------------
// Messages from Lua
// -------------------------
window.addEventListener('message', (e) => {
    const msg = e.data;
    if (!msg || !msg.action) return;

    if (msg.action === 'config') {
        if (msg.texts && typeof msg.texts === 'object') {
            TEXT = { ...TEXT, ...msg.texts };
        }
        if (msg.theme && typeof msg.theme === 'object') {
            applyTheme(msg.theme);
        }

        const sub = document.querySelector('.subtitle');
        if (sub) sub.textContent = TEXT.vehiclesStored || sub.textContent;

        const hint = document.querySelector('.hint');
        if (hint) hint.textContent = TEXT.hint || hint.textContent;

        return;
    }

    if (msg.action === 'open') {
        ui.classList.remove('hidden');

        vehicles = Array.isArray(msg.vehicles) ? msg.vehicles : [];
        selected = 0;

        garageTitle.textContent = msg.title || 'GARAGE';

        renderList();
        if (vehicles.length) select(0);
        return;
    }

    if (msg.action === 'hide') {
        ui.classList.add('hidden');
        vehicles = [];
        selected = 0;
        listEl.innerHTML = '';
        return;
    }
});

// -------------------------
// Keyboard
// -------------------------
document.addEventListener(
    'keydown',
    (ev) => {
        if (ui.classList.contains('hidden')) return;

        if (['Escape', 'ArrowDown', 'ArrowUp', 'Enter'].includes(ev.key)) {
            ev.preventDefault();
            ev.stopPropagation();
        }

        if (ev.key === 'Escape') closeUI();
        if (ev.key === 'ArrowDown') select(selected + 1);
        if (ev.key === 'ArrowUp') select(selected - 1);
        if (ev.key === 'Enter') takeVehicle();
    },
    true
);
