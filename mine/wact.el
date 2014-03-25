(defun read-wact-command ()
  (completing-read-ng "WACT Command: "
                      '("get" "fetch"
                        "export"
                        "commit" "ci"
                        "status" "st"
                        "softlink" "ln"
                        "update" "up"
                        "switch" "sw"
                        "branch" "br"
                        "remove_ci_branch"
                        "lock"
                        "unlock"
                        "verify")))
;; Use: (read-wact-command)

(provide 'wact)
