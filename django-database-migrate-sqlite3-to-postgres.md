```bash
CREATE DATABASE my_project_db;
python manage.py dumpdata --exclude auth.permission --exclude contenttypes > datadump.json


# settings.py

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'my_project_db',
        'USER': 'your_postgres_username',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

python manage.py migrate


python manage.py loaddata datadump.json
```