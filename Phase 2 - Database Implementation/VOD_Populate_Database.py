#PHASE 2: VOD Database Implementation
#Purpose: Data Population
#Author: Ashley Shaw-Strand
#Attributes: https://www.alberta.ca/how-alberta-classifies-films for short and full descriptions of advisories

#Installation-------------------------------------------------------------------------
# python install
# latest pip
# PostgreSQL adapter
# faker library for realistic data
#----------------------------------------------------------------------------------------

#python.exe -m pip install --upgrade pip
#pip install psycopg2-binary
#pip install faker

#---------------------------------------------------------------------------------------

import psycopg2
from faker import Faker
import random
from datetime import timedelta

#Canadian English realistic data
fake = Faker('en_CA')

#Database Connection
connection = psycopg2.connect(
    dbname = "VOD",
    user = "postgres",
    password = "admin",
    host="localhost"
)
cursor = connection.cursor()

#Lists for IDs for FK
customer_ids = []
movie_ids = []
actor_ids = []
director_ids = []
advisory_ids = []
category_ids = []


#function to get random ID from a list
def get_random_id(id_list):
    return random.choice(id_list) if id_list else 1


#Advisory Data

short_descriptions = [ "Coarse Language", "Language May Offend", "Violence", "Frightening Scenes",
    "Brutal Violence", "Gory Scenes", "Sexual Violence", "Nudity",
    "Sexually Suggestive Scenes", "Sexual Content", "Explicit Sexual Content",
    "Crude Content", "Substance Abuse", "Not Recommended For Young Children",
    "Not Recommended For Children", "Mature Subject Matter", "Disturbing Content"]

full_descriptions = ["Contains profanity, expletives, vulgar expressions, threats, slurs, sexual references or sexual innuendo.",
    "Contains language that may be offensive to some groups. It may include sacrilegious language, slurs or vulgar expressions.",
    "Contains scenes of violence, which could range from mild hand-to-hand combat to detailed portrayals of torture, depending upon the rating of the film.",
    "Contains images that may frighten a person, or are clearly intended to shock or scare.",
    "Contains detailed portrayals of violence that may include extreme brutality, bloody or gory violence, and may include images of torture, horror or war.",
    "Contains graphic images of bloody or gory violence, and may include images of torture, horror or war.",
    "Contains scenes of sexual violence, which could range from scenes of non-consensual sex acts to graphic portrayals of sexual assault, depending upon the rating of the film.",
    "Contains breast, buttock, genital nudity. Nudity can be portrayed in a sexual or a non-sexual context.",
    "Contains scenes that imply, rather than show, that sexual activity is taking place or has occurred.",
    "Contains sexual language, references, innuendo, and/or scenes of implied or simulated sexual activity.",
    "Contains sexual activity that is explicit and unsimulated, as in adult films that involve actual genital contact.",
    "Contains crude portrayals of bodily functions.",
    "Contains excessive alcohol use or the use of illegal substances.",
    "May be inappropriate for young children. For example, the subject matter could include the death of a family pet, a complicated family breakdown or images considered frightening or disturbing for the very young.",
    "May include scenes that reflect a more mature situation, such as drug use or abuse.",
    "Contains scenes or themes that may be upsetting or troubling to some. The film may contain portrayals of sexual violence, torture, deviant behaviour or cruelty.",
    "Contains images or storylines that may be challenging for minors. The film may contain portrayals of domestic violence, racism, religious matters, death or controversial social issues."]



#Realistic Categories

categories = [
    "Action", "Comedy", "Drama", "Horror", "Romance", "Sci-Fi",
    "Documentary", "Thriller", "Animation", "Fantasy", "Musical"
]


# Function to format phone number to xxx.xxx.xxxx
def format_phone_number():
    #10 random digits from the string below
    digits = ''.join(random.choices('0123456789', k=10))
    #format for xxx.xxx.xxxx
    return f"{digits[:3]}.{digits[3:6]}.{digits[6:]}"


