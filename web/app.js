'use strict';

// ---------- Данные ----------

const MEALS = [
  { id: 'breakfast', title: 'Завтрак', icon: '🌅' },
  { id: 'lunch', title: 'Обед', icon: '☀️' },
  { id: 'dinner', title: 'Ужин', icon: '🌙' },
  { id: 'snack', title: 'Перекус', icon: '🥕' },
];

const PRESETS = [
  { name: 'Гречка', calories: 110, protein: 4.2, fat: 1.1, carbs: 21.3 },
  { name: 'Рис', calories: 130, protein: 2.7, fat: 0.3, carbs: 28 },
  { name: 'Куриная грудка', calories: 165, protein: 31, fat: 3.6, carbs: 0 },
  { name: 'Яйцо', calories: 155, protein: 13, fat: 11, carbs: 1.1 },
  { name: 'Творог 5%', calories: 121, protein: 17, fat: 5, carbs: 1.8 },
  { name: 'Банан', calories: 89, protein: 1.1, fat: 0.3, carbs: 23 },
  { name: 'Яблоко', calories: 52, protein: 0.3, fat: 0.2, carbs: 14 },
  { name: 'Хлеб', calories: 265, protein: 9, fat: 3.2, carbs: 49 },
];

const ENTRIES_KEY = 'calorie-counter.entries';
const GOAL_KEY = 'calorie-counter.goal';
const DEFAULT_GOAL = 2000;

/** Хранилище записей в localStorage браузера. */
const store = {
  entries: readJSON(ENTRIES_KEY, []),
  goal: readJSON(GOAL_KEY, DEFAULT_GOAL),

  entriesOn(day) {
    return this.entries
      .filter((e) => e.day === day)
      .sort((a, b) => a.createdAt - b.createdAt);
  },
  add(entry) {
    this.entries.push(entry);
    writeJSON(ENTRIES_KEY, this.entries);
  },
  remove(id) {
    this.entries = this.entries.filter((e) => e.id !== id);
    writeJSON(ENTRIES_KEY, this.entries);
  },
  setGoal(goal) {
    this.goal = goal;
    writeJSON(GOAL_KEY, goal);
  },
};

function readJSON(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw === null ? fallback : JSON.parse(raw);
  } catch {
    return fallback;
  }
}

function writeJSON(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch (error) {
    console.error('Не удалось сохранить данные', error);
  }
}

/** КБЖУ записи с учётом веса порции. */
function nutrition(entry) {
  const k = entry.grams / 100;
  return {
    calories: entry.caloriesPer100g * k,
    protein: entry.proteinPer100g * k,
    fat: entry.fatPer100g * k,
    carbs: entry.carbsPer100g * k,
  };
}

function totals(entries) {
  return entries.map(nutrition).reduce(
    (sum, n) => ({
      calories: sum.calories + n.calories,
      protein: sum.protein + n.protein,
      fat: sum.fat + n.fat,
      carbs: sum.carbs + n.carbs,
    }),
    { calories: 0, protein: 0, fat: 0, carbs: 0 },
  );
}

// ---------- Утилиты ----------

const $ = (selector) => document.querySelector(selector);

/** Создаёт элемент; текст передаётся через textContent, поэтому безопасен. */
function el(tag, props = {}, ...children) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(props)) {
    if (key.startsWith('on')) node.addEventListener(key.slice(2), value);
    else if (key in node) node[key] = value;
    else node.setAttribute(key, value);
  }
  node.append(...children.filter((c) => c !== null && c !== undefined));
  return node;
}

