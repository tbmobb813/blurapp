#!/usr/bin/env python3
"""
Fetch CI logs for the latest workflow run on branch comp/implement, download zip,
extract to logs/run-<id>/ and print failure excerpts.

Usage: python3 scripts/fetch_ci_logs.py
"""
import os
import sys
import time
import json
import re
import zipfile
from urllib.request import Request, urlopen

REPO = 'tbmobb813/blurapp'
BRANCH = 'comp/implement'
TOKEN_FILE = os.path.join(os.path.dirname(__file__), '..', '.secrets', 'gh_pat')

if not os.path.exists(TOKEN_FILE):
    print('ERROR: PAT file not found at', TOKEN_FILE, file=sys.stderr)
    sys.exit(2)

with open(TOKEN_FILE, 'r') as f:
    TOKEN = f.read().strip()

HEADERS = {
    'Authorization': f'token {TOKEN}',
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'ci-watcher'
}

def api_get(url, timeout=30):
    req = Request(url, headers=HEADERS)
    with urlopen(req, timeout=timeout) as resp:
        return json.load(resp)

try:
    print('Querying workflow runs for branch', BRANCH)
    url = f'https://api.github.com/repos/{REPO}/actions/runs?branch={BRANCH}&per_page=10'
    data = api_get(url)
    runs = data.get('workflow_runs', [])
    if not runs:
        print('No workflow runs found for branch', BRANCH)
        sys.exit(1)
    runs_sorted = sorted(runs, key=lambda r: r.get('created_at') or '', reverse=True)
    run = runs_sorted[0]
    run_id = str(run['id'])
    print('Found run id', run_id, 'status', run.get('status'), 'conclusion', run.get('conclusion'))

    jobs_url = f'https://api.github.com/repos/{REPO}/actions/runs/{run_id}/jobs'
    build_job = None
    attempts = 0
    while attempts < 120:
        attempts += 1
        jobs_data = api_get(jobs_url)
        jobs = jobs_data.get('jobs', [])
        for job in jobs:
            name = (job.get('name') or '').lower()
            if 'build' in name or 'build-test' in name or 'build apk' in name:
                build_job = job
                break
        if build_job:
            status = build_job.get('status')
            conclusion = build_job.get('conclusion')
            print(f'Attempt {attempts}: job id={build_job["id"]} name={build_job.get("name")} status={status} conclusion={conclusion}')
            if status == 'completed':
                break
        else:
            print('No build job found yet; jobs count=', len(jobs))
        time.sleep(6)
    else:
        print('Timed out waiting for build job to complete')
        sys.exit(3)

    # Download logs zip
    logs_url = f'https://api.github.com/repos/{REPO}/actions/runs/{run_id}/logs'
    zip_name = f'run-{run_id}-logs.zip'
    print('Downloading logs to', zip_name)
    req = Request(logs_url, headers=HEADERS)
    with urlopen(req, timeout=120) as resp:
        data = resp.read()
        with open(zip_name, 'wb') as f:
            f.write(data)
    print('Saved', zip_name, 'size=', os.path.getsize(zip_name))

    out_dir = os.path.join('logs', f'run-{run_id}')
    os.makedirs(out_dir, exist_ok=True)
    with zipfile.ZipFile(zip_name, 'r') as z:
        z.extractall(out_dir)
    print('Extracted to', out_dir)

    # Search for failure excerpts
    pattern = re.compile(r'ERROR|Error|FAILED|FAIL|Process completed with exit code|deprecated_member_use|Exception|Java heap space')
    matches = []
    for root, dirs, files in os.walk(out_dir):
        for fn in files:
            if 'build-test' in root or 'build-test' in fn or 'analyze-and-test' in root or 'build apk' in fn.lower():
                path = os.path.join(root, fn)
                try:
                    txt = open(path, errors='replace').read()
                except Exception:
                    continue
                if pattern.search(txt):
                    excerpt_lines = [line for line in txt.splitlines() if pattern.search(line)]
                    excerpt = '\n'.join(excerpt_lines)
                    matches.append((path, excerpt))

    if not matches:
        print('No obvious failure lines found in build-test logs; job may have succeeded.')
    else:
        print('\nFound failure excerpts:')
        for p, excerpt in matches:
            print('\n---', p, '---')
            print(excerpt[:8000])

    print('\nDone')

except Exception as e:
    print('Error during CI fetch:', e)
    sys.exit(4)
