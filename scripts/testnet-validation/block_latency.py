# program to get average block latency without including the time taken  to create the diff or validate
# Subscribes to logs on stackdriver from a testnet to find block-received-time - block-sent-time using the timestamp of the log
# writes the data to a csv file for finding the required stats
#Needs python 3.7 or above

from google.cloud import pubsub_v1
from google.cloud import logging
import json
from datetime import datetime
from datetime import timedelta
import uuid
import time
import csv
import click
import glob

uuid = str(uuid.uuid1())

name = 'block_latency'+'_'+uuid
latency_data_file = name +'.csv'

block_event_file = 'block_event'+'_'+uuid+'.csv'

def resource_name(name, project_id):
    return 'projects/{project_id}/{res}/{t}'.format(
    project_id=project_id,
    res=name,
    t='block_latency'+'_'+uuid,  # Set this to something appropriate.
)

block_received_filter = "Received a block from" #host is the receiver, recieved timestamp, received state hash and sender
block_broadcasted_filter = "Broadcasting new state over gossip net" #host is the source, sent timestamp, sent state_hash

block_rebroadcast_filter = "Rebroadcasting $state_hash"  #host is the sender, received timestamp, and received state_hash

block_generation_started = "Producing new block with parent $breadcrumb"  #host is the creator, generation start timestamp, and parent state_hash

block_production = "Successfully produced a new block" #host is the creator, generation end timestamp, and state_hash

project_id = "o1labs-192920"
topic_name = resource_name('topics', project_id)
subscription_name = resource_name('subscriptions', project_id)
sink_name= name

csv_header = ["state_hash", "sender", "block_creation_start_timestamp", "sender_timestamp", "receiver", "receiver_timestamp", "rebroadcast_timestamp", "from_creator"]

event_data_header = ["event", "host", "parent_state_hash", "state_hash", "timestamp, ""sender", "is_rebroadcast"]
#Generate, host, parent_state_hash, "", creation_state_timestamp, "", ""
#Send, host, parent_state_hash, sent_state_hash, sent_timestamp, "", T/F
#Receive, host, "", received_state_hash, received_timestamp, sender, ""

event_generate = "Generate"
event_send = "Send"
event_receive = "Receive"



def time_diff(start, end):
    start = datetime.fromisoformat(start.replace("Z", "+00:00"))
    end = datetime.fromisoformat(end.replace("Z", "+00:00"))
    diff = (end-start)/(timedelta(milliseconds=1))
    return diff

