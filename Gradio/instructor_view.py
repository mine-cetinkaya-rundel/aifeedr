import gradio as gr
import pandas as pd
from sqlalchemy import create_engine
from itables import init_notebook_mode, to_html_datatable

#  Enable interactive HTML output for itables
init_notebook_mode(all_interactive=True)

import os
from dotenv import load_dotenv
load_dotenv()

# settings for postgres logging
PGUSER = os.getenv('PGUSER')
PGHOST = os.getenv('PGHOST')
PGHPORT = os.getenv('PGHPORT')
PGPASSWORD = os.getenv('PGPASSWORD')
PGDATABASE= os.getenv('PGDATABASE')


# SQLAlchemy engine
engine = create_engine(
    f"postgresql+psycopg2://{PGUSER}:{PGPASSWORD}@{PGHOST}:{PGHPORT}/{PGDATABASE}"
)

def load_activity_log():
    """Fetch data from 'activity_log' and return interactive HTML table."""
    try:
        df = pd.read_sql("SELECT assignment, to_char(ts, 'YYYY-MM-DD HH24:MI:SS') as ts, session_id as session, CASE WHEN action = 'answer' THEN 'stu' WHEN action = 'feedback' THEN 'llm' ELSE action END AS who, detail FROM activity_log order by ts desc", engine)
#        print( df )
        return df
    except Exception as e:
        return f"<p style='color: red;'>Error fetching data: {e}</p>"

data = load_activity_log()
# Keep a reference to the full details in memory
full_details = data["detail"].to_list()

# For showing in the dataframe: truncate to 60 chars
display_data = data.copy()
display_data["detail"] = display_data["detail"].str.slice(0, 60)

def show_full_detail(evt: gr.SelectData):
    """Triggered when a row is clicked in the dataframe"""
    row_index = evt.index[0]   # evt.index returns (row, col); take row
    return full_details[row_index]

# --- Gradio UI ---
with gr.Blocks() as demo:
    gr.Markdown("### Activity Log Viewer")


    table = gr.DataFrame(
        value=display_data,
        interactive=False,   # read-only
        wrap=False,
        label="Click a row to see full details",
        elem_id="activity-log"
    )

    detail_view = gr.Markdown("")

    # Wire row selection to show_full_detail
    table.select(show_full_detail, outputs=detail_view)

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860, share=False)
