FROM ubuntu:18.04

# Variables de entorno
ENV PYTHON_VERSION=3.6.15
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV SPARK_VERSION=2.3.0
ENV HADOOP_VERSION=2.7
ENV SPARK_HOME="/opt/spark"
ENV PATH="$SPARK_HOME/bin:$PATH"

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias básicas
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    wget \
    curl \
    git \
    build-essential \
    software-properties-common \
    python3-pip \
    python3-dev \
    python3-setuptools \
    python3.6 \
    python3.6-dev \
    python3.6-venv \
    && apt-get clean

# Alias python3.6 como python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1

# Actualizar pip y añadir librerías Python necesarias
RUN python3.6 -m pip install --upgrade pip
RUN python3.6 -m pip install jupyterlab pandas matplotlib pyarrow pyspark==2.3.0

# Descargar y configurar Spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark && \
    rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Crear carpeta de trabajo
WORKDIR /app

# Exponer puerto de Jupyter
EXPOSE 8888

# Comando por defecto: lanzar Jupyter Lab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--no-browser"]
