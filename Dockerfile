FROM apache/airflow:2.11.0

# Accept host UID and GID
ARG HOST_UID=50000
ARG HOST_GID=50000

USER root

# Install required packages including FreeTDS and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unixodbc \
        unixodbc-dev \
        libodbc1 \
        odbcinst \
        iproute2 \
        net-tools \
        odbcinst1debian2 \
        freetds-bin \
        freetds-common \
        freetds-dev \
        libsybdb5 \
        libct4 \
        openjdk-17-jre \
        tdsodbc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install Microsoft ODBC Driver 17 for SQL Server directly
#RUN curl -sSL https://packages.microsoft.com/debian/12/prod/pool/main/m/msodbcsql17/msodbcsql17_17.10.5.1-1_amd64.deb -o msodbcsql17.deb && \
#   ACCEPT_EULA=Y dpkg -i msodbcsql17.deb && \
#   rm msodbcsql17.deb

# Install system build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure ODBC for FreeTDS
RUN echo "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nSetup=/usr/lib/x86_64-linux-gnu/odbc/libtdsS.so\nUsageCount=1" >> /etc/odbcinst.ini

# Configure FreeTDS
RUN echo "[global]\nTDS_Version = 7.0\nclient charset = UTF-8" > /etc/freetds/freetds.conf

# Ensure group exists (create only if missing)
RUN getent group airflow || groupadd -g ${HOST_GID} airflow

# Ensure user exists (create only if missing)
RUN id -u airflow >/dev/null 2>&1 || \
    useradd -u ${HOST_UID} -g airflow -m airflow

# If user already exists, adjust UID/GID only if needed
RUN CURRENT_UID=$(id -u airflow) && \
    CURRENT_GID=$(id -g airflow) && \
    if [ "$CURRENT_UID" != "$HOST_UID" ]; then usermod -u ${HOST_UID} airflow; fi && \
    if [ "$CURRENT_GID" != "$HOST_GID" ]; then groupmod -g ${HOST_GID} airflow; fi

USER airflow


#COPY requirements.txt /opt/airbyte-docker/airflow/include/scripts/requirements.txt
ENV PYTHONPATH=/opt/airflow/include:/opt/airbyte-docker/airflow/scripts:$PYTHONPATH

# Upgrade pip and install dependencies with retry options
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --timeout 1000 --retries 10 -r requirements.txt

# FROM apache/airflow:2.11.0

# RUN pip install --no-cache-dir apache-airflow-providers-airbyte==3.6.0
# # RUN pip install --no-cache-dir astronomer-cosmos[dbt-snowflake]==1.3.2

# ENV PIP_USER=false

# RUN python -m venv soda_venv && source soda_venv/bin/activate && \
#     pip install --no-cache-dir soda-core-snowflake==3.2.2 &&\
#     pip install --no-cache-dir soda-core-scientific==3.2.2 && deactivate

# RUN python -m venv dbt_venv && source dbt_venv/bin/activate && \
#     pip install --no-cache-dir dbt-snowflake==1.7.2 && deactivate

# ENV PIP_USER=true
