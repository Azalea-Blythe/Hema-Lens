import numpy as np

def fuse_risk(image_probs_list, survey_dict):
    """
    Fuses image probabilities from multiple scans (Conjunctiva, Fingernails, Palm) 
    with survey data based on WHO guidelines.
    
    Args:
        image_probs_list (list of dict): List containing prob dicts for each scan,
            e.g. [{'low': 0.8, 'moderate': 0.1, 'high': 0.1}, ...]
        survey_dict (dict): {
            'pregnant': bool,
            'heavy_menstrual_bleeding': bool,
            'pica_present': bool,
            'malaria_history': bool,
            'fatigue': bool,
            'pallor': bool,
            'vegetarian_diet': bool,
            'prior_anaemia_diagnosis': bool
        }
        
    Returns:
        dict: {'adjusted_probs': dict, 'final_risk': str, 'confidence': float}
    """
    
    # Average the probabilities across all scans provided
    low_prob = sum(p.get('low', 0.0) for p in image_probs_list) / max(1, len(image_probs_list))
    mod_prob = sum(p.get('moderate', 0.0) for p in image_probs_list) / max(1, len(image_probs_list))
    high_prob = sum(p.get('high', 0.0) for p in image_probs_list) / max(1, len(image_probs_list))

    survey_boost = 0.0
    if survey_dict.get('pregnant', False):
        survey_boost += 0.15
    if survey_dict.get('heavy_menstrual_bleeding', False):
        survey_boost += 0.15
    if survey_dict.get('pica_present', False):
        survey_boost += 0.12
    if survey_dict.get('malaria_history', False):
        survey_boost += 0.08
    if survey_dict.get('fatigue', False) and survey_dict.get('pallor', False):
        survey_boost += 0.08
    if survey_dict.get('vegetarian_diet', False):
        survey_boost += 0.05
    if survey_dict.get('prior_anaemia_diagnosis', False):
        survey_boost += 0.05

    adjusted_high = min(1.0, high_prob + survey_boost)
    
    # Calculate remainder to distribute among low and moderate
    remainder = 1.0 - adjusted_high
    original_non_high = low_prob + mod_prob
    if original_non_high > 0:
        adjusted_low = low_prob * (remainder / original_non_high)
        adjusted_mod = mod_prob * (remainder / original_non_high)
    else:
        # Fallback if original was 100% high
        adjusted_low = 0.0
        adjusted_mod = 0.0
        
    adjusted_probs = {
        'low': adjusted_low,
        'moderate': adjusted_mod,
        'high': adjusted_high
    }

    # argmax
    final_risk = max(adjusted_probs, key=adjusted_probs.get)
    confidence = adjusted_probs[final_risk]

    return {
        'adjusted_probs': adjusted_probs,
        'final_risk': final_risk,
        'confidence': confidence
    }

# Unit tests
if __name__ == '__main__':
    def test_case(name, probs, survey, expected_tier):
        res = fuse_risk([probs], survey)
        if res['final_risk'] == expected_tier:
            print(f"✅ {name}: {res['final_risk']} (Conf: {res['confidence']:.2f})")
        else:
            print(f"❌ {name}: Expected {expected_tier}, got {res['final_risk']} (Probs: {res['adjusted_probs']})")

    # Edge Case 1: All False, Normal BMI, no change
    test_case("Base Case", 
              {'low': 0.8, 'moderate': 0.1, 'high': 0.1}, 
              {}, 
              'low')

    # Edge Case 2: Pregnant + Heavy Menstrual Bleeding tips moderate to high
    test_case("Pregnant + HMB", 
              {'low': 0.3, 'moderate': 0.4, 'high': 0.3}, 
              {'pregnant': True, 'heavy_menstrual_bleeding': True}, 
              'high')

    # Edge Case 3: Everything goes wrong! Boost > 1.0
    test_case("Max Boost", 
              {'low': 0.9, 'moderate': 0.05, 'high': 0.05}, 
              {'pregnant': True, 'heavy_menstrual_bleeding': True, 
               'pica_present': True, 'malaria_history': True, 'fatigue': True, 'pallor': True, 
               'vegetarian_diet': True, 'prior_anaemia_diagnosis': True}, 
              'high') # Boost = 0.68, High = 0.73

    # Edge Case 4: Fatigue without pallor (No boost)
    test_case("Fatigue Only", 
              {'low': 0.5, 'moderate': 0.4, 'high': 0.1}, 
              {'fatigue': True}, 
              'low')

    # Edge Case 5: Fatigue WITH pallor
    test_case("Fatigue + Pallor", 
              {'low': 0.4, 'moderate': 0.3, 'high': 0.3}, 
              {'fatigue': True, 'pallor': True}, 
              'high') # High is 0.3 + 0.08 = 0.38, Low becomes 0.4 * (0.62 / 0.7) = 0.35

    # Edge Case 6: Pica Present tips low to moderate? No, it goes to high.
    test_case("Pica Present", 
              {'low': 0.45, 'moderate': 0.25, 'high': 0.30}, 
              {'pica_present': True}, 
              'high') # High = 0.42

    # Edge Case 7: Vegetarian + Prior Anaemia
    test_case("Vegetarian + Prior", 
              {'low': 0.4, 'moderate': 0.35, 'high': 0.25}, 
              {'vegetarian_diet': True, 'prior_anaemia_diagnosis': True}, 
              'high') # High = 0.25 + 0.10 = 0.35, Low = 0.4 * (0.65 / 0.75) ≈ 0.34

    # Edge Case 8: Extreme Image Prob High (No Boost needed)
    test_case("Image Very High", 
              {'low': 0.05, 'moderate': 0.05, 'high': 0.90}, 
              {}, 
              'high')

    # Edge Case 10: Zero values
    test_case("Missing Data", 
              {'low': 0.6, 'moderate': 0.3, 'high': 0.1}, 
              {}, 
              'low')
