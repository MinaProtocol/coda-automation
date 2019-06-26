#! /usr/bin/env python3
import codalib
import json
if __name__ == "__main__":
    result = codalib.filtered_status()
    print(json.dumps(result, sort_keys=True, indent=4))
