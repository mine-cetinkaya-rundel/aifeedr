This folder contains the Gradio backend code and the Docker build script for a container to run it.

For production use, we assume that there is an NGinx HTTPS proxy running in front of this container
amnd that we firewall access to this app so that only API calls originating on the servers where
RStudio is running can get to the app.

The LLM keys are read from environment variables, so you need to volume mount a .env file 
where the Docker container can get to it. These are the env vars that need to be present:

GRADIO_API_KEY - the OpenAI-style LLM key
GRADIO_LLM_MODEL - The LLM model
LITELLM_API_BASE - the base URL for the LLM. Either go direct to OpenAI or go through a LiteLLM proxy

We are also logging the answers and feedback to a postgress database so you will need a couple more 
env variables:

PGUSER - postgres db user
PGHOST - postgres host
PGHPORT - postgres port
PGPASSWORD - password for postgres user
PGDATABASE - database where the logs are stored

You should also create an activity_log table in the database something like this:

````` SQL

CREATE SEQUENCE activity_log_activity_log_key_seq;

CREATE TABLE activity_log (
    activity_log_key bigint NOT NULL DEFAULT nextval('activity_log_activity_log_key_seq'::regclass),
    session_id       text,
    assignment       text,
    action           text,
    detail           text,
    ts               timestamp with time zone
);

ALTER TABLE activity_log
  ALTER COLUMN ts SET DEFAULT current_timestamp;

`````

The session_id field is used to track which actions go together - for our purposes it works to
use the HOSTNAME of the docker container where RStudio is running, and the R SHiny code passes
the parameter to us along with the homework/assignment and the student's answer.


## student feedback backend

app.py runs the Gradio server that the R Shiny UI talks to 

## Instructor view

On a different port, you can run instructor_view.py to view the activity log





 