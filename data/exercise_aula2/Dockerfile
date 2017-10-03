FROM python
COPY sample /opt/sample
WORKDIR /opt/sample
RUN apt-get update && apt-get install gcc libpq-dev -y && \
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    pip install -r requirements.txt

EXPOSE 8000
ENTRYPOINT ["/opt/sample/start.sh"]
