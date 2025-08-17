/*PHASE 2: VOD Database Implementation
Purpose: Table creation
Author: Ashley Shaw-Strand */


/* Safely remove tables during testing in REVERSE ORDER*/
DROP TABLE IF EXISTS movie_category CASCADE;
DROP TABLE IF EXISTS movie_advisory CASCADE;
DROP TABLE IF EXISTS movie_director CASCADE;
DROP TABLE IF EXISTS movie_actor CASCADE;
DROP TABLE IF EXISTS wishlist CASCADE;
DROP TABLE IF EXISTS rental CASCADE;
DROP TABLE IF EXISTS director CASCADE;
DROP TABLE IF EXISTS actor CASCADE;
DROP TABLE IF EXISTS advisory CASCADE;
DROP TABLE IF EXISTS movie CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS customer CASCADE;

-----------------------------------------------------------------------------------------------

/* Parent Tables */

--Customer

CREATE TABLE Customer(
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(12) NOT NULL CHECK (phone_number ~ '^[0-9]{3}\.[0-9]{3}\.[0-9]{4}$'),
    address VARCHAR(200) NOT NULL,
    postal_code VARCHAR(6) NOT NULL CHECK (postal_code ~ '^[A-Za-z][0-9][A-Za-z][0-9][A-Za-z][0-9]$'),
    credit_card_num VARCHAR(16) NOT NULL CHECK (credit_card_num ~ '^[0-9]+$'),
    credit_card_type VARCHAR(2) NOT NULL
);

ALTER TABLE Customer
    ADD CONSTRAINT chk_credit_card_type CHECK (credit_card_type IN ('AX', 'MC', 'VS'));

--Category

CREATE TABLE Category(
    category_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_category_id INT,
    FOREIGN KEY (parent_category_id) REFERENCES Category(category_id)
);

--Movie

CREATE TABLE Movie(
    movie_id INTEGER PRIMARY KEY,
    title VARCHAR(200) NOT NULL UNIQUE,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    rating VARCHAR(4)NOT NULL,
    sd_price DECIMAL(6,2) NOT NULL,
    hd_price DECIMAL(6,2) NOT NULL,
    CHECK (hd_price > sd_price),
    is_new_release BOOLEAN DEFAULT FALSE,
    is_most_popular BOOLEAN DEFAULT FALSE,
    is_coming_soon BOOLEAN DEFAULT FALSE
    
);

ALTER TABLE Movie
    ADD CONSTRAINT chk_rating_values CHECK (rating IN ('G', 'PG', '14A', '18A', 'R'));

--Advisory

CREATE TABLE Advisory(
    advisory_id INTEGER PRIMARY KEY,
    short_description VARCHAR(200) NOT NULL,
    full_description VARCHAR(500) NOT NULL
);

--Actor

CREATE TABLE Actor(
    actor_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL
);


--Director

CREATE TABLE Director(
    director_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL
);


--------------------------------------------------------------------------


/* Child Tables */


--Rental

CREATE TABLE Rental (
    rental_id INTEGER PRIMARY KEY,
    rental_date DATE NOT NULL,
    start_viewing_date DATE NOT NULL,
    expiry_date DATE NOT NULL CHECK (expiry_date > start_viewing_date),
    price_paid DECIMAL(6,2) NOT NULL,
    credit_card_num VARCHAR(16) NOT NULL CHECK (credit_card_num ~ '^[0-9]+$'),
    credit_card_type CHAR(2) NOT NULL CHECK (credit_card_type IN ('AX', 'MC', 'VS')),
    customer_rating INT NOT NULL,
    customer_id INT NOT NULL,
    movie_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id)
);

ALTER TABLE Rental
    ADD CONSTRAINT chk_customer_rating CHECK (customer_rating BETWEEN 1 AND 5);

--Wishlist

CREATE TABLE Wishlist (
    customer_id INT,
    movie_id INT,
    date_added DATE NOT NULL,
    PRIMARY KEY (customer_id,movie_id),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id)
);

---------------------------------------------------------------------------

/* Junction Tables */

--movie_actor

CREATE TABLE movie_actor(
    movie_id INT,
    actor_id INT,
    role_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (movie_id, actor_id),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (actor_id) REFERENCES Actor(actor_id)
);

--movie_director

CREATE TABLE movie_director(
    movie_id INT,
    director_id INT,
    PRIMARY KEY (movie_id, director_id),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (director_id) REFERENCES Director(director_id)
);

--movie_advisory

CREATE TABLE movie_advisory(
    movie_id INT,
    advisory_id INT,
    PRIMARY KEY (movie_id, advisory_id),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (advisory_id) REFERENCES Advisory(advisory_id)
);

--movie_category

CREATE TABLE movie_category(
    movie_id INT,
    category_id INT,
    PRIMARY KEY (movie_id, category_id),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (category_id) REFERENCES Category(category_id)
);