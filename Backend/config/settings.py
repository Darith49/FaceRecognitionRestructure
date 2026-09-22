import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env
load_dotenv(BASE_DIR / '.env')

SECRET_KEY = os.environ.get(
    'SECRET_KEY',
    'django-insecure-face-attendance-mvp-secret-key-2026'
)

DEBUG = os.environ.get('DEBUG', 'True').lower() in ('true', '1', 'yes')

ALLOWED_HOSTS = [
    h.strip()
    for h in os.environ.get('ALLOWED_HOSTS', '*').split(',')
    if h.strip()
]

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'api.apps.ApiConfig',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Must be at the top
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

csrf_trusted_env = os.environ.get('CSRF_TRUSTED_ORIGINS')
if csrf_trusted_env:
    CSRF_TRUSTED_ORIGINS = [o.strip() for o in csrf_trusted_env.split(',') if o.strip()]
else:
    CSRF_TRUSTED_ORIGINS = [
        'https://*.trycloudflare.com',
        'http://localhost:8000',
        'http://127.0.0.1:8000',
    ]


ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = 'config.asgi.application'

# Database: SQLite for Year 3 University MVP
sqlite_db_env = os.environ.get('SQLITE_DB_PATH')
if sqlite_db_env:
    SQLITE_DB_PATH = Path(sqlite_db_env)
    if not SQLITE_DB_PATH.is_absolute():
        SQLITE_DB_PATH = BASE_DIR / SQLITE_DB_PATH
elif (BASE_DIR / 'data' / 'db.sqlite3').exists():
    SQLITE_DB_PATH = BASE_DIR / 'data' / 'db.sqlite3'
else:
    SQLITE_DB_PATH = BASE_DIR / 'db.sqlite3'

# Ensure directory for SQLite DB exists
SQLITE_DB_PATH.parent.mkdir(parents=True, exist_ok=True)

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': SQLITE_DB_PATH,
    }
}


# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Phnom_Penh'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# CORS settings for development and local network (mobile apps)
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

# Allow image uploads (up to 15MB)
DATA_UPLOAD_MAX_MEMORY_SIZE = 15 * 1024 * 1024
FILE_UPLOAD_MAX_MEMORY_SIZE = 15 * 1024 * 1024

# Django REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'api.permissions.FirebaseAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# Firebase Configuration
FIREBASE_CREDENTIALS_PATH = os.environ.get('FIREBASE_CREDENTIALS_PATH', '')
if not FIREBASE_CREDENTIALS_PATH:
    default_cred = BASE_DIR / 'face-recognition-attenda-230d3-firebase-adminsdk-fbsvc-255c00d255.json'
    data_cred_1 = BASE_DIR / 'data' / 'face-recognition-attenda-230d3-firebase-adminsdk-fbsvc-255c00d255.json'
    data_cred_2 = BASE_DIR / 'data' / 'firebase-credentials.json'
    if default_cred.exists():
        FIREBASE_CREDENTIALS_PATH = str(default_cred)
    elif data_cred_1.exists():
        FIREBASE_CREDENTIALS_PATH = str(data_cred_1)
    elif data_cred_2.exists():
        FIREBASE_CREDENTIALS_PATH = str(data_cred_2)
elif not os.path.isabs(FIREBASE_CREDENTIALS_PATH):
    # Check direct relative path, then data/ relative path
    candidate_1 = BASE_DIR / FIREBASE_CREDENTIALS_PATH
    candidate_2 = BASE_DIR / 'data' / FIREBASE_CREDENTIALS_PATH
    if candidate_1.exists():
        FIREBASE_CREDENTIALS_PATH = str(candidate_1)
    elif candidate_2.exists():
        FIREBASE_CREDENTIALS_PATH = str(candidate_2)
    else:
        FIREBASE_CREDENTIALS_PATH = str(candidate_1)
FIREBASE_PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID', 'face-recognition-attenda-230d3')

