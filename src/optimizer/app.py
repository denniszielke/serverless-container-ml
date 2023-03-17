import os
import datetime
import base64
import requests
import os, uuid
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient
from io import BytesIO
from flask import Flask,request
app = Flask(__name__)

#code
storageAccount = os.getenv('STORAGE_ACCOUNT')
storageAccountConnectionString = os.environ.get('STORAGE_ACCOUNT_CONNECTIONSTRING')
print('>>>>>>>>STORAGE_ACCOUNT : '+ storageAccount )
print('>>>>>>>>STORAGE_ACCOUNT_CONNECTIONSTRING : '+ storageAccountConnectionString )

@app.route("/queueinput", methods=['POST'])
def incoming():
    incomingtext = request.get_data().decode()
    print(">>>>>>>Message Received: "+ incomingtext,flush="true")
    
    outputfile = "Msg_"+datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")+".mp3"
    base64_message = process_message(incomingtext,outputfile)

    print('>>>>>>Audio uploaded to storage.',flush="true")

    blob_service_client = BlobServiceClient.from_connection_string(connect_str)

    container_name = str(uuid.uuid4())

    container_client = blob_service_client.create_container(container_name)

    return "Incoming message successfully processed!"

if __name__ == '__main__':
    app.run(host="localhost", port=6000, debug=False)