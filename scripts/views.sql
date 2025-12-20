-- 1) Агрегирующее представление - с GROUP BY и агрегатными функциями
CREATE OR REPLACE VIEW user_statistics AS
SELECT u.id,
       u.username,
       u.email,
       u.created_at,
       COUNT(DISTINCT r.id)         AS total_recipes,
       COUNT(DISTINCT c.id)         AS total_collections,
       COUNT(DISTINCT rv.id)        AS total_reviews,
       COUNT(DISTINCT sl.id)        AS total_shop_lists,
       COUNT(DISTINCT v.id)         AS total_views_given,
       COALESCE(AVG(rev.rating), 0) AS avg_review_rating_given,
       COALESCE(AVG(r.rating), 0)   AS avg_recipe_rating,
       SUM(r.views)                 AS total_recipe_views
FROM "user" u
         LEFT JOIN recipe r ON u.id = r.user_id AND r.deleted_at IS NULL
         LEFT JOIN collection c ON u.id = c.user_id AND c.deleted_at IS NULL
         LEFT JOIN review rv ON u.id = rv.user_id AND rv.deleted_at IS NULL
         LEFT JOIN shop_list sl ON u.id = sl.user_id AND sl.deleted_at IS NULL
         LEFT JOIN recipe_view v ON u.id = v.user_id
         LEFT JOIN review rev ON u.id = rev.user_id AND rev.deleted_at IS NULL
WHERE u.deleted_at IS NULL
GROUP BY u.id, u.username, u.email, u.created_at
ORDER BY total_recipes DESC;


---------------------------------------------------------------------------------------------


-- 2) Представление-отчет - с JOIN 3+ таблиц для аналитики
CREATE OR REPLACE VIEW recipe_detailed_report AS
SELECT r.id                                AS recipe_id,
       r.title,
       r.description,
       u.username                          AS author,
       r.active_cooking_time,
       r.total_cooking_time,
       r.servings,
       r.views,
       r.rating,
       r.created_at,
       COUNT(DISTINCT ri.id)               AS total_ingredients,
       COUNT(DISTINCT rs.id)               AS total_steps,
       COUNT(DISTINCT rev.id)              AS total_reviews,
       COUNT(DISTINCT cr.collection_id)    AS times_in_collections,
       COUNT(DISTINCT rt.tag_id)           AS total_tags,
       COUNT(DISTINCT rc.category_id)      AS total_categories,
       STRING_AGG(DISTINCT cat.name, ', ') AS categories_list,
       STRING_AGG(DISTINCT t.name, ', ')   AS tags_list,
       MAX(rev.created_at)                 AS last_review_date

FROM recipe r
         JOIN "user" u ON r.user_id = u.id AND u.deleted_at IS NULL
         LEFT JOIN recipe_ingredient ri ON r.id = ri.recipe_id AND ri.deleted_at IS NULL
         LEFT JOIN recipe_step rs ON r.id = rs.recipe_id AND rs.deleted_at IS NULL
         LEFT JOIN review rev ON r.id = rev.recipe_id AND rev.deleted_at IS NULL
         LEFT JOIN collection_recipe cr ON r.id = cr.recipe_id AND cr.deleted_at IS NULL
         LEFT JOIN recipe_tag rt ON r.id = rt.recipe_id AND rt.deleted_at IS NULL
         LEFT JOIN recipe_category rc ON r.id = rc.recipe_id AND rc.deleted_at IS NULL
         LEFT JOIN category cat ON rc.category_id = cat.id AND cat.deleted_at IS NULL
         LEFT JOIN tag t ON rt.tag_id = t.id AND t.deleted_at IS NULL
WHERE r.deleted_at IS NULL
GROUP BY r.id, r.title, r.description, u.username, r.active_cooking_time,
         r.total_cooking_time, r.servings, r.views, r.rating, r.created_at
ORDER BY r.views DESC, r.rating DESC NULLS LAST;


---------------------------------------------------------------------------------------------


-- 3) Представление с вычисляемыми полями - включающее производные атрибуты
CREATE OR REPLACE VIEW recipe_enhanced AS
SELECT r.id,
       r.title,
       r.description,
       u.username                        AS author,
       r.active_cooking_time || ' мин'   AS active_time_display,
       r.total_cooking_time || ' мин'    AS total_time_display,
       CASE
           WHEN r.total_cooking_time <= 30 THEN 'Быстрый'
           WHEN r.total_cooking_time <= 60 THEN 'Средний'
           ELSE 'Долгий'
           END                           AS difficulty_level,

       r.servings || ' порц.'            AS servings_display,
       -- Рейтинг с текстовым отображением
       CASE
           WHEN r.rating IS NULL THEN 'Нет оценок'
           WHEN r.rating >= 4.5 THEN 'Отлично'
           WHEN r.rating >= 4.0 THEN 'Очень хорошо'
           WHEN r.rating >= 3.0 THEN 'Хорошо'
           WHEN r.rating >= 2.0 THEN 'Удовлетворительно'
           ELSE 'Плохо'
           END                           AS rating_display,

       -- Популярность
       CASE
           WHEN r.views >= 500 THEN 'Очень популярный'
           WHEN r.views >= 200 THEN 'Популярный'
           WHEN r.views >= 50 THEN 'Средняя популярность'
           ELSE 'Малоизвестный'
           END                           AS popularity_level,

       -- Возраст рецепта
       CURRENT_DATE - r.created_at::DATE AS days_since_creation,
       CASE
           WHEN CURRENT_DATE - r.created_at::DATE <= 7 THEN 'Новый'
           WHEN CURRENT_DATE - r.created_at::DATE <= 30 THEN 'Недавний'
           WHEN CURRENT_DATE - r.created_at::DATE <= 365 THEN 'Старый'
           ELSE 'Архивный'
           END                           AS recipe_age

