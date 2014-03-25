;;; oddmuse-curl.el -- edit pages on an Oddmuse wiki using curl
;; $Id: oddmuse-curl.el,v 1.5 2012/01/23 16:30:46 alex Exp $

;; Copyright (C) 2006, 2009, 2011  Alex Schroeder <alex@gnu.org>
;;           (C) 2007  rubikitch <rubikitch@ruby-lang.org>

;; Latest version:
;;   http://www.emacswiki.org/cgi-bin/wiki/download/oddmuse-curl.el
;;   (oddmuse-edit "EmacsWiki" "oddmuse-curl.el")
;;   or save using (emacswiki-post "oddmuse-curl.el")
;; Discussion, feedback:
;;   http://www.emacswiki.org/cgi-bin/wiki/OddmuseMode

;; This program is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A simple mode to edit pages on Oddmuse wikis using Emacs and the command-line
;; HTTP client `curl'.

;; Since text formatting rules depend on the wiki you're writing for, the
;; font-locking can only be an approximation.

;; Put this file in a directory on your `load-path' and 
;; add this to your init file:
;; (require 'oddmuse)
;; (oddmuse-mode-initialize)
;; And then use M-x oddmuse-edit to start editing.

;;; Code:

(eval-when-compile
  (require 'cl)
  (require 'sgml-mode)
  (require 'skeleton))

(defcustom oddmuse-directory "~/emacs/oddmuse"
  "Directory to store oddmuse pages."
  :type '(string)
  :group 'oddmuse)

(defcustom oddmuse-wikis
  '(("TestWiki" "http://www.emacswiki.org/cgi-bin/test" utf-8 "question" nil)
    ("EmacsWiki" "http://www.emacswiki.org/cgi-bin/emacs" utf-8 "uihnscuskc" nil)
    ("CommunityWiki" "http://www.communitywiki.org/cw" utf-8 "question" nil)
    ("OddmuseWiki" "http://www.oddmuse.org/cgi-bin/oddmuse" utf-8 "question" nil)
    ("CampaignWiki" "http://www.campaignwiki.org/wiki/NameOfYourWiki" utf-8 "ts" nil))
  "Alist mapping wiki names to URLs.
The username is optional and defaults to `oddmuse-username'."
  :type '(repeat (list (string :tag "Wiki")
                       (string :tag "URL")
                       (choice :tag "Coding System"
			       (const :tag "default" utf-8)
			       (symbol :tag "specify"
				       :validate (lambda (widget)
						   (unless (coding-system-p
							    (widget-value widget))
						     (widget-put widget :error
								 "Not a valid coding system")))))
		       (choice :tag "Secret"
			       (const :tag "default" "question")
			       (string :tag "specify"))
		       (choice  :tag "Username"
				(const :tag "default" nil)
				(string :tag "specify"))))
  :group 'oddmuse)

(defcustom oddmuse-username user-full-name
  "Username to use when posting.
Setting a username is the polite thing to do."
  :type '(string)
  :group 'oddmuse)

(defcustom oddmuse-password ""
  "Password to use when posting.
You only need this if you want to edit locked pages and you
know an administrator password."
  :type '(string)
  :group 'oddmuse)

(defcustom oddmuse-use-always-minor nil
  "When t, set all the minor mode bit to all editions.
This can be changed for each edition using `oddmuse-toggle-minor'."
 :type '(boolean)
 :group 'oddmuse)

(defvar oddmuse-get-command
  "curl --silent %w\"?action=browse;raw=2;\"id=%t"
  "Command to use for publishing pages.
It must print the page to stdout.

%?  '?' character
%w  URL of the wiki as provided by `oddmuse-wikis'
%t  URL encoded pagename, eg. HowTo, How_To, or How%20To")

(defvar oddmuse-rc-command
  "curl --silent %w\"?action=rc&raw=1\""
  "Command to use for Recent Changes.
It must print the RSS 3.0 text format to stdout.

%?  '?' character
%w  URL of the wiki as provided by `oddmuse-wikis'")

(defvar oddmuse-post-command
  (concat "curl --silent --write-out '%{http_code}'"
          " --form title=%t"
          " --form summary=%s"
          " --form username=%u"
          " --form password=%p"
	  " --form %q=1"
          " --form recent_edit=%m"
	  " --form oldtime=%o"
          " --form text=\"<-\""
          " %w")
  "Command to use for publishing pages.
It must accept the page on stdin.

%?  '?' character
%t  pagename
%s  summary
%u  username
%p  password
%q  question-asker cookie
%m  minor edit
%o  oldtime, a timestamp provided by Oddmuse
%w  URL of the wiki as provided by `oddmuse-wikis'")

(defvar oddmuse-link-pattern
  "\\<[A-Z\xc0-\xde]+[a-z\xdf-\xff]+\\([A-Z\xc0-\xde]+[a-z\xdf-\xff]*\\)+\\>"
  "The pattern used for finding WikiName.")

(defvar oddmuse-wiki nil
  "The current wiki.
Must match a key from `oddmuse-wikis'.")

(defvar oddmuse-page-name nil
  "Pagename of the current buffer.")

(defvar oddmuse-pages-hash (make-hash-table :test 'equal)
  "The wiki-name / pages pairs.")

(defvar oddmuse-index-get-command
  "curl --silent %w\"?action=index;raw=1\""
  "Command to use for publishing index pages.
It must print the page to stdout.

%?  '?' character
%w  URL of the wiki as provided by `oddmuse-wikis'
")

(defvar oddmuse-minor nil
  "Is this edit a minor change?")

(defvar oddmuse-revision nil
  "The ancestor of the current page.
This is used by Oddmuse to merge changes.")

(defun oddmuse-mode-initialize ()
  (add-to-list 'auto-mode-alist
               `(,(expand-file-name oddmuse-directory) . oddmuse-mode)))

(defun oddmuse-creole-markup ()
  "Implement markup rules for the Creole markup extension."
  (font-lock-add-keywords
   nil
  '(("^=[^=\n]+" . 'info-title-1); = h1
    ("^==[^=\n]+" . 'info-title-2); == h2
    ("^===[^=\n]+" . 'info-title-3); === h3
    ("^====+[^=\n]+" . 'info-title-4); ====h4
    ("\\_<//\\(.*\n\\)*?.*?//" . 'italic); //italic//
    ("\\*\\*\\(.*\n\\)*?.*?\\*\\*" . 'bold); **bold**
    ("__\\(.*\n\\)*?.*?__" . 'underline); __underline__
    ("|+=?" . font-lock-string-face)
    ("\\\\\\\\[ \t]+" . font-lock-warning-face)
    ("^#+ " . font-lock-constant-face)
    ("^- " . font-lock-constant-face))))

(defun oddmuse-bbcode-markup ()
  "Implement markup rules for the bbcode markup extension."
  (font-lock-add-keywords
   nil
  '(("\\[u\\]\\(.*\n\\)*?.*?\\[/u\\]" . 'underline)
    ("\\[s\\(trike\\)?\\]\\(.*\n\\)*?.*?\\[/s\\(trike\\)?\\]" . 'strike)
    ("\\[u\\]\\(.*\n\\)*?.*?\\[/u\\]" . 'underline)
    ("\\[b\\]\\(.*\n\\)*?.*?\\[/b\\]" . 'bold)
    ("\\[i\\]\\(.*\n\\)*?.*?\\[/i\\]" . 'italic))))

(defun oddmuse-usemod-markup ()
  "Implement markup rules for the Usemod markup extension."
  (font-lock-add-keywords
   nil
  '(("^=[^=\n]+=$" . 'info-title-1); = h1 =
    ("^==[^=\n]+==$" . 'info-title-2); == h2 ==
    ("^===[^=\n]+===$" . 'info-title-3); === h3 ===
    ("^====+[^=\n]+====$" . 'info-title-4); ==== h4 ====
    ("^ .+?$" . font-lock-comment-face);       code
    ("^[#]\\([#]+\\)" . font-lock-constant-face)
    ("^\\([*#]\\)[^*#]" 1 font-lock-builtin-face))))

(defun oddmuse-usemod-html-markup ()
  "Implement markup rules for the HTML option in the Usemod markup extension."
  (font-lock-add-keywords
   nil
   '(("<\\(/?[a-z]+\\)" 1 font-lock-function-name-face))); <strong
  (set (make-local-variable 'sgml-tag-alist)
       `(("b") ("code") ("em") ("i") ("strong") ("nowiki")
	 ("pre" \n) ("tt") ("u")))
  (set (make-local-variable 'skeleton-transformation) 'identity))

(defun oddmuse-extended-markup ()
  "Implement markup rules for the Markup extension."
  (font-lock-add-keywords
   nil
   '(("\\*.*?\\*" . 'bold)
     ("\\_</.*?/" . 'italic)
     ("_.*?_" . 'underline))))

(defun oddmuse-basic-markup ()
  "Implement markup rules for the basic Oddmuse setup without extensions.
This function should come come last in `oddmuse-markup-functions'
because of such basic patterns as [.*] which are very generic."
  (font-lock-add-keywords
   nil
   `((,oddmuse-link-pattern . 'link)
     ("\\[\\[.*?\\]\\]" . 'link)
     ("\\[.*\\]" . 'link)
     ("^\\([*]+\\)" . 'font-lock-constant-face)))
  (goto-address))

;; Should determine this automatically based on the version? And cache it per wiki?
;; http://emacswiki.org/wiki?action=version
(defvar oddmuse-markup-functions
  '(oddmuse-creole-markup
    oddmuse-bbcode-markup
    oddmuse-usemod-markup
    oddmuse-extended-markup
    oddmuse-basic-markup)
  "The list of functions to call when `oddmuse-mode' runs.
If you want to add your own code, use `oddmuse-mode-hook'.")

(define-derived-mode oddmuse-mode text-mode "Odd"
  "Simple mode to edit wiki pages.

Use \\[oddmuse-follow] to follow links. With prefix, allows you
to specify the target page yourself.

Use \\[oddmuse-post] to post changes. With prefix, allows you to
post the page to a different wiki.

Use \\[oddmuse-edit] to edit a different page. With prefix,
forces a reload of the page instead of just popping to the buffer
if you are already editing the page.

Customize `oddmuse-wikis' to add more wikis to the list.

Font-locking is controlled by `oddmuse-markup-functions'.

\\{oddmuse-mode-map}"
  (mapc 'funcall oddmuse-markup-functions)
  (font-lock-mode 1)
  (when buffer-file-name
    (set (make-local-variable 'oddmuse-wiki)
	 (file-name-nondirectory
	  (substring (file-name-directory buffer-file-name) 0 -1)))
    (set (make-local-variable 'oddmuse-page-name)
	 (file-name-nondirectory buffer-file-name)))
  (set (make-local-variable 'oddmuse-minor)
       oddmuse-use-always-minor)
  (set (make-local-variable 'oddmuse-revision)
       (save-excursion
	 (goto-char (point-min))
	 (if (looking-at
	      "\\([0-9]+\\) # Do not delete this line when editing!\n")
	     (prog1 (match-string 1)
	       (replace-match "")
	       (set-buffer-modified-p nil)))))
  (setq indent-tabs-mode nil))

(autoload 'sgml-tag "sgml-mode" t)

(define-key oddmuse-mode-map (kbd "C-c C-t") 'sgml-tag)
(define-key oddmuse-mode-map (kbd "C-c C-o") 'oddmuse-follow)
(define-key oddmuse-mode-map (kbd "C-c C-m") 'oddmuse-toggle-minor)
(define-key oddmuse-mode-map (kbd "C-c C-c") 'oddmuse-post)
(define-key oddmuse-mode-map (kbd "C-x C-v") 'oddmuse-revert)
(define-key oddmuse-mode-map (kbd "C-c C-f") 'oddmuse-edit)
(define-key oddmuse-mode-map (kbd "C-c C-i") 'oddmuse-insert-pagename)

;; This has been stolen from simple-wiki-edit
;;;###autoload
(defun oddmuse-toggle-minor (&optional arg)
  "Toggle minor mode state."
  (interactive)
  (let ((num (prefix-numeric-value arg)))
    (cond
     ((or (not arg) (equal num 0))
      (setq oddmuse-minor (not oddmuse-minor)))
     ((> num 0) (set 'oddmuse-minor t))
     ((< num 0) (set 'oddmuse-minor nil)))
    (message "Oddmuse Minor set to %S" oddmuse-minor)
    oddmuse-minor))

(add-to-list 'minor-mode-alist
             '(oddmuse-minor " [MINOR]"))

(defun oddmuse-format-command (command)
  "Internal: Substitute oddmuse format flags according to `url',
`oddmuse-page-name', `summary', `oddmuse-username', `question',
`oddmuse-password', `oddmuse-revision'."
  (let ((hatena "?"))
    (dolist (pair '(("%w" . url)
		    ("%t" . oddmuse-page-name)
		    ("%s" . summary)
                    ("%u" . oddmuse-username)
		    ("%m" . oddmuse-minor)
                    ("%p" . oddmuse-password)
                    ("%q" . question)
		    ("%o" . oddmuse-revision)
		    ("%\\?" . hatena)))
      (when (and (boundp (cdr pair)) (stringp (symbol-value (cdr pair))))
        (setq command (replace-regexp-in-string (car pair)
                                                (shell-quote-argument
                                                 (symbol-value (cdr pair)))
                                                command t t))))
    command))

(defun oddmuse-read-wiki-and-pagename ()
  "Read an wikiname and a pagename of `oddmuse-wikis' with completion."
  (let ((wiki (completing-read "Wiki: " oddmuse-wikis nil t oddmuse-wiki)))
    (list wiki (oddmuse-read-pagename wiki))))  

;;;###autoload
(defun oddmuse-edit (wiki pagename)
  "Edit a page on a wiki.
WIKI is the name of the wiki as defined in `oddmuse-wikis',
PAGENAME is the pagename of the page you want to edit.
Use a prefix argument to force a reload of the page."
  (interactive (oddmuse-read-wiki-and-pagename))
  (make-directory (concat oddmuse-directory "/" wiki) t)
  (let ((name (concat wiki ":" pagename)))
    (if (and (get-buffer name)
             (not current-prefix-arg))
        (pop-to-buffer (get-buffer name))
      (let* ((wiki-data (assoc wiki oddmuse-wikis))
             (url (nth 1 wiki-data))
             (command (let ((oddmuse-page-name pagename))
			(oddmuse-format-command oddmuse-get-command)))
             (coding (nth 2 wiki-data))
             (buf (find-file-noselect (concat oddmuse-directory "/" wiki "/"
					      pagename)))
             (coding-system-for-read coding)
             (coding-system-for-write coding))
        (set-buffer buf)
        (unless (equal name (buffer-name)) (rename-buffer name))
        (erase-buffer)
	(let ((max-mini-window-height 1))
	  (shell-command command buf))
        (pop-to-buffer buf)
	(oddmuse-mode)))))

(defalias 'oddmuse-go 'oddmuse-edit)

(autoload 'word-at-point "thingatpt")

;;;###autoload
(defun oddmuse-follow (arg)
  "Figure out what page we need to visit
and call `oddmuse-edit' on it."
  (interactive "P")
  (let ((pagename (if arg (oddmuse-read-pagename oddmuse-wiki)
                    (oddmuse-pagename-at-point))))
    (oddmuse-edit (or oddmuse-wiki
                      (read-from-minibuffer "URL: "))
                  pagename)))

(defun oddmuse-current-free-link-contents ()
  "Free link contents if the point is between [[ and ]]."
  (save-excursion
    (let* ((pos (point))
           (start (search-backward "[[" nil t))
           (end (search-forward "]]" nil t)))
      (and start end (>= end pos)
           (replace-regexp-in-string
            " " "_"
            (buffer-substring (+ start 2) (- end 2)))))))

(defun oddmuse-pagename-at-point ()
  "Page name at point."
  (let ((pagename (word-at-point)))
    (cond ((oddmuse-current-free-link-contents))
          ((oddmuse-wikiname-p pagename)
           pagename)
          (t
           (error "No link found at point")))))

(defun oddmuse-wikiname-p (pagename)
  "Whether PAGENAME is WikiName or not."
  (let (case-fold-search)
    (string-match (concat "^" oddmuse-link-pattern "$") pagename)))

;; (oddmuse-wikiname-p "WikiName")
;; (oddmuse-wikiname-p "not-wikiname")
;; (oddmuse-wikiname-p "notWikiName")

(defun oddmuse-run (mesg command buf)
  "Print MESG and run COMMAND on the current buffer.
MESG should be appropriate for the following uses:
  \"MESG...\"
  \"MESG...done\"
  \"MESG failed: REASON\"
Save outpout in BUF and report an appropriate error."
  (message "%s..." mesg)
  (if (and (= 0 (shell-command-on-region (point-min) (point-max) command buf))
	   (string= "302" (with-current-buffer buf
			     (buffer-string))))
      (message "%s...done" mesg)
    (let ((err "Unknown error"))
      (with-current-buffer buf
	(when (re-search-forward "<h1>\\(.*?\\)\\.?</h1>" nil t)
	  (setq err (match-string 1))))
      (error "%s...%s" mesg err))))

;;;###autoload
(defun oddmuse-post (summary)
  "Post the current buffer to the current wiki.
The current wiki is taken from `oddmuse-wiki'."
  (interactive "sSummary: ")
  ;; when using prefix or on a buffer that is not in oddmuse-mode
  (when (or (not oddmuse-wiki) current-prefix-arg)
    (set (make-local-variable 'oddmuse-wiki)
         (completing-read "Wiki: " oddmuse-wikis nil t)))
  (when (not oddmuse-page-name)
    (set (make-local-variable 'oddmuse-page-name)
         (read-from-minibuffer "Pagename: " (buffer-name))))
  (let* ((list (assoc oddmuse-wiki oddmuse-wikis))
         (url (nth 1 list))
         (oddmuse-minor (if oddmuse-minor "on" "off"))
         (coding (nth 2 list))
         (coding-system-for-read coding)
         (coding-system-for-write coding)
	 (question (nth 3 list))
	 (oddmuse-username (or (nth 4 list)
			       oddmuse-username))
         (command (oddmuse-format-command oddmuse-post-command))
	 (buf (get-buffer-create " *oddmuse-response*"))
	 (text (buffer-string)))
    (and buffer-file-name (basic-save-buffer))
    (oddmuse-run "Posting" command buf)))

(defun oddmuse-make-completion-table (wiki)
  "Create pagename completion table for WIKI. if available, return precomputed one."
  (or (gethash wiki oddmuse-pages-hash)
      (oddmuse-compute-pagename-completion-table wiki)))

(defun oddmuse-compute-pagename-completion-table (&optional wiki-arg)
  "Really fetch the list of pagenames from WIKI.
This command is used to reflect new pages to `oddmuse-pages-hash'."
  (interactive)
  (let* ((wiki (or wiki-arg
                   (completing-read "Wiki: " oddmuse-wikis nil t oddmuse-wiki)))
         (url (cadr (assoc wiki oddmuse-wikis)))
         (command (oddmuse-format-command oddmuse-index-get-command))
         table)
    (message "Getting index of all pages...")
    (prog1 (setq table (mapcar 'list (split-string (shell-command-to-string command))))
      (puthash wiki table oddmuse-pages-hash)
      (message "Getting index of all pages...done"))))

(defun oddmuse-read-pagename (wiki)
  "Read a pagename of WIKI with completion."
  (completing-read "Pagename: " (oddmuse-make-completion-table wiki)))

;;;###autoload
(defun oddmuse-rc (&optional include-minor-edits)
  "Show Recent Changes.
With universal argument, reload."
  (interactive "P")
  (let* ((wiki (or oddmuse-wiki
		   (completing-read "Wiki: " oddmuse-wikis nil t)))
	 (name (concat "*" wiki " RC*")))
    (if (and (get-buffer name)
             (not current-prefix-arg))
        (pop-to-buffer (get-buffer name))
      (let* ((wiki-data (assoc oddmuse-wiki oddmuse-wikis))
             (url (nth 1 wiki-data))
             (command (oddmuse-format-command oddmuse-rc-command))
             (coding (nth 2 wiki-data))
             (buf (get-buffer-create name))
             (coding-system-for-read coding)
             (coding-system-for-write coding))
	(set-buffer buf)
        (unless (equal name (buffer-name)) (rename-buffer name))
        (erase-buffer)
	(let ((max-mini-window-height 1))
	  (shell-command command buf))
        (pop-to-buffer buf)
	(oddmuse-rc-buffer)
	(set (make-local-variable 'oddmuse-wiki) wiki)))))

(defun oddmuse-rc-buffer ()
  "Parse current buffer as RSS 3.0 and display it correctly."
  (let (result)
    (dolist (item (cdr (split-string (buffer-string) "\n\n")));; skip first item
      (let ((data (mapcar (lambda (line)
			    (when (string-match "^\\(.*?\\): \\(.*\\)" line)
			      (cons (match-string 1 line)
				    (match-string 2 line))))
			  (split-string item "\n"))))
	(setq result (cons data result))))
    (erase-buffer)
    (dolist (item (nreverse result))
      (insert "[[" (cdr (assoc "title" item)) "]] – "
	      (cdr (assoc "generator" item)) "\n"))
    (goto-char (point-min))
    (oddmuse-mode)))

;;;###autoload
(defun oddmuse-revert ()
  "Revert this oddmuse page."
  (interactive)
  (let ((current-prefix-arg 4))
    (oddmuse-edit oddmuse-wiki oddmuse-page-name)))

;;;###autoload
(defun oddmuse-insert-pagename (pagename)
  "Insert a PAGENAME of current wiki with completion."
  (interactive (list (oddmuse-read-pagename oddmuse-wiki)))
  (insert pagename))

;;;###autoload
(defun emacswiki-post (&optional pagename summary)
  "Post the current buffer to the EmacsWiki.
If this command is invoked interactively: with prefix argument, prompts pagename,
otherwise set pagename as basename of `buffer-file-name'.

This command is intended to post current EmacsLisp program easily."
  (interactive)
  (let* ((oddmuse-wiki "EmacsWiki")
         (oddmuse-page-name (or pagename
                                (and (not current-prefix-arg)
                                     buffer-file-name
                                     (file-name-nondirectory buffer-file-name))
                                (oddmuse-read-pagename oddmuse-wiki)))
         (summary (or summary (read-string "Summary: "))))
    (oddmuse-post summary)))

(defun oddmuse-url (wiki pagename)
  "Get the URL of oddmuse wiki."
  (condition-case v
      (concat (or (cadr (assoc wiki oddmuse-wikis)) (error)) "/" pagename)
    (error nil)))

;; (oddmuse-url "EmacsWiki" "OddmuseMode")
;; (oddmuse-url "a" "OddmuseMode")

;;;###autoload
(defun oddmuse-browse-page (wiki pagename)
  "Ask a WWW browser to load an oddmuse page.
WIKI is the name of the wiki as defined in `oddmuse-wikis',
PAGENAME is the pagename of the page you want to browse."
  (interactive (oddmuse-read-wiki-and-pagename))
  (browse-url (oddmuse-url wiki pagename)))

;;;###autoload
(defun oddmuse-browse-this-page ()
  "Ask a WWW browser to load current oddmuse page."
  (interactive)
  (oddmuse-browse-page oddmuse-wiki oddmuse-page-name))

;;;###autoload
(defun oddmuse-kill-url ()
  "Make the URL of current oddmuse page the latest kill in the kill ring."
  (interactive)
  (kill-new (oddmuse-url oddmuse-wiki oddmuse-page-name)))

(provide 'oddmuse)

;;; oddmuse-curl.el ends here
