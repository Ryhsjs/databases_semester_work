-- Найти рецепты конкретного пользователя
SELECT id, title, description, rating, views
FROM recipe
WHERE user_id = 12
  AND deleted_at IS NULL
ORDER BY created_at DESC;

-- Получить 10 самых популярных рецептов
SELECT r.id, r.title, u.username, r.rating, r.views
FROM recipe r
JOIN "user" u ON r.user_id = u.id
WHERE r.deleted_at IS NULL
  AND r.rating >= 4.0
ORDER BY r.views DESC
LIMIT 10;

-- Найти быстрые рецепты (до 30 минут)
SELECT id, title, active_cooking_time, total_cooking_time
FROM recipe
WHERE total_cooking_time <= 30
  AND deleted_at IS NULL
ORDER BY total_cooking_time;

-- Показать рецепты в конкретной коллекции
SELECT r.id, r.title, r.description
FROM collection_recipe cr
JOIN recipe r ON cr.recipe_id = r.id
WHERE cr.collection_id = 4
  AND cr.deleted_at IS NULL
  AND r.deleted_at IS NULL
ORDER BY cr.created_at DESC;

-- Показать ингредиенты для рецепта
SELECT i.name, ri.quantity, u.name as unit, ri.notes
FROM recipe_ingredient ri
JOIN ingredient i ON ri.ingredient_id = i.id
JOIN unit u ON ri.unit_id = u.id
WHERE ri.recipe_id = 2
  AND ri.deleted_at IS NULL
ORDER BY i.name;

-- Получить активный список покупок пользователя
SELECT sl.name as list_name, i.name as ingredient,
       sli.quantity, u.name as unit, sli.completed
FROM shop_list sl
JOIN shop_list_item sli ON sl.id = sli.shop_list_id
JOIN ingredient i ON sli.ingredient_id = i.id
JOIN unit u ON sli.unit_id = u.id
WHERE sl.user_id = 3
  AND sl.deleted_at IS NULL
  AND sli.deleted_at IS NULL
ORDER BY sli.completed, i.name;

-- Найти рецепты по категории
SELECT r.id, r.title, r.description
FROM recipe_category rc
JOIN recipe r ON rc.recipe_id = r.id
JOIN category c ON rc.category_id = c.id
WHERE c.name = 'Десерты'
  AND rc.deleted_at IS NULL
  AND r.deleted_at IS NULL
LIMIT 10;

-- Показать самые популярные теги
SELECT t.name, COUNT(rt.id) as usage_count
FROM recipe_tag rt
JOIN tag t ON rt.tag_id = t.id
WHERE rt.deleted_at IS NULL
GROUP BY t.id, t.name
ORDER BY usage_count DESC
LIMIT 20;

