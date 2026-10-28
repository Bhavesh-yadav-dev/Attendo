import mysql.connector
import os
from dotenv import load_dotenv
#hello giys
# Load credentials from .env file
load_dotenv()

def get_connection():
    # Connect to MySQL database using credentials from .env
    connection = mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME")
    )
    return connection
