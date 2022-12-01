import Lean
open Lean IO System

structure ExerciseResult where
  name : Name
  passed : Bool
  messages : Array String := #[]
  deriving ToJson

structure GradingResults where
  errors : Array String -- compilation errors, etc.
  exercises : Array ExerciseResult
  deriving ToJson

def Lean.Environment.moduleDataOf? (module : Name) (env : Environment) : Option ModuleData := do
  let modIdx : Nat ← env.getModuleIdx? module
  env.header.moduleData[modIdx]?

def Lean.Environment.moduleOfDecl? (decl : Name) (env : Environment) : Option Name := do
  let modIdx : Nat ← env.getModuleIdxFor? decl
  env.header.moduleNames[modIdx]?

def grade (sheetName : Name) (sheet submission : Environment) : IO (Array ExerciseResult) := do
  let some sheetMod := sheet.moduleDataOf? sheetName
    | throw <| IO.userError s!"module name {sheetName} not found"
  let mut results := #[]
  -- TODO check imports
  for name in sheetMod.constNames, constInfo in sheetMod.constants do
    if constInfo.value?.any (·.hasSorry) then
      let result ←
        -- exercise to be filled in
        if let some subConstInfo := submission.find? name then
          if subConstInfo.value?.any (!·.hasSorry) then
            pure { name, passed := true }
          else
            pure { name, passed := false, messages := #["proof contains sorry"] }
        else
          pure { name, passed := false, messages := #["declaration not found in submission"] }
      results := results.push result
  return results

def main (args : List String) : IO Unit := do
  let usage := throw <| IO.userError s!"Usage: autograder Exercise.Sheet.Module submission-file.lean"
  let [sheetName, submission] := args | usage
  let submission : FilePath := submission
  let some sheetName := Syntax.decodeNameLit ("`" ++ sheetName) | usage
  searchPathRef.set (← addSearchPathFromEnv {})
  let sheet ← importModules [{module := sheetName}] {}
  let submissionBuildDir : FilePath := "build" / "submission"
  FS.createDirAll submissionBuildDir
  let submissionOlean := submissionBuildDir / "Submission.olean"
  if ← submissionOlean.pathExists then FS.removeFile submissionOlean
  let mut errors := #[]
  let submissionEnv ←
    try
      let out ← IO.Process.output {
        cmd := "lean"
        args := #[submission.toString, "-o", submissionOlean.toString]
      }
      if out.exitCode != 0 then
        throw <| IO.userError "Lean exited with code {out.exitCode}:\n{out.stderr}"
      searchPathRef.modify fun sp => submissionBuildDir :: sp
      importModules [{module := `Submission}] {}
    catch ex =>
      errors := errors.push ex.toString
      importModules sheet.header.imports.toList {}
  let exercises ← grade sheetName sheet submissionEnv
  let results : GradingResults := { errors, exercises }
  IO.println (toJson results).pretty
  unless results.errors.isEmpty && results.exercises.all (·.passed) do
    Process.exit 1
