;;; def-unless.el --- Unobtrusive definitions

(defmacro defalias-unless-fboundp (symbol definition &optional docstring)
  "Set symbol's function definition to definition, and return
definition if it is not already bound to a function."
  (if (fboundp symbol)
      (error  "%s already fboundp!" symbol)
    (defalias symbol definition docstring)))

(defmacro defun-unless-fboundp (name arglist docstring body...)
  (if (fboundp name)
      (error  "%s already fboundp!" name)
    (defun name (arglist docstring body))))

(defmacro defmacro-unless-fboundp (name arglist docstring decl body...)
  (if (fboundp name)
      (error  "%s already fboundp!" name)
    (defmacro name (arglist docstring decl body))))

(provide 'def-unless)
