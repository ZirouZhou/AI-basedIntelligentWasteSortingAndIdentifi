-- One-time (idempotent) data normalization for historical classification logs.
-- Goal: convert legacy Chinese labels in vision_classification_logs to English.
-- Safe to run multiple times.

USE `20260419_ai_intelligent_waste_sorting_identification_app`;

START TRANSACTION;

-- 1) Normalize mapped category title to England-standard English labels.
UPDATE vision_classification_logs
SET mapped_category_title = CASE
  WHEN mapped_category_title LIKE '%有害%' OR mapped_category_title LIKE '%危险%' THEN 'Household Hazardous Waste'
  WHEN mapped_category_title LIKE '%厨余%' OR mapped_category_title LIKE '%湿%' OR mapped_category_title LIKE '%食品%' THEN 'Food Waste'
  WHEN mapped_category_title LIKE '%可回收%' OR mapped_category_title LIKE '%回收%' THEN 'Mixed Recyclables'
  WHEN mapped_category_title LIKE '%其他%' OR mapped_category_title LIKE '%干垃圾%' OR mapped_category_title LIKE '%残余%' THEN 'General Waste'
  ELSE mapped_category_title
END
WHERE mapped_category_title REGEXP '[一-龥]';

-- 2) Normalize raw category label text from AI provider.
UPDATE vision_classification_logs
SET category_label = CASE
  WHEN category_label LIKE '%有害%' OR category_label LIKE '%危险%' THEN 'Hazardous'
  WHEN category_label LIKE '%厨余%' OR category_label LIKE '%湿%' OR category_label LIKE '%食品%' THEN 'Organic'
  WHEN category_label LIKE '%可回收%' OR category_label LIKE '%回收%' THEN 'Recyclable'
  WHEN category_label LIKE '%其他%' OR category_label LIKE '%干垃圾%' OR category_label LIKE '%残余%' THEN 'Residual'
  ELSE category_label
END
WHERE category_label REGEXP '[一-龥]';

-- 3) Normalize identified item names.
UPDATE vision_classification_logs
SET rubbish_label = CASE
  WHEN rubbish_label LIKE '%电池%' OR rubbish_label LIKE '%蓄电池%' THEN 'Battery'
  WHEN rubbish_label LIKE '%塑料瓶%' OR rubbish_label LIKE '%矿泉水瓶%' THEN 'Plastic bottle'
  WHEN rubbish_label LIKE '%纸%' OR rubbish_label LIKE '%纸张%' THEN 'Paper'
  WHEN rubbish_label LIKE '%玻璃器皿%' THEN 'Glassware'
  WHEN rubbish_label LIKE '%玻璃%' OR rubbish_label LIKE '%玻璃瓶%' THEN 'Glass bottle'
  WHEN rubbish_label LIKE '%易拉罐%' OR rubbish_label LIKE '%罐%' THEN 'Aluminium can'
  WHEN rubbish_label LIKE '%果皮%' OR rubbish_label LIKE '%水果%' THEN 'Fruit peel'
  WHEN rubbish_label LIKE '%菜叶%' OR rubbish_label LIKE '%蔬菜%' THEN 'Vegetable scraps'
  WHEN rubbish_label LIKE '%药品%' OR rubbish_label LIKE '%药%' THEN 'Medicine'
  WHEN rubbish_label LIKE '%油漆%' THEN 'Paint'
  WHEN rubbish_label LIKE '%餐巾纸%' OR rubbish_label LIKE '%纸巾%' THEN 'Used tissue'
  WHEN rubbish_label LIKE '%毯子%' OR rubbish_label LIKE '%毛毯%' THEN 'Blanket'
  WHEN rubbish_label LIKE '%衣物%' OR rubbish_label LIKE '%纺织%' THEN 'Textiles'
  WHEN rubbish_label LIKE '%陶瓷%' THEN 'Ceramics'
  ELSE 'Unspecified item'
END
WHERE rubbish_label REGEXP '[一-龥]';

COMMIT;

-- Post-check: if script worked, all three counts should be 0.
SELECT
  SUM(mapped_category_title REGEXP '[一-龥]') AS mapped_category_title_cn_rows,
  SUM(category_label REGEXP '[一-龥]') AS category_label_cn_rows,
  SUM(rubbish_label REGEXP '[一-龥]') AS rubbish_label_cn_rows
FROM vision_classification_logs;
