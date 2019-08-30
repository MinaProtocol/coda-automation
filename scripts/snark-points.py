import CodaClient
import json
import pandas as pd

# GraphQL client on localhost:8000
coda = CodaClient.Client(graphql_host="localhost")

# Get all the blocks
blocks = coda.get_blocks()["blocks"]

data = []
nBlocks = len(blocks["nodes"])

# Known Snarker aliases
snarkers = {
    "tNci9ERxHGkemqBmNxEWTcPgY5sn347yq6BFcUGTpve6aJpaDUgaaTEQ3rfAgYeK7KhzEbYoJvSbqQ8u88aBNtu8ALVcEeRo4ei6sGjxMsmBAJW7vwW57KLzrvou4YEMA3saq6Xqtpg3sb": "Coda",
    "tNciQET6x3DhYmBVLXYRwqdRAtTMgH4tzZfU9vYGdSrnk3p9qvnB8JK5BcSou51gfZbvCrnoKhqUFKqbRi2qCWpKNhZS1j4txdEaNHDzBYVZScsCCZFJrgW2PyLMi7no6UVMnuCTSJ5nym": "garethtdavies",
    "tNciQfhx9aXvE6VXAvZ7i84S8gwP5bqZuHam2b5dNacGGz95wVpxkQ5msDPSUvh5VCu7r1UMQ7Dq6oM1LADuzyYKaBV3J2ZQqoe2NF8rEujNm4ivkNhyhYZNf5f4TKaM3M2W2QLyNydGZz": "Alexander",
    "tNcibAmoSQqiZYTEu52LPV3KadPQJKZUVpQe3ji3cdGMv8uB6ByyhMsfTnCYdKxUXUNjFGMdyW7dBVmDpFEFdjxVGpekAKfrsHc9Pbk8pXY2MCLQwNqgBbWHcWWyqhVjCdh7X6zVHSu87A": "whataday2day",
    "tNciQ5nHMgNrzAWTkZx8Nc6fZVGTJ9xg9HEqGVE4SDoBXafsMAqbw5gU2Fx8Eq1ZNAD3YyxqqtsYdbrTm3kbMG3kGfX1D6WuQM4ZoeNDU6bHcMGF9MT9aM3d9HXWbFNf6XFtGAPBTJ8PHF": "Unknown",
    "tNci2apfQDHNoaGXnBZ4TM6XDTTrcMGNe2BHK7XMWMCZ9KoXbW4MPw86dmmsgjRBNTv62AA7HvEhGH7CnjJYCxfj2KJ52nC3UZrfLW8qSzbCzuFNJThCc2fx6vbhpBSSoMKVnxTEwEvpbU": "LatentHero",
    "tNci7NvTGz8AVngwkhhiC4ES15Hgpx2yt1vehEQwuMfFAeXJ1Vy9bdhM4goQyAdHLrKmCxKf8QVPjY4cDm4QpZo8tsUJSqYRXU346wL2wm8pV6UhqRPgsErz1Y1S79w1xeyVQPuQRFmYGf": "boscro",
    "tNcihsGQhy8XmDqYTPZtbjUd897X5T4VDAY5v1dUZJj785j8nNY4RBgeHp3Uv5DsYr6DhxbNuaYNyf4jrhZ2SprTTEQry3WZtVsi4FsYjhwnwzJLmyXVYyx3b8jZ6Hf1DYNkvtMgMpDSQw": "y3v63n",
    "tNcicNArpuQKzfokRasB2Mz7nFaSxnF2zojB43GZcN6pK3oDXVGUvJ8bxTW5rcB3b6UwTorUdvo8dV5R7dd25SVvErwhuF8KtmFBsG8Zu6visqrNVN99Y1QdUjZByLLz1BZbnh1yGcvHXR": "IIya | Genesis Labs",
    "tNci6xWipwohUQQVw8F69FqnSuMBLBpfpK9LNdea1YaDbPrPEy61HPyfkjGjwxYuEKNvvvxikUg3aYigWpowMZo53EkNzSnzrJs3fpKBUMqmfreQGc9VrxXCbT1GbYNQNYyMEYreWMfj3W": "aureus",
    "tNciCJB9Df2QdurcjSpKEJDuFU5sBphMCmjSr5xVPf77V7Pq3HyuKqheWiz6pekZjdhnBMTxYrfttMoiA4tzYPBmTwEN2bZKkhH9hcHa28eEJFZdiSryZ6mCKyniqXYhAxzKUfSXAKwQWN": "jspadave",
    "tNciPt5taz5rze7dF6TZSMUYtWzwoLKRfQxgCi8tT35HGsama9dmGqAZXNonv8m8dnbRe56H9zT63kVBSxTHjbeU5egZcqTFMpsCbCvV6sbMq44X45eguHSWhPtFodqfR7fPWXSLqFFBku": "Dmitry D",
    "tNciBNjgL24UDGk6PfqB49S5sZmkPrmzxKjJchk9XAiFrd9TWxpyFSsxEVpXeVTfAkfYXndZU97512YpYbJXKVp5TTcXjKen3f1MZQrjW63MhrP4L3cGq9yYv9b7uEs2wDfPq7j83zmY2e": "Unknown",
    "tNciUwf4Uns6fSuxcfgtdLHKv1CJd7iQmfGt9m9dWNNiB9nxC3A4FMD8xT13k5eqeasNwQKP8yBNbreQxePjBPzQDHSzbh93UXQgvjLQ5vYtTXC8bTavZDaRZtq41fpnD2246RvAsvFR9u": "ansonlau3",
    "tNciVbLmBb3kkZggRNUstqMeYKBEVikXtnVufMpEXJkv1hhVj2dfmk3owUraN3xfwk6foz8aJXRsrK6NsiqLNFS3uMBNwnD7uNgou9KqFHvhNNrHLf8MiERTxgubS7SvYpwyV6gNXDTrpx": "ilya_petrov",
    "tNcibPYLvy6MvM9XEfm2ECoibzcsRNv7cF5AcGpiQa5zs3bpmZF8DiHkvPvRcr6iGe2hsii6mE5ufXsdCdfZdA51GuuDaDYaVZJwSwcTiYRw1aJ2WMgm3JSLPYUPQ1bTBieQveWwUT45dK": "Tyler34214",
}

for value in blocks["nodes"]:
    jobs = value["snarkJobs"]
    if jobs:
        # Loop through all jobs
        for j in jobs:
            data.append([j["prover"][0:15] + "...", j["fee"],
                         snarkers.get(j["prover"], "New")])

if len(data) == 0:
    print("{} Blocks -- No Snark Jobs Observed :(".format(nBlocks))
else:
    df = pd.DataFrame(data)
    df.columns = ["ProverKey", "Fee", "User"]

    # We are interested in total number of proofs and also sum of fees earned
    earners = pd.to_numeric(df.Fee).groupby([df.ProverKey, df.User]).agg(
        ["sum", "count"]).sort_values("sum", ascending=False).rename(columns={"sum": "Total Fees", "count": "Total SNARKS Sold"})
    print(earners)
    print("{} Blocks Observed".format(nBlocks))