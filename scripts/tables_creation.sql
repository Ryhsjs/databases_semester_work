CREATE TABLE IF NOT EXISTS "user"
(
    id            BIGSERIAL PRIMARY KEY,
    username      VARCHAR(32)  NOT NULL UNIQUE,
    email         VARCHAR(256) NOT NULL UNIQUE,
    password_hash VARCHAR(512) NOT NULL,
    salt          VARCHAR(256) NOT NULL,
    avatar_url    VARCHAR(512) DEFAULT NULL,
    created_at    TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ  DEFAULT NULL,
    deleted_at    TIMESTAMPTZ  DEFAULT NULL,

    CONSTRAINT chk_user_username_length CHECK (LENGTH(username) >= 3),
    CONSTRAINT chk_user_email_format CHECK (email ~* '^[A-z0-9._%+-]+@[A-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_user_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);


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
    title               VARCHAR(128) NOT NULL,
    description         VARCHAR(512)          DEFAULT NULL,
    active_cooking_time SMALLINT     NOT NULL,
    total_cooking_time  SMALLINT     NOT NULL,
    servings            SMALLINT     NOT NULL,
    image_url           VARCHAR(512)          DEFAULT NULL,
    views               BIGINT                DEFAULT 0,
    rating              NUMERIC(3, 2)         DEFAULT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ           DEFAULT NULL,
    deleted_at          TIMESTAMPTZ           DEFAULT NULL,

    CONSTRAINT chk_recipe_title_length CHECK (LENGTH(title) >= 3),
    CONSTRAINT chk_recipe_active_cooking_time CHECK (active_cooking_time > 0 AND active_cooking_time <= 1440),
    CONSTRAINT chk_recipe_total_cooking_time CHECK (total_cooking_time >= active_cooking_time),
    CONSTRAINT chk_recipe_servings CHECK (servings > 0 AND servings <= 20),
    CONSTRAINT chk_recipe_views CHECK (views >= 0),
    CONSTRAINT chk_recipe_rating CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT chk_recipe_updated_at CHECK (updated_at IS NULL OR updated_at > created_at),
    CONSTRAINT chk_recipe_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS recipe_step
(
    id           BIGSERIAL PRIMARY KEY,
    recipe_id    BIGINT        NOT NULL,
    step_order   SMALLINT      NOT NULL,
    instructions VARCHAR(2048) NOT NULL,
    image_url    VARCHAR(512) DEFAULT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at   TIMESTAMPTZ           DEFAULT NULL,

    CONSTRAINT chk_recipe_step_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS collection
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT       NOT NULL,
    title      VARCHAR(256) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ           DEFAULT NULL,

    CONSTRAINT chk_collection_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS collection_recipe
(
    id            BIGSERIAL PRIMARY KEY,
    collection_id BIGINT NOT NULL,
    recipe_id     BIGINT NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMPTZ DEFAULT NULL,

    CONSTRAINT chk_collection_recipe_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS review
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT        NOT NULL,
    recipe_id  BIGINT        NOT NULL,
    rating     SMALLINT      NOT NULL,
    comment    VARCHAR(1024) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ            DEFAULT NULL,
    deleted_at TIMESTAMPTZ            DEFAULT NULL,

    CONSTRAINT chk_review_rating CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT chk_review_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);


CREATE TABLE IF NOT EXISTS recipe_view
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT               DEFAULT NULL,
    recipe_id  BIGINT      NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS unit
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(256) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ           DEFAULT NULL,

    CONSTRAINT chk_unit_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS ingredient
(
    id                   SERIAL PRIMARY KEY,
    name                 VARCHAR(256) NOT NULL UNIQUE,
    parent_ingredient_id INT DEFAULT NULL,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at           TIMESTAMPTZ           DEFAULT NULL,

    CONSTRAINT chk_ingredient_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS recipe_ingredient
(
    id            BIGSERIAL PRIMARY KEY,
    recipe_id     BIGINT         NOT NULL,
    ingredient_id INT            NOT NULL,
    quantity      NUMERIC(10, 3) NOT NULL,
    unit_id       INT            NOT NULL,
    notes         VARCHAR(256)   NOT NULL DEFAULT '',
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMPTZ             DEFAULT NULL,

    CONSTRAINT chk_recipe_ingredient_quantity CHECK (quantity > 0 AND quantity <= 1000),
    CONSTRAINT chk_recipe_ingredient_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS category
(
    id                 SERIAL PRIMARY KEY,
    name               VARCHAR(256) NOT NULL UNIQUE,
    description        VARCHAR(512) NOT NULL DEFAULT '',
    parent_category_id INT                   DEFAULT NULL,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at         TIMESTAMPTZ           DEFAULT NULL,

    CONSTRAINT chk_category_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS recipe_category
(
    id          BIGSERIAL PRIMARY KEY,
    recipe_id   BIGINT      NOT NULL,
    category_id INT         NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMPTZ          DEFAULT NULL,

    CONSTRAINT chk_recipe_category_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS shop_list
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT       NOT NULL,
    name       VARCHAR(256) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ           DEFAULT NULL,

    CONSTRAINT chk_shop_list_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS shop_list_item
(
    id            BIGSERIAL PRIMARY KEY,
    shop_list_id  BIGINT         NOT NULL,
    ingredient_id INT            NOT NULL,
    quantity      NUMERIC(10, 3) NOT NULL DEFAULT 1,
    unit_id       INT            NOT NULL,
    completed     BOOLEAN        NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMPTZ             DEFAULT NULL,

    CONSTRAINT chk_shop_list_item_quantity CHECK (quantity > 0 AND quantity <= 1000),
    CONSTRAINT chk_shop_list_item_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS tag
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(256) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ           DEFAULT NULL,

    CONSTRAINT chk_tag_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

CREATE TABLE IF NOT EXISTS recipe_tag
(
    id         BIGSERIAL PRIMARY KEY,
    recipe_id  BIGINT      NOT NULL,
    tag_id     INT         NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ          DEFAULT NULL,

    CONSTRAINT chk_recipe_tag_deleted_at CHECK (deleted_at IS NULL OR deleted_at >= created_at)
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