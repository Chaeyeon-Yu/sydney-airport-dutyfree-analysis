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
| **Setting** | Sydney International Airport — Terminal 1 duty-free gift shop |
| **Period** | 1 January 2024 – 30 June 2024 (26 weeks) |
| **Tables** | 6 |
| **Total records** | ~20,000+ rows |
| **Output** | 6 CSV files + 1 SQLite database |
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
| **Holiday event design** | No formal price promotions — holiday periods shift purchase patterns and visitor mix naturally (Lunar New Year → CN/KR surge + Honey boost, Easter → AU/GB surge + Confectionery boost) | Directly observed on shop floor during peak periods |
| **Item-level promotions** | Paw Paw Buy 5 Get 6th Free (G Paw Paw free - cheaper one free) · Comvita UMF 5+ Buy 3 Get 4th Free · Tim Tam any 4 for $24 | Modelled on actual in-store deals |
| **Payment methods** | Credit/Debit Card · Cash · AliPay · WeChat Pay · Digital Wallet — CN uses AliPay/WeChat; KR uses AliPay ~0.1% only; JP cash still high | Observed at POS daily |


---

## 🗂️ Table Structure

```
Customer_Profiles ──┐
                    ├──▶ Sales_Transactions ◀──── Product_Inventory
Flight_Schedules ───┘            │                      │
                          Holiday_Events        Transaction_Items
```

| Table | Rows | Primary Key | Description |
|---|---|---|---|
| Customer_Profiles | 4,000 | Customer_ID | Passenger demographics & membership |
| Product_Inventory | 108 | Product_SKU | 108 SKUs across 9 categories |
| Flight_Schedules | 2,860 | Flight_No + Departure_Time | 26-week departure schedule |
| Holiday_Events | 3 | Event_ID | Jan–Apr holiday event calendar |
| Sales_Transactions | 5,000 | Trans_ID | Transaction header (customer, flight, payment) |
| Transaction_Items | 9,365 | Trans_ID + Line_No | Transaction lines (SKU, qty, price per item) |

---

## 📐 Design Principles

### 1. Customer_Profiles

- **12 nationalities** weighted by duty-free purchase likelihood (not raw airport traffic)
  - CN 20% · AU 12% · US 10% · GB 9% · KR 9% · IN 8% · JP 7% · NZ 8% · others
  - AU weight (12%) is intentionally lower than traffic share (22%):
    - Most AU residents buy the same products locally — low duty-free conversion
    - Accounts for naturalised AU citizens travelling to their hometown (higher purchase rate)
  - NZ weight kept low — MPI biosecurity restricts AU honey imports; NZ residents buy locally
- **4,000 customers** → average 1.25 transactions per customer
- **Membership tiers**: Non-Member 55% · Silver 25% · Gold 13% · Diamond 7%
- `Preferred_Category` assigned using nationality-based weighted probability (see `PREF_MAP`)

---

### 2. Product_Inventory (108 SKUs)

All categories use **variant-based SKU generation** — every SKU row corresponds to a specific variant tuple `(Item, Variant, Price)`. No random duplicate SKUs.

