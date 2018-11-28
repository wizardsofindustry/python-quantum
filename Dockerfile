FROM wizardsofindustry/quantum-builder:python-3.6.5-slim-stretch
WORKDIR /app

COPY ./ /usr/local/src/quantum/
COPY requirements.txt /app/requirements.txt
RUN pip3 install -r requirements.txt
