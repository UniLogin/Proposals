@startuml

class Identity {
    moduleExecute()
    executeSigned()    
}

class CompositeAutorisation {
    canExecute()
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

Identity o-- CompositeAutorisation
CompositeAutorisation o-- Multisig
CompositeAutorisation o-- ERC725
CompositeAutorisation o-- ReccuringSubscription
Multisig o-- DailyLimit
Multisig o-- ReleayerNetwork


@enduml