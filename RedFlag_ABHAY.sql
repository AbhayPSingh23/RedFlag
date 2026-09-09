-- ===================================================================== 
-- RedFlag — Fraud Detection Submission -- Student: ABHAY | Batch: DA-DS-1 
-- ===================================================================== 

USE redflag;

-- =========================================================
-- P1 · Velocity Fraud
-- Detects users making 30 or more transactions
-- on a single calendar day.
-- ========================================================= 

SELECT
    user_id,
    DATE(txn_time) AS transaction_date,
    COUNT(DISTINCT txn_id) AS transaction_count
FROM transactions
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(DISTINCT txn_id) >= 30
ORDER BY transaction_count DESC;

-- =========================================================
-- P2 · Round-Amount Clustering
-- Detects users with 15 or more transactions using
-- the specified exact round amounts.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS round_amount_transactions
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_amount_transactions DESC;

-- =========================================================
-- P3 · Card Testing
-- Detects users making 30 or more transactions
-- below ₹10 on a single day.
-- =========================================================

SELECT
    user_id,
    DATE(txn_time) AS transaction_date,
    COUNT(*) AS tiny_transaction_count
FROM transactions
WHERE amount < 10
GROUP BY
    user_id,
    DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY tiny_transaction_count DESC;

-- =========================================================
-- P4 · Failed-Then-Succeeded
-- Detects users with 20 or more failed transactions,
-- indicating possible automated card-testing behaviour.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS failed_transaction_count
FROM transactions
WHERE status = 'FAILED'
GROUP BY user_id
HAVING COUNT(*) >= 20
ORDER BY failed_transaction_count DESC;

-- =========================================================
-- P5 · Odd-Hour Concentration
--  Detects users with at least 30 transactions where
-- 80% or more occur between 2 AM and 4 AM.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) AS odd_hour_transactions,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS odd_hour_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND
   SUM(
       CASE
           WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
           ELSE 0
       END
   ) / COUNT(*) >= 0.80
ORDER BY odd_hour_percentage DESC;

-- =========================================================
-- P6 · Mule Accounts
-- Detects users with 8 or more credit transactions,
-- indicating possible mule-account activity.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS credit_transaction_count
FROM transactions
WHERE txn_type = 'CREDIT'
GROUP BY user_id
HAVING COUNT(*) >= 8
ORDER BY credit_transaction_count DESC;

-- =========================================================
-- P7 · Refund Abuse
-- Detects users with 20 or more total transactions
-- where more than 40% of transactions are refunds.
-- ========================================================= 

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) AS refund_transactions,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN txn_type = 'REFUND' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS refund_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND
   SUM(
       CASE
           WHEN txn_type = 'REFUND' THEN 1
           ELSE 0
       END
   ) / COUNT(*) > 0.40
ORDER BY refund_percentage DESC;

-- =========================================================
-- P8 · Merchant Collusion
-- Detects merchants where the top 5 users by transaction
-- volume account for more than 60% of the merchant's total volume.
-- =========================================================

WITH user_merchant_volume AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_volume
    FROM transactions
    GROUP BY
        merchant_id,
        user_id
),

ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_volume,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_volume DESC
        ) AS user_rank
    FROM user_merchant_volume
),

top_5_volume AS (
    SELECT
        merchant_id,
        SUM(user_volume) AS top_5_volume
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY merchant_id
),

merchant_total AS (
    SELECT
        merchant_id,
        SUM(amount) AS total_volume
    FROM transactions
    GROUP BY merchant_id
)

SELECT
    m.merchant_id,
    m.total_volume,
    t.top_5_volume,
    ROUND(
        100.0 * t.top_5_volume / m.total_volume,
        2
    ) AS top_5_volume_percentage
FROM merchant_total m
JOIN top_5_volume t
    ON m.merchant_id = t.merchant_id
WHERE t.top_5_volume / m.total_volume > 0.60
ORDER BY top_5_volume_percentage DESC;