# Sets to remove duplicates

#track use emails to avoid duplicates
used_emails = set()
# Track wishlist entries
wishlist_entries = set()
# Track movie and and advisory 
movie_advisory_links = set()
#Track movie and director
movie_director_links = set()


#-------------------------------------------------------------------------------------------------------------------

#Populate Our Tables

# Populate Customer

for i in range(1000):
    first_name = fake.first_name()
    last_name = fake.last_name()
    email = fake.email()
    while email in used_emails:
        email = fake.email()
    used_emails.add(email)
    #Format Phone # like 999.999.9999
    phone_number = format_phone_number()
    address = fake.street_address() + ', ' + fake.city()
    #Format PostalCode like L9L9L9 and must be 6 and no space
    postal_code = fake.postalcode().replace(' ', '')
    while len(postal_code) != 6:
        postal_code = fake.postalcode().replace(' ', '')
    credit_card_num = fake.credit_card_number().replace('-','')[:16]
    #Credit Card Type needs to be either American Express (AX), MasterCard (MC), or Visa (VS)
    credit_card_type = random.choice(['AX', 'MC', 'VS'])
    #Run a query to insert data into Customer
    cursor.execute("""
        INSERT INTO Customer (customer_id, first_name, last_name, email, phone_number, address, postal_code, credit_card_num, credit_card_type)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
        #Assign unique customer id and add to the customer_ids list
        (i + 1, first_name, last_name, email, phone_number, address, postal_code, credit_card_num, credit_card_type))
    customer_ids.append(i + 1)



# Populate Movie

for i in range(1000):
    #unique movie titles
    title = fake.catch_phrase() + ' ' + str(i + 1)
    #random movie durations between 1 and 3 hours (realistic time)
    duration_minutes = random.randint(60, 180)
    #movie rating from the canadian classifications
    rating = random.choice(['G', 'PG', '14A', '18A', 'R'])
    #random price for standard definition option
    sd_price = round(random.uniform(1,10), 2)
    #random price for high definition option that is > sd price
    hd_price = round(random.uniform(sd_price + 0.01, sd_price + 5.00), 2)
    is_new_release = random.choice([True, False])
    is_most_popular = random.choice([True, False])
    is_coming_soon = random.choice([True, False])
    #Run a query to insert data into Movie
    cursor.execute("""
        INSERT INTO Movie (movie_id, title, duration_minutes, rating, sd_price, hd_price, is_new_release, is_most_popular, is_coming_soon)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
        (i + 1, title, duration_minutes, rating, sd_price, hd_price, is_new_release, is_most_popular, is_coming_soon))
    movie_ids.append(i + 1)



# Populate Actor

for i in range(1000):
    first_name = fake.first_name()
    last_name = fake.last_name()
    #Realistic actor/actress ages, assuming child actors wouldn't have emails
    date_of_birth = fake.date_of_birth(minimum_age=15, maximum_age=80)
    #Run a query to insert data into Actor
    cursor.execute("""
        INSERT INTO Actor (actor_id, first_name, last_name, date_of_birth)
        VALUES (%s, %s, %s, %s)""",
        (i + 1, first_name, last_name, date_of_birth))
    actor_ids.append(i + 1)



# Populate Director

for i in range(1000):
    first_name = fake.first_name()
    last_name = fake.last_name()
    date_of_birth = fake.date_of_birth(minimum_age=20, maximum_age=90)
    #Run a query to insert data into Director
    cursor.execute("""
        INSERT INTO Director (director_id, first_name, last_name, date_of_birth)
        VALUES (%s, %s, %s, %s)""",
        (i + 1, first_name, last_name, date_of_birth))
    director_ids.append(i + 1)



# Populate Advisory 

