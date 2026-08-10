# Model Info & Hierarchy

1. **CategoryModel**
   - `name`: String
   - `recipes`: Array of RecipeModel

2. **RecipeModel**
   - `name`: String
   - `ingredients`: Array of IngredientModel (Cascade delete rule)
   - `steps`: Array of StepModel (Cascade delete rule)
   - `image`: Data (Optional)
   - `category`: CategoryModel (Optional)
   - `minutesToCook`: Int
   - `servingSize`: Int

3. **IngredientModel**
   - `name`: String
   - `quantity`: String (Optional)
   - `recipes`: Array of RecipeModel

4. **StepModel**
   - `stepNumber`: Int
   - `instruction`: String
   - `image`: Data (Optional)
   - `recipe`: RecipeModel (Optional)

## Hierarchy:
- CategoryModel
    - RecipeModel
        - IngredientModel
        - StepModel

## Diagram
- **CategoryModel** `1----*` **RecipeModel** `1----*` **IngredientModel/StepModel**
    - `1----*` represents a one-to-many relationship.
    - RecipeModel can have multiple IngredientModels and StepModels.
