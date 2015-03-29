;;; htmlr.el -- HTML rendering in Elisp

;; Copyright (C) 2002  Alex Schroeder

;; Author: Alex Schroeder <alex@gnu.org>
;; Maintainer: Steve Yegge <steve.yegge@gmail.com>
;; Modified by: Pierre Gaston <pierre@gaston-karlaouzou.com>
;;              Steve Yegge <steve.yegge@gmail.com>
;; Version: 0.0.7
;; Keywords: hypermedia
;; URL: http://www.emacswiki.org/cgi-bin/wiki.pl?HtmlRendering

;; This file is not part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Provides functions to render HTML in a buffer, and a filter
;; function that does the right thing when connected to a network
;; stream.

;; If you want to contribute see the HomePage and the TODOs in the code

;;History
;; 0.0.7
;;  - bug fix: wrap/fill even if there are no tags in the text
;; 0.0.6
;;  - support for pre, code tags
;;  - several fixes for the generation of newlines, including
;;    consolidation of multiple blank lines for cleaner-looking output
;;  - added new behavioral customization variables
;;  - code cleanup: FSF elisp style guide compliance fixes
;; 0.0.5
;;  - support for dl dd dt tags
;;  - fixes new line problems
;;  - other fixes
;; 0.0.4
;;  - support for h1..h6, ol tags
;;  - more style variables
;;  - highlight for link and img tags
;;  - more fixes
;; 0.0.3
;;  - change the behaviour of the parser. It now uses the content
;;    of the stack for the transitions and not last-tag.
;;  - as a result, all tags but empty tags (img, hr ...) and closing
;;    tags must be pushed.
;;  - transition definitions are more compact because we don't need
;;    transition from closing tag anymore
;;  - stack now contains the position of the beginning of the tag
;;  - introduce `htmlr-last-wrap-pos' variable to keep track of what
;;    has already been wrapped
;;  - bugs treat space around <img> <a> <b> etc.. a trick solution
;;    but a \n if we need a space because \n are replace by space by
;;    wrap while space are erased.
;;  - add the bullet list definition for sublist + * - etc...
;;  - other small fixes
;;
;; 0.0.2
;;  - added whatever tag to limit the complexity of the definition
;;    of `htmlr-transitions'.
;;  - added support for links [src text]. better highlight needed
;;  - added support for images {src (alt | name)} better highlight needed
;;  - added support for i, em, hr, br, tags
;;
;;; Thanks:

;; Patrick Anderson <patware@freeshell.org> -- for writing ewb.el

;;; Code:

(defcustom htmlr-respect-fill-column nil
  "Non-nil to wrap to the current `fill-column'.
If nil, adjusts text to fill the bounds of the window."
  :type 'boolean
  :group 'htmlr)

(defcustom htmlr-retain-text-properties nil
  "Non-nil to leave existing text properties in the text during rendering."
  :type 'boolean
  :group 'htmlr)

(defcustom htmlr-newline-after-heading nil
  "Non-nil to insert a newline after a heading element."
  :type 'boolean
  :group 'htmlr)

;;; Cosmetics

(defvar htmlr-style-bullet-list
  (if window-system
      '("•" "◦" "⁃" "-" "." "")
    '("*" "+" "-" "." "="))
  "List of bullets to be used for nested ul tags.")

(defvar htmlr-style-horizontal-line
  ?-
  "Character for drawing an hr tag")

;; For all text properties make sure that they are rear-nonsticky
;; so that they don't modify the text inserted afterward.
(defvar htmlr-style-h1
   '(face (:family "helv" :height 2.0 :weight bold)
          front-sticky nil rear-nonsticky t)
  "Text properties for h1 title")

(defvar htmlr-style-h2
   '(face (:family "helv" :height 1.8 :weight bold)
          front-sticky nil rear-nonsticky t)
  "Text properties for h2 title")

(defvar htmlr-style-h3
   '(face (:family "helv" :height 1.6 :weight bold)
          front-sticky nil  rear-nonsticky t)
  "Text properties for h3 title")

(defvar htmlr-style-h4
   '(face (:family "helv" :height 1.4 :weight bold)
          front-sticky nil rear-nonsticky t)
  "Text properties for h4 title")

(defvar htmlr-style-b
  '(face bold front-sticky nil rear-nonsticky t)
  "Text properties for bold tags")

(defvar htmlr-style-em
  '(face bold-italic front-sticky nil rear-nonsticky t)
  "Text properties for emphasis tags")

(defvar htmlr-style-i
  '(face italic front-sticky nil rear-nonsticky t)
  "Text properties for italic tags")

