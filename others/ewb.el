;;; ewb.el --- Emacs Web Browser

;; Copyright (C) 2002  Free Software Foundation, Inc.

;; Author: Patrick Anderson <patware around freeshell.org>
;; Keywords: hypermedia, browser, web, net

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;;; Installation:
;;   Add these lines to your .emacs
;; (autoload 'ewb "ewb" "emacs web browser" t)
;; (autoload 'ewb-local "ewb" "emacs web browser" t)

;;; Commentary:
;;   Try  M-x ewb  or  M-x ewb-local
;;   type C-h m for keystroke help

;;; Todo:
;;   Use interpreter-minor
;;   Use xml.el to make state parser.
;;   Display bold, italics, etc.
;;   Turn <frame> into link
;;   Handle encodings [gzip, deflate, compress, etc.]
;;   Handle ssl. I don't know how to use ssl yet. does tramp have ssl client code?
;;   Handle form data (RFC 2616)
;;   <style>.*?</style>, <script>.*?</script>


;;; Current:
;;   -.05
;;   fixed font-lock errors
;;   local files should work (use `ewb-local')

;;; Changes:
;;   -.09 --
;;   Much more responsive because i'm using the idea from
;;   http://emacswiki.org/cgi-bin/wiki.pl?PrettyLambda to piggy-back
;;   onto font-lock.
;;   Can now view local files, but cannot follow local links
;;   killing stale ewb-connection when entering ewb-get.

;;   -.1a -- Fixed dangerous sentinel code (when ewb-connection finally exits, the formatting was being applied to whichever buffer had focus.)
;;   -.1 --- Sending a more complete request - sourceforge.net works, but replies with gzipped content.  patware.freeshell.org works but ewb-connection hangs.  now using HTTP/1.1
;;   -.2a -- Removed referer string.
;;   -.2 --- Sending referer. Changed version numbering. ewb-href now accepts <a name=>. need to move to state-machine parser.
;;   -.3 --- Prefix arg or file extensions suppress formatting. write bookmarks to file, customizeable
;;   -.4 --- added ewb-revert [(g)], minibuffer state messages, display ewb-url above header, mouse-face, help-echo
;;   -.5 --- first alpha.

;; Installation:
;;   (autoload 'ewb "ewb" "emacs web browser" t) ;put in your .emacs
;;   type M-x eval-buffer RET then M-x ewb RET to try it now
;;   M-x customize-variable RET browse-url-browser-function to make ewb your default browser.

;;; Customizations:
(defgroup ewb nil "Emacs Web Browser"
  :group 'hypermedia)

(defcustom ewb-suppressed-extensions 
  "\.el$\\|\.txt$"
  "Don't parse these extensions."
  :group 'ewb)

(defcustom ewb-bookmark-file
  "~/.ewb/bookmarks"
  "Bookmark file"
  :group 'ewb)

(defcustom ewb-history-file
  "~/.ewb/history"
  "History file"
  :group 'ewb)

(defcustom ewb-invisible-markup
  t
  "Make markup invisible?"
  :type 'boolean
  :group 'ewb)

(defcustom ewb-markup-font
  'file-name-shadow
  "Font for markup if `ewb-invisible-markup' is not set."
  :type 'face
  :group 'ewb)


;; Code:
(defun ewb (url &optional prefix)
  "Emacs Web Browser.
\\{ewb-mode-map}"
  (interactive "sURL: ")
  (ewb-parse-url url nil))

(defun ewb-local (file)
  "Start `ewb' on a local file."
  (interactive "fFile: ")
  (ewb-parse-url (concat "file://" "/" (file-relative-name file "/")) nil))

(defvar ewb-mode-map (make-sparse-keymap))

(define-key ewb-mode-map [(C)]
  (lambda (dir)
	(interactive "DDownload to: ")
	(cd dir)
	(start-process "wget" "*wget*" "wget" "-nv"
				   (message (progn
							  (re-search-backward ewb-href)
							  (match-string 1))))))

(define-key ewb-mode-map [(b)] 'ewb-bookmarks)
(defun ewb-bookmarks ()
  (interactive)
  (find-file ewb-bookmark-file))
(defun ewb-bookmark-add ()
  (interactive)
  (message (concat ewb-url "\nAdded to " ewb-bookmark-file))
  (write-region (concat ewb-url "\n") nil ewb-bookmark-file t))
(define-key ewb-mode-map [(B)] 'ewb-bookmark-add)

(define-key ewb-mode-map [(o)] 'ewb)
(define-key ewb-mode-map [(g)] 'ewb-revert)
(defun ewb-revert ()
  (interactive)
  (ewb ewb-url)
  (setq ewb-history (cdr ewb-history)))

(define-key ewb-mode-map [(9)] 'ewb-next)
(defun ewb-next ()
  "jump to next link"
  (interactive)
  (re-search-forward ewb-href)
  (message (match-string 1)))

(define-key ewb-mode-map [(shift 9)] 'ewb-prev)
(defun ewb-prev ()
  "jump to prev link"
  (interactive)
  (re-search-backward ewb-href)
  (message (match-string 1)))

(define-key ewb-mode-map [(13)] 'ewb-follow)
(defun ewb-follow ()
  "follow this link"
  (interactive)
  (re-search-backward ewb-href)
  (ewb-parse-url (replace-regexp-in-string "%20" " " (match-string 1)) t))

(define-key ewb-mode-map [(mouse-2)] 'ewb-follow-mouse)
(defun ewb-follow-mouse (event &optional univ)
  (interactive "e\nP")
  (goto-char (posn-point (event-end event)))
  (ewb-follow))

(define-key ewb-mode-map [(s)] 'ewb-search)
(defun ewb-search (str)
  "use google"
  (interactive "sFor: ")
  (ewb (concat "www.google.com/search?q=" (dired-replace-in-string " " "+" str))))

(define-key ewb-mode-map [(q)] 'bury-buffer)
(define-key ewb-mode-map " " 'scroll-up)
(define-key ewb-mode-map [(u)] 'scroll-down)
(define-key ewb-mode-map [(h)] (lambda () (interactive) (mapcar 'print ewb-history)))

(define-key ewb-mode-map [(meta left)] 'ewb-back)
(define-key ewb-mode-map [(backspace)] 'ewb-back)
(defun ewb-back ()
  "go back in history"
  (interactive)
  (if ewb-history
	  (progn
		(setq ewb-history (cdr ewb-history))
		(let ((cur (car ewb-history)))
		  (setq ewb-history (cdr ewb-history)) ;remove self, since ewb-get adds
		  (ewb cur)))))

;;(defvar ewb-href "<a[^>]*?\\(?:href\\|name\\)=\"?\\([^\">]+\\)[^>]*?>")
(defvar ewb-href "<a.*?\\(?:href\\|name\\)=\"?\\([^\">]+\\).*?>")
(defvar ewb-history nil)
(defvar ewb-host nil)
(defvar ewb-proto nil)
(defvar ewb-dir nil)
(defvar ewb-url nil)
(defvar ewb-connection nil)

(defun ewb-mode ()
  "emacs web browser mode. \\{ewb-mode-map}"
  (interactive)
  (kill-all-local-variables)
										;  (setq buffer-read-only t)
  (use-local-map ewb-mode-map)
  (setq mode-name "ewb")
  (setq major-mode 'ewb-mode)
  (add-to-invisibility-spec 'ewb)
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(ewb-font-lock-keywords t t nil nil)) ; nil nil ((?_ . "w")))))
  (run-hooks 'ewb-mode-hook))

(defconst ewb-font-lock-keywords
  (eval-when-compile
    (list
  	 `("\\(<br/?>\\|<p/?>\\|<hr/?>\\|</h[1-9]>\\|</li>\\|</title>\\)[^\n]"
   	   (1
		(progn
		  (backward-char)
		  (insert "\n")
		  ewb-markup-font)))

  	 `("<img .*?src=\"\\(.*?\\)\".*?>"
   	   (0
		(progn
;; 		  (if ewb-invisible-markup
;; 			  (insert (match-string 1)))
		  ewb-markup-font)))

	 ;; 	 `(,(concat ewb-href "\\([^<]*?\\)" "</a>")
 	 `(,(concat ewb-href "\\(.*?\\)</a>")
  	   (2 (progn
  			(let (( overlay (make-overlay (match-beginning 2) (match-end 2))))
  			  (overlay-put overlay 'mouse-face 'highlight)
  			  (overlay-put overlay 'help-echo (match-string 1)))
			font-lock-keyword-face)))

 	 `("&nbsp;[^ ]"
  	   (0
		(progn
		  (backward-char)
		  (insert " ")
		  font-lock-string-face)))

 	 `("&quot;[^\"]"
  	   (0
		(progn
		  (backward-char)
		  (insert "\"")
		  font-lock-string-face)))

 	 `("<.*?>\\|&....;"
  	   (0 (progn
			(if ewb-invisible-markup
				(let ((overlay (make-overlay (match-beginning 0) (match-end 0))))
				  (overlay-put overlay 'invisible 'ewb)
				  (overlay-put overlay 'intangible 'ewb)))
			ewb-markup-font)))

	 (cons (regexp-opt
			'("HTTP/1.1" "Date:" "Server:" "Keep-Alive:" "Connection:" "Transfer-Encoding:" "Content-Type:")
			'words)
		   'font-lock-builtin-face)
	 )))

(defun ewb-parse-url (url followed)
  " A 'followed' link has a looser file spec, tighter host spec:
A host must begin with (http:)?//
A link such as \"a.b\" specifies file or directory.

An 'interactive' url has a tighter 'file' spec, looser host spec:
A host might not begin with (http:)?//
A link such as \"a.b\" specifies a host."
  (if followed
	  ;;            1=proto?,      2=//host?       3=/?,       4=dir/*             5=file?
	  (string-match "\\(http:\\)?\\(//[^/\n]+\\)?\\(/\\)?\\(\\(?:[^/\n]+/\\)*\\)\\(.*\\)" url)
	;;            1=proto//?,      2=host       3=/?,   4=dir/*                5=file?
	(string-match "\\(http://\\|file://\\)?\\([^/\n]+\\)?\\(/\\)?\\(\\(?:[^/\n]+/\\)*\\)\\(.*\\)" url))

  (let* ((proto (match-string 1 url))
		 (host (match-string 2 url))
		 (dir (match-string 4 url))
		 (file (match-string 5 url))
		 (local (or (string-equal "file://" proto)
					(and (not host) (not ewb-host))))
		 (buf (get-buffer-create "*Emacs Web Browser*")))

	(if proto
		(setq ewb-proto proto))

	(if local
		(setq ewb-host nil)
	  (setq ewb-proto "http://"))

	(if host
		(progn
		  (string-match "\\(//\\)?\\(.*\\)" host)
		  (setq host (match-string 2 host)) ;;strip leading // if present
		  (setq ewb-host host)
		  (setq ewb-dir dir))) ;force this (generally to clear)
	(if dir
		(if (not (= 0 (length dir)))
			(setq ewb-dir dir)))

	(setq ewb-url (concat ewb-proto ewb-host "/" ewb-dir file))
	(write-region (concat ewb-url "\n") nil ewb-history-file t)
	(setq ewb-history (cons ewb-url ewb-history))
	(switch-to-buffer buf)
	(erase-buffer)
	(insert (concat ewb-url "\n"))
	(overlay-put (make-overlay 1 (+ (length ewb-url) 1)) 'face 'font-lock-constant-face)

	(if local
		(insert-file-contents (concat "/" ewb-dir file))
	  (ewb-get ewb-proto ewb-host ewb-dir file buf))

	(ewb-mode)))

(defun ewb-get (proto host dir file buf)
  "get over http"
  (message (concat "downloading " ewb-url "..."))

  (if ewb-connection
	  (progn
		(delete-process ewb-connection)
		(setq ewb-connection nil)))

  (setq ewb-connection (open-network-stream "ewb-connection" buf host 80))
  (process-send-string
   ewb-connection
   (concat
	"GET /"
	(replace-regexp-in-string " " "%20" (concat dir file))
	" HTTP/1.1\r\n"
	"Host: " host "\r\n"
	"User-Agent: Emacs Web Browser\r\n"
	"Accept: */*\r\n"
	"Accept-Language: *\r\n"
	"Accept-Encoding: gzip, deflate, compress\r\n"
	"Accept-Charset: ISO-8859-1, utf-8\r\n"
	"Keep-Alive: 300\r\n"
	"Connection: keep-alive\r\n"
	"\r\n")))


(provide 'ewb)
;;; ewb.el ends here
