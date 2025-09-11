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

# plotting ###
from bokeh.plotting import figure
from bokeh.models import HoverTool, ColumnDataSource
from bokeh.palettes import Turbo256
from itertools import cycle
import random

def get_session_ids():
    """Fetch distinct session_ids from database."""
    query = "SELECT DISTINCT session_id FROM activity_log ORDER BY session_id;"
    df = pd.read_sql_query(query, engine)
    ids = df["session_id"].dropna().astype(str).tolist()
    return ["ALL"] + ids   # Add an "ALL" option at the top


def fetch_time_series(session_id):
    if session_id == "ALL" or session_id is None or session_id == "":
        where_clause = ""
        params = None
    else:
        where_clause = "WHERE session_id = %(session_id)s"
        params = {"session_id": session_id}   # dict instead of list
    
    query = f"""
        SELECT 
            session_id,
            date_trunc('hour', ts) AS hour_bucket,
            COUNT(*) AS entry_count
        FROM activity_log
        {where_clause}
        GROUP BY session_id, hour_bucket
        ORDER BY session_id, hour_bucket;
    """
    df = pd.read_sql_query(query, engine, params=params)

    if df.empty:
        p = figure(title="No Data Found", x_axis_type="datetime", width=700, height=400)
        return p

    # Create plot
    p = figure(
        title="Activity per Hour",
        x_axis_label="Hour",
        y_axis_label="Count",
        x_axis_type="datetime",
        width=1200,
        height=600,
        tools="pan,wheel_zoom,box_zoom,reset,save",
        sizing_mode="stretch_width"  # fills available space
    )

    hover = HoverTool(
        tooltips=[
            ("Session", "@session_id"),
            ("Hour", "@hour_bucket{%F %H:%M}"),
            ("Count", "@entry_count")
        ],
        formatters={"@hour_bucket": "datetime"}
    )
    p.add_tools(hover)

    # Define marker shapes to cycle through
    marker_types = [ "circle", "square", "triangle", "inverted_triangle" ]
    marker_cycle = cycle(marker_types)   # infinite cycle through shapes

    # Use Turbo256 palette for colors
    colors = list(Turbo256)
    random.shuffle(colors)
    color_cycle = cycle(colors)

    for i, (sid, subdf) in enumerate(df.groupby("session_id")):
        source = ColumnDataSource(subdf)
        color = next(color_cycle)
        marker = next(marker_cycle)
        p.scatter("hour_bucket", "entry_count", source=source,
                  size=9, marker=marker, color=color,
                  legend_label=str(sid))

    #p.legend.location = "top_left"
    p.legend.visible = False
    p.title.align = "center"
    return p


# Build dropdown options dynamically at launch
session_choices = get_session_ids()

# --- Gradio UI ---
with gr.Blocks() as demo:
    gr.Markdown("### Activity Log")
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

    # plot usage 
    gr.Markdown("### 📊 Activity Log Time Series\nActivity_log entries grouped into 1-hour buckets.")

    with gr.Row():
        session_dropdown = gr.Dropdown(
            choices=get_session_ids(),
            label="Session ID",
            allow_custom_value=True,   # you can type into the dropdown
            value="ALL"
        )

    plot_output = gr.Plot() # label="Activity Log Time Series")

    # Auto-generate when dropdown value changes
    session_dropdown.change(fetch_time_series, inputs=session_dropdown, outputs=plot_output)

    # Auto-generate plot on page load (default to "ALL")
    demo.load(fn=fetch_time_series, inputs=[session_dropdown], outputs=plot_output)


if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860, share=False)

