-- File: src/database/sql/new_tables.sql
-- This file contains the SQL statements to create new tables in the database.

-- Function to update dependent is_active fields
CREATE OR REPLACE FUNCTION update_dependent_is_active()
RETURNS TRIGGER AS $$
DECLARE
    target_table TEXT := TG_ARGV[0];
    join_column TEXT := TG_ARGV[1];
BEGIN
    EXECUTE format('UPDATE %I SET is_active = $1.is_active WHERE %I = $1.serial_id',
                   target_table, join_column) -- %I is used for identifiers, and SQL injection is avoided by using parameterized queries
    USING NEW;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Generic function to update dependent is_active fields by a given ID
CREATE OR REPLACE FUNCTION update_dependent_is_active_by_id(
    target_table_name TEXT,
    join_column_name TEXT,
    entity_serial_id_to_update INTEGER,
    new_is_active_status BOOLEAN
)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('UPDATE %I SET is_active = %L WHERE %I = %L',
                   target_table_name,
                   new_is_active_status,
                   join_column_name,
                   entity_serial_id_to_update);
END;
$$ LANGUAGE plpgsql;

-- Trigger function for updates to authority active status.
-- Multiple dependent tables can be updated by calling the generic function.
CREATE OR REPLACE FUNCTION master_authority_is_active_update()
RETURNS TRIGGER AS $$
DECLARE
    contact_id INTEGER;
BEGIN
    -- Call the generic function with the specific arguments dependent tables.
    PERFORM update_dependent_is_active('addresses', 'entity_serial_id');

    PERFORM update_dependent_is_active('divisions', 'authority_id');
    
    IF NEW.authority_contacts IS NOT NULL AND array_length(NEW.authority_contacts, 1) > 0 THEN
        FOREACH contact_id IN ARRAY NEW.authority_contacts LOOP
            PERFORM update_dependent_is_active_by_id('contacts', 'serial_id', contact_id, NEW.is_active);
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION master_division_is_active_update()
RETURNS TRIGGER AS $$
DECLARE
    contact_id INTEGER;
BEGIN
    -- Call the generic function with the specific arguments for dependent tables.
    PERFORM update_dependent_is_active('addresses', 'entity_serial_id');
    
    IF NEW.division_contacts IS NOT NULL AND array_length(NEW.division_contacts, 1) > 0 THEN
        FOREACH contact_id IN ARRAY NEW.division_contacts LOOP
            PERFORM update_dependent_is_active_by_id('contacts', 'serial_id', contact_id, NEW.is_active);
        END LOOP;
    END IF;
    
    PERFORM update_dependent_is_active('drivers', 'division_id');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Master Lookup Table for Stop Types
