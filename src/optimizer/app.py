import os
import datetime
import base64
import requests
from gtts import gTTS
from io import BytesIO
from flask import Flask,request
app = Flask(__name__)

#code
daprPort = os.getenv('DAPR_HTTP_PORT')
daprGRPCPort = os.environ.get('DAPR_GRPC_PORT')
print('>>>>>>>>DAPR_HTTP_PORT : '+ daprPort )
print('>>>>>>>>DAPR_GRPC_PORT : '+ daprGRPCPort )

@app.route("/queueinput", methods=['POST'])
def incoming():
    incomingtext = request.get_data().decode()
    print(">>>>>>>Message Received: "+ incomingtext,flush="true")
    
    outputfile = "Msg_"+datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")+".mp3"
    base64_message = process_message(incomingtext,outputfile)

    url = 'http://localhost:'+daprPort+'/v1.0/bindings/bloboutput'
    uploadcontents = '{ "operation": "create", "data": "'+ base64_message+ '", "metadata": { "blobName": "'+ outputfile+'" } }'
    #print(uploadcontents)
    requests.post(url, data = uploadcontents)
    print('>>>>>>Audio uploaded to storage.',flush="true")

    return "Incoming message successfully processed!"

def process_message(incomingtext,outputfile):
    tts = gTTS(text=incomingtext, lang='en', slow=False)
    tts.save(outputfile)
    print('>>>>>>>Audio saved to ' + outputfile,flush="true")

    fin = open(outputfile, "rb")
    binary_data = fin.read()
    fin.close()
    base64_encoded_data = base64.b64encode(binary_data)
    base64_message = base64_encoded_data.decode('utf-8')

    return base64_message

if __name__ == '__main__':
    app.run(host="localhost", port=6000, debug=False)