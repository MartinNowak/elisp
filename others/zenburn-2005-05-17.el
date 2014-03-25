;;; zenburn.el --- just some alien fruit salad to keep you in the zone
;; Copyright (C) 2003, 2004, 2005  Daniel Brockman

;; Author: Daniel Brockman <daniel@brockman.se>
;; URL: http://www.brockman.se/software/zenburn/zenburn.el

;; This file is not part of GNU Emacs.

;; This color theme is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This color theme is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; News:

;; 2005-05-15: Hack mode line variables to colorize the buffer name.
;; 2005-05-14: Miscellaneous minor additions and cleanups.
;; 2005-05-13: Hack Gnus color and logo variables.
;; 2005-05-12: Add support for diff-mode.
;; 2005-05-12: Add `message-separator-face' and `message-mml-face'.
;; 2005-05-01: Add `custom-button-face'.
;; 2005-04-27: Fix `outline-{1,2,3,4}' to not be huge.
;; 2005-04-27: Add `match'.
;; 2005-04-13: Add `font-lock-preprocessor-face'.
;; 2005-04-13: Add `font-lock-variable-name-face'.
;; 2004-12-13: Add support for new compilation and breakpoint faces.
;; 2004-10-12: Add support for latest CVS features.
;; 2004-10-10: Add support for setnu-mode.
;; 2004-10-08: Add support for todoo-mode.
;; 2004-10-08: Add support for apt-utils.
;; 2004-10-07: Add support for dictionary.
;; 2004-10-07: Add support for emacs-jabber.

;;; Commentary:

;; Many thanks to Jani Nurminen, the creator of the original Zenburn
;; color theme for Vim, and the creators of the `BlackDust', `Camo',
;; and `Desert' Vim color themes, on which Jani's Zenburn was based.
;; I'm just imitating these guys.

;; Other adaptions of the Zenburn color theme
;;   <http://www.brockman.se/software/zenburn/>

;; The Lucy font family
;;   <http://www.brockman.se/software/lucy/>

;;; Short-Term Wishlist:

;; Add support for eshell.

;; Theme the ansi-term faces `term-red', etc., and the ERC faces
;; `fg:erc-color-face1', etc.

;; Theme `gnus-server-offline-face', `gnus-server-opened-face', and
;; `gnus-server-denied-face'.  First, find out what they hell they do.

;; Theme `gnus-emphasis-highlight-words' after finding out what it
;; does.

;; Theme `gnus-cite-face-6' to `gnus-cite-face-11'.

;; Theme `emms-stream-name-face' and `emms-stream-url-face'.

;; Theme `ido-indicator-face'.

;;; Long-Term Wishlist:

;; More and better abstraction with regard to Zenburn-specific virtual
;; faces such as `zenburn-primary-1'.  In the same vein, better names?

;; Less code duplication.  For example, the foreground color is
;; spelled out in multiple different places.

;; With all due respect to Jani, cook up some new colors, instead of
;; reusing the classing ones over and over and over.  There will come
;; a point in time at which these colors will start to feel overused.

;;; Code:

