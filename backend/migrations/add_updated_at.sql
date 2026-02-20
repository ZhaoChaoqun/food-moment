-- Migration: Add updated_at columns for sync conflict resolution
-- Run this against the production database before deploying the code.

-- MealRecord: add updated_at
ALTER TABLE meal_records ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
UPDATE meal_records SET updated_at = created_at WHERE updated_at IS NULL;

-- WaterLog: add created_at and updated_at
ALTER TABLE water_logs ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE water_logs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- WeightLog: add updated_at
ALTER TABLE weight_logs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
UPDATE weight_logs SET updated_at = created_at WHERE updated_at IS NULL;
