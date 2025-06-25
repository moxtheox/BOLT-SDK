-- src/database/sql/10-create-tables.sql

-- Master table for all address types
CREATE TABLE IF NOT EXISTS address_types (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this address type
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Master table for all addresses, referenced by stops and terminals
CREATE TABLE IF NOT EXISTS addresses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    street1 VARCHAR(255),
    street2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(3), -- Adjusted to VARCHAR(3) for North American coverage (e.g., TN, PA, NC)
    postal_code VARCHAR(20),
    phone VARCHAR(50),
    email VARCHAR(255),
    comments TEXT,
    local_directions TEXT,
    is_active BOOLEAN,
    parent_address_id INTEGER, -- Self-referencing FK to addresses(id) for hierarchical addresses
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    terminal_id INTEGER, -- FK to terminals(id) if this address is associated with a terminal (from shipTo)
    address_type_id INTEGER, -- FK to address_types(id) for the type of address (from shipTo.type)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Master table for all terminals, which are essentially specific addresses
CREATE TABLE IF NOT EXISTS terminals (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this terminal
    address_id INTEGER NOT NULL, -- FK to addresses(id) for the terminal's physical address
    name VARCHAR(255), -- Denormalized for convenience, or strictly from terminal API.
    code VARCHAR(100),
    type VARCHAR(50), -- E.g., from the terminal's 'type' field in the API return (often null)
    is_active BOOLEAN,
    maintenance_emails TEXT, -- For "MAINTENANCE_EMAILS" field found in terminal API
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Master table for stop types
CREATE TABLE IF NOT EXISTS stop_types (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this stop type
    name VARCHAR(255) UNIQUE NOT NULL,
    rules JSONB, -- Store the 'rules' object as JSONB for flexibility
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Master table for data suppliers (ELDs)
CREATE TABLE IF NOT EXISTS data_suppliers (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this data supplier
    name VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN, -- Indicates if the data supplier is active (from ELD return)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table for breadcrumb events
CREATE TABLE IF NOT EXISTS breadcrumbs (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this breadcrumb
    data_supplier_id INTEGER, -- FK to data_suppliers(id)

    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    speed NUMERIC(10, 2), -- Assuming speed can be decimal
    heading INTEGER, -- Degrees
    temperature NUMERIC(10, 2), -- Assuming temperature can be decimal
    recorded_at TIMESTAMP WITH TIME ZONE,
    received_at TIMESTAMP WITH TIME ZONE,
    is_ignition_on BOOLEAN,
    odometer NUMERIC(15, 2), -- Assuming odometer can be large and decimal
    name TEXT, -- E.g., "1.20 mi. from NASHVILLE, TN" (from load_board.current_location.name)

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() -- Timestamp when *this record* was created in your DB
);

INSERT INTO breadcrumbs (tms_id, data_supplier_id, latitude, longitude, speed, heading,
                         temperature, recorded_at, received_at, is_ignition_on, odometer, name)
VALUES (0, NULL, 0.0, 0.0, 0.0, 0, 0.0, '1970-01-01 00:00:00+00', '1970-01-01 00:00:00+00', FALSE, 0.0, 'Unknown Location')
ON CONFLICT (tms_id) DO NOTHING; -- Ensure it's only inserted once

-- Master table for owners (e.g., truck owners, general owners)
CREATE TABLE IF NOT EXISTS owners (
    id INTEGER PRIMARY KEY,
    tms_id INTEGER UNIQUE, -- The original ID from the TMS for this owner (can be null for 'No Owner')
    name VARCHAR(255) NOT NULL UNIQUE, -- E.g., "No Owner", "Company Name", "Individual Name" (from truckowners.name)
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),
    address_id INTEGER, -- FK to addresses(id) if owner has a physical address (from truckowners data)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO owners (id, name, tms_id)
VALUES (-1, 'No Owner', NULL) -- Default owner for trucks/trailers without a specific owner
ON CONFLICT (id) DO NOTHING;

-- Master table for trucks
CREATE TABLE IF NOT EXISTS trucks (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this truck
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN,
    last_dot_inspection DATE,
    last_in_service TIMESTAMP WITH TIME ZONE,
    last_out_of_service TIMESTAMP WITH TIME ZONE,
    is_cross_terminal BOOLEAN,
    is_ifta BOOLEAN,
    insurance_expiration DATE,
    truck_type_name VARCHAR(100),
    spec_year INTEGER,
    spec_price NUMERIC(10, 2),
    spec_vin VARCHAR(50) UNIQUE,
    spec_model VARCHAR(100),
    spec_make VARCHAR(100),
    reg_expiration DATE,
    reg_country VARCHAR(100),
    reg_state VARCHAR(3),
    reg_tag VARCHAR(100),
    owned_by_id INTEGER NOT NULL DEFAULT -1, -- FK to owners(id)
    primary_terminal_id INTEGER, -- FK to terminals(id)
    last_breadcrumb_id INTEGER, -- FK to breadcrumbs(id) for the latest known location
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- Master table for trailers
CREATE TABLE IF NOT EXISTS trailers (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this trailer
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN,
    last_dot_inspection DATE,
    last_in_service TIMESTAMP WITH TIME ZONE,
    last_out_of_service TIMESTAMP WITH TIME ZONE,
    is_cross_terminal BOOLEAN, 
    is_ifta BOOLEAN,
    insurance_expiration DATE,
    spec_year INTEGER,
    spec_price NUMERIC(10, 2),
    spec_vin VARCHAR(50) UNIQUE,
    spec_model VARCHAR(100),
    spec_make VARCHAR(100),
    reg_expiration DATE,
    reg_country VARCHAR(100),
    reg_state VARCHAR(3),
    reg_tag VARCHAR(100),
    owned_by_id INTEGER NOT NULL DEFAULT -1, -- FK to owners(id)
    primary_terminal_id INTEGER, -- FK to terminals(id)
    last_breadcrumb_id INTEGER, -- FK to breadcrumbs(id) for the latest known location
    type JSONB, -- The 'type' object, captured as JSONB (was empty in example, but good for future proofing)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- Master table for users (employees/drivers)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this user
    employee_id VARCHAR(50) UNIQUE, -- Can be distinct or identical to user_name
    first_name VARCHAR(100),
    middle_name VARCHAR(100),
    last_name VARCHAR(100),
    suffix VARCHAR(50),
    user_name VARCHAR(100), -- Can be distinct or identical to employee_id
    name VARCHAR(255), -- Full name
    is_active BOOLEAN,
    landing_path TEXT,
    personal_mobile_phone VARCHAR(50),
    personal_home_phone VARCHAR(50),
    personal_email VARCHAR(255),
    personal_birthday DATE,
    work_mobile_phone VARCHAR(50),
    work_desk_phone VARCHAR(50),
    work_email VARCHAR(255),
    work_hire_date DATE,
    work_termination_date DATE,
    work_review_date DATE,
    permissions JSONB, -- Store complex permissions as JSONB
    primary_terminal_id INTEGER, -- FK to terminals(id) for the user's primary terminal
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link table for users and secondary terminals (many-to-many relationship)
CREATE TABLE IF NOT EXISTS user_terminals (
    user_id INTEGER NOT NULL, -- FK to users(id)
    terminal_id INTEGER NOT NULL, -- FK to terminals(id)
    permission_type VARCHAR(20) NOT NULL, -- E.g., 'view', 'modify'
    PRIMARY KEY (user_id, terminal_id, permission_type), -- Composite primary key for uniqueness
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table for load statuses
CREATE TABLE IF NOT EXISTS load_statuses (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this status
    code VARCHAR(50) UNIQUE NOT NULL, -- E.g., "PENDING", "INTRANSIT"
    name VARCHAR(255) NOT NULL, -- E.g., "Pending", "In-Transit"
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table for load categories
CREATE TABLE IF NOT EXISTS load_categories (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this category
    name VARCHAR(255) UNIQUE NOT NULL, -- E.g., "3rd Party", "Backhaul"
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table for individual stops
CREATE TABLE IF NOT EXISTS stops (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- Original ID from TMS

    location_id INTEGER, -- FK to addresses(id) for the stop's location
    stop_type_id INTEGER, -- FK to stop_types(id) for the type of stop (e.g., Pickup, Delivery)

    number INTEGER, -- Stop number within a load/shipment
    contact TEXT,
    comment TEXT,
    bill_of_lading TEXT,
    is_active BOOLEAN,

    time_from_last_stop INTEGER, -- In minutes, from last stop
    distance_from_last_stop NUMERIC(10, 3), -- In miles, from last stop

    actual_arrive_at TIMESTAMP WITH TIME ZONE,
    actual_depart_at TIMESTAMP WITH TIME ZONE,
    scheduled_arrive_at TIMESTAMP WITH TIME ZONE,
    scheduled_depart_at TIMESTAMP WITH TIME ZONE,

    aggregates JSONB, -- Store aggregate values (linear_feet, pallets_out, etc.) as JSONB
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table for Purchase Orders (normalized from shipment.purchase_order)
CREATE TABLE IF NOT EXISTS purchase_orders (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this PO
    name VARCHAR(255), -- E.g., "Unknown", or the PO number
    is_active BOOLEAN,
    agent_id INTEGER, -- FK to users(id) if 'agent' is a user
    bill_to_id INTEGER, -- FK to addresses(id) if 'bill_to' is an address
    reviewed_by_id INTEGER, -- FK to users(id) if 'reviewed_by' is a user
    rate_rollup JSONB, -- Store 'rate_rollup' object as JSONB
    distance JSONB, -- Store 'distance' object as JSONB
    line_items JSONB, -- Store 'line_items' as JSONB (can be further normalized if needed)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Main Shipments Table
CREATE TABLE IF NOT EXISTS shipments (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this shipment
    name VARCHAR(255), -- The 'name' field from the shipment object (can be empty)

    -- Foreign Keys
    first_stop_id INTEGER, -- FK to stops(id) for the first stop of the shipment
    last_stop_id INTEGER,  -- FK to stops(id) for the last stop of the shipment
    purchase_order_id INTEGER, -- FK to purchase_orders(id)
    hauled_for_id INTEGER, -- If 'hauled_for' refers to an existing entity (e.g., customer, user)
    origin_created_by_id INTEGER, -- FK to users(id) if 'created_by' is a user
    current_breadcrumb_id INTEGER, -- FK to breadcrumbs(id) for the current location of the assigned truck/trailer

    -- Direct fields from the shipment object
    is_backhaul BOOLEAN,
    is_active BOOLEAN,
    is_csa BOOLEAN,
    is_edi BOOLEAN,

    -- Complex objects as JSONB
    handling_rules JSONB, -- Store 'handling_rules' object as JSONB
    edi JSONB, -- Placeholder for 'edi' object if it contains data

    -- Origin metadata
    origin_created_at TIMESTAMP WITH TIME ZONE, -- From origin.created_at

    -- Raw JSON column for the entire shipment, useful for debugging
    raw_json JSONB,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Main Loads Table
CREATE TABLE IF NOT EXISTS loads (
    id SERIAL PRIMARY KEY,
    tms_id INTEGER UNIQUE NOT NULL, -- The original ID from the TMS for this load

    load_template VARCHAR(255), -- From load_board.load_template

    -- Foreign Key columns
    current_stop_id INTEGER, -- FK to stops(id) for the current stop
    next_stop_id INTEGER, -- FK to stops(id) for the next stop
    first_stop_id INTEGER, -- FK to stops(id) for the first stop (from load_board.first_stop)
    last_stop_id INTEGER, -- FK to stops(id) for the last stop (from load_board.last_stop)

    truck_id INTEGER, -- FK to trucks(id)
    creator_user_id INTEGER, -- FK to users(id) for the load creator
    status_id INTEGER, -- FK to load_statuses(id) (from load_board.status)
    hauling_terminal_id INTEGER, -- FK to terminals(id) (from load_board.hauling_terminal_id)
    origination_terminal_id INTEGER, -- FK to terminals(id) (from load_board.origination_terminal_id)
    category_id INTEGER, -- FK to load_categories(id) (from load_board.category)
    first_shipment_main_id INTEGER, -- This will be the `id` of the *main* shipment associated with this load
    current_breadcrumb_id INTEGER, -- FK to breadcrumbs(id) for the current location of the assigned truck/trailer

    comment_count INTEGER, -- From load_board.comment_count
    is_active BOOLEAN, -- From load_board.is_active
    first_purchase_order VARCHAR(255), -- From load_board.first_purchase_order

    summary JSONB, -- Store load_board.summary object as JSONB
    raw_json JSONB, -- Raw JSON for the entire load object, useful for debugging

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link table for loads and drivers (many-to-many)
CREATE TABLE IF NOT EXISTS load_drivers (
    load_id INTEGER NOT NULL, -- FK to loads(id)
    driver_user_id INTEGER NOT NULL, -- FK to users(id)
    PRIMARY KEY (load_id, driver_user_id), -- Composite primary key
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table for Load Revenue (normalized from load_board.summary.revenue array)
CREATE TABLE IF NOT EXISTS load_revenues (
    id SERIAL UNIQUE NOT NULL,
    load_id INTEGER NOT NULL, -- FK to loads(id)
    type VARCHAR(50) NOT NULL, -- E.g., 'front_haul', 'back_haul'
    fuel_surcharge NUMERIC(10, 2),
    miscellaneous NUMERIC(10, 2),
    accessorial NUMERIC(10, 2),
    line_haul NUMERIC(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (id, load_id, type) -- Composite primary key to ensure uniqueness
);

-- Link table for loads and shipments (many-to-many)
CREATE TABLE IF NOT EXISTS load_shipments (
    load_id INTEGER NOT NULL, -- FK to loads(id)
    shipment_id INTEGER NOT NULL, -- FK to shipments(id)
    PRIMARY KEY (load_id, shipment_id), -- Composite primary key
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link table for shipments and stops (many-to-many, since stop_ids is an array)
CREATE TABLE IF NOT EXISTS shipment_stops (
    shipment_id INTEGER NOT NULL, -- FK to shipments(id)
    stop_id INTEGER NOT NULL, -- FK to stops(id)
    stop_order INTEGER NOT NULL, -- To preserve the order of stops within a shipment
    PRIMARY KEY (shipment_id, stop_id), -- Composite primary key
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link table for loads and trailers (many-to-many, based on loads.trailers array)
CREATE TABLE IF NOT EXISTS load_trailers (
    load_id INTEGER NOT NULL, -- FK to loads(id)
    trailer_id INTEGER NOT NULL, -- FK to trailers(id)
    PRIMARY KEY (load_id, trailer_id), -- Composite primary key
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);