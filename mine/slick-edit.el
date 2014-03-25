;;; slick-edit.el --- Quick Single-Line Kill and Yank used in SlickEdit.
;; If region is inactive, copy and cut will operate on the current line, as if
;; the current line is currently selected.
;; See: http://www.emacswiki.org/emacs-en/SlickCopy
;; TODO: Integrate with auto-indent-mode.el at https://github.com/mlf176f2/auto-indent-mode.el/

(defgroup slick-edit nil
  "Productivity Enhancements to killing and yanking."
  :group 'editing)

(defvar slick-kill-active nil "Indicates that last kill command was slick (killed current line only).")
(defvar slick-copy-count 1 "Number of slick copy of recent slick `kill-ring-save'.")
(defvar slick-yank-count 0 "Number of slick yanks of recent slick kill.")

(defun slick-copy-region-as-kill (&rest rest)
  "When called with no active region, copy current line."
  (interactive)
  (setq slick-kill-active (null mark-active)
        slick-yank-count 0)
  (if mark-active (copy-region-as-kill (region-beginning)
                                       (region-end))
    (unless (minibufferp) (message "Copied line"))
    (copy-region-as-kill (line-beginning-position)
                         (line-beginning-position 2))))

(defun slick-kill-ring-save (&rest rest)
  "When called with no active region, save current line."
  (interactive)
  (setq slick-kill-active (null mark-active)
        slick-yank-count 0
        slick-copy-count (if (memq last-command '(slick-kill-ring-save))
                             (1+ slick-copy-count)
                           1))
  (if mark-active (kill-ring-save (region-beginning)
                                  (region-end))
    (unless (minibufferp) (if (>= slick-copy-count 2)
                              (message "Copied %s lines" slick-copy-count)
                            (message "Copied line")))
    (kill-ring-save (line-beginning-position)
                    (line-beginning-position (1+ slick-copy-count)))))
(global-set-key [(meta ?w)] 'slick-kill-ring-save)

(defun slick-kill-region (&rest rest)
  "When called with no active region, kill current line."
  (interactive)
  (setq slick-kill-active (null mark-active)
        slick-yank-count 0)
  (if mark-active (kill-region (region-beginning)
                               (region-end))
    (unless (minibufferp) (message "Killed line"))
    (kill-region (line-beginning-position)
                 (line-beginning-position 2))))
(global-set-key [(control ?w)] 'slick-kill-region)

(defun slick-yank (&rest rest)
  "Yank Do What I Mean (DWIM."
  (interactive "*P")
  (if (and slick-kill-active
           (memq last-command '(copy-region-as-kill
                                kill-ring-save
                                kill-region
                                yank )))
      (save-excursion (bol)
                      (prog1 (yank rest)
                        (incf slick-yank-count)
                        (message "Inserted line copy%s" (if (zerop slick-yank-count)
                                                            ""
                                                          (format " %s" slick-yank-count)))))
    (setq slick-kill-active nil)        ;not active anymore
    (setq slick-yank-count 0)
    (yank (delq nil rest))              ;normal yank
    (unless (minibufferp)
      (message "Inserted killed region"))))
(global-set-key [remap yank] 'slick-yank) ;Undo: (global-set-key [remap yank] nil)

(defface yank '((t (:inherit highlight))) "Face used to highlight yanks." :group 'slick-edit)

;;; Highlighting
(when (require 'hictx nil t)
  (defadvice slick-kill-ring-save (after ctx-flash-slick-kill-ring-save activate)
    (when (called-interactively-p 'any) (hictx-mark-region-or-lines slick-copy-count 'region)))
  (defadvice slick-copy-region-as-kill (after ctx-flash-slick-copy-region-as-kill activate)
    (when (called-interactively-p 'any) (hictx-mark-region-or-lines nil 'region)))
  (defadvice slick-kill-region (after ctx-flash-slick-kill-region activate)
    (when (called-interactively-p 'any) (when (use-region-p) (hictx-line))))
  (defadvice yank (after ctx-flash-yank activate)
    (when (called-interactively-p 'any) (hictx-region nil 'yank)))
  (defadvice slick-yank (after ctx-flash-slick-yank activate)
    (when (called-interactively-p 'any) (hictx-region nil 'yank)))
  )

;;; Another Alternative
;; (when nil
;;   (defadvice kill-ring-save (around slick-copy-kill-ring-save activate)
;;     "When called interactively with no active region, copy a single line instead."
;;     (if (or (use-region-p) (not (called-interactively-p)))
;;         ad-do-it
;;       (kill-new (buffer-substring (line-beginning-position)
;;                                   (line-beginning-position 2))
;;                 nil '(yank-line))
;;       (message "Copied line"))) (ad-activate 'kill-ring-save)
;;   (defadvice kill-region (around slick-copy-kill-region activate)
;;     "When called interactively with no active region, kill a single line instead."
;;     (if (or (use-region-p) (not (called-interactively-p)))
;;         ad-do-it
;;       (kill-new (filter-buffer-substring (line-beginning-position)
;;                                          (line-beginning-position 2) t)
;;                 nil '(yank-line)))) (ad-activate 'kill-region)
;;   (defun yank-line (string)
;;     "Insert STRING above the current line."
;;     (beginning-of-line)
;;     (unless (= (elt string (1- (length string))) ?\n)
;;       (save-excursion (insert "\n")))
;;     (insert string)) (ad-activate 'yank-line)
;;   ;; Thus, a line can be duplicated with ‘M-w C-y’.
;;   )

;;; Yet Another Alternative
;; (when nil
;;   (defun slick-copy ()
;;     (interactive)
;;     "Copy the current line if region is inactive.
;;     Otherwise it behaves just like `kill-ring-save'."
;;     (condition-case VAR
;;         (progn (mark)
;;                (kill-ring-save (region-beginning) (region-end)))
;;       ('mark-inactive
;;        (kill-ring-save (line-beginning-position)
;;                        (line-beginning-position 2))
;;        (message "Copied line"))))
;;   (defcustom slick-save-to-kill-ring t
;;     "Specify whether slick-cut should use the kill-ring.
;;      If `nil', it will delete the line instead of killing it.")
;;   (defun slick-cut (toggle-save-to-kill-ring)
;;     (interactive "P")
;;     "Cut the current line if region is inactive.
;;     Otherwise it behaves just like `kill-region'.
;;     If prefix argument is specified, will use `delete-region'
;;     instead (in case you are deleting a bunch of junk and you don't
;;     want to pollute your kill-ring.) Prefix argument will toggle back
;;     to `kill-region' again."
;;     (condition-case VAR (progn (mark) (kill-region (region-beginning) (region-end)))
;;       ('mark-inactive
;;        (if toggle-save-to-kill-ring
;;            (setq slick-save-to-kill-ring
;;                  (if slick-save-to-kill-ring '() t)))
;;        (if slick-save-to-kill-ring
;;            (progn (kill-region (line-beginning-position) (line-beginning-position 2))
;;                   (message "Cut line"))
;;          (progn (delete-region (line-beginning-position) (line-beginning-position 2))
;;                 (message "Killed line"))))))
;;   (global-set-key "\M-w" 'slick-copy)
;;   (global-set-key "\C-w" 'slick-cut)
;;   )

;;; Advice Variants
;; (when nil
;;   (defadvice copy-region-as-kill (before slick-copy-region-as-kill activate compile)
;;     "When called interactively with no active region, copy the current line instead."
;;     (interactive
;;      (progn (setq slick-kill-active (null mark-active)
;;                   slick-yank-count 0)
;;             (if mark-active          ;Note: Independent of 'transient-mark-mode'
;;                 (list (region-beginning)
;;                       (region-end))
;;               (unless (minibufferp)
;;                 (message "Copied line"))
;;               (list (line-beginning-position)
;;                     (line-beginning-position 2))
;;               ))))
;;   (defadvice kill-ring-save (before slick-kill-ring-save activate compile)
;;     "When called interactively with no active region, kill the current line instead."
;;     (interactive
;;      (progn (setq slick-kill-active (null mark-active)
;;                   slick-yank-count 0
;;                   slick-copy-count (if (memq last-command '(kill-ring-save))
;;                                        (1+ slick-copy-count)
;;                                      1))
;;             (if mark-active          ;Note: Independent of 'transient-mark-mode'
;;                 ;; normal behaviour
;;                 (list (region-beginning)
;;                       (region-end))
;;               ;; slick behaviour
;;               (unless (minibufferp)
;;                 (if (>= slick-copy-count 2)
;;                     (message "Copied %s lines" slick-copy-count)
;;                   (message "Copied line")))
;;               (list (line-beginning-position)
;;                     (line-beginning-position (1+ slick-copy-count)))))))
;;   (global-set-key [(meta ?w)] 'kill-ring-save)
;;   (defadvice kill-region (before slick-kill-region activate compile)
;;     "When called interactively with no active region, kill a
;; single line instead."
;;     (interactive
;;      (progn (setq slick-kill-active (null mark-active)
;;                   slick-yank-count 0)
;;             (if mark-active
;;                 (list (region-beginning)
;;                       (region-end))
;;               (unless (minibufferp)
;;                 (message "Killed line"))
;;               (list (line-beginning-position)
;;                     (line-beginning-position 2))))))
;;   (when (require 'hictx nil t)
;;     (defadvice kill-ring-save (after ctx-flash-kill-ring-save activate)
;;       (when (called-interactively-p 'any) (hictx-mark-region-or-lines slick-copy-count 'region)))
;;     ;; (defadvice copy-region-as-kill (after ctx-flash-copy-region-as-kill activate)
;;     ;;   (when (called-interactively-p 'any) (hictx-mark-region-or-lines nil 'region)))
;;     ;; (defadvice kill-region (after ctx-flash-kill-region activate)
;;     ;;   (when (called-interactively-p 'any) (when (use-region-p) (hictx-line))))
;;     (defadvice yank (after ctx-flash-yank activate)
;;       (when (called-interactively-p 'any) (hictx-region nil 'yank)))
;;     (defadvice slick-yank (after ctx-flash-slick-yank activate)
;;       (when (called-interactively-p 'any) (hictx-region nil 'yank)))
;;     )
;; )

(provide 'slick-edit)
