-- 30-create-indices.sql
-- This script creates primary keys, unique constraints, foreign keys, and additional indexes
-- for the tables defined in 10-create-tables.sql.
-- Ensure all tables are explicitly set up with PRIMARY KEY constraints
-- Most 'id SERIAL PRIMARY KEY' already handle this, but explicit ALTER TABLE can clarify.


-- Wrap in a transaction for atomicity
BEGIN;

--------------------------------------------------------------------------------
-- 1. Primary Keys (if not already handled by SERIAL PRIMARY KEY in 10-create-tables.sql)
--    and TMS ID Unique Constraints
--------------------------------------------------------------------------------

-- data_suppliers
ALTER TABLE data_suppliers ADD CONSTRAINT uq_data_suppliers_tms_id UNIQUE (tms_id);

-- users
ALTER TABLE users ADD CONSTRAINT uq_users_tms_id UNIQUE (tms_id);

-- owners
ALTER TABLE owners ADD CONSTRAINT uq_owners_tms_id UNIQUE (tms_id);

-- terminals
ALTER TABLE terminals ADD CONSTRAINT uq_terminals_tms_id UNIQUE (tms_id);

-- address_types
ALTER TABLE address_types ADD CONSTRAINT uq_address_types_tms_id UNIQUE (tms_id);

-- addresses
ALTER TABLE addresses ADD CONSTRAINT uq_addresses_tms_id UNIQUE (tms_id);

-- trucks
ALTER TABLE trucks ADD CONSTRAINT uq_trucks_tms_id UNIQUE (tms_id);

-- trailers
ALTER TABLE trailers ADD CONSTRAINT uq_trailers_tms_id UNIQUE (tms_id);

-- breadcrumbs
ALTER TABLE breadcrumbs ADD CONSTRAINT uq_breadcrumbs_tms_id UNIQUE (tms_id);

-- stop_types
ALTER TABLE stop_types ADD CONSTRAINT uq_stop_types_tms_id UNIQUE (tms_id);

-- stops
ALTER TABLE stops ADD CONSTRAINT uq_stops_tms_id UNIQUE (tms_id);

-- purchase_orders
ALTER TABLE purchase_orders ADD CONSTRAINT uq_purchase_orders_tms_id UNIQUE (tms_id);

-- shipments
ALTER TABLE shipments ADD CONSTRAINT uq_shipments_tms_id UNIQUE (tms_id);

-- load_statuses
ALTER TABLE load_statuses ADD CONSTRAINT uq_load_statuses_tms_id UNIQUE (tms_id);

-- load_categories
ALTER TABLE load_categories ADD CONSTRAINT uq_load_categories_tms_id UNIQUE (tms_id);

-- loads
ALTER TABLE loads ADD CONSTRAINT uq_loads_tms_id UNIQUE (tms_id);
-- Add unique constraint for load_hash if you decide to implement hashing for deduplication
-- ALTER TABLE loads ADD CONSTRAINT uq_loads_hash UNIQUE (load_hash);

--------------------------------------------------------------------------------
-- 2. Foreign Key Constraints
--------------------------------------------------------------------------------

