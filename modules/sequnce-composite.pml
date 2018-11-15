@startuml

title Authorisation
actor User
actor Relayer
participant Identity
participant Multisig
participant DailyLimit
participant RelayerNetwork


Relayer -> Identity: executeSigned
Identity -> Multisig: canExecute
Identity <- Multisig
Multisig -> DailyLimit: canExecute
Multisig <- DailyLimit
Identity -> RelayerNetwork: canExecute
Identity <- RelayerNetwork

@enduml