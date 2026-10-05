-- SCENARIO 1: UNIVERSITY LIBRARY BOOK LOANS

-- Create books table
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    available_copies INTEGER NOT NULL
);

-- Create book_loans table
CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    book_id INTEGER REFERENCES books(book_id),
    quantity INTEGER NOT NULL,
    loan_status VARCHAR(20) NOT NULL
);

-- Add at least three books
INSERT INTO books (title, available_copies)
VALUES
('Database Systems', 10),
('Computer Networks', 5),
('Data Structures', 2);

-- Display the tables
SELECT * FROM books;

SELECT * FROM book_loans;

DO $$
DECLARE
    copies INTEGER;
BEGIN
    SELECT available_copies
    INTO copies
    FROM books
    WHERE book_id = 1;

    IF copies = 0 THEN
        RAISE NOTICE 'The book is unavailable.';
    ELSIF copies <= 3 THEN
        RAISE NOTICE 'The book is low on copies.';
    ELSE
        RAISE NOTICE 'The book is sufficiently stocked.';
    END IF;
END $$;

DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN

    -- WHILE loop: three overdue reminders
    WHILE reminder_number <= 3 LOOP
        RAISE NOTICE 'Overdue reminder number: %', reminder_number;
        reminder_number := reminder_number + 1;
    END LOOP;

    -- Numeric FOR loop: three library shelf numbers
    FOR shelf_number IN 1..3 LOOP
        RAISE NOTICE 'Library shelf number: %', shelf_number;
    END LOOP;

END $$;

CREATE OR REPLACE PROCEDURE borrow_book(
    p_student_number VARCHAR,
    p_book_id INTEGER,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INTEGER;
BEGIN
    -- Check the available copies
    SELECT available_copies
    INTO available
    FROM books
    WHERE book_id = p_book_id;

    -- Check if the book exists
    IF available IS NULL THEN
        RAISE NOTICE 'Book does not exist.';
    
    -- Check if enough copies are available
    ELSIF available < p_quantity THEN
        RAISE NOTICE 'Not enough copies available.';
    
    ELSE
        -- Reduce available copies
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        -- Record the loan
        INSERT INTO book_loans (
            student_number,
            book_id,
            quantity,
            loan_status
        )
        VALUES (
            p_student_number,
            p_book_id,
            p_quantity,
            'Borrowed'
        );

        RAISE NOTICE 'Book borrowed successfully.';
    END IF;
END;
$$;

-- First valid loan
CALL borrow_book('202600001', 1, 2);

-- Second valid loan
CALL borrow_book('202600002', 2, 1);

-- Invalid loan: requesting more copies than available
CALL borrow_book('202600003', 3, 5);

SELECT * FROM books;

SELECT * FROM book_loans;

CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    loan_book_id INTEGER;
    loan_quantity INTEGER;
    current_status VARCHAR(20);
BEGIN
    -- Get the loan details
    SELECT book_id, quantity, loan_status
    INTO loan_book_id, loan_quantity, current_status
    FROM book_loans
    WHERE loan_id = p_loan_id;

    -- Check if the loan exists
    IF loan_book_id IS NULL THEN
        RAISE NOTICE 'Loan does not exist.';

    -- Check if the loan was already returned
    ELSIF current_status = 'Returned' THEN
        RAISE NOTICE 'This loan has already been returned. No copies restored.';

    ELSE
        -- Restore the available copies
        UPDATE books
        SET available_copies = available_copies + loan_quantity
        WHERE book_id = loan_book_id;

        -- Mark the loan as returned
        UPDATE book_loans
        SET loan_status = 'Returned'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Book returned successfully. Copies restored.';
    END IF;
END;
$$;

-- Return loan number 1
CALL return_book(1);

-- Try to return the same loan again
CALL return_book(1);

SELECT * FROM books;

SELECT * FROM book_loans;

DO $$
DECLARE
    book_record RECORD;

    book_cursor CURSOR FOR
        SELECT book_id, title, available_copies
        FROM books
        WHERE available_copies <= 3;
BEGIN
    OPEN book_cursor;

    LOOP
        FETCH book_cursor INTO book_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Book: %, Available copies: %',
            book_record.title,
            book_record.available_copies;
    END LOOP;

    CLOSE book_cursor;
END;
$$;
CREATE OR REPLACE PROCEDURE borrow_book(
    p_student_number VARCHAR,
    p_book_id INTEGER,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INTEGER;
BEGIN
    -- Reject zero or negative quantities
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity. Quantity must be greater than zero.';
    END IF;

    -- Check the available copies
    SELECT available_copies
    INTO available
    FROM books
    WHERE book_id = p_book_id;

    -- Check if the book exists
    IF available IS NULL THEN
        RAISE NOTICE 'Book does not exist.';

    ELSIF available < p_quantity THEN
        RAISE NOTICE 'Not enough copies available.';

    ELSE
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        INSERT INTO book_loans (
            student_number,
            book_id,
            quantity,
            loan_status
        )
        VALUES (
            p_student_number,
            p_book_id,
            p_quantity,
            'Borrowed'
        );

        RAISE NOTICE 'Book borrowed successfully.';
    END IF;
END;
$$;
DO $$
BEGIN
    CALL borrow_book('202600004', 1, 0);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Invalid quantity handled: %', SQLERRM;
END;
$$;

-- FINAL RESULTS FOR SCENARIO 1

SELECT * FROM books;

SELECT * FROM book_loans;