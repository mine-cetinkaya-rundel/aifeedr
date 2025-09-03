This folder contains the Gradio backend code and teh Docker build script for a container to run it.

For production use, we assume that there is an Nginx HTTPS proxy running in front of this container
amnd that we firewall access to this app so that only API calls originating on the servers where
RStudio is running can get to the app.

The LLM keys are read from environment variables, so you need to volume mount a .env file 
where the Docker container can get to it. These are the env vars that need to be present:

GRADIO_API_KEY - the OpenAI-style LLM key
GRADIO_LLM_MODEL - The LLM model
LITELLM_API_BASE - the base URL for the LLM. Either go direct to OpenAI or go through a LiteLLM proxy



 