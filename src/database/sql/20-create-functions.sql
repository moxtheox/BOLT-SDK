-- src/database/sql/20-create-functions.sql

-- Function to upsert data into the address_types table
CREATE OR REPLACE FUNCTION upsert_address_type(
    p_tms_id INTEGER,
    p_code VARCHAR(50),
    p_name VARCHAR(255)
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO address_types (tms_id, code, name)
    VALUES (p_tms_id, p_code, p_name)
    ON CONFLICT (tms_id) DO UPDATE
    SET
        code = EXCLUDED.code,
        name = EXCLUDED.name,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the data_suppliers table
CREATE OR REPLACE FUNCTION upsert_data_supplier(
    p_tms_id INTEGER,
    p_name VARCHAR(255),
    p_is_active BOOLEAN
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO data_suppliers (tms_id, name, is_active)
    VALUES (p_tms_id, p_name, p_is_active)
    ON CONFLICT (tms_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        is_active = EXCLUDED.is_active,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the stop_types table
CREATE OR REPLACE FUNCTION upsert_stop_type(
    p_tms_id INTEGER,
    p_name VARCHAR(255),
    p_rules JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO stop_types (tms_id, name, rules)
    VALUES (p_tms_id, p_name, p_rules)
    ON CONFLICT (tms_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        rules = EXCLUDED.rules,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the addresses table
CREATE OR REPLACE FUNCTION upsert_address(
    p_name VARCHAR(255),
    p_street1 VARCHAR(255),
    p_street2 VARCHAR(255),
    p_city VARCHAR(100),
    p_state VARCHAR(3),
    p_postal_code VARCHAR(20),
    p_phone VARCHAR(50),
    p_email VARCHAR(255),
    p_comments TEXT,
    p_local_directions TEXT,
    p_is_active BOOLEAN,
    p_parent_address_tms_id INTEGER, -- TMS ID for parent address
    p_latitude NUMERIC(10, 7),
    p_longitude NUMERIC(10, 7),
    p_terminal_tms_id INTEGER, -- TMS ID for associated terminal
    p_address_type_tms_id INTEGER -- TMS ID for address type
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_parent_address_id INTEGER;
    v_terminal_id INTEGER;
    v_address_type_id INTEGER;
BEGIN
    -- Resolve parent_address_id
    IF p_parent_address_tms_id IS NOT NULL THEN
        SELECT id INTO v_parent_address_id FROM addresses WHERE tms_id = p_parent_address_tms_id;
    END IF;

    -- Resolve terminal_id
    IF p_terminal_tms_id IS NOT NULL THEN
        SELECT id INTO v_terminal_id FROM terminals WHERE tms_id = p_terminal_tms_id;
    END IF;

    -- Resolve address_type_id
    IF p_address_type_tms_id IS NOT NULL THEN
        SELECT id INTO v_address_type_id FROM address_types WHERE tms_id = p_address_type_tms_id;
    END IF;

    INSERT INTO addresses (
        name, street1, street2, city, state, postal_code, phone, email, comments,
        local_directions, is_active, parent_address_id, latitude, longitude,
        terminal_id, address_type_id
    )
    VALUES (
        p_name, p_street1, p_street2, p_city, p_state, p_postal_code, p_phone, p_email, p_comments,
        p_local_directions, p_is_active, v_parent_address_id, p_latitude, p_longitude,
        v_terminal_id, v_address_type_id
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        street1 = EXCLUDED.street1,
        street2 = EXCLUDED.street2,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        postal_code = EXCLUDED.postal_code,
        phone = EXCLUDED.phone,
        email = EXCLUDED.email,
        comments = EXCLUDED.comments,
        local_directions = EXCLUDED.local_directions,
        is_active = EXCLUDED.is_active,
        parent_address_id = EXCLUDED.parent_address_id, -- Note: This assumes parent_address_id can change
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        terminal_id = EXCLUDED.terminal_id,
        address_type_id = EXCLUDED.address_type_id,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the terminals table
CREATE OR REPLACE FUNCTION upsert_terminal(
    p_tms_id INTEGER,
    p_address_tms_id INTEGER, -- TMS ID for the terminal's address
    p_name VARCHAR(255),
    p_code VARCHAR(100),
    p_type VARCHAR(50),
    p_is_active BOOLEAN,
    p_maintenance_emails TEXT
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_address_id INTEGER;
BEGIN
    -- Resolve the address_id. The address record MUST already exist or be upserted prior.
    SELECT id INTO v_address_id FROM addresses WHERE tms_id = p_address_tms_id;

    -- If the address doesn't exist, this function will raise an error (good, as it's a NOT NULL FK)
    IF v_address_id IS NULL THEN
        RAISE EXCEPTION 'Address with tms_id % not found for terminal %', p_address_tms_id, p_tms_id;
    END IF;

    INSERT INTO terminals (
        tms_id, address_id, name, code, type, is_active, maintenance_emails
    )
    VALUES (
        p_tms_id, v_address_id, p_name, p_code, p_type, p_is_active, p_maintenance_emails
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        address_id = EXCLUDED.address_id,
        name = EXCLUDED.name,
        code = EXCLUDED.code,
        type = EXCLUDED.type,
        is_active = EXCLUDED.is_active,
        maintenance_emails = EXCLUDED.maintenance_emails,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the owners table
CREATE OR REPLACE FUNCTION upsert_owner(
    p_tms_id INTEGER,
    p_name VARCHAR(255),
    p_contact_phone VARCHAR(50),
    p_contact_email VARCHAR(255),
    p_address_tms_id INTEGER, -- TMS ID for the owner's address
    p_is_active BOOLEAN
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_address_id INTEGER;
BEGIN
    -- Resolve the address_id if provided
    IF p_address_tms_id IS NOT NULL THEN
        SELECT id INTO v_address_id FROM addresses WHERE tms_id = p_address_tms_id;
        -- If the address doesn't exist, it implies an issue in data ingestion order
        IF v_address_id IS NULL THEN
            RAISE WARNING 'Address with tms_id % not found for owner % (TMS ID: %). address_id will be set to NULL.', p_address_tms_id, p_name, p_tms_id;
        END IF;
    END IF;

    INSERT INTO owners (
        tms_id, name, contact_phone, contact_email, address_id, is_active
    )
    VALUES (
        p_tms_id, p_name, p_contact_phone, p_contact_email, v_address_id, p_is_active
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        contact_phone = EXCLUDED.contact_phone,
        contact_email = EXCLUDED.contact_email,
        address_id = EXCLUDED.address_id,
        is_active = EXCLUDED.is_active,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the users table
CREATE OR REPLACE FUNCTION upsert_user(
    p_tms_id INTEGER,
    p_employee_id VARCHAR(50),
    p_first_name VARCHAR(100),
    p_middle_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_suffix VARCHAR(50),
    p_user_name VARCHAR(100),
    p_name VARCHAR(255),
    p_is_active BOOLEAN,
    p_landing_path TEXT,
    p_personal_mobile_phone VARCHAR(50),
    p_personal_home_phone VARCHAR(50),
    p_personal_email VARCHAR(255),
    p_personal_birthday DATE,
    p_work_mobile_phone VARCHAR(50),
    p_work_desk_phone VARCHAR(50),
    p_work_email VARCHAR(255),
    p_work_hire_date DATE,
    p_work_termination_date DATE,
    p_work_review_date DATE,
    p_permissions JSONB,
    p_primary_terminal_tms_id INTEGER -- TMS ID for primary terminal
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_primary_terminal_id INTEGER;
BEGIN
    -- Resolve primary_terminal_id
    IF p_primary_terminal_tms_id IS NOT NULL THEN
        SELECT id INTO v_primary_terminal_id FROM terminals WHERE tms_id = p_primary_terminal_tms_id;
        IF v_primary_terminal_id IS NULL THEN
            RAISE WARNING 'Terminal with tms_id % not found for user % (TMS ID: %u). primary_terminal_id will be set to NULL.', p_primary_terminal_tms_id, p_name, p_tms_id;
        END IF;
    END IF;

    INSERT INTO users (
        tms_id, employee_id, first_name, middle_name, last_name, suffix, user_name, name,
        is_active, landing_path, personal_mobile_phone, personal_home_phone, personal_email,
        personal_birthday, work_mobile_phone, work_desk_phone, work_email, work_hire_date,
        work_termination_date, work_review_date, permissions, primary_terminal_id
    )
    VALUES (
        p_tms_id, p_employee_id, p_first_name, p_middle_name, p_last_name, p_suffix, p_user_name, p_name,
        p_is_active, p_landing_path, p_personal_mobile_phone, p_personal_home_phone, p_personal_email,
        p_personal_birthday, p_work_mobile_phone, p_work_desk_phone, p_work_email, p_work_hire_date,
        p_work_termination_date, p_work_review_date, p_permissions, v_primary_terminal_id
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        employee_id = EXCLUDED.employee_id,
        first_name = EXCLUDED.first_name,
        middle_name = EXCLUDED.middle_name,
        last_name = EXCLUDED.last_name,
        suffix = EXCLUDED.suffix,
        user_name = EXCLUDED.user_name,
        name = EXCLUDED.name,
        is_active = EXCLUDED.is_active,
        landing_path = EXCLUDED.landing_path,
        personal_mobile_phone = EXCLUDED.personal_mobile_phone,
        personal_home_phone = EXCLUDED.personal_home_phone,
        personal_email = EXCLUDED.personal_email,
        personal_birthday = EXCLUDED.personal_birthday,
        work_mobile_phone = EXCLUDED.work_mobile_phone,
        work_desk_phone = EXCLUDED.work_desk_phone,
        work_email = EXCLUDED.work_email,
        work_hire_date = EXCLUDED.work_hire_date,
        work_termination_date = EXCLUDED.work_termination_date,
        work_review_date = EXCLUDED.work_review_date,
        permissions = EXCLUDED.permissions,
        primary_terminal_id = EXCLUDED.primary_terminal_id,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the breadcrumbs table
CREATE OR REPLACE FUNCTION upsert_breadcrumb(
    p_tms_id INTEGER,
    p_data_supplier_tms_id INTEGER, -- TMS ID for the data supplier
    p_latitude NUMERIC(10, 7),
    p_longitude NUMERIC(10, 7),
    p_speed NUMERIC(10, 2),
    p_heading INTEGER,
    p_temperature NUMERIC(10, 2),
    p_recorded_at TIMESTAMP WITH TIME ZONE,
    p_received_at TIMESTAMP WITH TIME ZONE,
    p_is_ignition_on BOOLEAN,
    p_odometer NUMERIC(15, 2),
    p_name TEXT
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_data_supplier_id INTEGER;
BEGIN
    -- Resolve data_supplier_id
    IF p_data_supplier_tms_id IS NOT NULL THEN
        SELECT id INTO v_data_supplier_id FROM data_suppliers WHERE tms_id = p_data_supplier_tms_id;
        IF v_data_supplier_id IS NULL THEN
            RAISE WARNING 'Data supplier with tms_id % not found for breadcrumb (TMS ID: %)', p_data_supplier_tms_id, p_tms_id;
        END IF;
    END IF;

    INSERT INTO breadcrumbs (
        tms_id, data_supplier_id, latitude, longitude, speed, heading, temperature,
        recorded_at, received_at, is_ignition_on, odometer, name
    )
    VALUES (
        p_tms_id, v_data_supplier_id, p_latitude, p_longitude, p_speed, p_heading, p_temperature,
        p_recorded_at, p_received_at, p_is_ignition_on, p_odometer, p_name
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        data_supplier_id = EXCLUDED.data_supplier_id,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        speed = EXCLUDED.speed,
        heading = EXCLUDED.heading,
        temperature = EXCLUDED.temperature,
        recorded_at = EXCLUDED.recorded_at,
        received_at = EXCLUDED.received_at,
        is_ignition_on = EXCLUDED.is_ignition_on,
        odometer = EXCLUDED.odometer,
        name = EXCLUDED.name
        -- breadcrumbs do not typically have an updated_at as they are immutable events
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the trucks table
CREATE OR REPLACE FUNCTION upsert_truck(
    p_tms_id INTEGER,
    p_name VARCHAR(255),
    p_is_active BOOLEAN,
    p_last_dot_inspection DATE,
    p_last_in_service TIMESTAMP WITH TIME ZONE,
    p_last_out_of_service TIMESTAMP WITH TIME ZONE,
    p_is_cross_terminal BOOLEAN,
    p_is_ifta BOOLEAN,
    p_insurance_expiration DATE,
    p_truck_type_name VARCHAR(100),
    p_spec_year INTEGER,
    p_spec_price NUMERIC(10, 2),
    p_spec_vin VARCHAR(50),
    p_spec_model VARCHAR(100),
    p_spec_make VARCHAR(100),
    p_reg_expiration DATE,
    p_reg_country VARCHAR(100),
    p_reg_state VARCHAR(3),
    p_reg_tag VARCHAR(100),
    p_owned_by_tms_id INTEGER,      -- TMS ID for the owner
    p_primary_terminal_tms_id INTEGER, -- TMS ID for the primary terminal
    p_last_breadcrumb_tms_id INTEGER   -- TMS ID for the last breadcrumb (can be NULL)
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_owned_by_id INTEGER;
    v_primary_terminal_id INTEGER;
    v_last_breadcrumb_id INTEGER;
    v_unknown_breadcrumb_id INTEGER; -- To store the ID of the 'Unknown Location' breadcrumb
BEGIN
    -- Get the ID of the 'Unknown Location' breadcrumb (tms_id = 0)
    SELECT id INTO v_unknown_breadcrumb_id FROM breadcrumbs WHERE tms_id = 0;

    -- Resolve owned_by_id
    IF p_owned_by_tms_id IS NOT NULL THEN
        SELECT id INTO v_owned_by_id FROM owners WHERE tms_id = p_owned_by_tms_id;
        IF v_owned_by_id IS NULL THEN
            RAISE WARNING 'Owner with tms_id % not found for truck % (TMS ID: %). Defaulting to "No Owner".', p_owned_by_tms_id, p_name, p_tms_id;
            SELECT id INTO v_owned_by_id FROM owners WHERE name = 'No Owner' AND tms_id IS NULL;
        END IF;
    ELSE
        SELECT id INTO v_owned_by_id FROM owners WHERE name = 'No Owner' AND tms_id IS NULL;
    END IF;

    -- Resolve primary_terminal_id
    IF p_primary_terminal_tms_id IS NOT NULL THEN
        SELECT id INTO v_primary_terminal_id FROM terminals WHERE tms_id = p_primary_terminal_tms_id;
        IF v_primary_terminal_id IS NULL THEN
            RAISE WARNING 'Terminal with tms_id % not found for truck % (TMS ID: %). primary_terminal_id will be set to NULL.', p_primary_terminal_tms_id, p_name, p_tms_id;
        END IF;
    END IF;

    -- Resolve last_breadcrumb_id
    IF p_last_breadcrumb_tms_id IS NOT NULL THEN
        SELECT id INTO v_last_breadcrumb_id FROM breadcrumbs WHERE tms_id = p_last_breadcrumb_tms_id;
        IF v_last_breadcrumb_id IS NULL THEN
            RAISE WARNING 'Breadcrumb with tms_id % not found for truck % (TMS ID: %). Defaulting to "Unknown Location" breadcrumb.', p_last_breadcrumb_tms_id, p_name, p_tms_id;
            v_last_breadcrumb_id = v_unknown_breadcrumb_id; -- Set to unknown if not found
        END IF;
    ELSE
        v_last_breadcrumb_id = v_unknown_breadcrumb_id; -- Set to unknown if TMS ID is NULL
    END IF;

    -- Ensure v_last_breadcrumb_id is not null if v_unknown_breadcrumb_id was null itself
    IF v_last_breadcrumb_id IS NULL THEN
        RAISE EXCEPTION 'Default "Unknown Location" breadcrumb (tms_id=0) not found. Please ensure it is seeded.';
    END IF;


    INSERT INTO trucks (
        tms_id, name, is_active, last_dot_inspection, last_in_service, last_out_of_service,
        is_cross_terminal, is_ifta, insurance_expiration, truck_type_name, spec_year,
        spec_price, spec_vin, spec_model, spec_make, reg_expiration, reg_country,
        reg_state, reg_tag, owned_by_id, primary_terminal_id, last_breadcrumb_id
    )
    VALUES (
        p_tms_id, p_name, p_is_active, p_last_dot_inspection, p_last_in_service, p_last_out_of_service,
        p_is_cross_terminal, p_is_ifta, p_insurance_expiration, p_truck_type_name, p_spec_year,
        p_spec_price, p_spec_vin, p_spec_model, p_spec_make, p_reg_expiration, p_reg_country,
        p_reg_state, p_reg_tag, v_owned_by_id, v_primary_terminal_id, v_last_breadcrumb_id
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        is_active = EXCLUDED.is_active,
        last_dot_inspection = EXCLUDED.last_dot_inspection,
        last_in_service = EXCLUDED.last_in_service,
        last_out_of_service = EXCLUDED.last_out_of_service,
        is_cross_terminal = EXCLUDED.is_cross_terminal,
        is_ifta = EXCLUDED.is_ifta,
        insurance_expiration = EXCLUDED.insurance_expiration,
        truck_type_name = EXCLUDED.truck_type_name,
        spec_year = EXCLUDED.spec_year,
        spec_price = EXCLUDED.spec_price,
        spec_vin = EXCLUDED.spec_vin,
        spec_model = EXCLUDED.spec_model,
        spec_make = EXCLUDED.spec_make,
        reg_expiration = EXCLUDED.reg_expiration,
        reg_country = EXCLUDED.reg_country,
        reg_state = EXCLUDED.reg_state,
        reg_tag = EXCLUDED.reg_tag,
        owned_by_id = EXCLUDED.owned_by_id,
        primary_terminal_id = EXCLUDED.primary_terminal_id,
        last_breadcrumb_id = EXCLUDED.last_breadcrumb_id,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the trailers table
CREATE OR REPLACE FUNCTION upsert_trailer(
    p_tms_id INTEGER,
    p_name VARCHAR(255),
    p_is_active BOOLEAN,
    p_last_dot_inspection DATE,
    p_last_in_service TIMESTAMP WITH TIME ZONE,
    p_last_out_of_service TIMESTAMP WITH TIME ZONE,
    p_is_cross_terminal BOOLEAN,
    p_is_ifta BOOLEAN,
    p_insurance_expiration DATE,
    p_spec_year INTEGER,
    p_spec_price NUMERIC(10, 2),
    p_spec_vin VARCHAR(50),
    p_spec_model VARCHAR(100),
    p_spec_make VARCHAR(100),
    p_reg_expiration DATE,
    p_reg_country VARCHAR(100),
    p_reg_state VARCHAR(3),
    p_reg_tag VARCHAR(100),
    p_owned_by_tms_id INTEGER,      -- TMS ID for the owner
    p_primary_terminal_tms_id INTEGER, -- TMS ID for the primary terminal
    p_last_breadcrumb_tms_id INTEGER,   -- TMS ID for the last breadcrumb (can be NULL)
    p_type JSONB -- The 'type' object for trailers
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_owned_by_id INTEGER;
    v_primary_terminal_id INTEGER;
    v_last_breadcrumb_id INTEGER;
    v_unknown_breadcrumb_id INTEGER; -- To store the ID of the 'Unknown Location' breadcrumb
BEGIN
    -- Get the ID of the 'Unknown Location' breadcrumb (tms_id = 0)
    SELECT id INTO v_unknown_breadcrumb_id FROM breadcrumbs WHERE tms_id = 0;

    -- Resolve owned_by_id
    IF p_owned_by_tms_id IS NOT NULL THEN
        SELECT id INTO v_owned_by_id FROM owners WHERE tms_id = p_owned_by_tms_id;
        IF v_owned_by_id IS NULL THEN
            RAISE WARNING 'Owner with tms_id % not found for trailer % (TMS ID: %). Defaulting to "No Owner".', p_owned_by_tms_id, p_name, p_tms_id;
            SELECT id INTO v_owned_by_id FROM owners WHERE name = 'No Owner' AND tms_id IS NULL;
        END IF;
    ELSE
        SELECT id INTO v_owned_by_id FROM owners WHERE name = 'No Owner' AND tms_id IS NULL;
    END IF;

    -- Resolve primary_terminal_id
    IF p_primary_terminal_tms_id IS NOT NULL THEN
        SELECT id INTO v_primary_terminal_id FROM terminals WHERE tms_id = p_primary_terminal_tms_id;
        IF v_primary_terminal_id IS NULL THEN
            RAISE WARNING 'Terminal with tms_id % not found for trailer % (TMS ID: %). primary_terminal_id will be set to NULL.', p_primary_terminal_tms_id, p_name, p_tms_id;
        END IF;
    END IF;

    -- Resolve last_breadcrumb_id
    IF p_last_breadcrumb_tms_id IS NOT NULL THEN
        SELECT id INTO v_last_breadcrumb_id FROM breadcrumbs WHERE tms_id = p_last_breadcrumb_tms_id;
        IF v_last_breadcrumb_id IS NULL THEN
            RAISE WARNING 'Breadcrumb with tms_id % not found for trailer % (TMS ID: %). Defaulting to "Unknown Location" breadcrumb.', p_last_breadcrumb_tms_id, p_name, p_tms_id;
            v_last_breadcrumb_id = v_unknown_breadcrumb_id; -- Set to unknown if not found
        END IF;
    ELSE
        v_last_breadcrumb_id = v_unknown_breadcrumb_id; -- Set to unknown if TMS ID is NULL
    END IF;

    -- Ensure v_last_breadcrumb_id is not null if v_unknown_breadcrumb_id was null itself
    IF v_last_breadcrumb_id IS NULL THEN
        RAISE EXCEPTION 'Default "Unknown Location" breadcrumb (tms_id=0) not found. Please ensure it is seeded.';
    END IF;

    INSERT INTO trailers (
        tms_id, name, is_active, last_dot_inspection, last_in_service, last_out_of_service,
        is_cross_terminal, is_ifta, insurance_expiration, spec_year, spec_price,
        spec_vin, spec_model, spec_make, reg_expiration, reg_country, reg_state,
        reg_tag, owned_by_id, primary_terminal_id, last_breadcrumb_id, type
    )
    VALUES (
        p_tms_id, p_name, p_is_active, p_last_dot_inspection, p_last_in_service, p_last_out_of_service,
        p_is_cross_terminal, p_is_ifta, p_insurance_expiration, p_spec_year, p_spec_price,
        p_spec_vin, p_spec_model, p_spec_make, p_reg_expiration, p_reg_country, p_reg_state,
        p_reg_tag, v_owned_by_id, v_primary_terminal_id, v_last_breadcrumb_id, p_type
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        is_active = EXCLUDED.is_active,
        last_dot_inspection = EXCLUDED.last_dot_inspection,
        last_in_service = EXCLUDED.last_in_service,
        last_out_of_service = EXCLUDED.last_out_of_service,
        is_cross_terminal = EXCLUDED.is_cross_terminal,
        is_ifta = EXCLUDED.is_ifta,
        insurance_expiration = EXCLUDED.insurance_expiration,
        spec_year = EXCLUDED.spec_year,
        spec_price = EXCLUDED.spec_price,
        spec_vin = EXCLUDED.spec_vin,
        spec_model = EXCLUDED.spec_model,
        spec_make = EXCLUDED.spec_make,
        reg_expiration = EXCLUDED.reg_expiration,
        reg_country = EXCLUDED.reg_country,
        reg_state = EXCLUDED.reg_state,
        reg_tag = EXCLUDED.reg_tag,
        owned_by_id = EXCLUDED.owned_by_id,
        primary_terminal_id = EXCLUDED.primary_terminal_id,
        last_breadcrumb_id = EXCLUDED.last_breadcrumb_id,
        type = EXCLUDED.type,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the stops table
CREATE OR REPLACE FUNCTION upsert_stop(
    p_tms_id INTEGER,
    p_location_tms_id INTEGER,    -- TMS ID for the stop's location (address)
    p_stop_type_tms_id INTEGER,   -- TMS ID for the stop type
    p_number INTEGER,
    p_contact TEXT,
    p_comment TEXT,
    p_bill_of_lading TEXT,
    p_is_active BOOLEAN,
    p_time_from_last_stop INTEGER,
    p_distance_from_last_stop NUMERIC(10, 3),
    p_actual_arrive_at TIMESTAMP WITH TIME ZONE,
    p_actual_depart_at TIMESTAMP WITH TIME ZONE,
    p_scheduled_arrive_at TIMESTAMP WITH TIME ZONE,
    p_scheduled_depart_at TIMESTAMP WITH TIME ZONE,
    p_aggregates JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_location_id INTEGER;
    v_stop_type_id INTEGER;
BEGIN
    -- Resolve location_id
    IF p_location_tms_id IS NOT NULL THEN
        SELECT id INTO v_location_id FROM addresses WHERE tms_id = p_location_tms_id;
        IF v_location_id IS NULL THEN
            RAISE WARNING 'Address with tms_id % not found for stop % (TMS ID: %). location_id will be set to NULL.', p_location_tms_id, p_number, p_tms_id;
        END IF;
    END IF;

    -- Resolve stop_type_id
    IF p_stop_type_tms_id IS NOT NULL THEN
        SELECT id INTO v_stop_type_id FROM stop_types WHERE tms_id = p_stop_type_tms_id;
        IF v_stop_type_id IS NULL THEN
            RAISE WARNING 'Stop type with tms_id % not found for stop % (TMS ID: %). stop_type_id will be set to NULL.', p_stop_type_tms_id, p_number, p_tms_id;
        END IF;
    END IF;

    INSERT INTO stops (
        tms_id, location_id, stop_type_id, number, contact, comment, bill_of_lading,
        is_active, time_from_last_stop, distance_from_last_stop,
        actual_arrive_at, actual_depart_at, scheduled_arrive_at, scheduled_depart_at,
        aggregates
    )
    VALUES (
        p_tms_id, v_location_id, v_stop_type_id, p_number, p_contact, p_comment, p_bill_of_lading,
        p_is_active, p_time_from_last_stop, p_distance_from_last_stop,
        p_actual_arrive_at, p_actual_depart_at, p_scheduled_arrive_at, p_scheduled_depart_at,
        p_aggregates
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        location_id = EXCLUDED.location_id,
        stop_type_id = EXCLUDED.stop_type_id,
        number = EXCLUDED.number,
        contact = EXCLUDED.contact,
        comment = EXCLUDED.comment,
        bill_of_lading = EXCLUDED.bill_of_lading,
        is_active = EXCLUDED.is_active,
        time_from_last_stop = EXCLUDED.time_from_last_stop,
        distance_from_last_stop = EXCLUDED.distance_from_last_stop,
        actual_arrive_at = EXCLUDED.actual_arrive_at,
        actual_depart_at = EXCLUDED.actual_depart_at,
        scheduled_arrive_at = EXCLUDED.scheduled_arrive_at,
        scheduled_depart_at = EXCLUDED.scheduled_depart_at,
        aggregates = EXCLUDED.aggregates,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the purchase_orders table
CREATE OR REPLACE FUNCTION upsert_purchase_order(
    p_tms_id INTEGER,
    p_name VARCHAR(255),
    p_is_active BOOLEAN,
    p_agent_tms_id INTEGER,     -- TMS ID for the agent user
    p_bill_to_tms_id INTEGER,   -- TMS ID for the bill-to address
    p_reviewed_by_tms_id INTEGER, -- TMS ID for the user who reviewed
    p_rate_rollup JSONB,
    p_distance JSONB,
    p_line_items JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_agent_id INTEGER;
    v_bill_to_id INTEGER;
    v_reviewed_by_id INTEGER;
BEGIN
    -- Resolve agent_id
    IF p_agent_tms_id IS NOT NULL THEN
        SELECT id INTO v_agent_id FROM users WHERE tms_id = p_agent_tms_id;
        IF v_agent_id IS NULL THEN
            RAISE WARNING 'User with tms_id % (agent) not found for purchase order (TMS ID: %). agent_id will be set to NULL.', p_agent_tms_id, p_tms_id;
        END IF;
    END IF;

    -- Resolve bill_to_id
    IF p_bill_to_tms_id IS NOT NULL THEN
        SELECT id INTO v_bill_to_id FROM addresses WHERE tms_id = p_bill_to_tms_id;
        IF v_bill_to_id IS NULL THEN
            RAISE WARNING 'Address with tms_id % (bill_to) not found for purchase order (TMS ID: %). bill_to_id will be set to NULL.', p_bill_to_tms_id, p_tms_id;
        END IF;
    END IF;

    -- Resolve reviewed_by_id
    IF p_reviewed_by_tms_id IS NOT NULL THEN
        SELECT id INTO v_reviewed_by_id FROM users WHERE tms_id = p_reviewed_by_tms_id;
        IF v_reviewed_by_id IS NULL THEN
            RAISE WARNING 'User with tms_id % (reviewed_by) not found for purchase order (TMS ID: %). reviewed_by_id will be set to NULL.', p_reviewed_by_tms_id, p_tms_id;
        END IF;
    END IF;

    INSERT INTO purchase_orders (
        tms_id, name, is_active, agent_id, bill_to_id, reviewed_by_id,
        rate_rollup, distance, line_items
    )
    VALUES (
        p_tms_id, p_name, p_is_active, v_agent_id, v_bill_to_id, v_reviewed_by_id,
        p_rate_rollup, p_distance, p_line_items
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        is_active = EXCLUDED.is_active,
        agent_id = EXCLUDED.agent_id,
        bill_to_id = EXCLUDED.bill_to_id,
        reviewed_by_id = EXCLUDED.reviewed_by_id,
        rate_rollup = EXCLUDED.rate_rollup,
        distance = EXCLUDED.distance,
        line_items = EXCLUDED.line_items,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the shipments table
CREATE OR REPLACE FUNCTION upsert_shipment(
    p_tms_id INTEGER,
    p_name VARCHAR(255),
    p_first_stop_tms_id INTEGER,
    p_last_stop_tms_id INTEGER,
    p_purchase_order_tms_id INTEGER,
    p_hauled_for_id INTEGER, -- Note: This is an internal ID, not TMS ID, from discussion. Re-evaluate if needed.
    p_origin_created_by_tms_id INTEGER,
    p_current_breadcrumb_tms_id INTEGER,
    p_is_backhaul BOOLEAN,
    p_is_active BOOLEAN,
    p_is_csa BOOLEAN,
    p_is_edi BOOLEAN,
    p_handling_rules JSONB,
    p_edi JSONB,
    p_origin_created_at TIMESTAMP WITH TIME ZONE,
    p_raw_json JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_first_stop_id INTEGER;
    v_last_stop_id INTEGER;
    v_purchase_order_id INTEGER;
    v_origin_created_by_id INTEGER;
    v_current_breadcrumb_id INTEGER;
    v_unknown_breadcrumb_id INTEGER;
BEGIN
    -- Get the ID of the 'Unknown Location' breadcrumb (tms_id = 0)
    SELECT id INTO v_unknown_breadcrumb_id FROM breadcrumbs WHERE tms_id = 0;

    -- Resolve FKs
    IF p_first_stop_tms_id IS NOT NULL THEN
        SELECT id INTO v_first_stop_id FROM stops WHERE tms_id = p_first_stop_tms_id;
        IF v_first_stop_id IS NULL THEN
            RAISE WARNING 'First stop with tms_id % not found for shipment % (TMS ID: %). first_stop_id will be NULL.', p_first_stop_tms_id, p_name, p_tms_id;
        END IF;
    END IF;

    IF p_last_stop_tms_id IS NOT NULL THEN
        SELECT id INTO v_last_stop_id FROM stops WHERE tms_id = p_last_stop_tms_id;
        IF v_last_stop_id IS NULL THEN
            RAISE WARNING 'Last stop with tms_id % not found for shipment % (TMS ID: %). last_stop_id will be NULL.', p_last_stop_tms_id, p_name, p_tms_id;
        END IF;
    END IF;

    IF p_purchase_order_tms_id IS NOT NULL THEN
        SELECT id INTO v_purchase_order_id FROM purchase_orders WHERE tms_id = p_purchase_order_tms_id;
        IF v_purchase_order_id IS NULL THEN
            RAISE WARNING 'Purchase order with tms_id % not found for shipment % (TMS ID: %). purchase_order_id will be NULL.', p_purchase_order_tms_id, p_name, p_tms_id;
        END IF;
    END IF;

    IF p_origin_created_by_tms_id IS NOT NULL THEN
        SELECT id INTO v_origin_created_by_id FROM users WHERE tms_id = p_origin_created_by_tms_id;
        IF v_origin_created_by_id IS NULL THEN
            RAISE WARNING 'User with tms_id % (creator) not found for shipment % (TMS ID: %). origin_created_by_id will be NULL.', p_origin_created_by_tms_id, p_name, p_tms_id;
        END IF;
    END IF;

    -- Resolve current_breadcrumb_id, defaulting to unknown if not found/provided
    IF p_current_breadcrumb_tms_id IS NOT NULL THEN
        SELECT id INTO v_current_breadcrumb_id FROM breadcrumbs WHERE tms_id = p_current_breadcrumb_tms_id;
        IF v_current_breadcrumb_id IS NULL THEN
            RAISE WARNING 'Breadcrumb with tms_id % not found for shipment % (TMS ID: %). Defaulting to "Unknown Location" breadcrumb.', p_current_breadcrumb_tms_id, p_name, p_tms_id;
            v_current_breadcrumb_id = v_unknown_breadcrumb_id;
        END IF;
    ELSE
        v_current_breadcrumb_id = v_unknown_breadcrumb_id;
    END IF;

    IF v_current_breadcrumb_id IS NULL THEN
        RAISE EXCEPTION 'Default "Unknown Location" breadcrumb (tms_id=0) not found. Please ensure it is seeded.';
    END IF;

    INSERT INTO shipments (
        tms_id, name, first_stop_id, last_stop_id, purchase_order_id, hauled_for_id,
        origin_created_by_id, current_breadcrumb_id, is_backhaul, is_active, is_csa,
        is_edi, handling_rules, edi, origin_created_at, raw_json
    )
    VALUES (
        p_tms_id, p_name, v_first_stop_id, v_last_stop_id, v_purchase_order_id, p_hauled_for_id,
        v_origin_created_by_id, v_current_breadcrumb_id, p_is_backhaul, p_is_active, p_is_csa,
        p_is_edi, p_handling_rules, p_edi, p_origin_created_at, p_raw_json
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        first_stop_id = EXCLUDED.first_stop_id,
        last_stop_id = EXCLUDED.last_stop_id,
        purchase_order_id = EXCLUDED.purchase_order_id,
        hauled_for_id = EXCLUDED.hauled_for_id,
        origin_created_by_id = EXCLUDED.origin_created_by_id,
        current_breadcrumb_id = EXCLUDED.current_breadcrumb_id,
        is_backhaul = EXCLUDED.is_backhaul,
        is_active = EXCLUDED.is_active,
        is_csa = EXCLUDED.is_csa,
        is_edi = EXCLUDED.is_edi,
        handling_rules = EXCLUDED.handling_rules,
        edi = EXCLUDED.edi,
        origin_created_at = EXCLUDED.origin_created_at,
        raw_json = EXCLUDED.raw_json,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into the loads table
CREATE OR REPLACE FUNCTION upsert_load(
    p_tms_id INTEGER,
    p_load_template VARCHAR(255),
    p_current_stop_tms_id INTEGER,
    p_next_stop_tms_id INTEGER,
    p_first_stop_tms_id INTEGER,
    p_last_stop_tms_id INTEGER,
    p_truck_tms_id INTEGER,
    p_creator_user_tms_id INTEGER,
    p_status_tms_id INTEGER,
    p_hauling_terminal_tms_id INTEGER,
    p_origination_terminal_tms_id INTEGER,
    p_category_tms_id INTEGER,
    p_first_shipment_main_tms_id INTEGER, -- TMS ID of the main shipment
    p_current_breadcrumb_tms_id INTEGER,
    p_comment_count INTEGER,
    p_is_active BOOLEAN,
    p_first_purchase_order VARCHAR(255),
    p_summary JSONB,
    p_raw_json JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_current_stop_id INTEGER;
    v_next_stop_id INTEGER;
    v_first_stop_id INTEGER;
    v_last_stop_id INTEGER;
    v_truck_id INTEGER;
    v_creator_user_id INTEGER;
    v_status_id INTEGER;
    v_hauling_terminal_id INTEGER;
    v_origination_terminal_id INTEGER;
    v_category_id INTEGER;
    v_first_shipment_main_id INTEGER;
    v_current_breadcrumb_id INTEGER;
    v_unknown_breadcrumb_id INTEGER;
BEGIN
    -- Get the ID of the 'Unknown Location' breadcrumb (tms_id = 0)
    SELECT id INTO v_unknown_breadcrumb_id FROM breadcrumbs WHERE tms_id = 0;

    -- Resolve FKs
    IF p_current_stop_tms_id IS NOT NULL THEN
        SELECT id INTO v_current_stop_id FROM stops WHERE tms_id = p_current_stop_tms_id;
        IF v_current_stop_id IS NULL THEN
            RAISE WARNING 'Current stop with tms_id % not found for load (TMS ID: %). current_stop_id will be NULL.', p_current_stop_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_next_stop_tms_id IS NOT NULL THEN
        SELECT id INTO v_next_stop_id FROM stops WHERE tms_id = p_next_stop_tms_id;
        IF v_next_stop_id IS NULL THEN
            RAISE WARNING 'Next stop with tms_id % not found for load (TMS ID: %). next_stop_id will be NULL.', p_next_stop_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_first_stop_tms_id IS NOT NULL THEN
        SELECT id INTO v_first_stop_id FROM stops WHERE tms_id = p_first_stop_tms_id;
        IF v_first_stop_id IS NULL THEN
            RAISE WARNING 'First stop with tms_id % not found for load (TMS ID: %). first_stop_id will be NULL.', p_first_stop_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_last_stop_tms_id IS NOT NULL THEN
        SELECT id INTO v_last_stop_id FROM stops WHERE tms_id = p_last_stop_tms_id;
        IF v_last_stop_id IS NULL THEN
            RAISE WARNING 'Last stop with tms_id % not found for load (TMS ID: %). last_stop_id will be NULL.', p_last_stop_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_truck_tms_id IS NOT NULL THEN
        SELECT id INTO v_truck_id FROM trucks WHERE tms_id = p_truck_tms_id;
        IF v_truck_id IS NULL THEN
            RAISE WARNING 'Truck with tms_id % not found for load (TMS ID: %). truck_id will be NULL.', p_truck_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_creator_user_tms_id IS NOT NULL THEN
        SELECT id INTO v_creator_user_id FROM users WHERE tms_id = p_creator_user_tms_id;
        IF v_creator_user_id IS NULL THEN
            RAISE WARNING 'Creator user with tms_id % not found for load (TMS ID: %). creator_user_id will be NULL.', p_creator_user_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_status_tms_id IS NOT NULL THEN
        SELECT id INTO v_status_id FROM load_statuses WHERE tms_id = p_status_tms_id;
        IF v_status_id IS NULL THEN
            RAISE WARNING 'Load status with tms_id % not found for load (TMS ID: %). status_id will be NULL.', p_status_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_hauling_terminal_tms_id IS NOT NULL THEN
        SELECT id INTO v_hauling_terminal_id FROM terminals WHERE tms_id = p_hauling_terminal_tms_id;
        IF v_hauling_terminal_id IS NULL THEN
            RAISE WARNING 'Hauling terminal with tms_id % not found for load (TMS ID: %). hauling_terminal_id will be NULL.', p_hauling_terminal_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_origination_terminal_tms_id IS NOT NULL THEN
        SELECT id INTO v_origination_terminal_id FROM terminals WHERE tms_id = p_origination_terminal_tms_id;
        IF v_origination_terminal_id IS NULL THEN
            RAISE WARNING 'Origination terminal with tms_id % not found for load (TMS ID: %). origination_terminal_id will be NULL.', p_origination_terminal_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_category_tms_id IS NOT NULL THEN
        SELECT id INTO v_category_id FROM load_categories WHERE tms_id = p_category_tms_id;
        IF v_category_id IS NULL THEN
            RAISE WARNING 'Load category with tms_id % not found for load (TMS ID: %). category_id will be NULL.', p_category_tms_id, p_tms_id;
        END IF;
    END IF;

    IF p_first_shipment_main_tms_id IS NOT NULL THEN
        SELECT id INTO v_first_shipment_main_id FROM shipments WHERE tms_id = p_first_shipment_main_tms_id;
        IF v_first_shipment_main_id IS NULL THEN
            RAISE WARNING 'First main shipment with tms_id % not found for load (TMS ID: %). first_shipment_main_id will be NULL.', p_first_shipment_main_tms_id, p_tms_id;
        END IF;
    END IF;

    -- Resolve current_breadcrumb_id, defaulting to unknown if not found/provided
    IF p_current_breadcrumb_tms_id IS NOT NULL THEN
        SELECT id INTO v_current_breadcrumb_id FROM breadcrumbs WHERE tms_id = p_current_breadcrumb_tms_id;
        IF v_current_breadcrumb_id IS NULL THEN
            RAISE WARNING 'Breadcrumb with tms_id % not found for load (TMS ID: %). Defaulting to "Unknown Location" breadcrumb.', p_current_breadcrumb_tms_id, p_tms_id;
            v_current_breadcrumb_id = v_unknown_breadcrumb_id;
        END IF;
    ELSE
        v_current_breadcrumb_id = v_unknown_breadcrumb_id;
    END IF;

    IF v_current_breadcrumb_id IS NULL THEN
        RAISE EXCEPTION 'Default "Unknown Location" breadcrumb (tms_id=0) not found. Please ensure it is seeded.';
    END IF;

    INSERT INTO loads (
        tms_id, load_template, current_stop_id, next_stop_id, first_stop_id, last_stop_id,
        truck_id, creator_user_id, status_id, hauling_terminal_id, origination_terminal_id,
        category_id, first_shipment_main_id, current_breadcrumb_id, comment_count,
        is_active, first_purchase_order, summary, raw_json
    )
    VALUES (
        p_tms_id, p_load_template, v_current_stop_id, v_next_stop_id, v_first_stop_id, v_last_stop_id,
        v_truck_id, v_creator_user_id, v_status_id, v_hauling_terminal_id, v_origination_terminal_id,
        v_category_id, v_first_shipment_main_id, v_current_breadcrumb_id, p_comment_count,
        p_is_active, p_first_purchase_order, p_summary, p_raw_json
    )
    ON CONFLICT (tms_id) DO UPDATE
    SET
        load_template = EXCLUDED.load_template,
        current_stop_id = EXCLUDED.current_stop_id,
        next_stop_id = EXCLUDED.next_stop_id,
        first_stop_id = EXCLUDED.first_stop_id,
        last_stop_id = EXCLUDED.last_stop_id,
        truck_id = EXCLUDED.truck_id,
        creator_user_id = EXCLUDED.creator_user_id,
        status_id = EXCLUDED.status_id,
        hauling_terminal_id = EXCLUDED.hauling_terminal_id,
        origination_terminal_id = EXCLUDED.origination_terminal_id,
        category_id = EXCLUDED.category_id,
        first_shipment_main_id = EXCLUDED.first_shipment_main_id,
        current_breadcrumb_id = EXCLUDED.current_breadcrumb_id,
        comment_count = EXCLUDED.comment_count,
        is_active = EXCLUDED.is_active,
        first_purchase_order = EXCLUDED.first_purchase_order,
        summary = EXCLUDED.summary,
        raw_json = EXCLUDED.raw_json,
        updated_at = NOW()
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into load_drivers (linking table)
-- This function is designed to handle individual links.
-- For bulk updates, consider a separate function that clears and re-inserts.
CREATE OR REPLACE FUNCTION upsert_load_driver(
    p_load_tms_id INTEGER,
    p_driver_user_tms_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_load_id INTEGER;
    v_driver_user_id INTEGER;
BEGIN
    SELECT id INTO v_load_id FROM loads WHERE tms_id = p_load_tms_id;
    IF v_load_id IS NULL THEN
        RAISE WARNING 'Load with tms_id % not found. Cannot create load_driver link.', p_load_tms_id;
        RETURN;
    END IF;

    SELECT id INTO v_driver_user_id FROM users WHERE tms_id = p_driver_user_tms_id;
    IF v_driver_user_id IS NULL THEN
        RAISE WARNING 'Driver user with tms_id % not found. Cannot create load_driver link.', p_driver_user_tms_id;
        RETURN;
    END IF;

    INSERT INTO load_drivers (load_id, driver_user_id)
    VALUES (v_load_id, v_driver_user_id)
    ON CONFLICT (load_id, driver_user_id) DO NOTHING; -- Do nothing if link already exists
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into load_revenues (detail table)
-- This assumes revenue items are distinct by type for a given load, or new ones are always added.
-- This function is designed to insert individual load revenue items.
-- To ensure a load's revenues are up-to-date from an API payload,
-- you should DELETE all existing load_revenues for that load_id
-- before calling this function for each revenue item in the new payload.
CREATE OR REPLACE FUNCTION upsert_load_revenue(
    p_load_tms_id INTEGER,
    p_type VARCHAR(50),
    p_fuel_surcharge NUMERIC(10, 2),
    p_miscellaneous NUMERIC(10, 2),
    p_accessorial NUMERIC(10, 2),
    p_line_haul NUMERIC(10, 2)
)
RETURNS INTEGER AS $$
DECLARE
    v_id INTEGER;
    v_load_id INTEGER;
BEGIN
    SELECT id INTO v_load_id FROM loads WHERE tms_id = p_load_tms_id;
    IF v_load_id IS NULL THEN
        RAISE WARNING 'Load with tms_id % not found. Cannot create load_revenue record.', p_load_tms_id;
        RETURN NULL;
    END IF;

    INSERT INTO load_revenues (
        load_id, type, fuel_surcharge, miscellaneous, accessorial, line_haul
    )
    VALUES (
        v_load_id, p_type, p_fuel_surcharge, p_miscellaneous, p_accessorial, p_line_haul
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into load_shipments (linking table)
CREATE OR REPLACE FUNCTION upsert_load_shipment(
    p_load_tms_id INTEGER,
    p_shipment_tms_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_load_id INTEGER;
    v_shipment_id INTEGER;
BEGIN
    SELECT id INTO v_load_id FROM loads WHERE tms_id = p_load_tms_id;
    IF v_load_id IS NULL THEN
        RAISE WARNING 'Load with tms_id % not found. Cannot create load_shipment link.', p_load_tms_id;
        RETURN;
    END IF;

    SELECT id INTO v_shipment_id FROM shipments WHERE tms_id = p_shipment_tms_id;
    IF v_shipment_id IS NULL THEN
        RAISE WARNING 'Shipment with tms_id % not found. Cannot create load_shipment link.', p_shipment_tms_id;
        RETURN;
    END IF;

    INSERT INTO load_shipments (load_id, shipment_id)
    VALUES (v_load_id, v_shipment_id)
    ON CONFLICT (load_id, shipment_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert data into load_trailers (linking table)
CREATE OR REPLACE FUNCTION upsert_load_trailer(
    p_load_tms_id INTEGER,
    p_trailer_tms_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_load_id INTEGER;
    v_trailer_id INTEGER;
BEGIN
    SELECT id INTO v_load_id FROM loads WHERE tms_id = p_load_tms_id;
    IF v_load_id IS NULL THEN
        RAISE WARNING 'Load with tms_id % not found. Cannot create load_trailer link.', p_load_tms_id;
        RETURN;
    END IF;

    SELECT id INTO v_trailer_id FROM trailers WHERE tms_id = p_trailer_tms_id;
    IF v_trailer_id IS NULL THEN
        RAISE WARNING 'Trailer with tms_id % not found. Cannot create load_trailer link.', p_trailer_tms_id;
        RETURN;
    END IF;

    INSERT INTO load_trailers (load_id, trailer_id)
    VALUES (v_load_id, v_trailer_id)
    ON CONFLICT (load_id, trailer_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple data suppliers from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_data_suppliers(
    p_data_suppliers JSONB[]
)
RETURNS VOID AS $$
DECLARE
    data_supplier_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_data_suppliers, 1) LOOP
        data_supplier_data := p_data_suppliers[i];
        PERFORM upsert_data_supplier(
            (data_supplier_data->>'tms_id')::INTEGER,
            data_supplier_data->>'name',
            (data_supplier_data->>'is_active')::BOOLEAN
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple users from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_users(
    p_users JSONB[]
)
RETURNS VOID AS $$
DECLARE
    user_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_users, 1) LOOP
        user_data := p_users[i];
        PERFORM upsert_user(
            (user_data->>'tms_id')::INTEGER,
            user_data->>'username',
            (user_data->>'data_supplier_tms_id')::INTEGER,
            user_data->>'first_name',
            user_data->>'last_name',
            user_data->>'email',
            (user_data->>'is_active')::BOOLEAN,
            user_data->'roles', -- Pass JSONB directly
            user_data->'metadata' -- Pass JSONB directly
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple owners from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_owners(
    p_owners JSONB[]
)
RETURNS VOID AS $$
DECLARE
    owner_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_owners, 1) LOOP
        owner_data := p_owners[i];
        PERFORM upsert_owner(
            (owner_data->>'tms_id')::INTEGER,
            owner_data->>'name',
            (owner_data->>'data_supplier_tms_id')::INTEGER,
            (owner_data->>'is_active')::BOOLEAN
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple terminals from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_terminals(
    p_terminals JSONB[]
)
RETURNS VOID AS $$
DECLARE
    terminal_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_terminals, 1) LOOP
        terminal_data := p_terminals[i];
        PERFORM upsert_terminal(
            (terminal_data->>'tms_id')::INTEGER,
            terminal_data->>'name',
            (terminal_data->>'is_active')::BOOLEAN
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple address types from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_address_types(
    p_address_types JSONB[]
)
RETURNS VOID AS $$
DECLARE
    address_type_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_address_types, 1) LOOP
        address_type_data := p_address_types[i];
        PERFORM upsert_address_type(
            (address_type_data->>'tms_id')::INTEGER,
            address_type_data->>'name',
            (address_type_data->>'is_active')::BOOLEAN
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple trucks from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_trucks(
    p_trucks JSONB[]
)
RETURNS VOID AS $$
DECLARE
    truck_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_trucks, 1) LOOP
        truck_data := p_trucks[i];
        PERFORM upsert_truck(
            (truck_data->>'tms_id')::INTEGER,
            truck_data->>'name',
            (truck_data->>'is_active')::BOOLEAN,
            (truck_data->>'last_dot_inspection')::DATE,
            (truck_data->>'last_in_service')::TIMESTAMP WITH TIME ZONE,
            (truck_data->>'last_out_of_service')::TIMESTAMP WITH TIME ZONE,
            (truck_data->>'is_cross_terminal')::BOOLEAN,
            (truck_data->>'is_ifta')::BOOLEAN,
            (truck_data->>'insurance_expiration')::DATE,
            truck_data->>'truck_type_name',
            (truck_data->>'spec_year')::INTEGER,
            (truck_data->>'spec_price')::NUMERIC(10, 2),
            truck_data->>'spec_vin',
            truck_data->>'spec_model',
            truck_data->>'spec_make',
            (truck_data->>'reg_expiration')::DATE,
            truck_data->>'reg_country',
            truck_data->>'reg_state',
            truck_data->>'reg_tag',
            (truck_data->>'owned_by_tms_id')::INTEGER,
            (truck_data->>'primary_terminal_tms_id')::INTEGER,
            (truck_data->>'last_breadcrumb_tms_id')::INTEGER
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple trailers from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_trailers(
    p_trailers JSONB[]
)
RETURNS VOID AS $$
DECLARE
    trailer_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_trailers, 1) LOOP
        trailer_data := p_trailers[i];
        PERFORM upsert_trailer(
            (trailer_data->>'tms_id')::INTEGER,
            trailer_data->>'name',
            (trailer_data->>'is_active')::BOOLEAN,
            (trailer_data->>'last_dot_inspection')::DATE,
            (trailer_data->>'last_in_service')::TIMESTAMP WITH TIME ZONE,
            (trailer_data->>'last_out_of_service')::TIMESTAMP WITH TIME ZONE,
            (trailer_data->>'is_cross_terminal')::BOOLEAN,
            (trailer_data->>'is_ifta')::BOOLEAN,
            (trailer_data->>'insurance_expiration')::DATE,
            (trailer_data->>'spec_year')::INTEGER,
            (trailer_data->>'spec_price')::NUMERIC(10, 2),
            trailer_data->>'spec_vin',
            trailer_data->>'spec_model',
            trailer_data->>'spec_make',
            (trailer_data->>'reg_expiration')::DATE,
            trailer_data->>'reg_country',
            trailer_data->>'reg_state',
            trailer_data->>'reg_tag',
            (trailer_data->>'owned_by_tms_id')::INTEGER,
            (trailer_data->>'primary_terminal_tms_id')::INTEGER,
            (trailer_data->>'last_breadcrumb_tms_id')::INTEGER,
            trailer_data->'type' -- Pass JSONB directly
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple breadcrumbs from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_breadcrumbs(
    p_breadcrumbs JSONB[]
)
RETURNS VOID AS $$
DECLARE
    breadcrumb_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_breadcrumbs, 1) LOOP
        breadcrumb_data := p_breadcrumbs[i];
        PERFORM upsert_breadcrumb(
            (breadcrumb_data->>'tms_id')::INTEGER,
            (breadcrumb_data->>'data_supplier_tms_id')::INTEGER,
            (breadcrumb_data->>'latitude')::NUMERIC(10, 6),
            (breadcrumb_data->>'longitude')::NUMERIC(10, 6),
            (breadcrumb_data->>'speed')::NUMERIC(7, 2),
            (breadcrumb_data->>'heading')::INTEGER,
            (breadcrumb_data->>'temperature')::NUMERIC(5, 2),
            (breadcrumb_data->>'recorded_at')::TIMESTAMP WITH TIME ZONE,
            (breadcrumb_data->>'received_at')::TIMESTAMP WITH TIME ZONE,
            (breadcrumb_data->>'is_ignition_on')::BOOLEAN,
            (breadcrumb_data->>'odometer')::NUMERIC(10, 2),
            breadcrumb_data->>'name'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple stop types from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_stop_types(
    p_stop_types JSONB[]
)
RETURNS VOID AS $$
DECLARE
    stop_type_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_stop_types, 1) LOOP
        stop_type_data := p_stop_types[i];
        PERFORM upsert_stop_type(
            (stop_type_data->>'tms_id')::INTEGER,
            stop_type_data->>'name',
            (stop_type_data->>'is_active')::BOOLEAN
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple stops from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_stops(
    p_stops JSONB[]
)
RETURNS VOID AS $$
DECLARE
    stop_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_stops, 1) LOOP
        stop_data := p_stops[i];
        PERFORM upsert_stop(
            (stop_data->>'tms_id')::INTEGER,
            (stop_data->>'location_tms_id')::INTEGER,
            (stop_data->>'stop_type_tms_id')::INTEGER,
            (stop_data->>'number')::INTEGER,
            stop_data->>'contact',
            stop_data->>'comment',
            stop_data->>'bill_of_lading',
            (stop_data->>'is_active')::BOOLEAN,
            (stop_data->>'time_from_last_stop')::INTEGER,
            (stop_data->>'distance_from_last_stop')::NUMERIC(10, 3),
            (stop_data->>'actual_arrive_at')::TIMESTAMP WITH TIME ZONE,
            (stop_data->>'actual_depart_at')::TIMESTAMP WITH TIME ZONE,
            (stop_data->>'scheduled_arrive_at')::TIMESTAMP WITH TIME ZONE,
            (stop_data->>'scheduled_depart_at')::TIMESTAMP WITH TIME ZONE,
            stop_data->'aggregates'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple purchase orders from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_purchase_orders(
    p_purchase_orders JSONB[]
)
RETURNS VOID AS $$
DECLARE
    po_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_purchase_orders, 1) LOOP
        po_data := p_purchase_orders[i];
        PERFORM upsert_purchase_order(
            (po_data->>'tms_id')::INTEGER,
            po_data->>'name',
            (po_data->>'is_active')::BOOLEAN,
            (po_data->>'agent_tms_id')::INTEGER,
            (po_data->>'bill_to_tms_id')::INTEGER,
            (po_data->>'reviewed_by_tms_id')::INTEGER,
            po_data->'rate_rollup',
            po_data->'distance',
            po_data->'line_items'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple shipments from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_shipments(
    p_shipments JSONB[]
)
RETURNS VOID AS $$
DECLARE
    shipment_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_shipments, 1) LOOP
        shipment_data := p_shipments[i];
        PERFORM upsert_shipment(
            (shipment_data->>'tms_id')::INTEGER,
            shipment_data->>'name',
            (shipment_data->>'first_stop_tms_id')::INTEGER,
            (shipment_data->>'last_stop_tms_id')::INTEGER,
            (shipment_data->>'purchase_order_tms_id')::INTEGER,
            (shipment_data->>'hauled_for_id')::INTEGER, -- Assuming this is still an integer
            (shipment_data->>'origin_created_by_tms_id')::INTEGER,
            (shipment_data->>'current_breadcrumb_tms_id')::INTEGER,
            (shipment_data->>'is_backhaul')::BOOLEAN,
            (shipment_data->>'is_active')::BOOLEAN,
            (shipment_data->>'is_csa')::BOOLEAN,
            (shipment_data->>'is_edi')::BOOLEAN,
            shipment_data->'handling_rules',
            shipment_data->'edi',
            (shipment_data->>'origin_created_at')::TIMESTAMP WITH TIME ZONE,
            shipment_data->'raw_json'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple load statuses from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_load_statuses(
    p_load_statuses JSONB[]
)
RETURNS VOID AS $$
DECLARE
    status_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_load_statuses, 1) LOOP
        status_data := p_load_statuses[i];
        PERFORM upsert_load_status(
            (status_data->>'tms_id')::INTEGER,
            status_data->>'name',
            (status_data->>'is_active')::BOOLEAN
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple load categories from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_load_categories(
    p_load_categories JSONB[]
)
RETURNS VOID AS $$
DECLARE
    category_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_load_categories, 1) LOOP
        category_data := p_load_categories[i];
        PERFORM upsert_load_category(
            (category_data->>'tms_id')::INTEGER,
            category_data->>'name',
            (category_data->>'is_active')::BOOLEAN
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple loads from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_loads(
    p_loads JSONB[]
)
RETURNS VOID AS $$
DECLARE
    load_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_loads, 1) LOOP
        load_data := p_loads[i];
        PERFORM upsert_load(
            (load_data->>'tms_id')::INTEGER,
            load_data->>'load_template',
            (load_data->>'current_stop_tms_id')::INTEGER,
            (load_data->>'next_stop_tms_id')::INTEGER,
            (load_data->>'first_stop_tms_id')::INTEGER,
            (load_data->>'last_stop_tms_id')::INTEGER,
            (load_data->>'truck_tms_id')::INTEGER,
            (load_data->>'creator_user_tms_id')::INTEGER,
            (load_data->>'status_tms_id')::INTEGER,
            (load_data->>'hauling_terminal_tms_id')::INTEGER,
            (load_data->>'origination_terminal_tms_id')::INTEGER,
            (load_data->>'category_tms_id')::INTEGER,
            (load_data->>'first_shipment_main_tms_id')::INTEGER,
            (load_data->>'current_breadcrumb_tms_id')::INTEGER,
            (load_data->>'comment_count')::INTEGER,
            (load_data->>'is_active')::BOOLEAN,
            load_data->>'first_purchase_order',
            load_data->'summary',
            load_data->'raw_json'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple load_drivers from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_load_drivers(
    p_load_drivers JSONB[]
)
RETURNS VOID AS $$
DECLARE
    ld_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_load_drivers, 1) LOOP
        ld_data := p_load_drivers[i];
        PERFORM upsert_load_driver(
            (ld_data->>'load_tms_id')::INTEGER,
            (ld_data->>'driver_user_tms_id')::INTEGER
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple load revenues from a JSONB array for a specific parent load.
-- This function handles the "clear and re-insert" strategy for its child collection.
CREATE OR REPLACE FUNCTION bulk_upsert_load_revenues(
    p_load_id INTEGER, -- IMPORTANT: This is the internal DB ID of the parent load
    p_revenues JSONB[]
)
RETURNS VOID AS $$
DECLARE
    revenue_data JSONB;
BEGIN
    -- Clear existing revenues for this load_id
    DELETE FROM load_revenues WHERE load_id = p_load_id;

    -- Then, insert the new revenues
    FOR i IN 1..array_length(p_revenues, 1) LOOP
        revenue_data := p_revenues[i];
        PERFORM upsert_load_revenue(
            p_load_id, -- Pass the parent load's internal ID
            revenue_data->>'type',
            (revenue_data->>'fuel_surcharge')::NUMERIC(10, 2),
            (revenue_data->>'miscellaneous')::NUMERIC(10, 2),
            (revenue_data->>'accessorial')::NUMERIC(10, 2),
            (revenue_data->>'line_haul')::NUMERIC(10, 2)
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Important Note: The bulk_upsert_load_revenues function assumes 
--you have the internal database ID of the parent load. 
--If your API provides load_revenues nested within a load object, 
--your application code will first upsert_load to get that internal load_id, 
--and then pass it to bulk_upsert_load_revenues.
-- Function to upsert multiple load_shipments from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_load_shipments(
    p_load_shipments JSONB[]
)
RETURNS VOID AS $$
DECLARE
    ls_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_load_shipments, 1) LOOP
        ls_data := p_load_shipments[i];
        PERFORM upsert_load_shipment(
            (ls_data->>'load_tms_id')::INTEGER,
            (ls_data->>'shipment_tms_id')::INTEGER
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple shipment_stops from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_shipment_stops(
    p_shipment_stops JSONB[]
)
RETURNS VOID AS $$
DECLARE
    ss_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_shipment_stops, 1) LOOP
        ss_data := p_shipment_stops[i];
        PERFORM upsert_shipment_stop(
            (ss_data->>'shipment_tms_id')::INTEGER,
            (ss_data->>'stop_tms_id')::INTEGER,
            (ss_data->>'stop_order')::INTEGER
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Function to upsert multiple load_trailers from a JSONB array
CREATE OR REPLACE FUNCTION bulk_upsert_load_trailers(
    p_load_trailers JSONB[]
)
RETURNS VOID AS $$
DECLARE
    lt_data JSONB;
BEGIN
    FOR i IN 1..array_length(p_load_trailers, 1) LOOP
        lt_data := p_load_trailers[i];
        PERFORM upsert_load_trailer(
            (lt_data->>'load_tms_id')::INTEGER,
            (lt_data->>'trailer_tms_id')::INTEGER
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;