;;; pgo-project.el --- Setup Project Management Integration.
;;
;; Filename: pgo-project.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor jun 11 16:45:51 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 22
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   None
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(when nil
  (require 'projman nil t);Simple source file project management
  )

(when (and nil (require 'mk-project nil t)) ;Lightweight project handling
;;;   (project-def "PNW"
;;;         '((basedir "~/justcxx/")
;;;           (src-patterns ("*.lisp" "*.c"))
;;;           (ignore-patterns ("*.elc" "*.o"))
;;;           (tags-file "~/pnw/TAGS")
;;;           (git-p t)
;;;           (compile-cmd "make")
;;;           (startup-hook myproj-startup-hook)))
  ;;
  ;; (defun myproj-startup-hook ()
  ;;   (find-file "/home/me/my-proj/foo.el"))
  (global-set-key (kbd "C-c M-p c") 'project-compile)
  (global-set-key (kbd "C-c M-p g") 'project-grep)
  (global-set-key (kbd "C-c M-p l") 'project-load)
  (global-set-key (kbd "C-c M-p u") 'project-unload)
  (global-set-key (kbd "C-c M-p f") 'project-find-file)
  (global-set-key (kbd "C-c M-p i") 'project-index)
  (global-set-key (kbd "C-c M-p s") 'project-status)
  (global-set-key (kbd "C-c M-p h") 'project-home)
  (global-set-key (kbd "C-c M-p d") 'project-dired)
  (global-set-key (kbd "C-c M-p t") 'project-tags)
  )

(when (and nil (require 'eproject nil t)) ;assign files to projects, programatically. See: http://blog.jrock.us/articles/eproject.pod
  )

;; http://www.emacswiki.org/emacs-en/ProjectBufferMode
(when (and nil
           (require 'project-buffer-mode nil t))
  ;; Microsoft Visual Studio Solution File (sln)
  (require 'sln-mode nil t)
  (require 'fsproject nil t)
  )

(provide 'pgo-project)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-project.el ends here
