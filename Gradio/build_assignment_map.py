#
# assign student-friendly (?) names to question/rubric from the question bank
# and put the student-friendly name and the question, answer, rubric, and detailed rubric 
# into a JSON object so we are not parsing the files at runtime
#
# The Gradio backend will read from the assignment_map.json file this script creates
# to know which assignments it can provide feedback for, so when assignments or rubrics change
# we need to re-run this (probably from a CI/CD script tied to the question back git project).
#

import os
import json

def read_assignment_files(assignment_title, base_dir):
    result = {
        'question': '',
        'answer': '',
        'rubric': '',
        'detailed_rubric': ''
    }

    for filename in os.listdir(base_dir):
        file_path = os.path.join(base_dir, filename)
        if os.path.isfile(file_path):
            content = []
            with open(file_path, 'r') as f:
                for line in f:
                    stripped_line = line.lstrip()
                    if not (stripped_line.startswith('title:') or 
                            stripped_line.startswith('subtitle:') or 
                            stripped_line.startswith('---')):
                        content.append(line)
            content_str = ''.join(content)

            if filename.endswith('-Q.qmd'):
                result['question'] = content_str
            elif filename.endswith('-A.qmd'):
                result['answer'] = content_str
            elif filename.endswith('-R.qmd'):
                result['rubric'] = content_str
            elif filename.endswith('-RD.qmd'):
                result['detailed_rubric'] = content_str

    return {assignment_title.lower(): result}

def make_rules():
   rules = {}
   rules.update( read_assignment_files('homework1-Q1', 'question-bank/viz-midwest-histogram-binwidths') )
   rules.update( read_assignment_files('homework1-Q2', 'question-bank/viz-midwest-boxplot-outlier') )
   rules.update( read_assignment_files('homework1-Q3', 'question-bank/viz-midwest-scatterplot') )
   rules.update( read_assignment_files('homework1-Q4', 'question-bank/viz-midwest-county-area-state-boxplot') )
   rules.update( read_assignment_files('homework1-Q5', 'question-bank/viz-midwest-metropolitan-barchart-segmented') )

   return rules 

everything = make_rules()

with open('assignment_map.json', 'w', encoding='utf-8') as f:
            json.dump(everything, f, indent=4, ensure_ascii=False)