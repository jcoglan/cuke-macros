
(tag-macro @split_test
  ((scenario line keyword name
     (step_invocation step-args ...)
     ...)
   (scenario_outline "Scenario Outline:" name
     (step line "Given" "I am in group \"<test group>\"")
     (step step-args ...)
     ...
     (examples "Examples:" name
       (table
         (row 0 (cell "test group") (cell "result"))
         (row 0 (cell "A")          (cell "something"))
         (row 0 (cell "B")          (cell "nothing")))
       ))))

(tag-macro @outline
  ((scenario_outline keyword name
     (step step-args ...)
     ...)
   (scenario 0 "Scenario:" name
     (step_invocation step-args ...)
     ...)))

