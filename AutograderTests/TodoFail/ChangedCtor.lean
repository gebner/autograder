import AutograderTests.Util

in_exercise

  inductive Example
    | ctor (h : False)

  theorem exercise : Example :=
    sorry

in_solution

  inductive Example
    | ctor (h : True) -- clever change

  theorem exercise : Example :=
    ⟨⟨⟩⟩
