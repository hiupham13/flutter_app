import '../../../../models/food_model.dart';
import '../interfaces/scorer_interfaces.dart';

/// Dietary restriction types
enum DietaryRestriction {
  keto,
  vegan,
  vegetarian,
  halal,
  lowCarb,
  glutenFree,
  dairyFree,
  nutFree,
}

/// Scores foods based on dietary restrictions
/// Implements IDietaryRestrictionScorer interface (DIP)
class DietaryRestrictionScorer implements IDietaryRestrictionScorer {
  /// Get dietary multiplier based on restrictions
  /// Returns 0.1 if food doesn't match restriction (hard filter)
  /// Returns 1.0 if matches or no restrictions
  @override
  double getDietaryMultiplier(
    FoodModel food,
    List<DietaryRestriction> restrictions,
  ) {
    if (restrictions.isEmpty) {
      return 1.0; // No restrictions
    }
    
    double multiplier = 1.0;
    
    for (final restriction in restrictions) {
      switch (restriction) {
        case DietaryRestriction.keto:
          // Check if food is keto-friendly
          final isKeto = food.flavorProfile.contains('keto') ||
                        food.contextScores['is_keto'] == 1.0;
          if (!isKeto) {
            multiplier *= 0.1; // Hard penalty
          }
          break;
          
        case DietaryRestriction.vegan:
          // Check if food is vegan
          final isVegan = food.flavorProfile.contains('vegan') ||
                         food.contextScores['is_vegan'] == 1.0;
          if (!isVegan) {
            multiplier *= 0.1; // Hard penalty
          }
          break;
          
        case DietaryRestriction.vegetarian:
          // Check if food is vegetarian (already handled in context)
          final isVegetarian = food.flavorProfile.contains('vegetarian') ||
                             food.contextScores['is_vegetarian'] == 1.0;
          if (!isVegetarian) {
            multiplier *= 0.1; // Hard penalty
          }
          break;
          
        case DietaryRestriction.halal:
          // Check if food is halal
          final isHalal = food.flavorProfile.contains('halal') ||
                         food.contextScores['is_halal'] == 1.0;
          if (!isHalal) {
            multiplier *= 0.1; // Hard penalty
          }
          break;
          
        case DietaryRestriction.lowCarb:
          // Check carb content (if available)
          // For now, check flavor profile
          final isLowCarb = food.flavorProfile.contains('low-carb') ||
                          food.contextScores['is_low_carb'] == 1.0;
          if (!isLowCarb) {
            multiplier *= 0.5; // Moderate penalty (not as strict)
          }
          break;
          
        case DietaryRestriction.glutenFree:
          // Check if contains gluten allergen
          if (food.allergenTags.contains('gluten')) {
            multiplier *= 0.1; // Hard penalty
          }
          break;
          
        case DietaryRestriction.dairyFree:
          // Check if contains dairy allergen
          if (food.allergenTags.contains('dairy') || 
              food.allergenTags.contains('lactose')) {
            multiplier *= 0.1; // Hard penalty
          }
          break;
          
        case DietaryRestriction.nutFree:
          // Check if contains nut allergens
          final hasNuts = food.allergenTags.any(
            (tag) => tag.contains('nut') || 
                    tag.contains('peanut') || 
                    tag.contains('almond'),
          );
          if (hasNuts) {
            multiplier *= 0.1; // Hard penalty
          }
          break;
      }
    }
    
    return multiplier;
  }
  
  /// Check if food matches all restrictions
  @override
  bool matchesRestrictions(
    FoodModel food,
    List<DietaryRestriction> restrictions,
  ) {
    return getDietaryMultiplier(food, restrictions) > 0.5;
  }
  
  /// Convert string to DietaryRestriction enum
  static DietaryRestriction? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'keto':
        return DietaryRestriction.keto;
      case 'vegan':
        return DietaryRestriction.vegan;
      case 'vegetarian':
        return DietaryRestriction.vegetarian;
      case 'halal':
        return DietaryRestriction.halal;
      case 'low-carb':
      case 'lowcarb':
        return DietaryRestriction.lowCarb;
      case 'gluten-free':
      case 'glutenfree':
        return DietaryRestriction.glutenFree;
      case 'dairy-free':
      case 'dairyfree':
        return DietaryRestriction.dairyFree;
      case 'nut-free':
      case 'nutfree':
        return DietaryRestriction.nutFree;
      default:
        return null;
    }
  }
  
  /// Convert list of strings to DietaryRestriction list
  static List<DietaryRestriction> fromStringList(List<String> values) {
    return values
        .map((v) => fromString(v))
        .whereType<DietaryRestriction>()
        .toList();
  }
}

