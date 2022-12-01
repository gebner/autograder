import Lake
open Lake DSL

package autograder

@[default_target]
lean_exe autograder where
  root := `Main
  supportInterpreter := true
