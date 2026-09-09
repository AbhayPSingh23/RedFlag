# SQL Fraud Detection Engine

A rule-based fraud detection engine built entirely with SQL, designed to identify suspicious transaction behaviour across a simulated Indian payment-aggregator dataset containing 200,000 transactions.

The project implements 12 fraud detection patterns, progressing from basic aggregation and filtering to advanced SQL concepts such as CTEs, window functions, `LAG()`, `ROW_NUMBER()`, correlated subqueries, and time-based analysis.

---

## Project Overview

Financial fraud rarely follows a single pattern. Fraudsters may exploit transaction velocity, test stolen cards, structure payments below regulatory thresholds, abuse refunds, operate mule accounts, or take over dormant accounts.

This project demonstrates how these behaviours can be detected using SQL alone, without machine-learning models.

### Objective

> Identify users and merchants whose transaction behaviour matches predefined fraud signatures.

The engine analyses transaction history and flags accounts or merchants that satisfy specific behavioural rules.

---

## Dataset

The project uses a simulated Indian payment-aggregator transaction dataset.

| Attribute | Details |
|---|---|
| Total Transactions | 200,000 |
| Time Period | January – June 2024 |
| Users | ~14,500 |
| Suspect Users | 255+ |
| Merchants | 800 |
| Cities | 20 Indian cities |
| Transaction Status | `SUCCESS`, `FAILED` |
| Payment Modes | `UPI`, `CARD`, `NETBANKING`, `WALLET` |
| Transaction Types | `DEBIT`, `CREDIT`, `REFUND` |

The dataset contains both legitimate behaviour and seeded fraudulent behaviour to evaluate the effectiveness of each detection pattern.

---

# Fraud Detection Patterns

## P1 — Velocity Fraud

Signature:  
A user performs 30 or more transactions on a single calendar day.

SQL Concepts:
- `GROUP BY`
- `DATE()`
- `HAVING`
- `COUNT()`

Expected: ~45–55 suspicious user-days.

---

## P2 — Round-Amount Clustering

Signature:  
A user performs 15 or more transactions using exact round amounts:

`₹100, ₹200, ₹500, ₹1,000, ₹2,000, ₹5,000, ₹10,000`

SQL Concepts:
- `WHERE`
- `IN`
- `GROUP BY`
- `HAVING`

Expected: Exactly 25 suspects.

---

## P3 — Card Testing

Signature:  
A user performs 30 or more transactions below ₹10 on a single day.

This represents potential testing of stolen card credentials using very small transactions before larger fraudulent activity.

SQL Concepts:
- `WHERE`
- `GROUP BY`
- `DATE()`
- `HAVING`

Expected: Exactly 20 suspects.

---

## P4 — Failed-Then-Succeeded

Signature:  
A user has 20 or more failed transactions.

A high concentration of failures can indicate automated card-testing or credential-testing behaviour.

SQL Concepts:
- `WHERE`
- `GROUP BY`
- `HAVING`
- `COUNT()`

Expected: Exactly 25 suspects.

---

## P5 — Odd-Hour Concentration

Signature:  
A user has at least 30 transactions, with 80% or more occurring between 2 AM and 4 AM.

SQL Concepts:
- `HOUR()`
- `CASE WHEN`
- Aggregate functions
- `HAVING`

Expected: Exactly 20 suspects.

---

## P6 — Mule Accounts

Signature:  
A user has 8 or more credit transactions.

The advanced behavioural signature identifies a credit followed by a debit of at least **70% of the credit amount within 30 minutes**.

SQL Concepts:
- Subqueries
- `EXISTS`
- `GROUP BY`
- Time intervals

Expected: Exactly 30 suspects for the simplified signature.

---

## P7 — Refund Abuse

Signature:  
A user has:

- At least 20 total transactions
- More than 40% of transactions are refunds

SQL Concepts:
- `CASE WHEN`
- Aggregate functions
- Ratio calculations
- `HAVING`

Expected: 24–25 suspects.

---

## P8 — Merchant Collusion

Signature:  
The top 5 users by transaction volume account for more than 60% of a merchant's total transaction value.

This identifies merchants whose transaction volume is unusually concentrated among a small number of users.

SQL Concepts:
- CTEs
- `ROW_NUMBER()`
- `PARTITION BY`
- `SUM()`
- Multi-step aggregation
- Joins

Expected: Exactly 15 merchants.

Seeded colluding merchants:

`Merchant IDs 1–15`

---

## P9 — Just-Under-Threshold / Structuring

Signature:  
A user performs 10 or more transactions at exactly ₹9,999.00.

This represents potential structuring behaviour designed to keep transactions just below a specified ₹10,000 threshold.

SQL Concepts:
- Exact `WHERE` matching
- `GROUP BY`
- `HAVING`
- `COUNT()`

Expected: Exactly 20 suspects.

---

## P10 — Dormant-Then-Active

Signature:  
A user has a 90+ day gap between consecutive transactions, followed by 15 or more transactions after the gap.

This pattern can indicate account takeover followed by rapid monetisation.

SQL Concepts:
- `LAG()`
- Window functions
- CTEs
- Date/time arithmetic
- Joins

Expected: 25–27 suspects.

---

## P11 — Velocity Spike

Signature:  

A user's:

> Peak monthly transaction count ≥ 5 × average monthly transaction count and the peak must contain at least 20 transactions.

This detects sudden behavioural changes relative to a user's historical activity.

SQL Concepts:
- CTEs
- Monthly aggregation
- `AVG()`
- `MAX()`
- Window/analytical techniques