(require 'color-theme)

(defvar zenburn-fg "#dcdccc")
(defvar zenburn-bg "#3f3f3f")
(defvar zenburn-bg-1 "#4f4f4f")
(defvar zenburn-bg-2 "#5f5f5f")
(defvar zenburn-yellow-1 "#f0dfaf")
(defvar zenburn-orange-1 "#dfaf8f")
(defvar zenburn-red-1 "#cc9393")
(defvar zenburn-green-0 "#5f7f5f")
(defvar zenburn-green-1 "#7f9f7f")
(defvar zenburn-green-2 "#8fb28f")
(defvar zenburn-green-3 "#9fc59f")
(defvar zenburn-green-4 "#afd8af")
(defvar zenburn-green-5 "#bfebbf")
(defvar zenburn-blue-1 "#8cd0d3")
(defvar zenburn-blue-2 "#7cb8bb")
(defvar zenburn-blue-3 "#6ca0a3")
(defvar zenburn-blue-4 "#5c888b")
(defvar zenburn-blue-5 "#4c7073")

(defvar font-lock-pseudo-keyword-face 'font-lock-pseudo-keyword-face)
(defvar font-lock-operator-face 'font-lock-operator-face)

(when (and (fboundp 'format-spec)
           (< (next-property-change
               0 (format-spec #("<%x>" 0 4 (face (:weight bold)))
                              '((?x . "foo"))) 4) 4))
  ;; We have a broken `format-spec'.  I've had the following corrected version
  ;; installed in the Emacs CVS repository, but an overriding buggy version is
  ;; included in the ERC Debian package.
  (defun format-spec (format specification)
    "Return a string based on FORMAT and SPECIFICATION.
FORMAT is a string containing `format'-like specs like \"bash %u %k\",
while SPECIFICATION is an alist mapping from format spec characters
to values."
    (with-temp-buffer
      (insert format)
      (goto-char (point-min))
      (while (search-forward "%" nil t)
        (cond
         ;; Quoted percent sign.
         ((eq (char-after) ?%)
          (delete-char 1))
         ;; Valid format spec.
         ((looking-at "\\([-0-9.]*\\)\\([a-zA-Z]\\)")
          (let* ((num (match-string 1))
                 (spec (string-to-char (match-string 2)))
                 (val (cdr (assq spec specification))))
            (unless val
              (error "Invalid format character: %s" spec))
            (let ((text (format (concat "%" num "s") val)))
              (insert-and-inherit text)
              ;; Delete the specifier body.
              (delete-region (+ (match-beginning 0) (length text))
                             (+ (match-end 0) (length text)))
              ;; Delete the percent sign.
              (delete-region (1- (match-beginning 0)) (match-beginning 0)))))
         ;; Signal an error on bogus format strings.
         (t
          (error "Invalid format string"))))
      (buffer-string))))

(setq-default mode-line-buffer-identification
              (list (propertize "%12b" 'face
                                (list :weight 'bold
                                      :foreground zenburn-yellow-1))))
(setq-default mode-line-frame-identification "")
(setq-default erc-mode-line-format
              (concat (propertize "%t" 'face
                                  (list :weight 'bold
                                        :foreground zenburn-yellow-1))
                      " %a"))

(setq gnus-logo-colors `(,zenburn-bg-2 ,zenburn-bg-1)
      gnus-mode-line-image-cache
      '(image :type xpm :ascent center :data "/* XPM */
static char *gnus-pointer[] = {
/* width height num_colors chars_per_pixel */
\"    18    11        2            1\",
/* colors */
\". c #dcdccc\",
\"# c None s None\",
/* pixels */
\"######..##..######\",
\"#####........#####\",
\"#.##.##..##...####\",
\"#...####.###...##.\",
\"#..###.######.....\",
\"#####.########...#\",
\"###########.######\",
\"####.###.#..######\",
\"######..###.######\",
\"###....####.######\",
\"###..######.######\"};"))

;;;###autoload
(defun color-theme-zenburn ()
  "Just some alien fruit salad to keep you in the zone."
  (interactive)
  (color-theme-install
   `(color-theme-zenburn
     ((background-color . ,zenburn-bg)
      (background-mode . dark)
      (border-color . ,zenburn-bg)
      (foreground-color . ,zenburn-fg)
      (mouse-color . ,zenburn-fg))
     ((goto-address-mail-face . italic)
      (goto-address-mail-mouse-face . secondary-selection)
      (goto-address-url-face . bold)
      (goto-address-url-mouse-face . hover-highlight)
      (help-highlight-face . hover-highlight)
      (imaxima-label-color . ,zenburn-yellow-1)
      (imaxima-equation-color . ,zenburn-fg)
      (list-matching-lines-face . bold)
      (view-highlight-face . hover-highlight)
      (widget-mouse-face . hover-highlight))

     (bold ((t (:weight bold))))
     (bold-italic ((t (:italic t :weight bold))))
     (default ((t (:background ,zenburn-bg :foreground ,zenburn-fg))))
     (fixed-pitch ((t (:weight bold))))
     (italic ((t (:slant italic))))
     (underline ((t (:underline t))))
     ;; (variable-pitch ((t (:font "-*-utopia-regular-r-*-*-12-*-*-*-*-*-*-*"))))

     (zenburn-background-1 ((t (:background ,zenburn-bg-1))))
     (zenburn-background-2 ((t (:background ,zenburn-bg-2))))

     (zenburn-primary-1 ((t (:foreground ,zenburn-yellow-1 :weight bold))))
     (zenburn-primary-2 ((t (:foreground ,zenburn-orange-1 :weight bold))))
     (zenburn-primary-3 ((t (:foreground "#dfdfbf" :weight bold))))
     (zenburn-primary-4 ((t (:foreground "#dca3a3" :weight bold))))
     (zenburn-primary-5 ((t (:foreground "#94bff3" :weight bold))))

     (zenburn-highlight-damp
      ((t (:foreground "#88b090" :background "#2e3330"))))
     (zenburn-highlight-alerting
      ((t (:foreground "#e37170" :background "#332323"))))
     (zenburn-highlight-subtle
      ((t (:background "#464646"))))

     (zenburn-lowlight-1 ((t (:foreground "#606060"))))
     (zenburn-lowlight-2 ((t (:foreground "#708070"))))

     (zenburn-yellow-1 ((t (:foreground ,zenburn-yellow-1))))
     (zenburn-orange-1 ((t (:foreground ,zenburn-orange-1))))
     (zenburn-red-1 ((t (:foreground ,zenburn-red-1))))
     (zenburn-green-0 ((t (:foreground ,zenburn-green-0))))
     (zenburn-green-1 ((t (:foreground ,zenburn-green-1))))
     (zenburn-green-2 ((t (:foreground ,zenburn-green-2))))
     (zenburn-green-3 ((t (:foreground ,zenburn-green-3))))
     (zenburn-green-4 ((t (:foreground ,zenburn-green-4))))
     (zenburn-green-5 ((t (:foreground ,zenburn-green-5))))
     (zenburn-blue-1 ((t (:foreground ,zenburn-blue-1))))
     (zenburn-blue-2 ((t (:foreground ,zenburn-blue-2))))
     (zenburn-blue-3 ((t (:foreground ,zenburn-blue-3))))
     (zenburn-blue-4 ((t (:foreground ,zenburn-blue-4))))
     (zenburn-blue-5 ((t (:foreground ,zenburn-blue-5))))

     (zenburn-title ((t (:inherit variable-pitch :weight bold))))

     (font-lock-builtin-face
      ((t (:inherit zenburn-blue-1))))
     (font-lock-comment-face
      ((t (:inherit zenburn-green-1))))
     (font-lock-comment-delimiter-face
      ((t (:inherit zenburn-lowlight-2))))
     (font-lock-constant-face
      ((t (:inherit zenburn-primary-4))))
     (font-lock-doc-face
      ((t (:inherit zenburn-green-2))))
     (font-lock-function-name-face
      ((t (:inherit zenburn-yellow-1))))
     (font-lock-keyword-face
      ((t (:inherit zenburn-primary-1))))
     (font-lock-negation-char-face
      ((t (:inherit zenburn-primary-1))))
     (font-lock-preprocessor-face
      ((t (:inherit zenburn-blue-1))))
     (font-lock-string-face
      ((t (:inherit zenburn-red-1))))
     (font-lock-type-face
      ((t (:inherit zenburn-primary-3))))
     (font-lock-variable-name-face
      ((t (:inherit zenburn-yellow-1))))
     (font-lock-warning-face
      ((t (:inherit zenburn-highlight-alerting))))

     (font-lock-pseudo-keyword-face
      ((t (:inherit zenburn-primary-2))))
     (font-lock-operator-face
      ((t (:inherit zenburn-primary-3))))

     (term-default-bg ((t (nil))))
     (term-default-bg-inv ((t (nil))))
     (term-default-fg ((t (nil))))
     (term-default-fg-inv ((t (nil))))
     (term-invisible ((t (nil)))) ;; FIXME: Security risk?
     (term-invisible-inv  ((t (nil))))
     (term-bold ((t (:weight bold))))
     (term-underline ((t (:underline t))))

     ;; FIXME: Map these to ansi-term's faces (`term-red', etc.).
     (zenburn-term-dark-gray      ((t (:foreground "#709080"))))
     (zenburn-term-light-blue     ((t (:foreground "#94bff3"))))
     (zenburn-term-light-cyan     ((t (:foreground "#93e0e3"))))
     (zenburn-term-light-green    ((t (:foreground "#c3bf9f"))))
     (zenburn-term-light-magenta  ((t (:foreground "#ec93d3"))))
     (zenburn-term-light-red      ((t (:foreground "#dca3a3"))))
     (zenburn-term-light-yellow   ((t (:foreground "#f0dfaf"))))
     (zenburn-term-white          ((t (:foreground "#ffffff"))))

     (zenburn-term-black          ((t (:foreground "#000000"))))
     (zenburn-term-dark-blue      ((t (:foreground "#506070"))))
     (zenburn-term-dark-cyan      ((t (:foreground "#8cd0d3"))))
     (zenburn-term-dark-green     ((t (:foreground "#60b48a"))))
     (zenburn-term-dark-magenta   ((t (:foreground "#dc8cc3"))))
     (zenburn-term-dark-red       ((t (:foreground "#705050"))))
     (zenburn-term-dark-yellow    ((t (:foreground "#dfaf8f"))))
     (zenburn-term-light-gray     ((t (:foreground ,zenburn-fg))))

     (plain-widget-button-face
      ((t (:weight bold))))
     (plain-widget-button-pressed-face
      ((t (:inverse-video t))))
     (plain-widget-documentation-face
      ((t (:inherit font-lock-doc-face))))
     (plain-widget-field-face
      ((t (:inherit zenburn-background-2))))
     (plain-widget-inactive-face
      ((t (:strike-through t))))
     (plain-widget-single-line-field-face
      ((t (:inherit zenburn-background-2))))

     (fancy-widget-button-face
      ((t (:inherit zenburn-background-1
           :box (:line-width 2 :style released-button)))))
     (fancy-widget-button-pressed-face
      ((t (:inherit zenburn-background-1
           :box (:line-width 2 :style pressed-button)))))
     (fancy-widget-button-highlight-face
      ((t (:inherit zenburn-background-1
           :box (:line-width 2 :style released-button)))))
     (fancy-widget-button-pressed-highlight-face
      ((t (:inherit zenburn-background-1
           :box (:line-width 2 :style pressed-button)))))
     (fancy-widget-documentation-face
      ((t (:inherit font-lock-doc-face))))
     (fancy-widget-field-face
      ((t (:inherit zenburn-background-2))))
     (fancy-widget-inactive-face
      ((t (:strike-through t))))
     (fancy-widget-single-line-field-face
      ((t (:inherit zenburn-background-2))))

     (widget-button-face
      ((t (:inherit plain-widget-button-face))))
     (widget-button-pressed-face
      ((t (:inherit fancy-widget-button-pressed-face))))
     (widget-button-highlight-face
      ((t (:inherit fancy-widget-button-highlight-face))))
     (widget-button-pressed-highlight-face
      ((t (:inherit fancy-widget-button-pressed-highlight-face))))
     (widget-documentation-face
      ((t (:inherit fancy-widget-documentation-face))))
     (widget-field-face
      ((t (:inherit fancy-widget-field-face))))
     (widget-inactive-face
      ((t (:inherit fancy-widget-inactive-face))))
     (widget-single-line-field-face
      ((t (:inherit fancy-widget-single-line-field-face))))

     (border ((t (:inherit zenburn-background))))
     (fringe ((t (:inherit zenburn-highlight-subtle))))
     (header-line ((t (:inherit zenburn-highlight-damp
                       :box (:color "#2e3330" :line-width 2)))))
     (mode-line ((t (:foreground "#acbc90" :background "#1e2320"
                     :box (:color "#1e2320" :line-width 2)))))
     (mode-line-inactive ((t (:background "#2e3330" :foreground "#88b090"
                              :box (:color "#2e3330" :line-width 2)))))
     (minibuffer-prompt ((t (:foreground ,zenburn-yellow-1))))
     (Buffer-menu-buffer-face ((t (:inherit zenburn-primary-1))))

     (region ((t (:foreground "#71d3b4" :background "#233323"))))
     (secondary-selection ((t (:foreground ,zenburn-fg :background "#506070"))))

     (trailing-whitespace ((t (:inherit font-lock-warning-face))))
     (highlight ((t (:inherit default))))
     (paren-face ((t (:inherit zenburn-lowlight-1))))
     (show-paren-mismatch-face ((t (:inherit font-lock-warning-face))))
     (show-paren-match-face ((t (:inherit font-lock-keyword-face))))
     (match ((t (:weight bold))))

     (cursor ((t (:background ,zenburn-fg :foreground ,zenburn-bg))))
     (hover-highlight ((t (:underline t :foreground "#f8f893"))))
     (menu ((t nil)))
     (mouse ((t (:inherit zenburn-foreground))))
     (scroll-bar ((t (:inherit zenburn-background-2))))
     (tool-bar ((t (:inherit zenburn-background-2))))

     (ido-first-match-face ((t (:inherit zenburn-primary-1))))
     (ido-only-match-face ((t (:inherit zenburn-primary-2))))
     (ido-subdir-face ((t (:inherit zenburn-primary-3))))

     (isearch ((t (:foreground ,zenburn-fg :background "#1e2320"
                   :weight normal))))
     (isearch-lazy-highlight-face ((t (:inherit isearch))))

     (mtorus-highlight-face ((t (:inherit zenburn-highlight-bluish))))
     (mtorus-notify-highlight-face ((t (:inherit zenburn-primary-1))))

     (apt-utils-normal-package-face
      ((t (:inherit zenburn-primary-1))))
     (apt-utils-virtual-package-face
      ((t (:inherit zenburn-primary-2))))
     (apt-utils-field-keyword-face
      ((t (:inherit font-lock-doc-face))))
     (apt-utils-field-contents-face
      ((t (:inherit font-lock-comment-face))))
     (apt-utils-summary-face
      ((t (:inherit bold))))
     (apt-utils-description-face
      ((t (:inherit default))))
     (apt-utils-version-face
      ((t (:inherit zenburn-blue-1))))
     (apt-utils-broken-face
      ((t (:inherit font-lock-warning-face))))

     (breakpoint-enabled-bitmap-face ((t (:inherit zenburn-primary-1))))
     (breakpoint-disabled-bitmap-face ((t (:inherit font-lock-comment-face))))

     (calendar-today-face ((t (:underline t :inherit zenburn-primary-2))))
     (diary-face ((t (:underline t :inherit zenburn-primary-1))))
     (holiday-face ((t (:underline t :inherit zenburn-primary-4))))

     (change-log-date-face ((t (:inherit zenburn-blue-1))))

     (comint-highlight-input ((t (:inherit zenburn-primary-1))))
     (comint-highlight-prompt ((t (:inherit zenburn-primary-2))))

     (compilation-info-face ((t (:inherit zenburn-primary-1))))
     (compilation-warning-face ((t (:inherit font-lock-warning-face))))

     ;; TODO
     ;;      (cua-rectangle-face ((t (:inherit region))))

     (custom-button-face
      ((t (:inherit fancy-widget-button-face))))
     (custom-button-pressed-face
      ((t (:inherit fancy-widget-button-pressed-face))))
     (custom-changed-face
      ((t (:inherit zenburn-blue))))
     (custom-comment-face
      ((t (:inherit font-lock-doc-face))))
     (custom-comment-tag-face
      ((t (:inherit font-lock-doc-face))))
     (custom-documentation-face
      ((t (:inherit font-lock-doc-face))))
     (custom-face-tag-face
      ((t (:inherit zenburn-primary-2))))
     (custom-group-tag-face
      ((t (:inherit zenburn-primary-1))))
     (custom-group-tag-face-1
      ((t (:inherit zenburn-primary-4))))
     (custom-invalid-face
      ((t (:inherit font-lock-warning-face))))
     (custom-modified-face
      ((t (:inherit zenburn-primary-3))))
     (custom-rogue-face
      ((t (:inhrit font-lock-warning-face))))
     (custom-saved-face
      ((t (:underline t))))
     (custom-set-face
      ((t (:inverse-video t :inherit zenburn-blue-1))))
     (custom-state-face
      ((t (:inherit font-lock-comment-face))))
     (custom-variable-button-face
      ((t (:weight bold :underline t))))
     (custom-variable-tag-face
      ((t (:inherit zenburn-primary-2))))

     (dictionary-button-face ((t (:inherit fancy-widget-button-face))))
     (dictionary-reference-face ((t (:inherit zenburn-primary-1))))
     (dictionary-word-entry-face ((t (:inherit font-lock-keyword-face))))

     (diff-header-face ((t (:inherit zenburn-highlight-subtle))))
     (diff-index-face ((t (:inherit bold))))
     (diff-file-header-face ((t (:inherit bold))))
     (diff-hunk-header-face ((t (:inherit zenburn-highlight-subtle))))

     (diff-added-face ((t (:inherit zenburn-primary-3))))
     (diff-removed-face ((t (:inherit zenburn-blue-1))))
     (diff-context-face ((t (:inherit font-lock-comment-face))))

     (emms-pbi-song-face ((t (:inherit zenburn-yellow-1))))
     (emms-pbi-current-face ((t (:inherit zenburn-primary-1))))
     (emms-pbi-mark-marked-face ((t (:inherit zenburn-primary-2))))

     (erc-action-face ((t (:weight bold))))
     (erc-bold-face ((t (:weight bold))))
     (erc-current-nick-face ((t (:inherit zenburn-primary-1))))
     (erc-dangerous-host-face ((t (:inherit font-lock-warning-face))))
     (erc-default-face ((t (:foreground ,zenburn-fg))))
     (erc-direct-msg-face ((t (:inherit erc-default-face))))
     (erc-error-face ((t (:inherit font-lock-warning-face))))
     (erc-fool-face ((t (:inherit zenburn-lowlight-1))))
     (erc-highlight-face ((t (:inherit hover-highlight))))
     (erc-input-face ((t (:inherit zenburn-yellow-1))))
     (erc-keyword-face ((t (:inherit zenburn-primary-1))))
     (erc-nick-default-face ((t (:inherit bold))))
     (erc-nick-msg-face ((t (:inherit erc-default-face))))
     (erc-notice-face ((t (:inherit zenburn-green-1))))
     (erc-pal-face ((t (:inherit zenburn-primary-3))))
     (erc-prompt-face ((t (:inherit zenburn-primary-2))))
     (erc-timestamp-face ((t (:inherit zenburn-green-2))))
     (erc-underline-face ((t (:inherit underline))))

     (highlight-current-line-face ((t (:inherit zenburn-highlight-subtle))))

     (ibuffer-deletion-face ((t (:inherit zenburn-primary-2))))
     (ibuffer-marked-face ((t (:inherit zenburn-primary-1))))
     (ibuffer-special-buffer-face ((t (:inherit font-lock-doc-face))))
     (ibuffer-help-buffer-face ((t (:inherit font-lock-comment-face))))

     (message-cited-text-face ((t (:inherit font-lock-comment-face))))
     (message-header-name-face ((t (:inherit zenburn-green-2))))
     (message-header-other-face ((t (:inherit zenburn-green-1))))
     (message-header-to-face ((t (:inherit zenburn-primary-1))))
     (message-header-from-face ((t (:inherit zenburn-primary-1))))
     (message-header-cc-face ((t (:inherit zenburn-primary-1))))
     (message-header-newsgroups-face ((t (:inherit zenburn-primary-1))))
     (message-header-subject-face ((t (:inherit zenburn-primary-2))))
     (message-header-xheader-face ((t (:inherit zenburn-green-1))))
     (message-mml-face ((t (:inherit zenburn-primary-1))))
     (message-separator-face ((t (:inherit font-lock-comment-face))))

     (gnus-header-name-face ((t (:inherit message-header-name-face))))
     (gnus-header-content-face ((t (:inherit message-header-other-face))))
     (gnus-header-from-face ((t (:inherit message-header-from-face))))
     (gnus-header-subject-face ((t (:inherit message-header-subject-face))))
     (gnus-header-newsgroups-face ((t (:inherit message-header-other-face))))

     (gnus-x-face ((t (:background ,zenburn-fg :foreground ,zenburn-bg))))

     (gnus-cite-face-1 ((t (:inherit zenburn-blue-1))))
     (gnus-cite-face-2 ((t (:inherit zenburn-blue-2))))
     (gnus-cite-face-3 ((t (:inherit zenburn-blue-3))))
     (gnus-cite-face-4 ((t (:inherit zenburn-blue-4))))

     (gnus-group-mail-3-face ((t (:inherit zenburn-primary-1))))
     (gnus-group-mail-1-empty-face ((t (:inherit defult))))
     (gnus-group-mail-2-empty-face ((t (:inherit defult))))
     (gnus-group-mail-3-empty-face ((t (:inherit zenburn-yellow-1))))
     (gnus-group-news-1-empty-face ((t (:inherit defult))))
     (gnus-group-news-2-empty-face ((t (:inherit defult))))
     (gnus-group-news-3-empty-face ((t (:inherit defult))))

     (gnus-signature-face ((t (:inherit zenburn-yellow-1))))

     (gnus-summary-selected-face
      ((t (:inherit zenburn-primary-1))))
     (gnus-summary-cancelled-face
      ((t (:inherit zenburn-highlight-alerting))))

     (gnus-summary-low-ticked-face
      ((t (:inherit zenburn-primary-2))))
     (gnus-summary-normal-ticked-face
      ((t (:inherit zenburn-primary-2))))
     (gnus-summary-high-ticked-face
      ((t (:inherit zenburn-primary-2))))

     (gnus-summary-low-unread-face
      ((t (:inherit zenburn-foreground :weight normal))))
     (gnus-summary-normal-unread-face
      ((t (:inherit zenburn-foreground :weight normal))))
     (gnus-summary-high-unread-face
      ((t (:inherit zenburn-foreground :weight bold))))

     (gnus-summary-low-read-face
      ((t (:inherit zenburn-green-1 :weight normal))))
     (gnus-summary-normal-read-face
      ((t (:inherit zenburn-green-1 :weight normal))))
     (gnus-summary-high-read-face
      ((t (:inherit zenburn-green-1 :weight bold))))

     (gnus-summary-low-ancient-face
      ((t (:inherit zenburn-blue-1 :weight normal))))
     (gnus-summary-normal-ancient-face
      ((t (:inherit zenburn-blue-1 :weight normal))))
     (gnus-summary-high-ancient-face
      ((t (:inherit zenburn-blue-1))))

     (help-argument-name ((t (:weight bold))))

     ;; See also the variable definitions at the top of this file
     (imaxima-latex-error-face ((t (:inherit font-lock-warning-face))))

     (info-xref ((t (:foreground ,zenburn-yellow-1 :weight bold))))
     (info-xref-visited ((t (:inherit info-xref :weight normal))))
     (info-header-xref ((t (:inherit info-xref))))
     (info-menu-5 ((t (:foreground ,zenburn-orange-1 :weight bold))))
     (info-node ((t (:weight bold))))
     (info-header-node ((t (:weight normal))))

     (jabber-roster-user-chatty
      ((t (:inherit zenburn-primary-1))))
     (jabber-roster-user-online
      ((t (:inherit zenburn-primary-2))))
     (jabber-roster-user-away
      ((t (:inherit font-lock-doc-face))))
     (jabber-roster-user-xa
      ((t (:inherit font-lock-comment-face))))
     (jabber-roster-user-offline
      ((t (:inherit zenburn-lowlight-1))))
     (jabber-roster-user-dnd
      ((t (:inherit zenburn-primary-5))))
     (jabber-roster-user-error
      ((t (:inherit font-lock-warning-face))))

     (jabber-title-small
      ((t (:inherit zenburn-title :height 1.2))))
     (jabber-title-medium
      ((t (:inherit jabber-title-small :height 1.2))))
     (jabber-title-large
      ((t (:inherit jabber-title-medium :height 1.2))))

     (jabber-chat-prompt-local
      ((t (:inherit zenburn-primary-1))))
     (jabber-chat-prompt-foreign
      ((t (:inherit zenburn-primary-2))))

     (jde-java-font-lock-modifier-face
      ((t (:inherit zenburn-primary-2))))
     (jde-java-font-lock-doc-tag-face
      ((t (:inherit zenburn-primary-1))))
     (jde-java-font-lock-constant-face
      ((t (:inherit font-lock-constant-face))))
     (jde-java-font-lock-package-face
      ((t (:inherit zenburn-primary-3))))
     (jde-java-font-lock-number-face
      ((t (:inherit font-lock-constant-face))))
     (jde-java-font-lock-operator-face
      ((t (:inherit font-lock-keyword-face))))
     (jde-java-font-lock-link-face
      ((t (:inherit zenburn-primary-5 :underline t))))

     (keywiz-right-face ((t (:inherit zenburn-primary-1))))
     (keywiz-wrong-face ((t (:inherit font-lock-warning-face))))
     (keywiz-command-face ((t (:inherit zenburn-primary-2))))

     (font-latex-bold-face ((t (:inherit bold))))
     (font-latex-warning-face ((t (:inherit font-lock-warning-face))))
     (font-latex-sedate-face ((t (:inherit zenburn-primary-1))))
     (font-latex-title-4-face ((t (:inherit zenburn-title))))

     (makefile-space-face ((t (:inherit font-lock-warning-face))))
     (makefile-shell-face ((t (nil))))
     ;; This does not work very well because everything that's highlighted
     ;; inside the shell region will get its own box.
     ;; (makefile-shell-face ((t (:background "#4f4f4f"
     ;;                           :box (:line-width 2 :color "#4f4f4f")))))

     (nxml-delimited-data-face ((t (:inherit font-lock-string-face))))
     (nxml-name-face ((t (:inherit zenburn-primary-1))))
     (nxml-ref-face ((t (:inherit zenburn-primary-5))))
     (nxml-delimiter-face ((t (:inherit default))))
     (nxml-text-face ((t (:inherit default))))

     (nxml-comment-content-face
      ((t (:inherit font-lock-comment-face))))
     (nxml-comment-delimiter-face
      ((t (:inherit nxml-comment-content-face))))

     (nxml-processing-instruction-target-face
      ((t (:inherit zenburn-primary-2))))
     (nxml-processing-instruction-delimiter-face
      ((t (:inherit nxml-processing-instruction-target-face))))
     (nxml-processing-instruction-content-face
      ((t (:inherit nxml-processing-instruction-target-face))))

     (nxml-cdata-section-CDATA-face
      ((t (:inherit zenburn-primary-4))))
     (nxml-cdata-section-delimiter-face
      ((t (:inherit nxml-cdata-section-CDATA-face))))
     (nxml-cdata-section-content-face
      ((t (:inherit nxml-text-face))))

     (nxml-entity-ref-name-face
      ((t (:inherit zenburn-primary-5))))
     (nxml-entity-ref-delimiter-face
      ((t (:inherit nxml-entity-ref-name-face))))
     (nxml-char-ref-number-face
      ((t (:inherit nxml-entity-ref-name-face))))
     (nxml-char-ref-delimiter-face
      ((t (:inherit nxml-entity-ref-delimiter-face))))

     (nxml-tag-delimiter-face ((t (:inherit default))))
     (nxml-tag-slash-face ((t (:inherit default))))
     (nxml-element-colon-face ((t (:inherit default))))

     (nxml-element-local-name-face ((t (:inherit zenburn-primary-1))))
     (nxml-element-prefix-face ((t (:inherit default))))
     (nxml-element-colon-face ((t (:inherit default))))

     (nxml-attribute-local-name-face
      ((t (:inherit zenburn-primary-3))))
     (nxml-namespace-attribute-prefix-face
      ((t (:inherit nxml-attribute-local-name-face))))

     (nxml-attribute-value-face
      ((t (:inherit font-lock-string-face))))
     (nxml-attribute-value-delimiter-face
      ((t (:inherit nxml-attribute-value-face))))

     (nxml-attribute-prefix-face
      ((t (:inherit default))))
     (nxml-namespace-attribute-xmlns-face
      ((t (:inherit nxml-attribute-prefix-face))))

     (nxml-attribute-colon-face
      ((t (:inherit default))))
     (nxml-namespace-attribute-colon-face
      ((t (:inherit nxml-attribute-colon-face))))

     ;; TODO
     (outline-8 ((t (:inherit default))))
     (outline-7 ((t (:inherit outline-8 :height 1.0))))
     (outline-6 ((t (:inherit outline-7 :height 1.0))))
     (outline-5 ((t (:inherit outline-6 :height 1.0))))
     (outline-4 ((t (:inherit outline-5 :height 1.0))))
     (outline-3 ((t (:inherit outline-4 :height 1.0))))
     (outline-2 ((t (:inherit outline-3 :height 1.0))))
     (outline-1 ((t (:inherit outline-2 :height 1.0))))
          
     (setnu-line-number-face ((t (:inherit zenburn-lowlight-2))))

     (speedbar-button-face ((t (:inherit zenburn-primary-1))))
     (speedbar-file-face ((t (:inherit zenburn-primary-2))))
     (speedbar-directory-face ((t (:inherit zenburn-primary-5))))
     (speedbar-tag-face ((t (:inherit font-lock-function-name-face))))
     (speedbar-highlight-face ((t (:underline t))))

     (strokes-char-face ((t (:inherit font-lock-keyword-face))))

     (todoo-item-header-face
      ((t (:inherit zenburn-primary-1))))
     (todoo-item-assigned-header-face
      ((t (:inherit zenburn-primary-2))))
     (todoo-sub-item-header-face
      ((t (:inherit zenburn-yellow-1))))

     (tuareg-font-lock-governing-face
      ((t (:inherit zenburn-primary-2))))
     (tuareg-font-lock-interactive-error-face
      ((t (:inherit font-lock-warning-face))))
     (tuareg-font-lock-interactive-output-face
      ((t (:inherit zenburn-primary-3))))
     (tuareg-font-lock-operator-face
      ((t (:inherit font-lock-operator-face))))

     (w3m-form-button-face
      ((t (:inherit widget-button-face))))
     (w3m-form-button-pressed-face
      ((t (:inherit widget-button-pressed-face))))
     (w3m-form-button-mouse-face
      ((t (:inherit widget-button-pressed-face))))
     (w3m-tab-unselected-face
      ((t (:box (:line-width 1 :style released-button)))))
     (w3m-tab-selected-face
      ((t (:box (:line-width 1 :style pressed-button)))))
     (w3m-tab-unselected-retrieving-face
      ((t (:inherit (w3m-tab-unselected-face widget-inactive-face)))))
     (w3m-tab-selected-retrieving-face
      ((t (:inherit (w3m-tab-selected-face widget-inactive-face)))))
     (w3m-tab-background-face
      ((t (:inherit zenburn-highlight-subtle))))
     (w3m-anchor-face
      ((t (:inherit zenburn-primary-1))))
     (w3m-arrived-anchor-face
      ((t (:inherit zenburn-primary-2))))
     (w3m-image-face
      ((t (:inherit zenburn-primary-4))))
     (w3m-form-face
      ((t (:inherit widget-field-face))))

     )))

(provide 'zenburn)

;;; zenburn.el ends here.
