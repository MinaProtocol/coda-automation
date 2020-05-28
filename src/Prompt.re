type readline;

type options = {
  input: in_channel,
  output: out_channel,
};

[@bs.module "readline"]
external createReadline: options => readline = "createInterface";

[@bs.send]
external questionInternal: (readline, string, string => unit) => unit =
  "question";

[@bs.send] external close: readline => unit = "close";

let yes = [%re "/yes|y/gi"];
let no = [%re "/no|n/gi"];

exception Invalid_input;

let yesNo = query => {
  let readline =
    createReadline({
      input: [%raw "process.stdin"],
      output: [%raw "process.stdout"],
    });
  Js.Promise.make((~resolve, ~reject) =>
    questionInternal(
      readline,
      query,
      res => {
        close(readline);
        switch (res) {
        | r when Js.Re.test_(yes, r) => resolve(. true)
        | r when Js.Re.test_(no, r) => resolve(. false)
        | _ => reject(. Invalid_input)
        };
      },
    )
  );
};

let question = query => {
  let readline =
    createReadline({
      input: [%raw "process.stdin"],
      output: [%raw "process.stdout"],
    });
  Js.Promise.make((~resolve, ~reject as _) =>
    questionInternal(
      readline,
      query,
      response => {
        close(readline);
        resolve(. response);
      },
    )
  );
};
