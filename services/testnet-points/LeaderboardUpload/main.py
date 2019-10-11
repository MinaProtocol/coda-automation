from __future__ import print_function
import sheets
import metrics
import challenges
import upload

SHEET_ID = '18VXeazbKykDuyu4RDabgq9y8Ox4lm_UnQqSWC8aMWaw'

def main():

    """
    Note: new metrics should be in the following form:
    {
      "name1": {"metric1": 1, "metric2": 134, "metric3": 11}
      "name2": {"metric1": 2, "metric3": 8}
      "name3": {"metric2": 412}
    }
    """
    new_metrics = {"user3": {"metric1": 100, "metric4": 11}}

    credentials = sheets.get_credentials()
    uploaded_metrics = upload.upload_metrics(
        credentials,
        SHEET_ID,
        "Metrics2.2",
        metrics.combine_fns,
        new_metrics)

    upload.upload_points(
        credentials,
        SHEET_ID,
        "Challenges2.2",
        challenges.challenges2_2,
        uploaded_metrics)

if __name__ == '__main__':
    main()
