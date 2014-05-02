;;; hictx.el --- Highlight Operation Result or Context.
;; Author: Per Nordlöw
;;
;; TODO: Use ideas from `volatile-highlights' and `eval-sexp-fu' if relevant.
;; TODO: See: http://groups.google.se/group/gnu.emacs.help/browse_thread/thread/25024cc86611ea35#
;; TODO: Call the function `hictx-add-default-advice' to activate default context highlighters.
;; TODO: Notify hictx.el to author of nav-flash
;; TODO: Highlight region of `kmacro-end-or-call-macro-dwim' and `kmacro-call-macro'.
;; TODO: Generalize hictx-XXX with higher-order function (defun hictx-at (move-fun)).
;; TODO: Reuse functions in `highlight.el'

(require 'timer)
(require 'power-utils)

(defgroup hictx nil
  "Highlight Contexts of Operations."
  :group 'tools)

(defface hictx-face      '((t (:background "#404040"))) "Face used to highlight context.")
(defface hictx-eval-face '((t (:background "#404040" :inherit widget-button-pressed))) "Face used to highlight evaluate context.")
(defface hictx-kill-face '((t (:background "red" :foreground "black"))) "Face used to highlight kill context.")
(defface hictx-delete-face '((t (:background "red" :foreground "black"))) "Face used to highlight delete context.")

(defcustom hictx-timeout      0.15 "Default time period to display the highlighted context." :group 'hictx)
(defcustom hictx-eval-timeout 0.20 "Default time period to display the evaluated context." :group 'hictx)
(defcustom hictx-kill-timeout 0.05 "Default time period to display the killed context." :group 'hictx)
(defcustom hictx-new-window-timeout 0.16 "Default time period to display cross-window navigated content." :group 'hictx)

;; bounds-of-symbol-atpt
;; tap-bounds-of-symbol-at-point

(defvar hictx-overlays nil
  "Last overlay created by `hictx-generic'.")
(make-variable-buffer-local 'hictx-overlays) ;we need one for each buffer

(defun hictx-log (overlay)
  "Log OVERLAY in `hictx-overlays'."
  (setq hictx-overlays (cons overlay hictx-overlays)))

(defun hictx-delete (&optional overlay buffer-or-name)
  "Delete OVERLAY(s) created in BUFFER-OR-NAME.
If OVERLAY is `t' delete all hictx overlays in BUFFER, if nil
default to last overlay.  If BUFFER-OR-NAME is `t' delete in all
buffers and if nil default to `current-buffer'."
  (interactive)
  (cond ((eq overlay 't)                ;all overlays
         (mapc 'delete-overlay hictx-overlays)
         (setq hictx-overlays nil)
         ;; (setq hictx-overlays
         ;;       (delq nil
         ;;             (mapcar (lambda (overlay)
         ;;                       (if (or (not buffer-or-name) ;all overlays regardless of window
         ;;                               (eq (overlay-get overlay 'window)
         ;;                                   (buffer-window buffer-or-name)))
         ;;                           (progn (delete-overlay overlay) nil)
         ;;                         overlay))
         ;;                     hictx-overlays)))
         )
        ((overlayp overlay)             ;single specific overlay
         (delete-overlay overlay)
         (setq hictx-overlays (delete overlay hictx-overlays))
         )
        ((null overlay)                 ;last overlay
         (let ((overlay (car hictx-overlays)))
           (when overlay
             (delete-overlay overlay)
             (setq hictx-overlays (delete overlay hictx-overlays))
             ;;(error "No last overlay in %s" buffer-or-name)
             )))
        ))
(defun hictx-delete-all (&optional buffer-or-name)
  "Delete all hictx overlays."
  (interactive)
  (when hictx-overlays                  ;optimization for `pre-command-hook'
    (hictx-delete t buffer-or-name)))
;; (remove-hook 'pre-command-hook 'hictx-delete-all)
;; Use: (hictx-delete) => normally error
;; Use: (hictx-delete t) => ok
;; Use: (hictx-delete t "*Messages*") => ok
;; Use: (hictx-delete t "*fMessages*") => error

