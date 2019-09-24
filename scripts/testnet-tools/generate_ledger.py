#!/usr/bin/env python3

import pubkey_to_discord
import offline_keys

content = """
open Functor.Without_private
module Public_key = Signature_lib.Public_key

include Make (struct
  let accounts =
    (* VRF Account *)
    [ { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNciXRzP5ViAqK6TbwfBhNkuppA2XVatF6uEvWNrrh6eBY7hsYbQfQTBkfNjpQZuY3s4jU5LYD3ZBhM2z4mbvmHeHQvCHqe7vwr2wQH4gJLSv14tf6iWHyoRWHZ4XS2s6oxzBFW3xB5Nvn"
      ; balance= 0
      ; delegate= None }
      (* O(1) Proposer Account Pair 1 *)
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNciTDiJziUovrKA4KKs7wN1XNhV8BW1YUvcyoo33RdrtPa5fKSKJSqFTgo13aNscVYTBa2kRmPnNGCdsuAqsSw6YJSn1GKVuqfpTDxXkifm6PJoVmVN3Gd1vBPKzdpeyuTBULfwsjmFxB"
      ; balance= 10000000
      ; delegate=
          Some
            (Public_key.Compressed.of_base58_check_exn
               "tNcihXwbnb6Sv3MwW2rbhXDS4TNSn75tnDZjzUKsjgFSmVJUycLFftqnSZmikKBKEo7KHeLviRpsZw3XUh6zDZwtdH8zk9mhNG6ydL8pqrFM5FdkeV9fYdtvysVC29PSKyb97vK7jkJB5d")
      }
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNcihXwbnb6Sv3MwW2rbhXDS4TNSn75tnDZjzUKsjgFSmVJUycLFftqnSZmikKBKEo7KHeLviRpsZw3XUh6zDZwtdH8zk9mhNG6ydL8pqrFM5FdkeV9fYdtvysVC29PSKyb97vK7jkJB5d"
      ; balance= 0
      ; delegate= None }
      (* O(1) Proposer Account Pair 2 *)
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNciGGG62uN18dV5YJrr2SyGWsGbQQhBn5fSEBJ5967KBikntN6hhnCw3Zc1aQCWi4FQDSZMS1d1aq18iKUVnJdDi87ZtBsvgvS1YRo9rWFyX3pUxeM7mntZmA387gztnXT4xfqYSwSh3v"
      ; balance= 10000000
      ; delegate=
          Some
            (Public_key.Compressed.of_base58_check_exn
               "tNci4GbJQMkTxsoZyVtn86HtLYA6KKxcR1ujoy9da7QWzw7QZgiL7MTxXbb3cxDx7nRpeFBBJ7m8SSVRR3Ua3tbiDAiARBYW6x7DFf56jTNjAypFbq69FvJsKBubKb5GhnH27qR6FjJeEA")
      }
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNci4GbJQMkTxsoZyVtn86HtLYA6KKxcR1ujoy9da7QWzw7QZgiL7MTxXbb3cxDx7nRpeFBBJ7m8SSVRR3Ua3tbiDAiARBYW6x7DFf56jTNjAypFbq69FvJsKBubKb5GhnH27qR6FjJeEA"
      ; balance= 0
      ; delegate= None }
      (* O(1) Proposer Account Pair 3 *)
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNcij94DDKfuVRL2VrK9HQVeyJPwFK3Sz6bnpGWgme24Cqsgup1cpfb19XKEfkiUmRrUJ6CrJ8C7Bgz1w6mzeRvQ9BXuTsKaEc1yvuJUoDioGVXpuGowYVXw4KC1mG6RsqPYF4oH7iWcHY"
      ; balance= 10000000
      ; delegate=
          Some
            (Public_key.Compressed.of_base58_check_exn
               "tNciedhUUQQ2db9aZYhLjFTtPenzBTJsABVWemDeevGcfn2XvbaGpUDcoVdKxNRhfSEaUJCrN6iCht2zsRUH1yRnWpTfLA8CtC8yCDDrxvLNzRuSSrGMvzYEX5z3wt2SdmqJVVfTJaqNSu")
      }
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNciedhUUQQ2db9aZYhLjFTtPenzBTJsABVWemDeevGcfn2XvbaGpUDcoVdKxNRhfSEaUJCrN6iCht2zsRUH1yRnWpTfLA8CtC8yCDDrxvLNzRuSSrGMvzYEX5z3wt2SdmqJVVfTJaqNSu"
      ; balance= 0
      ; delegate= None }
      (* O(1) Proposer Account Pair 4 *)
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNciMTgwisDWsms9pEiJvbRXWpCnp5vFQRJd417w1aN15ofzCEFQA37JC4yEoNLNw9MxP12uZVv4Wm5mcwCUryD6zr2DpZGiaBvrWikHTreYMbE4BViMB9d7BUGxLExtoC8cc1LjQFXPgG"
      ; balance= 10000000
      ; delegate=
          Some
            (Public_key.Compressed.of_base58_check_exn
               "tNcibGJshuL8dqvQitNyLfndYsrLRffYBfqYS8CsgnCyUMdD8MEmzLPiZ5f3Sv7i3KAYCJygNMvQCULHuZBXE6swQTCfMiHvkL6eG4cmDBQ1NjdRjVeqMEv5zEW76sxduKbVG26LExKYj8")
      }
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNcibGJshuL8dqvQitNyLfndYsrLRffYBfqYS8CsgnCyUMdD8MEmzLPiZ5f3Sv7i3KAYCJygNMvQCULHuZBXE6swQTCfMiHvkL6eG4cmDBQ1NjdRjVeqMEv5zEW76sxduKbVG26LExKYj8"
      ; balance= 0
      ; delegate= None }
      (* O(1) Proposer Account Pair 5 *)
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNciUfrbXAYtEfcMhW8nYdh9DsFfGenEYNgqRq5vmzBnRgaQd4fDYVEt8VhfbZGQc7brDWCkvNrUdxbfbV9mc7pEN6GG6hEkqNAbXuz3YtKtQPLefz8YMcbLhdE1ninWdkym5ytaKNteCa"
      ; balance= 10000000
      ; delegate=
          Some
            (Public_key.Compressed.of_base58_check_exn
               "tNci77WCk8buqGTyrQb9ehAp2fwHe4BUjN4kTGZVvG3mPUhntKKDBf4NMiR2GEuVwHaD28KyhP8zqVXtfAv66h7D3TKE8PTnNnsA154GDHLodnXT6q25a7mGanZjSQwhGcAVChjN4bGw9y")
      }
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNci77WCk8buqGTyrQb9ehAp2fwHe4BUjN4kTGZVvG3mPUhntKKDBf4NMiR2GEuVwHaD28KyhP8zqVXtfAv66h7D3TKE8PTnNnsA154GDHLodnXT6q25a7mGanZjSQwhGcAVChjN4bGw9y"
      ; balance= 0
      ; delegate= None }
      (* Faucet Key *)
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNciczxpMfZ4eW1ZPP9NVK2vxcm9cCHvTBWMe8Nskn2A25P1YqcdvFCD5LvgngraiCmAsnC8zWAiv5pwMYjrUwpMNYDePMQYiXX7HVMjrnB1JkEckyayvsAm2Bo4EQBWbHXD5Cxp65PZy5"
      ; balance= 5000000
      ; delegate=
          Some
            (Public_key.Compressed.of_base58_check_exn
               "tNcihXwbnb6Sv3MwW2rbhXDS4TNSn75tnDZjzUKsjgFSmVJUycLFftqnSZmikKBKEo7KHeLviRpsZw3XUh6zDZwtdH8zk9mhNG6ydL8pqrFM5FdkeV9fYdtvysVC29PSKyb97vK7jkJB5d")
      }
      (* Echo Key *)
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "tNciUTDQupJTEjEgFefiGBYuXNF8asTBSEimH2uBjkmq1vMEDMnzQyaVF9MgRmecViUUzZwPMQCDVoKLFmPeWG9dPY7o7erkLDFRWnoGpNGUk3H5r3rHtyfrG17Di6tx9VqQMq6rehPmAu"
      ; balance= 5000000
      ; delegate=
          Some
            (Public_key.Compressed.of_base58_check_exn
               "tNcihXwbnb6Sv3MwW2rbhXDS4TNSn75tnDZjzUKsjgFSmVJUycLFftqnSZmikKBKEo7KHeLviRpsZw3XUh6zDZwtdH8zk9mhNG6ydL8pqrFM5FdkeV9fYdtvysVC29PSKyb97vK7jkJB5d")
      }
      (* User Stake Keys *)
"""

total_user_accounts = len(pubkey_to_discord.FILET_MIGNON_STAKING_CHALLENGE)

coda_per_user = int(40000000 / total_user_accounts)

id = 1
for (user_key, discord_id) in pubkey_to_discord.FILET_MIGNON_STAKING_CHALLENGE.items():
    offline_key = offline_keys.OFFLINE_PUBLIC_KEYS[id]
    content += """
      (* Offline/Online User Keys: %s   %s of %s *)
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "%s"
      ; balance= %s
      ; delegate=
          Some
            (Public_key.Compressed.of_base58_check_exn
               "%s")
      }
    ; { pk=
          Public_key.Compressed.of_base58_check_exn
            "%s"
      ; balance= 1
      ; delegate= None }""" % (discord_id, id,  total_user_accounts, offline_key, coda_per_user, user_key, user_key)
    id += 1

content += """]
end)"""

print(content)