FROM recipe r
         JOIN "user" u ON r.user_id = u.id AND u.deleted_at IS NULL
         LEFT JOIN recipe_ingredient ri ON r.id = ri.recipe_id AND ri.deleted_at IS NULL
         LEFT JOIN ingredient i ON ri.ingredient_id = i.id AND i.deleted_at IS NULL
WHERE r.deleted_at IS NULL
GROUP BY r.id, r.title, r.description, u.username, r.active_cooking_time,
         r.total_cooking_time, r.servings, r.views, r.rating, r.created_at;


---------------------------------------------------------------------------------------------


-- 4) Представление с фильтрацией - WHERE с комплексными условиями
CREATE OR REPLACE VIEW quick_recipes_with_reviews AS
SELECT r.id,
       r.title,
       r.description,
       u.username                   AS author,
       r.active_cooking_time,
       r.total_cooking_time,
       r.servings,
       r.rating,
       r.views,
       CASE
           WHEN r.total_cooking_time <= 15 THEN 'Очень быстро (до 15 мин)'
           WHEN r.total_cooking_time <= 30 THEN 'Быстро (до 30 мин)'
           ELSE 'Средне (до 60 мин)'
           END                      AS speed_category,
       COUNT(rev.id)                AS review_count,
       COALESCE(AVG(rev.rating), 0) AS avg_review_score,
       STRING_AGG(
               DISTINCT CASE
                            WHEN rev.comment != ''
                                THEN LEFT(rev.comment, 50) || '...'
                            ELSE 'Без комментария'
           END,
               ' | '
       )                            AS recent_review_previews,
       CASE
           WHEN COUNT(DISTINCT ri.id) <= 5 THEN 'Простой'
           WHEN COUNT(DISTINCT ri.id) <= 10 THEN 'Средний'
           ELSE 'Сложный'
           END                      AS complexity_level

FROM recipe r
         JOIN "user" u ON r.user_id = u.id AND u.deleted_at IS NULL
         LEFT JOIN review rev ON r.id = rev.recipe_id AND rev.deleted_at IS NULL
         LEFT JOIN recipe_ingredient ri ON r.id = ri.recipe_id AND ri.deleted_at IS NULL
WHERE r.deleted_at IS NULL
  AND r.total_cooking_time <= 60                                            -- быстрые рецепты (до 1 часа)
  AND r.servings BETWEEN 1 AND 6                                            -- для небольшой семьи
  AND r.rating IS NOT NULL                                                  -- с оценками
  AND r.rating >= 3.5                                                       -- хорошие оценки
  AND (SELECT COUNT(*) FROM recipe_step rs WHERE rs.recipe_id = r.id) <= 10 -- не слишком много шагов
GROUP BY r.id, r.title, r.description, u.username, r.active_cooking_time,
         r.total_cooking_time, r.servings, r.rating, r.views
HAVING COUNT(rev.id) >= 2 -- минимум 2 отзыва
ORDER BY r.total_cooking_time, r.rating DESC;


---------------------------------------------------------------------------------------------


-- 5) Представление для безопасности - с ограничением доступа к данным
CREATE OR REPLACE VIEW public_user_profiles AS
SELECT u.id,
       u.username,
       CONCAT(
               LEFT(u.email, 1),
               '***',
               RIGHT(SPLIT_PART(u.email, '@', 1), 1),
               '@',
               LEFT(SPLIT_PART(u.email, '@', 2), 1),
               SPLIT_PART(u.email, '@', 2)
       )                                                                                   AS masked_email,
       u.avatar_url,
       u.created_at,

       -- Публичная статистика
       (SELECT COUNT(*) FROM recipe r WHERE r.user_id = u.id AND r.deleted_at IS NULL)     AS recipe_count,
       (SELECT COUNT(*) FROM collection c WHERE c.user_id = u.id AND c.deleted_at IS NULL) AS collection_count,

       -- Средний рейтинг рецептов пользователя
       COALESCE(
               (SELECT ROUND(AVG(r.rating), 2)
                FROM recipe r
                WHERE r.user_id = u.id
                  AND r.rating IS NOT NULL
                  AND r.deleted_at IS NULL),
               0
       )                                                                                   AS avg_recipe_rating,

       -- Активность пользователя (последняя активность)
       GREATEST(
               COALESCE((SELECT MAX(created_at) FROM recipe WHERE user_id = u.id), '1970-01-01'),
               COALESCE((SELECT MAX(created_at) FROM review WHERE user_id = u.id), '1970-01-01'),
               COALESCE((SELECT MAX(created_at) FROM collection WHERE user_id = u.id), '1970-01-01')
       )                                                                                   AS last_activity_date,

       -- Уровень пользователя
       CASE
           WHEN u.created_at > CURRENT_DATE - INTERVAL '30 days' THEN 'Новичок'
           WHEN (SELECT COUNT(*) FROM recipe r WHERE r.user_id = u.id AND r.deleted_at IS NULL) >= 10 THEN 'Продвинутый'
           WHEN (SELECT COUNT(*) FROM recipe r WHERE r.user_id = u.id AND r.deleted_at IS NULL) >= 3 THEN 'Активный'
           ELSE 'Начинающий'
           END                                                                             AS user_level

FROM "user" u
WHERE u.deleted_at IS NULL
ORDER BY u.created_at DESC;