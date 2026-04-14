-----------------------------------------------
-- Rebuilding tables to implement PK/FK constraints for Star Schema
-----------------------------------------------

-- 1. customer_details


CREATE TABLE "customer_details_new" (
    "customer_id" TEXT PRIMARY KEY,
    "nationality" TEXT,
    "age_group" TEXT
);

INSERT INTO "customer_details_new" SELECT * FROM "customer_details";

SELECT * FROM customer_details_new;

DROP TABLE "customer_details";
ALTER TABLE "customer_details_new" RENAME TO "customer_details";


-- 2. flight_schedules


CREATE TABLE "flight_schedules_new" (
	"flight_id" TEXT PRIMARY KEY,
  	"flight_no" TEXT,
  	"airline" TEXT,
 	"destination" TEXT,
  	"departure_time" TIMESTAMP,
 	"flight_status" TEXT
);

INSERT INTO "flight_schedules_new" SELECT * FROM "flight_schedules";

SELECT * FROM flight_schedules_new;

DROP TABLE "flight_schedules";
ALTER TABLE "flight_schedules_new" RENAME TO "flight_schedules";


-- 3. holiday_events


CREATE TABLE "holiday_events_new" (
	"event_id" TEXT PRIMARY KEY,
  	"event_name" TEXT,
 	"start_date" TEXT,
 	"end_date" TEXT
);

INSERT INTO "holiday_events_new" SELECT * FROM "holiday_events";

SELECT * FROM holiday_events_new;

DROP TABLE "holiday_events";
ALTER TABLE "holiday_events_new" RENAME TO "holiday_events";


-- 4. product_master


CREATE TABLE "product_master_new" (
	"product_sku" TEXT PRIMARY KEY,
  	"category" TEXT,
  	"item" TEXT,
  	"variant" TEXT,
  	"selling_price" REAL,
 	"cost_price" REAL
);


INSERT INTO "product_master_new" SELECT * FROM "product_master";

SELECT * FROM product_master_new;

DROP TABLE "product_master";
ALTER TABLE "product_master_new" RENAME TO "product_master";


-- 5. transactions


CREATE TABLE "transactions_new" (
    "tx_id" TEXT,
    "line_no" INTEGER,
    "tx_time" TEXT,
    "customer_id" TEXT,
    "flight_id" TEXT,
    "event_id" TEXT,
    "product_sku" TEXT,
    "qty" INTEGER,
    "unit_price" REAL,
    "net_amount" REAL,
    "disc_amount" REAL,
    "promo_id" TEXT,
    "payment_method" TEXT,
    PRIMARY KEY ("tx_id", "line_no"),
    FOREIGN KEY ("customer_id") REFERENCES "customer_details" ("customer_id"),
    FOREIGN KEY ("flight_id") REFERENCES "flight_schedules" ("flight_id"),
    FOREIGN KEY ("event_id") REFERENCES "holiday_events" ("event_id"),
    FOREIGN KEY ("product_sku") REFERENCES "product_master" ("product_sku")
);

INSERT INTO "transactions_new" SELECT * FROM "transactions";

DROP TABLE "transactions";
ALTER TABLE "transactions_new" RENAME TO "transactions";

