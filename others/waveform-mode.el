;;; 
;-*- coding: utf-8 -*-
; http://www.emacswiki.org/emacs/WaveformMode
; waveform mode by Zhu, Shenli

;; TODO list
; make "Waveform" buffer read only
; marker in "Waveform" buffer
; 

(defconst wf_display_buffer "*Waveform*"
  "Buffer to display generated waveform.")

(defvar wf_input_buffer)

(setq wf-font-lock-defaults
      '(("^[a-zA-Z][0-9a-zA-Z_-]*\\(\\[[0-9]+:?[0-9]*\\]\\)?" . font-lock-function-name-face)
        (" [_⎺\\\/]+" . font-lock-type-face)
        ("⎼" . font-lock-variable-name-face)
        ("<\\(.*?>\\)" . (1 highlight))))

(define-derived-mode waveform-mode fundamental-mode 
  "A major mode for drawing digital circuit waveform"
  (set (make-local-variable 'comment-start) "# ")
  (make-local-variable 'wf_input_buffer)
  (setq font-lock-defaults '(wf-font-lock-defaults))
  (setq mode-name "Waveform")
  (flyspell-mode -1)
  (auto-fill-mode nil)
  ;; perl style comment: “# …” 
  (modify-syntax-entry ?# "< b" waveform-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" waveform-mode-syntax-table)
   )

;;;###autoload
(defun wf-update ()
  "update waveform to reflect outside changes to waveform source"
  (interactive)
  
  (assert (eq major-mode 'waveform-mode))
  (setq wf_input_buffer (current-buffer)) ; don't work?
  (let ((wf_input_buffer1 (current-buffer)))
    (when (one-window-p) (split-window))
    (set-buffer (get-buffer-create wf_display_buffer))
    (waveform-mode)
    (barf-if-buffer-read-only)
    (erase-buffer)
    (insert-buffer-substring wf_input_buffer1)
    (wf-translate-buf wf_display_buffer)
    (setq buffer-read-only t) ; don't work
    ;(next-window) ; don't work
    ))  

(defun wf-translate-buf (buf)
  "translate waveform string, normally one per line"
  (progn
    (pop-to-buffer buf)
    (beginning-of-buffer)
    (while
        (re-search-forward "\$\\([0-9]+\\)\\([hmlrs]\\)")
      (setq times (string-to-number (match-string 1)))
      (setq char (match-string 2))
      (if (string= char "r")
          (let ((r_begin (match-beginning 0))
                (r_end (match-end 0)))
            (progn
             (re-search-backward " ")
             (goto-char r_end)
             (dotimes (i (- times 1))
               (insert-buffer-substring (current-buffer)
                                        (+ (match-beginning 0) 1) r_begin))
             (delete-region r_begin r_end)
             ))
        (progn
          (wf-insert char times) ; insert replace
          (delete-region (match-beginning 0) (match-end 0)))))))

(defun wf-insert (char times)
  "char is h,m,l"
  (if (string= char "l") 
      (dotimes (i times) (insert "_"))
    (if (string= char "s")
        (dotimes (i times) (insert " "))
      (progn  
        (setq ucode (cond ((string= char "h") "23BA")
                          ((string= char "m") "23BC")))
        (ucs-insert ucode times)))))
     
(provide 'waveform-mode)
