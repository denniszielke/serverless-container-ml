import os
import datetime
import base64
import requests
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

    return "Incoming message successfully processed!"

if __name__ == '__main__':
    app.run(host="localhost", port=6000, debug=False)