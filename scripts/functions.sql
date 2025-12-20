-- Функция для добавления нового рецепта с ингредиентами, шагами и категориями
CREATE OR REPLACE FUNCTION add_recipe_with_details(
    p_user_id BIGINT,
    p_title VARCHAR(128),
    p_description VARCHAR(512),
    p_active_cooking_time SMALLINT,
    p_total_cooking_time SMALLINT,
    p_servings SMALLINT,
    p_image_url VARCHAR(512) DEFAULT NULL,
    p_ingredients JSONB DEFAULT '[]',
    p_steps JSONB DEFAULT '[]',
    p_category_ids SMALLINT[] DEFAULT '{}',
    p_tag_ids SMALLINT[] DEFAULT '{}'
)
    RETURNS TABLE
            (
                STATUS_CODE    INT,
                STATUS_MESSAGE VARCHAR
            )
AS
$$
DECLARE
    v_recipe_id   BIGINT;
    v_ingredient  JSONB;
    v_step        JSONB;
    v_category_id SMALLINT;
    v_tag_id      SMALLINT;
    v_step_order  SMALLINT := 1;
BEGIN
    -- Валидация входных параметров
    IF p_user_id IS NULL OR p_user_id <= 0 THEN
        RETURN QUERY SELECT 400, 'Неверный ID пользователя';
        RETURN;
    END IF;

    IF LENGTH(p_title) < 3 THEN
        RETURN QUERY SELECT 400, 'Название должно содержать минимум 3 символа';
        RETURN;
    END IF;

    IF p_active_cooking_time <= 0 OR p_active_cooking_time > 1440 THEN
        RETURN QUERY SELECT 400, 'Активное время готовки должно быть от 1 до 1440 минут';
        RETURN;
    END IF;

    IF p_total_cooking_time < p_active_cooking_time THEN
        RETURN QUERY SELECT 400, 'Общее время готовки должно быть больше или равно активному времени';
        RETURN;
    END IF;

    IF p_servings <= 0 OR p_servings > 40 THEN
        RETURN QUERY SELECT 400, 'Количество порций должно быть от 1 до 40';
        RETURN;
    END IF;

    -- Проверка существования пользователя
    IF NOT EXISTS (SELECT 1 FROM "user" WHERE id = p_user_id AND deleted_at IS NULL) THEN
        RETURN QUERY SELECT 404, 'Пользователь не найден';
        RETURN;
    END IF;

    BEGIN
        -- Начало транзакции
        START TRANSACTION;

        -- Добавление рецепта
        INSERT INTO recipe (user_id,
                            title,
                            description,
                            active_cooking_time,
                            total_cooking_time,
                            servings,
                            image_url)
        VALUES (p_user_id,
                p_title,
                p_description,
                p_active_cooking_time,
                p_total_cooking_time,
                p_servings,
                p_image_url)
        RETURNING id INTO v_recipe_id;

        -- Добавление ингредиентов
        FOR v_ingredient IN SELECT * FROM JSONB_ARRAY_ELEMENTS(p_ingredients)
            LOOP
                INSERT INTO recipe_ingredient (recipe_id,
                                               ingredient_id,
                                               quantity,
                                               unit_id,
                                               notes)
                VALUES (v_recipe_id,
                        (v_ingredient ->> 'ingredient_id')::INT,
                        (v_ingredient ->> 'quantity')::NUMERIC(6, 3),
                        (v_ingredient ->> 'unit_id')::INT,
                        COALESCE(v_ingredient ->> 'notes', ''));
            END LOOP;

        -- Добавление шагов
        FOR v_step IN SELECT * FROM JSONB_ARRAY_ELEMENTS(p_steps)
            LOOP
                INSERT INTO recipe_step (recipe_id,
                                         step_order,
                                         instructions,
                                         image_url)
                VALUES (v_recipe_id,
                        v_step_order,
                        v_step ->> 'instructions',
                        NULLIF(v_step ->> 'image_url', ''));
                v_step_order := v_step_order + 1;
            END LOOP;

        -- Добавление категорий
        FOREACH v_category_id IN ARRAY p_category_ids
            LOOP
                INSERT INTO recipe_category (recipe_id,
                                             category_id)
                VALUES (v_recipe_id,
                        v_category_id);
            END LOOP;

        -- Добавление тегов
        FOREACH v_tag_id IN ARRAY p_tag_ids
            LOOP
                INSERT INTO recipe_tag (recipe_id,
                                        tag_id)
                VALUES (v_recipe_id,
                        v_tag_id);
            END LOOP;
        COMMIT;

        RETURN QUERY SELECT 201, 'Рецепт успешно создан';

    EXCEPTION
        WHEN foreign_key_violation THEN
            ROLLBACK;
            RETURN QUERY SELECT 400, 'Ошибка внешнего ключа. Проверьте существование связанных записей', NULL::BIGINT;
        WHEN check_violation THEN
            ROLLBACK;
            RETURN QUERY SELECT 400, 'Ошибка проверки ограничений. Проверьте входные данные', NULL::BIGINT;
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN QUERY SELECT 500, 'Внутренняя ошибка сервера: ' || sqlerrm, NULL::BIGINT;
    END;
