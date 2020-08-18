# TODO: Not sure where google_sheets_credentials.json will be stored. Will it need be accessed by a volume? 
kubectl create secret generic credentials --from-file=google_sheets_credentials.json