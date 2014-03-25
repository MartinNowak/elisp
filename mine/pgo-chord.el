;;; pgo-chord.el --- Setup Key and Space Chords.
;; Author: Per Nordlöw

;;; key-chord.el --- map pairs of simultaneously pressed keys to commands
(when nil ;Note: WARNING: Disabled because chord-actions happens for me in normal writing aswell.
  (when (require 'key-chord nil t)
    (key-chord-mode 1)
    ;; and some chords, for example
    (key-chord-define-global "fg" 'redo)
    (key-chord-define-global "hj" 'undo)
    (key-chord-define-global "89" "()")
    (key-chord-define-global "70" "{}")
    (key-chord-define-global ",." "<>\C-b")
    (key-chord-define-global "jk" 'dabbrev-expand)
    (key-chord-define-global "cv" 'reindent-then-newline-and-indent)
    (key-chord-define-global "4r" "$")
    (key-chord-define-global "3e" "£")
    (key-chord-define-global "2w" "@")
    )
  )

;;; space-chord.el --- key chord with space
(when nil ;Note: WARNING: Disabled because chord-actions happens for me in normal writing aswell.
  (when (require 'space-chord nil t)
    (space-chord-define-global "f" 'find-file)
    (space-chord-define-global "r" 'find-file-read-only)
    (space-chord-define-global "w" 'write-file)
    (space-chord-define-global "u" 'upcase-region)
    (space-chord-define-global "l" 'downcase-region)
    (space-chord-define-global "c" 'compile)
    (space-chord-define-global "b" 'switch-to-buffer)
    (space-chord-define-global "g" 'tgrep-string)

    (space-chord-define-global "1" 'delete-other-windows)
    (space-chord-define-global "2" 'split-window-vertically)
    (space-chord-define-global "3" 'split-window-horizontally)

    ;;(space-chord-define-global "<>\C-j" 'hippie-expand)
    )
  )

(provide 'pgo-chord)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-chord.el ends here
