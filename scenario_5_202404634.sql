-- =====================================================
-- SCENARIO 5: ENGINEERING WORKSHOP TOOL LOANS
-- =====================================================

DROP TABLE IF EXISTS tool_loans;
DROP TABLE IF EXISTS tools;

-- 1. CREATE TABLES

CREATE TABLE tools (
    tool_id SERIAL PRIMARY KEY,
    tool_name VARCHAR(100) NOT NULL,
    available_quantity INTEGER NOT NULL
);

CREATE TABLE tool_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    tool_id INTEGER REFERENCES tools(tool_id),
    quantity INTEGER NOT NULL,
    loan_status VARCHAR(20) NOT NULL
);

-- Add at least three tool types

INSERT INTO tools
(tool_name, available_quantity)
VALUES
('Hammer', 10),
('Screwdriver', 6),
('Spanner', 2);

SELECT * FROM tools;

-- =====================================================
-- 2. IF / ELSIF / ELSE
-- =====================================================

DO $$
DECLARE
    quantity_available INTEGER;
BEGIN

    SELECT available_quantity
    INTO quantity_available
    FROM tools
    WHERE tool_id = 1;

    IF quantity_available = 0 THEN

        RAISE NOTICE 'The tool is unavailable.';

    ELSIF quantity_available <= 3 THEN

        RAISE NOTICE 'The tool is low on stock.';

    ELSE

        RAISE NOTICE 'The tool is readily available.';

    END IF;

END;
$$;

-- =====================================================
-- 3. WHILE LOOP + NUMERIC FOR LOOP
-- =====================================================

DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN

    WHILE reminder_number <= 3 LOOP

        RAISE NOTICE
            'Workshop safety reminder: %',
            reminder_number;

        reminder_number := reminder_number + 1;

    END LOOP;

    FOR inspection_number IN 1..3 LOOP

        RAISE NOTICE
            'Tool inspection number: %',
            inspection_number;

    END LOOP;

END;
$$;

-- =====================================================
-- 4. CREATE issue_tool PROCEDURE
-- =====================================================

CREATE OR REPLACE PROCEDURE issue_tool(
    p_student_number VARCHAR,
    p_tool_id INTEGER,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INTEGER;
BEGIN

    IF p_quantity <= 0 THEN

        RAISE EXCEPTION
            'Invalid quantity. Quantity must be greater than zero.';

    END IF;

    SELECT available_quantity
    INTO available
    FROM tools
    WHERE tool_id = p_tool_id;

    IF available IS NULL THEN

        RAISE NOTICE 'Tool does not exist.';

    ELSIF available < p_quantity THEN

        RAISE NOTICE 'Not enough tools available.';

    ELSE

        UPDATE tools
        SET available_quantity =
            available_quantity - p_quantity
        WHERE tool_id = p_tool_id;

        INSERT INTO tool_loans
        (
            student_number,
            tool_id,
            quantity,
            loan_status
        )
        VALUES
        (
            p_student_number,
            p_tool_id,
            p_quantity,
            'Borrowed'
        );

        RAISE NOTICE 'Tool issued successfully.';

    END IF;

END;
$$;

-- =====================================================
-- 5. TWO VALID LOANS + ONE EXCESSIVE REQUEST
-- =====================================================

CALL issue_tool(
    '202600001',
    1,
    3
);

CALL issue_tool(
    '202600002',
    2,
    2
);

CALL issue_tool(
    '202600003',
    3,
    5
);

SELECT * FROM tools;

SELECT * FROM tool_loans;

-- =====================================================
-- 6. CREATE return_tool PROCEDURE
-- =====================================================

CREATE OR REPLACE PROCEDURE return_tool(
    p_loan_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    returned_tool_id INTEGER;
    returned_quantity INTEGER;
    current_status VARCHAR(20);
BEGIN

    SELECT tool_id,
           quantity,
           loan_status
    INTO returned_tool_id,
         returned_quantity,
         current_status
    FROM tool_loans
    WHERE loan_id = p_loan_id;

    IF returned_tool_id IS NULL THEN

        RAISE NOTICE 'Tool loan does not exist.';

    ELSIF current_status = 'Returned' THEN

        RAISE NOTICE
            'Tool already returned. Stock not restored again.';

    ELSE

        UPDATE tools
        SET available_quantity =
            available_quantity + returned_quantity
        WHERE tool_id = returned_tool_id;

        UPDATE tool_loans
        SET loan_status = 'Returned'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE
            'Tool returned successfully. Stock restored.';

    END IF;

END;
$$;

-- Return loan 1

CALL return_tool(1);

-- Return the SAME loan again

CALL return_tool(1);

SELECT * FROM tools;

SELECT * FROM tool_loans;

-- =====================================================
-- 7. EXPLICIT CURSOR
-- Display tools with low availability
-- =====================================================

DO $$
DECLARE
    tool_record RECORD;

    tool_cursor CURSOR FOR
        SELECT tool_id,
               tool_name,
               available_quantity
        FROM tools
        WHERE available_quantity <= 3;

BEGIN

    OPEN tool_cursor;

    LOOP

        FETCH tool_cursor INTO tool_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Tool: %, Available quantity: %',
            tool_record.tool_name,
            tool_record.available_quantity;

    END LOOP;

    CLOSE tool_cursor;

END;
$$;

-- =====================================================
-- 8. ZERO TOOLS + EXCEPTION
-- =====================================================

DO $$
BEGIN

    CALL issue_tool(
        '202600004',
        1,
        0
    );

EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE
            'Invalid tool quantity handled: %',
            SQLERRM;

END;
$$;

-- =====================================================
-- 9. FINAL QUERIES
-- =====================================================

SELECT * FROM tools;

SELECT * FROM tool_loans;