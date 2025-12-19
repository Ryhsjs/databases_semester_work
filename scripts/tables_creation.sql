CREATE TABLE IF NOT EXISTS "user"
(
    id            BIGSERIAL PRIMARY KEY,
    username      VARCHAR(32)  NOT NULL UNIQUE CHECK (LENGTH(username) >= 3),
    email         VARCHAR(256) NOT NULL UNIQUE CHECK (email ~* '^[A-z0-9._%+-]+@[A-z0-9.-]+\.[A-Za-z]{2,}$'),
    password_hash VARCHAR(512) NOT NULL,
    salt          VARCHAR(256) NOT NULL,
    avatar_url    VARCHAR(512) DEFAULT NULL,
    created_at    TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ  DEFAULT NULL,
    deleted_at    TIMESTAMPTZ  DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);


-- создания сессии полностью происходит на сервере
CREATE TABLE IF NOT EXISTS session
(
    id        VARCHAR(256) PRIMARY KEY,
    user_id   BIGINT      NOT NULL,
    expire_at TIMESTAMPTZ NOT NULL
);


CREATE TABLE IF NOT EXISTS recipe
(
    id                  BIGSERIAL PRIMARY KEY,
    user_id             BIGINT       NOT NULL,
    title               VARCHAR(128) NOT NULL CHECK (LENGTH(title) >= 3),
    description         VARCHAR(512)          DEFAULT NULL,
    -- время рассчитывается в минутах и 2 часа готовки максимум
    active_cooking_time SMALLINT     NOT NULL CHECK (active_cooking_time > 0 AND active_cooking_time <= 1440),
    total_cooking_time  SMALLINT     NOT NULL CHECK (total_cooking_time >= active_cooking_time),
    -- относительное большое число, если пользователь захочет считать не порции,
    -- а количество приготовленных штук
    servings            SMALLINT     NOT NULL CHECK (servings > 0 AND servings <= 20),
    image_url           VARCHAR(512)          DEFAULT NULL,
    -- рассчитывается через триггер функцию
    views               BIGINT                DEFAULT 0 CHECK (views >= 0),
    -- тоже через триггер функцию
    rating              NUMERIC(3, 2)         DEFAULT NULL CHECK (rating >= 1 AND rating <= 5),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ           DEFAULT NULL CHECK (updated_at IS NULL OR updated_at > created_at),
    deleted_at          TIMESTAMPTZ           DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS recipe_step
(
    id           BIGSERIAL PRIMARY KEY,
    recipe_id    BIGINT        NOT NULL,
    step_order   SMALLINT      NOT NULL,
    instructions VARCHAR(2048) NOT NULL,
    image_url    VARCHAR(512) DEFAULT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at   TIMESTAMPTZ           DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS collection
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT       NOT NULL,
    title      VARCHAR(256) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ           DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS collection_recipe
(
    id            BIGSERIAL PRIMARY KEY,
    collection_id BIGINT NOT NULL,
    recipe_id     BIGINT NOT NULL,
    -- для сортировки по дате добавления
    created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMPTZ DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS review
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT        NOT NULL,
    recipe_id  BIGINT        NOT NULL,
    rating     SMALLINT      NOT NULL CHECK (rating >= 1 AND rating <= 5),
    -- пользователь захочет оставить только оценку без отзыва
    comment    VARCHAR(1024) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ            DEFAULT NULL,
    deleted_at TIMESTAMPTZ            DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);


CREATE TABLE IF NOT EXISTS recipe_view
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT               DEFAULT NULL,
    recipe_id  BIGINT      NOT NULL,
    -- если нужно будет вывести пользователю его историю просмотров,
    -- можно будет сделать это в нужном порядке
    -- удалению будет противоречить целостности данных
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS unit
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(256) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ           DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS ingredient
(
    id                   SERIAL PRIMARY KEY,
    name                 VARCHAR(256) NOT NULL UNIQUE,
    parent_ingredient_id INT DEFAULT NULL,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at           TIMESTAMPTZ           DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS recipe_ingredient
(
    id            BIGSERIAL PRIMARY KEY,
    recipe_id     BIGINT         NOT NULL,
    ingredient_id INT            NOT NULL,
    quantity      NUMERIC(10, 3) NOT NULL CHECK (quantity > 0 AND quantity <= 1000),
    unit_id       INT            NOT NULL,
    notes         VARCHAR(256)   NOT NULL DEFAULT '',
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMPTZ             DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS category
(
    id                 SERIAL PRIMARY KEY,
    name               VARCHAR(256) NOT NULL UNIQUE,
    description        VARCHAR(512) NOT NULL DEFAULT '',
    parent_category_id INT                   DEFAULT NULL,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at         TIMESTAMPTZ           DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS recipe_category
(
    id          BIGSERIAL PRIMARY KEY,
    recipe_id   BIGINT     NOT NULL,
    category_id INT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMPTZ          DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS shop_list
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT       NOT NULL,
    name       VARCHAR(256) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ           DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS shop_list_item
(
    id            BIGSERIAL PRIMARY KEY,
    shop_list_id  BIGINT         NOT NULL,
    ingredient_id INT            NOT NULL,
    quantity      NUMERIC(10, 3) NOT NULL DEFAULT 1 CHECK (quantity > 0 AND quantity <= 1000),
    unit_id       INT            NOT NULL,
    completed     BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMPTZ             DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS tag
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(256) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ           DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS recipe_tag
(
    id         BIGSERIAL PRIMARY KEY,
    recipe_id  BIGINT     NOT NULL,
    tag_id     INT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ          DEFAULT NULL CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);



ALTER TABLE session
    ADD CONSTRAINT fk_sessions_user_id
        FOREIGN KEY (user_id)
            REFERENCES "user" (id)
            ON DELETE CASCADE;


ALTER TABLE recipe
    ADD CONSTRAINT fk_recipes_user_id
        FOREIGN KEY (user_id)
            REFERENCES "user" (id)
            ON DELETE CASCADE;


ALTER TABLE recipe_step
    ADD CONSTRAINT fk_recipe_steps_recipe_id
        FOREIGN KEY (recipe_id)
            REFERENCES recipe (id)
            ON DELETE CASCADE;


ALTER TABLE review
    ADD CONSTRAINT fk_reviews_user_id
        FOREIGN KEY (user_id)
            REFERENCES "user" (id)
            ON DELETE CASCADE,

    ADD CONSTRAINT fk_reviews_recipe_id
        FOREIGN KEY (recipe_id)
            REFERENCES recipe (id)
            ON DELETE CASCADE;


ALTER TABLE collection
    ADD CONSTRAINT fk_collections_user_id
        FOREIGN KEY (user_id)
            REFERENCES "user" (id)
            ON DELETE CASCADE;


ALTER TABLE collection_recipe
    ADD CONSTRAINT fk_collection_recipes_collection_id
        FOREIGN KEY (collection_id)
            REFERENCES collection (id)
            ON DELETE CASCADE,

    ADD CONSTRAINT fk_collection_recipes_recipe_id
        FOREIGN KEY (recipe_id)
            REFERENCES recipe (id)
            ON DELETE CASCADE;


ALTER TABLE recipe_view
    ADD CONSTRAINT fk_recipe_views_recipe_id
        FOREIGN KEY (recipe_id)
            REFERENCES recipe (id)
            ON DELETE CASCADE,

    ADD CONSTRAINT fk_recipe_views_user_id
        FOREIGN KEY (user_id)
            REFERENCES "user" (id)
            ON DELETE SET NULL;


ALTER TABLE ingredient
    ADD CONSTRAINT fk_ingredients_parent_ingredient_id
        FOREIGN KEY (parent_ingredient_id)
            REFERENCES ingredient (id)
            ON DELETE SET NULL,

    ADD CONSTRAINT check_ingredient_not_self_referencing
        CHECK (parent_ingredient_id != id OR parent_ingredient_id IS NULL);


ALTER TABLE recipe_ingredient
    ADD CONSTRAINT fk_recipe_ingredients_recipe_id
        FOREIGN KEY (recipe_id)
            REFERENCES recipe (id)
            ON DELETE CASCADE,

    ADD CONSTRAINT fk_recipe_ingredients_ingredient_id
        FOREIGN KEY (ingredient_id)
            REFERENCES ingredient (id)
            ON DELETE RESTRICT,

    ADD CONSTRAINT fk_recipe_ingredients_unit_id
        FOREIGN KEY (unit_id)
            REFERENCES unit (id)
            ON DELETE RESTRICT;


ALTER TABLE category
    ADD CONSTRAINT fk_categories_parent_category_id
        FOREIGN KEY (parent_category_id)
            REFERENCES category (id)
            ON DELETE SET NULL,

    ADD CONSTRAINT check_category_not_self_referencing
        CHECK (parent_category_id != id OR parent_category_id IS NULL);

ALTER TABLE recipe_category
    ADD CONSTRAINT fk_recipe_categories_recipe_id
        FOREIGN KEY (recipe_id)
            REFERENCES recipe (id)
            ON DELETE CASCADE,

    ADD CONSTRAINT fk_recipe_categories_category_id
        FOREIGN KEY (category_id)
            REFERENCES category (id)
            ON DELETE RESTRICT;

ALTER TABLE shop_list
    ADD CONSTRAINT fk_shop_lists_user_id
        FOREIGN KEY (user_id)
            REFERENCES "user" (id)
            ON DELETE CASCADE;


ALTER TABLE shop_list_item
    ADD CONSTRAINT fk_shop_list_items_shop_list_id
        FOREIGN KEY (shop_list_id)
            REFERENCES shop_list (id)
            ON DELETE CASCADE,

    ADD CONSTRAINT fk_shop_list_items_ingredient_id
        FOREIGN KEY (ingredient_id)
            REFERENCES ingredient (id)
            ON DELETE RESTRICT,

    ADD CONSTRAINT fk_shop_list_items_unit_id
        FOREIGN KEY (unit_id)
            REFERENCES unit (id)
            ON DELETE RESTRICT;


ALTER TABLE recipe_tag
    ADD CONSTRAINT fk_recipe_tags_tag_id
        FOREIGN KEY (tag_id)
            REFERENCES tag (id)
            ON DELETE CASCADE,

    ADD CONSTRAINT fk_recipe_tags_recipe_id
        FOREIGN KEY (recipe_id)
            REFERENCES recipe (id)
            ON DELETE CASCADE;