FROM python:3-alpine
COPY . /usr/src
WORKDIR /usr/src
RUN pip install -r requirements.txt
ENV FLASK_APP=app.py
EXPOSE 5000
CMD ["flask","run"]
