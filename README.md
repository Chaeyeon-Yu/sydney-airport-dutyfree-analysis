# Sydney Airport Duty-Free Shop Analysis — Synthetic Dataset

> ⚠️ **Disclaimer**  
> This project is based on personal retail work experience and uses a **fully synthetic dataset built around a hypothetical scenario**.  
> All data is artificially generated — no real customer, transaction, or operational data has been used or reproduced.  
> *"This dataset was designed from first-hand retail experience to reflect real-world airport duty-free dynamics as accurately as possible."*

---

## 📌 Project Overview

A portfolio dataset simulating the sales operations of a **duty-free gift shop at Sydney International Airport Terminal 1 (T1)**.  
Designed to practise SQL analytics, data modelling, and Tableau visualisation — covering realistic retail patterns such as flight-linked transactions, nationality-based purchasing behaviour, and holiday-driven demand shifts.

| Item | Detail |
|---|---|
| **Setting** | Sydney Int'l Airport (T1) Duty-Free Gift Shop — Retail Transaction Data |
| **Period** | 1 January 2024 – 31 December 2024 (52 weeks) |
| **Tables** | 5 |
| **Total records** | 22,038 Transactions |
| **Output** | 5 CSV files + 1 SQLite database |
| **Reproducibility** | `random.seed(42)` fixed |

---

## 💡 Built from Real-World Experience

This dataset was not generated from a template — every design decision reflects patterns observed from **direct retail experience working at a duty-free shop at Sydney Airport T1**.  
The goal was to make the synthetic data as realistic as possible, so that any analysis drawn from it mirrors the kind of insights a real retail analyst would surface.

| Area | What was applied | Source of knowledge |
|---|---|---|
| **Product categories** | 9 categories matching actual shop inventory (Honey, Indigenous, Apparel, Tea, etc.) | Worked categories on the shop floor |
| **Item & variant selection** | AU/NZ-specific items with realistic variants (A/B brand, 100ml vs 6-pack, UMF grade, Tim Tam flavours, Ugg style, etc.) | Direct product knowledge from daily sales |
| **Cosmetics focus** | Lanolin Cream, Sheep Placenta Cream, Emu Oil Cream, Paw Paw Ointment, Wild Fern Skincare — popular AU/NZ souvenir beauty items | Observed as top-selling categories |
| **Honey SKU structure** | Each brand-grade combination is a separate SKU (Comvita UMF 5+/10+/15+/20+, Manuka Health MGO 263+/400+, Beepower MGO 115+/263+) with fixed grade-based pricing | Real product knowledge + iHerb/Chemist Warehouse price research |
| **Honey import restrictions** | Honey weight reduced for NZ (MPI biosecurity) | Awareness of customs rules from working in duty-free |
| **Nationality weights** | Reflects duty-free purchase likelihood, not raw airport traffic — AU weight (12%) is lower than traffic share (22%) as most AU residents buy locally; accounts for naturalised citizens travelling to hometown | Cross-referenced with official airport data + floor observation |
| **AU purchasing behaviour** | AU: Confectionery · Liquor (duty-free benefit) · Cosmetics (pharmacy substitute) · Souvenir (for friends/family) — Honey/Indigenous not a typical AU duty-free purchase | Observed customer behaviour on the floor |
| **NZ passenger note** | NZ weight kept below raw volume — MPI biosecurity restricts AU honey imports; NZ residents can buy same products locally | Operational knowledge of customs rules |
| **Nationality purchasing behaviour** | CN/KR → Honey & Cosmetics; JP → Confectionery & Souvenir; US/GB/CA → Apparel & Indigenous (not liquor-dominant) | Observed customer behaviour on the floor |
| **CN purchasing behaviour** | CN: Honey (UMF 10+/MGO 400+ preferred) · Cosmetics · Souvenir · Liquor ($85+ preferred) — gift-buying culture with bulk quantities | Observed customer behaviour on the floor |
| **Remainder category distribution** | PREF_MAP weights intentionally sum to <100 — remainder distributed evenly so every category has some background purchase probability | Reflects reality that customers occasionally buy outside their main preference |
| **Flight schedule patterns** | Fixed flight numbers (CX101, KE601), fixed weekday patterns, realistic departure windows per route | Familiar with T1 departure board and peak hours |
| **Transaction timing** | Purchases generated 30–180 min before departure — reflects actual pre-flight shopping window | Observed traffic spikes before gate calls |
| **Holiday event design** | No formal price promotions — holiday periods shift purchase patterns and visitor mix naturally (Lunar New Year → CN/KR surge + Honey, Souvenir, Confectionery boost, Easter → AU/GB surge + Confectionery boost) | Directly observed on shop floor during peak periods |
| **Item-level promotions** | Paw Paw Buy 5 Get 6th Free (G Paw Paw free - cheaper one free) · Comvita UMF 5+ Buy 3 Get 4th Free · Tim Tam any 4 for $24 | Modelled on actual in-store deals |
| **Payment methods** | Credit/Debit Card · Cash · AliPay · WeChat Pay · Digital Wallet — CN uses AliPay/WeChat; KR uses AliPay ~0.1% only; JP cash still high | Observed at POS daily |


