-- защита от изменения created_at
CREATE OR REPLACE FUNCTION protect_created_at()
    RETURNS TRIGGER AS
$$
BEGIN
    -- если пытаемся изменить created_at на значение, отличное от текущего
    IF new.created_at IS DISTINCT FROM old.created_at THEN
        new.created_at := old.created_at;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_protect_user_created
    BEFORE UPDATE
    ON "user"
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_recipe_created
    BEFORE UPDATE
    ON recipe
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_recipe_step_created
    BEFORE UPDATE
    ON recipe_step
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_collection_created
    BEFORE UPDATE
    ON collection
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_collection_recipe_created
    BEFORE UPDATE
    ON collection_recipe
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_review_created
    BEFORE UPDATE
    ON review
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_recipe_view_created
    BEFORE UPDATE
    ON recipe_view
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_unit_created
    BEFORE UPDATE
    ON unit
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_ingredient_created
    BEFORE UPDATE
    ON ingredient
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_recipe_ingredient_created
    BEFORE UPDATE
    ON recipe_ingredient
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_category_created
    BEFORE UPDATE
    ON category
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_recipe_category_created
    BEFORE UPDATE
    ON recipe_category
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_shop_list_created
    BEFORE UPDATE
    ON shop_list
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_shop_list_item_created
    BEFORE UPDATE
    ON shop_list_item
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_tag_created
    BEFORE UPDATE
    ON tag
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

CREATE OR REPLACE TRIGGER trg_protect_recipe_tag_created
    BEFORE UPDATE
    ON recipe_tag
    FOR EACH ROW
EXECUTE FUNCTION protect_created_at();

----------------------------------------------------------------------------------------------------------

-- изменение даты редактирования
CREATE OR REPLACE FUNCTION set_updated_at()
    RETURNS TRIGGER AS
$$
BEGIN
    new.updated_at = CURRENT_TIMESTAMP;
    RETURN new;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_user_updated
    BEFORE UPDATE
    ON "user"
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


CREATE OR REPLACE TRIGGER trg_recipe_updated
    BEFORE UPDATE
    ON recipe
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


CREATE OR REPLACE TRIGGER trg_review_updated
    BEFORE UPDATE
    ON review
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-----------------------------------------------------------------------------------------

-- подсчет среднего рейтинга рецепты
CREATE OR REPLACE FUNCTION update_recipe_rating() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE recipe
    SET rating = (SELECT ROUND(AVG(rating)::NUMERIC, 2)
                  FROM review
                  WHERE recipe_id = COALESCE(new.recipe_id, old.recipe_id)
                    AND deleted_at IS NULL)
    WHERE id = COALESCE(new.recipe_id, old.recipe_id)
      AND deleted_at IS NULL;
    RETURN COALESCE(new, old);
END;
$$;


CREATE OR REPLACE TRIGGER trg_review_rating
    AFTER INSERT OR UPDATE OR DELETE
    ON review
    FOR EACH ROW
EXECUTE FUNCTION update_recipe_rating();

----------------------------------------------------------------------------

-- обновление просмотров рецепта
CREATE OR REPLACE FUNCTION update_recipe_views()
    RETURNS TRIGGER AS
$$
BEGIN
    UPDATE recipe
    SET views = views + 1
    WHERE id = new.recipe_id;

    RETURN new;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_recipe_view_increment
    AFTER INSERT
    ON recipe_view
    FOR EACH ROW
EXECUTE FUNCTION update_recipe_views();


------------------------------------------------------------------------------------------------


-- валидация добавления категорий рецептов
CREATE OR REPLACE FUNCTION upsert_recipe_category()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    existing_record_id BIGINT;
    existing_deleted_at TIMESTAMPTZ;
BEGIN

    SELECT id, deleted_at
    INTO existing_record_id, existing_deleted_at
    FROM recipe_category
    -- ищем совпадающую запись
    WHERE recipe_id = NEW.recipe_id
      AND category_id = NEW.category_id;
    IF existing_record_id IS NOT NULL THEN
        IF existing_deleted_at IS NULL THEN
            -- запись активна - игнорируем дубликат
            RETURN NULL;
        ELSE
            -- запись удалена - делаем новую
            RETURN NEW;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_upsert_recipe_category
    BEFORE INSERT
    ON recipe_category
    FOR EACH ROW
EXECUTE FUNCTION upsert_recipe_category();


-- остальные триггеры по аналогии с предыдущим


-- валидация добавления тегов рецептов
CREATE OR REPLACE FUNCTION upsert_recipe_tag()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    existing_record_id BIGINT;
    existing_deleted_at TIMESTAMPTZ;
BEGIN

    SELECT id, deleted_at
    INTO existing_record_id, existing_deleted_at
    FROM recipe_tag
    WHERE recipe_id = NEW.recipe_id
      AND tag_id = NEW.tag_id;

    IF existing_record_id IS NOT NULL THEN
        IF existing_deleted_at IS NULL THEN
            RETURN NULL;
        ELSE
            RETURN NEW;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_upsert_recipe_tag
    BEFORE INSERT
    ON recipe_tag
    FOR EACH ROW
EXECUTE FUNCTION upsert_recipe_tag();



