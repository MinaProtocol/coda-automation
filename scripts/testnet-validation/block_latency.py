# program to get average block latency without including the time taken  to create the diff or validate
# Subscribes to logs on stackdriver from a testnet to find block-received-time - block-sent-time using the timestamp of the log
# writes the data to a csv file for finding the required stats

from google.cloud import pubsub_v1
from google.cloud import logging
import json
from datetime import datetime
from datetime import timedelta
import uuid
import time
import csv

publisher = pubsub_v1.PublisherClient()
subscriber = pubsub_v1.SubscriberClient()
logging_client = logging.Client()

project_id = "o1labs-192920"

uuid = str(uuid.uuid1())

name = 'block_latency'+'_'+uuid
sink_name= name

latency_data_file = name +'.csv'

def resource_name(name):
   return 'projects/{project_id}/{res}/{t}'.format(
    project_id=project_id,
    res=name,
    t='block_latency'+'_'+uuid,  # Set this to something appropriate.
)

topic_name = resource_name('topics')

subscription_name = resource_name('subscriptions')
block_received_filter = "Received a block from" #host is the receiver, timestamp, state hash and sender
block_broadcasted_filter = "Broadcasting new state over gossip net" #host is the source, timestamp, state_hash

block_rebroadcast_filter = "Rebroadcasting $state_hash"  #host is the sender, timestamp, and state_hash Check: this rebroadcasts internal transitions as well? isn't it already done by Coda_networking.broadcast_state?

block_generation_started = "Producing new block with parent $breadcrumb"

test_block_production = "Successfully produced a new block"

sink_destination = 'pubsub.googleapis.com/{}'.format(topic_name)

def filter(namespace):
     return """
        resource.type="k8s_container"
        resource.labels.namespace_name="{}"
        resource.labels.pod_name:"block-producer"
        ("{}" OR "{}" OR "{}" OR "{}" OR "{}")
        """.format(namespace, block_received_filter, block_broadcasted_filter, block_rebroadcast_filter, test_block_production, block_generation_started )

def setup(namespace):
    print ('creating topic: {}'.format(topic_name))
    topic = publisher.create_topic(topic_name)
    print ('creating sink:{}'.format(sink_name))
    sink = logging.sink.Sink(sink_name, filter(namespace), sink_destination, logging_client)
    sink.create()
    print ('creating subscription:{}'.format(subscription_name))
    subscription = subscriber.create_subscription(subscription_name, topic_name)
    print('finished setting up')
    return sink

senders = dict()

creators = dict()

block_latency_temp = dict()

block_latency = dict()

csv_header = ["state_hash", "sender", "block_creation_start_timestamp", "sender_timestamp", "receiver", "receiver_timestamp", "rebroadcast_timestamp", "from_creator"]

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
        "peer_id": "12D3KooWCSLMDVCHiq3ZJSsiRtA3TC59vmuf5vkenbhB93WLod3D"      
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
        "peer_id": "12D3KooWCSLMDVCHiq3ZJSsiRtA3TC59vmuf5vkenbhB93WLod3D"      
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

def process_logs(message):
    data = json.loads(message.data)
    #data = json.loads(message)
    print ("message: {}".format(message))
    jsonPayload = data["jsonPayload"]
    log_message = jsonPayload["message"]
    print ("log message: {}".format(log_message))
    timestamp = jsonPayload["timestamp"]
    #print ("timestamp: {}".format(timestamp))
    metadata = jsonPayload["metadata"]
    #print ("metadata: {}".format(metadata))
    host = metadata["peer_id"]
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
        s[host] = (timestamp, parent_hash, True) #timestamp and if it is the producer of the block
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
                    s[host] = (timestamp, parent_hash, False)
            else:
                print("Error! Duplicate rebroadcasting") #should not hit this because we invalidate duplicate blocks
            senders[state_hash] = s
        else:
            if exists(log_message, block_received_filter):
                print ("block received")
                state_hash = metadata["state_hash"]
                print ("state_hash: {}".format(state_hash))
                sender_b = metadata["sender"]
                sender = (sender_b["Remote"])["peer_id"]
                print ("sender: {}".format(sender))
                line = (sender, host, timestamp)
                if state_hash in block_latency_temp:
                    existing_lines = block_latency_temp[state_hash]
                else:
                    existing_lines = []
                list.append(existing_lines, line)
                block_latency_temp[state_hash] = existing_lines
            else:
                if exists(log_message, block_generation_started):
                    print ("block generation started")
                    crumb = metadata["breadcrumb"]
                    parent_hash = crumb["validated_transition"]["hash"]
                    if parent_hash in creators:
                        s = creators[parent_hash]
                    else:
                        s = dict()
                    s[host] = timestamp #timestamp and if it is the producer of the block
                    print("setting block creator start time:{}".format(s[host]))
                    creators[parent_hash] = s
                else:
                 print ("unexpected log message: {}".format(log_message))
    message.ack()

def stats(data):
    all_gossip_times = []
    creation_times = []
    validation_times = []
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
            diff = (r-s)/(timedelta(milliseconds=1))
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

def update_sender_time():
    for (state_hash, lines) in block_latency_temp.items():
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
                

def start():
    sink = setup('deploy-test1')
    with open(latency_data_file, 'w') as data_file:
        writer = csv.writer(data_file, delimiter=",")
        writer.writerow(csv_header)
    print ("subscribing to the logs..")
    subscriber.subscribe(subscription_name, process_logs)
    time.sleep(600)
    update_sender_time()
    print ("senders: {}".format(senders))
    print ("data: {}".format(block_latency))
    stats(block_latency)
    print ("cleaning up")
    cleanup(sink)
    print ("Done!")

def cleanup(sink):
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


#stat_from_file("block_latency_fe10d35c-c58c-11ea-95af-000c29d636e7.csv")

start()

#stat_from_file("/home/o1labs/Documents/projects/coda_beta/coda_automation/block_latency_a972ed40-cd51-11ea-95af-000c29d636e7.csv")