def stat_of_event_file(directory):
    creators = dict ()
    senders_parent_state_hash = dict () #for calculating block production time
    senders = dict ()
    receivers = dict ()
    event_file_list = glob.glob('block_event*')
    for file in event_file_list:    
        with open(file, 'r') as data_file:
            reader = csv.reader(data_file, delimiter=',')
            next(reader) #skip header
            for [event, host, parent_state_hash, state_hash, timestamp, sender, is_rebroadcast] in reader:
                if (event==event_generate):
                    if parent_state_hash in creators:
                        hosts = creators[parent_state_hash]
                    else:
                        hosts = dict()
                    hosts[host]=timestamp
                    creators[parent_state_hash]=hosts
                elif (event==event_send):
                    if not(is_rebroadcast):
                        if parent_state_hash in senders_parent_state_hash:
                            hosts = senders_parent_state_hash[parent_state_hash]
                        else:
                            hosts = dict()
                        hosts[host]=timestamp
                        senders_parent_state_hash[parent_state_hash]=hosts
                    if state_hash in senders:
                        hosts = senders[state_hash]
                    else:
                        hosts= dict()
                    hosts[host]=(timestamp, is_rebroadcast)
                    senders[state_hash]=hosts
                elif (event==event_receive):
                    if state_hash in receivers:
                        hosts = receivers[state_hash]
                    else:
                        hosts= dict()
                    hosts[host]=(timestamp, sender)
                    receivers[state_hash]=hosts
                else:
                    print("Invalid event {}".format(event))
    #calculate block production time
    block_production_times = []
    for (parent_state_hash, hosts) in senders_parent_state_hash.items():
        for (host, sent_timestamp) in hosts.items():
            if (parent_state_hash in creators) and (host in creators[parent_state_hash]):
                diff = time_diff(creators[parent_state_hash][host],sent_timestamp )
                list.append(block_production_times, diff)
    #calculate single-hop-times, validation-times, total_gossip_times
    single_hop_times = []
    total_gossip_time = dict()
    validation_times = []
    for (state_hash, hosts) in senders.items():
        for(host, (sent_timestamp, is_rebroadcast)) in hosts.items():
            if not(is_rebroadcast):
                total_gossip_time[state_hash] = (sent_timestamp,"", 0) #sent-time, received-time, received-block-count
    for (state_hash, hosts) in receivers.items():
        for(host, (received_timestamp, sender)) in hosts.items():
            #single hop time
            if (state_hash in senders) and (sender in senders[state_hash]):
                sent_timestamp, is_rebroadcast = senders[state_hash][sender]
                diff = time_diff(sent_timestamp,received_timestamp)
                print("SH diff:{}\n".format(diff))
                list.append(single_hop_times, diff)
            #total gossip time
            if state_hash in total_gossip_time:
                sent_timestamp, latest_received_timestamp, received_block_count = total_gossip_time[state_hash]
                if latest_received_timestamp=="":
                    latest_received_timestamp=received_timestamp
                    received_block_count=1
                else:
                    diff = time_diff(latest_received_timestamp,received_timestamp)
                    received_block_count=received_block_count+1
                    if diff < 0:
                        latest_received_timestamp=received_timestamp
                total_gossip_time[state_hash]=(sent_timestamp, latest_received_timestamp, received_block_count)
            #validation time
            if (state_hash in senders) and (host in senders[state_hash]):
                host_sent_timestamp, is_rebroadcast = senders[state_hash][host]
                diff = time_diff(received_timestamp, host_sent_timestamp)
                list.append(validation_times, diff)
    #print stats
    print("creators: {}\n senders_parent: {}\n senders: {}\n receivers: {}\n".format(creators, senders_parent_state_hash, senders, receivers))
    list.sort(block_production_times)
    list.sort(validation_times)
    list.sort(single_hop_times)
    print("block production times:{}\n".format(block_production_times))
    print("single_hop_times {}\n".format(single_hop_times))
    print("validation times {}\n".format(validation_times))
    #total gossip time
    total_gossip_time_list=[]
    for (state_hash,(sent,latest_received,received_count)) in total_gossip_time.items():
        diff = time_diff(sent,latest_received_timestamp)
        list.append(total_gossip_time_list,(diff, received_count))
    print("total gossip times {}\n".format(total_gossip_time_list))
    avg_bp=(sum(block_production_times,0.0))/(max(len(block_production_times),1))
    print("Average block production time(ms): {}".format(avg_bp))
    avg_hop=(sum(single_hop_times,0.0))/(max(len(single_hop_times),1))
    print("Average single hop time(ms): {}".format(avg_hop))
    avg_vt=(sum(validation_times,0.0))/(max(len(validation_times),1))
    print("Average validation time(ms): {}".format(avg_vt))



@click.group()
@click.option('--debug/--no-debug', default=False)
def cli(debug):
    pass

@cli.group()
def generate():
  pass

@cli.group()
def stats():
  pass