| Category | Key Items & Variants | Price Range (AUD) | Cost Ratio | SKUs |
|---|---|---|---|---|
| Cosmetics | Lanolin Cream (A/B brand, single/6-pack), Sheep Placenta Cream, Emu Oil Cream, Paw Paw Ointment (Lucas/Gronk), Wild Fern Skincare (Lip Balm/Hand Cream/Face Cream/Face Mask/Gift Set) | $8–42 | 40% | 16 |
| Liquor | Penfolds Wine (Max's/Bin 28/Bin 407/Bin 389/Grange), Johnnie Walker (Red/Black/Gold), Hennessy (VS/VSOP/XO), Absolut Vodka, Tanqueray Gin | $30–999 | 55% | 17 |
| Jewellery | Opal (Earrings/Necklace/Pendant/Premium), Paua Shell (Earrings/Pendant/Bracelet/Ring), Jade (Pendant S/L, Bracelet/Ring) | $38–520 | 40% | 12 |
| Souvenir | SYD Keychain (Metal/Acrylic), SYD Mug (S/L), AUS Magnet (Single/3-Pack), Kangaroo Plush (S/L), Koala Plush (S/L), AUS Tea Towel | $9–45 | 35% | 11 |
| Confectionery | Cadbury (3 SKUs), Tim Tam (7 flavours), Patons (3 SKUs), Lindt (3 SKUs), Macadamia Nuts (3 SKUs), Kangaroo Jerky (50g/100g) | $7–36 | 50% | 21 |
| Apparel | AUS T-Shirt (Kids/Adult), AUS Hoodie (Standard/Premium), Ugg Boots (Short/Tall), Ugg Slipper, AUS Cap (Standard/Premium) | $22–180 | 40% | 9 |
| Honey | Comvita UMF 5+/10+/15+/20+, Manuka Health MGO 263+/400+, Beepower MGO 115+/263+ | $35–170 | 45% | 8 |
| Indigenous | Aboriginal Art Print (A4/A3/Framed), Boomerang (S/L), Hand Cream (50ml/100ml), Lip Balm (Single/3-Pack), Kitchenware (Coaster/Cutting Board) | $9–110 | 30% | 11 |
| Tea | T2 Tea (Small Tin/Large Tin/Gift Set) | $22–62 | 40% | 3 |

- **Highest margin** categories: Indigenous (70%) · Souvenir (65%)
- **Lowest margin** categories: Liquor (45%) · Confectionery (50%)

---

### 3. Flight_Schedules

- **Fixed real-world flight numbers** (e.g. CX101, KE601) — same flight repeats on the same weekday every week
- **Fixed operating weekdays** per route (0 = Mon … 6 = Sun)

| Route group | Departure window | Example flights |
|---|---|---|
| Northeast Asia (HK · Shanghai · Beijing · Seoul · Tokyo) | 09:00–17:00 | CX101, KE601, JL771, MU502 |
| Southeast Asia (Singapore · Manila · KL · Bangkok · Bali) | 07:00–14:00 | SQ211, GA715, TG476, PR211 |
| Singapore long-haul | 16:30 | QF1 (SYD→SIN, connects to London as QF2) |
| Middle East | 20:45–21:10 | EK413 (Dubai) · QR007 (Doha) |
| Los Angeles | 11:55–21:00 | QF7, UA839 |

- **±5 min random delay** applied to each departure for realism
- Terminal gate fixed to **T1** (T1-01 through T1-55)

---

### 4. Holiday_Events

- **3 events, January–April** — only holidays that meaningfully affect international travel volumes
- **No price discounts** — the shop does not run formal promotions; purchase patterns shift naturally

| Event | Period | Category Boost | Nationality Boost |
|---|---|---|---|
| New Year Kickoff | Jan 1–7 | Souvenir +20 | — |
| Lunar New Year | Feb 8–18 | Honey +30 | CN 20%→38% · KR 9%→14% |
| Easter Long Weekend | Mar 29–Apr 1 | Confectionery +20 | AU 12%→35% · GB 9%→14% |

#### How holiday boosts work

```
Normal period:
  Category selected by PREF_MAP nationality weights (70%) + destination group (30%)

Holiday period — two effects:
  ① Category boost   : Boost_Weight added on top of PREF_MAP for target category
                       e.g. Lunar New Year: Honey weight for CN 30 → 60
  ② Nationality boost: visitor mix shifts toward boosted nationalities
                       e.g. Lunar New Year: CN share rises from 20% → 38%
```

| Column | Description |
|---|---|
| `Event_ID` | Unique identifier (E-01 … E-03) |
| `Event_Name` | Holiday name |
| `Start_Date / End_Date` | Holiday window |
| `Target_Category` | Category with elevated purchase probability |
| `Boost_Weight` | Extra weight added to target category |
| `Nat_Boost` | Nationalities with elevated visit share e.g. `"CN,KR"` (NULL if none) |
| `Nat_Weight` | Adjusted weights during window e.g. `"0.38,0.14"` (NULL if none) |

---

### 5. Sales_Transactions

#### Transaction time linkage

- Purchase time = **30–180 minutes before departure** of the linked flight
- Transactions outside operating hours (before 06:00 or after 23:00) are discarded and regenerated

#### Category selection logic

```
70%  →  weighted by customer nationality  (PREF_MAP)
30%  →  weighted by flight destination group
```

PREF_MAP weights intentionally sum to less than 100 per nationality — the remainder is distributed evenly across unlisted categories, giving every category a small background purchase probability.

| Nationality | Strong preferences | Note |
|---|---|---|
| AU | Confectionery · Liquor · Cosmetics · Souvenir | Lower conversion; interstate travellers buy Souvenir |
| CN | Honey · Cosmetics · Souvenir · Liquor | Gift-buying culture |
| KR | Cosmetics · Honey · Confectionery | Occasional wine buyer |
| US / GB / CA | Apparel · Indigenous · Souvenir | Liquor not a dominant duty-free driver |
| JP | Confectionery · Souvenir · Tea | Honey restricted by JP customs |
| NZ | Souvenir · Confectionery · Tea | Honey very low — MPI biosecurity |

| Destination group | Category bias |
|---|---|
| Northeast Asia | Cosmetics · Honey · Confectionery · Tea |
| Southeast Asia | Souvenir · Confectionery · Cosmetics · Tea |
| Long-haul (Dubai · Doha · LA) | Liquor · Apparel · Jewellery · Indigenous |

#### Item-level promotions (year-round)

| Promo_ID | Promotion | Type |
|---|---|---|
| IP-01 | Paw Paw Ointment — Buy 5 Get 6th Free (G Paw Paw free) | MIX_BUY_X_GET_Y |
| IP-02 | Comvita UMF 5+ — Buy 3 Get 4th Free | BUY_X_GET_Y_ITEM |
| IP-03 | Tim Tam — Any 4 Flavours for $24 | BUNDLE_FIXED_ITEM |

#### Payment method by nationality

| Nationality | Dominant method | Notes |
|---|---|---|
| AU / NZ / CA | Credit/Debit Card · Digital Wallet | Minimal cash |
| CN | AliPay · WeChat Pay | Cash also common (older travellers) |
| KR | Credit/Debit Card · Digital Wallet | AliPay ~0.1% (1 in 1,000) |
| JP | Cash · Digital Wallet | Cash culture still strong |
| GB / US | Credit/Debit Card | Low cash, growing digital wallet |
| IN / PH | Cash · Credit/Debit Card | Higher cash usage |

### Sales_Transactions columns (header)

| Column | Description |
|---|---|
| `Trans_ID` | Unique transaction identifier |
| `Date_Time` | Purchase timestamp |
| `Customer_ID` | FK → Customer_Profiles |
| `Flight_No` | FK → Flight_Schedules |
| `Destination` | Flight destination |
| `Event_ID` | Holiday event if active (else NULL) |
| `Event_Name` | Holiday event name for easy SQL filtering (else NULL) |
| `Item_Count` | Number of line items in this transaction |
| `Total_Amount` | Sum of all line amounts |
| `Total_Cost` | Sum of all line costs |
| `Gross_Profit` | Total_Amount − Total_Cost |
| `Payment_Method` | Payment method used |

#### Transaction_Items columns (lines)

| Column | Description |
|---|---|
| `Trans_ID` | FK → Sales_Transactions |
| `Line_No` | Line number within transaction (1, 2, 3…) |
| `Product_SKU` | FK → Product_Inventory |
| `Category` | Product category |
| `Quantity` | Units purchased (includes free items for BUY_X_GET_Y) |
| `Unit_Price` | Product retail price |
| `Line_Amount` | Actual charged amount for this line |
| `Line_Cost` | Cost of goods for this line |
| `Gross_Profit` | Line_Amount − Line_Cost |
| `Promo_ID` | Item-level promo if triggered (IP-01 to IP-03, else NULL) |

---

## 📊 Analytics Use Cases (Killer Insights)

| # | Question | Key columns | SQL techniques |
|---|---|---|---|
| 1 | **What is the golden hour by flight route?** | `Date_Time`, `Flight_No`, `Departure_Time`, `Total_Amount` | JOIN + DATEDIFF + WINDOW FUNCTION |
| 2 | **Do holidays shift purchase patterns?** | `Event_Name`, `Category`, `Nationality`, `Total_Amount` | CASE WHEN + GROUP BY + ratio comparison |
| 3 | **Who are the true VIP customers?** | `Nationality`, `Membership_Level`, `Total_Amount` | RANK() + ATV calculation |
| 4 | **Which category drives margin?** | `Category`, `Gross_Profit`, `Total_Amount` | GROUP BY + margin rate |
| 5 | **Do item promotions increase units sold?** | `Promo_ID`, `Quantity`, `Total_Amount`, `Gross_Profit` | GROUP BY + avg qty comparison |

---

## 🚀 How to Run

```bash
# 1. Install dependencies
pip install pandas numpy faker

# 2. Generate all datasets
python generate_duty_free_data.py

# 3. Output
duty_free_data/
├── Customer_Profiles.csv     (4,000 rows)
├── Product_Inventory.csv     (108 rows)
├── Flight_Schedules.csv      (2,860 rows)
├── Holiday_Events.csv        (3 rows)
├── Sales_Transactions.csv    (5,000 rows)
└── Transaction_Items.csv     (9,365 rows)

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