END;
$$ LANGUAGE plpgsql;


-- Функция для изменения рецепта с обновлением связанных данных
CREATE OR REPLACE FUNCTION update_recipe_with_details(
    p_recipe_id BIGINT,
    p_user_id BIGINT,
    p_title VARCHAR(128) DEFAULT NULL,
    p_description VARCHAR(512) DEFAULT NULL,
    p_active_cooking_time SMALLINT DEFAULT NULL,
    p_total_cooking_time SMALLINT DEFAULT NULL,
    p_servings SMALLINT DEFAULT NULL,
    p_image_url VARCHAR(512) DEFAULT NULL,

    -- null = без изменений
    p_update_ingredients JSONB DEFAULT NULL,
    p_steps JSONB DEFAULT NULL,
    p_categories SMALLINT[] DEFAULT NULL,
    p_tags SMALLINT[] DEFAULT NULL
)
    RETURNS TABLE
            (
                STATUS_CODE    INT,
                STATUS_MESSAGE VARCHAR,
                RECIPE_DATA    JSON
            )
AS
$$
DECLARE
    v_old_record RECORD;
    v_new_record RECORD;
BEGIN
    -- Проверка существования записи
    IF NOT EXISTS (SELECT 1 FROM recipe WHERE id = p_recipe_id AND deleted_at IS NULL) THEN
        RETURN QUERY SELECT 404, 'Рецепт не найден';
        RETURN;
    END IF;

    -- Проверка прав доступа
    IF NOT EXISTS (SELECT 1 FROM recipe WHERE id = p_recipe_id AND user_id = p_user_id) THEN
        RETURN QUERY SELECT 403, 'Нет прав для изменения этого рецепта';
        RETURN;
    END IF;

    -- Валидация новых значений
    IF p_title IS NOT NULL AND LENGTH(p_title) < 3 THEN
        RETURN QUERY SELECT 400, 'Название должно содержать минимум 3 символа';
        RETURN;
    END IF;

    IF p_active_cooking_time IS NOT NULL AND (p_active_cooking_time <= 0 OR p_active_cooking_time > 1440) THEN
        RETURN QUERY SELECT 400, 'Активное время готовки должно быть от 1 до 1440 минут';
        RETURN;
    END IF;

    IF p_total_cooking_time IS NOT NULL AND p_active_cooking_time IS NOT NULL
        AND p_total_cooking_time < p_active_cooking_time THEN
        RETURN QUERY SELECT 400, 'Общее время готовки должно быть больше или равно активному времени';
        RETURN;
    END IF;

    IF p_servings IS NOT NULL AND (p_servings <= 0 OR p_servings >= 40) THEN
        RETURN QUERY SELECT 400, 'Количество порций должно быть от 1 до 40';
        RETURN;
    END IF;

    BEGIN
        -- Получаем старые значения для логирования
        SELECT title,
               description,
               active_cooking_time,
               total_cooking_time,
               servings,
               image_url,
               updated_at
        INTO v_old_record
        FROM recipe
        WHERE id = p_recipe_id;

        -- Начало транзакции
        START TRANSACTION;

        -- Обновление основных данных рецепта
        UPDATE recipe
        SET title               = COALESCE(p_title, title),
            description         = COALESCE(p_description, description),
            active_cooking_time = COALESCE(p_active_cooking_time, active_cooking_time),
            total_cooking_time  = COALESCE(p_total_cooking_time, total_cooking_time),
            servings            = COALESCE(p_servings, servings),
            image_url           = COALESCE(p_image_url, image_url)
        WHERE id = p_recipe_id
        RETURNING * INTO v_new_record;

        IF p_update_ingredients IS NOT NULL THEN
            PERFORM update_recipe_ingredients(
                    p_recipe_id := p_recipe_id,
                    p_ingredients := p_update_ingredients
                    );
        END IF;

        IF p_steps IS NOT NULL THEN
            PERFORM update_recipe_steps(
                    p_recipe_id := p_recipe_id,
                    p_steps := p_steps
                    );
        END IF;

        IF p_categories IS NOT NULL THEN
            PERFORM update_recipe_categories(
                    p_recipe_id := p_recipe_id,
                    p_category_ids := p_categories
                    );
        END IF;

        IF p_tags IS NOT NULL THEN
            PERFORM update_recipe_tags(
                    p_recipe_id := p_recipe_id,
                    p_tag_ids := p_tags
                    );
        END IF;
        COMMIT;

        RETURN QUERY SELECT 200, 'Рецепт успешно обновлен';

    EXCEPTION
        WHEN check_violation THEN
            ROLLBACK;
            RETURN QUERY SELECT 400, 'Ошибка проверки ограничений. Проверьте входные данные';
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN QUERY SELECT 500, 'Внутренняя ошибка сервера при обновлении рецепта';
    END;

