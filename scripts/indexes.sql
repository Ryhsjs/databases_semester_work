-- user
CREATE INDEX idx_user_email ON "user"(email);
CREATE INDEX idx_user_username ON "user"(username);
CREATE INDEX idx_user_deleted ON "user"(deleted_at) WHERE deleted_at IS NULL;

-- session
CREATE INDEX idx_session_user_id ON session(user_id);
CREATE INDEX idx_session_expire_at ON session(expire_at);

-- recipe (самая важная!)
CREATE INDEX idx_recipe_user_id ON recipe(user_id);
CREATE INDEX idx_recipe_created_at ON recipe(created_at DESC);
CREATE INDEX idx_recipe_deleted ON recipe(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_recipe_rating ON recipe(rating DESC) WHERE rating IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_recipe_servings ON recipe(servings) WHERE deleted_at IS NULL;
CREATE INDEX idx_recipe_total_time ON recipe(total_cooking_time) WHERE deleted_at IS NULL;

-- recipe_step
CREATE INDEX idx_recipe_step_recipe_order ON recipe_step(recipe_id, step_order);
CREATE INDEX idx_recipe_step_deleted ON recipe_step(deleted_at) WHERE deleted_at is NULL;

-- review
CREATE INDEX idx_review_recipe_id ON review(recipe_id);
CREATE INDEX idx_review_user_id ON review(user_id);
CREATE INDEX idx_review_recipe_rating ON review(recipe_id, rating) WHERE deleted_at IS NULL;
CREATE INDEX idx_review_deleted ON review(deleted_at) WHERE deleted_at IS NULL;

-- recipe_view
CREATE INDEX idx_recipe_view_recipe_id ON recipe_view(recipe_id);
CREATE INDEX idx_recipe_view_user_id ON recipe_view(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_recipe_view_created_at ON recipe_view(created_at DESC);
CREATE INDEX idx_recipe_view_recipe_created ON recipe_view(recipe_id, created_at DESC);

-- collection
CREATE INDEX idx_collection_user_id ON collection(user_id);
CREATE INDEX idx_collection_deleted ON collection(deleted_at) WHERE deleted_at IS NULL;

-- collection_recipe
CREATE INDEX idx_collection_recipe_collection_id ON collection_recipe(collection_id);
CREATE INDEX idx_collection_recipe_recipe_id ON collection_recipe(recipe_id);
CREATE INDEX idx_collection_recipe_deleted ON collection_recipe(deleted_at) WHERE deleted_at IS NULL;

-- recipe_ingredient
CREATE INDEX idx_recipe_ingredient_recipe_id ON recipe_ingredient(recipe_id);
CREATE INDEX idx_recipe_ingredient_ingredient_id ON recipe_ingredient(ingredient_id);
CREATE INDEX idx_recipe_ingredient_deleted ON recipe_ingredient(deleted_at) WHERE deleted_at is NULL;

-- recipe_category
CREATE INDEX idx_recipe_category_category_id ON recipe_category(category_id);
CREATE INDEX idx_recipe_category_recipe_id ON recipe_category(recipe_id);
CREATE INDEX idx_recipe_category_deleted ON recipe_category(deleted_at) WHERE deleted_at is NULL;

-- shop_list
CREATE INDEX idx_shop_list_user_id ON shop_list(user_id);
CREATE INDEX idx_shop_list_deleted ON shop_list(deleted_at) WHERE deleted_at IS NULL;

-- shop_list_item
CREATE INDEX idx_shop_list_item_shop_list_id ON shop_list_item(shop_list_id);
CREATE INDEX idx_shop_list_item_deleted ON shop_list_item(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_shop_list_item_completed ON shop_list_item(completed) WHERE deleted_at IS NULL;

-- recipe_tag
CREATE INDEX idx_recipe_tag_recipe_id ON recipe_tag(recipe_id);
CREATE INDEX idx_recipe_tag_tag_id ON recipe_tag(tag_id);