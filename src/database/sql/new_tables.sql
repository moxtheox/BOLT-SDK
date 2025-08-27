-- File: src/database/sql/new_tables.sql
-- This file contains the SQL statements to create new tables in the database.

CREATE OR REPLACE FUNCTION string_has_length(p_string TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_string IS NOT NULL AND LENGTH(TRIM(p_string)) > 0;
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

CREATE OR REPLACE FUNCTION upsert_stop_type(p_stop_type_name VARCHAR(50))

RETURNS INTEGER AS $$
DECLARE
    v_stop_type_id INTEGER;
BEGIN
    IF NOT string_has_length(p_stop_type_name) THEN
        RAISE EXCEPTION 'Stop type name cannot be null or empty';
    END IF;
    INSERT INTO lu_stop_types (stop_type_name)
    VALUES (TRIM(p_stop_type_name))
    ON CONFLICT (stop_type_name) DO UPDATE SET
        stop_type_name = EXCLUDED.stop_type_name,
        updated_at = NOW()
    RETURNING serial_id INTO v_stop_type_id;
    RETURN v_stop_type_id;
END;
$$ LANGUAGE plpgsql;

-- Master Lookup Table for Address Types
-- This table contains the types of addresses (e.g. Billing, Shipping, Terminal).
CREATE TABLE IF NOT EXISTS lu_address_types (
    serial_id SERIAL PRIMARY KEY,
    address_type_name VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION upsert_address_type(p_address_type_name VARCHAR(50))
RETURNS INTEGER AS $$
DECLARE
    v_address_type_id INTEGER;
BEGIN
    IF NOT string_has_length(p_address_type_name) THEN
        RAISE EXCEPTION 'Address type name cannot be null or empty';
    END IF;
    INSERT INTO lu_address_types (address_type_name)
    VALUES (TRIM(p_address_type_name))
    ON CONFLICT (address_type_name) DO UPDATE SET
        address_type_name = EXCLUDED.address_type_name,
        updated_at = NOW()
    RETURNING serial_id INTO v_address_type_id;
    RETURN v_address_type_id;
END;
$$ LANGUAGE plpgsql;


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
    location_source_name = EXCLUDED.location_source_name,
    updated_at = NOW();

-- Insert system location source
-- This record helps enforce the system as 0 default in later queries.
INSERT INTO lu_location_sources (serial_id, location_source_name) VALUES (0, 'System')
ON CONFLICT (serial_id) DO UPDATE SET
    location_source_name = EXCLUDED.location_source_name,
    updated_at = NOW();

-- Insert current location sources for initial setup
INSERT INTO lu_location_sources (location_source_name) VALUES
('BOLT'),
('Geotab'),
('Manual Entry')
ON CONFLICT (location_source_name) DO UPDATE SET
    location_source_name = EXCLUDED.location_source_name,
    updated_at = NOW();



CREATE OR REPLACE FUNCTION upsert_location_source(p_location_source_name VARCHAR(50))
RETURNS INTEGER AS $$
DECLARE
    v_location_source_id INTEGER;
BEGIN
    IF NOT string_has_length(p_location_source_name) THEN
        RAISE EXCEPTION 'Location source name cannot be null or empty';
    END IF;
    INSERT INTO lu_location_sources (location_source_name)
    VALUES (TRIM(p_location_source_name))
    ON CONFLICT (location_source_name) DO UPDATE SET
        location_source_name = EXCLUDED.location_source_name,
        updated_at = NOW()
    RETURNING serial_id INTO v_location_source_id;
    RETURN v_location_source_id;
END;
$$ LANGUAGE plpgsql;


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


CREATE OR REPLACE FUNCTION upsert_contact_type(p_contact_type_name VARCHAR(50))
RETURNS INTEGER AS $$
DECLARE
    v_contact_type_id INTEGER;
BEGIN
    IF NOT string_has_length(p_contact_type_name) THEN
        RAISE EXCEPTION 'Contact type name cannot be null or empty';
    END IF;
    INSERT INTO lu_contact_types (contact_type_name)
    VALUES (TRIM(p_contact_type_name))
    ON CONFLICT (contact_type_name) DO UPDATE SET
        contact_type_name = EXCLUDED.contact_type_name,
        updated_at = NOW()
    RETURNING serial_id INTO v_contact_type_id;
    RETURN v_contact_type_id;
END;
$$ LANGUAGE plpgsql;


--Master Contacts Table
CREATE TABLE IF NOT EXISTS contacts (
    serial_id SERIAL PRIMARY KEY,
    contact_type INTEGER NOT NULL, -- INT indicating the type of contact (e.g. Driver, Customer, Delivery Notification)
    FOREIGN KEY (contact_type) REFERENCES lu_contact_types(serial_id),
    email VARCHAR(255),
    mobile_phone VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_email_format CHECK (email ~* '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$' OR email IS NULL),
    CONSTRAINT chk_phone_number_format CHECK (mobile_phone ~ '^[0-9]{10}$' OR mobile_phone IS NULL)
);


CREATE OR REPLACE FUNCTION insert_contact(
    p_contact_type INTEGER,
    p_email VARCHAR(255),
    p_mobile_phone VARCHAR(10)
) RETURNS INTEGER AS $$
DECLARE
    v_contact_id INTEGER;
BEGIN
    INSERT INTO contacts (contact_type, email, mobile_phone)
    VALUES (p_contact_type, p_email, p_mobile_phone)
    RETURNING serial_id INTO v_contact_id;
    RETURN v_contact_id;
END;
$$ LANGUAGE plpgsql;


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


-- Index to speed up queries that filter by location_source
CREATE INDEX IF NOT EXISTS idx_geo_locations_location_source ON geo_locations (location_source) WHERE is_active = TRUE;
-- Index to speed up queries that filter by currency: recorded_at.
CREATE INDEX IF NOT EXISTS idx_geo_locations_recorded_at ON geo_locations (recorded_at DESC) WHERE is_active = TRUE;


CREATE OR REPLACE FUNCTION insert_geo_location(
    p_location_source INTEGER,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_recorded_at TIMESTAMP WITH TIME ZONE
) RETURNS BIGINT AS $$
DECLARE
    v_location_id BIGINT;
BEGIN
    INSERT INTO geo_locations (location_source, latitude, longitude, recorded_at)
    VALUES (p_location_source, p_latitude, p_longitude, p_recorded_at)
    RETURNING serial_id INTO v_location_id;
    RETURN v_location_id;
END;
$$ LANGUAGE plpgsql;



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


-- Partial index to speed up queries that filter by is_active
-- This index is useful for queries that retrieve only active addresses.
CREATE INDEX IF NOT EXISTS idx_addresses_serial_id ON addresses (serial_id DESC) WHERE is_active = TRUE; 


CREATE OR REPLACE FUNCTION insert_address(
    p_address_contact_ids INTEGER [],
    p_street_1 VARCHAR(255),
    p_street_2 VARCHAR(255),
    p_city VARCHAR(100),
    p_state VARCHAR(50),
    p_postal_code VARCHAR(20),
    p_country VARCHAR(100),
    p_address_type INTEGER,
    p_location_id BIGINT
) RETURNS INTEGER AS $$
DECLARE
    v_address_id INTEGER;
BEGIN
    INSERT INTO addresses (
        address_contact_ids, street_1, street_2, city, state, postal_code, country, address_type, location_id
    ) VALUES (
        p_address_contact_ids, p_street_1, p_street_2, p_city, p_state, p_postal_code, p_country, p_address_type, p_location_id
    )
    RETURNING serial_id INTO v_address_id;
    RETURN v_address_id;
END;
$$ LANGUAGE plpgsql;


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

CREATE OR REPLACE FUNCTION insert_authority(
    p_authority_name VARCHAR(255),
    p_dot_number VARCHAR(20),
    p_address_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_authority_id INTEGER;
BEGIN
    INSERT INTO authorities (authority_name, dot_number, address_id)
    VALUES (p_authority_name, p_dot_number, p_address_id)
    RETURNING serial_id INTO v_authority_id;
    RETURN v_authority_id;
END;
$$ LANGUAGE plpgsql;


-- Master Divisions Table
CREATE TABLE IF NOT EXISTS divisions (
    serial_id SERIAL PRIMARY KEY,
    division_name VARCHAR(255) NOT NULL,
    tms_terminal_id INTEGER NOT NULL,
    authority_id INTEGER NOT NULL,
    FOREIGN KEY (authority_id) REFERENCES authorities(serial_id),
    address_id INTEGER NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(serial_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION insert_division(
    p_division_name VARCHAR(255),
    p_tms_terminal_id INTEGER,
    p_authority_id INTEGER,
    p_address_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_division_id INTEGER;
BEGIN
    INSERT INTO divisions (division_name, tms_terminal_id, authority_id, address_id)
    VALUES (p_division_name, p_tms_terminal_id, p_authority_id, p_address_id)
    RETURNING serial_id INTO v_division_id;
    RETURN v_division_id;
END;
$$ LANGUAGE plpgsql;

-- Insert an unavailable division record
-- This record is used to represent a division that is not currently known or available.
INSERT INTO divisions (serial_id, division_name, tms_terminal_id, authority_id, address_id)
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


CREATE OR REPLACE FUNCTION insert_terminal(
    p_tms_id VARCHAR(255),
    p_terminal_name VARCHAR(255),
    p_division_id INTEGER,
    p_address_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_terminal_id INTEGER;
BEGIN
    INSERT INTO terminals (tms_id, terminal_name, division_id, address_id)
    VALUES (p_tms_id, p_terminal_name, p_division_id, p_address_id)
    RETURNING serial_id INTO v_terminal_id;
    RETURN v_terminal_id;
END;
$$ LANGUAGE plpgsql;


-- MASTER Trailer Table
CREATE TABLE IF NOT EXISTS trailers (
    serial_id SERIAL PRIMARY KEY,
    tms_id VARCHAR(255) NOT NULL,
    trailer_name VARCHAR(20) NOT NULL,
    terminal_id INTEGER NOT NULL DEFAULT 0, -- 0 indicates no terminal
    FOREIGN KEY (terminal_id) REFERENCES terminals(serial_id),
    division_id INTEGER NOT NULL DEFAULT 0, -- 0 indicates no division
    FOREIGN KEY (division_id) REFERENCES divisions(serial_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE OR REPLACE FUNCTION insert_trailer(
    p_tms_id VARCHAR(255),
    p_trailer_name VARCHAR(20),
    p_terminal_id INTEGER,
    p_division_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_trailer_id INTEGER;
BEGIN
    INSERT INTO trailers (tms_id, trailer_name, terminal_id, division_id)
    VALUES (p_tms_id, p_trailer_name, p_terminal_id, p_division_id)
    RETURNING serial_id INTO v_trailer_id;
    RETURN v_trailer_id;
END;
$$ LANGUAGE plpgsql;


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
);


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


CREATE OR REPLACE FUNCTION insert_truck(
    p_tms_id VARCHAR(255),
    p_telematic_id VARCHAR(255),
    p_truck_name VARCHAR(255),
    p_division_id INTEGER,
    p_terminal_id INTEGER,
    p_current_driver_id INTEGER,
    p_trailer_1_id INTEGER,
    p_trailer_2_id INTEGER,
    p_current_location_id BIGINT,
    p_vin VARCHAR(17),
    p_license_plate VARCHAR(15),
    p_license_plate_state VARCHAR(3)
) RETURNS INTEGER AS $$
DECLARE
    v_truck_id INTEGER;
BEGIN
    INSERT INTO trucks (
        tms_id, telematic_id, truck_name, division_id, terminal_id, current_driver_id, trailer_1_id, trailer_2_id, current_location_id, vin, license_plate, license_plate_state
    ) VALUES (
        p_tms_id, p_telematic_id, p_truck_name, p_division_id, p_terminal_id, p_current_driver_id, p_trailer_1_id, p_trailer_2_id, p_current_location_id, p_vin, p_license_plate, p_license_plate_state
    )
    RETURNING serial_id INTO v_truck_id;
    RETURN v_truck_id;
END;
$$ LANGUAGE plpgsql;

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



CREATE OR REPLACE FUNCTION insert_driver(
    p_first_name VARCHAR(50),
    p_last_name VARCHAR(100),
    p_license_number VARCHAR(40),
    p_license_state VARCHAR(25),
    p_division_id INTEGER,
    p_terminal_id INTEGER,
    p_tms_id VARCHAR(255),
    p_telematic_id VARCHAR(255),
    p_current_truck_serial_id INTEGER,
    p_contact_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_driver_id INTEGER;
BEGIN
    INSERT INTO drivers (
        first_name, last_name, license_number, license_state, division_id, terminal_id, tms_id, telematic_id, current_truck_serial_id, contact_id
    ) VALUES (
        p_first_name, p_last_name, p_license_number, p_license_state, p_division_id, p_terminal_id, p_tms_id, p_telematic_id, p_current_truck_serial_id, p_contact_id
    )
    RETURNING serial_id INTO v_driver_id;
    RETURN v_driver_id;
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION insert_stop(
    p_address_id INTEGER,
    p_stop_type_id INTEGER,
    p_stop_purchase_orders VARCHAR(255) [],
    p_stop_sequence INTEGER,
    p_tms_pro_number VARCHAR(255),
    p_stop_driver_id INTEGER,
    p_stop_truck_id INTEGER,
    p_sched_arrival TIMESTAMP WITH TIME ZONE,
    p_actl_arrive TIMESTAMP WITH TIME ZONE,
    p_sched_dept TIMESTAMP WITH TIME ZONE,
    p_actl_dept TIMESTAMP WITH TIME ZONE,
    p_is_completed BOOLEAN
) RETURNS BIGINT AS $$
DECLARE
    v_stop_id BIGINT;
BEGIN
    INSERT INTO stops (
        address_id, stop_type_id, stop_purchase_orders, stop_sequence, tms_pro_number, stop_driver_id, stop_truck_id, sched_arrival, actl_arrive, sched_dept, actl_dept, is_completed
    ) VALUES (
        p_address_id, p_stop_type_id, p_stop_purchase_orders, p_stop_sequence, p_tms_pro_number, p_stop_driver_id, p_stop_truck_id, p_sched_arrival, p_actl_arrive, p_sched_dept, p_actl_dept, p_is_completed
    )
    RETURNING serial_id INTO v_stop_id;
    RETURN v_stop_id;
END;
$$ LANGUAGE plpgsql;


-- Master Loads Table
CREATE TABLE IF NOT EXISTS loads (
    serial_id SERIAL PRIMARY KEY,
    load_purchase_orders VARCHAR(255) [],
    load_stop_ids BIGINT [],
    tms_pro_number VARCHAR(255) UNIQUE,
    assigned_driver_ids INTEGER [],
    assigned_truck_ids INTEGER [],
    trailer_ids INTEGER [],
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
CREATE INDEX IF NOT EXISTS idx_loads_assigned_driver_ids_gin ON loads USING GIN (assigned_driver_ids); -- GIN index for array column
CREATE INDEX IF NOT EXISTS idx_loads_assigned_truck_ids_gin ON loads USING GIN (assigned_truck_ids); -- GIN index for array column

CREATE OR REPLACE FUNCTION insert_load(
    p_load_purchase_orders VARCHAR(255) [],
    p_load_stop_ids BIGINT [],
    p_tms_pro_number VARCHAR(255),
    p_assigned_driver_ids INTEGER [],
    p_assigned_truck_ids INTEGER [],
    p_trailer_ids INTEGER [],
    p_terminal_id INTEGER,
    p_division_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_load_id INTEGER;
BEGIN
    INSERT INTO loads (
        load_purchase_orders, load_stop_ids, tms_pro_number, assigned_driver_ids, assigned_truck_ids, trailer_ids, terminal_id, division_id
    ) VALUES (
        p_load_purchase_orders, p_load_stop_ids, p_tms_pro_number, p_assigned_driver_ids, p_assigned_truck_ids, p_trailer_ids, p_terminal_id, p_division_id
    )
    RETURNING serial_id INTO v_load_id;
    RETURN v_load_id;
END;
$$ LANGUAGE plpgsql;