-- users
--ALTER TABLE users ADD CONSTRAINT fk_users_data_supplier_id
--    FOREIGN KEY (data_supplier_id) REFERENCES data_suppliers(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

-- owners
--ALTER TABLE owners ADD CONSTRAINT fk_owners_data_supplier_id
--    FOREIGN KEY (data_supplier_id) REFERENCES data_suppliers(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

-- addresses
ALTER TABLE addresses ADD CONSTRAINT fk_addresses_parent_address_id
    FOREIGN KEY (parent_address_id) REFERENCES addresses(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE addresses ADD CONSTRAINT fk_addresses_terminal_id
    FOREIGN KEY (terminal_id) REFERENCES terminals(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE addresses ADD CONSTRAINT fk_addresses_address_type_id
    FOREIGN KEY (address_type_id) REFERENCES address_types(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

-- trucks
ALTER TABLE trucks ADD CONSTRAINT fk_trucks_owned_by_id
    FOREIGN KEY (owned_by_id) REFERENCES owners(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE trucks ADD CONSTRAINT fk_trucks_primary_terminal_id
    FOREIGN KEY (primary_terminal_id) REFERENCES terminals(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE trucks ADD CONSTRAINT fk_trucks_last_breadcrumb_id
    FOREIGN KEY (last_breadcrumb_id) REFERENCES breadcrumbs(id) ON DELETE SET NULL ON UPDATE NO ACTION; -- Use SET NULL if breadcrumb can be deleted independently

-- trailers
ALTER TABLE trailers ADD CONSTRAINT fk_trailers_owned_by_id
    FOREIGN KEY (owned_by_id) REFERENCES owners(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE trailers ADD CONSTRAINT fk_trailers_primary_terminal_id
    FOREIGN KEY (primary_terminal_id) REFERENCES terminals(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE trailers ADD CONSTRAINT fk_trailers_last_breadcrumb_id
    FOREIGN KEY (last_breadcrumb_id) REFERENCES breadcrumbs(id) ON DELETE SET NULL ON UPDATE NO ACTION;

-- breadcrumbs: No direct FK to addresses based on previous definitions.
-- If `location_id` or similar were to reference `addresses.id`, it would go here.

-- stops
ALTER TABLE stops ADD CONSTRAINT fk_stops_location_id
    FOREIGN KEY (location_id) REFERENCES addresses(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE stops ADD CONSTRAINT fk_stops_stop_type_id
    FOREIGN KEY (stop_type_id) REFERENCES stop_types(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

-- purchase_orders
ALTER TABLE purchase_orders ADD CONSTRAINT fk_purchase_orders_agent_user_id
    FOREIGN KEY (agent_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE purchase_orders ADD CONSTRAINT fk_purchase_orders_bill_to_address_id
    FOREIGN KEY (bill_to_id) REFERENCES addresses(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE purchase_orders ADD CONSTRAINT fk_purchase_orders_reviewed_by_user_id
    FOREIGN KEY (reviewed_by_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

-- shipments
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_first_stop_id
    FOREIGN KEY (first_stop_id) REFERENCES stops(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_last_stop_id
    FOREIGN KEY (last_stop_id) REFERENCES stops(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_purchase_order_id
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_hauled_for_owner_id
    FOREIGN KEY (hauled_for_id) REFERENCES owners(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_origin_created_by_user_id
    FOREIGN KEY (origin_created_by_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_current_breadcrumb_id
    FOREIGN KEY (current_breadcrumb_id) REFERENCES breadcrumbs(id) ON DELETE SET NULL ON UPDATE NO ACTION;

-- loads
ALTER TABLE loads ADD CONSTRAINT fk_loads_current_stop_id
    FOREIGN KEY (current_stop_id) REFERENCES stops(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_next_stop_id
    FOREIGN KEY (next_stop_id) REFERENCES stops(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_first_stop_id
    FOREIGN KEY (first_stop_id) REFERENCES stops(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_last_stop_id
    FOREIGN KEY (last_stop_id) REFERENCES stops(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_truck_id
    FOREIGN KEY (truck_id) REFERENCES trucks(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_creator_user_id
    FOREIGN KEY (creator_user_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_status_id
    FOREIGN KEY (status_id) REFERENCES load_statuses(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_hauling_terminal_id
    FOREIGN KEY (hauling_terminal_id) REFERENCES terminals(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_origination_terminal_id
    FOREIGN KEY (origination_terminal_id) REFERENCES terminals(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_category_id
    FOREIGN KEY (category_id) REFERENCES load_categories(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_first_shipment_main_id
    FOREIGN KEY (first_shipment_main_id) REFERENCES shipments(id) ON DELETE RESTRICT ON UPDATE NO ACTION;
ALTER TABLE loads ADD CONSTRAINT fk_loads_current_breadcrumb_id
    FOREIGN KEY (current_breadcrumb_id) REFERENCES breadcrumbs(id) ON DELETE SET NULL ON UPDATE NO ACTION;


-- Linking Tables Foreign Keys
-- load_drivers
ALTER TABLE load_drivers ADD CONSTRAINT fk_load_drivers_load_id
    FOREIGN KEY (load_id) REFERENCES loads(id) ON DELETE CASCADE ON UPDATE NO ACTION; -- Cascade delete if load is removed
ALTER TABLE load_drivers ADD CONSTRAINT fk_load_drivers_driver_user_id
    FOREIGN KEY (driver_user_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

-- load_revenues
ALTER TABLE load_revenues ADD CONSTRAINT fk_load_revenues_load_id
    FOREIGN KEY (load_id) REFERENCES loads(id) ON DELETE CASCADE ON UPDATE NO ACTION;

-- load_shipments
ALTER TABLE load_shipments ADD CONSTRAINT fk_load_shipments_load_id
    FOREIGN KEY (load_id) REFERENCES loads(id) ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE load_shipments ADD CONSTRAINT fk_load_shipments_shipment_id
    FOREIGN KEY (shipment_id) REFERENCES shipments(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

-- shipment_stops
ALTER TABLE shipment_stops ADD CONSTRAINT fk_shipment_stops_shipment_id
    FOREIGN KEY (shipment_id) REFERENCES shipments(id) ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE shipment_stops ADD CONSTRAINT fk_shipment_stops_stop_id
    FOREIGN KEY (stop_id) REFERENCES stops(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

-- load_trailers
ALTER TABLE load_trailers ADD CONSTRAINT fk_load_trailers_load_id
    FOREIGN KEY (load_id) REFERENCES loads(id) ON DELETE CASCADE ON UPDATE NO ACTION;
ALTER TABLE load_trailers ADD CONSTRAINT fk_load_trailers_trailer_id
    FOREIGN KEY (trailer_id) REFERENCES trailers(id) ON DELETE RESTRICT ON UPDATE NO ACTION;

COMMIT;
-- End of transaction block
--------------------------------------------------------------------------------
-- 3. Additional Indexes for Performance
--------------------------------------------------------------------------------

-- Indexes on common lookup fields, or fields used in JOINs/WHERE clauses that aren't PKs/Unique-constrained

-- users
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users (employee_id); -- Common lookup by employee_id

-- addresses
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_addresses_city_state ON addresses (city, state);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_addresses_postal_code ON addresses (postal_code);

-- trucks
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trucks_name ON trucks (name);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trucks_reg_tag ON trucks (reg_tag);

-- trailers
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trailers_name ON trailers (name);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trailers_reg_tag ON trailers (reg_tag);

-- breadcrumbs
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_breadcrumbs_recorded_at ON breadcrumbs (recorded_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_breadcrumbs_received_at ON breadcrumbs (received_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_breadcrumbs_latitude_longitude ON breadcrumbs (latitude, longitude);

-- stops
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stops_scheduled_arrive_at ON stops (scheduled_arrive_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stops_scheduled_depart_at ON stops (scheduled_depart_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stops_number ON stops (number);

-- purchase_orders
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_purchase_orders_name ON purchase_orders (name);

-- shipments
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shipments_name ON shipments (name);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shipments_origin_created_at ON shipments (origin_created_at DESC);

-- loads
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_loads_first_purchase_order ON loads (first_purchase_order);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_loads_summary ON loads (summary); -- If `summary` is frequently searched (consider `GIN` for `jsonb` if full-text search)


-- Indexes on FK columns that are not part of a composite PK (e.g., in linking tables)
-- For `load_drivers`, `load_revenues`, `load_shipments`, `shipment_stops`, `load_trailers`,
-- their FKs are part of their composite PK, so indexes are automatically created.
-- No need to explicitly add more for these specific cases.