---

## 🗂️ Table Structure

```
customer_details ──┐
                    ├──▶ transactions ◀──── product_master
flight_schedules ───┘         │                     
                        holiday_events       
```

| Table | Rows | Primary Key | Description |
|---|---|---|---|
| customer_details | 8,000 | customer_id | Passenger demographics |
| product_master | 108 | product_sku | 108 SKUs across 9 categories |
| flight_schedules | 5,907 | flight_no + departure_time | 52-week departure schedule |
| holiday_events | 6 | event_id | Jan–Dec holiday event calendar |
| transactions | 22,038 | tx_id | All transactions details|
---

## 📐 Design Principles

### 1. customer_details

- **12 nationalities** weighted by duty-free purchase likelihood (not raw airport traffic)
  - CN 20% · AU 12% · US 10% · GB 9% · KR 9% · IN 8% · JP 7% · NZ 8% · others
  - AU weight (12%) is intentionally lower than traffic share (22%):
    - Most AU residents buy the same products locally — low duty-free conversion
    - Accounts for naturalised AU citizens travelling to their hometown (higher purchase rate)
  - NZ weight kept low — MPI biosecurity restricts AU honey imports; NZ residents buy locally
- **8,000 customers** → average 1.25 transactions per customer
- `Preferred_Category` assigned using nationality-based weighted probability (see `PREF_MAP`)

| Column | Description | 
|---|---|
| `customer_id` | Unique identifier (C-0001 to C-8000) |
| `nationality` | Passenger's country of origin |
| `age_group` | Passenger's age group ("Under 20", "20s", "30s", "40s", "50s", "60+")|


---

### 2. product_master (108 SKUs)

All categories use **variant-based SKU generation** — every SKU row corresponds to a specific variant tuple `(Item, Variant, Price)`. No random duplicate SKUs.

