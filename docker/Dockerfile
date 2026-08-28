ARG AIRFLOW_VERSION=3.3.1

FROM apache/airflow:${AIRFLOW_VERSION}

ARG AIRFLOW_VERSION

COPY requirements.txt /tmp/commerce-pulse-requirements.txt

RUN pip install --no-cache-dir \
    "apache-airflow==${AIRFLOW_VERSION}" \
    -r /tmp/commerce-pulse-requirements.txt
