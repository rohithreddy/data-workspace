# Generated by Django 2.2.4 on 2019-10-24 08:21

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('applications', '0011_auto_20190917_1446'),
    ]

    operations = [
        migrations.AddField(
            model_name='applicationtemplate',
            name='visible',
            field=models.BooleanField(default=True),
        ),
    ]
