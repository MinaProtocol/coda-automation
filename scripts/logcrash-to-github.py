#!/usr/bin/env python3

from glob import glob
import json
import os
import sys
import requests

# Authentication for user filing issue
try:
    USERNAME = os.environ['GITHUB_USER']
except KeyError:
    print('ERROR: Environent variable GITHUB_USER unset.')
    sys.exit(1)
try:
    # Use a developer token if you have 2FA
    PASSWORD = os.environ['GITHUB_PASSWORD']
except KeyError:
    print('ERROR: Environent variable GITHUB_PASSWORD unset.')
    sys.exit(1)

# The repository to add this issue to
REPO_OWNER = 'CodaProtocol'
REPO_NAME  = 'coda'


def make_github_issue(title, body=None, labels=None):
    '''Create an issue on github.com using the given parameters.'''
    # Our url to create issues via POST
    url = 'https://api.github.com/repos/%s/%s/issues' % (REPO_OWNER, REPO_NAME)
    # Create an authenticated session to create the issue
    session = requests.Session()
    session.auth = (USERNAME, PASSWORD)
    # Create our issue
    issue = {'title': title,
             'body': body,
             'labels': labels}
    # Add the issue to our repository
    r = session.post(url, json.dumps(issue))
    if r.status_code == 201:
        print ('Successfully created Issue {0:s}'.format(title))
        data = r.json()
        print ('URL: %s' % data['html_url'])
    else:
        print ('Could not create Issue {0:s}'.format(title))
        print ('Response:', r.content)

def yes_or_no(question):
    while "the answer is invalid":
        try:
            reply = str(input(question+' (y/n)[default: n]: ')).lower().strip()
        except KeyboardInterrupt:
            print('\nExiting')
            sys.exit(1)
        if len(reply) < 1:
            return False
        elif reply[0] == 'y':
            return True
        elif reply[0] == 'n':
            return False

if __name__ == "__main__":
    crashdirs = glob('test-coda-CRASH-*/coda.log')

    seen_exns = []
    for crashdir in crashdirs:
        with open(crashdir, encoding = "ISO-8859-1") as fp:
            for count, line in enumerate(fp):
                if 'Fatal' in line:
                    data = json.loads(line)
                    try:
                        exn = data['metadata']['exn'].replace("\\n",'').replace('\"','')[:120]
                    except KeyError:
                        exn = 'Unknown'

                    if exn in seen_exns:
                        # Duplicate
                        continue
                    else:
                        seen_exns.append(exn)

                    print('-'*80)
                    print(crashdir)
                    print('New: %s' % exn)
                    print(json.dumps(data, indent=4, sort_keys=True))
                    if yes_or_no('Create new issue?'):
                        # FIXME - how to attach gz to issue.
                        title = 'TESTING - CRASH - TESTNET - %s' % exn.strip()
                        body = 'Details:\n```'
                        body += json.dumps(data, indent=4, sort_keys=True)
                        body += '\n```'
                        make_github_issue(title=title,
                                body=body,
                                labels=['testnet', 'robot'])
