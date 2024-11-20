extends ActionStepResult
class_name DamageStepResult

var HealthDelta : int # The signed amount the Health of the Target should move. If being delt damage, this will be negative. If healing, this will be positive
var SourceHealthDelta : int # Signed amount referring to how the Sources HP will be modified. Positive is a heal, negative is a self-damage
var FocusDelta : int

var Miss : bool
var Crit : bool
