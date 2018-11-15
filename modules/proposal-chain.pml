@startuml

class Identity {
    moduleExecute()
    executeSigned()
}

class Multisig {
    canExecute()
}

class ERC725 {
    canExecute()
}

class DailyLimit {
    canExecute()
}

class ReleayerNetwork {
    canExecute()
}

class ReccuringSubscription {
    amount
    period
    canExecute()
}

 
Identity o-- Multisig
Identity o-- ERC725
Identity o-- ReccuringSubscription
Identity o-- DailyLimit
Identity o-- ReleayerNetwork


@enduml