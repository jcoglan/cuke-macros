(define-syntax tag-macro (syntax-rules ()
  ((tag-macro name
     ((root-name pattern ...) template)
     ...)
   (define-syntax name (syntax-rules (scenario scenario_outline step step_invocation examples table row cell)
     ((_ root-name pattern ...) template)
     ...)))))