;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/1a9678d00146647c
;; TODO: Add `delay' and use this in `previous-line' and `next-line' advice.
(defun hictx-generic (&optional start end window face duration delay keep-last sync-flag)
  "Highlight region from START to END with FACE in WINDOW for
DURATION seconds. START defaults to beginning of line, END to end
of line, WINDOW to `selected-window', FACE to `next-error' and
DURATION to `hictx-timeout'. If KEEP-LAST is non-nil keep the
overlay untouched (until it finishes), `hictx-last-overlay'."
  (let* ((buffer (window-buffer window))
         (overlay (make-overlay (or start (line-beginning-position))
                                (or end (line-end-position))
                                buffer)))
    (unless keep-last
      (hictx-delete-all buffer))
    (hictx-log overlay)
    (when window
      (overlay-put overlay 'window window))
    (overlay-put overlay 'face (or face 'hictx-face))
    (run-with-timer (or duration hictx-timeout) nil ;run in original window to prevent flashing of menus
                    #'hictx-delete
                    overlay buffer)) ;delete overlay later kind of "asynchronously"
  (when sync-flag
    (with-timeout ((or duration hictx-timeout))
      (hictx-wait-key))))
;; Use: (progn (hictx-generic (- (point) 10) (+ (point) 0)) (hictx-generic (+ (point) 10) (+ (point) 20) nil nil nil t))
;; Use: (progn (hictx-generic (- (point) 10) (+ (point) 0)) (hictx-generic (+ (point) 10) (+ (point) 20) nil nil nil t t))

(defun hictx-line (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (hictx-generic (line-beginning-position) (line-beginning-position 2) window face duration delay keep-last async-flag)))
;; Use: (hictx-line)
;; Use: (progn (display-buffer (get-buffer-create "*scratch*") t) (hictx-line (get-buffer-window "*scratch*") nil nil nil))

(defun hictx-lines (num &optional window face duration delay keep-last async-flag)
  "Highlight NUM number of lines."
  (with-selected-window (or window (selected-window))
    (hictx-generic (line-beginning-position) (line-beginning-position (1+ num)) window face duration delay keep-last async-flag)))
;; Use: (hictx-line)
;; Use: (progn (display-buffer (get-buffer-create "*scratch*") t) (hictx-line (get-buffer-window "*scratch*") nil nil nil))

(defun hictx-line-content (&optional window face duration delay keep-last async-flag)
  "Highlight Line Content."
  (with-selected-window (or window (selected-window))
    (hictx-generic (line-beginning-position) (line-end-position))))

(defun hictx-region (&optional window face duration delay keep-last async-flag)
  "Highlight current region."
  (with-selected-window (or window (selected-window))
    (hictx-generic (region-beginning) (region-end) window face duration delay keep-last async-flag)))

(defun hictx-match (&optional subexp window face duration delay keep-last async-flag)
  "Highlight match SUBEXP."
  (with-selected-window (or window (selected-window))
    (hictx-generic (match-beginning subexp) (match-end subexp) window face duration delay keep-last async-flag)))

(defun hictx-buffer (&optional window face duration delay keep-last async-flag)
  "Highlight current buffer."
  (with-selected-window (or window (selected-window))
    (hictx-generic (point-min) (point-max) window face duration delay keep-last async-flag)))

(defun hictx-defun-atpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((bounds (bounds-of-defun-atpt)))
      (hictx-generic (car bounds) (cadr bounds) window face duration delay keep-last async-flag))))
(defun hictx-defun-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (end-of-defun 1) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))
(defun hictx-defun-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (beginning-of-defun 1) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-c-defun-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (c-end-of-defun 1) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-c-defun-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (c-beginning-of-defun 1) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-c-statement-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (c-end-of-statement 1) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-c-statement-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (c-beginning-of-statement 1) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-sexp-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (forward-sexp-safe) (point))))
      (when (neq beg end)
        (hictx-generic beg end window face duration delay keep-last async-flag)))))

(defun hictx-sexp-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (backward-sexp-safe) (point))))
      (when (neq beg end)
        (hictx-generic beg end window face duration delay keep-last async-flag)))))