-- валидация добавления рецептов в коллекции
CREATE OR REPLACE FUNCTION upsert_collection_recipe()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    existing_record_id BIGINT;
    existing_deleted_at TIMESTAMPTZ;
BEGIN

    SELECT id, deleted_at
    INTO existing_record_id, existing_deleted_at
    FROM collection_recipe
    WHERE collection_id = NEW.collection_id
      AND recipe_id = NEW.recipe_id;

    IF existing_record_id IS NOT NULL THEN
        IF existing_deleted_at IS NULL THEN
            RETURN NULL;
        ELSE
            RETURN NEW;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_upsert_collection_recipe
    BEFORE INSERT
    ON collection_recipe
    FOR EACH ROW
EXECUTE FUNCTION upsert_collection_recipe();


---------------------------------------------------------------------


-- тут есть отличия, а дальше также
-- валидация добавления ингредиентов рецептов
CREATE OR REPLACE FUNCTION upsert_recipe_ingredient()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    existing_record_id BIGINT;
    existing_deleted_at TIMESTAMPTZ;
    records_match BOOLEAN;
    existing_quantity NUMERIC(10,3);
    existing_unit_id INT;
    existing_notes VARCHAR(256);
BEGIN

    SELECT id, deleted_at, quantity, unit_id, notes
    INTO existing_record_id, existing_deleted_at, existing_quantity, existing_unit_id, existing_notes
    FROM recipe_ingredient
    WHERE recipe_id = NEW.recipe_id
      AND ingredient_id = NEW.ingredient_id;

    IF existing_record_id IS NOT NULL THEN
        -- проверяем, совпадают ли все параметры
        records_match := (
            existing_quantity = NEW.quantity AND
            existing_unit_id = NEW.unit_id AND
            COALESCE(existing_notes, '') = COALESCE(NEW.notes, '')
        );

        IF records_match THEN
            IF existing_deleted_at IS NULL THEN
                -- полностью совпадает и не удалена - игнорируем
                RETURN NULL;
            ELSE
                -- совпадает, но удалена - создаем новую
                RETURN NEW;
            END IF;
        ELSE
            -- параметры отличаются - помечаем старую запись как удаленную
            UPDATE recipe_ingredient
            SET deleted_at = CURRENT_TIMESTAMP
            WHERE id = existing_record_id
              AND deleted_at IS NULL;
            -- создаем новую запись
            RETURN NEW;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_upsert_recipe_ingredient
    BEFORE INSERT
    ON recipe_ingredient
    FOR EACH ROW
EXECUTE FUNCTION upsert_recipe_ingredient();




-- валидация добавления продуктов в список покупок
CREATE OR REPLACE FUNCTION upsert_shop_list_item()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    existing_record_id BIGINT;
    existing_deleted_at TIMESTAMPTZ;
    records_match BOOLEAN;
    existing_quantity NUMERIC(10,3);
    existing_unit_id INT;
BEGIN

    SELECT id, deleted_at, quantity, unit_id
    INTO existing_record_id, existing_deleted_at, existing_quantity, existing_unit_id
    FROM shop_list_item
    WHERE shop_list_id = NEW.shop_list_id
      AND ingredient_id = NEW.ingredient_id;

    IF existing_record_id IS NOT NULL THEN
        records_match := (
            existing_quantity = NEW.quantity AND
            existing_unit_id = NEW.unit_id
        );

        IF records_match THEN
            IF existing_deleted_at IS NULL THEN
                RETURN NULL;
            ELSE
                RETURN NEW;
            END IF;
        ELSE
            UPDATE shop_list_item
            SET deleted_at = CURRENT_TIMESTAMP
            WHERE id = existing_record_id
              AND deleted_at IS NULL;
            RETURN NEW;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_upsert_shop_list_item
    BEFORE INSERT
    ON shop_list_item
    FOR EACH ROW
EXECUTE FUNCTION upsert_shop_list_item();



-- валидация добавления отзывов к рецепту
CREATE OR REPLACE FUNCTION upsert_review()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    existing_record_id BIGINT;
    existing_deleted_at TIMESTAMPTZ;
    records_match BOOLEAN;
    existing_rating SMALLINT;
    existing_comment VARCHAR(1024);
BEGIN

    SELECT id, deleted_at, rating, comment
    INTO existing_record_id, existing_deleted_at, existing_rating, existing_comment
    FROM review
    WHERE user_id = NEW.user_id
      AND recipe_id = NEW.recipe_id;

    IF existing_record_id IS NOT NULL THEN
        records_match := (
            existing_rating = NEW.rating AND
            COALESCE(existing_comment, '') = COALESCE(NEW.comment, '')
        );

        IF records_match THEN
            IF existing_deleted_at IS NULL THEN
                RETURN NULL;
            ELSE
                RETURN NEW;
            END IF;
        ELSE
            UPDATE review
            SET deleted_at = CURRENT_TIMESTAMP
            WHERE id = existing_record_id
              AND deleted_at IS NULL;
            RETURN NEW;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


CREATE OR REPLACE TRIGGER trg_upsert_review
    BEFORE INSERT
    ON review
    FOR EACH ROW
EXECUTE FUNCTION upsert_review();
