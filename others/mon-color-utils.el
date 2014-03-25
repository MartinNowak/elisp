;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; -*- mode: EMACS-LISP; -*-
;;; this is mon-color-utils.el
;;; ================================================================
;;; DESCRIPTION:
;;; mon-color-utils provides an assembled set of routines pertinent to
;;; manipulations/examinations of color.There is nothing new in here. 
;;; Everything presented herein has been made available separately
;;; elsewhere, including:
;;;
;;; Juri Linkov's list-colors,rgb->hsv routines, etc. 
;;;
;;; An implementation of ``colorcomp'' from info node:
;;; `(elisp) Abstract Display Example'; 
;;; 
;;; A snippet of commented out code from faces.el;
;;;
;;; `*mon-list-colors-sort*' (&etc.) WAS: Juri Linkov's `list-colors-sort' etc.
;;; See inline for addtional comments/sources.
;;;
;;; `mon-defined-colors-without-duplicates' <- faces.el
;;;
;;; The code of `mon-colorcomp' (&etc.) was lifted verbatim from: 
;;; (info "(elisp)Abstract Display Example") w/ minor modification to the
;;; completely (IMHO) nonsensical key-bindings of the original example.
;;; 
;;; !!!The MON KEY does not claim authorship of _any_ of the individual 
;;; components included of this file. The only act of authorship on MON's part
;;; is their assembly in the aggregate.!!!
;;;
;;; FUNCTIONS:►►►
;;; `mon-mon-rgb-to-hsv', `mon-list-colors-display', `mon-list-colors-key'    
;;; `mon-colorcomp-pp',`mon-colorcomp', `colorcomp-mod'
;;; `mon-colorcomp-R-more', `mon-colorcomp-G-more', `mon-colorcomp-B-more'
;;; `mon-colorcomp-R-less', `mon-colorcomp-G-less', `mon-colorcomp-B-less'
;;; `mon-colorcomp-copy-as-kill-and-exit'
;;; FUNCTIONS:◄◄◄
;;;
;;; MACROS:
;;;
;;; CONSTANTS:
;;;
;;; VARIABLES:
;;; `*mon-list-colors-sort*' 
;;; `*mon-colorcomp-ewoc*', `*mon-colorcomp-data*'
;;; `*mon-colorcomp-mode-map*',`*mon-colorcomp-labels*'
;;;
;;; ALIASED/ADVISED/SUBST'D:
;;; `read-color' -> `mon-read-color'
;;;
;;; DEPRECATED:
;;;
;;; RENAMED: 
;;;
;;; MOVED:
;;;
;;; REQUIRES:
;;;
;;; TODO:
;;;
;;; NOTES:
;;;
;;; SNIPPETS:
;;;
;;; THIRD PARTY CODE:
;;; FOLLOWING: `list-colors-display', `list-colors-key', `list-colors-sort', `rgb-to-hsv'
;;; FROM: SOURCE: (URL `http://lists.gnu.org/archive/html/emacs-devel/2009-08/msg00188.html')
;;;
;;; MAINTAINER: MON KEY
;;;
;;; PUBLIC-LINK: (URL `http://www.emacswiki.org/emacs/mon-color-utils.el')
;;; FILE-PUBLISHED: <Timestamp: #{2009-09-22} - by MON KEY>
;;;
;;; FILE-CREATED:
;;; <Timestamp: #{2009-09-04T16:06:46-04:00Z}#{09365} - by MON KEY>
;;; ================================================================
;;; This file is not part of GNU Emacs.
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 3, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; see the file COPYING.  If not, write to
;;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;;; Floor, Boston, MA 02110-1301, USA.
;;; ================================================================
;;; CODE:

;;; ==============================
;;; COURTESY: faces.el
;;; Commented out because it was decided that it was better to include the
;;; duplicates in read-color's completion list.
(defun mon-defined-colors-without-duplicates ()
   "Return the list of `defined-colors', without the no-space versions.
For each color name, we keep the variant that DOES have spaces."
   (let ((result (copy-sequence (defined-colors)))
         to-be-rejected)
     (save-match-data
       (dolist (this result)
         (if (string-match " " this)
             (push (replace-regexp-in-string " " ""
                                             this)
                   to-be-rejected)))
       (dolist (elt to-be-rejected)
         (let ((as-found (car (member-ignore-case elt result))))
           (setq result (delete as-found result)))))
     result))

