# TRUST_SCORE_ENGINE.md

# PureScan AI Trust Score Engine

## Purpose

The Trust Score Engine is the core intelligence system of PureScan AI.

Its purpose is to convert complex ingredient and nutritional information into a transparent score between 0 and 100.

The score helps consumers quickly evaluate the overall quality and trustworthiness of a food product.

---

# Philosophy

The system does NOT determine:

- Safe or Unsafe
- Good or Bad

Instead, it evaluates:

- Ingredient quality
- Nutritional quality
- Additive density
- Processing level
- Transparency

The score is designed to assist decision-making, not replace professional medical advice.

---

# Final Score Formula

```text
Trust Score =
Ingredient Quality Score
+
Nutrition Score
+
Transparency Score
-
Risk Penalties
```

Maximum Score:

100

Minimum Score:

0

---

# Score Breakdown

| Category | Weight |
|-----------|---------|
| Ingredient Quality | 40 |
| Nutrition Quality | 30 |
| Transparency | 10 |
| Additives & Risks | 20 |

Total:

100 Points

---

# Ingredient Quality Score

Maximum:

40 Points

---

## Natural Ingredients

Award:

+1 point per ingredient

Maximum:

20 points

Examples:

- Oats
- Milk
- Almonds
- Cocoa

---

## Whole Food Ingredients

Award:

+2 points each

Maximum:

20 points

Examples:

- Whole Grain Oats
- Peanuts
- Brown Rice

---

# Nutrition Score

Maximum:

30 Points

---

## Sugar

| Sugar Level | Score |
|------------|--------|
| Very Low | +10 |
| Low | +8 |
| Moderate | +5 |
| High | 0 |

---

## Sodium

| Sodium Level | Score |
|-------------|--------|
| Low | +10 |
| Moderate | +5 |
| High | 0 |

---

## Protein

| Protein Level | Score |
|--------------|--------|
| High | +10 |
| Moderate | +5 |
| Low | 0 |

---

# Transparency Score

Maximum:

10 Points

Awarded when:

- Ingredient list exists
- Nutrition facts exist
- Claims are verifiable

---

# Risk Penalties

Maximum Deduction:

20 Points

---

## Artificial Colors

| Count | Penalty |
|---------|---------|
| 1 | -2 |
| 2 | -4 |
| 3+ | -8 |

---

## Artificial Sweeteners

| Count | Penalty |
|---------|---------|
| 1 | -3 |
| 2+ | -6 |

---

## Preservatives

| Count | Penalty |
|---------|---------|
| 1 | -2 |
| 2 | -4 |
| 3+ | -8 |

---

## High-Risk Ingredients

Examples:

- BHA
- BHT
- Certain controversial additives

Penalty:

-5 each

Maximum:

-20

---

# Final Rating

| Score | Rating |
|---------|---------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Moderate |
| 40-59 | Poor |
| 0-39 | Avoid Frequent Consumption |

---

# Explainability

Every score must generate reasons.

Example:

```text
Trust Score: 82

Reasons:
+ High Protein
+ Low Sugar
+ Whole Grain Ingredients

- Contains 2 Preservatives
- Contains Artificial Flavor
```

---

# Versioning

Every score calculation must be stored.

Example:

```text
Trust Score Engine v1.0
```

Future versions:

```text
v1.1
v2.0
v3.0
```

---

Status: Approved

Version: 1.0