for i in range(1000):
    #use the short and full description advisories
    index = i % len(short_descriptions)
    #short description sentence from selection
    short_description = short_descriptions[index]
    #same but for full description
    full_description = full_descriptions[index]
    #Run a query to insert data into Advisory
    cursor.execute("""
        INSERT INTO Advisory (advisory_id, short_description, full_description)
        VALUES (%s, %s, %s)""",
        #Add to advisory_ids
        (i + 1, short_description, full_description))
    advisory_ids.append(i + 1)



# Populate Category 

for i in range(1000):
    #go through the categories listed above
    index = i % len(categories)
    name = categories[index]
    parent_category_id = get_random_id(category_ids) if category_ids and random.choice([True, False]) else None
    #Run a query to insert data into Category
    cursor.execute("""
        INSERT INTO Category (category_id, name, parent_category_id)
        VALUES (%s, %s, %s)""",
        (i + 1, name, parent_category_id))
    category_ids.append(i + 1)



# Populate Rental 

for i in range(1000):
    #random date within the past year
    rental_date = fake.date_between(start_date="-1y", end_date="today")
    #viewing stats on or after the rental date
    start_viewing_date = fake.date_between(start_date=rental_date, end_date="today")
    #expiry date 24 hrs later than start view date
    expiry_date = start_viewing_date + timedelta(days=1)
    #random price between $5 and $15, to 2 decimal places
    price_paid = round(random.uniform(5, 15), 2)
    #fake 16 digit cc number
    credit_card_num = fake.credit_card_number().replace('-', '')[:16]
    #cc type matches these type/company cards
    credit_card_type = random.choice(['AX', 'MC', 'VS'])
    customer_rating = random.randint(1, 5)
    customer_id = get_random_id(customer_ids)
    movie_id = get_random_id(movie_ids)
    #Run a query to insert data into Rental
    cursor.execute("""
        INSERT INTO Rental (rental_id, rental_date, start_viewing_date, expiry_date, price_paid, credit_card_num, credit_card_type, customer_rating, customer_id, movie_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
        (i + 1, rental_date, start_viewing_date, expiry_date, price_paid, credit_card_num, credit_card_type, customer_rating, customer_id, movie_id))



# Populate Wishlist 

for i in range(1000):
    customer_id = get_random_id(customer_ids)
    movie_id = get_random_id(movie_ids)
    key = (customer_id, movie_id)

    # Skip if this pair already exists
    if key in wishlist_entries:
        continue

    wishlist_entries.add(key)
    date_added = fake.date_between(start_date="-1y", end_date="today")

    cursor.execute("""
        INSERT INTO Wishlist (customer_id, movie_id, date_added)
        VALUES (%s, %s, %s)""",
        (customer_id, movie_id, date_added))



# Populate Junction Tables 

for i in range(1000):

    # movie_actor
    cursor.execute("""
        INSERT INTO movie_actor (movie_id, actor_id, role_name)
        VALUES (%s, %s, %s)""",
        (get_random_id(movie_ids), get_random_id(actor_ids), fake.name()))
    
    # movie_director
    movie_id = get_random_id(movie_ids)
    director_id = get_random_id(director_ids)
    key = (movie_id, director_id)

    if key not in movie_director_links:
        movie_director_links.add(key)
        cursor.execute("""
            INSERT INTO movie_director (movie_id, director_id)
            VALUES (%s, %s)""",
            (movie_id, director_id))
    
    # movie_advisory
    movie_id = get_random_id(movie_ids)
    advisory_id = get_random_id(advisory_ids)
    key = (movie_id, advisory_id)

    if key not in movie_advisory_links:
        movie_advisory_links.add(key)
        cursor.execute("""
            INSERT INTO movie_advisory (movie_id, advisory_id)
            VALUES (%s, %s)""",
            (movie_id, advisory_id))
    
    # movie_category
    cursor.execute("""
        INSERT INTO movie_category (movie_id, category_id)
        VALUES (%s, %s)""",
        (get_random_id(movie_ids), get_random_id(category_ids)))



# Commit transaction and close connection
connection.commit()
cursor.close()
connection.close()
