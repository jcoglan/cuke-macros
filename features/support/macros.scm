(define-syntax scenario (syntax-rules (tag step_invocation)
  ((scenario x "Scenario:" "Standard users"
     (tag "@outline")
     (step_invocation y "Given" "I am in group \"<group>\"")
     (step_invocation z "Then" "I should see \"<result>\""))
   (scenario x "Scenario:" "Standard users"
     (step_invocation y "Given" "I am in group \"A\"")
     (step_invocation z "Then" "I should see \"something\"")))
))

