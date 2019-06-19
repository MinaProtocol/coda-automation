#! /usr/bin/env python3

""" Extract and attempt to make a signature of an ocaml traceback """
import glob
import os
import subprocess
import re
import hashlib
import sys
import json
from dateutil.parser import parse
import socket

""" Wrap os tail call, doing it in native python was wasy too difficult """
def tail(fileName, n):
    p=subprocess.Popen(['tail','-n',str(n), fileName], stdout=subprocess.PIPE)
    soutput,_ =p.communicate()
    return soutput.decode('utf-8')

""" Hack way to get current coda version - using dpkg until we have coda --version """
def coda_version():
    cmd = 'dpkg -l'
    p=subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    soutput,_ = p.communicate()
    output = ''
    for line in soutput.decode('utf-8').splitlines(True):
        if 'coda-testnet' in line:
            output = re.sub(' +', ' ', line).rstrip()
    return output

""" Collect lines beginning with the error condition - start of trace """
def find_error(string):
    output = ''
    for line in string.splitlines(True):
        # First line
        if 'monitor.ml.Error' in line:
            output += line
            # parse timestamp from previous line
            try:
                data = json.loads(lastline)
                mytime  = parse(data['timestamp']).timestamp()
            except:
                print('Error parsing timestamp from: %s' % lastline)
                mytime = 0
        elif len(output) > 0:
            # continue appending trace output
            output += line
        else:
            # haven't hit error yet, keep looking
            lastline = line
    return(output, mytime)


""" Mask out actual line numbers and collumns, generate a signature based on stripped data """
def error_sig(string):
    output = ''
    for line in string.splitlines(True):
        if 'Called' in line or 'Raised' in line:
            line = re.sub("line (\d+), characters (\d+)-(\d+)", "line HIDDEN, characters HIDDEN", line)
        output += line
    sig = hashlib.md5(output.encode('utf-8')).hexdigest()
    return(sig)


if __name__ == '__main__':
    logfiles=glob.glob('./test-*/coda.log')
    output = {}
    for filename in logfiles:
        tailcontent = tail(filename, 30)
        if 'monitor.ml.Error' in tailcontent:
            (myerror, mytime) = find_error(tailcontent)
            mysig = error_sig(myerror)
            output['hostname'] = socket.gethostname()
            output['filename'] = filename
            output['signature'] = mysig
            output['crash_timestamp'] = mytime
            output['full_error'] = myerror
            output['coda_version'] = coda_version()
            print(json.dumps(output, indent=4, sort_keys=True))
