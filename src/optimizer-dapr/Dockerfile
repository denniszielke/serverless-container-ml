FROM python:3.9-slim-buster
WORKDIR /app
RUN apt-get update && apt-get -y install gcc g++
RUN pip3 install --upgrade pip
COPY . . 
RUN pip3 install -r requirements.txt
ENTRYPOINT ["/app/startup.sh"]
