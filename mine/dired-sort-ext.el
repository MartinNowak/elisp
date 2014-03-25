;; Redefine the sorting in dired to flip between sorting on name, size,
;; time, and extension,  rather than simply on name and time.

(provide 'dired-sort-ext)

(defun dired-sort-toggle ()
  "Toggle between sort by date/name/.  Reverts the buffer."
  (setq dired-actual-switches
        (let (case-fold-search)
          (cond
           ((string-match " " dired-actual-switches) ;; contains a space
            ;; New toggle scheme: add/remove a trailing " -t" " -S",
            ;; or " -U"
            (cond
             ((string-match " -t\\'" dired-actual-switches)
              (concat
               (substring dired-actual-switches 0 (match-beginning 0))
               " -X"))
             ((string-match " -X\\'" dired-actual-switches)
              (concat
               (substring dired-actual-switches 0 (match-beginning 0))
               " -S"))
             ((string-match " -S\\'" dired-actual-switches)
              (substring dired-actual-switches 0 (match-beginning 0)))
             (t
              (concat dired-actual-switches " -t"))))
           (t
            ;; old toggle scheme: look for a sorting switch, one of [tUXS]
            ;; and switch between them. Assume there is only ONE present.
            (let* ((old-sorting-switch
                    (if (string-match (concat "[t" dired-ls-sorting-switches "]")
                                      dired-actual-switches)
                        (substring dired-actual-switches (match-beginning 0)
                                   (match-end 0))
                      ""))
                   (new-sorting-switch
                    (cond
                     ((string= old-sorting-switch "t")
                      "X")
                     ((string= old-sorting-switch "X")
                      "S")
                     ((string= old-sorting-switch "S")
                      "")
                     (t
                      "t"))))
              (concat
               "-l"
               ;; strip -l and any sorting switches
               (dired-replace-in-string (concat "[-lt"
                                                dired-ls-sorting-switches "]")
                                        ""
                                        dired-actual-switches)
               new-sorting-switch))))))
  (dired-sort-set-modeline)
  (revert-buffer))