;;; ==============================
;;; SOURCE: (URL `http://lists.gnu.org/archive/html/emacs-devel/2009-08/msg00188.html')
;;; FROM: 	Juri Linkov
;;; SUBJECT: 	Re: Darkening font-lock colors
;;; DATE: 	Wed, 05 Aug 2009 01:14:14 +0300
;;; RE: Darkening font-lock colors
;;; ==============================
;; As proposed in 
;; (URL `http://lists.gnu.org/archive/html/emacs-devel/2005-01/msg00251.html')
;; I implemented the color sorting option for `list-colors-display'.
;;
;; Below is a short patch that adds a customizable variable
;; `list-colors-sort' with some useful sort orders to sort
;; by color name, RGB, HSV, and HVS distance to the specified color.
;; The default is unordered - the same order as now.
;;
;; The HVS distance is the most useful sorting order.
;; For instance, for the source color "rosy brown"
;; (the former `font-lock-string-face' color) it shows
;; that a new color "VioletRed4" is far away from "rosy brown".
;; The closest colors for "rosy brown" on the HVS cylinder are:
;;
;;  rosy brown RosyBrown3 RosyBrown4 RosyBrown2 RosyBrown1 light coral indian
;;  IndianRed3 IndianRed4 IndianRed2 IndianRed1 brown brown3 brown4 brown2
;;  firebrick  red
;;
;;; ==============================
;;; COURTESY: Juri Linkov WAS: `list-colors-sort' 
;;; CREATED: <Timestamp: #{2009-09-04T16:08:42-04:00Z}#{09365} - by MON KEY>
(defcustom *mon-list-colors-sort* nil
  "Sort order for `mon-list-colors-display'.
`nil' means unsorted (implementation-dependent order).
`name' sorts by color name.
`r-g-b' sorts by red, green, blue components.
`h-s-v' sorts by hue, saturation, value.
`hsv-dist' sorts by the HVS distance to the specified color."
  :type '(choice (const :tag "Color Name" name)
               (const :tag "Red-Green-Blue" r-g-b)
               (const :tag "Hue-Saturation-Value" h-s-v)
               (cons :tag "Distance on HSV cylinder"
                     (const :tag "Distance from Color" hsv-dist)
                     (color :tag "Source Color Name"))
               (const :tag "Unsorted" nil))
  :group 'facemenu
  :version "23.2")
;;
;;; ==============================
;;; COURTESY: Juri Linkov WAS: `rgb-to-hsv'
;;; CREATED: <Timestamp: #{2009-09-04T16:08:42-04:00Z}#{09365} - by MON KEY>
(defun mon-mon-rgb-to-hsv (r g b)
  "For R, G, B color components return a list of hue, saturation, value.
R, G, B input values should be in [0..65535] range.
Output values for hue are in [0..360] range.
Output values for saturation and value are in [0..1] range."
  (let* ((r (/ r 65535.0))
       (g (/ g 65535.0))
       (b (/ b 65535.0))
       (max (max r g b))
       (min (min r g b))
       (h (cond ((= max min) 0)
                ((= max r) (mod (+ (* 60 (/ (- g b) (- max min))) 360) 360))
                ((= max g) (+ (* 60 (/ (- b r) (- max min))) 120))
                ((= max b) (+ (* 60 (/ (- r g) (- max min))) 240))))
       (s (cond ((= max 0) 0)
                (t (- 1 (/ min max)))))
       (v max))
    (list h s v)))
;;
;;; ==============================
;;; SOURCE: (URL `http://lists.gnu.org/archive/html/emacs-devel/2009-08/msg00188.html')
;;; COURTESY: Juri Linkov 
;;; CREATED: <Timestamp: #{2009-09-04T16:08:42-04:00Z}#{09365} - by MON KEY>
;;; WAS: `list-colors-key'
(defun mon-list-colors-key (color)
  "Return a list of keys for sorting colors depending on `*mon-list-colors-sort*'.
COLOR is the name of the color.  Filters out a color from the output
when return value is nil."
  (cond
   ((null *mon-list-colors-sort*) color)
   ((eq *mon-list-colors-sort* 'name)
    (list color))
   ((eq *mon-list-colors-sort* 'r-g-b)
    (color-values color))
   ((eq *mon-list-colors-sort* 'h-s-v)
    (apply 'mon-rgb-to-hsv (color-values color)))
   ((eq (car *mon-list-colors-sort*) 'hsv-dist)
    (let* ((c-rgb (color-values color))
         (c-hsv (apply 'mon-rgb-to-hsv c-rgb))
         (o-hsv (apply 'mon-rgb-to-hsv (color-values (cdr *mon-list-colors-sort*)))))
      (unless (and (eq (nth 0 c-rgb) (nth 1 c-rgb)) ; exclude grayscale
                 (eq (nth 1 c-rgb) (nth 2 c-rgb)))
      ;; 3D Euclidean distance
      (list (+ (expt (- (abs (- 180 (nth 0 c-hsv))) ; wrap hue as circle
                        (abs (- 180 (nth 0 o-hsv)))) 2)
               (expt (- (nth 1 c-hsv) (nth 1 o-hsv)) 2)
               (expt (- (nth 2 c-hsv) (nth 2 o-hsv)) 2))))))))
;;
;;; ==============================
;;; COURTESY: Juri Linkov WAS: `list-colors-display' <- facemenu.el
;;; CREATED: <Timestamp: #{2009-09-04T16:08:42-04:00Z}#{09365} - by MON KEY>
(defun mon-list-colors-display (&optional list buffer-name)
  "Display names of defined colors, and show what they look like.
If the optional argument LIST is non-nil, it should be a list of
colors to display.  Otherwise, this command computes a list of
colors that the current display can handle.  If the optional
argument BUFFER-NAME is nil, it defaults to *Colors*."
  (interactive)
  (when (and (null list) (> (display-color-cells) 0))
    (setq list (list-colors-duplicates (defined-colors)))
    (when *mon-list-colors-sort*
      (setq list (mapcar
		  'car
		  (sort (delq nil (mapcar
				   (lambda (c)
				     (let ((key (mon-list-colors-key (car c))))
				       (and key (cons c key))))
				   list))
			(lambda (a b)
			  (let* ((a-keys (cdr a))
				 (b-keys (cdr b))
				 (a-key (car a-keys))
				 (b-key (car b-keys)))
			    (while (and a-key b-key (eq a-key b-key))
			      (setq a-keys (cdr a-keys) a-key (car a-keys)
				    b-keys (cdr b-keys) b-key (car b-keys)))
			    (cond
			     ((and (numberp a-key) (numberp b-key))
			      (< a-key b-key))
			     ((and (stringp a-key) (stringp b-key))
			      (string< a-key b-key)))))))))
    (when (memq (display-visual-class) '(gray-scale pseudo-color direct-color))
      ;; Don't show more than what the display can handle.
      (let ((lc (nthcdr (1- (display-color-cells)) list)))
	(if lc
	    (setcdr lc nil)))))
  (with-help-window (or buffer-name "*Colors*")
    (save-excursion
      (set-buffer standard-output)
      (setq truncate-lines t)
      (if temp-buffer-show-function
	  (list-colors-print list)
	;; Call list-colors-print from temp-buffer-show-hook
	;; to get the right value of window-width in list-colors-print
	;; after the buffer is displayed.
	(add-hook 'temp-buffer-show-hook
		  (lambda () (list-colors-print list)) nil t)))))


;;; ==============================
;;; COLORCOMP 
;;; SOURCE: (info "(elisp)Abstract Display Example")
;;; Here is a simple example using functions of the ewoc package to
;;; implement a "color components display," an area in a buffer that
;;; represents a vector of three integers (itself representing a 24-bit RGB
;;; value) in various ways.
;;
;;; This example can be extended to be a "color selection widget" (in
;;; other words, the controller part of the "model/view/controller" design
;;; paradigm) by defining commands to modify `colorcomp-data' and to
;;; "finish" the selection process, and a keymap to tie it all together
;;; conveniently.
;;;
;;; Note that we never modify the data in each node, which is fixed when
;;; the ewoc is created to be either `nil' or an index into the vector
;;; `colorcomp-data', the actual color components.
;;; ==============================
;;;
;;; (setq rep-mon-cc
;;;   '(("colorcomp-ewoc"    "*mon-colorcomp-ewoc*")
;;; 	("colorcomp-data"     "*mon-colorcomp-data*")
;;; 	("colorcomp-mode-map" "*mon-colorcomp-mode-map*")
;;; 	("colorcomp-labels"   "*mon-colorcomp-labels*")))
;;; (mon-replace-region-regexp-lists 'rep-mon-cc)
;;; ==============================

(require 'ewoc)

;;; ==============================
;;; WAS: `colorcomp-ewoc' `colorcomp-data' 
;;;      `colorcomp-mode-map' `colorcomp-labels'
(defvar *mon-colorcomp-ewoc* nil)
;;
(defvar *mon-colorcomp-data* nil)
;;
(defvar *mon-colorcomp-mode-map* nil)
;;
(defvar *mon-colorcomp-labels* ["Red" "Green" "Blue"])

;;; ==============================
;;; WAS: `colorcomp-pp'
(defun mon-colorcomp-pp (data)
  (if data
      (let ((comp (aref *mon-colorcomp-data* data)))
	(insert (aref *mon-colorcomp-labels* data) "\t: #x"
		(format "%02X" comp) " "
		(make-string (ash comp -2) ?#) "\n"))
    (let ((cstr (format "#%02X%02X%02X"
			(aref *mon-colorcomp-data* 0)
			(aref *mon-colorcomp-data* 1)
			(aref *mon-colorcomp-data* 2)))
	  (samp " (sample text) "))
      (insert "Color\t: "
	      (propertize samp 'face `(foreground-color . ,cstr))
	      (propertize samp 'face `(background-color . ,cstr))
	      "\n"))))

;;; ==============================
;;; WAS: `colorcomp'
(defun mon-colorcomp (color)
  "Allow fiddling with COLOR in a new buffer.
     The buffer is in MON Color Components mode."
  (interactive "sColor (name or #RGB or #RRGGBB): ")
  (when (string= "" color)
    (setq color "green"))
  (unless (color-values color)
    (error "No such color: %S" color))
  (switch-to-buffer
   (generate-new-buffer (format "originally: %s" color)))
  (kill-all-local-variables)
  (setq major-mode 'mon-colorcomp-mode
	mode-name "MON Color Components")
  (use-local-map *mon-colorcomp-mode-map*)
  (erase-buffer)
  (buffer-disable-undo)
  (let ((data (apply 'vector (mapcar (lambda (n) (ash n -8))
				     (color-values color))))
	(ewoc (ewoc-create 'mon-colorcomp-pp
			   "\nMON Color Components\n\n"
			   (substitute-command-keys
			    "\n\\{*mon-colorcomp-mode-map*}"))))
    (set (make-local-variable '*mon-colorcomp-data*) data)
    (set (make-local-variable '*mon-colorcomp-ewoc*) ewoc)
    (ewoc-enter-last ewoc 0)
    (ewoc-enter-last ewoc 1)
    (ewoc-enter-last ewoc 2)
    (ewoc-enter-last ewoc nil)))

;;; ==============================
;;; WAS: `colorcomp-mod'
(defun colorcomp-mod (index limit delta)
  (let ((cur (aref *mon-colorcomp-data* index)))
    (unless (= limit cur)
      (aset *mon-colorcomp-data* index (+ cur delta)))
    (ewoc-invalidate
     *mon-colorcomp-ewoc*
     (ewoc-nth *mon-colorcomp-ewoc* index)
     (ewoc-nth *mon-colorcomp-ewoc* -1))))

;;; ==============================
;;; WAS: `colorcomp-R-more', `colorcomp-G-more', `colorcomp-B-more'
;;;      `colorcomp-R-less', `colorcomp-G-less', `colorcomp-B-less'
(defun mon-colorcomp-R-more () (interactive) (mon-colorcomp-mod 0 255 1))
(defun mon-colorcomp-G-more () (interactive) (mon-colorcomp-mod 1 255 1))
(defun mon-colorcomp-B-more () (interactive) (mon-colorcomp-mod 2 255 1))
(defun mon-colorcomp-R-less () (interactive) (mon-colorcomp-mod 0 0 -1))
(defun mon-colorcomp-G-less () (interactive) (mon-colorcomp-mod 1 0 -1))
(defun mon-colorcomp-B-less () (interactive) (mon-colorcomp-mod 2 0 -1))

;;; ==============================
;;; WAS: `colorcomp-copy-as-kill-and-exit'
(defun mon-colorcomp-copy-as-kill-and-exit ()
  "Copy the color components into the kill ring and kill the buffer.
     The string is formatted #RRGGBB (hash followed by six hex digits)."
  (interactive)
  (kill-new (format "#%02X%02X%02X"
		    (aref colorcomp-data 0)
		    (aref colorcomp-data 1)
		    (aref colorcomp-data 2)))
  (kill-buffer nil))

;;; ==============================
;;; NOTE: Changed default bindings. 
;;; MODIFICATIONS: <Timestamp: #{2009-09-04T16:32:08-04:00Z}#{09365} - by MON KEY>
;;; WAS: `colorcomp-mode-map'
(setq *mon-colorcomp-mode-map*
      (let ((m (make-sparse-keymap)))
	(suppress-keymap m)
	(define-key m "r" 'mon-colorcomp-R-less)
	(define-key m "R" 'mon-colorcomp-R-more)
	(define-key m "g" 'mon-colorcomp-G-less)
	(define-key m "G" 'mon-colorcomp-G-more)
	(define-key m "b" 'mon-colorcomp-B-less)
	(define-key m "B" 'mon-colorcomp-B-more)
	(define-key m " " 'mon-colorcomp-copy-as-kill-and-exit)
	m))

;;; ==============================
(provide 'mon-color-utils)
;;; ==============================

;;; ================================================================
;;; mon-color-utils.el ends here
;;; EOF