(defvar htmlr-style-link
   '(face (:foreground "cyan" :underline t)
          front-sticky nil rear-nonsticky t)
   "Text properties for link tags")

(defvar htmlr-style-img
  '(face custom-state-face front-sticky nil rear-nonsticky t)
  "Text properties for img tags")

(defvar htmlr-style-code
  '(face (:family "fixed") front-sticky nil rear-nonsticky t)
  "Text properties for code tags")

(defvar htmlr-style-pre
  '(face (:family "courier") front-sticky nil rear-nonsticky t)
  "Text properties for pre tags")

(defun htmlr-style-bullet (n)
  "Return the n bullet."
  (elt htmlr-style-bullet-list (% n (length htmlr-style-bullet-list))))

(defun htmlr-style-title (tag)
  "Return the text-properties associated with the title tag TAG."
  (cond
   ((eq tag 'h1) htmlr-style-h1)
   ((eq tag 'h2) htmlr-style-h2)
   ((eq tag 'h3) htmlr-style-h3)
   ((eq tag 'h4) htmlr-style-h4)
   ((eq tag 'h5) htmlr-style-h4)
   ((eq tag 'h6) htmlr-style-h4)))

;; Parser definitions.
(defvar htmlr-transitions
  '((p (/p wrap pop)
       (p pop push wrap paragraph)
       (pre wrap paragraph push)
       (ol wrap indent push counter)
       (ul wrap paragraph indent push)
       (dl push wrap)
       (li wrap bullet push)
       (h1 wrap paragraph push)
       (h2 wrap paragraph push)
       (h3 wrap paragraph push)
       (h4 wrap paragraph push)
       (h5 wrap paragraph push)
       (h6 wrap paragraph push))
    (nil (p wrap paragraph push)
         (ul wrap paragraph indent push)
         (ol wrap indent push counter)
         (dl push wrap)
         (pre wrap paragraph push)
         (h1 wrap paragraph push)
         (h2 wrap paragraph push)
         (h3 wrap paragraph push)
         (h4 wrap paragraph push)
         (h5 wrap paragraph push)
         (h6 wrap paragraph push)
         (nil wrap))
    (a (/a zap-ws close-link pop))
    (b (/b zap-ws bold pop))
    (i (/i zap-ws italic pop))
    (em (/em zap-ws emphasis pop))
    (code (/code zap-ws code pop))
    (h1 (/h1 wrap title paragraph pop))
    (h2 (/h2 wrap title paragraph pop))
    (h3 (/h3 wrap title paragraph pop))
    (h4 (/h4 wrap title paragraph pop))
    (h5 (/h5 wrap title paragraph pop))
    (h6 (/h6 wrap title paragraph pop))
    (ul (li bullet push)
        (/ul outdent pop))
    (ol (li bullet push)
        (/ol outdent pop))
    (li (p wrap pop newline push)
        (h1 wrap newline push)
        (h2 wrap newline push)
        (h3 wrap newline push)
        (h4 wrap newline push)
        (h5 wrap newline push)
        (h6 wrap newline push)
        (ul wrap indent push)
        (ol wrap indent push counter)
        (dl wrap push)
        (/ul wrap pop outdent paragraph pop)
        (/ol wrap pop outdent pop)
        (li wrap pop bullet push)
        (/li pop))
    (dl (dt push wrap newline)
        (dd push wrap indent)
        (/dl pop))
    (dt (p wrap paragraph push)
        (/dt pop)
        (/dl wrap pop pop)
        (dt pop push wrap newline)
        (dd pop push wrap indent)
        (dl push wrap))
    (dd (p wrap paragraph push)
        (/dd outdent pop)
        (/dl wrap outdent pop pop)
        (dt pop push wrap outdent newline)
        (dd pop push wrap newline)
        (dl push wrap))
    (pre (/pre paragraph preformat pop))
    (whatever
     (a push link)
     (img image)
     (b push)
     (em push)
     (code push)
     (i push)
     (hr wrap line)
     (br wrap newline)))
   "Rules for transitions between tags.
Tags are symbols.  They can be closing tags as well.  This is a nested
alist.  The first key is the current tag, the second key is the new
tag, and the value is a list of actions to take.  Use
`htmlr-transition' to access these rules.  Valid actions are in
`htmlr-actions'.")

(defvar htmlr-actions
   '((wrap . htmlr-wrap)
     (paragraph . htmlr-paragraph)
     (bullet . htmlr-bullet)
     (indent . htmlr-indent)
     (outdent . htmlr-outdent)
     (bold . htmlr-bold)
     (italic . htmlr-italic)
     (emphasis . htmlr-emphasis)
     (code . htmlr-code)
     (pop . htmlr-pop)
     (push . htmlr-push)
     (preformat . htmlr-preformat)
     (link . htmlr-link)
     (close-link . htmlr-close-link)
     (image . htmlr-image)
     (line . htmlr-line)
     (newline . htmlr-newline)
     (counter . htmlr-counter)
     (title . htmlr-title)
     (zap-ws . htmlr-zap-whitespace))
  "Alist for actions from `htmlr-transitions' and functions to call.")

(defun htmlr-transition (from to)
  "Return functions to call when transition FROM TO happens.
FROM and TO are tag symbols.  The actions are based upon
`htmlr-transitions' and `htmlr-actions'."
  (let* ((from-alist (assq 'whatever htmlr-transitions))
         (actions (mapcar (lambda (action)
                            (cdr (assq action htmlr-actions)))
                          (cdr (assq to from-alist)))))
    (or actions
        ;;if not whatever
        (when (setq from-alist (assq from htmlr-transitions))
          (mapcar (lambda (action)
                    (cdr (assq action htmlr-actions)))
                  (cdr (assq to from-alist)))))))

;;; Actions

(defun htmlr-title ()
  "Fontify the title."
  (let ((title-tag (htmlr-stack-previous-tag 'h1 'h2 'h3 'h4 'h5 'h6)))
    (add-text-properties
     (cadr title-tag)
     (point)
     (htmlr-style-title (car title-tag)))
    (htmlr-newline)
    (when htmlr-newline-after-heading
      (newline))))


(defun htmlr-link ()
  "Link like [url text]."
  (insert (concat
           "["
           (cdr (assq 'href (htmlr-parse-attributes htmlr-data)))
           " ")))

(defun htmlr-close-link ()
  "Close the bracket of a link TODO highlight making url and bracket invisible."
  (save-restriction
    (let ((start (copy-marker (cadar htmlr-stack)))
          (end (point)))
      (when (> end start)
        (goto-char start)
        (add-text-properties start (search-forward " " end)
                             '(invisible t intangible t))
        (add-text-properties (point) end htmlr-style-link)
        (goto-char end)
        (insert (propertize "]" 'invisible 't 'intangible 't))))))

(defun htmlr-image ()
  "Image like [alt] or [name] TODO highlight."
  (let ((alt-text (cdr (assq 'alt (htmlr-parse-attributes htmlr-data))))
        (src-url (cdr (assq 'src (htmlr-parse-attributes htmlr-data)))))
    (unless (and alt-text (> (length alt-text) 0))
      (setq alt-text
            (if src-url
                (car (last (split-string src-url "/")))
              "dumb image")))
    (insert (concat
             (apply 'propertize "{" htmlr-style-img)
             (propertize (concat " " src-url) 'invisible 't 'intangible 't)
             (apply 'propertize (concat alt-text "}") htmlr-style-img)))))

(defun htmlr-line ()
  "Insert a line --- for hr tags."
  (htmlr-delete-whitespace-forward)
  (newline)
  (insert-char htmlr-style-horizontal-line (- (window-width) (current-column) 1))
  (newline)
  (setq htmlr-last-wrap-pos (1+ (point))))

(defun htmlr-newline ()
  "Insert a line break."
  (htmlr-delete-whitespace-forward)
  (htmlr-soft-newline)
  (setq htmlr-last-wrap-pos (1+ (point))))

(defun htmlr-bold ()
  "Make the last content bold."
  (add-text-properties (cadr (htmlr-stack-previous-tag 'b))
                       (point) htmlr-style-b))

(defun htmlr-italic ()
  "Make the last content italic."
  (add-text-properties (cadr (htmlr-stack-previous-tag 'i))
                       (point) htmlr-style-i))

(defun htmlr-emphasis ()
  "Make the last content emphasized."
  (add-text-properties (cadr (htmlr-stack-previous-tag 'em))
                       (point) htmlr-style-em))

(defun htmlr-code ()
  "Format last content as a code fragment."
  (add-text-properties (cadr (htmlr-stack-previous-tag 'code))
                       (point) htmlr-style-code))

(defun htmlr-preformat ()
  "Make the last content preformatted."
  (add-text-properties (cadr (htmlr-stack-previous-tag 'pre))
                       (point) htmlr-style-pre)
  (setq htmlr-last-wrap-pos (point)))

(defun htmlr-push ()
  "Push the current tag (dynamically bound to the symbol tag) to the stack.
See the source of `htmlr-doit'."
  (setq htmlr-stack (cons (with-no-warnings
                            (list tag (point)))
                          htmlr-stack)))

(defun htmlr-pop ()
  "Remove the previous tag from the stack."
  (setq htmlr-stack (cdr htmlr-stack)))

(defun htmlr-delete-whitespace-backward ()
  "Delete all whitespace from htmlr-last-wrap-pos to point ."
  (let ((end (point)))
    (unless (zerop (skip-chars-backward " \t\r\n" htmlr-last-wrap-pos))
      (delete-region (point) end))))

(defun htmlr-delete-whitespace-forward ()
  "Delete all whitespace following point."
  (let ((start (point)))
    (unless (zerop (skip-chars-forward " \t\r\n"))
      (delete-region start (point)))))

(defun htmlr-paragraph ()
  "Start a new paragraph, if necessary."
  (htmlr-delete-whitespace-backward)
  (htmlr-delete-whitespace-forward)
  (if (or (bobp) (looking-back "[\r\n]+"))
      (htmlr-soft-newline)
    (newline 2))
  (setq htmlr-last-wrap-pos (1+ (point))))

(defun htmlr-counter ()
  "Add a counter to the ol element in the stack."
  ;; TODO possibly take attributes value or start into account
  (nconc (car htmlr-stack) (list 0)))

(defun htmlr-bullet ()
  "Start a new list item."
  ;; TODO possibly take atribute type into account
  (let ((found (htmlr-stack-previous-tag 'ol 'ul)))
    (htmlr-delete-whitespace-backward)
    (htmlr-soft-newline)
    (delete-blank-lines)
    (if (eq (car found) 'ol)
        (insert (format "%i " (setcar (cddr found) (1+ (caddr found)))))
      (insert (concat (htmlr-style-bullet
                       (1- (htmlr-stack-count-tag 'ul))) " ")))))

(defun htmlr-delete ()
  "Delete the current element."
  (delete-region (cdar htmlr-stack) (point)))

(defun htmlr-zap-whitespace ()
  "Delete ignorable white space inside the current element."
  (htmlr-delete-whitespace (copy-marker (cadar htmlr-stack)) (point-marker)))

(defun htmlr-delete-whitespace (start end)
  "Replace multiple \n or ws by a single whitespace between START and END."
  (save-restriction
    (when (> end start)
      (goto-char start)
      (while (search-forward-regexp "\\([\n]\\|[ ]\\)+" end t)
        (replace-match " "))
      (goto-char end))))

(defun htmlr-wrap ()
  "Wrap the content of the current element.
Zap all whitespace at the beginning, too."
  (save-restriction
    (let ((start (copy-marker htmlr-last-wrap-pos))
          (end (point-marker)))
      (when (> end start)
        (goto-char start)
        (htmlr-delete-whitespace-forward)
        (while (search-forward "\n" end t)
          (replace-match " "))
        (goto-char start)
        (fill-region start end)
        (goto-char end))
      (setq htmlr-last-wrap-pos (1+ end)))))

(defun htmlr-indent ()
  "Indent some."
  (setq left-margin (+ left-margin 2))
  (htmlr-soft-newline))

(defun htmlr-outdent ()
  "Outdent some."
  (when (>= left-margin 2)
    (setq left-margin (- left-margin 2))))

(defun htmlr-soft-newline ()
  "Insert a newline, but don't allow more than one blank line."
  (newline)
  (save-excursion
    (previous-line 1)
    (delete-blank-lines)))

;;; Parsing
(require 'sgml-mode)

(defvar htmlr-entities
  (let ((table (make-hash-table :test 'equal))
        (i 32)
        elt)
    (while (< i 256)
      (setq elt (aref sgml-char-names i))
      (when elt (puthash elt
                         (if (< i 128)
                             (string i)
                           (string (make-char 'latin-iso8859-1 i)))
                         table))
      (setq i (1+ i)))
    table)
  "A hash-table for mapping SGML entity names into non-ASCII characters.
Currently, only Latin-1 characters are supported.")

(defun htmlr-parse-attributes (string-tag)
  "Return an alist where key is a symbol for the attribute name
and value is a string containing the value of the attribute
STRING-TAG is the whole tag."
  (when (string-match "</?[a-z1-6]*" string-tag)
    ;;the string starts like a tag
    (let ((attributes-list nil) (start (match-end 0)))
      (while (string-match "\\([a-z1-6]+\\)=?\"?\\([^ \">]*\\)\"?" string-tag start)
        ;;there is some attributes
        (setq start (match-end 0))
        (push (cons
               (intern (downcase (match-string 1 string-tag)))
               (match-string 2 string-tag))
              attributes-list))
      attributes-list)))

(defun htmlr-next-tag (&optional bound)
  "Go to the next tag and return a symbol for it.
The optional argument BOUND bounds the search; it is a buffer position.
`match-data' will match the tag (including the < and > characters),
and point will be left at the end of the tag, or at the last safe
point in the buffer, if no tag was found.  The last safe point is
either BOUND, `point-max', or the next < character.
Any SGML named entities are replaced on the way."
  ;; [a-z1-6]* instead of [a-z1-6]+ so that it matches comments, too
  (let* ((start (and (re-search-forward
                      "\\(<\\(/?[a-z1-6]*\\)\\|&\\([a-z1-6]+\\);\\)"
                      bound 'move)
                     (match-beginning 0)))
         (tag (and start (match-string 2)))
         (entity (and start (match-string 3)))
         (end (and start tag (search-forward ">" bound t))))
    (cond (entity
           (let ((s (gethash entity htmlr-entities)))
             (when s
               (replace-match s)))
           ;; watch out, calling recursively -- and elisp is not tail
           ;; recursive
           (htmlr-next-tag bound))
          (end
           (setq htmlr-data (if htmlr-retain-text-properties
                                (buffer-substring start end)
                              (buffer-substring-no-properties start end)))
           (delete-region start end)
           (intern (downcase tag)))
          (start (goto-char start) nil))))

(defvar htmlr-stack nil
  "List of open environments. currently filled with pair (TAG . START-POS)")
(make-variable-buffer-local 'htmlr-stack)

(defvar htmlr-last-wrap-pos nil
  "Last pos of what has allready been wrapped.")
(make-variable-buffer-local 'htmlr-last-wrap-pos)

(defvar htmlr-data nil
  "Data used for the current tag.")
(make-variable-buffer-local 'htmlr-data)

(defvar htmlr-whitespace nil
  "Within some elements, whitespace must be conserved.
In these cases, bind this variable to a non-nil value.")
(make-variable-buffer-local 'htmlr-whitespace)

(defun htmlr-stack-previous-tag (&rest tags)
  "Return the first stack entry which is eq to TAGS.
Or, to one of the car of TAGS."
  (let ((stack htmlr-stack) (found nil) result)
    (while (and stack (not found))
      (if (dolist (elem tags result)
            (setq result (or (eq (caar stack) elem) result)))
          (setq found (car stack)))
      (setq stack (cdr stack)))
    found))

(defun htmlr-stack-count-tag (tag)
  "Return the number of occurence of TAG in stack."
  (let ((count 0))
    (dolist (elem htmlr-stack)
      (if (eq (car elem) tag)
          (setq count (1+ count))))
    count))

(defun htmlr-doit (tag)
  "Based upon TAG, do the right thing.
This involves looking up the correct transition using
`htmlr-transition'.  The functions are called with point just before
the tag.  If you need to change a lot of text, such as filling
paragraphs, use `narrow-to-region' from  the beginning to
`point'.  If you need to access the data in the tag, use
`htmlr-data'."
  (let* ((functions (htmlr-transition (caar htmlr-stack) tag)))
;;    (message "%S to %S: %S" (car htmlr-stack) tag functions)
    (mapc 'funcall functions)))

(defun htmlr-step ()
  "Search for the next tag, and `htmlr-doit'.
Searching the next tag happens using `htmlr-next-tag'.
Point is left at the next safe position."
  (htmlr-doit (htmlr-next-tag)))

(defun htmlr-reset ()
  "Reset all the variables needed before starting to render.
They must be reset every time something is rendered interactively.
They must not be reset when rendering happens as part of a process
filter."
  (unless htmlr-retain-text-properties
    (fundamental-mode)
    (font-lock-mode -1)
    (set-text-properties (point) (point-max) nil))
  (setq htmlr-stack nil
        htmlr-last-tag nil
        htmlr-last-wrap-pos (point)
        left-margin 0))

;; (global-set-key (kbd "C-c c") (lambda () (interactive) (htmlr-step)))
;; (global-set-key (kbd "C-c v") (lambda () (interactive) (htmlr-reset)))

(defun htmlr-render ()
  "Render from point to the end of the buffer."
  (interactive)
  (htmlr-reset)
  (unless htmlr-respect-fill-column
    (set (make-local-variable 'fill-column) (1-(window-width))))
  (while (not (eobp))
    (htmlr-step)))

(provide 'htmlr)
;;; htmlr.el ends here
