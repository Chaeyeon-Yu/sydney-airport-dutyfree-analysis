# Sydney Airport Duty-Free Shop Analysis — Synthetic Dataset

> ⚠️ **Disclaimer**  
> This project is based on personal retail work experience and uses a **fully synthetic dataset built around a hypothetical scenario**.  
> All data is artificially generated — no real customer, transaction, or operational data has been used or reproduced.  
> *"This dataset was designed from first-hand retail experience to reflect real-world airport duty-free dynamics as accurately as possible."*

---

## 📌 Project Scope & Methodology

- **Data Synthesis**: Generated realistic retail datasets using Python, simulating complex patterns like flight schedules and seasonal demand.
- **Database Management**: Leveraged DBeaver for initial SQL exploration and schema validation.
- **Data Engineering**: Built a robust Medallion Architecture in Snowflake, transforming raw data into high-quality, reporting-ready Gold layers through rigorous cleansing and standardisation.
- **Advanced Insights**: Conducted deep-dive exploratory data analysis (EDA) using Jupyter Notebooks to uncover actionable business intelligence.

| Item | Detail |
|---|---|
| **Setting** | Sydney International Airport (T1) Duty-Free Retail Operations |
| **Period** | 1 January 2024 – 31 December 2024 (52 weeks) |
| **Tables** | 5 Relational Tables (Normalised Schema) |
| **Total records** | 22,038 Transactions |
| **Output** | 5 CSV files + 1 SQLite database |
| **Reproducibility** | `random.seed(42)` fixed |

---

## 🗂️ Data Architecture & Schema

### [Entity Relationship Diagram]

```
      Dimension Tables                                   Dimension Table
   (Passenger & Context)          Fact Table            (Product Details)
   
   customer_details ───┐                               
   flight_schedules ───┼──▶     [transactions]     ◀─── product_master
   holiday_events   ───┘     
```

| Table | Rows | Primary Key | Foreign Keys | Description |
|---|---|---|---|---|
| customer_details | 8,000 | customer_id | | Passenger demographics |
| product_master | 108 | product_sku | | 108 SKUs across 9 categories |
| flight_schedules | 5,907 | flight_id | | 52-week departure schedule |
| holiday_events | 6 | event_id | | Jan–Dec holiday event calendar |
| transactions | 22,038 | tx_id | customer_id, product_sku, flight_id, event_id | Fact table linking all entities|

---

## 📐 Design Principles

### 1. customer_details (8,000 customers)

| Column | Description | 
|---|---|
| `customer_id` | PK: Unique identifier (C-0001 to C-8000) |
| `nationality` | Passenger's country of origin |
| `age_group` | Passenger's age group ("Under 20", "20s", "30s", "40s", "50s", "60+")|

---

### 2. product_master (108 SKUs)

All categories use **variant-based SKU generation** — every SKU row corresponds to a specific variant tuple `(Item, Variant, Price)`. No random duplicate SKUs.

| Column | Description |
|---|---|
| `product_sku` | PK: Unique identifier (SKU-001 to SKU-108) |
| `category` | Product category (9 distinct groups) |
| `item` | The base product name |
| `variant` | Specific attribute (e.g., "500g", "Gold", "Single Malt") |
| `selling_price` | Retail price in AUD | 
| `cost_price` | Wholesale cost based on category-specific margin ratios |

---

### 3. flight_schedules (5,907 flights)

| Column | Description |
|---|---|
| `flight_id` | PK: Unique identifier (F-0001 to F-5907) |
| `flight_no` | Flight identifier (e.g., QF001, KE402) |
| `airline` | Operating carrier (Full service and budget carriers) |
| `destination` | Departure destination (Used for DEST_MAP preference logic) |
| `departure_time` | Scheduled departure (including ±5 min random variance) | 
| `flight_status` | Real-time status (On Time, Delayed, Cancelled) |

---

### 4. holiday_events (6 events)

| Column | Description |
|---|---|
| `event_id` | PK: Unique identifier (E-01 to E-06) |
| `event_name` | Holiday name |
| `start_date` | Event start date (YYYY-MM-DD)|
| `end_date` | Event end date (YYYY-MM-DD) |
---

### 5. transactions (22,038 transactions)

This is the Fact Table containing 22,038 records.

