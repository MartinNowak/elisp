;;; yank-indent.el --- Indent on Yank and Pop.

(require 'cc-utils)

(defvar yank-indent-modes
  (append
   cc-derived-modes
   '(emacs-lisp-mode pascal-mode
                     f90-mode
                     octave-mode matlab-mode
                     tcl-mode sql-mode perl-mode
                     cperl-mode java-mode jde-mode LaTeX-mode TeX-mode sh-mode
                                        ;python-mode
                     ruby-mode html-mode))
  "List of modes in which a yank should be indented automatically.")

;; TODO Does this doesn't include case when M-w C-y.
(defadvice yank (after indent-region activate)
  (if (member major-mode yank-indent-modes)
      (save-excursion                    ;otherwise point and mark gets swapped
        (let ((mark-even-if-inactive t)) ;Alternative: (let ((transient-mark-mode nil))
          (indent-region (region-beginning)
                         (region-end) nil)
          ;;(indent-for-tab-command)
          ))))
(ad-activate 'yank)

;; TODO Does this doesn't include case when M-w C-y.
(defadvice yank-pop (after indent-region activate)
  (if (member major-mode yank-indent-modes)
      (save-excursion                   ;otherwise point and mark gets swapped
        (let ((mark-even-if-inactive t)) ;Alternative: (let ((transient-mark-mode nil))
          (indent-region (region-beginning)
                         (region-end) nil)
          ;;(indent-for-tab-command)
          ))))
(ad-activate 'yank-pop)

(provide 'yank-indent)