-- This table contains the types of stops (e.g. Pickup, Delivery, Fuel, Rest).
CREATE TABLE IF NOT EXISTS lu_stop_types (
    serial_id SERIAL PRIMARY KEY,
    stop_type_name VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Master Lookup Table for Address Types
-- This table contains the types of addresses (e.g. Billing, Shipping, Terminal).
CREATE TABLE IF NOT EXISTS lu_address_types (
    serial_id SERIAL PRIMARY KEY,
    address_type_name VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)

-- Master Lookup Table for Location Sources
-- This table contains the origin of the location data (e.g. GPS, manual entry).
CREATE TABLE IF NOT EXISTS lu_location_sources (
    serial_id SERIAL PRIMARY KEY,
    location_source_name VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default location sources
-- These records are used to represent the default and system location sources.
INSERT INTO lu_location_sources (serial_id, location_source_name) VALUES (-1, 'unavailable')
ON CONFLICT (serial_id) DO UPDATE SET
    location_source = EXCLUDED.location_source_name,
    updated_at = NOW();

-- Insert system location source
-- This record helps enforce the system as 0 default in later queries.
INSERT INTO lu_location_sources (serial_id, location_source_name) VALUES (0, 'System')
ON CONFLICT (serial_id) DO UPDATE SET
    location_source = EXCLUDED.location_source_name,
    updated_at = NOW();

-- Insert current location sources for initial setup
INSERT INTO lu_location_sources (location_source_name) VALUES
('BOLT'),
('Geotab'),
('Manual Entry')
ON CONFLICT (location_source_name) DO UPDATE SET
    location_source_name = EXCLUDED.location_source_name,
    updated_at = NOW();

-- Master Lookup Table for Contact Types
-- This table contains the types of contacts (e.g. Driver, Customer, Delivery Notification).
CREATE TABLE IF NOT EXISTS lu_contact_types (
    serial_id SERIAL PRIMARY KEY,
    contact_type_name VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default contact types
-- These records are used to represent the default and system contact types.
INSERT INTO lu_contact_types (serial_id, contact_type_name) VALUES (-1, 'unavailable')
ON CONFLICT (serial_id) DO UPDATE SET
    contact_type_name = EXCLUDED.contact_type_name,
    updated_at = NOW();
-- Insert system contact type
-- This record helps enforce the system as 0 default in later queries.
INSERT INTO lu_contact_types (serial_id, contact_type_name) VALUES (0, 'System')
ON CONFLICT (serial_id) DO UPDATE SET
    contact_type_name = EXCLUDED.contact_type_name,
    updated_at = NOW();


--Master Contacts Table
CREATE TABLE IF NOT EXISTS contacts (
    serial_id SERIAL PRIMARY KEY,
    contact_type INTEGER NOT NULL, -- INT indicating the type of contact (e.g. Driver, Customer, Delivery Notification)
    FOREIGN KEY (contact_type) REFERENCES lu_contact_types(serial_id),
    email VARCHAR(255),
    CONSTRAINT chk_email_format CHECK (email ~* '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$' OR email IS NULL)
    mobile_phone VARCHAR(10),
    CONSTRAINT chk_phone_number_format CHECK (mobile_phone ~ '^[0-9]{10}$' OR mobile_phone IS NULL),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert an unavailable contact record
-- This record is used to represent a contact that is unavailable or unknown.
INSERT INTO contacts (serial_id, contact_type, email, mobile_phone)
VALUES (-1, -1, 'unavailable', '0000000000')
ON CONFLICT (serial_id) DO UPDATE SET
    contact_type = EXCLUDED.contact_type,
    email = EXCLUDED.email,
    mobile_phone = EXCLUDED.mobile_phone,
    updated_at = NOW();

-- Index to speed up queries search on serial_id
-- This index is useful for queries that retrieve a specific contact by its serial_id.
CREATE INDEX IF NOT EXISTS idx_contact_serial_id ON contacts (serial_id DESC) WHERE is_active = TRUE;


-- Master Geo Locations Table
CREATE TABLE IF NOT EXISTS geo_locations (
    serial_id BIGSERIAL PRIMARY KEY,
    location_source INTEGER NOT NULL DEFAULT 0, -- INT indicating the source of the location (e.g. GPS, manual entry)
    FOREIGN KEY (location_source) REFERENCES lu_location_sources(serial_id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT '1970-01-01 00:00:00+00',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- TODO: Index to speed up queries that filter by location_source
-- TODO: Index to speed up queries that filter by currency: recorded_at.

-- Insert a default location record
-- This record is used to represent a default or unknown location.
INSERT INTO geo_locations (serial_id, latitude, longitude, location_source, recorded_at)
VALUES (-1, 0, 0, 0, '1970-01-01 00:00:00+00'::timestamp with time zone)
ON CONFLICT (serial_id) DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    location_source = EXCLUDED.location_source,
    recorded_at = DEFAULT;

-- Master Addresses Table
CREATE TABLE IF NOT EXISTS addresses (
    serial_id SERIAL PRIMARY KEY,
    address_contact_ids INTEGER [],
    FOREIGN KEY (address_contact_ids) REFERENCES contacts(serial_id),
    street_1 VARCHAR(255) NOT NULL,
    street_2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    address_type INTEGER NOT NULL,
    FOREIGN KEY (address_type) REFERENCES lu_address_types(serial_id),
    is_active BOOLEAN DEFAULT TRUE,
    location_id BIGINT NOT NULL,
    FOREIGN KEY (location_id) REFERENCES geo_locations(serial_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TODO: add a trigger to update location_id is_active when address is_active is updated.
-- TODO: add a trigger to update location_id when street_1, street_2, city, state, postal_code, or country is updated.

-- Partial index to speed up queries that filter by is_active
-- This index is useful for queries that retrieve only active addresses.
CREATE INDEX IF NOT EXISTS idx_addresses_serial_id ON addresses (serial_id DESC) WHERE is_active = TRUE; 


-- Master Authorities Table
CREATE TABLE IF NOT EXISTS authorities (
    serial_id SERIAL PRIMARY KEY,
    authority_name VARCHAR(255) NOT NULL,
    dot_number VARCHAR(20) NOT NULL,
    address_id INTEGER NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(serial_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger to update dependent is_active fields when authority is activated/deactivated.
CREATE TRIGGER update_authority_is_active
AFTER UPDATE OF is_active ON authorities
FOR EACH ROW
EXECUTE FUNCTION master_authority_is_active_update();

-- Master Divisions Table
CREATE TABLE IF NOT EXISTS divisions (
    serial_id SERIAL PRIMARY KEY,
    division_name VARCHAR(255) NOT NULL,
    bolt_terminal_id INTEGER NOT NULL,
    authority_id INTEGER NOT NULL,
    FOREIGN KEY (authority_id) REFERENCES authorities(serial_id),
    address_id INTEGER NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(serial_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger to update dependent is_active fields when division is activated/deactivated.
CREATE TRIGGER update_division_is_active
AFTER UPDATE OF is_active ON divisions
FOR EACH ROW
EXECUTE FUNCTION master_division_is_active_update();

-- Insert an unavailable division record
-- This record is used to represent a division that is not currently known or available.
INSERT INTO divisions (serial_id, division_name, bolt_terminal_id, authority_id, address_id)
VALUES (-1, 'unavailable', -1, -1, -1)
ON CONFLICT (serial_id) DO NOTHING;

-- Master Terminals Table
CREATE TABLE IF NOT EXISTS terminals (
    serial_id SERIAL PRIMARY KEY,
    tms_id VARCHAR(255) NOT NULL,
    terminal_name VARCHAR(255) NOT NULL,
    division_id INTEGER NOT NULL,
    FOREIGN KEY (division_id) REFERENCES divisions(serial_id),
    address_id INTEGER NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(serial_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO terminals (serial_id, tms_id, terminal_name, division_id, address_id)
VALUES (-1, 'unavailable', 'unavailable', -1, -1);


-- MASTER Trailer Table
CREATE TABLE IF NOT EXISTS trailers (
    serial_id SERIAL PRIMARY KEY,
    tms_id VARCHAR(255) NOT NULL,
    terminal_id INTEGER NOT NULL DEFAULT 0, -- 0 indicates no terminal
    FOREIGN KEY (terminal_id) REFERENCES terminals(serial_id),
    division_id INTEGER NOT NULL DEFAULT 0, -- 0 indicates no division
    FOREIGN KEY (division_id) REFERENCES divisions(serial_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)

-- TODO: Add trigger that updates attached_to_entity_id to 0 and detaches trailer from truck when trailer is deactivated.

-- Master Truck Table
-- This table contains all trucks, including those that are not currently in use.
CREATE Table IF NOT EXISTS trucks (
    serial_id SERIAL PRIMARY KEY,
    tms_id VARCHAR(255) NOT NULL,
    telematic_id VARCHAR(255),
    truck_name VARCHAR(255) NOT NULL,
    division_id INTEGER NOT NULL,
    FOREIGN KEY (division_id) REFERENCES divisions(serial_id),
    terminal_id INTEGER NOT NULL DEFAULT -1, -- -1 indicates no terminal
    FOREIGN KEY (terminal_id) REFERENCES terminals(serial_id),
    current_driver_id INTEGER,
    trailer_1_id INTEGER,
    FOREIGN KEY (trailer_1_id) REFERENCES trailers(serial_id),
    trailer_2_id INTEGER,
    FOREIGN KEY (trailer_2_id) REFERENCES trailers(serial_id),
    current_location_id BIGINT,
    is_active BOOLEAN DEFAULT TRUE,
    vin VARCHAR(17),
    license_plate VARCHAR(15),
    license_plate_state VARCHAR(3),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)


-- Inserts default truck records for unknown and no truck
-- These records are used to represent an unknown truck, or for assignment to a driver who is not on a truck.
-- The serial_id follows the -1 and 0 pattern used in other tables to ensure consistency.
INSERT INTO trucks (
    serial_id, 
    tms_id, 
    telematic_id, 
    truck_name, 
    division_id,
    terminal_id, 
    current_driver_id, 
    trailer_1_id, 
    trailer_2_id, 
    current_location_id, 
    vin, 
    license_plate, 
    license_plate_state
    )
    VALUES ( 
        -1, 'unavailable', NULL, 'unavailable',-1, -1, -1, -1, -1, -1, 'unavailable', 'unavailable', 'unavailable'
    ),
    (
        0, 'No truck', NULL, 'No truck', -1, -1, 0, -1, 0, 0, 'No Truck', 'No Truck', 'No Truck'
    )
    ON CONFLICT (serial_id) DO UPDATE SET
        tms_id = EXCLUDED.tms_id,
        telematic_id = EXCLUDED.telematic_id,
        truck_name = EXCLUDED.truck_name,
        division_id = EXCLUDED.division_id,
        current_driver_id = EXCLUDED.current_driver_id,
        trailer_1_id = EXCLUDED.trailer_1_id,
        trailer_2_id = EXCLUDED.trailer_2_id,
        current_location_id = EXCLUDED.current_location_id,
        vin = EXCLUDED.vin,
        license_plate = EXCLUDED.license_plate,
        license_plate_state = EXCLUDED.license_plate_state,
        updated_at = NOW();


-- Master Driver Table
CREATE TABLE IF NOT EXISTS drivers (
    serial_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    license_number VARCHAR(40) UNIQUE NOT NULL,
    license_state VARCHAR(25) NOT NULL,
    division_id INTEGER NOT NULL DEFAULT -1,
    FOREIGN KEY (division_id) REFERENCES divisions(serial_id),
    terminal_id INTEGER NOT NULL DEFAULT -1,
    FOREIGN KEY (terminal_id) REFERENCES terminals(serial_id),
    tms_id VARCHAR(255),
    telematic_id VARCHAR(255),
    current_truck_serial_id INTEGER DEFAULT 0, -- 0 indicates no truck assigned
    FOREIGN KEY (current_truck_serial_id) REFERENCES trucks(serial_id),
    contact_id INTEGER,
    FOREIGN KEY (contact_id) REFERENCES contacts(serial_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);



-- Insert an unknown driver record
-- This record is used to represent a driver that is not currently known or available.
-- This record is inserted with serial_id -1 to ensure it is unique and can be used in queries.
-- It is also updated on conflict to ensure the record is always available.
INSERT INTO drivers 
(
    serial_id, 
    first_name, 
    last_name, 
    license_number, 
    license_state, 
    division_id, 
    terminal_id, 
    tms_id, 
    telematic_id, 
    current_truck_serial_id
    ) 
VALUES (-1, 'unavailable', 'unavailable', 'unavailable', 'unavailable', -1, -1, NULL, NULL, -1),
       (0, 'No Driver', 'No Driver', 'No Driver', 'No Driver', -1, -1, NULL, NULL, 0)
ON CONFLICT (serial_id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    license_number = EXCLUDED.license_number,
    license_state = EXCLUDED.license_state,
    division_id = EXCLUDED.division_id,
    terminal_id = EXCLUDED.terminal_id,
    tms_id = EXCLUDED.tms_id,
    telematic_id = EXCLUDED.telematic_id,
    current_truck_serial_id = EXCLUDED.current_truck_serial_id,
    updated_at = NOW();


-- Master Stops Table

CREATE TABLE IF NOT EXISTS stops (
    serial_id BIGSERIAL PRIMARY KEY,
    address_id INTEGER NOT NULL DEFAULT -1, -- Default to 'unavailable' address
    FOREIGN KEY (address_id) REFERENCES addresses(serial_id),
    stop_type_id INTEGER NOT NULL DEFAULT 0, -- Default to 'System' stop type
    FOREIGN KEY (stop_type_id) REFERENCES lu_stop_types(serial_id),
    stop_purchase_orders VARCHAR(255) [],
    stop_sequence INTEGER NOT NULL,
    tms_pro_number VARCHAR(255),
    stop_driver_id INTEGER NOT NULL DEFAULT 0, -- Default to 'No Driver'
    FOREIGN KEY (stop_driver_id) REFERENCES drivers(serial_id),
    stop_truck_id INTEGER NOT NULL DEFAULT 0, -- Default to 'No Truck'
    FOREIGN KEY (stop_truck_id) REFERENCES trucks(serial_id),
    sched_arrival TIMESTAMP WITH TIME ZONE,
    actl_arrive TIMESTAMP WITH TIME ZONE,
    sched_dept TIMESTAMP WITH TIME ZONE,
    actl_dept TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT FALSE, -- Default to not completed
    is_active BOOLEAN DEFAULT TRUE, -- Default to active
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stops_tms_pro_number ON stops (tms_pro_number) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_stops_address_id ON stops (address_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_stops_stop_type_id ON stops (stop_type_id);
CREATE INDEX IF NOT EXISTS idx_stops_stop_driver_id ON stops (stop_driver_id);
CREATE INDEX IF NOT EXISTS idx_stops_stop_truck_id ON stops (stop_truck_id);
CREATE INDEX IF NOT EXISTS idx_stops_pos_gin ON stops USING GIN (stop_purchase_orders);  -- GIN index for array column
CREATE INDEX IF NOT EXISTS idx_stops_pro_seq ON stops (tms_pro_number, stop_sequence);

-- Master Loads Table
CREATE TABLE IF NOT EXISTS loads (
    serial_id SERIAL PRIMARY KEY,
    load_purchase_orders VARCHAR(255) [],
    load_stop_ids BIGINT [],
    FOREIGN KEY (load_stop_ids) REFERENCES stops(serial_id),
    tms_pro_number VARCHAR(255) UNIQUE,
    assigned_driver_ids INTEGER [],
    FOREIGN KEY (assigned_driver_ids) REFERENCES drivers(serial_id),
    assigned_truck_ids INTEGER [],
    FOREIGN KEY (assigned_truck_ids) REFERENCES trucks(serial_id),
    trailer_ids INTEGER [],
    FOREIGN KEY (trailer_ids) REFERENCES trailers(serial_id),
    terminal_id INTEGER NOT NULL DEFAULT -1, -- -1 indicates no terminal
    FOREIGN KEY (terminal_id) REFERENCES terminals(serial_id),
    division_id INTEGER NOT NULL DEFAULT -1, -- -1 indicates no division
    FOREIGN KEY (division_id) REFERENCES divisions(serial_id),
    is_active BOOLEAN DEFAULT TRUE, -- Default to active
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loads_tms_pro_number ON loads (tms_pro_number) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_loads_terminal_id ON loads (terminal_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_loads_division_id ON loads (division_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_loads_assigned_driver_ids_gin ON loads USING GIN; -- GIN index for array column
CREATE INDEX IF NOT EXISTS idx_loads_assigned_truck_ids_gin ON loads USING GIN; -- GIN index for array column