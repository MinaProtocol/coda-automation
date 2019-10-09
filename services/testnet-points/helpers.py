import time
from datetime import datetime
import pytz

def date_in_window(date, window):
    start_time = window[0]
    end_time = start_time + window[1]
    test_time = datetime.fromtimestamp(int(date[:-3]), tz=pytz.timezone('America/Los_Angeles'))
    return start_time < test_time and test_time < end_time


def in_range(date, window_times):
    return next((date_in_window(date, window) for window in window_times), False)