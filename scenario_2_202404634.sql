-- =====================================================
-- SCENARIO 2: COMPUTER LABORATORY RESERVATIONS
-- =====================================================

DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS lab_sessions;

-- 1. CREATE TABLES

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INTEGER NOT NULL
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    lecturer VARCHAR(100) NOT NULL,
    session_id INTEGER REFERENCES lab_sessions(session_id),
    workstations INTEGER NOT NULL,
    reservation_status VARCHAR(20) NOT NULL
);

-- Add at least three sessions

INSERT INTO lab_sessions
(session_name, available_workstations)
VALUES
('Database Practical', 30),
('Networking Practical', 20),
('Programming Practical', 10);

-- Check the sessions

SELECT * FROM lab_sessions;

-- =====================================================
-- 2. IF / ELSIF / ELSE
-- =====================================================

DO $$
DECLARE
    workstations INTEGER;
BEGIN
    SELECT available_workstations
    INTO workstations
    FROM lab_sessions
    WHERE session_id = 1;

    IF workstations = 0 THEN
        RAISE NOTICE 'The lab session is full.';
    ELSIF workstations <= 5 THEN
        RAISE NOTICE 'The lab session is nearly full.';
    ELSE
        RAISE NOTICE 'The lab session has enough workstations.';
    END IF;
END;
$$;

-- =====================================================
-- 3. WHILE LOOP AND NUMERIC FOR LOOP
-- =====================================================

DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN

    WHILE reminder_number <= 3 LOOP
        RAISE NOTICE 'Session preparation reminder: %',
            reminder_number;
        reminder_number := reminder_number + 1;
    END LOOP;

    FOR workstation_check IN 1..3 LOOP
        RAISE NOTICE 'Workstation check number: %',
            workstation_check;
    END LOOP;

END;
$$;

-- =====================================================
-- 4. CREATE reserve_workstations PROCEDURE
-- =====================================================

CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_lecturer VARCHAR,
    p_session_id INTEGER,
    p_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INTEGER;
BEGIN

    IF p_workstations <= 0 THEN
        RAISE EXCEPTION
            'Invalid number of workstations. Must be greater than zero.';
    END IF;

    SELECT available_workstations
    INTO available
    FROM lab_sessions
    WHERE session_id = p_session_id;

    IF available IS NULL THEN

        RAISE NOTICE 'Lab session does not exist.';

    ELSIF available < p_workstations THEN

        RAISE NOTICE 'Not enough workstations available.';

    ELSE

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations - p_workstations
        WHERE session_id = p_session_id;

        INSERT INTO reservations
        (
            lecturer,
            session_id,
            workstations,
            reservation_status
        )
        VALUES
        (
            p_lecturer,
            p_session_id,
            p_workstations,
            'Reserved'
        );

        RAISE NOTICE 'Workstations reserved successfully.';

    END IF;

END;
$$;

-- =====================================================
-- 5. TWO VALID RESERVATIONS + ONE EXCEEDING CAPACITY
-- =====================================================

CALL reserve_workstations(
    'Dr. Banda',
    1,
    10
);

CALL reserve_workstations(
    'Dr. Phiri',
    2,
    5
);

CALL reserve_workstations(
    'Dr. Zulu',
    3,
    20
);

-- Check results

SELECT * FROM lab_sessions;

SELECT * FROM reservations;

-- =====================================================
-- 6. CREATE cancel_reservation PROCEDURE
-- =====================================================

CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    reserved_session_id INTEGER;
    reserved_workstations INTEGER;
    current_status VARCHAR(20);
BEGIN

    SELECT session_id, workstations, reservation_status
    INTO reserved_session_id,
         reserved_workstations,
         current_status
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF reserved_session_id IS NULL THEN

        RAISE NOTICE 'Reservation does not exist.';

    ELSIF current_status = 'Cancelled' THEN

        RAISE NOTICE
            'Reservation already cancelled. Workstations not restored.';

    ELSE

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations + reserved_workstations
        WHERE session_id = reserved_session_id;

        UPDATE reservations
        SET reservation_status = 'Cancelled'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE
            'Reservation cancelled. Workstations restored.';

    END IF;

END;
$$;

-- Cancel reservation 1

CALL cancel_reservation(1);

-- Try cancelling the SAME reservation again

CALL cancel_reservation(1);

-- Check results

SELECT * FROM lab_sessions;

SELECT * FROM reservations;

-- =====================================================
-- 7. EXPLICIT CURSOR
-- Display sessions with few workstations remaining
-- =====================================================

DO $$
DECLARE
    session_record RECORD;

    session_cursor CURSOR FOR
        SELECT session_id,
               session_name,
               available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5;

BEGIN

    OPEN session_cursor;

    LOOP

        FETCH session_cursor INTO session_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Session: %, Available workstations: %',
            session_record.session_name,
            session_record.available_workstations;

    END LOOP;

    CLOSE session_cursor;

END;
$$;

-- =====================================================
-- 8. ZERO WORKSTATIONS + EXCEPTION
-- =====================================================

DO $$
BEGIN

    CALL reserve_workstations(
        'Dr. Tembo',
        1,
        0
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE
            'Invalid workstation quantity handled: %',
            SQLERRM;
END;
$$;

-- =====================================================
-- 9. FINAL QUERIES
-- =====================================================

SELECT * FROM lab_sessions;

SELECT * FROM reservations;