-- =========================================================
-- P9 · Just-Under-Threshold (Structuring)
-- Detects users with 10 or more transactions at exactly
-- ₹9,999.00, indicating possible transaction structuring.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS threshold_transactions
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_transactions DESC;

-- =========================================================
-- P10 · Dormant-Then-Active
-- Detects users with a 90+ day gap between consecutive
-- transactions followed by at least 15 transactions after reactivation.
-- =========================================================

WITH transaction_gaps AS (
    SELECT
        user_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
),

dormant_gaps AS (
    SELECT
        user_id,
        txn_time AS reactivation_time,
        previous_txn_time
    FROM transaction_gaps
    WHERE previous_txn_time IS NOT NULL
      AND txn_time >= previous_txn_time + INTERVAL 90 DAY
),

post_gap_activity AS (
    SELECT
        d.user_id,
        d.reactivation_time,
        COUNT(t.txn_id) AS post_gap_transactions
    FROM dormant_gaps d
    JOIN transactions t
        ON t.user_id = d.user_id
       AND t.txn_time >= d.reactivation_time
    GROUP BY
        d.user_id,
        d.reactivation_time
)

SELECT
    user_id,
    reactivation_time,
    post_gap_transactions
FROM post_gap_activity
WHERE post_gap_transactions >= 15
ORDER BY post_gap_transactions DESC;

-- =========================================================
-- P11 · Velocity Spike
-- Detects users whose peak monthly transaction count is
-- at least 5 times their average monthly transaction count,
-- with a peak of at least 20 transactions.
-- ========================================================= 

WITH monthly_counts AS (
    SELECT
        user_id,
        YEAR(txn_time) AS transaction_year,
        MONTH(txn_time) AS transaction_month,
        COUNT(*) AS monthly_transaction_count
    FROM transactions
    GROUP BY
        user_id,
        YEAR(txn_time),
        MONTH(txn_time)
),

user_monthly_stats AS (
    SELECT
        user_id,
        AVG(monthly_transaction_count) AS average_monthly_count,
        MAX(monthly_transaction_count) AS peak_monthly_count
    FROM (
        SELECT
            u.user_id,
            m.transaction_month,
            COALESCE(mc.monthly_transaction_count, 0) AS monthly_transaction_count
        FROM (
            SELECT DISTINCT user_id
            FROM transactions
        ) u
        CROSS JOIN (
            SELECT 1 AS transaction_month
            UNION ALL SELECT 2
            UNION ALL SELECT 3
            UNION ALL SELECT 4
            UNION ALL SELECT 5
            UNION ALL SELECT 6
        ) m
        LEFT JOIN monthly_counts mc
            ON mc.user_id = u.user_id
           AND mc.transaction_month = m.transaction_month
    ) monthly_data
    GROUP BY user_id
)

SELECT
    user_id,
    ROUND(average_monthly_count, 2) AS average_monthly_count,
    peak_monthly_count,
    ROUND(
        peak_monthly_count / NULLIF(average_monthly_count, 0),
        2
    ) AS peak_to_average_ratio
FROM user_monthly_stats
WHERE peak_monthly_count >= 20
  AND peak_monthly_count / NULLIF(average_monthly_count, 0) >= 5
ORDER BY peak_to_average_ratio DESC;

-- =========================================================
-- P12 · Geographic Impossibility
-- Detects users with consecutive transactions in different
-- cities within 60 minutes of each other.
-- ========================================================= 

WITH transaction_history AS (
    SELECT
        user_id,
        txn_time,
        city,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time, txn_id
        ) AS previous_city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time, txn_id
        ) AS previous_txn_time
    FROM transactions
)

SELECT DISTINCT
    user_id
FROM transaction_history
WHERE previous_city IS NOT NULL
  AND previous_city <> city
  AND TIMESTAMPDIFF(
        MINUTE,
        previous_txn_time,
        txn_time
      ) BETWEEN 0 AND 60
ORDER BY user_id;