END;
$$ LANGUAGE plpgsql;


-- Функция для обновления ингредиентов рецепта
CREATE OR REPLACE FUNCTION update_recipe_ingredients(
    p_recipe_id BIGINT,
    p_ingredients JSONB
)
RETURNS VOID AS $$
DECLARE
    v_ingredient JSONB;
BEGIN
    -- Если передан пустой массив - удаляем все ингредиенты (мягкое удаление)
    IF p_ingredients = '[]'::JSONB THEN
        UPDATE recipe_ingredient
        SET deleted_at = CURRENT_TIMESTAMP
        WHERE recipe_id = p_recipe_id AND deleted_at IS NULL;
        RETURN;
    END IF;

    -- Добавляем новые ингредиенты
    FOR v_ingredient IN SELECT * FROM jsonb_array_elements(p_ingredients)
    LOOP
        INSERT INTO recipe_ingredient (
            recipe_id,
            ingredient_id,
            quantity,
            unit_id,
            notes
        ) VALUES (
            p_recipe_id,
            (v_ingredient->>'ingredient_id')::INT,
            (v_ingredient->>'quantity')::NUMERIC(6,3),
            (v_ingredient->>'unit_id')::INT,
            COALESCE(v_ingredient->>'notes', '')
        );
    END LOOP;

END;
$$ LANGUAGE plpgsql;


-- Функция для обновления шагов рецепта
CREATE OR REPLACE FUNCTION update_recipe_steps(
    p_recipe_id BIGINT,
    p_steps JSONB
)
RETURNS VOID AS $$
DECLARE
    v_step JSONB;
    v_step_order SMALLINT := 1;
BEGIN
    -- Если передан пустой массив - удаляем все шаги
    IF p_steps = '[]'::JSONB THEN
        UPDATE recipe_step
        SET deleted_at = CURRENT_TIMESTAMP
        WHERE recipe_id = p_recipe_id AND deleted_at IS NULL;
        RETURN;
    END IF;

    -- Добавляем новые шаги
    FOR v_step IN SELECT * FROM jsonb_array_elements(p_steps)
    LOOP
        INSERT INTO recipe_step (
            recipe_id,
            step_order,
            instructions,
            image_url
        ) VALUES (
            p_recipe_id,
            v_step_order,
            v_step->>'instructions',
            NULLIF(v_step->>'image_url', '')
        );
        v_step_order := v_step_order + 1;
    END LOOP;

END;
$$ LANGUAGE plpgsql;

-- Функция для обновления категорий рецепта
CREATE OR REPLACE FUNCTION update_recipe_categories(
    p_recipe_id BIGINT,
    p_category_ids INT[]
)
RETURNS VOID AS $$
DECLARE
    v_category_id INT;
BEGIN
    -- Если передан пустой массив - удаляем все категории
    IF p_category_ids = '{}'::INT[] THEN
        UPDATE recipe_category
        SET deleted_at = CURRENT_TIMESTAMP
        WHERE recipe_id = p_recipe_id AND deleted_at IS NULL;
        RETURN;
    END IF;

    -- Добавляем новые связи с категориями
    FOREACH v_category_id IN ARRAY p_category_ids
    LOOP
        INSERT INTO recipe_category (
            recipe_id,
            category_id
        ) VALUES (
            p_recipe_id,
            v_category_id
        );
    END LOOP;

END;
$$ LANGUAGE plpgsql;


-- Функция для обновления тегов рецепта
CREATE OR REPLACE FUNCTION update_recipe_tags(
    p_recipe_id BIGINT,
    p_tag_ids INT[]
)
RETURNS VOID AS $$
DECLARE
    v_tag_id INT;
BEGIN
    -- Если передан пустой массив - удаляем все теги
    IF p_tag_ids = '{}'::INT[] THEN
        UPDATE recipe_tag
        SET deleted_at = CURRENT_TIMESTAMP
        WHERE recipe_id = p_recipe_id AND deleted_at IS NULL;
        RETURN;
    END IF;

    -- Добавляем новые связи с тегами
    FOREACH v_tag_id IN ARRAY p_tag_ids
    LOOP
        INSERT INTO recipe_tag (
            recipe_id,
            tag_id
        ) VALUES (
            p_recipe_id,
            v_tag_id
        );
    END LOOP;

END;
$$ LANGUAGE plpgsql;