/** Ключ дня в локальном времени: «2026-10-21». */
function dayKey(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function addDays(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

/** Разбирает число, принимая и точку, и запятую как разделитель. */
function parseNumber(text) {
  const value = Number(String(text).trim().replace(',', '.'));
  return String(text).trim() !== '' && Number.isFinite(value) ? value : null;
}

const round = (n) => Math.round(n);
const fmt1 = (n) => n.toLocaleString('ru-RU', { maximumFractionDigits: 1 });
/** Значение для поля ввода: без разделителей тысяч, чтобы parseNumber его прочитал. */
const inputValue = (n) => String(Math.round(n * 10) / 10).replace('.', ',');

function suggestedMeal(date = new Date()) {
  const h = date.getHours();
  if (h >= 5 && h < 11) return 'breakfast';
  if (h >= 11 && h < 16) return 'lunch';
  if (h >= 16 && h < 22) return 'dinner';
  return 'snack';
}

function foodRow({ name, subtitle, calories, unit = 'ккал' }, ...extra) {
  return el('li', { className: 'food-row' },
    el('div', { className: 'info' },
      el('div', { className: 'name' }, name),
      ...subtitle.map((line) => el('div', { className: 'details' }, line)),
    ),
    el('div', { className: 'kcal' }, `${round(calories)} `, el('small', {}, unit)),
    ...extra,
  );
}

function macrosLine(n) {
  return `Б ${fmt1(n.protein)} · Ж ${fmt1(n.fat)} · У ${fmt1(n.carbs)}`;
}

// ---------- Дневная сводка ----------

let selectedDate = new Date();
const RING_LENGTH = 2 * Math.PI * 88;

function render() {
  const today = dayKey(new Date());
  const day = dayKey(selectedDate);
  const entries = store.entriesOn(day);
  const sum = totals(entries);
  const goal = store.goal;

  // Заголовок дня
  let title;
  if (day === today) title = 'Сегодня';
  else if (day === dayKey(addDays(new Date(), -1))) title = 'Вчера';
  else title = selectedDate.toLocaleDateString('ru-RU', { weekday: 'short', day: 'numeric', month: 'long' });
  $('#day-title').textContent = title;
  $('#next-day').disabled = day >= today;

  // Кольцо
  const progress = goal > 0 ? sum.calories / goal : 0;
  const ring = $('#ring-progress');
  ring.style.strokeDasharray = RING_LENGTH;
  ring.style.strokeDashoffset = RING_LENGTH * (1 - Math.min(progress, 1));
  ring.classList.toggle('over', progress > 1);

  const remaining = goal - sum.calories;
  $('#eaten').textContent = round(sum.calories);
  $('#goal-label').textContent = `из ${goal} ккал`;
  const remainingLabel = $('#remaining');
  remainingLabel.textContent = remaining >= 0
    ? `осталось ${round(remaining)}`
    : `превышение ${round(-remaining)}`;
  remainingLabel.classList.toggle('over', remaining < 0);

  $('#protein').textContent = `${round(sum.protein)} г`;
  $('#fat').textContent = `${round(sum.fat)} г`;
  $('#carbs').textContent = `${round(sum.carbs)} г`;

  // Приёмы пищи
  const meals = $('#meals');
  meals.replaceChildren();
  for (const meal of MEALS) {
    const items = entries.filter((e) => e.meal === meal.id);
    if (items.length === 0) continue;

    meals.append(
      el('div', { className: 'meal-header' },
        el('span', {}, `${meal.icon} ${meal.title}`),
        el('span', {}, `${round(totals(items).calories)} ккал`),
      ),
      el('ul', { className: 'group' },
        ...items.map((entry) => {
          const n = nutrition(entry);
          return foodRow(
            { name: entry.name, subtitle: [`${fmt1(entry.grams)} г · ${macrosLine(n)}`], calories: n.calories },
            el('button', {
              className: 'delete-button',
              type: 'button',
              title: 'Удалить',
              'aria-label': `Удалить «${entry.name}»`,
              onclick: () => { store.remove(entry.id); render(); },
            }, '✕'),
          );
        }),
      ),
    );
  }

  $('#empty-state').hidden = entries.length > 0;
}

$('#prev-day').addEventListener('click', () => { selectedDate = addDays(selectedDate, -1); render(); });
$('#next-day').addEventListener('click', () => { selectedDate = addDays(selectedDate, 1); render(); });

// Если приложение оставили открытым на ночь, «Сегодня» должно обновиться.
document.addEventListener('visibilitychange', () => { if (!document.hidden) render(); });

// ---------- Добавление продукта ----------

const addDialog = $('#add-dialog');
const form = $('#food-form');

form.elements.meal.append(...MEALS.map((m) => el('option', { value: m.id }, `${m.icon} ${m.title}`)));
$('#presets').append(...PRESETS.map((p) => el('button', { type: 'button', onclick: () => fillForm(p) }, p.name)));

function readDraft() {
  const f = form.elements;
  const name = f.name.value.trim();
  const grams = parseNumber(f.grams.value);
  const calories = parseNumber(f.calories.value);
  if (!name || grams === null || grams <= 0 || calories === null || calories < 0) return null;

  return {
    id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now() + Math.random()),
    name,
    caloriesPer100g: calories,
    proteinPer100g: parseNumber(f.protein.value) ?? 0,
    fatPer100g: parseNumber(f.fat.value) ?? 0,
    carbsPer100g: parseNumber(f.carbs.value) ?? 0,
    grams,
    meal: f.meal.value,
    day: dayKey(selectedDate),
    createdAt: Date.now(),
  };
}

function updatePreview() {
  const draft = readDraft();
  $('#save-button').disabled = !draft;
  $('#preview').hidden = !draft;
  if (draft) {
    const n = nutrition(draft);
    $('#preview-row').replaceChildren(
      foodRow({ name: draft.name, subtitle: [`${fmt1(draft.grams)} г · ${macrosLine(n)}`], calories: n.calories }),
    );
  }
}

function fillForm(product) {
  const f = form.elements;
  f.name.value = product.name;
  f.calories.value = inputValue(product.calories);
  f.protein.value = inputValue(product.protein);
  f.fat.value = inputValue(product.fat);
  f.carbs.value = inputValue(product.carbs);
  updatePreview();
  f.grams.focus();
  f.grams.select();
}

function openAddDialog() {
  form.reset();
  form.elements.meal.value = suggestedMeal();
  updatePreview();
  addDialog.showModal();
  form.elements.name.focus();
}

form.addEventListener('input', updatePreview);
form.addEventListener('submit', (event) => {
  event.preventDefault();
  const draft = readDraft();
  if (!draft) return;
  store.add(draft);
  addDialog.close();
  render();
});

$('#add-button').addEventListener('click', openAddDialog);

// ---------- Поиск по Open Food Facts ----------

const searchDialog = $('#search-dialog');
const searchInput = $('#search-input');
const searchStatus = $('#search-status');
const searchResults = $('#search-results');
let searchTimer;
let searchController;

/**
 * Ищет продукты в открытой базе Open Food Facts.
 * Документация: https://openfoodfacts.github.io/openfoodfacts-server/api/
 */
async function searchProducts(query, signal) {
  const url = new URL('https://world.openfoodfacts.org/cgi/search.pl');
  url.search = new URLSearchParams({
    search_terms: query,
    search_simple: '1',
    action: 'process',
    json: '1',
    lc: 'ru',
    sort_by: 'unique_scans_n',
    page_size: '30',
    fields: 'code,product_name,product_name_ru,brands,nutriments',
  });

  const response = await fetch(url, { signal });
  if (!response.ok) throw new Error(`Сервер ответил с кодом ${response.status}`);
  const data = await response.json();

  const seen = new Set();
  return (data.products ?? []).map(toProduct).filter((p) => p && !seen.has(p.id) && seen.add(p.id));
}

/** В базе числа иногда приходят строками, поэтому принимаем оба варианта. */
function toNumber(value) {
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  if (typeof value === 'string') return parseNumber(value);
  return null;
}

function toProduct(p) {
  const name = [p.product_name_ru, p.product_name].map((s) => s?.trim()).find(Boolean);
  const n = p.nutriments ?? {};
  // Если калорий нет, пересчитываем из килоджоулей.
  const kj = toNumber(n.energy_100g);
  const calories = toNumber(n['energy-kcal_100g']) ?? (kj !== null ? kj / 4.184 : null);
  if (!name || !p.code || calories === null) return null;

  return {
    id: p.code,
    name,
    brand: p.brands?.split(',')[0].trim() || null,
    calories,
    protein: toNumber(n.proteins_100g) ?? 0,
    fat: toNumber(n.fat_100g) ?? 0,
    carbs: toNumber(n.carbohydrates_100g) ?? 0,
  };
}

function showStatus(...content) {
  searchResults.replaceChildren();
  searchStatus.replaceChildren(...content);
}

function scheduleSearch(delay = 500) {
  clearTimeout(searchTimer);
  searchController?.abort();
  const query = searchInput.value.trim();

  if (query.length < 2) {
    showStatus('🔍 Найдите продукт. Данные берутся из открытой базы Open Food Facts');
    return;
  }
  searchTimer = setTimeout(() => runSearch(query), delay);
}

async function runSearch(query) {
  searchController = new AbortController();
  showStatus('Ищем…');
  try {
    const products = await searchProducts(query, searchController.signal);
    if (products.length === 0) {
      showStatus(`Ничего не найдено по запросу «${query}»`);
      return;
    }
    searchStatus.replaceChildren();
    searchResults.replaceChildren(...products.map((product) => {
      const row = foodRow({
        name: product.name,
        subtitle: [product.brand, macrosLine(product)].filter(Boolean),
        calories: product.calories,
        unit: 'ккал/100 г',
      });
      row.tabIndex = 0;
      row.addEventListener('click', () => pickProduct(product));
      row.addEventListener('keydown', (e) => { if (e.key === 'Enter') pickProduct(product); });
      return row;
    }));
  } catch (error) {
    if (error.name === 'AbortError') return;
    const message = navigator.onLine ? error.message : 'Нет подключения к интернету';
    showStatus(
      el('div', {}, `Не удалось загрузить: ${message}`),
      el('button', { type: 'button', className: 'link-button strong', onclick: () => scheduleSearch(0) }, 'Повторить'),
    );
  }
}

function pickProduct(product) {
  searchDialog.close();
  fillForm(product);
}

searchInput.addEventListener('input', () => scheduleSearch());
$('#open-search').addEventListener('click', () => {
  searchDialog.showModal();
  scheduleSearch(0);
  searchInput.focus();
});

// ---------- Цель ----------

const goalDialog = $('#goal-dialog');
let goalDraft = store.goal;

function showGoal() { $('#goal-value').textContent = `${goalDraft} ккал`; }

$('#goal-button').addEventListener('click', () => {
  goalDraft = store.goal;
  showGoal();
  goalDialog.showModal();
});
goalDialog.querySelectorAll('[data-step]').forEach((button) => {
  button.addEventListener('click', () => {
    goalDraft = Math.min(6000, Math.max(800, goalDraft + Number(button.dataset.step)));
    showGoal();
  });
});
goalDialog.addEventListener('close', () => {
  store.setGoal(goalDraft);
  render();
});

// ---------- Общее ----------

document.querySelectorAll('[data-close]').forEach((button) => {
  button.addEventListener('click', () => button.closest('dialog').close());
});

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').catch((error) => console.warn('Service worker не зарегистрирован', error));
}

render();
