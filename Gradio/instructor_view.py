import gradio as gr
import pandas as pd
from sqlalchemy import create_engine
from itables import init_notebook_mode
init_notebook_mode(all_interactive=True)
import tempfile
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

# --------------------------
# NEW: Fetch database stats
# --------------------------
def fetch_db_stats():
    """Return total rows and unique sessions count."""
    try:
        query = """
            SELECT COUNT(*) AS total_rows,
                   COUNT(DISTINCT session_id) AS unique_sessions
            FROM activity_log;
        """
        df = pd.read_sql(query, engine)
        total_rows = int(df["total_rows"].iloc[0])
        unique_sessions = int(df["unique_sessions"].iloc[0])
        return f"📊 **Database Stats:** {total_rows:,} rows · {unique_sessions:,} unique sessions"
    except Exception as e:
        return f"⚠️ Error fetching stats: {str(e)}"


def get_session_ids():
    """Fetch distinct session_ids from database."""
    query = "SELECT DISTINCT session_id FROM activity_log ORDER BY session_id;"
    df = pd.read_sql_query(query, engine)
    ids = df["session_id"].dropna().astype(str).tolist()
    return ["ALL"] + ids

def fetch_activity_log(session_id="ALL"):
    """Fetch and filter activity_log table."""
    try:
        if session_id is None or session_id == "ALL":
            query = """
                SELECT assignment, 
                       to_char(ts, 'YYYY-MM-DD HH24:MI:SS') as ts,
                       session_id as session, 
                       CASE WHEN action = 'answer' THEN 'stu'
                            WHEN action = 'feedback' THEN 'llm'
                            ELSE action END AS who, 
                       detail
                FROM activity_log
                ORDER BY ts desc;
            """
            df = pd.read_sql(query, engine)
        else:
            query = """
                SELECT assignment, 
                       to_char(ts, 'YYYY-MM-DD HH24:MI:SS') as ts,
                       session_id as session, 
                       CASE WHEN action = 'answer' THEN 'stu'
                            WHEN action = 'feedback' THEN 'llm'
                            ELSE action END AS who, 
                       detail
                FROM activity_log
                WHERE session_id = %(session_id)s
                ORDER BY ts desc;
            """
            df = pd.read_sql(query, engine, params={"session_id": session_id})

        # keep the whole dataframe around in case we want to download the data
        global full_log_df 
        full_log_df = df.copy() #keep this around for downloads
        
        # keep full details, truncate for default display
        global full_details
        full_details = df["detail"].to_list()
        display_df = df.copy()
        display_df["detail"] = display_df["detail"].str.slice(0, 60)
        return display_df
    except Exception as e:
        return pd.DataFrame({"error": [str(e)]})

def show_full_detail(evt: gr.SelectData):
    """Triggered when a row is clicked in the dataframe"""
    row_index = evt.index[0]
    return full_details[row_index] if 0 <= row_index < len(full_details) else "[No detail]"

## download the activity log
def download_activity_log(session_id="ALL"):
    """Return a TSV file with the activity log """

    # Create a temporary directory
    tmpdir = tempfile.mkdtemp()
    filepath = os.path.join(tmpdir, "activity_log.tsv")

    # Save file as TSV with the correct name
    full_log_df.to_csv(filepath, sep="\t", index=False)
    return filepath
   
##

# plotting ###
from bokeh.plotting import figure
from bokeh.models import HoverTool, ColumnDataSource
from bokeh.palettes import Turbo256
from itertools import cycle
import random

def fetch_time_series(session_id="ALL"):
    if session_id == "ALL" or session_id is None or session_id == "":
        where_clause = ""
        params = None
    else:
        where_clause = "WHERE session_id = %(session_id)s"
        params = {"session_id": session_id}
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

    p = figure(
        title="Activity per Hour",
        x_axis_label="Hour",
        y_axis_label="Count",
        x_axis_type="datetime",
        width=1200,
        height=600,
        tools="pan,wheel_zoom,box_zoom,reset,save",
        sizing_mode="stretch_width"
    )

    # Add ±1h padding
    from datetime import timedelta
    xmin = df["hour_bucket"].min() - timedelta(hours=1)
    xmax = df["hour_bucket"].max() + timedelta(hours=1)
    p.x_range.start = xmin
    p.x_range.end = xmax


    hover = HoverTool(
        tooltips=[
            ("Session", "@session_id"),
            ("Hour", "@hour_bucket{%F %H:%M}"),
            ("Count", "@entry_count")
        ],
        formatters={"@hour_bucket": "datetime"}
    )
    p.add_tools(hover)

    marker_types = ["circle", "square", "triangle", "inverted_triangle"]
    marker_cycle = cycle(marker_types)
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

    p.legend.visible = False
    p.title.align = "center"
    return p

# --- Gradio UI ---
with gr.Blocks() as demo:
    with gr.Row():
        gr.Markdown("## Activity Log")
        stats_display = gr.Markdown(fetch_db_stats())


    with gr.Row():
        session_dropdown = gr.Dropdown(
            choices=get_session_ids(),
            label="Session ID",
            allow_custom_value=True,
            value="ALL"
        )

    table = gr.DataFrame(
        value=fetch_activity_log("ALL"),
        interactive=False,
        wrap=False,
        label="Click a row to see full details",
        elem_id="activity-log"
    )
    gr.Markdown("\n---\n### Detail")
    detail_placeholder = "<span style='color: gray; font-style: italic;'>Select a row to see details</span>"
    detail_view = gr.Markdown(detail_placeholder)
    table.select(show_full_detail, outputs=detail_view)

    gr.Markdown("\n\n---\n### Activity time series")
    plot_output = gr.Plot()

    with gr.Row():
        download_btn = gr.Button("📥 Download Activity Log")
        download_file = gr.File(label="Download Log", type="filepath")

    # update table + plot together when dropdown changes
    session_dropdown.change(
        fn=lambda sid: (fetch_activity_log(sid), fetch_time_series(sid), detail_placeholder),
        inputs=session_dropdown,
        outputs=[table, plot_output, detail_view]
    )

    # Connect download button to our new function
    download_btn.click(fn=download_activity_log,
                       inputs=session_dropdown,
                       outputs=download_file)

    # Auto-load both table and plot on page open
    demo.load(
        fn=lambda sid: (fetch_activity_log(sid), fetch_time_series(sid), detail_placeholder, fetch_db_stats()),
        inputs=[session_dropdown],
        outputs=[table, plot_output, detail_view, stats_display]
    )


if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860, share=False)
