from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive
import pandas as pd
import json


# Authenticate and create the PyDrive client.
# This only needs to be done once per notebook.

gauth = GoogleAuth("conf/pydrive_settings.yaml")

drive = GoogleDrive(gauth)


# PUT YOUR FILE ID AND ANY-NAME HERE
file_id = '1ERRCrr1lLqY65wR31CYfpGhBolYMnTjGukLWm03E1sA'
file_name = 'metadata.xlsx'
# Get contents of your drive file into the desired file. Here contents are stored in the file specified by 'file_name'
downloaded = drive.CreateFile({'id': file_id})
downloaded.GetContentFile(
    file_name, mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
df = pd.read_excel(file_name, usecols=None,
                   sheet_name="v1", engine='openpyxl')


df.set_index("id").rename(columns={"value": 'metadata'}).to_json(
    'site-content/src/_data/metadata.json')
