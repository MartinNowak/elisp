;;; tab-utils.el --- Tab Utilities
;; Author: Per Nordlöw

;; in text mode, make tab stops correlate with tab width
;; NOTE: smarter than =text-mode would be to test for tab bound
;; to tab-to-next-tab-stop, but that's a later microproject
(defun make-tab-stops-like-I-like-em ()
  (if (and (/= tab-width 8) (eq major-mode 'text-mode))
      (let ((column (* tab-width (/ 131 tab-width)))
            (stops ()))
        (while (>= column 0)
          (setq stops (cons column stops)
                column (- column tab-width)))
        (setq tab-stop-list stops))))
;;(add-hook 'hack-local-variables-hook 'make-tab-stops-like-I-like-em)

(setq default-tab-width 8)
(setq-default indent-tabs-mode nil)

(defvar pnw-tab-width default-tab-width
  "Variable used in function toggle-tab-width.")

(defun toggle-tab-width ()
  "Toggle the tab width between 2, 4 and 8."
  (interactive)
  (cond
   ((= pnw-tab-width 2)
    (setq pnw-tab-width 4))
   ((= pnw-tab-width 4)
    (setq pnw-tab-width 8))
   ((= pnw-tab-width 8)
    (setq pnw-tab-width 2)))
  (message "Tab width changed to %d." pnw-tab-width)
  (setq tab-width pnw-tab-width)
  (redraw-display))

(provide 'tab-utils)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; tab-utils.el ends here
