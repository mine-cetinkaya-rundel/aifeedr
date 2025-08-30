FROM quay.io/jupyter/minimal-notebook:x86_64-ubuntu-24.04

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update 
RUN apt-get dist-upgrade -y
RUN apt-get install -y \
    build-essential \
    postgresql \
    libpq-dev
RUN echo "force rebuild"
USER ${NB_UID}
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

RUN pip install  gradio  
RUN pip install  asyncio 
RUN pip install  requests    

RUN pip install  openai    
#RUN pip install  llama_index.llms.openai
#RUN pip install  llama_index.llms.azure_openai   
#RUN pip install  llama_index.embeddings.azure_openai  
#RUN pip install  llama_index.embeddings.huggingface   
#RUN pip install  llama_index.core  
#RUN pip install  llama_index.graph_stores.nebula   
#RUN pip install  llama_index.vector_stores.milvus   
RUN pip install  psycopg2

EXPOSE 7860

CMD python app.py
