FROM pytorch/pytorch
COPY . /app
WORKDIR /app
USER root

RUN pip install flask
CMD python3 inferring.py