@generate.command()
@click.option('--namespace', default="hard-fork", help='Namespace to Query.')
@click.option('--source', default="cloud", help='cloud/local for the source of logs')
@click.option('--log-directory', default=".", help='Local directory containing log files')
@click.option('--event-directory', default=".", help='Local directory to store event data files')
def start(namespace, source, directory):

    def filter(namespace):
        return """
            resource.type="k8s_container"
            resource.labels.namespace_name="{}"
            resource.labels.pod_name:"block-producer"
            ("{}" OR "{}" OR "{}" OR "{}" OR "{}")
            """.format(namespace, block_received_filter, block_broadcasted_filter, block_rebroadcast_filter, block_production, block_generation_started )

    def setup(namespace):
        publisher = pubsub_v1.PublisherClient()
        subscriber = pubsub_v1.SubscriberClient()
        logging_client = logging.Client()
        sink_destination = 'pubsub.googleapis.com/{}'.format(topic_name)
        print ('creating topic: {}'.format(topic_name))
        topic = publisher.create_topic(topic_name)
        print ('creating sink:{}'.format(sink_name))
        sink = logging.sink.Sink(sink_name, filter(namespace), sink_destination, logging_client)
        sink.create()
        print ('creating subscription:{}'.format(subscription_name))
        subscription = subscriber.create_subscription(subscription_name, topic_name)
        print('finished setting up')
        return (sink, publisher, subscriber)

    #block producers
    creators = dict()

    #for all the broadcasts and rebroadcasts
    senders = dict()

    #for all the received blocks
    receivers = dict()

    block_latency = dict()


    def exists(str, sub):
        return (str.find(sub) != -1)

    logline_creation = '''{
    "insertId": "7jk4vufvm7qmbtsbp",  
    "jsonPayload": {
    "level": "Trace",   
    "message": "Producing new block with parent $breadcrumb",   
    
    "metadata": {
    
        "breadcrumb": {
        "just_emitted_a_proof": false,     
        "staged_ledger": "<opaque>",     
        
        "validated_transition": { 
        "data": "Blah",     
        "hash": "D2rcXVQa8JD878CRDfvHaC2oCNf1ZutuTBWY7FATVc3omzMAAWB9ahfgp8aLzg3Y9xijU1T6D1Zb9YWF5W8nwHL1bBtHukwpwchuj6iQ36WaToETLEAUrXoSPiUCeJJk6ekYRURqaxtREmjdmKfecVCibJE1JQ6jBnX7FCnNmcmG43uPyYktUdw6k4MB6dxCFX4CubUJGVbzBrDWtVsURUijUKWR5C9V4ge5xyQkfHz5MmyS4Mh7vZLCSnvTwoNEnUdVDvWL6TVxyaZho5wpGHZrnL6r4jGhYY1pGKaUZPXmidGJBBSnHMTVmrF9c64E19"      
        }
    },
    "host": "104.196.130.255",    
    "peer_id": "12D3KooWKvJun7JntFvHgWQs2KB8zwomBcFvzhGmRQdhCni77xCo",    
    "pid": 10,    
    "port": 10010  
    },
    
    "source": "Blah",  
    "timestamp": "2020-07-23 22:16:21.012086Z"   
    },
    
    "labels": "Blah",  
    "logName": "projects/o1labs-192920/logs/stdout",  
    "receiveTimestamp": "2020-07-23T22:16:27.578325493Z",  
    "resource": "Blah",  
    "severity": "INFO",  
    "timestamp": "2020-07-13 09:45:44.814576Z"  
    }'''

    logline_sent = '''{
    "insertId": "p2qohfk1emyqq1d87",
    "jsonPayload": {
    "event_id": "1545437164f4a0cb00c4a91f08783290",
    "level": "Trace",
    "message": "Broadcasting new state over gossip net",
    "metadata": {
    "host": "104.196.130.255",
    "peer_id": "12D3KooWKvJun7JntFvHgWQs2KB8zwomBcFvzhGmRQdhCni77xCo",
    "pid": 10,
    "port": 10009,
    "message": [
        "New_state",    
        {
            "current_protocol_version": "0.1.0",      
            "delta_transition_chain_proof": "<opaque>",    
            "proposed_protocol_version": "<None>",    
            "protocol_state": {
            "body": "blah",      
            "previous_state_hash": "D2rcXVQa8JD878CRDfvHaC2oCNf1ZutuTBWY7FATVc3omzMAAWB9ahfgp8aLzg3Y9xijU1T6D1Zb9YWF5W8nwHL1bBtHukwpwchuj6iQ36WaToETLEAUrXoSPiUCeJJk6ekYRURqaxtREmjdmKfecVCibJE1JQ6jBnX7FCnNmcmG43uPyYktUdw6k4MB6dxCFX4CubUJGVbzBrDWtVsURUijUKWR5C9V4ge5xyQkfHz5MmyS4Mh7vZLCSnvTwoNEnUdVDvWL6TVxyaZho5wpGHZrnL6r4jGhYY1pGKaUZPXmidGJBBSnHMTVmrF9c64E19" }
        }
    ],
    "state_hash": "D2rcXVQYb3XHXzC9yW8jXRfF1fwVvHJ2xf4zPT5MUV67vjdi5vqjfEjZeQf6caypG1CAWHAj1cPyW7nmxQDM28M6iSyCcqt5mj1iMzjhBV5bGGyCkexCEoZZQugaCHxrfR1AbqjUVoFCdPdLhSK1CffWEBmiJTZGFw7ardLH8N4wK77R1pQ5bBBZNLo8V6fTyM4Nn4cyrVvkJUjx6UxgBdprKwrbNPP5PScSDHKqhbrNzo9eG45dXyJcAkSUU1ZjibvsCRuYVcevLGJqiD4U9kbs7LZmk3oLrQxzmeUmG45jjSeojVaqyMPgYTEHfStLdg"
    },
    "timestamp": "2020-07-13 09:50:44.814576Z"
    },
    "logName": "projects/o1labs-192920/logs/stdout",
    "receiveTimestamp": "2020-07-13T09:50:50.976162692Z",
    "severity": "INFO",
    "timestamp": "2020-07-13T09:50:45.147454542Z"
    }'''

    logline_received1 = '''{
    "insertId": "5e48wcczjk0ri1v90",
    "jsonPayload": {
    "event_id": "586638300e6d186ec71e4cf1e1808a1b",  
    "level": "Debug",
    "message": "Received a block from $sender",
    "metadata": {   
    "host": "34.74.83.1",
    "peer_id": "12D3KooWCqPhx9nMw4ZB1RRay7WKYpBjT7pYeZr1Tv3YBqQ3pYqm",
    "pid": 10,
    "port": 10015, 
    "sender": {
            "Remote": {
            "host": "104.196.130.255",
            "peer_id": "12D3KooWKvJun7JntFvHgWQs2KB8zwomBcFvzhGmRQdhCni77xCo"      
        }
    },
    "state_hash": "D2rcXVQYb3XHXzC9yW8jXRfF1fwVvHJ2xf4zPT5MUV67vjdi5vqjfEjZeQf6caypG1CAWHAj1cPyW7nmxQDM28M6iSyCcqt5mj1iMzjhBV5bGGyCkexCEoZZQugaCHxrfR1AbqjUVoFCdPdLhSK1CffWEBmiJTZGFw7ardLH8N4wK77R1pQ5bBBZNLo8V6fTyM4Nn4cyrVvkJUjx6UxgBdprKwrbNPP5PScSDHKqhbrNzo9eG45dXyJcAkSUU1ZjibvsCRuYVcevLGJqiD4U9kbs7LZmk3oLrQxzmeUmG45jjSeojVaqyMPgYTEHfStLdg"    
    },
    "timestamp": "2020-07-13 09:51:44.814576Z"   
    },
    "logName": "projects/o1labs-192920/logs/stdout" ,
    "receiveTimestamp": "2020-07-13T08:31:18.549928642Z",   
    "severity": "INFO",
    "timestamp": "2020-07-13T08:31:16.161410312Z"  
    }'''

    logline_received2 = '''{
    "insertId": "5e48wcczjk0ri1v90",
    "jsonPayload": {
    "event_id": "586638300e6d186ec71e4cf1e1808a1b",  
    "level": "Debug",
    "message": "Received a block from $sender",
    "metadata": {   
    "host": "34.74.83.5",
    "peer_id": "12D3KooWCqPhx9nMw4ZB1RRay7WKYpBjT7pYeZr1Tv3YBqQ3pYqm",
    "pid": 10,
    "port": 10015, 
    "sender": {
            "Remote": {
            "host": "104.196.130.255",
            "peer_id": "12D3KooWKvJun7JntFvHgWQs2KB8zwomBcFvzhGmRQdhCni77xCo"      
        }
    },
    "state_hash": "D2rcXVQYb3XHXzC9yW8jXRfF1fwVvHJ2xf4zPT5MUV67vjdi5vqjfEjZeQf6caypG1CAWHAj1cPyW7nmxQDM28M6iSyCcqt5mj1iMzjhBV5bGGyCkexCEoZZQugaCHxrfR1AbqjUVoFCdPdLhSK1CffWEBmiJTZGFw7ardLH8N4wK77R1pQ5bBBZNLo8V6fTyM4Nn4cyrVvkJUjx6UxgBdprKwrbNPP5PScSDHKqhbrNzo9eG45dXyJcAkSUU1ZjibvsCRuYVcevLGJqiD4U9kbs7LZmk3oLrQxzmeUmG45jjSeojVaqyMPgYTEHfStLdg"    
    },
    "timestamp": "2020-07-13 09:50:48.813576Z"   
    },
    "logName": "projects/o1labs-192920/logs/stdout" ,
    "receiveTimestamp": "2020-07-13T08:31:18.549928642Z",   
    "severity": "INFO",
    "timestamp": "2020-07-13T08:31:16.161410312Z"  
    }'''

    def host_str(metadata):
        return (metadata["host"]+"/"+metadata["peer_id"])

    def process_payload(jsonPayload):
        log_message = jsonPayload["message"]
        print ("log message: {}".format(log_message))
        timestamp = jsonPayload["timestamp"]
        #print ("timestamp: {}".format(timestamp))
        metadata = jsonPayload["metadata"]
        host = host_str(metadata)
        print("host: {}\n".format(host))
        print ("host: {}".format(host))
        if exists(log_message, block_broadcasted_filter):
            print ("new block broadcasted")
            state_hash = metadata["state_hash"]
            parent_hash = (metadata["message"][1])["protocol_state"]["previous_state_hash"]
            print ("state_hash: {}".format(state_hash))
            if state_hash in senders:
                s = senders[state_hash]
            else:
                s = dict()
            s[host] = (timestamp, parent_hash, False) #timestamp and if it is rebroadcast
            print("setting broadcast sender:{}".format(s[host]))
            senders[state_hash] = s
        else:
            if exists(log_message, block_rebroadcast_filter):
                print ("block rebroadcasted")
                state_hash = metadata["state_hash"]
                parent_hash = (metadata["external_transition"]["data"])["protocol_state"]["previous_state_hash"]
                print ("state_hash: {}".format(state_hash))
                if state_hash in senders:
                    s = senders[state_hash]
                else:
                    s = dict()
                if not(host in s): #don't log duplicate rebroadcasting?
                        s[host] = (timestamp, parent_hash, True)
                else:
                    print("Error! Duplicate rebroadcasting") #should not hit this because we invalidate duplicate blocks
                senders[state_hash] = s
            else:
                if exists(log_message, block_received_filter):
                    print ("block received")
                    state_hash = metadata["state_hash"]
                    print ("state_hash: {}".format(state_hash))
                    sender_b = metadata["sender"]
                    sender = host_str(sender_b["Remote"])
                    print ("sender: {}".format(sender))
                    line = (sender, host, timestamp)
                    if state_hash in receivers:
                        existing_lines = receivers[state_hash]
                    else:
                        existing_lines = []
                    list.append(existing_lines, line)
                    receivers[state_hash] = existing_lines
                else:
                    if exists(log_message, block_generation_started):
                        print ("block generation started")
                        crumb = metadata["breadcrumb"]
                        parent_hash = crumb["validated_transition"]["hash"]
                        if parent_hash in creators:
                            s = creators[parent_hash]
                        else:
                            s = dict() #there could be multiple blocks with the same parent
                        s[host] = timestamp
                        print("setting block creator start time:{}".format(s[host]))
                        creators[parent_hash] = s
                    else:
                        print ("unexpected log message: {}".format(log_message))

    def process_stackdriver_logs(message):
        data = json.loads(message.data)
        #data = json.loads(message)
        print ("message: {}".format(message))
        jsonPayload = data["jsonPayload"]
        process_payload(jsonPayload)
        message.ack()


    def write_event_file(block_event_file):
        rows = []
        na = "NA"
        for (parent_state_hash, hosts) in creators.items():
            for (host,create_timestamp) in hosts.items():
                list.append(rows, [event_generate,host,parent_state_hash, na,create_timestamp,na,na ])
        for (state_hash, hosts) in senders.items():
            for (host, (sent_timestamp, parent_state_hash, is_rebroadcast )) in hosts.items():
                list.append(rows, [event_send, host, parent_state_hash, state_hash, sent_timestamp, na, is_rebroadcast])
        for (state_hash,items) in receivers.items():
            for (sender, host, received_timestamp) in items:
                list.append(rows, [event_receive, host, na, state_hash, received_timestamp, sender, na])
        with open(block_event_file, 'w') as data_file:
            writer = csv.writer(data_file, delimiter=",")
            writer.writerow(event_data_header)
            writer.writerows(rows)
    def update_sender_time():
        for state_hash in list(receivers):
            lines = receivers[state_hash]
            for line in lines:
                (sender, host, timestamp) = line
                if (state_hash in senders) and (sender in senders[state_hash]):
                    sender_timestamp, parent_hash, is_creator = senders[state_hash][sender]
                    print ("sender_timestamp: {}".format(sender_timestamp))
                    if state_hash in block_latency:
                        lst = block_latency[state_hash]
                    else:
                        lst = []
                    #block creation time
                    if is_creator and (parent_hash in creators) and (sender in creators[parent_hash]):
                        cs = creators[parent_hash]
                        creation_start_time = cs[sender]
                    else:
                        creation_start_time = sender_timestamp #creation time diff of zero will be discarded
                    #validation time (if this host has rebroadcast it)
                    if host in senders[state_hash]:
                        rebroadcast_timestamp, p, i = senders[state_hash][host]
                    else:
                        rebroadcast_timestamp = timestamp
                    list.append(lst, (sender, creation_start_time, sender_timestamp, host, timestamp, rebroadcast_timestamp, is_creator))
                    block_latency[state_hash]=lst
                    with open(latency_data_file, 'a') as data_file:
                        writer = csv.writer(data_file, delimiter=",")
                        writer.writerow([state_hash, sender, creation_start_time, sender_timestamp, host, timestamp, rebroadcast_timestamp, is_creator])
                else:
                    print("No sender log found for a recieved block with hash: {}".format(state_hash))

    def stats(data):
        all_gossip_times = []
        creation_times = []
        validation_times = []
        #TODO: total gossip time = last received - start creation (or sent first)
        total_gossip_time_per_block = dict()
        gossip_times_small_variance = []
        gossip_times_large_variance = []
        for (state_hash,items) in data.items():
            for item in items: #lines for each state hash
                (sender, creation_start_time, sender_timestamp, host, receiver_timestamp, rebroadcast_timestamp, is_creator) = item
                s_t = sender_timestamp.replace("Z", "+00:00")
                s = datetime.fromisoformat(s_t)
                r_t = receiver_timestamp.replace("Z", "+00:00")
                r = datetime.fromisoformat(r_t)
                c_t = creation_start_time.replace("Z", "+00:00")
                c = datetime.fromisoformat(c_t)
                rb_t = rebroadcast_timestamp.replace("Z", "+00:00")
                rb = datetime.fromisoformat(rb_t)
                #received_time - sent_time
                diff = (r-s)/(timedelta(milliseconds=1))
                #sent_time - creations_start_time = generation_time
                c_diff = (s-c)/(timedelta(milliseconds=1))
                if state_hash in total_gossip_time_per_block:
                    d = total_gossip_time_per_block[state_hash]
                else: d = 0
                total_gossip_time_per_block[state_hash] = diff + d
                list.append(all_gossip_times, diff)
                if is_creator and c_diff > 0:
                    list.append(creation_times, c_diff)
                else:
                    v_diff = (rb - r)/(timedelta(milliseconds=1))
                    if v_diff > 0:
                        list.append(validation_times, v_diff)
                #if the diff is a second or more, considering it high variance since most t_t's are ~40 ms
                if diff >= 1000:
                    list.append(gossip_times_large_variance, diff)
                else:
                    list.append(gossip_times_small_variance, diff)
        print("All gossip times(ms): {}\n".format(all_gossip_times))
        print("Gossip times per state_hash(ms) T_gc: {}\n".format(total_gossip_time_per_block.values()))
        print("High variance gossip times(ms): {}\n".format(gossip_times_large_variance))
        print("low variance gossip times(ms): {}\n".format(gossip_times_small_variance))
        print("Block creation times(ms) T_g: {}".format(creation_times))
        print("Block validation times(ms) T_v:{}".format(validation_times))
        if len(all_gossip_times) > 0:
            print ("average latency per block: {}ms\n".format(sum(all_gossip_times, 0.0)/len(all_gossip_times)))
            print ("average latency per block(low variance): {}ms\n".format(sum(gossip_times_small_variance, 0.0)/len(gossip_times_small_variance)))
            print ("average latency per block (high variance): {}ms\n".format(sum(gossip_times_large_variance, 0.0)/len(gossip_times_large_variance)))
            print ("average latency per state_hash: {}ms\n".format(sum(total_gossip_time_per_block.values(), 0.0)/len(total_gossip_time_per_block.values())))
            print ("average block creation time: {}ms\n".format(sum(creation_times, 0.0)/ len(creation_times)))
            print ("average block validation time: {}ms\n".format(sum(validation_times, 0.0)/ len(validation_times)))
        else:
            print ("No data")

    def collect_from_stackdriver(namespace):
        sink, publisher, subscriber = setup(namespace)
        #with open(latency_data_file, 'w') as data_file:
        #    writer = csv.writer(data_file, delimiter=",")
        #    writer.writerow(csv_header)
        print ("subscribing to the logs..")
        subscriber.subscribe(subscription_name, process_stackdriver_logs)
        time.sleep(900)
        write_event_file(block_event_file)
        return (sink, publisher, subscriber)

    if source=="cloud":
        sink, publisher, subscriber = collect_from_stackdriver(namespace)
        print("generating stats")
        stat_of_event_file(block_event_file)
        print("Cleaning up")
        cleanup(sink, publisher, subscriber)
    elif source=="local":
        for payload in [logline_creation,logline_sent,logline_received1, logline_received2]:
            payload=json.loads(payload)
            process_payload(payload["jsonPayload"])
        write_event_file(block_event_file)
        stat_of_event_file(block_event_file)
    else:
        print("Invalid source option {}. Should be either cloud or local".format(source))
    print ("Done!")

    def cleanup(sink, publisher, subscriber):
        publisher.delete_topic(topic_name)
        sink.delete()
        subscriber.delete_subscription(subscription_name)


    def stat_from_file(file_name):
        data_dict = dict()
        with open(file_name, 'r') as data_file:
            reader = csv.reader(data_file, delimiter=',')
            next(reader) #skip header
            for row in reader:
                [state_hash, sender, creation_start_time, sender_timestamp, host, receiver_timestamp, is_creator] = row
                if state_hash in data_dict:
                    lst = data_dict[state_hash]
                else:
                    lst = []
                list.append(lst, (sender, creation_start_time, sender_timestamp, host, receiver_timestamp, is_creator) )
                data_dict[state_hash]=lst
        stats(data_dict)

    def test():
        process_logs(logline_creation)
        process_logs(logline_received1)
        process_logs(logline_sent)
        process_logs(logline_received2)
        update_sender_time()
        stats(block_latency)
        print(creators)
        print( senders)
        print(block_latency)

@stats.command()
@click.option('--event-directory', default=".", help='Local directory to store event data files')
def generate(event_directory):
    stat_of_event_file(event_directory)

#stat_from_file("block_latency_fe10d35c-c58c-11ea-95af-000c29d636e7.csv")
if __name__ == '__main__':
    cli()

    #stat_from_file("/home/o1labs/Documents/projects/coda_beta/coda_automation/block_latency_a972ed40-cd51-11ea-95af-000c29d636e7.csv")

