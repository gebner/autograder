import Lean
open Lean Elab Term Command

def inExercise : BaseIO Bool := return (← IO.getEnv "AUTOGRADER_IN_EXERCISE").isSome

syntax withPosition("in_exercise" (colGt command)*) : command
elab_rules : command
  | `(command| in_exercise $a*) => do
    let s ← get
    elabCommand (mkNullNode a)
    unless ← inExercise do
      modify fun s' => { s with infoState := s'.infoState }

syntax withPosition("in_solution" (colGt command)*) : command
elab_rules : command
  | `(command| in_solution $a*) => do
    let s ← get
    elabCommand (mkNullNode a)
    if ← inExercise then
      modify fun s' => { s with infoState := s'.infoState }

elab "if_in_exercise " a:term " else " b:term : term <= expectedType => do
  let a ← elabTerm a expectedType
  let b ← elabTerm b expectedType
  return if ← inExercise then a else b

macro "sorry_in_exercise_else " t:term : term =>
  `(if_in_exercise sorry else $t)
