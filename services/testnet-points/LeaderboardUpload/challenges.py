from __future__ import print_function
from collections import OrderedDict

def winners(metrics, metric_name, point_values):
    """Awards points to the top scoring users in a particular metric

    point_values should be a list of point values like [1000, 500, 200].
    In this example, 1000 points are awarded to the top scoring member,
    500 to the second place, and 200 to the third. Any number of point
    values can be specified, and points are awarded to all applicable users
    in the case of a tie.

    Users need to have a non-zero metric value to qualify.

    arguments:
    metrics -- metrics object
    metric_name -- the name of the metric for which points are being awarded
    point_values -- List of point values for the top scorers in order
    """
    metrics_values = set()
    metric_to_user = {}
    points = {}
    for user, user_metric in metrics.items():
        # initialize all users to 0
        points[user] = 0

        metric = int(user_metric.get(metric_name, 0))
        if (metric > 0):
            # Add to the set of metrics values
            metrics_values.add(metric)

            # add user to the list of people with this metric value
            users = metric_to_user.get(metric, [])
            users.append(user)
            metric_to_user[metric] = users
    
    sorted_metrics = sorted(list(metrics_values), reverse=True)

    for metric, point_value in zip(sorted_metrics, point_values):
        for user in metric_to_user[metric]:
            points[user] = point_value

    return points


    
def multiply(metrics, metric_name, multiplier):
    """Multiplies a metric by a constant value to get the points

    arguments:
    metrics -- metrics object
    metric_name -- the name of the metric for which points are being awarded
    multiplier -- How much to multiply the metric
    """
    return dict([(user, int(user_metric.get(metric_name, 0)) * multiplier) 
        for user, user_metric in metrics.items()])

def add(pts1, pts2):
    users = list(set(pts1.keys()) | set(pts2.keys()))
    return dict([(user, pts1.get(user, 0) + pts2.get(user, 0)) for user in users])

def challenge1(metrics):
    return winners(metrics, "metric1", [1000, 500, 200])

def challenge2(metrics):
    return multiply(metrics, "metric1", 5)

def challenge3(metrics):
    return add(multiply(metrics, "metric1", 5),
               winners(metrics, "metric1", [1000, 500, 200]))

# You can make a different challenges object for each testnet
challenges2_2 = OrderedDict({
    "challenge1": challenge1,
    "challenge2": challenge2,
    "challenge3": challenge3,
})
