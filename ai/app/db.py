import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# "+psycopg" selects the psycopg 3 driver installed by requirements.txt. A
# plain "postgresql://" URL makes SQLAlchemy reach for psycopg2, which is not
# installed. Overridden by env/ai.env.
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://eduhist_ai:eduhist_ai@ai-postgres-lib-unb-ca:5432/eduhist_ai",
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base()