(defun hictx-word-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (forward-word) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))
(defun hictx-word-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (backward-word) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-subword-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (subword-forward) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))
(defun hictx-subword-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (subword-backward) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-c-arg-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (c-forward-arg) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))
(defun hictx-c-arg-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (c-backward-arg) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-c-token-unbalanced-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (c-forward-token-unbalanced) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))
(defun hictx-c-token-unbalanced-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (c-backward-token-unbalanced) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-c-token-balanced-afpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((beg (point)) (end (save-excursion (c-forward-token-balanced) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))
(defun hictx-c-token-balanced-bfpt (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((end (point)) (beg (save-excursion (c-backward-token-balanced) (point))))
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-symbol-at-point (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let ((bounds (cond ((fboundp 'tap-bounds-of-symbol-at-point)
                         (tap-bounds-of-symbol-at-point)))))
      (when bounds
        (hictx-generic (car bounds) (cdr bounds) window face duration delay keep-last async-flag)))))

(defun hictx-button (&optional window face duration delay keep-last async-flag)
  (with-selected-window (or window (selected-window))
    (let* ((button (button-at (point)))
           (beg (button-start button))
           (end (button-end button))
           )
      (hictx-generic beg end window face duration delay keep-last async-flag))))

(defun hictx-wait-key (&optional exit-char message)
  "Momentarily wait until a key stroke is pressed.
The pressed key is not consumed and will be acted upon as usual.
This is used to do something after the next key is pressed.
Imagine that you're levitating in a Tibetan buddhist temple and
that you're waiting for the other shoe to drop.  This was
inspired by the implementation of momentary-string-display."
  (let ((inhibit-read-only t)
        ;; Don't modify the undo list at all.
        (buffer-undo-list t)
        )
    (unwind-protect
        (let (char)
          (when exit-char
            (message (or message "Type %s to continue editing.")
                     (single-key-description exit-char)))
          (if (integerp exit-char)
              (condition-case nil
                  (progn
                    (setq char (read-char))
                    (or (eq char exit-char)
                        (setq unread-command-events (list char))))
                (error
                 ;; `exit-char' is a character, hence it differs
                 ;; from char, which is an event.
                 (setq unread-command-events (list char))))

            ;; `exit-char' can be an event, or an event description
            ;; list.
            (setq char (read-event))
            (or (eq char exit-char)
                (eq char (event-convert-list exit-char))
                (setq unread-command-events (list char)))))
      ))
  nil)

(defun hictx-mark-region-or-lines (&optional num face)
  "Highlight region if mark is active, otherwise current line.
If NUM is non-nil highlight NUM lines including current."
  (if (use-region-p)
      (hictx-region nil face)
    (if (and num (>= num 2))
        (hictx-lines num nil face)
      (hictx-line nil face))))

(defcustom hictx-buffer-fun 'hictx-line
  "Function to call to highlight buffer navigation and layout changes.
Suitables choices are `hictx-buffer' line `hictx-buffer'."
  :group 'hictx)

(defun hictx-add-default-advice ()
  "Set default highlight context advices."
  (interactive)
  ;; Buffer
  (defadvice beginning-of-buffer (after ctx-flash-beginning-of-buffer activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'beginning-of-buffer)
  (defadvice end-of-buffer (after ctx-flash-end-of-buffer activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'end-of-buffer)
  ;; Function
  (defadvice beginning-of-defun (after ctx-flash-beginning-of-defun activate) (when (called-interactively-p 'any) (hictx-defun-afpt))) (ad-activate 'beginning-of-defun)
  (defadvice end-of-defun (after ctx-flash-end-of-defun activate) (when (called-interactively-p 'any) (hictx-defun-bfpt))) (ad-activate 'end-of-defun)
  ;; C Function
  (defadvice c-beginning-of-defun (after ctx-flash-c-beginning-of-defun activate) (when (called-interactively-p 'any) (hictx-c-defun-afpt))) (ad-activate 'c-beginning-of-defun)
  (defadvice c-end-of-defun (after ctx-flash-c-end-of-defun activate) (when (called-interactively-p 'any) (hictx-c-defun-bfpt))) (ad-activate 'c-end-of-defun)
  ;; C Statement
  (defadvice c-beginning-of-statement (after ctx-flash-c-beginning-of-statement activate) (when (called-interactively-p 'any) (hictx-c-statement-afpt))) (ad-activate 'c-beginning-of-statement)
  (defadvice c-end-of-statement (after ctx-flash-c-end-of-statement activate) (when (called-interactively-p 'any) (hictx-c-statement-bfpt))) (ad-activate 'c-end-of-statement)
  ;; Line
  (defadvice move-beginning-of-line (after ctx-flash-move-beginning-of-line activate) (when (called-interactively-p 'any) (hictx-line-content))) (ad-activate 'move-beginning-of-line)
  (defadvice move-end-of-line (after ctx-flash-move-end-of-line activate) (when (called-interactively-p 'any) (hictx-line-content))) (ad-activate 'move-end-of-line)
  ;; Ibuffer Line
  (defadvice ibuffer-backward-line (after ctx-flash-ibuffer-backward-line activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ibuffer-backward-line)
  (defadvice ibuffer-forward-line (after ctx-flash-ibuffer-forward-line activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ibuffer-forward-line)
  (defadvice ibuffer-unmark-forward (after ctx-flash-ibuffer-unmark-forward activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ibuffer-unmark-forward)
  (defadvice ibuffer-mark-for-delete (after ctx-flash-ibuffer-mark-for-delete activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ibuffer-mark-for-delete)
  (defadvice ibuffer-mark-forward (after ctx-flash-ibuffer-mark-forward activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ibuffer-mark-forward)
  ;; Ibuffer Line
  ;; (defadvice dired-previous-line (after ctx-flash-dired-previous-line activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'dired-previous-line)
  ;; (defadvice dired-next-line (after ctx-flash-dired-next-line activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'dired-next-line)
  (defadvice diredp-previous-line (after ctx-flash-dired-previous-line activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'diredp-previous-line)
  (defadvice diredp-next-line (after ctx-flash-dired-next-line activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'diredp-next-line)
  ;; Sentence
  (defadvice forward-sentence (after ctx-flash-forward-sentence activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'forward-sentence)
  (defadvice backward-sentence (after ctx-flash-backward-sentence activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'backward-sentence)
  ;; SExp
  ;; (defadvice forward-sexp (after ctx-flash-forward-sexp activate) (when (called-interactively-p 'any) (hictx-sexp-bfpt))) (ad-deactivate 'forward-sexp)
  ;; (defadvice backward-sexp (after ctx-flash-backward-sexp activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-deactivate 'backward-sexp)
  (defadvice forward-sexp-safe (after ctx-flash-forward-sexp-safe activate) (when (called-interactively-p 'any) (hictx-sexp-bfpt))) (ad-activate 'forward-sexp-safe)
  (defadvice backward-sexp-safe (after ctx-flash-backward-sexp-safe activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'backward-sexp-safe)
  (defadvice paredit-forward (after ctx-flash-paredit-forward activate) (when (called-interactively-p 'any) (hictx-sexp-bfpt))) (ad-activate 'paredit-forward)
  (defadvice paredit-backward (after ctx-flash-paredit-backward activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'paredit-backward)
  (defadvice paredit-forward-down (after ctx-flash-paredit-forward-down activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'paredit-forward-down)
  (defadvice paredit-backward-up (after ctx-flash-paredit-backward-up activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'paredit-backward-up)
  ;; Word
  (defadvice right-word (after ctx-flash-right-word activate) (when (called-interactively-p 'any) (hictx-word-bfpt))) (ad-activate 'right-word)
  (defadvice left-word (after ctx-flash-left-word activate) (when (called-interactively-p 'any) (hictx-word-afpt))) (ad-activate 'left-word)
  ;; C SubWord
  (defadvice subword-forward (after ctx-flash-subword-forward activate) (when (called-interactively-p 'any) (hictx-subword-bfpt))) (ad-activate 'subword-forward)
  (defadvice subword-backward (after ctx-flash-subword-backward activate) (when (called-interactively-p 'any) (hictx-subword-afpt))) (ad-activate 'subword-backward)
  ;; Word
  (defadvice forward-word (after ctx-flash-forward-word activate) (when (called-interactively-p 'any) (hictx-word-bfpt))) (ad-activate 'forward-word)
  (defadvice backward-word (after ctx-flash-backward-word activate) (when (called-interactively-p 'any) (hictx-word-afpt))) (ad-activate 'backward-word)
  (defadvice forward-word-safe (after ctx-flash-forward-word-safe activate) (when (called-interactively-p 'any) (hictx-word-bfpt))) (ad-activate 'forward-word-safe)
  (defadvice backward-word-safe (after ctx-flash-backward-word-safe activate) (when (called-interactively-p 'any) (hictx-word-afpt))) (ad-activate 'backward-word-safe)
  ;; C Arguments
  (defadvice c-forward-arg (after ctx-flash-c-forward-arg activate) (when (called-interactively-p 'any) (hictx-c-arg-bfpt))) (ad-activate 'c-forward-arg)
  (defadvice c-backward-arg (after ctx-flash-c-backward-arg activate) (when (called-interactively-p 'any) (hictx-c-arg-afpt))) (ad-activate 'c-backward-arg)
  (defadvice c-beginning-of-arglist (after ctx-flash-c-beginning-of-arglist activate) (when (called-interactively-p 'any) (hictx-c-arg-afpt))) (ad-activate 'c-beginning-of-arglist)
  (defadvice c-end-of-arglist (after ctx-flash-c-end-of-arglist activate) (when (called-interactively-p 'any) (hictx-c-arg-bfpt))) (ad-activate 'c-end-of-arglist)
  (defadvice c-beginning-of-tokenlist (after ctx-flash-c-beginning-of-tokenlist activate) (when (called-interactively-p 'any) (hictx-c-token-unbalanced-afpt))) (ad-activate 'c-beginning-of-tokenlist)
  (defadvice c-end-of-tokenlist (after ctx-flash-c-end-of-tokenlist activate) (when (called-interactively-p 'any) (hictx-c-token-unbalanced-bfpt))) (ad-activate 'c-end-of-tokenlist)
  ;; CC Tokens
  (defadvice c-forward-token-balanced (after ctx-flash-c-forward-token-balanced activate) (when (called-interactively-p 'any) (hictx-c-token-balanced-bfpt))) (ad-activate 'c-forward-token-balanced)
  (defadvice c-backward-token-balanced (after ctx-flash-c-backward-token-balanced activate) (when (called-interactively-p 'any) (hictx-c-token-balanced-afpt))) (ad-activate 'c-backward-token-balanced)
  (defadvice c-forward-token-unbalanced (after ctx-flash-c-forward-token-unbalanced activate) (when (called-interactively-p 'any) (hictx-c-token-unbalanced-bfpt))) (ad-activate 'c-forward-token-unbalanced)
  (defadvice c-backward-token-unbalanced (after ctx-flash-c-backward-token-unbalanced activate) (when (called-interactively-p 'any) (hictx-c-token-unbalanced-afpt))) (ad-activate 'c-backward-token-unbalanced)
  (defadvice c-mark-token-balanced (after ctx-flash-c-mark-token-balanced activate) (when (called-interactively-p 'any) (hictx-c-token-balanced-afpt))) (ad-activate 'c-mark-token-balanced)
  ;; List
  (defadvice backward-up-list (after ctx-flash-backward-up-list activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'backward-up-list)
  (defadvice down-list (after ctx-flash-down-list activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'down-list)
  (defadvice beginning-of-list (after ctx-flash-beginning-of-list activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'beginning-of-list)
  (defadvice end-of-list (after ctx-flash-end-of-list activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'end-of-list)
  ;; Line
  (defadvice goto-line (after ctx-flash-goto-line activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'goto-line)
  ;; Char
  (defadvice goto-char (after ctx-flash-goto-char activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'goto-char)
  ;; Minibuffer Completion Navigation (right/left)
  (defadvice previous-completion (after ctx-flash-previous-completion activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'previous-completion)
  (defadvice next-completion (after ctx-flash-next-completion activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'next-completion)

  ;; Paragraph
  (defadvice backward-paragraph-nomark (after ctx-flash-backward-paragraph-nomark activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'backward-paragraph-nomark)
  (defadvice forward-paragraph-nomark (after ctx-flash-forward-paragraph-nomark activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'forward-paragraph-nomark)

  ;; Window Focus Navigation and Layout
  (defadvice other-window (after ctx-flash-other-window activate) (when (called-interactively-p 'any) (funcall hictx-buffer-fun))) (ad-activate 'other-window)
  (defadvice window-number-select (after ctx-flash-window-number-select activate) (when (called-interactively-p 'any) (funcall hictx-buffer-fun))) (ad-activate 'window-number-select)
  (defadvice select-window-by-number (after ctx-flash-select-window-by-number activate) (funcall hictx-buffer-fun)) (ad-activate 'select-window-by-number)
  (defadvice split-window-right (after ctx-flash-split-window-right activate) (funcall hictx-buffer-fun)) (ad-activate 'split-window-right)
  (defadvice split-window-below (after ctx-flash-split-window-below activate) (funcall hictx-buffer-fun)) (ad-activate 'split-window-below)

  ;; Window Undo and Redo
  (defadvice winner-undo (after ctx-flash-winner-undo activate) (when (called-interactively-p 'any) (hictx-line))) (ad-deactivate 'winner-undo)
  (defadvice winner-redo (after ctx-flash-winner-redo activate) (when (called-interactively-p 'any) (hictx-line))) (ad-deactivate 'winner-redo)

  ;; Window Navigation
  (defadvice select-previous-window (after ctx-flash-select-previous-window activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'select-previous-window)
  (defadvice select-next-window (after ctx-flash-select-next-window activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'select-next-window)
  (defadvice windmove-do-window-select (after ctx-flash-windmove-do-window-select activate) (hictx-line)) (ad-activate 'windmove-do-window-select)
  ;; (defadvice windmove-left (after ctx-flash-windmove-left activate) (hictx-line))
  ;; (defadvice windmove-right (after ctx-flash-windmove-right activate) (hictx-line))
  ;; (defadvice windmove-up (after ctx-flash-windmove-up activate) (hictx-line))
  ;; (defadvice windmove-down (after ctx-flash-windmove-down activate) (hictx-line))

  (defadvice move-line-region-up (after ctx-flash-windmove-up activate) (hictx-line)) (ad-activate 'move-line-region-up)
  (defadvice move-line-region-down (after ctx-flash-windmove-up activate) (hictx-line)) (ad-activate 'move-line-region-down)

  ;; Search
  (defadvice isearch-beginning-of-buffer (after ctx-flash-isearch-beginning-of-buffer activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'isearch-beginning-of-buffer)
  (defadvice isearch-end-of-buffer (after ctx-flash-isearch-end-of-buffer activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'isearch-end-of-buffer)

  ;; Note: This is too sluggish to be usable.
  ;; hictx: isearch-repeat-backward/forward
  ;;(defadvice isearch-forward (after ctx-flash-isearch-forward activate) (when (called-interactively-p 'any) (hictx-line)))
  ;;(add-hook 'isearch-update-post-hook (lambda () (hictx-line)))

  (add-hook 'imenu-after-jump-hook 'hictx-line nil t)

  ;; Window Scrolling
  (defadvice recenter (after ctx-flash-recenter activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'recenter)
  (defadvice recenter-top-bottom (after ctx-flash-recenter-top-bottom activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'recenter-top-bottom)
  (defadvice reposition-window (after ctx-flash-reposition-window activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'reposition-window)

  ;; Point/Mark
  (defadvice exchange-point-and-mark (after ctx-flash-exchange-point-and-mark activate) (when (called-interactively-p 'any) (hictx-region))) (ad-activate 'exchange-point-and-mark)
  (defadvice exchange-point-and-mark-nomark (after ctx-flash-exchange-point-and-mark-nomark activate) (when (called-interactively-p 'any) (hictx-region))) (ad-activate 'exchange-point-and-mark-nomark)

  ;; Scoll, disabled because of sluggishness
  (defadvice scroll-down-command (after ctx-flash-scroll-down-command activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'scroll-down-command)
  (defadvice scroll-up-command (after ctx-flash-scroll-up-command activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'scroll-up-command)
  ;; (defadvice scroll-left (after ctx-flash-scroll-left activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'scroll-left)
  ;; (defadvice scroll-right (after ctx-flash-scroll-right activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'scroll-right)
  ;; (defadvice scroll-down (after ctx-flash-scroll-down activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'scroll-down)
  ;; (defadvice scroll-up (after ctx-flash-scroll-up activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'scroll-up)
  ;; (defadvice scroll-down-nomark (after ctx-flash-scroll-down-nomark activate) (when (called-interactively-p 'any) (hictx-line)))
  ;; (defadvice scroll-up-nomark (after ctx-flash-scroll-up-nomark activate) (when (called-interactively-p 'any) (hictx-line)))

  ;; Tag Navigation
  (defadvice find-ectag (after ctx-flash-find-ectag activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'find-ectag)
  (defadvice pop-tag-mark (after ctx-flash-pop-tag-mark activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'pop-tag-mark)
  (defadvice pop-tag-mark-safe (after ctx-flash-pop-tag-mark-safe activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'pop-tag-mark-safe)
  (defadvice icicle-pop-tag-mark-pnw (after ctx-flash-icicle-pop-tag-mark-pnw activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'icicle-pop-tag-mark-pnw)
  (defadvice icicle-find-first-tag (after ctx-flash-icicle-find-first-tag activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'icicle-find-first-tag)
  (defadvice icicle-pop-tag-mark (after ctx-flash-icicle-pop-tag-mark activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'icicle-pop-tag-mark)

  ;; IMenu
  (defadvice imenu-default-goto-function (after ctx-flash-imenu-default-goto-function activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'imenu-default-goto-function)

  ;; Buttons
  (defadvice push-button (after ctx-flash-push-button activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'push-button)

  ;; Org Navigation
  (defadvice org-shifttab (after ctx-flash-org-shifttab activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'org-shifttab)

  ;; Outline Navigation
  (defadvice outline-previous-heading (after ctx-flash-outline-previous-heading activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'outline-previous-heading)
  (defadvice outline-next-heading (after ctx-flash-outline-next-heading activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'outline-next-heading)
  (defadvice outline-previous-visible-heading (after ctx-flash-outline-previous-visible-heading activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'outline-previous-visible-heading)
  (defadvice outline-next-visible-heading (after ctx-flash-outline-next-visible-heading activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'outline-next-visible-heading)

  ;; Buffer/File Navigation
  (defadvice toggle-source-dwim (after ctx-flash-toggle-source-dwim activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'toggle-source-dwim)

  ;; Org Navigation
  (defadvice vc-dir-find-file (after ctx-flash-vc-dir-find-file activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'vc-dir-find-file)
  (defadvice vc-dir-find-file-other-window (after ctx-flash-vc-dir-find-file-other-window activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'vc-dir-find-file-other-window)

  ;; (defadvice ibuffer-forward-line (after ctx-flash-ibuffer-forward-line activate) (when (called-interactively-p 'any) (hictx-line)))
  ;; (defadvice ibuffer-backward-line (after ctx-flash-ibuffer-backward-line activate) (when (called-interactively-p 'any) (hictx-line)))
  ;; (defadvice ibuffer-mark-forward (after ctx-flash-ibuffer-mark-forward activate) (when (called-interactively-p 'any) (hictx-line)))

  ;; Evaluation
  (defadvice eval-last-sexp (after ctx-flash-eval-last-sexp activate) (when (called-interactively-p 'any) (hictx-sexp-bfpt nil 'hictx-eval-face hictx-eval-timeout))) (ad-activate 'eval-last-sexp)
  (defadvice pp-eval-last-sexp (after ctx-flash-pp-eval-last-sexp activate) (when (called-interactively-p 'any) (hictx-sexp-bfpt nil 'hictx-eval-face hictx-eval-timeout))) (ad-activate 'pp-eval-last-sexp)

  ;; EDebug
  (defadvice edebug-set-mode (after ctx-flash-edebug-set-mode activate) (progn (message "current-window: %s" (selected-window)) (hictx-sexp-bfpt nil 'hictx-eval-face hictx-eval-timeout))) (ad-activate 'edebug-set-mode)
  (defadvice edebug-next-mode (after ctx-flash-edebug-next-mode activate) (progn (message "current-window: %s" (selected-window)) (hictx-sexp-bfpt nil 'hictx-eval-face hictx-eval-timeout))) (ad-activate 'edebug-next-mode)

  ;; Tex/LaTeX
  (when (and (require 'rng-valid nil t)
             (fboundp 'rng-next-error))
    (defadvice rng-previous-error (after ctx-flash-rng-previous-error activate) (hictx-line nil nil hictx-new-window-timeout)) (ad-activate 'rng-previous-error)
    (defadvice rng-next-error (after ctx-flash-rng-next-error activate) (hictx-line nil nil hictx-new-window-timeout)) (ad-activate 'rng-next-error)
    )

  (defadvice makefile-previous-dependency (after ctx-flash-makefile-previous-dependency activate) (hictx-line)) (ad-activate 'makefile-previous-dependency)
  (defadvice makefile-next-dependency (after ctx-flash-makefile-next-dependency activate) (hictx-line)) (ad-activate 'makefile-next-dependency)

  ;; Indent
  (defadvice indent-for-tab-command (after ctx-flash-indent-for-tab-command activate) (hictx-generic (line-beginning-position) (point))) (ad-activate 'indent-for-tab-command)

  ;; Kill
  (defadvice kill-region (before ctx-flash-kill-region (beg end &optional yank-handler) activate)
    (when (and beg end)
      (hictx-generic (min beg end) (max beg end) nil 'hictx-kill-face hictx-kill-timeout nil nil t)))
  (ad-activate 'kill-region)
  ;; Delete
  (defadvice delete-region (before ctx-flash-delete-region (beg end &optional yank-handler) activate)
    (when (and beg end)
      (hictx-generic (min beg end) (max beg end) nil 'hictx-delete-face hictx-kill-timeout nil nil t)))
  (ad-activate 'delete-region)

  ;; Icicles
  (when nil
    (defadvice icicle-find-first-tag (after pulse-advice activate)
      "After going to a tag, pulse the line the cursor lands on."
      (when (and pulse-command-advice-flag (interactive-p))
        (pulse-momentary-highlight-one-line (point)))) (ad-deactivate 'icicle-find-first-tag)
    (defadvice icicle-pop-tag-mark (after pulse-advice activate)
      "After going to a hit, pulse the line the cursor lands on."
      (when (and pulse-command-advice-flag (interactive-p))
        (pulse-momentary-highlight-one-line (point)))) (ad-deactivate 'icicle-pop-tag-mark)
    )

  ;; (defadvice add-name-to-file (around reuse-fcache (file newname &optional ok-if-already-exists))
  ;;   ad-do-it) (ad-activate 'add-name-to-file)

  ;; Undo/Redo
  (when t
    (defadvice undo-tree-undo (after ctx-flash-undo-tree-undo activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'undo-tree-undo)
    (defadvice undo-tree-redo (after ctx-flash-undo-tree-redo activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'undo-tree-redo)))

(when t
  ;; See: http://www.gnu.org/software/emacs/manual/html_node/elisp/Undo.html
  (defun highlight-undo-before (elm)
    (when (and (consp elm))
      (let ((beg (car elm))
            (end (cdr elm)))
        (when (and (numberp beg) (numberp end)) ;(beg . end)
          (hictx-generic (min beg end) (max beg end) nil 'hictx-kill-face hictx-kill-timeout nil nil t)
          ))))
  (defun highlight-undo-after (elm)
    (cond ((numberp elm)                ;position
           (hictx-line)
           )
          ((and (consp elm))
           (let ((text (car elm)) (position (cdr elm))) ;(text . position)
             (cond ((and (stringp text)
                         (numberp position))
                    (let ((apos (abs position)))
                      (hictx-generic position (+ position (length text)))))
                   )))))
  (defadvice primitive-undo (around ctx-flash-kills-primitive-undo (n list))
    (let ((l (copy-list list)))
      (dotimes (c n)
        (highlight-undo-before (car l))
        (setq l (cdr l))))
    ad-do-it
    (let ((l (copy-list list)))
      (dotimes (c n)
        (highlight-undo-after (car l))
        (setq l (cdr l)))))
  (ad-activate 'primitive-undo)
  )

(provide 'hictx)
