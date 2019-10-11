from __future__ import print_function
import sheets as sheets_api

DEFAULT_RANGE = "A1:Z"

def combine_metrics(old_metric_names, old_metrics, new_metrics, combine_fns):
    # calculate combined order
    new_metric_names = set()
    for user, user_metrics in new_metrics.items():
        for metric_name in user_metrics:
            if not metric_name in old_metric_names:
                new_metric_names.add(metric_name)

    combined_order = old_metric_names + list(new_metric_names)

    # calculate combined user list
    users = sorted(list(set(old_metrics.keys()) | set(new_metrics.keys())))

    # calculate combined metrics
    combined_metrics = {}
    for user in users:
        user_metrics = {}
        for metric_name in combined_order:
            old_metric = old_metrics.get(user, {}).get(metric_name)
            new_metric = new_metrics.get(user, {}).get(metric_name)
            if old_metric is None and new_metric is None:
                pass
            elif old_metric is not None and new_metric is None:
                user_metrics[metric_name] = old_metric
            elif old_metric is None and new_metric is not None:
                user_metrics[metric_name] = new_metric
            elif not metric_name in combine_fns:
                raise ValueError("Don't know how to combine metric '%s'" % metric_name)
            else:
                combine_fn = combine_fns[metric_name]
                user_metrics[metric_name] = combine_fn(old_metric, new_metric)

        combined_metrics[user] = user_metrics

    return (combined_order, combined_metrics)

"""
Finds and returns all duplicates in a list (of strings, ideally)
"""
def get_duplicates(lst):
    seen = set()
    duplicates = []
    for e in lst:
      if e in seen:
        duplicates.append(e)
      else:
        seen.add(e)
    return duplicates

def values_to_metrics(values):
    # Check users are unique:
    duplicate_users = get_duplicates([row[0] for row in values[1:]])
    if duplicate_users:
        raise ValueError("Found duplicate users in spreadsheet: %s" % duplicate_users)

    metric_order = values[0][1:]
    # Check metric names are unique:
    duplicate_metrics = get_duplicates(metric_order)
    if duplicate_metrics:
        raise ValueError("Found duplicate metric names in spreadsheet: %s" % duplicate_metrics)

    metrics = {}

    for row in values[1:]:
        user = row[0]
        for (metric_name, metric_value) in zip(metric_order, row[1:]):
            user_metrics = metrics.get(user, {})
            if (metric_value != ''):
                user_metrics[metric_name] = metric_value
            metrics[user] = user_metrics

    return (metric_order, metrics)

# Assumes all metrics are in metrics_order
def metrics_to_values(metrics_order, metrics):
    def mapUsers(username):
        user_values = [metrics.get(username, {}).get(metrics_name)
                       for metrics_name in metrics_order]
        user_values.insert(0, username)
        return user_values

    values = [mapUsers(users) for users in sorted(metrics.keys())]
    values.insert(0, [''] + metrics_order)
    return values

def upload_metrics(credentials, sheet_id, sheet_name, combine_fns, new_metrics):
    sheet_range = sheet_name + "!" + DEFAULT_RANGE
    values = sheets_api.get_sheet(credentials, sheet_id, sheet_range)
    order, metrics = values_to_metrics(values)

    combined_order, combined_metrics = combine_metrics(order, metrics, new_metrics, combine_fns)

    new_values = metrics_to_values(combined_order, combined_metrics)

    sheets_api.set_sheet(credentials, sheet_id, sheet_range, new_values)

    return combined_metrics

def upload_points(credentials, sheet_id, sheet_name, challenges, new_metrics):
    sheet_range = sheet_name + "!" + DEFAULT_RANGE

    all_points = dict([(challenge_name, challenge_fn(new_metrics))
                       for challenge_name, challenge_fn in challenges.items()])

    points_rows = [
        ['GENERATED: Do not edit', '' * len(challenges.keys())],
        [''] + list(challenges.keys())
    ]

    for user in sorted(new_metrics.keys()):
        row = [all_points[challenge_name].get(user, 0)
               for challenge_name in challenges.keys()]
        row.insert(0, user)
        points_rows.append(row)

    sheets_api.set_sheet(credentials, sheet_id, sheet_range, points_rows)
