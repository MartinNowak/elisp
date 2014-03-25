;;; wthreem-type-ahead.el --- type ahead support for Emacs-w3m

;;; Copyright (C) 2003, 2004 Matthew P. Hodges

;; Author: Matthew P. Hodges <MPHodges@member.fsf.org>
;; Version: $Id: wthreem-type-ahead.el,v 1.73 2004/10/14 16:14:44 matt Exp $

;; wthreem-type-ahead.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; wthreem-type-ahead.el is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied warranty
;; of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;;; Commentary:
;; 
;; Type ahead support for Emacs-w3m. This allows an isearch facility
;; that is limited to HREF anchors. Switch the minor mode on for all
;; w3m-mode buffers with:
;;     (add-hook 'w3m-mode-hook 'w3m-type-ahead-minor-mode)

;;; Code:

;; Customisable variables

(defgroup w3m-type-ahead nil
  "Type ahead support for Emacs-w3m."
  :group 'w3m
  :link '(url-link "http://www.tc.bham.ac.uk/~matt/published/Public/WthreemTypeAheadEl.html"))

(defcustom w3m-type-ahead-reload t
  "Argument passed to `w3m-view-this-url' by `w3m-type-ahead'.
If non-nil, the URL will be reloaded."
  :group 'w3m-type-ahead
  :type 'boolean)

(defcustom w3m-type-ahead-preserve-point-on-failure t
  "If non-nil, preserve `point' for failed searches."
  :group 'w3m-type-ahead
  :type 'boolean)

;; Faces

(defface w3m-type-ahead-overlay-face
  '((((class color))
     (:inherit isearch)))
  "Face used for type-ahead overlays in `w3m' buffer."
  :group 'w3m-type-ahead)

;; The above doesn't work for Emacs 20/XEmacs

(when (or (eq emacs-major-version 20)
	  (featurep 'xemacs))
  (set-face-foreground 'w3m-type-ahead-overlay-face "cyan1")
  (set-face-background 'w3m-type-ahead-overlay-face "magenta4"))

;; Other variables

(defvar w3m-type-ahead-anchors (make-hash-table)
  "Hash table containing type-ahead anchors data.")

(defvar w3m-type-ahead-isearch-mode-map
  (let ((map (copy-keymap isearch-mode-map)))
    ;; Don't need this for Emacs 20 or XEmacs 21.4
    (when (and (> emacs-major-version 20)
               (not (featurep 'xemacs)))
      ;; Redefine isearch-edit-string binding
      (define-key map "\M-e" 'isearch-exit)
      ;; And on escape keymap
      (define-key (cdr (assoc 'escape map)) "e" 'isearch-exit))
    map)
  "Local mode map for command `w3m-type-ahead-minor-mode'.
Like `isearch-mode-map' but with bindings that are difficult to
deal with removed.")

(defvar w3m-type-ahead-overlays nil
  "Current type-ahead overlays.")

(defvar w3m-type-ahead-parent-buffer nil
  "Parent `w3m' buffer.")

(defvar w3m-type-ahead-point nil
  "Saved value of `point' in parent `w3m' buffer.")

(defvar w3m-type-ahead-window nil
  "Saved window displaying `w3m' buffer.")

(defvar w3m-type-ahead-window-start nil
  "Saved value of `window-start' in parent `w3m' buffer.")

;; Other configuration

(cond
 ((fboundp 'puthash)
  (defalias 'w3m-type-ahead-puthash 'puthash))
 (t
  (require 'cl)
  (defalias 'w3m-type-ahead-puthash 'cl-puthash)
  t))

(cond
 ;; Emacs 21
 ((fboundp 'replace-regexp-in-string)
  (defalias 'w3m-type-ahead-replace-regexp-in-string 'replace-regexp-in-string))
 ;; Emacs 20
 ((and (require 'dired)
       (fboundp 'dired-replace-in-string))
  (defalias 'w3m-type-ahead-replace-regexp-in-string 'dired-replace-in-string))
 ;; XEmacs
 ((fboundp 'replace-in-string)
  (defun w3m-type-ahead-replace-regexp-in-string (regexp rep string)
    (replace-in-string string regexp rep)))
 ;; Bail out
 (t
  (error "No replace in string function found")))

;; Entry points

(defun w3m-type-ahead (regexp)
  "Type-Ahead functionality for Emacs-w3m.
Incremental searching of anchors in the current buffer. With non-nil
REGEXP, do regular expression search."
  (interactive "P")
  (w3m-type-ahead-internal regexp nil))

(defun w3m-type-ahead-new-session (regexp)
  "Type-Ahead functionality for Emacs-w3m; creates new `w3m' session.
Incremental searching of anchors in the current buffer. With
non-nil REGEXP, do regular expression search."
  (interactive "P")
  (w3m-type-ahead-internal regexp t))

;; Internal functions

(defun w3m-type-ahead-internal (regexp new-session)
  "Internal `w3m-type-ahead' function.
If non-nil REGEXP, do regular expression search; if non-nil
NEW-SESSION, create new `w3m' session."
  (let ((w3m-buffer-list ; list of w3m buffers sans type-ahead one
         (delq (get-buffer " *w3m-type-ahead*") (w3m-list-buffers)))
        first-anchor selected)
    (cond
     ((not (equal major-mode 'w3m-mode))
      (message "Can't type ahead in non-W3M buffer."))
     (w3m-current-process
      (message "Can't type ahead while W3M is retrieving."))
     ((< (- (point-max) (point-min)) (buffer-size))
      ;; This is difficult to implement because of subtle differences
      ;; in text-property behaviour in various emacsen; probably not
      ;; worth doing.
      (message "Can't type ahead in narrowed W3M buffer."))
     ((not (next-single-property-change (point-min)
                                        'w3m-anchor-sequence))
      (message "Can't type ahead; no anchors found in buffer."))
     (t
      (setq first-anchor
            (or (get-text-property (point) 'w3m-anchor-sequence)
                (get-text-property
                 (or (next-single-property-change (point)
                                                  'w3m-anchor-sequence)
                     (next-single-property-change (point-min)
                                                  'w3m-anchor-sequence))
                 'w3m-anchor-sequence)))
      ;; Save window parameters
      (setq w3m-type-ahead-parent-buffer (current-buffer)
            w3m-type-ahead-window (selected-window)
            ;; In case we cancel the search immediately
            w3m-type-ahead-point (point)
            w3m-type-ahead-window-start
            (window-start w3m-type-ahead-window))
      ;; Update hash table containing anchors
      (w3m-type-ahead-get-anchors)
      ;; The flet statement is needed since we put the
      ;; *w3m-type-ahead* buffer into w3m-mode. This is needed to
      ;; preserve the toolbar in GNU Emacs 21, but we don't want the
      ;; tab line (actually the header-line) to include this buffer
      ;; (see w3m-tab-line).
      (flet ((w3m-list-buffers (&optional ignore)
                               w3m-buffer-list))
        ;; Create the buffer containing the links
        (w3m-type-ahead-setup-buffer)
        ;; Search in this buffer
        (save-window-excursion
          (set-window-buffer (minibuffer-window) " *w3m-type-ahead*")
          (select-window (minibuffer-window))
          (goto-char (text-property-any (point-min) (point-max)
                                        'anchor first-anchor))
          (let ((post-command-hook 'w3m-type-ahead-update-overlay)
                (isearch-mode-map w3m-type-ahead-isearch-mode-map)
                ;; Changing to non-incremental search changes minibuffer
                ;; window -- don't allow this.
                (search-nonincremental-instead nil))
            (when (integerp
                   (if regexp
                       (isearch-forward-regexp)
                     (isearch-forward)))
              (setq selected (w3m-type-ahead-get-anchor-at-point)))))
        ;; Back in parent *w3m* buffer
        ;; Clear out any old overlays
        (mapc #'delete-overlay w3m-type-ahead-overlays)
        (setq w3m-type-ahead-overlays nil)
        (kill-buffer " *w3m-type-ahead*"))
      ;; Discard any input
      (setq unread-command-events nil)
      ;; Find selected anchor
      (if selected
          (progn (goto-char (text-property-any (point-min) (point-max)
                                               'w3m-anchor-sequence selected))
                 (w3m-view-this-url w3m-type-ahead-reload new-session))
        ;; Restore point if we're not following a link and want this
        (when w3m-type-ahead-preserve-point-on-failure
          (set-window-point w3m-type-ahead-window w3m-type-ahead-point)
          (set-window-start w3m-type-ahead-window
                            w3m-type-ahead-window-start)))))))

(defun w3m-type-ahead-get-anchors ()
  "Get anchors from current W3M buffer.
Store them in `w3m-type-ahead-anchors'."
  (clrhash w3m-type-ahead-anchors)
  (save-excursion
    (goto-char (point-min))
    (let (anchor end start string value)
      (while (setq start
                   ;; If there are two adjacent anchors, we may
                   ;; already be in the right place
                   (if (get-text-property (point) 'w3m-anchor-sequence)
                       (point)
                     (next-single-property-change (point)
                                                  'w3m-anchor-sequence)))
        (goto-char start)
        (setq anchor (get-text-property (point) 'w3m-anchor-sequence)
              end (next-single-property-change (point) 'w3m-anchor-sequence)
              string (buffer-substring-no-properties start end))

        ;; Don't clobber pure whitespace strings
        (unless (string-match "^\\s-+$" string)
          (setq string (w3m-type-ahead-replace-regexp-in-string
                        "\\s-+$" "" string)))
        (setq value (car (gethash anchor w3m-type-ahead-anchors)))
        (when value
          (setq string (concat value " " string)))
        (let ((list (list string anchor)))
          (w3m-type-ahead-puthash anchor list w3m-type-ahead-anchors))
        (goto-char end)))))

(defun w3m-type-ahead-setup-buffer ()
  "Set up \" *w3m-type-ahead*\" buffer."
  (let ((buffer (get-buffer-create " *w3m-type-ahead*"))
        keys
        ;; Local emacs-w3m variables
        (url w3m-current-url)
        (history w3m-history))
    ;; Get a sorted list of the keys
    (maphash (lambda (key value) (setq keys (nconc keys (list key))))
             w3m-type-ahead-anchors)
    (setq keys (sort keys '<))
    ;; Insert the entries
    (save-excursion
      (set-buffer buffer)
      ;; We put the type-ahead buffer in w3m-mode to keep the tool bar
      ;; unchanged in GNU Emacs 21, and the buffer tabs unchanged in
      ;; XEmacs. Note that for the latter, we use an invisible buffer
      ;; name so that a tab isn't shown; the tabs are constructed for
      ;; buffers in the same major mode.
      (w3m-mode)
      (setq w3m-current-url url)        ; for reload icon
      (setq w3m-history history)       ; for back icon
      (erase-buffer)
      (mapcar 'w3m-type-ahead-insert-entry keys))))

(defun w3m-type-ahead-insert-entry (key)
  "Insert entry for given KEY.
The keys and values are stored in `w3m-type-ahead-anchors'."
  (let ((value (gethash key w3m-type-ahead-anchors))
        anchor start string)
    (setq string (car value)
          anchor (cadr value))
    (setq start (point))
    (insert string)
    (add-text-properties start (point) `(anchor ,anchor))
    (insert "\n")))

(defun w3m-type-ahead-update-overlay ()
  "Update overlay for current anchor in `w3m' buffer."
  (let ((anchor (w3m-type-ahead-get-anchor-at-point))
        end overlay posn)
    ;; Clear out any old overlays
    (mapc #'delete-overlay w3m-type-ahead-overlays)
    (setq w3m-type-ahead-overlays nil)
    (when anchor
      (set-buffer w3m-type-ahead-parent-buffer)
      (unless (or (string-equal isearch-string "") (null isearch-success))
        (save-excursion
          (goto-char (point-min))
          (while (setq posn (text-property-any (point) (point-max)
                                               'w3m-anchor-sequence anchor))
            (goto-char posn)
            (setq end (next-single-property-change (point)
                                                   'w3m-anchor-sequence))
            (setq overlay (make-overlay (point) end))
            (overlay-put overlay 'face 'w3m-type-ahead-overlay-face)
            (setq w3m-type-ahead-overlays
                  (append w3m-type-ahead-overlays (list overlay)))
	    (goto-char end))
          ;; Make sure this is visible
          (set-window-point w3m-type-ahead-window
                            (overlay-start (car w3m-type-ahead-overlays)))
          ;; Save state
          (when w3m-type-ahead-preserve-point-on-failure
            (sit-for 0)                 ; for correct window-start?
            (setq w3m-type-ahead-point (point)
                  w3m-type-ahead-window-start
                  (window-start w3m-type-ahead-window))))))))

(defun w3m-type-ahead-get-anchor-at-point ()
  "Get anchor corresponding to point."
  (let (anchor)
    (save-excursion
      ;; With isearch-abort, we could end up in *w3m* buffer? Only
      ;; when debugging?
      (set-buffer " *w3m-type-ahead*")
      ;; We could be in the right place already
      (or (get-text-property (point) 'anchor)
          (goto-char
           (or (previous-single-property-change (point) 'anchor)
               (point-min))))
      ;; We could still be one character after the property
      (setq anchor
            (or (get-text-property (point) 'anchor)
                (get-text-property (1- (point)) 'anchor))))
    anchor))

;; Minor mode settings

(defvar w3m-type-ahead-minor-mode nil
  "Non-nil if using function `w3m-type-ahead-minor-mode'.
Use the command `w3m-type-ahead-minor-mode' to toggle or set this
variable.")
(make-variable-buffer-local 'w3m-type-ahead-minor-mode)

(defvar w3m-type-ahead-minor-mode-map
  (let ((map (make-sparse-keymap)))
     (define-key map (kbd "/") 'w3m-type-ahead)
     (define-key map (kbd "M-/") 'w3m-type-ahead-new-session)
    map)
  "Keymap for `w3m-type-ahead' minor mode.")

(unless (assq 'w3m-type-ahead-minor-mode minor-mode-alist)
  (setq minor-mode-alist
        (cons '(w3m-type-ahead-minor-mode " wta") minor-mode-alist)))

(unless (assq 'w3m-type-ahead-minor-mode minor-mode-map-alist)
  (setq minor-mode-map-alist
        (cons (cons 'w3m-type-ahead-minor-mode w3m-type-ahead-minor-mode-map)
              minor-mode-map-alist)))

;;;###autoload
(defun w3m-type-ahead-minor-mode (&optional arg)
  "Toggle `w3m-type-ahead' minor mode.
With ARG, turn `w3m-type-ahead' minor mode on if ARG is positive,
off otherwise.

\\{w3m-type-ahead-minor-mode-map}"
  (interactive "P")
  (setq w3m-type-ahead-minor-mode (if (null arg)
                                      (not w3m-type-ahead-minor-mode)
                                    (> (prefix-numeric-value arg) 0))))

(provide 'w3m-type-ahead)

;;; wthreem-type-ahead.el ends here