| Category | Key Items & Variants | Price Range (AUD) | Cost Ratio | SKUs |
|---|---|---|---|---|
| Cosmetics | Lanolin Cream (A/B brand, single/6-pack), Sheep Placenta Cream, Emu Oil Cream, Paw Paw Ointment (Lucas/Gronk), Wild Fern Skincare (Lip Balm/Hand Cream/Face Cream/Face Mask/Gift Set) | $8–42 | 45% | 16 |
| Liquor | Penfolds Wine (Max's/Bin 28/Bin 407/Bin 389/Grange), Johnnie Walker (Red/Black/Gold), Hennessy (VS/VSOP/XO), Absolut Vodka, Tanqueray Gin | $30–999 | 65% | 17 |
| Jewellery | Opal (Earrings/Necklace/Pendant/Premium), Paua Shell (Earrings/Pendant/Bracelet/Ring), Jade (Pendant S/L, Bracelet/Ring) | $38–520 | 60% | 12 |
| Souvenir | SYD Keychain (Metal/Acrylic), SYD Mug (S/L), AUS Magnet (Single/3-Pack), Kangaroo Plush (S/L), Koala Plush (S/L), AUS Tea Towel | $9–45 | 45% | 11 |
| Confectionery | Cadbury (3 SKUs), Tim Tam (7 flavours), Patons (3 SKUs), Lindt (3 SKUs), Macadamia Nuts (3 SKUs), Kangaroo Jerky (50g/100g) | $7–36 | 55% | 21 |
| Apparel | AUS T-Shirt (Kids/Adult), AUS Hoodie (Standard/Premium), Ugg Boots (Short/Tall), Ugg Slipper, AUS Cap (Standard/Premium) | $22–180 | 50% | 9 |
| Honey | Comvita UMF 5+/10+/15+/20+, Manuka Health MGO 263+/400+, Beepower MGO 115+/263+ | $35–170 | 60% | 8 |
| Indigenous | Aboriginal Art Print (A4/A3/Framed), Boomerang (S/L), Hand Cream (50ml/100ml), Lip Balm (Single/3-Pack), Kitchenware (Coaster/Cutting Board) | $9–110 | 50% | 11 |
| Tea | T2 Tea (Small Tin/Large Tin/Gift Set) | $22–62 | 50% | 3 |

- The product_master table serves as the primary dimension table for all transaction analysis.

| Column | Description |
|---|---|
| product_sku | Unique identifier (SKU-001 to SKU-108) |
| category | Product category (9 distinct groups) |
| item | The base product name |
| variant | Specific attribute (e.g., "500g", "Gold", "Single Malt") |
| selling_price | Retail price in AUD | 
| cost_price | Wholesale cost based on category-specific margin ratios |

---

### 3. flight_schedules

- **Fixed real-world flight numbers** (e.g. CX101, KE601) — same flight repeats on the same weekday every week
- **Fixed operating weekdays** per route (0 = Mon … 6 = Sun)
- **Operational Status & Sales Correlation**:
  - On Time (85%): Standard departure flow.
  - Delayed (13%): Simulates increased Dwell Time in the departure lounge, which statistically correlates with a potential boost in spontaneous duty-free sales (e.g., Confectionery, Tea).
  - Cancelled (2%): Transactions are filtered out for these flights to maintain data integrity.
- **±5 min random delay** applied to each departure for realism

| Route group | Departure window | Example flights |
|---|---|---|
| Northeast Asia (HK · Shanghai · Beijing · Seoul · Tokyo) | 09:00–17:00 | CX101, KE601, JL771, MU502 |
| Southeast Asia (Singapore · Manila · KL · Bangkok · Bali) | 07:00–14:00 | SQ211, GA715, TG476, PR211 |
| Singapore long-haul | 16:30 | QF1 (SYD→SIN, connects to London as QF2) |
| Middle East | 20:45–21:10 | EK413 (Dubai) · QR007 (Doha) |
| Los Angeles | 11:55–21:00 | QF7, UA839 |

- The flight_schedules table provides the necessary context to analyse sales trends by airline, destination, and time of day.

| Column | Description |
|---|---|
| flight_no | Unique flight identifier (e.g., QF001, KE402) |
| airline | Operating carrier (Full service and budget carriers) |
| destination | Departure destination (Used for DEST_MAP preference logic) |
| departure_time | Scheduled departure (including ±5 min random variance) | 
| flight_status | Real-time status (On Time, Delayed, Cancelled) |

---

### 4. holiday_events

- **6 events, January–December** — only holidays that meaningfully affect international travel volumes to simulate how international travel and purchasing behaviors shift during major holidays at Sydney T1.
- **No price discounts** — the shop does not run formal promotions; purchase patterns shift naturally

| Event ID| Event | Period | Category Boost | Nationality Boost |
|---|---|---|---|---|
| E-01 | New Year Kickoff | Jan 1 – 7 | Confectionery | - |
| E-02 | Lunar New Year | Feb 8 – 18 | Honey, Souvenir, Confectionery | CN 38% · KR 14% |
| E-03 | Easter Long Weekend | Mar 29 – Apr 1 | Confectionery | AU 35% · GB 14% |
| E-04 | Chuseok | Sep 13 – 19 | Souvenir | KR 18% |
| E-05 | Mid-Autumn Festival | Sep 14 – 18 | Honey | CN 35% |
| E-06 | Christmas & New Year | Dec 22 – 31 | Souvenir | - |

- The function **generate_holiday_events()** produces a schema focused on public event information for analysis:

| Column | Description |
|---|---|
| `event_id` | Unique identifier (E-01 to E-06) |
| `event_name` | Holiday name |
| `start_date` | Event start date (YYYY-MM-DD)|
| `end_date` | Event end date (YYYY-MM-DD) |


---

### 5. transactions

This is the Fact Table containing 22,038 records.

#### Category selection logic

```
70%  →  weighted by customer nationality  (PREF_MAP)
30%  →  weighted by flight destination group
```

PREF_MAP weights intentionally sum to less than 100 per nationality — the remainder is distributed evenly across unlisted categories, giving every category a small background purchase probability.

| Nationality | Strong preferences | Note |
|---|---|---|
| AU | Confectionery · Liquor · Cosmetics · Souvenir | Lower conversion; local residents buy staples domestically. |
| CN | Honey · Cosmetics · Souvenir · Liquor | Gift-buying culture |
| KR | Cosmetics · Honey · Confectionery | Occasional wine buyer |
| US / GB / CA | Apparel · Indigenous · Souvenir | Higher interest in authentic Australian crafts/merchandise. |
| JP / NZ | Confectionery, Souvenir, Tea | High volume from School Trip |
| NZ | Souvenir · Confectionery · Tea | Honey very low — MPI biosecurity |

#### Item-level promotions (year-round)

| Promo_ID | Promotion | Type |
|---|---|---|
| IP-01 | Paw Paw Ointment — Buy 5 Get 6th Free (G Paw Paw free) | MIX_BUY_X_GET_Y |
| IP-02 | Comvita UMF 5+ — Buy 3 Get 4th Free | BUY_X_GET_Y_ITEM |
| IP-03 | Tim Tam — Any 4 Flavours for $24 | BUNDLE_FIXED_ITEM |

#### Payment method by nationality

| Nationality | Dominant method | Note |
|---|---|---|
| AU / NZ / CA / GB / US / SG | Credit/Debit Card · Digital Wallet | - |
| CN | Digital Wallet · AliPay | Cash also common |
| KR | Credit/Debit Card | AliPay ~0.1% (1 in 1,000) |
| JP | Digital Wallet · Cash | Cash culture still strong |
| IN / PH / TH | Digital Wallet · Cash · Credit/Debit Card | Higher cash usage |

---

## 🚀 How to Run

```bash
# 1. Install dependencies
pip install pandas numpy faker

# 2. Generate all datasets
python generate_duty_free_data.py

# 3. Output
duty_free_data/
├── customer_details.csv     (8,000 rows)
├── product_master.csv       (108 rows)
├── flight_schedules.csv     (5,907 rows)
├── holiday_events.csv       (6 rows)
└── transaction.csv          (22,038 rows)

duty_free.db                  ← SQLite for immediate SQL practice
```

---

## 🤖 AI Assistance

This project was developed with the support of **Claude (Anthropic)** as a coding and ideation assistant.

All domain knowledge, design decisions, and data logic reflect the author's own retail experience — AI was used to accelerate implementation, not to replace subject-matter expertise.

**AI assistance was used for:**
- Python code generation and iterative refinement
- Dataset schema review and edge case identification
- README drafting and documentation

**Defined entirely by the author based on first-hand work experience:**
- Product categories, brands, item variants, and pricing
- Nationality-based purchasing behaviour (PREF_MAP)
- Flight schedule patterns and peak hour logic
- Holiday event design and nationality boost values
- Item-level promotion types modelled on real in-store deals
- Payment method weights by nationality (observed at POS daily)
- CN high-value purchasing pattern (gift culture, premium grade preference)

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Python (pandas, numpy, faker) | Synthetic data generation |
| SQLite | Local SQL practice environment |
| SQL (DBeaver) | Analytics queries |
| Tableau | Dashboard visualisation |
| GitHub | Portfolio hosting |

