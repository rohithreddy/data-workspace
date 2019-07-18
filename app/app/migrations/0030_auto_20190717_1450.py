# Generated by Django 2.2.3 on 2019-07-17 14:50

import django.core.validators
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0029_merge_20190717_1328'),
    ]

    operations = [
        migrations.AlterField(
            model_name='referencedatasetfield',
            name='name',
            field=models.CharField(
                help_text='Field name must start with a letter and may only contain lowercase letters, numbers and underscores (no spaces)', max_length=60, validators=[
                    django.core.validators.RegexValidator(message='Name must start with a character and contain only lowercase letters, numbers and underscores', regex='^[a-z][a-z0-9_\\.]*$')]),
        ),
    ]