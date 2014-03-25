;;; pgo-tempo.el --- Setup Tempo
;;
;; Filename: pgo-tempo.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor jun 11 14:32:09 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 4
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   Required feature `pgo-tempo' was not provided.
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

(defcustom pnw/use-tempo nil
  "Flags whether or not to load tempo upon startup." :type 'boolean :group 'pnw-options)

(when pnw/use-tempo
  (when (require 'tempo nil t))

  ;; tempo-x.el --- More elements for tempo
  (when (require 'tempo-x nil t))

  ;; tempo-c-cpp.el --- abbrevs for c/c++ programming
  (when (require 'tempo-c-cpp nil t))

  ;; Tempo Snippets
  ;; tempo-snippets.el is a snippet.el-like interface for tempo templates
  ;; See: http://nschum.de/src/emacs/tempo-snippets/
  (when (require 'tempo-snippets nil t))

  ;; Snippets are defined with regular TempoMode syntax:
  (tempo-define-snippet "tempo-snippets/c-for-it"
                        '(> "for (" (p "Type: " type) "::iterator " (p "Iterator: " it) " = "
                            (p "Container: " container) ".begin();" n>
                            (s it) " != " (s container) ".end(); ++" (s it) ") {" > n> r n "}" >)
                        "fori"
                        "Insert a C++ for loop iterating over an STL container."
                        nil)

  ;; Basic forms are also allowed:
  (tempo-define-snippet "tempo-snippets/java-get-set"
                        '("private " (p "Type: " type) " _" (p "Name: " var) ";\n\n"
                          > "public " (s type) " get" (upcase-initials (tempo-lookup-named 'var))
                          "() {\n"
                          > "return _" (s var)  ";\n" "}" > n n
                          > "public set" (upcase-initials (tempo-lookup-named 'var))
                          "(" (s type) " value) {\n"
                          > "_" (s var) " = value;\n" "}" > n))
  )

(provide 'pgo-tempo)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-tempo.el ends here
