# Directory Structure
    
| Folder       | Description                                                                                                  |
|--------------|--------------------------------------------------------------------------------------------------------------|
| Containers/  | Kubernetes container components                                                                              |
| Contexts/    | Deployment contexts (used for PodSidecar specs)                                                              |
| Deployments/ | Kubernetes deployment components                                                                             |
| External/    | External, pinned dhall libraries                                                                             |
| Lib/         | Project wide helper functions and types (files in here should not depend on anything outside of this folder) |
| PodSidecars/ | PodSidecar components (see Lib/PodSidecar.dhall for info)                                                    |
| Templates/   | Top level entrypoints for rendering dhall configs                                                            |

# Design Patterns and Style

## Dhall Components

In order to best facilitate composable, reusable, and extensible abstractions on top of Kubernetes configuration, we choose to structure our dhall code into "Components" which provide a common interface for configuring, building, and (less directly) extending configuration objects. At it's core, a Component is a combination of at least two things: a Config schema, and a build function. An example template of a basic Component is provided below.

```dhall
let K = ../External/Kubernetes.dhall

let Config = {
  Type = {
    {- put your config field types here -}
  },
  default = {
    {- put default values for config fields here -}
  }
}

{- build returns whatever Kubernetes config object this Component represents -}
let build : Config.Type -> K.Something =
  ...

in {Config, build}
```

From this interface, the regular usage of a Component looks like:

```dhall
let MyScope/MyComponent = ../MyScope/MyComponent.dhall

in MyScope/MyComponent.build MyScope/MyComponent.Config::{
  {- put configuration here -}
}
```

The schema provides an easy way to configure the Component while filling in default values and asserting the type, and the build function provides the interface to generate the underlying config object from a configuration. Using dhall's record operators, we can extend Components to generate new Components. Take for instance the following example of this pattern:

```dhall
{- Object/A.dhall: base Component -}

let Config = {
  Type = {
    ids: List Text
  },
  default = {
    ids: ([] : List Text)
  }
}

let build = \(conf : Config.Type) ->
  K.Object::{ids = ids}

in {Config, build}

{- Object/B.dhall: extension of Component A -}

let Object/A = ./A.dhall

let Config = {
  {- extend the underlying config type -}
  Type = Object/A.Config.Type //\\ {
    appId: Text
  },
  {- extend the underlying defaults; can override defaults here if desired -}
  default = Object/A.Config.default // {
    appId = "test"
  }
}

let build = \(conf : Config.Type) ->
  {- modify the incoming config fields before passing to parent Component -}
  let confA = conf with ids = [conf.appId] # conf.ids
  {- downcast the modified configuration and pass it into the parent Component -}
  {- this step is necessary to remove the additional fields we added -}
  in Object/A.build confA.(Object/A.Config.Type)

in {Config, build}
```

For a simple example of how this pattern can be applied, take a peek at `Containers/Bash.dhall`, which extends `Containers/Base.dhall`, and `Containers/Python.dhall`, which extends the aforementioned `Containers/Bash.dhall`.

## Imports

As a standard, we maintain top-level directory structure in the qualified names of files we import. Only two directories in the project are special and do not follow this pattern: `Eternal/` and `Lib/`. Files in the `Lib/` folder do not have qualified names which are prefixed with `Lib/`, and same for `External/`. As a pattern, we tend to list imports 3 sections, each of which is ordered alphebetically: external imports, lib imports, and other imports. An example is provided below:

```dhall
{- we tend to shorten Kubernetes to just K for convenience -}
let K = ../External/Kubernetes.dhall

let Constants = ../Lib/Constants.dhall
let Volume = ../Lib/Volume.dhall

let Containers/Bash = ../Containers/Bash.dhall
let Deployments/BlockProducer = ../Deployments/BlockProducer.dhall
```
