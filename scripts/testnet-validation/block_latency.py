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

test_block_production = "Successfully produced a new block"

sink_destination = 'pubsub.googleapis.com/{}'.format(topic_name)

def filter(namespace):
     return """
        resource.type="k8s_container"
        resource.labels.namespace_name="{}"
        resource.labels.pod_name:"block-producer"
        ("{}" OR "{}" OR "{}" OR "{}")
        """.format(namespace, block_received_filter, block_broadcasted_filter, block_rebroadcast_filter, test_block_production )

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

block_latency_temp = dict()

block_latency = dict()

csv_header = ["state_hash", "sender", "sender_timestamp", "receiver", "receiver_timestamp", "is_first_hop"]

def exists(str, sub):
    return (str.find(sub) != -1)

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
    #print ("data: {}".format(data))
    jsonPayload = data["jsonPayload"]
    log_message = jsonPayload["message"]
    print ("log message: {}".format(log_message))
    timestamp = jsonPayload["timestamp"]
    #print ("timestamp: {}".format(timestamp))
    metadata = jsonPayload["metadata"]
    #print ("metadata: {}".format(metadata))
    host = metadata["host"]
    print ("host: {}".format(host))
    if exists(log_message, block_broadcasted_filter):
        print ("new block broadcasted")
        state_hash = metadata["state_hash"]
        print ("state_hash: {}".format(state_hash))
        if state_hash in senders:
            s = senders[state_hash]
        else:
            s = dict()
        if not(host in s):
            s[host] = (timestamp, True) #timestamp and if it is the producer of the block
        else:
            t, s = s[host]
            s[host] = (t, True)
        senders[state_hash] = s
    else:
        if exists(log_message, block_rebroadcast_filter):
            print ("block rebroadcasted")
            state_hash = metadata["state_hash"]
            print ("state_hash: {}".format(state_hash))
            if state_hash in senders:
                s = senders[state_hash]
            else:
                s = dict()
            if not(host in s): #don't log duplicate rebroadcasting?
                    s[host] = (timestamp, False)
            else:
                print("Error! Duplicate rebroadcasting") #should not hit this because we invalidate duplicate blocks
                senders[state_hash] = s
        else:
            if exists(log_message, block_received_filter):
                print ("block received")
                state_hash = metadata["state_hash"]
                print ("state_hash: {}".format(state_hash))
                sender_b = metadata["sender"]
                sender = (sender_b["Remote"])["host"]
                print ("sender: {}".format(sender))
                line = (sender, host, timestamp)
                if state_hash in block_latency_temp:
                    existing_lines = block_latency_temp[state_hash]
                else:
                    existing_lines = []
                list.append(existing_lines, line)
                block_latency_temp[state_hash] = existing_lines
            else:
                # if exists(log_message, test_block_production):
                #    print "produced a new block: {}".format(metadata)
                #    bc =(metadata["breadcrumb".encode('utf-8')])
                #    print "breadcrumb: {}".format(bc)
                #    tr = (bc["validated_transition".encode('utf-8')])
                #    print "validated transition: {}".format(tr)
                #    d = (tr["data".encode('utf-8')])
                #    print "data: {}".format(d)
                #    ps = d["protocol_state".encode('utf-8')]
                #    print "protocol state: {}".format(ps)"""
                # else:
                print ("unexpected log message: {}".format(log_message))
    message.ack()

def stats(data):
    all_items = []
    first_hops = []
    for items in data.values():
        for item in items: #lines for each state hash
            (sender, sender_timestamp, host, receiver_timestamp, is_first_hop) = item
            s_t = sender_timestamp.replace("Z", "+00:00")
            s = datetime.fromisoformat(s_t)
            r_t = receiver_timestamp.replace("Z", "+00:00")
            r = datetime.fromisoformat(r_t)
            diff = (r-s)/(timedelta(milliseconds=1))
            list.append(all_items, diff)
            if is_first_hop:
                list.append(first_hops, diff)
    print(all_items)
    print(first_hops)
    if len(all_items) > 0:
        print ("average latency: {}ms".format(sum(all_items, 0.0)/len(all_items)))
        print ("average latency (first hop): {}ms".format(sum(first_hops, 0.0)/ len(first_hops)))
    else:
        print ("No data")

def update_sender_time():
    for (state_hash, lines) in block_latency_temp.items():
        for line in lines:
            (sender, host, timestamp) = line
            if sender in senders[state_hash]:
                sender_timestamp, is_first_hop = (senders[state_hash])[sender]
                print ("sender_timestamp: {}".format(sender_timestamp))
                if state_hash in block_latency:
                    lst = block_latency[state_hash]
                else:
                    lst = []
                list.append(lst, (sender, sender_timestamp, host, timestamp, is_first_hop))
                block_latency[state_hash]=lst
                with open(latency_data_file, 'a') as data_file:
                    writer = csv.writer(data_file, delimiter=",")
                    writer.writerow([state_hash, sender, sender_timestamp, host, timestamp, is_first_hop])
            else:
                print("No sender log found for a recieved block with hash: {}".format(state_hash))
                

def start():
    sink = setup('deploy-test1')
    with open(latency_data_file, 'w') as data_file:
        writer = csv.writer(data_file, delimiter=",")
        writer.writerow(csv_header)
    print ("subscribing to the logs..")
    subscriber.subscribe(subscription_name, process_logs)
    time.sleep(1200)
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
            [state_hash, sender, sender_timestamp, host, receiver_timestamp, is_first_hop] = row
            if state_hash in data_dict:
                lst = data_dict[state_hash]
            else:
                lst = []
            list.append(lst, (sender, sender_timestamp, host, receiver_timestamp, is_first_hop) )
            data_dict[state_hash]=lst
    stats(data_dict)

#process_logs(logline_received1)
#process_logs(logline_sent)
#process_logs(logline_received2)
#update_sender_time()
#stats(block_latency)
#print( senders)
#print(block_latency)


#stat_from_file("block_latency_fe10d35c-c58c-11ea-95af-000c29d636e7.csv")

start()


