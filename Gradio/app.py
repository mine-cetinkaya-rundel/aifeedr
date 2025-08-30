from openai import OpenAI
import gradio as gr
from dotenv import load_dotenv
import os
import logging
import json
#logging.basicConfig(level=logging.DEBUG)
import gradio as gr

import re
from dotenv import load_dotenv
load_dotenv()

OPENAI_API_KEY = os.getenv("GRADIO_API_KEY")
LLM_MODEL = os.getenv("GRADIO_LLM_MODEL")
PROXY_URL = os.getenv("LITELLM_API_BASE")
CHATBOT_TITLE="<h3>R code feedback bot</h3>"

SYSTEM_PROMPT = """
{{ Question }}:
{{ Answer }}:
{{ Rubric }}:
{{ Student_response }}:
You are a helpful course instructor teaching a course on data science with the R programming language and the tidyverse and tidymodels suite of packages. You like to give succinct but precise feedback.

"Carefully read the {Question} and the {Rubric},
then evaluate {Student_response} against the {Rubric} to provide feedback. 
Be certain to spell out your reasoning so anyone can verify them.
Provide feedback in an output section named **Feedback:**. 
Format the feedback as bullet points. 
Each bullet point should first state the rubric item text from {Rubric}, 
and then provide one sentence explaining whether the {Student_response} meets the {Rubric} item.
Do not give away the correct answer in the feedback.
"""

client = OpenAI(
    base_url=PROXY_URL,
    api_key=OPENAI_API_KEY,
)
	
def generate_response(assignment, student_submission, history):
    messages = []

    # Add previous messages to the payload if they exist
    for message in history:
        messages.append({"role": message["role"], "content": message["content"]})

    # Add the current user message
    messages.append({"role": "user", "content": student_submission})

    # insert our custom system prompt at the beginning
    assignment_specifics = f"""
---
Question: 
{assignment['question']}
---
Rubric: 
{assignment['detailed_rubric']}
---
"""
    custom_prompt = SYSTEM_PROMPT + assignment_specifics
    messages.insert(0, {"role": "system", "content": custom_prompt } )
    try:
        response = client.chat.completions.create(
            model=LLM_MODEL,
            messages=messages
        )

        if len(response.choices) > 0:
            bot_response = response.choices[0].message.content
            # history.append({"role": "assistant", "content": bot_response})
        else:
            print(f"Unexpected response: {data}")
            #return "", history, [{"role": "assistant", "content": "No response received."}]
            bot_response = "No response received."

        # return history 
        return bot_response

    except Exception as e:
        print(f"Error processing input: {e}")
        return history ## , source_documents


def load_grading_rules():
    with open('assignment_map.json') as f_rules:
      return json.load(f_rules)

try:
    GRADING_RULES = load_grading_rules()
except Exception as e:
    GRADING_RULES = {}
    print(f"Error loading grading rules: {e}")

def grade_assignment(user_assignment_title, student_answer):
    assignment_title = user_assignment_title.lower()

    """Grade an assignment based on pre-defined rules"""
    if assignment_title not in GRADING_RULES:
        return "Error", f"Assignment '{user_assignment_title}' not found"
    else:
        fake_history = []
        assignment = GRADING_RULES[assignment_title]
        feedback = generate_response(assignment, student_answer, fake_history ) 
        return feedback

# Create Gradio interface
iface = gr.Interface(
    fn=grade_assignment,
    inputs=[
        gr.Textbox(label="Course Assignment"),
        gr.Textbox(label="Student Answer", lines=5)
    ],
    outputs=[
        gr.Textbox(label="Feedback")
    ],
    title="Course Assignment Feedback",
    description="Submit course assignment and student answer to get feedback"
)

# Launch the app with API endpoint
if __name__ == "__main__":
    iface.launch(server_name="0.0.0.0", server_port=7860, share=False)

