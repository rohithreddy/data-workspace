# Generated by Django 2.2.3 on 2019-07-19 16:43

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0031_auto_20190718_0906'),
    ]

    operations = [
        migrations.AlterField(
            model_name='referencedatasetfield',
            name='name',
            field=models.CharField(help_text='The display name for the field', max_length=255),
        ),
    ]