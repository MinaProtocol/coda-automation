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
    "tNciQ5nHMgNrzAWTkZx8Nc6fZVGTJ9xg9HEqGVE4SDoBXafsMAqbw5gU2Fx8Eq1ZNAD3YyxqqtsYdbrTm3kbMG3kGfX1D6WuQM4ZoeNDU6bHcMGF9MT9aM3d9HXWbFNf6XFtGAPBTJ8PHF": "Prague",
    "tNci2apfQDHNoaGXnBZ4TM6XDTTrcMGNe2BHK7XMWMCZ9KoXbW4MPw86dmmsgjRBNTv62AA7HvEhGH7CnjJYCxfj2KJ52nC3UZrfLW8qSzbCzuFNJThCc2fx6vbhpBSSoMKVnxTEwEvpbU": "LatentHero",
    "tNci7NvTGz8AVngwkhhiC4ES15Hgpx2yt1vehEQwuMfFAeXJ1Vy9bdhM4goQyAdHLrKmCxKf8QVPjY4cDm4QpZo8tsUJSqYRXU346wL2wm8pV6UhqRPgsErz1Y1S79w1xeyVQPuQRFmYGf": "boscro",
    "tNcihsGQhy8XmDqYTPZtbjUd897X5T4VDAY5v1dUZJj785j8nNY4RBgeHp3Uv5DsYr6DhxbNuaYNyf4jrhZ2SprTTEQry3WZtVsi4FsYjhwnwzJLmyXVYyx3b8jZ6Hf1DYNkvtMgMpDSQw": "y3v63n",
    "tNcicNArpuQKzfokRasB2Mz7nFaSxnF2zojB43GZcN6pK3oDXVGUvJ8bxTW5rcB3b6UwTorUdvo8dV5R7dd25SVvErwhuF8KtmFBsG8Zu6visqrNVN99Y1QdUjZByLLz1BZbnh1yGcvHXR": "Ilya | Genesis Lab",
    "tNci6xWipwohUQQVw8F69FqnSuMBLBpfpK9LNdea1YaDbPrPEy61HPyfkjGjwxYuEKNvvvxikUg3aYigWpowMZo53EkNzSnzrJs3fpKBUMqmfreQGc9VrxXCbT1GbYNQNYyMEYreWMfj3W": "aureus",
    "tNciCJB9Df2QdurcjSpKEJDuFU5sBphMCmjSr5xVPf77V7Pq3HyuKqheWiz6pekZjdhnBMTxYrfttMoiA4tzYPBmTwEN2bZKkhH9hcHa28eEJFZdiSryZ6mCKyniqXYhAxzKUfSXAKwQWN": "jspadave",
    "tNciPt5taz5rze7dF6TZSMUYtWzwoLKRfQxgCi8tT35HGsama9dmGqAZXNonv8m8dnbRe56H9zT63kVBSxTHjbeU5egZcqTFMpsCbCvV6sbMq44X45eguHSWhPtFodqfR7fPWXSLqFFBku": "Dmitry D",
    "tNciBNjgL24UDGk6PfqB49S5sZmkPrmzxKjJchk9XAiFrd9TWxpyFSsxEVpXeVTfAkfYXndZU97512YpYbJXKVp5TTcXjKen3f1MZQrjW63MhrP4L3cGq9yYv9b7uEs2wDfPq7j83zmY2e": "OranG3",
    "tNciUwf4Uns6fSuxcfgtdLHKv1CJd7iQmfGt9m9dWNNiB9nxC3A4FMD8xT13k5eqeasNwQKP8yBNbreQxePjBPzQDHSzbh93UXQgvjLQ5vYtTXC8bTavZDaRZtq41fpnD2246RvAsvFR9u": "ansonlau3",
    "tNciVbLmBb3kkZggRNUstqMeYKBEVikXtnVufMpEXJkv1hhVj2dfmk3owUraN3xfwk6foz8aJXRsrK6NsiqLNFS3uMBNwnD7uNgou9KqFHvhNNrHLf8MiERTxgubS7SvYpwyV6gNXDTrpx": "ilya_petrov",
    "tNcibPYLvy6MvM9XEfm2ECoibzcsRNv7cF5AcGpiQa5zs3bpmZF8DiHkvPvRcr6iGe2hsii6mE5ufXsdCdfZdA51GuuDaDYaVZJwSwcTiYRw1aJ2WMgm3JSLPYUPQ1bTBieQveWwUT45dK": "Tyler34214",
    "tNciRGY5DkKoeAbMWscZfJF9ZvJZHqEbharXjFuck43gKZkENsD2svkzKBp3ZrvGcoeVC4VDKt1Wp3vkrLXjsP7vTavnaseeRh5QeptFLiijzk7mGgFkgZi7ns53brN7Bk91WmyYPhBUDA": "TipaZloy",
    "tNciX9H5cqmhWTi2hscSaexxnzTZGtrEq7ESCFgC3qz36kX69MHvhfEUkJHYGFSQVDTD9WHQiPQ2Xa98ZwkVEc8UhQ5mqThye7GXKvCvkmtRePhTo4uKRDaWQE4MunzuphUvNXvpwZAWEF": "hulio",
    "tNciNB9392r2f36EgyqACw3aED1HYu4sJQNQnws1dTPiaPofmfW35jVqqtwLMEEFYrG4J6HF1wFxgpmfJ6cYf6YKcy4vfeyhinSTS34ZcAWDF8pFVh9keW1qEGvg9V9b69x38YMUVThCX7": "PetrG",
    "tNciQFukA6prhQisFLk8Xyp3tsW5b78vZzAThNNTzeWdbiNUVMpxtmhXf38pxTQ37f3wS3a9Wzx2ComAGykicpXTFd5fZoz3iadnWB5kJZ2saDZ1PRMxVctdx52sJahksWAB9KtMU2ggTG": "Hunterr84",
    "tNciUJbzpyufFsDxqyU6qnefMRYuem2dWXF4eEYaRW9UEnHzg4ekugrTcD4trgTkgiLj74bjbYGVgnEeqrsVrMLf3ePQ3Lp36bXYnoMKmZMk4y18HmoW5RLf4BXnobrPNmBSJgtFehSZc6": "ttt",
    "tNciVRxhXhJq78LFxg8acp7VwVSXtJMsQgyyASr9q9vXMcJ4whwawrtz1TZyH8TXHyy68cPatDR5xRn5G2o7cm8kWYMbooPaTVpte2vYsd7pqFDAJ6QAYTD8Ro1FPmzQdvCZHdhdMfdZqi": "novy",
    "tNciSsa6QA8sREh6vumV3incy6x7iCXixVBYGxwxZCt1WHKFACf5FurfThp9drF1KJDgdtdu6Mo4ecxKD4gnepuFXeZGJ3VNSfHdkw5pdFCvCWniezEMTwtqgbuvyjnDzseKabkj2wfoVM": "Kitfrag",
    "tNciYjrq2YuX6Msb5s1QxUHDMdJgXKrsSQybG9tPzf6efzfARe5C9QYtxaqShy8THYXNx5XYUwED9citmKe8dM13PCbkbtz6Ydn4NB9rcX3V8syw7vsGkcfBLdF7HQmuUacK5srpFr1Hsg": "Gs",
    "tNci66YXVbXh5bMcyvZ6BhAb7YVeFhQg1a2VdXY8EKuCHQ7jYqFZYjpF7QEfzW3CZytYTtXKgF9eV6fH4SpUanFboMZiz4BAtCoAx2f6DXjofruZTikvirpN8mNTVoyiNVVbuowLfN5Dh3": "GregMas",
    "tNciWh4QiBS5cBbforNv1pGzT5Fs3bWhYzXzBL9fyDxSGBg6JwGQpz98LBgSA12wJjpCoH1Xa8MNvnFmX3Vti5k9Ex3ZAZWvPb81bbJ18acxHTB2NT9c3weqmnxGue3eQupS7RX4cdSwYQ": "Gavin Cox",
    "tNciC4yPCG7VCrJhtnik81np3FA8hhHei2LdJ93Yux5GC1FKmdK5UsGASYqkgfBg5SjQKPamE9iPpBw84p3F542HPN4TjQGa1gsewxdXv7XDfbXN8K8z98UmPD7pbLxqHu9K22y6BpTqxu": "TylerTY",
    "tNci9ViV7ieBUu73BSGmFp8z6QdqvF3jpAy6sGJ8eCkk9TCeFBKSgUvTxZbdjELuSH2jUWzWUyhr35u1sWQc3HuiY56tJGUdXXM8tqTw3ZiSrHBCfLsn6oXDvyTPEfP3tZuD7gDArb8Ytj": "Connor Di",
    "tNciGfaEEdEkMpENBzevtcsuNPkPd9bRkebsLa7t63qafMYu7k7CSeqz6C5XmmjoQtPKsTR25ZUmwBBz79mjAYAMMxszSmhc41o2cv5fHfjKfdr2khrkN5vtVeLUkF9qzycT9s13zqBNBL": "Chester123",
    "tNciFwvpwzMVPJDgcZuGDgWLrxHxsEtfNMB1jWhFJL7YRd3baqyDVepnHqVMUcnrmcET44SdoFcaWwGS3zDQ5A1hGreYffWxL6DW4t92f6uW2URbZE8qdy4BTamkG4qqCzhNjEs5evPbD4": "mamio",
    "tNcidgsCphkdpU2bWvgrBYxkW1SSeT6kSYNRZMq5eeWkoga8uvbY7kQSEPBpBa7ahvT7Kr7NTucUNYchFcUS4KpuW2GMDGSH8Bu2pA9U6jseyqqEJFm2ij5zvndY3gLpzVZJGgbGnVuegD": "sashka",
    "tNciN3JM45idr84C8bjKXJXbWCQXWRSuDYq2ZZg6HbtT1g6dgvwBScPc8WL26VdfWzf7okUgaFktd63KtP2zM7X7pRgNDhBXHaEseUJ18NSqzuVdgtv1X5YBJivS8i2masYzaUszVdjfzJ": "Q.Margo",
    "tNcik6XeAF6d2WXKuVb9TRjKV9Gqm2WK2kWVVGoR1VKPMSfLxzYhkH7YxCAVPHBLBwnMKinrGiBCynRPzML8SuMGtqG1mnE398wtYgLor2xMmYLc5PZbu2pimTmrmvbKLZLoiY7JaAUGds": "Mishdmish",
    "tNciEkJqE2UDfVgbWDynNXuA8eXLuSWJs5CGc5Nk6giUvoQQdny7wZaBRyWpZpaBMFXHzG6iiSuwUwVjF1tFfv5GdDvRA4uEwsKzAkGy9Lb25TsiDTTzKeFAgGBZB7LNnQ22Zg4QxYSuxm": "romantoz",
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