Expected: 35–45 suspects.

The expected result includes:

- 20 seeded users
- Approximately 15–25 legitimate/noise users

This intentionally demonstrates that rule-based anomaly detection can produce both seeded detections and naturally occurring false positives.

---

## P12 — Geographic Impossibility

Signature:  
A user performs consecutive transactions in different cities within 60 minutes.

For example:


Mumbai
   ↓ 18 minutes
Delhi


Such movement is physically implausible and can indicate account takeover or stolen payment credentials.

SQL Concepts:
- `LAG()`
- Window functions
- `TIMESTAMPDIFF()`
- CTEs

Expected: Exactly 15 suspects.

---

# SQL Techniques Demonstrated

This project covers a broad range of practical SQL concepts:

```text
SELECT
WHERE
IN
CASE WHEN
GROUP BY
HAVING
COUNT()
SUM()
AVG()
MAX()
ROUND()
DATE()
HOUR()
TIMESTAMPDIFF()
CTEs
EXISTS
Correlated Subqueries
JOIN
Window Functions
LAG()
ROW_NUMBER()
PARTITION BY
```

The patterns intentionally increase in complexity from simple aggregation to multi-stage analytical queries.

---

# Project Structure

```text
SQL-Fraud-Detection/
│
├── README.md
│
├── The Query Section
│
├── Snapshot of Output
│
└── The Dataset
```

---

# Detection Methodology

Each pattern follows the same general analytical workflow:

```text
Raw Transactions
       │
       ▼
Behavioural Aggregation
       │
       ▼
Fraud Signature
       │
       ▼
Threshold / Ratio Check
       │
       ▼
Suspicious Users / Merchants
```

For example, P11 follows:

```text
Transactions
      ↓
Monthly transaction counts
      ↓
Average + Peak per user
      ↓
Peak / Average
      ↓
Ratio ≥ 5 AND Peak ≥ 20
      ↓
Velocity Spike Suspects
```

---

# Expected Detection Summary

| Pattern | Detection Signature | Expected Result |
|---|---|---:|
| P1 | 30+ transactions/day | ~45–55 |
| P2 | 15+ exact round-amount transactions | 25 |
| P3 | 30+ transactions under ₹10/day | 20 |
| P4 | 20+ failed transactions | 25 |
| P5 | 80%+ transactions at 2–4 AM | 20 |
| P6 | 8+ credit transactions | 30 |
| P7 | 20+ transactions & >40% refunds | 24–25 |
| P8 | Top 5 users >60% merchant volume | 15 |
| P9 | 10+ transactions at ₹9,999 | 20 |
| P10 | 90+ day gap + 15+ post-gap transactions | 25–27 |
| P11 | Peak ≥5× average & peak ≥20 | 35–45 |
| P12 | Different cities within 60 minutes | 15 |

---

# Key Learning Outcomes

Through this project, I worked with SQL as an analytical and fraud-detection tool, rather than using it only for basic data retrieval.

### Core skills developed

- Translating business fraud scenarios into SQL signatures
- Designing aggregation-based detection rules
- Working with behavioural ratios and thresholds
- Using CTEs for multi-step analytical pipelines
- Applying window functions to transaction histories
- Detecting temporal anomalies
- Analysing transaction concentration
- Comparing current behaviour against historical baselines
- Identifying potential false positives
- Validating query results against known seeded fraud cases

---

# Why SQL for Fraud Detection?

Machine learning is not always necessary for the first layer of fraud detection.

SQL can provide:

- Fast rule-based screening
- Explainable detection logic
- Easy integration with transactional databases
- Transparent thresholds
- Auditable detection rules
- Real-time or near-real-time analytical possibilities

A production fraud platform could use these SQL rules as an initial detection layer before applying more advanced statistical or machine-learning models.

---

# Limitations

This project is intentionally rule-based and uses a simulated dataset.

Therefore:

- Detection depends on predefined thresholds.
- Legitimate unusual behaviour can generate false positives.
- Sophisticated fraud that does not match these signatures may remain undetected.
- The dataset does not represent real banking/customer data.
- Production systems would require additional signals such as device fingerprints, IP intelligence, merchant risk scores, geolocation accuracy, account age, and historical behavioural profiles.

---

# Future Improvements

Potential extensions include:

- Risk scoring across multiple patterns
- Combining multiple fraud signals into a single user risk score
- Creating a fraud-alert table
- Building daily automated monitoring
- Adding merchant risk scoring
- Adding device/IP-based analysis
- Creating dashboards using Power BI or Tableau
- Comparing SQL rules with machine-learning models
- Measuring precision, recall, and false-positive rates
- Creating a production-style fraud monitoring pipeline

---

# Tech Stack

**Database / Query Language**
- SQL
- MySQL-compatible syntax

**Core SQL Features**
- Aggregations
- CTEs
- Window Functions
- Subqueries
- Joins
- Conditional Expressions
- Date/Time Functions

**Dataset**
- RedFlag_transactions

---

# Project Goal

The primary goal of this project is to demonstrate that **SQL can be used to build a practical, explainable fraud-detection engine by converting real-world behavioural patterns into measurable transaction signatures.**

> **12 patterns. 200,000 transactions. One SQL-based fraud detection engine.**

---

## Author

**Abhay Pratap Singh**

B.Tech — Artificial Intelligence & Data Science

GitHub: `AbhayPSingh23`

---

## Disclaimer

This project is created for **educational and portfolio purposes** using simulated transaction data. It does not represent real customer, banking, or payment-processor data.
