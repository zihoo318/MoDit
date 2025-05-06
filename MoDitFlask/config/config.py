from dotenv import load_dotenv
import os

load_dotenv()

NCLOUD_ACCESS_KEY = os.getenv("NCLOUD_ACCESS_KEY")
NCLOUD_SECRET_KEY = os.getenv("NCLOUD_SECRET_KEY")
NCLOUD_BUCKET_NAME = os.getenv("NCLOUD_BUCKET_NAME")
NCLOUD_ENDPOINT = os.getenv("NCLOUD_ENDPOINT")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
