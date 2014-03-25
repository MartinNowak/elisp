(defun endianess ()
  "Get Endianess."
  (if (= 1 (shell-command "python -c \"import sys; sys.exit(0 if sys.byteorder=='big' else 1)\""))
      "little"
    "big"))

(provide 'endianess)
