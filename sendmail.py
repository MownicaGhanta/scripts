import sendgrid
import os
import logging
from sendgrid.helpers.mail import Mail, Email, To, Content
import json
import sys

logging.basicConfig(filename='sendmail.log',level=logging.INFO)

agency = sys.argv[1]
logging.info(f'Starting sendmail for {agency}')
file_path  = f'/home/{agency}/Inbound/'

# Get Sendgrid API Key
with open('/home/iirc-admin/creds/sendgrid.json') as json_file:
    data = json.load(json_file)
    SENDGRID_API_KEY = data['sendgrid']

# Set parameters for mail
files = [f for f in os.listdir(file_path) if os.path.isfile(os.path.join(file_path,f))]
send_text = json.dumps(files)
sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
from_email = Email('mghanta1@niu.edu')
to_email = [
                ('mghanta1@niu.edu', 'Mownica Ghanta'),
                ('dtyndorf@niu.edu', 'Darryl Tyndorf'),
           ]
subject = f'Automated transfer from {agency} box to Azure storage account'
content = Content('text/html', send_text)
mail = Mail(from_email, to_email, subject, content)

# Get a JSON-ready representation of the Mail object
mail_json = mail.get()

# Send an HTTP POST request to /mail/send
response = sg.client.mail.send.post(request_body=mail_json)
logging.info(response.status_code)
logging.info(response.headers)

logging.info(f'End sendmail for {agency}')
