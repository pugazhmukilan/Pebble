/// Named, centrally-tunable thresholds that drive the deterministic insight
/// rules. All insight logic reads from these constants — one file to tune.
library;

/// A month is a "spike" when its total exceeds the range average by this
/// fraction (0.30 = 30%).
const double kInsightSpikeThreshold = 0.30;

/// Smallest single-expense amount (₹) that can earn a "largest expense"
/// insight.
const double kInsightLargestMin = 500;

/// A run counts as "flat" when each month's total stays within this fraction
/// (±0.05 = ±5%) of the range average.
const double kInsightFlatBand = 0.05;

/// A category's share change (percentage points) that triggers a "share
/// shift" insight.
const double kInsightShareShiftPp = 10;

/// Minimum number of months required before trend charts overlay multiple
/// months (single-month ranges don't make sense as trends).
const int kMinTrendMonths = 2;