| Column | Description |
|---|---|
| `tx_id` | Unique transaction identifier (e.g., TX-000001) |
| `line_no` | Item line number within the same transaction |
| `tx_time` | Timestamp of the purchase (YYYY-MM-DD HH:MM:SS) |
| `customer_id` | FK: Links to `customer_details` |
| `flight_id` | FK: Links to `flight_schedules` |
| `event_id` | FK: Links to `holiday_events` |
| `product_sku` | FK: Links to `product_master` |
| `qty` | Number of units purchased |
| `unit_price` | Price per single unit |
| `net_amount` | Final Payment (qty * unit_price - disc_amount) |
| `disc_amount` | Discount amount applied |
| `promo_id` | Identifier for the applied promotion |
| `payment_method` | Method of payment (e.g., Credit Card, Cash, WeChat Pay) |

---

## 🚀 How to Run

### 1. Environment Setup
Install the necessary libraries to run the data generation script:
```bash
# Clone the repository
git clone [https://github.com/Chaeyeon-Yu/sydney-airport-dutyfree-analysis.git](https://github.com/Chaeyeon-Yu/sydney-airport-dutyfree-analysis.git)
cd sydney-airport-dutyfree-analysis

# Install dependencies
pip install pandas numpy faker
```

### 2. Execute Data Generation
Run the script to generate 1 year (2024) of Sydney Airport T1 Duty-Free transaction data. The script uses random.seed(42) for reproducibility and creates 5 normalised relational tables.
``` bash
python generate_duty_free_data.py
```


### 3. Output
Upon execution, the following files will be generated in the duty_free_data/ directory, along with a SQLite database for immediate SQL analysis:
``` bash
.
├── duty_free.db               # SQLite database for local SQL querying/practice
└── duty_free_data/            # Normalised CSV datasets for Snowflake ingestion
    ├── customer_details.csv   (8,000 rows) - Passenger demographics & nationality
    ├── product_master.csv     (108 rows)   - Category hierarchy & unit pricing
    ├── flight_schedules.csv   (5,907 rows) - 52-week schedule with unique Flight_ID
    ├── holiday_events.csv     (6 rows)     - Major holiday calendar (YYYY-MM-DD)
    └── transactions.csv       (22,038 rows)- Sales Fact table (Final Payment)
```

---

## 🤖 AI Assistance

This project was developed with the support of **Claude (Anthropic)** and **Gemini (Google)** as coding and architectural assistants.

While AI accelerated the technical implementation, all domain-specific logic, strategic design decisions, and final code validation were conducted by the author to ensure data integrity and business relevance.

**AI assistance was used for:**
- - **Python Code Generation:** Iterative logic refinement for synthetic data scripts.
- **Data Architecture Review:** Optimising the **Star Schema** and implementing **Composite-to-Surrogate Key mapping** (e.g., `flight_id`) for Snowflake compatibility.
- **Silver Layer Optimisation (Cortex):** Leveraging **Snowflake Cortex** to clean and conform raw data. AI was used to suggest logic for filtering outliers and standardising non-structured elements (for the future dirty data) into a conformed schema suitable for analytical use.
- **Gold Layer View Creation:** Assistance in architecting curated Gold Layer views, ensuring the final data models are optimised for Tableau visualisation and high-level business reporting.
- **Normalisation Strategy:** Designing the transition from raw transactional data to **Normalised CSV datasets** suitable for Medallion Architecture (Bronze/Silver/Gold).
- README documentation and technical communication drafting.

**Verified and Defined entirely by the author based on first-hand industry expertise:**
- **Architecture Governance:** Full oversight and final validation of the Bronze, Silver, and Gold layer structures.
- **Final Logic Validation:** Manual review of all generated SQL, Python scripts, and Cortex functions to ensure professional data integrity standards.
- **Product & Operational Strategy:** Tiered pricing, nationality-based **PREF_MAP**, and seasonal holiday "boost" logic, etc.
- **Retail Insights:** Modeled item-level promotions and payment method weights based on real-world POS observations at Sydney Airport.

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Python (pandas, numpy, faker) | Synthetic data generation |
| SQLite | Local RDBMS environment for immediate SQL practice and testing |
| SQL (DBeaver) | Analytics queries |
| Snowflake | Cloud Data Warehousing and Medallion Architecture (Bronze/Silver/Gold) |
| Tableau | Business Intelligence (BI) dashboarding and interactive visualisation |
| GitHub | Version control, documentation (README), and portfolio hosting |

