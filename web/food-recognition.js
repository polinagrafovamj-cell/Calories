'use strict';

/**
 * Распознавание еды на фото прямо в браузере, без отправки фото на сервер.
 * Модель MobileNet v2 (ImageNet, 1000 классов) запускается через TensorFlow.js;
 * её классы сопоставляются с продуктами из recognized-foods.json.
 * Модель (~14 МБ) скачивается при первом распознавании и потом берётся из кэша.
 */
const FoodRecognizer = (() => {
  const MODEL_URL = 'models/mobilenet_v2/model.json';
  const INPUT_SIZE = 224;
  const MIN_PROBABILITY = 0.05;

  let ready;

  function loadScript(src) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = src;
      script.onload = resolve;
      script.onerror = () => reject(new Error(`Не удалось загрузить ${src}`));
      document.head.append(script);
    });
  }

  /** Загружает TensorFlow.js, модель и таблицу продуктов (один раз). */
  function load() {
    ready ??= (async () => {
      const [, foodsResponse] = await Promise.all([loadScript('vendor/tf.min.js'), fetch('recognized-foods.json')]);
      const { foods } = await foodsResponse.json();

      // Индекс класса ImageNet → продукт
      const byClass = new Map();
      for (const food of foods) for (const index of food.imagenet) byClass.set(index, food);

      await tf.ready();
      const model = await tf.loadGraphModel(MODEL_URL);
      return { model, byClass };
    })().catch((error) => {
      ready = undefined; // чтобы можно было повторить попытку
      throw error;
    });
    return ready;
  }

  /** Вырезает квадрат из центра фото и уменьшает до размера входа модели. */
  function toCanvas(image) {
    const side = Math.min(image.naturalWidth, image.naturalHeight);
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = INPUT_SIZE;
    canvas.getContext('2d').drawImage(
      image,
      (image.naturalWidth - side) / 2, (image.naturalHeight - side) / 2, side, side,
      0, 0, INPUT_SIZE, INPUT_SIZE,
    );
    return canvas;
  }

  /**
   * Возвращает до трёх вероятных продуктов: [{ food, probability }].
   * Пустой массив — на фото не нашлось ничего из известных продуктов.
   */
  async function recognize(image) {
    const { model, byClass } = await load();

    const output = tf.tidy(() => {
      // Модель с TF Hub ожидает пиксели в диапазоне [0, 1].
      const input = tf.browser.fromPixels(toCanvas(image)).toFloat().div(255).expandDims();
      return tf.softmax(model.predict(input).squeeze());
    });
    const probabilities = await output.data();
    output.dispose();

    // Выход — 1001 класс: нулевой означает «фон», дальше идут 1000 классов ImageNet.
    const scores = new Map();
    probabilities.forEach((p, i) => {
      const food = byClass.get(i - 1);
      if (food) scores.set(food, (scores.get(food) ?? 0) + p);
    });

    return [...scores]
      .map(([food, probability]) => ({ food, probability }))
      .filter((r) => r.probability >= MIN_PROBABILITY)
      .sort((a, b) => b.probability - a.probability)
      .slice(0, 3);
  }

  return { load, recognize };
})();
