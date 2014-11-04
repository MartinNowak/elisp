;;; cc-assist.el --- Development Tools and Assistance such auto-templates for CC Mode.
;; Author: Per Nordlöw <per.nordlow@gmail.com>

;; TODO - Support C++11 Initializer List
;; - Constructor:            vec(const std::initializer_list<T>& list) { passert_eq(list.size(), size()) ; std::copy(begin(list), end(list), begin(*this)); }
;; - Assignment Constructor: vec& operator = (const std::initializer_list<T>& list) { passert_eq(list.size(), size()); std::copy(begin(list), end(list), begin(*this)); }

;; TODO Support C++11 Inheriting Constructors
;; struct D1 : B1 {
;; using B1::B1; // implicitly declares D1( int )
;; int x;
;; };

;;; TODO When to use r-value refs? http://www.reddit.com/r/cpp/comments/tuvdf/where_to_use_rvalue_references_in_my_code/

;; TODO - Add list of standard exceptions. c++-insert-throw-statement, c++-insert-catch-statement.

;; TODO - Create Final (Non-Overridable) virtual function
;; TODO - Override virtual function from Base-Class

;; TODO - Ease use of type traits (e.g. is_floating_point) and template
;; metaprogramming (e.g. the enable_if template), you can specialize your
;; templates for types with particular characteristics and thus implement
;; optimizations.

;; TODO
;; Insert =>
;;   Pointer =>
;; Be sure to use const qualification for pointers where appropriate.
;; - T* x;             // Mutable/Non-constant pointer to mutable/non-constant T.
;; - const T* x;       // Mutable/Non-constant pointer to immutable/constant T.
;; - T* const x;       // Immutable/Constant pointer to mutable/non-constant T.
;; - const T* const x; // Immutable/Constant pointer to immutable/constant T.
;;
;;   Smart Pointer =>
;; This also applies to smart pointers such as unique_ptr (which you should use a lot) and shared_ptr (which you probably don’t need).
;; - shared_ptr<T> x;             // Mutable shared pointer to mutable T.
;; - shared_ptr<const T> x;       // Mutable shared pointer to immutable T.
;; - const shared_ptr<T> x;       // Immutable/Constant shared pointer to mutable/non-constant T.
;; - const shared_ptr<const T> x; // Immutable/Constant shared pointer to immutable/constant T.

;; TODO
;; Auto-Convert GCC's "typeof()" to C++11's "decltype()". Both in face `font-lock-keyword-face'.

;; TODO Add template menu support for Boost and wxWidgets classes and move these to
;; cc-assist-stl/boost/wxwidgets.el

;; TODO In c-mode and matlab-mode handle
;; tranpose of if-else if statements such as
;; if nargin >= 2
;; X = varargin{2};
;; ...
;; elseif nargin >= 1
;; X = varargin{1};
;; ...
;; end

;; TODO
;; defun c++-stl-sequencify-structure()
;; Link* begin(List& lst) { return lst.head; }
;; Link* end(List& lst) { return nullptr; }
;; Link* operator++(Link* p) { return p->next; }
;; int& operator*(Link* p) { return p->val; }

;; TODO Perfect Forward Construct Arguments such as in
;; class Blob {
;;    std::vector<std::string> m_v;
;; public:
;;    template<typename... Args> Blob(Args&&... args) : m_v(std::forward<Args>(args)...)

(require 'ectags nil t)
(require 'file-utils nil t)
(require 'power-utils nil t)
(require 'filedb nil t)
(require 'pnw-regexps nil t)
(require 'rx)
(require 'rx+)
(require 'auto-deb)
(require 'cc-assist-defs)
(require 'cc-utils)
(require 'toggle-source)
(require 'thingatpt-pnw)
(require 'charedit)
(require 'structed)
(require 'semantic/ctxt nil t)

(defun insert-indented (&rest args)
  "Insert arguments ARGS and indent region afterwards."
  (let ((begin (point)))
    (eval `(insert ,@args))
    (let ((end (point)))
      (indent-region begin end))))
(defalias 'indented-insert 'insert-indented)

(defun c-insert-indented-kill (kill)
  (insert (string-trim kill))
  (indent-region (region-beginning) (region-end))
  (hictx-generic (region-beginning) (region-end)))

(defun read-icicle-candidate-help (cand &optional face)
  (if (boundp 'icicle-nice-read-alist)
      (let* ((entry (assoc cand icicle-nice-read-alist))
             (sym (first entry))
             (face (or face
                       (when (boundp 'cc-assist-c++-symbol-face)
                         cc-assist-c++-symbol-face)))
             (sym (if face (propertize sym 'face face) sym)))
        (message (concat sym
                         " "
                         (propertize
                          (let ((props (fourth entry))) ;properties
                            (concat
                             (plist-get props :doc)
                             (let ((std (plist-get props :std)))
                               (when (eq std 'c++11) " (C++11)"))))
                          'face font-lock-doc-face)
                         )))
    (message cand))
  (sit-for 10))

(defun read-c++-symbol (prompt alist &optional face default)
  (let* ((default (or default
                      (thing-at-point 'symbol)))
         icicle-transform-function
         (icicle-candidate-help-fn 'read-icicle-candidate-help)
         ;;(icicle-candidate-action-fn 'icicle-find-ectag-action)
         ;;(icicle-sort-functions-alist ectags-sort-commands)
         (icicle-nice-read-alist alist)  ;NOTE: Ugly dynamically scoping!
         (cc-assist-c++-symbol-face face)
         (choice (completing-read (concat prompt " (default \"" default "\"): ")
                                  alist nil t nil nil default)))
    (list choice)))
;; (read-c++-symbol "C++ STL Algorithms" c++-stl-algorithms 'font-lock-function-name-face)

;; ---------------------------------------------------------------------------

(defun y-or-n-p-defaults (prompt &optional default-yes)
  (let ((char (read-char-choice (concat prompt
                                        (if default-yes
                                            " ([y], n or RET) "
                                          " (y, [n] or RET) "
                                          ))
                                (append  '(?y ?n 13)))))
    (if (eq char 13)                    ;if default argument given
        default-yes
      (eq char ?y))))
;; Use: (y-or-n-p-defaults "Do this?")
;; Use: (y-or-n-p-defaults "Do this?")
;; Use: (y-or-n-p-defaults "Do this?" t)

;; ---------------------------------------------------------------------------

(defun c-block-comment-start ()
  "C-style Block Comment Start.
- Qt style: /*!
- JavaDoc/D Style: /**"
  (cond ((eq major-mode 'd-mode)
         "/**")
        (t
         "/*!")))
;;(make-variable-buffer-local 'c-block-comment-start)

(defvar gcc-fixits
  '(
    (c++-mode "error: return type specification for constructor invalid"
              (lambda ()
                (c-beginning-of-defun)
                ;; TODO erase type definition
                ))
    (c++-mode "error: specializing member ‘\\(.*\\)’ requires ‘template<>’ syntax" ;M1: ::nameof<int8_t>
              (lambda ()
                (c-beginning-of-defun)
                (insert "template<> ")
                ))
    (c++-mode "error: to refer to a type member of a template parameter, use ‘typename \\(.*\\)’" ;M1: V:: value_type
              (lambda ()
                ;; go to error row and column
                (c-beginning-of-symbol)  ;using `semantic-ctxt-current-symbol'
                (insert "typename ")
                ))
    (c++-mode ("error: default argument given for parameter \\([0-9]\\) of ‘\\(.*\\)’" ;M1: 1, M2: void HFrame::on_fasmod_common(bool)
               "error: after previous specification in ‘\\(.*\\)’")  ; M3: void HFrame::on_fasmod_common(bool)
              (lambda ()
                (let ((n (string-to-number (match-string 1))))
                  (c-search-forward-token-balanced "(")
                  (backward-down-list)
                  (c-goto-arg n)
                  (c-beginning-of-arg)
                  (c-search-forward-token-balanced "=" 1 t)
                  (c-backward-token-balanced 1 nil t)
                  (c-forward-kill-arg 1)  ;kill rest of argument
                  ))
              )
    )
  "List of (MODE MESSAGE ACTION). ")

(defun compile-try-fix-error (&optional point)
  (catch 'fixed
    (save-excursion
      (with-current-buffer compilation-last-buffer
        (when point (goto-char point))
        (dolist (fixit gcc-fixits)
          (let* ((mode (first fixit)))
            (when (eq major-mode mode)
              (when (looking-back (second fixit))
                (when (y-or-n-p-defaults "Apply fixit?" t)
                  (funcall (third fixit))
                  (throw 'fixed t)))))
          ;; `compile-goto-error'
          )))))
(add-hook 'next-error-hook 'compile-try-fix-error)

;; ---------------------------------------------------------------------------

(defun c-header-file-name-cpp-constant (filepath &optional local)
  "Generate a C PreProcessor (CPP) Constant from the file
FILEPATH.\nSlashes are converted to double-underscores.  If LOCAL
is non-nil generate use only the local part of FILENAME to
generate the constant."
  (let ((f (if local
               (file-name-nondirectory filepath)
             filepath)))
    (upcase
     (replace-regexp-in-string
      (concat "\\(" "[/]" "\\)") "__"
      (replace-regexp-in-string
       (concat "\\(" "[\\. -]" "\\)") "_"
       (replace-regexp-in-string
        (concat "\\(" "/home/[[:alnum:]_]+/" "\\)")
        "" f)			;strip ~/
       )))))
;; Use: (c-header-file-name-cpp-constant "proj/foo.h")
;; Use: (c-header-file-name-cpp-constant "proj/foo.h" t)

(defun c-file-name-as-indentifier (filename)
  (replace-regexp-in-string "[^a-zA-Z_0-9]" "_" filename))

(defun c-header-file-name-guard-regexp (filepath &optional local)
  "Generate a regexp that matches a Standard C PreProcessor (CPP)
Header File Guard from the local part of file FILEPATH. Slashes
are converted to double-underscores."
  (let ((c (if filepath
               (c-header-file-name-cpp-constant filepath local)
             nil)))
    (concat
     ;; "#ifndef " "\\(" (when local "[[:alnum:]_]*") c "\\)" "\n"
     ;; "#define " "\\(" (when local "[[:alnum:]_]*") c "\\)" "\n"
     "^" _* "#" _* "ifndef" _+ "\\(" (when (or (not filepath) local) "[[:alnum:]_]*") c "\\)" _* "\n"
     _* "#" _* "define" _+ "\\(" (when (or (not filepath) local) "[[:alnum:]_]*") c "\\)" _* "\n"
     )))
;; Use: (c-header-file-name-guard-regexp nil)
;; Use: (c-header-file-name-guard-regexp nil t)
;; Use: (c-header-file-name-guard-regexp "proj/foo.h")
;; Use: (c-header-file-name-guard-regexp "proj/foo.h" t)

(defun c-insert-header-file-stub (&optional guard-flag cplusplus-flag local)
  "Insert a C ifndef-define block with the constant
CWD__CFILENAME_H where CWD is the Current Working Directory
upcased in which all slashes have been replaced by
double-underscores and remaining non-letter characters have been
replaced by underscores."
  (interactive (list (y-or-n-p-defaults "Insert Guard?" t)
                     (y-or-n-p-defaults "Insert C++ Guard?" t)
                     nil))
  (progn
    (let ((file buffer-file-name))
      (let ((hdr (c-header-file-name-cpp-constant file local)))
        (let ((user-hdr (unless (eq guard-flag 'old)
                          (read-from-minibuffer "C/C++ CPP Header Guard Constant(#ifndef-#define ): "
                                                hdr))))
          (progn
            (goto-char (point-min))

            (case guard-flag
              (old
               (insert-indented "#ifndef " user-hdr)
               (insert-indented "\n")
               (insert-indented "#define " user-hdr)
               (insert-indented "\n")
               )
              (t
               (insert "#pragma once\n"))
              )

            (when cplusplus-flag
              (insert-indented "#ifdef __cplusplus")
              (insert-indented "\n")
              (insert-indented "extern \"C\" {")
              (insert-indented "\n")
              (insert-indented "#endif")
              (insert-indented "\n")
              )

            (goto-char (point-max))	;go to end of buffer

            (when cplusplus-flag
              (insert-indented "\n" "#ifdef __cplusplus")
              (insert-indented "\n")
              (insert-indented "}")
              (insert-indented "\n")
              (insert-indented "#endif")
              (insert-indented "\n")
              )

            (when (eq guard-flag 'old)
              (insert-indented "#endif" "\n")
              )
            (forward-line -6)
            ))))))

(defun c-main-arguments (&optional mode)
  "C/C++/Objective-C/D main() function signature (arguments)."
  (let ((mode (or mode major-mode)))
    (case mode
      ((c-mode c++-mode)
       "int argc, const char * argv[], const char * envp[]")
      (d-mode
       "string[] args"))))

;; Insertion of C/C++ Code Template using Skeletons EmacsWiki:
;; SkeletonMode: http://www.emacswiki.org/cgi-bin/wiki/SkeletonMode
;; NOTE: YAsnippet has better usability becomes we insert template
;; arguments inline making it easier developer more aware of
;; current context.

(when (require 'skeleton nil t)

  (eval
   `(define-skeleton c-insert-main-skeleton
      ,(concat
        "Insert a C/C++ language main (" (c-main-arguments) ") {} Statement")
      ""
      > "int " "main ("
      (setq iter (skeleton-read "Arguments: " ,(c-main-arguments)))
      ")" "\n"
      "{" "\n" >
      > _ "\n"
      > "return 0;" "\n"
      "}" >))

  (define-skeleton c-insert-if-skeleton
    "Insert a C/C++ language if () {} Statement"
    ""
    > "if ("
    (setq iter (skeleton-read "Condition: ")) ") {" "\n"
    > _ "\n"
    "}" >)

  (define-skeleton c-insert-for-skeleton
    "Insert a C/C++ language for () {} Statement"
    ""
    > "for ("
    (setq init (skeleton-read "Initial Statements: ")) "; "
    (setq loop (skeleton-read "Loop Condition: ")) "; "
    (setq iter (skeleton-read "Post Iteration Statements: ")) ") {" "\n"
    > _ "\n"
    "}" >)

  (define-skeleton c-insert-while-skeleton
    "Insert a C/C++ language while () {} Statement"
    ""
    > "while ("
    (setq iter (skeleton-read "Loop Condition: ")) ") {" "\n"
    > _ "\n"
    "}" >)

  )

;; ============================================================================

;; Insertion of C/C++ Code Template

(defun c-token-indent (token)
  "Return (PRE . POST) indent status for TOKEN.
TOKEN can be either a character or a string."
  (let ((default '(t . t)))             ;default status
    (cond ((characterp token)
           (cond ((memq token '(?\r ?\n))
                  default)
                 (t
                  default))
           )
          ((stringp token)
           default)
          (t
           default)
          )))

(defun c-insert-token (token)
  "Insert C-Style TOKEN.
TOKEN can be either a character or a string."
  (interactive "sToken string: ")
  (let ((indent (c-token-indent token)))
    (when (car indent)
      (c-indent-command)) ;pre-indent
    (insert token)
    (save-excursion
      (backward-char)
      (fixup-whitespace))
    (fixup-whitespace)
    (when (cdr indent)
      (c-indent-command))               ;post-indent
    ))
(defun c-insert-number (number)
  "Insert C-Style Number Literal NUMBER."
  (interactive "nNumber: ")
  (c-insert-token (number-to-string number)))

(defun c-insert-open-brace () "Insert C-Style Opening Brace." (interactive) (c-insert-token ?{))
(defun c-insert-close-brace () "Insert C-Style Closing Brace." (interactive) (c-insert-token ?}))
(defun c-insert-braces ()
  "Insert C-Style Pair of Opening and Closing Brace."
  (interactive)
  (c-insert-open-brace)
  (forward-sexp)
  (c-insert-close-brace))

(defun c-insert-open-paren () "Insert C-Style Opening Paren." (interactive) (c-insert-token ?\())
(defun c-insert-close-paren () "Insert C-Style Closing Paren." (interactive) (c-insert-token ?\)))
(defun c-wrap-region ()
  "Insert C-Style Pair of Opening and Closing Brace."
  (interactive)
  (let ((begin (region-beginning))
        (end (region-end)))
    (goto-char end)
    (insert ")")
    (goto-char begin)
    (insert "(")))
(defun c-insert-parens ()
  "Insert C-Style Pair of Opening and Closing Paren.
C-Style variant of `paredit-wrap-round'."
  (interactive)
  (save-excursion
    (if (region-active-p)
        (let ((beg (region-beginning))
              (end (region-end)))
          (save-excursion (c-wrap-region)
                          (indent-region beg end)))
      (paredit-wrap-sexp 1 ?\( ?\))
      (when (require 'hictx nil t)
        (hictx-sexp-afpt)))))
(defalias 'c-wrap-round 'c-insert-parens)

(defun c-insert-open-hook () "Insert C-Style Opening Hook." (interactive) (c-insert-token ?\[))
(defun c-insert-close-hook () "Insert C-Style Closing Hook." (interactive) (c-insert-token ?\]))
(defun c-insert-hooks () "Insert C-Style Pair of Opening and Closing Hook."
  (interactive)
  (c-insert-open-hook)
  (forward-sexp)
  (c-insert-close-hook))

(defun d-get-ddoc-standard-sections (description)
  "Get D DDoc Standard Sections.
See also: http://dlang.org/ddoc.html"
  (interactive (list (read-string "Description: ")))
  (concat
   "/** " (replace-regexp-in-string "[\. ]*$" "." description) "\n"
   " * Params:" "\n"
   " *      x = is ..." "\n"
   " * Returns: ..." "\n"
   " * Throws: ..." "\n"
   " * Examples: ..." "\n"
   " * Deprecated: Superseded by ... ." "\n"
   " * Bugs: ..." "\n"
   " * Authors: Per Nordlöw, per.nordlow@gmail.com" "\n"
   " * Date: " display-time-string "\n" ;TODO Use format: May 19, 1975
   " * See_Also: foo, bar, http://www.digitalmars.com/d/phobos/index.html" "\n"
   " * Standards: Conforms to ..." "\n"
   " * Version: ..." "\n"
   " * License: ..." "\n"
   " * Copyright: ..." "\n"
   "*/" "\n"
   ))
;; Use: (d-get-ddoc-standard-sections "sdfd")
;; Use: (insert (d-get-ddoc-standard-sections "sdfd"))

(defun d-insert-module-stub (basename)
  (interactive)
  (goto-char (point-min))
  (when (looking-at (car (car (coolock/hash-bang))))
    (forward-line 1))
  (let ((description (read-string "Module Description: ")))
    (insert-indented (d-get-ddoc-standard-sections description)))
  (insert "\nmodule " (c-file-name-as-indentifier basename) ";\n")
  ;; See: http://stackoverflow.com/questions/6210663/what-does-static-this-outside-of-a-class-mean?rq=1
  (when (y-or-n-p-defaults "Insert Module Constructor (run on the creation of each thread, including the main threadl)?" nil)
    (insert "\nstatic this() { \n}\n"))
  (when (y-or-n-p-defaults "Insert Module Destructor (run on the destruction of each thread, including the main threadl)?" nil)
    (insert "\nstatic ~this() { \n}\n"))
  (when (y-or-n-p-defaults "Insert Shared Module Constructor (run once at the start of the program)?" nil)
    (insert "\nshared static this() { \n}\n"))
  (when (y-or-n-p-defaults "Insert Shared Module Destructor (run once at the end of the program)?" nil)
    (insert "\nshared static ~this() { \n}\n")))

(defun d-insert-struct-ddoc-standard-sections-stub (description)
  "Insert D DDoc Standard Sections."
  (interactive (list (read-string "Description: ")))
  (insert-indented (d-get-ddoc-standard-sections description)))

(defun d-insert-struct-stub (typename description)
  "Insert D struct definition. Structs in D have value semantics."
  (interactive (list (read-string "Name of struct type: ")
                     (read-string "Description for struct: " nil nil "Description: ")))
  (let ((invariant (when (and (eq major-mode 'd-mode)
                              (y-or-n-p-defaults "Insert invariant" t))
                     "invariant() { assert(true); }\n")))
    (insert-indented (concat (d-get-ddoc-standard-sections description)
                             "struct " typename " {
    int[] data;
    this(string s) {
        data.length = 42;
    }
    this(this) { // Post-blit to make a correction
        data = data.dup;
    }
    this(" typename " rhs) { // 'rhs' is a copy of the argument; do move...
    }
    this(ref const(" typename ") rhs) { // 'rhs' is an lvalue; do copy...
    }
    ref " typename " opAssign(" typename " rhs) { // 'rhs' is a copy of the argument; swap with this...
        return this;
    }
    ref " typename " opAssign(ref const(" typename ") rhs) { // 'rhs' is an lvalue; copy to this and destroy old state ...
        return this;
    }\n"
    invariant
    "}\n"))))

(defun d-insert-class-stub (typename description)
  "Insert D class definition. Classes in D have value semantics.
See http://dlang.org/memory.html#newdelete."
  (interactive (list (read-string "Name of class type: ")
                     (read-string (concat "Description for class " ": "))))
  (let ((invariant (when (and (eq major-mode 'd-mode)
                              (y-or-n-p-defaults "Insert invariant" t))
                     "invariant() { assert(true); }\n")))
    (insert-indented (concat
                      "import std.c.stdlib;
import core.exception;
import core.memory : GC;\n\n"
                      (d-get-ddoc-standard-sections description)
                      "class C {
    /// Default Constructor.
    this() {
        // Base class construction is done with super()
    }
    /// Explicit Class Instance Allocation Constructor.
    new(size_t sz) {
        void* p;
        p = std.c.stdlib.malloc(sz);
        if (!p) {
            throw new OutOfMemoryError();
        }
        GC.addRange(p, sz);
        return p;
    }
    /// Explicit Class Instance Deallocation Destructor.
    delete(void* p) {
        if (p) {
            GC.removeRange(p);
            std.c.stdlib.free(p);
        }
    }
    inout(" typename ") dup() inout {
        return new inout(" typename ")(/*...*/); // make a copy
    }
    void takeOver(" typename " rhs {
         // ... move the state of rhs to this object ...
    }\n"
    invariant
    "}\n"))))

(defun d-insert-alias-stub (a b &optional doc)
  (interactive "sSymbol Name: \nsAlias name: \nsDocumentation: ")
  (insert "\n/** " doc " */")
  (insert "\nalias " a " " b (when doc doc "") ";\n"))

(defun d-insert-unittest-stub ()
  (interactive)
  (goto-char (point-max))
  (insert "\nunittest {\n\n}\n")
  (forward-line -2))

(defun c-insert-main-stub (&optional mode)
  "Insert a C/C++/D \"main\" Program Statement."
  (interactive)
  (let ((mode (or mode major-mode)))
    (when (eq mode 'd-mode)
      (insert (or "#!/usr/bin/env rdmd-unittest-module\n\n"
                  "#!rdmd\n\n")))
    (insert (concat
             (c-block-comment-start)
             " \\file " (file-name-sans-directory buffer-file-name) "
 * \\brief
 */"))
    (insert "\n\n")

    ;; \see http://stackoverflow.com/questions/13525774/clang-and-float128-bug-error
    (when (memq mode '(c-mode c++-mode objc-mode))
      (insert "#ifdef __clang__
typedef struct { double x, y; } __float128;
extern \"C\" { extern char *gets(char *__s) { return 0; }; }
#endif\n\n"))

    (case mode
      (c-mode
       (insert "#include <stdio.h>\n"
               "#include <stdlib.h>\n"
               "#include <unistd.h>\n"))
      (c++-mode
       (insert "#include <iostream>\n"
               "#include <string>\n"
               "\n"
               "using std::cout;\n"
               "using std::endl;\n"
               "using std::hex;\n"
               "using std::dec;\n")
       )
      (d-mode
       (insert "import std.stdio, std.algorithm;\n"
               ;; "// pragma(lib, \"scid\");\n"
               ))
      )
    (insert "\n"
            (case mode
              ((c-mode
                c++-mode) "int")
              (d-mode "void"))
            " main(" (c-main-arguments mode) ")")
    (c-indent-command)
    (c-insert-open-brace)
    (insert-indented "\n")
    (when (memq mode '(c-mode c++-mode))
      (insert-indented "\nreturn 0;"))
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented "\n")
    (forward-line -2)
    (when (memq mode '(c-mode c++-mode))
      (forward-line -3))
    (c-indent-command) (end-of-line)
    ))

(defun c-insert-if-stub (expression)
  "Insert a C/C++ \"if\" Statement."
  (interactive "sCondition: ")
  (let (kill)
    (if (region-active-p)
        (let ((beg (region-beginning))
              (end (region-end)))
          (kill-region beg end)
          (setq kill (car kill-ring))
          ))
    (insert-indented "if (" expression ")")
    (c-insert-open-brace)
    (insert-indented "\n")
    (when kill
      (c-insert-indented-kill kill))
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented "\n")

    (if (zerop (length expression))
        (progn (c-backward-token-balanced 2)
               (down-list))
      (progn (forward-line -2)
             (c-indent-command)
             (end-of-line))
      )))

(defun c-insert-if-else-stub (expression)
  "Insert a C/C++ \"if-else\" Statement."
  (interactive "sCondition: ")
  (let (kill)
    (if (region-active-p)
        (let ((beg (region-beginning))
              (end (region-end)))
          (kill-region beg end)
          (setq kill (car kill-ring))
          ))
    (insert-indented "if (" expression ")")
    (c-insert-open-brace)
    (insert-indented "\n")
    (when kill
      (c-insert-indented-kill kill))
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented " else")
    (c-insert-open-brace)
    (insert-indented "\n")
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented "\n")
    (if (zerop (length expression))
        (progn (c-backward-token-balanced 4)
               (down-list))
      (progn (forward-line -4)
             (c-indent-command)
             (end-of-line))
      )
    ))

(defun c-insert-for-stub (expression)
  "Insert a C/C++ \"for\" Statement."
  (interactive "sCondition: ")
  (let (kill)
    (if (region-active-p)
        (let ((beg (region-beginning))
              (end (region-end)))
          (kill-region beg end)
          (setq kill (car kill-ring))
          ))
    (insert-indented "for (" expression ")")
    (c-insert-open-brace)
    (insert-indented "\n")
    (when kill
      (c-insert-indented-kill kill))
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented "\n")
    (if (zerop (length expression))
        (progn (c-backward-token-balanced 2)
               (down-list))
      (progn (forward-line -2)
             (c-indent-command)
             (end-of-line))
      )))

(defun d-insert-foreach-stub (range-variable &optional index-type
                                             exit-condition
                                             filter)
  "Insert a D \"foreach\" Statement.
See http://stackoverflow.com/questions/18601898/preferred-foreach-index-type/18602441?noredirect=1#18602441"
  (interactive (list (read-string "Range Variable: ")
                     (read-string "Index Type: ")
                     (read-string "Exit Condition (Function/Lambda Expression): ")
                     (read-string "Filter (Function/Lambda Expression): ")))
  (let (kill)
    (if (region-active-p)
        (let ((beg (region-beginning))
              (end (region-end)))
          (kill-region beg end)
          (setq kill (car kill-ring))
          ))
    (insert-indented "foreach ("
                     (if (zerop (length index-type))
                         ""
                       (concat index-type " "))
                     "i; " range-variable
                     (when exit-condition
                       (concat ".until!(" exit-condition ")"))
                     (when filter
                       (concat ".filter!(" filter ")"))
                     ")")
    (c-insert-open-brace)
    (insert-indented "\n")
    (when kill
      (c-insert-indented-kill kill))
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented "\n")
    (progn (forward-line -2)
           (c-indent-command)
           (end-of-line))))

(defun c-insert-while-stub (expression)
  "Insert a C/C++ \"while\" Statement."
  (interactive "sCondition: ")
  (let (kill)
    (if (region-active-p)
        (let ((beg (region-beginning))
              (end (region-end)))
          (kill-region beg end)
          (setq kill (car kill-ring))
          ))
    (insert-indented "while (" expression ")")
    (c-insert-open-brace)
    (insert-indented "\n")
    (when kill
      (c-insert-indented-kill kill))
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented "\n")
    (if (zerop (length expression))
        (progn (c-backward-token-balanced 2)
               (down-list))
      (progn (forward-line -2)
             (c-indent-command)
             (end-of-line))
      )))

(defun d-insert-with-stub (symbol)
  "Insert a D \"with\" Statement."
  (interactive "s(Qualified) Symbol: ")
  (let (kill)
    (if (region-active-p)
        (let ((beg (region-beginning))
              (end (region-end)))
          (replace-string (concat symbol ".") "" nil beg end)
          (kill-region beg end)
          (setq kill (car kill-ring))
          ))
    (insert-indented "with (" symbol ")")
    (c-insert-open-brace)
    (insert-indented "\n")
    (when kill
      (c-insert-indented-kill kill))
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented "\n")
    (if (zerop (length symbol))
        (progn (c-backward-token-balanced 2)
               (down-list))
      (progn (forward-line -2)
             (c-indent-command)
             (end-of-line))
      )))

(defun c-insert-do-while-stub (expression)
  "Insert a C/C++ \"do while\" Statement."
  (interactive "sCondition: ")
  (let (kill)
    (if (region-active-p)
        (let ((beg (region-beginning))
              (end (region-end)))
          (kill-region beg end)
          (setq kill (car kill-ring))
          ))
    (insert-indented "do")
    (c-insert-open-brace)
    (insert-indented "\n")
    (when kill
      (c-insert-indented-kill kill))
    (insert-indented "\n")
    (c-insert-close-brace)
    (insert-indented " while (" expression ");")
    (insert-indented "\n")

    (if (zerop (length expression))
        (progn (c-backward-token-balanced 2)
               (down-list))
      (progn (forward-line -2)
             (c-indent-command)
             (end-of-line))
      )))

(defun c-insert-switch-stub (expression constant)
  "Insert a C/C++ \"switch\" Statement."
  (interactive "sExpression: \nsFirst case constant: ")
  (insert-indented "switch (" expression ")")
  (insert-indented "\n")
  (c-insert-open-brace)
  (insert-indented "\n case " constant ":")
  (insert-indented "\n")
  (insert-indented "\n break;")
  (insert-indented "\n default:")
  (insert-indented "\n break;")
  (insert-indented "\n")
  (c-insert-close-brace)
  (insert-indented "\n")

  (if (zerop (length expression))
      (progn (c-backward-token-balanced 2)
             (down-list))
    (progn (forward-line -5)
           (c-indent-command)
           (end-of-line))
    )
  )

(defconst c-stubs
  '(("main" c-insert-main-stub)
    ("if" c-insert-if-stub)
    ("if-else" c-insert-if-else-stub)
    ("for" c-insert-for-stub)
    ("while" c-insert-while-stub)
    ("do" c-insert-do-while-stub)
    ("switch" c-insert-switch-stub))
  "List of pairs of trigger REGEXP and stub insert function.")

(defconst d-stubs
  '(("main" c-insert-main-stub)
    ("if" c-insert-if-stub)
    ("if-else" c-insert-if-else-stub)
    ("for" c-insert-for-stub)
    ("while" c-insert-while-stub)
    ("with" d-insert-with-stub)
    ("do" c-insert-do-while-stub)
    ("switch" c-insert-switch-stub)
    "--"
    ["Type Cast (Unsafe) (D)" c-insert-type-cast t]
    ["Convert To (Safe) (D)" d-insert-conv-to t]
    )
  "List of pairs of trigger REGEXP and stub insert function.")

(defun c-try-expand-stub-bfpt (&optional mode)
  "Try to Expand C/C++/D stub before point.
Return non-nil if a matching stub was found and expanded."
  (let ((mode (or mode major-mode)))
    (catch 'done
      (dolist (desc (cond ((eq mode 'c-mode) c-stubs)
                          ((eq mode 'd-mode) d-stubs)
                          (t c-stubs)))
        (let ((tsym (car desc)))         ;trigger symbol
          (when (looking-back (concat "\\(" tsym "\\)"
                                      "\\(" "[[:space:]]*" "(?" "[[:space:]]+" "\\)"))
            (atomic-change-group
              (kill-region (match-beginning 0)
                           (match-end 0))
              (call-interactively (cadr desc))
              )
            (throw 'done t)))))))
;; Use: (c-try-expand-stub-bfpt)

;; ============================================================================

;; Converters

(defun c++-convert-to-method-body ()
  "Take a function prototype from the class definition and convert it
to the implementation body."
  (interactive)
  (let ((class-name)
        (doit))
    (save-excursion
      (back-to-indentation)
      (setq doit (looking-at ".+(.*); *$")))
    (if doit
        (progn
          (save-excursion
            (re-search-backward "^[^ \t].+\\(\\<\\w+\\>*::\\)")
            (setq class-name (match-string-no-properties 1)))
          (back-to-indentation)
          (when (looking-at "virtual")
            (message class-name)
            (delete-region (match-beginning 0) (match-end 0)))
          (beginning-of-line)
          (re-search-forward "(")
          (re-search-backward "[ \t]")
          ;;(forward-char 1)
          (delete-horizontal-space)
          (insert " ")
          (insert class-name)
          (end-of-line)
          (delete-region (point) (- (point) 1))
          (indent-according-to-mode)
          (insert " {\n\n}\n")
          (forward-line 1))
      (message "This line does not contain a valid method declaration"))))

;; ============================================================================

;;; TODO Auto-Detect upon @ or \\ when buffer opened
(defvar c-doxygen-tag-prefix "\\"
  "Doxygen Tag Prefix")
(make-variable-buffer-local 'c-doxygen-tag-prefix)

(defun c-doxygen-tag (tag-name)
  (concat c-doxygen-tag-prefix tag-name " "))
;; (c-doxygen-tag "author")

(defun c-insert-header-template-info (filepath doxygen-info &optional c++-flag ifndef-guard)
  "Insert a C/C++ header file info at cursor position in the
current buffer. C++-FLAG is non-nil if we want a C++ header."
  (interactive "FC header file (.h): \nsAdd Doxygen header ([y]/n)?: ")
  (let ((c++-flag
         (file-match filepath 'C++-Header 'name-recog)))
    (let* ((hdr (c-header-file-name-cpp-constant buffer-file-name))
           (user-hdr (when ifndef-guard
                       (read-from-minibuffer "CPP Header Constant (#ifndef): " hdr)))
           )

      ;; doxygen
      (let ((brief (read-string "Brief Description: ")))
        (when (or (equal doxygen-info "y") (equal doxygen-info "")) ;default to yes
          (insert (c-block-comment-start) "\n * " (c-doxygen-tag "file")
                  (file-name-nondirectory filepath)) (c-indent-command)
                  (insert-indented "\n * " (c-doxygen-tag "brief") brief)
                  (insert (concat "\n * " (c-doxygen-tag "author") "Copyright (C) "
                                  (format-time-string "%Y")
                                  " Per Nordlöw (per.nordlow@gmail.com)"))
                  (c-indent-command)
                  (insert "\n * " (c-doxygen-tag "date"))
                  (insert (format-time-string "%Y-%m-%d %H:%M"))
                  (c-indent-command)
                  (insert-indented "\n *")
                  (insert-indented "\n * More details...")
                  (insert-indented "\n */\n")
                  ))

      ;; guard
      (insert-indented "\n")
      (if ifndef-guard
          (insert
           "#ifndef " user-hdr "\n"
           "#define " user-hdr "\n")
        (insert "#pragma once\n"))

      ;; c++ begin
      (unless c++-flag
        (insert-indented "\n")
        (insert-indented "#ifdef __cplusplus")
        (insert-indented "\n")
        (insert-indented "extern \"C\" {")
        (insert-indented "\n")
        (insert-indented "#endif")
        (insert-indented "\n")
        )
      )

    (insert-indented "\n")

    ;; c++ end
    (unless c++-flag
      (insert-indented "\n")
      (insert-indented "\n")
      (insert-indented "#ifdef __cplusplus")
      (insert-indented "\n")
      (insert-indented "}")
      (insert-indented "\n")
      (insert-indented "#endif")
      )

    (when ifndef-guard
      (insert-indented "\n")
      (insert "\n")
      (insert "#endif\n"))

    (when (not c++-flag)
      (forward-line -4)
      )))

;; ---------------------------------------------------------------------------

(defvar c-hdr-src-ext-alist
  '(("h" . "c")
    ("hpp" . "cpp")
    ("h++" . "c++")
    ("H" . "C")
    ("HH" . "CC")
    ("hxx" . "cxx")
    ("cpp" . "hpp")                     ;TODO Extend cdr to be a list ("hpp" "h") which are tried in given order.
    ("c++" . "h++")
    ("H" . "C")
    ("HH" . "CC")
    ("hxx". "cxx")
    )
  "Associations between header (interface) and
  source (implementation) filename-extensions for different
  programming languages, currently C and C++.")
;; Use: (cdr (assoc "h" c-hdr-src-ext-alist))
;; Use: (car (rassoc "c" c-hdr-src-ext-alist))
;; Use: (dassoc "c" c-hdr-src-ext-alist)
;; Use: (dassoc "h" c-hdr-src-ext-alist)
(defun c-toggle-ext (ext)
  "Toggle C/C++ Header or Source Extension String EXT."
  (dassoc ext c-hdr-src-ext-alist))
;; Use: (c-toggle-ext "h")
;; Use: (c-toggle-ext "c")
;; Use: (c-toggle-ext "hpp")
;; Use: (c-toggle-ext "cpp")

(defun c-toggle-header-source-file (filename)
  "Toggle to other C/C++ Header or Source File at FILENAME."
  (let* ((base (file-name-sans-extension filename))
         (ext (file-name-extension filename)))
    (find-file  (concat base "." (dassoc ext c-hdr-src-ext-alist)))))
(defalias 'c-find-other 'c-toggle-header-source-file)

;; ---------------------------------------------------------------------------

(defun c-insert-header-template (filepath c++-flag doxygen-info &optional vc-flag)
  "Insert C/C++ Header Template of the FILEPATH into current
buffer."
  (message "Creating the C/C++ header file %s..." (faze filepath 'file))
  (c-insert-header-template-info filepath doxygen-info))

(defun c-insert-source-template (filepath mode &optional add-main vc-flag)
  "Insert C/C++/D Source Template of the FILEPATH into current
buffer\n"
  (interactive "FC source file (.c): \nsAdd main() function (y/[n])?:" )
  (let* ((base (file-name-sans-extension filepath))
         (ext (file-name-extension filepath))
         (oext (c-toggle-ext ext))      ;other extension
         (oext-exist (file-exists-p (concat base "." oext)))
         )
    (progn
      (message "Creating the C/C++ source file %s..." (faze filepath 'file))
      ;; include corresponding header file
      (when oext-exist                  ;if corresponding (header) file exists
        (insert "#include \"" (file-name-nondirectory base) "." oext "\"\n\n")) ;include it
      ;; main function
      (unless oext-exist ;include main only if no corresponding header file present
        (when (or (equal add-main "y")
                  (y-or-n-p-defaults "Insert main() function? "))
          (c-insert-main-stub mode)))
      (when (and (string-equal ext "d")
                 (y-or-n-p-defaults "Insert D module definition? "))
        (d-insert-module-stub (file-name-nondirectory base))
        (d-insert-unittest-stub)))))

;; ---------------------------------------------------------------------------

(defun c-find-header-file (filepath doxygen-info)
  "Find C header file, insert some common stuff into it and
switch to it."
  (interactive "FC header file (.h): \nsAdd Doxygen header ([y]/n)?: ")
  (find-file filepath)
  (c-insert-header-template filepath nil doxygen-info))

(defun c-find-source-file (filepath add-main)
  "Find C source file, insert some common stuff into it
and switch to it."
  (interactive "FC source file (.c): \nsAdd main() function (y/[n])?:" )
  (find-file filepath)
  (c-insert-source-template filepath 'c-mode add-main))

(defun c-find-header-source-file (h-filepath c-filepath doxygen-info)
  "Create a new pair of C header-source file, and show them both
in current frame."
  (interactive "FC header file (.h): \nFC source file (.c): \nsAdd Doxygen header ([y]/n)?: ")
  (delete-other-windows)
  (split-window-vertically)
  (c-find-header-file h-filepath doxygen-info)
  ;; (save-buffer)
  (other-window 1)
  (c-find-source-file c-filepath "n")
  ;; (save-buffer)
  (other-window 1)
  )

;; ---------------------------------------------------------------------------

(defun c-auto-insert-empty-file-template (&optional filename)
  "Interactive insertion of file creation template."
  (interactive)
  (let ((filename (setq filename buffer-file-name)))
    (unless buffer-read-only
      (when (and filename
                 (buffer-empty-p))
        ;; empty buffer
        (when (file-match filename 'C-Header 'name-recog)
          (when (y-or-n-p-defaults (format "Insert C Header Template?") t)
            (c-insert-header-template filename nil "y")))
        (when (file-match filename 'C++-Header 'name-recog)
          (when (y-or-n-p-defaults (format "Insert C++ Header Template?") t)
            (c-insert-header-template filename t "y")))
        (when (file-match filename 'C-Source 'name-recog)
          (when (y-or-n-p-defaults (format "Insert C Source Template?") t)
            (c-insert-source-template filename 'c-mode)))
        (when (file-match filename 'C++-Source 'name-recog)
          (when (y-or-n-p-defaults (format "Insert C++ Source Template?") t)
            (c-insert-source-template filename 'c++-mode)))
        (when (file-match filename 'D 'name-recog)
          (when (y-or-n-p-defaults (format "Insert D Source Template?") t)
            (c-insert-source-template filename 'd-mode)))
        ))))
;; TODO Use with `auto-insert-mode'.
(add-hook 'find-file-hook 'c-auto-insert-empty-file-template t)
;; (defadvice find-file (after c-insert-template (file))
;;   (when (called-interactively-p 'any)
;;     (c-auto-insert-empty-file-template file)))
;; (ad-activate 'find-file)

(defun c-auto-insert-header-file-name-guard ()
  "Interactive insertion of C/C++ Header Filename Include Guard.
Deprecated in favor of `c-auto-insert-pragma-once'."
  (interactive)
  (unless buffer-read-only
    (when (and (cc-derived-mode-p major-mode)
               (switch-to-buffer (current-buffer) t))
      (let ((filepath buffer-file-name))
        (when (or (file-match filepath 'C-Header 'name-recog)
                  (file-match filepath 'C++-Header 'name-recog))
          (save-excursion
            (goto-char (point-min))
            (if (re-search-forward (c-header-file-name-guard-regexp nil t) nil t) ;any guard
                (let ((str1 (match-string 1))
                      (str2 (match-string 2))
                      (hc (c-header-file-name-cpp-constant filepath t))
                      )
                  ;; any named guard found
                  (when (save-match-data (not (and (string-match (concat hc "_*$") str1)
                                                   (string-match (concat hc "_*$") str2))))
                    ;; guard found but with non-matching preprocessor-constant
                    (let ((hc-full (c-header-file-name-cpp-constant filepath nil)))
                      ;; ask user to correct constant to match filename
                      (when (y-or-n-p-defaults (format "Correct Header #ifndef-#define Guard to %s "
                                                       (faze hc-full 'const)))
                        (replace-match (concat "#ifndef " hc-full "\n" "#define " hc-full "\n")))
                      )))
              ;; no guard at all found
              (goto-char (point-min))
              (c-insert-header-file-stub t nil nil)
              )))))))
;; NOTE: Disabled in f
;;(add-hook 'before-save-hook 'c-auto-insert-header-file-name-guard t)

(defun c-auto-insert-pragma-once ()
  "Interactive insertion of C/C++ Header Filename #pragma once."
  (interactive)
  (unless buffer-read-only
    (when (switch-to-buffer (current-buffer) t)
      (let ((filepath buffer-file-name))
        (when (and (file-regular-p filepath)
                   (or (file-match filepath 'C-Header 'name-recog)
                       (file-match filepath 'C++-Header 'name-recog)))
          (save-excursion
            (goto-char (point-min))
            (unless (re-search-forward "#pragma[[:space:]]+once" nil t) ;any guard
              (goto-char (point-min))
              (when (y-or-n-p-defaults
                     (format "Insert Header Guard #pragma once Guard? "))
                (if (re-search-forward (concat BOL _* "#" _*
                                               (regexp-opt '("if" "ifndef" "include"))
                                               _+) nil t) ;before first #preprocessor statement
                    (goto-char (match-beginning 0))
                  (goto-char (point-min)))
                (insert "#pragma once\n\n"))
              )))))))
(add-hook 'before-save-hook 'c-auto-insert-pragma-once t)

;; ---------------------------------------------------------------------------

(defun c-insert-general-doxygen-stub (descr &optional single-line)
  "Insert a C Doxygen-style documentation block DESCR."
  (interactive "sShort Description (single RET to skip): ")
  (when (and descr
             (> (length descr) 0))
    (if single-line
        (progn (insert (c-block-comment-start) " " descr "*/\n")
               (c-indent-command))
      (progn
        (insert-indented (c-block-comment-start) " " descr)
        (insert-indented "\n */\n")
        ))))

(defun c-insert-general-multiline-comment ()
  "Insert Multi-line Comment for structures used in C/C++."
  (interactive)
  (when (or (looking-at (concat "\\(?:\\s-*\n\\)+\\s-*" "\\_<enum\\_>"))
            (looking-at (concat "\\(?:\\s-*\n\\)+\\s-*" "\\_<typedef" _+ "\\_<enum\\_>"))
            (looking-at (concat "\\(?:\\s-*\n\\)+\\s-*" "\\_<struct\\_>"))
            (looking-at (concat "\\(?:\\s-*\n\\)+\\s-*" "\\_<typedef\\_>" _+ "struct\\_>"))
            (looking-at (concat "\\(?:\\s-*\n\\)+\\s-*" "class\\_>"))
            (looking-at (concat "\\(?:\\s-*\n\\)+\\s-*" "\\_<template\\_>"))
            (looking-at (concat "\\(?:\\s-*\n\\)+\\s-*" "\\_<" (regexp-opt '("inline" "__inline__")) "\\_>"))
            )
    (let ((descr (read-string "Brief Description (single RET to skip): ")))
      (when (and descr
                 (> (length descr) 0))
        (delete-blank-lines)
        (delete-blank-lines)
        (open-line 1)
        (end-of-line) (forward-char)
        (c-insert-general-doxygen-stub descr))
      )))
;; TODO Fix this!
;; (setq comment-insert-comment-function 'c-insert-general-multiline-comment)

;; ---------------------------------------------------------------------------

(defun c-insert-typedef-enum-stub (descr name packed alignment new-file-flag &optional strongly-typed)
  "Insert a C/C++ \"typedef enum\" Statement."
  (interactive "sShort Description: \nsName: \ns(GCC) Packed (in bytesize) ([y]/n)?: \ns(GCC) Aligned in memory (in bytes)?: \nsInsert in new file (y/[n])?: ")

  (when (equal new-file-flag "y")
    (find-file (concat name "_enum.h"))
    )

  (insert "\n")
  (c-insert-general-doxygen-stub descr)

  (insert "typedef ")
  (if (and (eq major-mode 'c++-mode)
           (or strongly-typed
               (y-or-n-p-defaults "Strongly typed? ")))
      (progn
        ;; See https://en.wikipedia.org/wiki/C%2B%2B11#Strongly_typed_enumerations
        (insert "enum class ")
        (let ((type (read-string "Strongly typed underlying class (default none): ")))
          (when (not (zerop (length (string-strip type))))
            (insert ": " type " "))))
    (insert "enum "))
  (c-indent-command)

  ;; byte-packing
  (when (or (string-equal packed "y")
            (string-equal packed ""))		;default to yes
    (insert "__attribute__ ((packed)) "))

  ;; alignment
  (when (not (string-equal alignment ""))
    (let ((num (string-to-number alignment)))
      (when (> num 0)
        (insert "__attribute__ ((aligned ("
                (number-to-string num)
                "))) "))))

  (insert-indented "{")

  (insert-indented "\n")
  (insert "\n} ")

  (insert-indented name ";")	;
  (insert-indented "\n")
  (forward-line -2)
  (c-indent-command)
  (end-of-line))

;; ---------------------------------------------------------------------------

(defun c-insert-array-stub (descr type name size &optional value alignment)
  "Insert a C/C++/D Array Statement."
  (interactive "sShort Description: \nsType: \nsName: \nsLength?: \nsValue?: \ns(GCC) Aligned in memory (in bytes)?: ")
  (insert "\n")
  (c-insert-general-doxygen-stub descr t) ;description
  (insert type " " name)                ;type and name
  (insert "[")
  (when (and size (not (string-equal size ""))) ;value
    (insert size))
  (insert "]")
  (when (and value (not (string-equal value ""))) ;value
    (insert " = " value))           ;TODO Ask for at most SIZE number of values.
  (when (and alignment (not (string-equal alignment ""))) ;alignment
    (let ((num (string-to-number alignment)))
      (when (> num 0)
        (insert " __attribute__ ((aligned ("
                (number-to-string num)
                ")))"))))
  (insert ";")
  (insert "\n")
  )

(defun c-insert-array-declaration-stub (descr type name size &optional alignment)
  "Insert a C/C++/D Array Declaration Statement."
  (interactive "sShort Description: \nsType: \nsName: \nsLength?: \ns(GCC) Aligned in memory (in bytes)?: ")
  (c-insert-array-stub descr type name size nil alignment)
  )

(defun c-insert-array-definition-stub (descr type name size &optional value alignment)
  "Insert a C/C++/D Array Definition Statement."
  (interactive "sShort Description: \nsType: \nsName: \nsLength?: \nsValue?: \ns(GCC) Aligned in memory (in bytes)?: ")
  (c-insert-array-stub descr type name size value alignment)
  )

(defun d-insert-array-definition-stub (descr var type length &optional uninitialized-flag)
  "Insert D Stack Array of given TYPE and LENGTH uninitialized.
If UNINITIALIZED-FLAG is non-nil default-initialize array (0 for
integers and nan for floating points."
  (interactive (list (read-string "Short description: ")
                     (read-string "Variable name: ")
                     (read-string "Type name: ")
                     (read-string "Array Length: ")
                     (y-or-n-p-defaults "Skip default-initialization of array values")))
  (c-indent-command)
  (when (> (length descr) 0)
    (c-insert-general-doxygen-stub descr t)) ;description
  (insert type "[" length "] " var)
  (when uninitialized-flag
    (insert " = void"))
  (insert ";")
  (c-indent-command)
  (insert-indented "\n")
  )

;; ---------------------------------------------------------------------------

(defun c-insert-typedef-struct-stub (descr name new-file-flag)
  "Insert a C \"typedef struct\" Statement."
  (interactive "sShort Description: \nsName: \nsInsert in new file (y/[n])?: ")

  (when (equal new-file-flag "y")
    (find-file (concat name ".h"))
    )

  (insert "\n")
  (c-insert-general-doxygen-stub descr)
  (insert-indented "typedef struct " name " {")
  (insert-indented "\n")
  (insert "\n} ")
  (insert-indented name ";")	;
  (insert-indented "\n")
  (forward-line -2)
  (c-indent-command)
  (end-of-line))

;; ---------------------------------------------------------------------------

(defun c-insert-function-header-stub (rtype name &optional args)
  "Insert a C Function Header."
  (interactive "nsReturn type: \nsName: \nsArguments: ")
  (insert rtype " " name "("
          (if (and args
                   (not (equal args "")))
              args
            "void")
          ")")
  (c-indent-command)
  )

(defun c-insert-function-doxygen-stub (descr rtype)
  "Insert a C Function Doxygen Documentation Block."
  (interactive "sShort Description: \nsReturn type: ")
  (insert-indented "\n" (c-block-comment-start) " " descr)
  (if (not (equal rtype "void"))
      (progn
        (insert-indented "\n * " (c-doxygen-tag "return"))
        ))
  (insert-indented "\n */\n")
  )

;; ---------------------------------------------------------------------------

(defun c-insert-function-declaration-stub (descr rtype name args)
  "Insert a C function declaration."
  (interactive "sShort Description: \nsReturn type: \nsName: \nsArguments: ")
  (c-insert-function-doxygen-stub descr rtype)
  (c-insert-function-header-stub rtype name args)
  (insert-indented ";\n")
  )

(defconst d-parameter-storage-classes
  '(
    ("none" "Parameter becomes a mutable copy of its argument")
    ("in" "Equivalent to const scope")
    ("out" "Parameter is initialized upon function entry with the default value for its type")
    ("ref" "Parameter is passed by reference")
    ("scope" "References in the parameter cannot be escaped (e.g. assigned to a global variable)")
    ("lazy" "Argument is evaluated by the called function and not by the caller")
    ("const" "Argument is implicitly converted to a const type")
    ("immutable" "Argument is implicitly converted to an immutable type")
    ("shared" "Argument is implicitly converted to a shared type")
    ("inout" "Argument is implicitly converted to an inout type")
    )
  "D Parameter Storage Classes.")

(defun c-insert-function-definition-stub (descr name
                                                &optional args rtype include-unittest mode)
  "Insert a C Function Definition."
  (interactive (list (read-string "Function Description: ")
                     (read-string "Function Name: ")
                     (read-string "Function Arguments: ")
                     (let ((default (if (memq major-mode '(d-mode
                                                           c++-mode))
                                        (faze "auto" 'keyword)
                                      (faze "void" 'type))))
                       (completing-read "Function Return Type: "
                                        '("auto" "void") nil nil nil nil
                                        default))
                     major-mode))

  (let ((mode (or mode
                  major-mode)))
    ;; Doxygen
    (if descr
        (c-insert-function-doxygen-stub descr rtype)
      (insert-indented "\n"))

    ;; D Specific Attributes
    (when (eq mode 'd-mode)
      (when (y-or-n-p-defaults "Tag function as pure (function can only access its arguments)" t) (insert "pure "))
      (when (y-or-n-p-defaults "Tag function as nothrow" t) (insert "nothrow "))
      (cond ((y-or-n-p-defaults "Tag function as @safe" t)
             (insert "@safe "))
            ((y-or-n-p-defaults "Tag function as @trusted" t)
             (insert "@trusted "))
            ((y-or-n-p-defaults "Tag function as @system" t)
             (insert "@system ")))
      ;; (completing-read-multiple "Other Function Parameter Storage Class: " d-parameter-storage-classes)
      )

    (c-insert-function-header-stub rtype name args)

    ;; Contract Conditions and Body
    (if (and (eq mode 'd-mode)
             (y-or-n-p-defaults "Insert Contract Conditions" t))
        (progn
          (insert-indented "
in {
    // assert(PRE_CONDITION, <PRE_CONDITION_FAIL_MESSAGE>);
}
out {
    // assert(POST_CONDITION, <POST_CONDITION_FAIL_MESSAGE>);
}
body {

}
")
          (forward-line -2) (c-indent-command))
      (progn (insert-indented "\n{")
             (insert-indented "\n")
             (unless (equal rtype "void")
               (insert-indented "\nreturn 0;"))
             (insert-indented "\n}")
             (insert-indented "\n")
             (forward-line -3) (c-indent-command))
      )
    ;; (save-buffer)
    ))
(defun d-insert-function-definition-stub (descr name &optional args rtype include-unittest)
  (c-insert-function-definition-stub descr name args rtype include-unittest 'd-mode))

(defun c-insert-function-declaration-definition-stub (descr rtype name args)
  "Insert a C Function Definition into the Current (C header) file and Definition into its Corresponding C Source File."
  (interactive "sShort Description: \nsReturn type: \nsName: \nsArguments: ")
  (delete-other-windows)
  (split-window-vertically)
  (c-insert-function-declaration-stub descr rtype name args)
  ;; (save-buffer)
  (other-window 1)
  (if (toggle-source-dwim)			;switch to source file if any
      (c-insert-function-definition-stub descr rtype name args)
    (delete-window) ;if no C source file present skip splitting buffers
    )
  )

;; ---------------------------------------------------------------------------

(defconst c++-operators-list
  '(("a+b" "Addition (Binary" 2
     (lambda ()
       (let* ((a (read-ectag-name-or-key "First Term Name" nil 'variable))
              (b (read-ectag-name-or-key "First Term Name" nil 'variable))))
       )
     )
    ("a-b" "Subtraction (Binary)" 2
     (lambda ()
       (let* ((a (read-ectag-name-or-key "First Term Name" nil 'variable))
              (b (read-ectag-name-or-key "First Term Name" nil 'variable))))
       ))
    ("a*b" "Multiplication (Binary)" 2
     (lambda ()
       (let* ((a (read-ectag-name-or-key "First Factor Name" nil 'variable))
              (b (read-ectag-name-or-key "First Factor Name" nil 'variable))))
       ))
    ("a/b" "Division (Binary)" 2
     (lambda ()
       (let* ((a (read-ectag-name-or-key "Nominator Name" nil 'variable))
              (b (read-ectag-name-or-key "Denominator Name" nil 'variable))))
       ))

    ("-a" "Negation (Unary)" 1
     (lambda ()
       (let* ((a (read-ectag-name-or-key "Argument Name" nil 'variable))))
       ))

    ("a==b" "Logical Equality (Binary)" 2)
    ("a!=b" "Logical InEquality (Binary)" 2)

    ("a++" "Postfix Increment (Unary)" 1)
    ("++a" "Prefix Increment (Unary)" 1)
    ("a--" "Postfix Decrement (Unary)" 1)
    ("--a" "Prefix Decrement (Unary)" 1)

    ("<<" "Output (Unary)" 1)
    (">>" "Input (Unary)" 1)
    )
  "List of C++ Overloadable Operators."
  )

(defun c++-read-operator ()
  "Read C++ Operator."
  (completing-read "C++ Operator: "
                   c++-operators-list
                   ))
;; Use: (c++-read-operator)
;; Use: (assoc (c++-read-operator) c++-operators-list)

(defun c++-insert-operator-definition-stub (descr rtype name)
  "Insert a C++ operator definition."
  (interactive (list (read-string "Short Description: ")
                     (read-ectag-name-or-key "Return type" nil 'type)
                     (c++-read-operator)))
  (if descr
      (c-insert-function-doxygen-stub descr rtype)
    (insert-indented "\n")
    )
  (c-insert-function-header-stub rtype
                                 (concat "operator " name " ") ;space is good here
                                 )
  (insert-indented "\n{")
  (insert-indented "\n")
  (if (not (equal rtype "void"))
      (progn
        (insert-indented "\nreturn 0;")
        ))
  (insert-indented "\n}")
  (insert-indented "\n")
  (forward-line -3) (c-indent-command)
  ;; (save-buffer)
  )

(defun c++11-insert-user-defined-literal-suffix-operator-stub (descr type name)
  "Insert a C++11 User Defined Literal (UDL) Operator Suffix Definition."
  (interactive (list (read-string "Short Description: ")
                     (read-ectag-name-or-key "Type" nil 'type)
                     (read-string "Operator Suffix Name: ")))
  (insert
   "constexpr " type " operator\"\" " name " (" type " a) { return a; }\n"))

(defun c++11-insert-raw-string-literal ()
  "Insert a C++11 User Defined Literal (UDL) Operator Suffix Definition."
  (interactive)
  (insert "R\"()\""))

(defun c++11-insert-range-based-for-stub ()
  "Insert a C++11 Range-Based for-Loop Stub."
  (interactive)
  (let* ((kr (when (region-active-p)
               (cons (region-beginning)
                     (region-end))))
         kill
         (evar (let ((default "e"))
                 (read-string (format "Element variable%s: "
                                      (when default
                                        (format " (default %s)"
                                                (faze default 'variable))))
                              nil nil "e")))
         (cont (unless kr
                 (read-ectag-key "Container variable" nil 'variable))))
    (when kr
      (kill-region (car kr) (cdr kr))
      (setq kill (car kill-ring)))
    (insert "for (auto " evar " : ")
    (if kr
        (c-insert-indented-kill kill)
      (insert cont))
    (insert-indented ") {")
    (insert-indented "\n")
    (insert-indented "\n}")
    (insert-indented "\n")
    (forward-line -2)
    (c-indent-command)
    (end-of-line)))

;; ---------------------------------------------------------------------------

(defun c++-insert-class-definition-stub (descr
                                         name
                                         def-ctor
                                         copy-ctor move-ctor
                                         copy-ass move-ass
                                         dtor
                                         boost-serialization-access
                                         comment &optional inherits)
  "Insert C++ Class Definition Stub."
  (interactive
   (let* ((descr (read-string "Short Description: "))
          (name (read-string "Class name: "))
          (def-ctor (y-or-n-p-defaults "Default Construct"))

          (dtor (y-or-n-p-defaults "Destruct"))
          ;; destructor choice decides default arguments for the rest of the
          ;; constructors
          (copy-ctor (and dtor (y-or-n-p-defaults "Copy Construct" dtor)))
          (move-ctor (and dtor (y-or-n-p-defaults "Move Construct" dtor)))
          (copy-ass (and dtor (y-or-n-p-defaults "Copy Assignment Construct" dtor)))
          (move-ass (and dtor (y-or-n-p-defaults "Move Assignment Construct" dtor)))
          (boost-serialization-access (y-or-n-p-defaults "Boost Serialization Access" t))

          (comment (y-or-n-p-defaults "Standard comments"))
          )
     (list descr name
           def-ctor
           copy-ctor move-ctor
           copy-ass move-ass
           boost-serialization-access
           dtor
           comment)
     ))

  (setq inherits
        (completing-read "Inherits (default none): " *ectags*
                         (lambda (tag-key) (eq ?c (ectag-get tag-key :kind))) ;filter out classes
                         nil nil))

  (if t
      (progn
        (insert-indented "\n" (c-block-comment-start) " " descr)
        (insert-indented "\n * " (c-doxygen-tag "author") user-full-name)
        (insert-indented "\n * " (c-doxygen-tag "date") display-time-string)
        (insert-indented "\n * More details here...")
        (insert-indented "\n */\n")
        ))

  (insert-indented "class " name)

  ;; insert inherited classes
  (when (not (string= inherits ""))
    (insert " : public " (ectag-get inherits :name))
    (c-assure-include (concat "\"" (ectag-get inherits :file) "\"") inherits) ;which requires this header
    )
  (when nil                             ;deprecate by C++11 delete keyword
    (unless copy-ctor
      (insert " : private boost::noncopyable") ;Note: inherit boost::noncopyable
      (c-assure-include "<boost/noncopyable.hpp>" "boost::noncopyable") ;which requires this header
      ))

  (insert-indented " {")
  (insert-indented "\npublic:")

  ;; Default Constructor
  (when comment (insert-indented "\n /// \\em Default Constructor."))
  (when def-ctor
    (insert-indented "\n " name "() { }"))

  (insert "\n")

  ;; Copy Constuctor
  (when comment (insert-indented "\n /// \\em Copy Constructor. Copy contents of \\p in to \\c this."))
  (if copy-ctor
      (insert "\n " name "(const " name "& in) { }")
    (insert "\n " name "(const " name "& in) = delete;") ;C++11
    )
  (c-indent-command)

  ;; Move Constuctor
  (when comment (insert-indented "\n /// \\em Move Constructor. Move contents of \\p in to \\c this."))
  (if move-ctor
      (insert "\n " name "(" name "&& in) { /* return std::forward(in); */ }")
    (insert "\n " name "(" name "&& in) = delete;") ;C++11
    )
  (c-indent-command)

  (insert "\n")

  ;; Assignment Operators
  ;; Alexander Stepanov doesn't advice use of self-assignment check in
  ;; Copy-Assignment Constructor as the average (correct usage case) becomes
  ;; slower.  For a cleverer solution see:
  ;; http://brskari.wordpress.com/2011/02/24/c-assignment-operator-or-how-i-learned-to-stop-worrying-and-not-check-for-self-assignment/

  ;; Copy-Assignment Constructor.
  (when comment (insert-indented "\n /// \\em Copy-Assignment Constructor. Copy contents of \\p in to \\c this."))
  (if copy-ass
      (insert "\n " name "& operator =(" name "& in) { auto* temp = new Data_Member(*in.m_data_member); swap(temp, m_data_member); delete m_data_member; return *this; }")
    (insert "\n " name "& operator =(" name "& in) = delete;") ;C++11
    )
  (c-indent-command)

  ;; Move-Assignment Constructor.
  (when comment (insert-indented "\n /// \\em Move-Assignment Constructor. Move contents of \\p in to \\c this."))
  (if move-ass
      (insert "\n " name "& operator =(const " name "&& in) { if (this == &in) { return *this; } else { return std::move(in); } }")
    (insert "\n " name "& operator =(const " name "&& in) = delete;") ;C++11
    )
  (c-indent-command)

  (insert "\n")

  (when comment (insert-indented "\n /// \\em Destructor."))
  (when dtor
    (insert-indented "\n ~" name "() { }"))

  (insert "\n")

  (when boost-serialization-access
    (when comment (insert-indented "\n /// \\em (De)Serialization (Encode/Decode)."))
    (insert-indented "\nfriend class boost::serialization::access;
    template<class Ar> void serialize(Ar& ar, const uint version) { ar & this; }")
    (c-assure-include "<boost/serialization/access.hpp>" "boost::serialization::access"))

  (insert-indented "\n protected:")
  (insert-indented "\n private:")
  (insert-indented "\n};")
  (insert-indented "\n")
  (forward-line -4)
  (c-indent-command)
  (end-of-line)
  )

(defun c++-insert-functor-definition-stub (struct-name)
  "Insert C++ Functor Struct/Class.
A C++ Functor is similar to a Haskell Monad.
When called asynchronously process-like semantics.
A proces with its own state."
  (interactive (list (read-string "Structure/Class name: ")))
  (insert
   (concat "struct " struct-name "
{
    int a = 10;
    int operator()(){return a;}
    int operator()(int n){return a+n;}
};
"))
  (indent-region (region-beginning)
                 (region-end)))

(defun c++-insert-namespace-stub (name)
  "Insert C++ Namespace NAME Stub.
If region is active wrap it in namespace NAME."
  (interactive "sNamespace: ")
  (if (region-active-p)
      (let ((beg (region-beginning))
            (end (region-end)))
        (goto-char end)        ;insert at end first because it doesn't modify beg
        (insert-indented "}\n")
        (goto-char beg)
        (insert-indented "namespace " name " {")
        (insert-indented "\n")
        )
    (insert-indented "namespace " name " {")
    (insert-indented "\n")
    (insert-indented "\n}")
    (insert-indented "\n")
    (forward-line -2))
  )

;; ---------------------------------------------------------------------------

(defconst c++-type-traits
  '(
    ;; *** Primary type categories *** (Unary)
    ;; template <class _T> struct is_void;
    ("is_integral" nil nil (:doc "Integral (integer) type." :ary 1 :std c++11))
    ("is_floating_point" nil nil (:doc "Is floating point type." :ary 1 :std c++11))
    ("is_array" nil nil (:doc "" :ary 1 :std c++11))
    ("is_pointer" nil nil (:doc "" :ary 1 :std c++11))
    ("is_lvalue_reference" nil nil (:doc "" :ary 1 :std c++11))
    ("is_rvalue_reference" nil nil (:doc "" :ary 1 :std c++11))
    ("is_member_object_pointer" nil nil (:doc "" :ary 1 :std c++11))
    ("is_member_function_pointer" nil nil (:doc "" :ary 1 :std c++11))
    ("is_enum" nil nil (:doc "" :ary 1 :std c++11))
    ("is_union" nil nil (:doc "" :ary 1 :std c++11))
    ("is_class" nil nil (:doc "" :ary 1 :std c++11))
    ("is_function" nil nil (:doc "" :ary 1 :std c++11))

    ;; *** Composite type categories *** (Unary)
    ("is_reference" nil nil (:doc "" :ary 1 :std c++11))
    ("is_arithmetic" nil nil (:doc "" :ary 1 :std c++11))
    ("is_fundamental" nil nil (:doc "" :ary 1 :std c++11))
    ("is_object" nil nil (:doc "" :ary 1 :std c++11))
    ("is_scalar" nil nil (:doc "" :ary 1 :std c++11))
    ("is_compound" nil nil (:doc "" :ary 1 :std c++11))
    ("is_member_pointer" nil nil (:doc "" :ary 1 :std c++11))

    ;; *** Type properties *** (Unary)
    ("is_const" nil nil (:doc "" :ary 1 :std c++11))
    ("is_volatile" nil nil (:doc "" :ary 1 :std c++11))
    ("is_pod" nil nil (:doc "" :ary 1 :std c++11))
    ("is_empty" nil nil (:doc "" :ary 1 :std c++11))
    ("is_polymorphic" nil nil (:doc "" :ary 1 :std c++11))
    ("is_abstract" nil nil (:doc "" :ary 1 :std c++11))
    ("has_trivial_constructor" nil nil (:doc "" :ary 1 :std c++11))
    ("has_trivial_copy" nil nil (:doc "" :ary 1 :std c++11))
    ("has_trivial_assign" nil nil (:doc "" :ary 1 :std c++11))
    ("has_trivial_destructor" nil nil (:doc "" :ary 1 :std c++11))
    ("has_nothrow_constructor" nil nil (:doc "" :ary 1 :std c++11))
    ("has_nothrow_copy" nil nil (:doc "" :ary 1 :std c++11))
    ("has_nothrow_assign" nil nil (:doc "" :ary 1 :std c++11))
    ("has_virtual_destructor" nil nil (:doc "" :ary 1 :std c++11))
    ("is_signed" nil nil (:doc "" :ary 1 :std c++11))
    ("is_unsigned" nil nil (:doc "" :ary 1 :std c++11))

    ;; *** Query Supported Operations *** (Unary)
    ;; is_constructible
    ;; is_trivially_constructible
    ;; is_nothrow_constructible
    ;; checks if a type has a constructor for specific arguments

    ;; is_default_constructible
    ;; is_trivially_default_constructible
    ;; is_nothrow_default_constructible
    ;; checks if a type has a default constructor

    ;; is_copy_constructible
    ;; is_trivially_copy_constructible
    ;; is_nothrow_copy_constructible
    ;; checks if a type has a copy constructor

    ;; is_move_constructible
    ;; is_trivially_move_constructible
    ;; is_nothrow_move_constructible
    ;; checks if a type has a move constructor

    ;; is_assignable
    ;; is_trivially_assignable
    ;; is_nothrow_assignable
    ;; checks if a type has a assignment operator for a specific argument

    ;; is_copy_assignable
    ;; is_trivially_copy_assignable
    ;; is_nothrow_copy_assignable
    ;; checks if a type has a copy assignment operator

    ;; is_move_assignable
    ;; is_trivially_move_assignable
    ;; is_nothrow_move_assignable
    ;; checks if a type has a move assignment operator

    ;; is_destructible
    ;; is_trivially_destructible
    ;; is_nothrow_destructible
    ;; checks if a type has a non-deleted destructor

    ("has_virtual_destructor" nil nil (:doc "Checks if a type has a virtual destructor" :ary 1 :std c++11))

    ;; *** Property Queries *** (Unary)
    ("alignment_of" nil nil (:doc (concat "Get " (italicize "memory alignment") " of type.") :ary 1 :std c++11))
    ("rank" nil nil (:doc (concat "Get " (italicize "rank") " of type.") :ary 1 :std c++11))
    ("extent" nil nil (:doc (concat "Get " (italicize "extent") " of type.") :ary 2 :std c++11))
    ;;template <class _T, unsigned _I = 0> struct extent;

    ;; *** Type Relationships *** (Binary)
    ;; template <class _T, class _U> struct is_same;
    ;; template <class _From, class _To> struct is_convertible;
    ;; template <class _From, class _To> struct is_base_of;

    ;; *** Transformation Type Traits *** (Unary)
    ;; **** Const-volatility specifiers ****
    ("remove_const" nil nil (:doc "" :ary 1 :std c++11))
    ("remove_volatile" nil nil (:doc "" :ary 1 :std c++11))
    ("remove_cv" nil nil (:doc "" :ary 1 :std c++11))
    ("add_const" nil nil (:doc "" :ary 1 :std c++11))
    ("add_volatile" nil nil (:doc "" :ary 1 :std c++11))
    ("add_cv" nil nil (:doc "" :ary 1 :std c++11))

    ;; **** References ****
    ("remove_reference" nil nil (:doc "" :ary 1 :std c++11))
    ("add_reference" nil nil (:doc "" :ary 1 :std c++11))

    ;; **** Pointers ****
    ("remove_pointer" nil nil (:doc "" :ary 1 :std c++11))
    ("add_pointer" nil nil (:doc "" :ary 1 :std c++11))

    ;; **** Sign modifiers ****

    ;; **** Arrays ****
    ("remove_extent" nil nil (:doc "" :ary 1 :std c++11))
    ("remove_all_extents" nil nil (:doc "" :ary 1 :std c++11))

    ;; **** Miscellaneous transformations ****
    ;; template <std::size_t _Len, std::size_t _Align> struct aligned_storage "defines the type suitable for use as uninitialized storage for types of given size"
    ;; aligned_union "defines the type suitable for use as uninitialized storage for all given types"
    ;; decay "applies type transformations as when passing a function argument by value"
    ;; enable_if "hides a function overload or template specialization based on compile-time boolean"
    ;; conditional "chooses one type or another based on compile-type boolean"
    ;; common_type "deduces the result type of a mixed-mode arithmetic expression"
    ;; underlying_type "obtains the underlying integer type for a given enumeration type"
    ;; result_of "deduces the return type of a function call expresion"
    )
  "C++ Type Traits. Defined in namespace std in C++11 or
  std::tr1. Use with std::enable_if. See
  http://en.cppreference.com/w/cpp/types and
  http://publib.boulder.ibm.com/infocenter/comphelp/v9v111/index.jsp?topic=/com.ibm.xlcpp9.aix.doc/standlib/header_type_traits.htm"
  )

(defun c++-insert-template-stub (name)
  "Insert C++ Template NAME Stub."
  (interactive "sTemplate type: ")
  (insert-indented "template <" name ">")
  (insert-indented "\n"))

(defun c++11-insert-variadic-template-stub (name)
  "Insert C++11 Variadic Template Stub."
  (interactive "sTemplate type: ")
  (insert-indented "template <" name ">")
  (insert-indented "\n"))

(defun c++-restrict-template-function ()
  )

;; TODO Use `semantic-fetch-tags', `semantic-current-tag', `semantic-tag-prototype-p'
;; Help remember syntax for template templates:
;; template<template <class> class T>
;; reuse `c++-restrict-template-function'
(defun c-templatize-thing (&optional c-type tparam thing mode)
  "Templatize C++/D THING.
 THING default to current function or class `defun'."
  (interactive)
  (save-excursion
    (let* ((mode (or mode major-mode))
           (thing (or thing 'defun))
           (bounds (bounds-of-thing-nearest-point thing)) ;suport afpt, bfpt and nearest-point

           ;; identifiers
           ;; TODO Filter out functions and variables and sort them on occurrence
           ;; Use `function' or `class' instead of `code' as context.
           (ids (set-difference (delq nil (cscan-buffer c-id-regexp nil (list bounds 'code) t nil t 'string))
                                '("return")))

           (types (or (semantic-ctxt-scoped-types (car bounds))
                      ids))

           ;; TODO pick most common type
           (default-type (car (delete-dups types)))

           (c-type (or c-type
                       (completing-read (format "Templatize on type%s: "
                                                (when default-type
                                                  (concat " (default " (faze default-type 'type) ")")))
                                        types
                                        nil nil nil nil default-type)
                       ;;(read-ectag-key "Type" nil 'type) ;match with symbol types in function
                       ))
           (tparam (or tparam
                       (let* ((default-tparam "T")
                              (str (read-string (format "Templatize %s with parameter%s: "
                                                        c-type
                                                        (when default-tparam
                                                          (concat " (default " (faze default-tparam 'type) ")"))))))
                         (if (zerop (length str))
                             default-tparam
                           str))
                       ;;(read-ectag-key "Type" nil 'type) ;match with symbol types in function
                       ))
           (concepts '("class"
                       "typename"
                       "size_t"
                       "template <class> class"))
           (default-tparam-concept (cond ((eq mode 'c++)
                                          (first concepts))
                                         ((eq mode 'd)
                                          "")
                                         (t
                                          "")))
           (tparam-concept (completing-read (format "Type of parameter %s%s: "
                                                    tparam
                                                    (if default-tparam-concept
                                                        (concat " (" (faze default-tparam-concept 'type) ")")
                                                      ""))
                                            concepts nil nil nil nil
                                            default-tparam-concept)
                           ;;(read-ectag-key "Type" nil 'type) ;match with symbol types in function
                           )
           (traits c++-type-traits)
           (default-trait nil ;; (first c++-type-traits)
             )
           (trait (read-c++-symbol (format "Type trait of parameter %s%s"
                                           tparam
                                           (if default-trait
                                               (concat " (" (faze default-trait 'type) ")")
                                             ""))
                                   traits
                                   'font-lock-class-face
                                   default-trait))
           )
      (replace-symbol c-type tparam
                      (car bounds)
                      (cdr bounds))
      (goto-char (car bounds))
      (case mode
        (c++-mode
         (insert "template <" tparam-concept " " tparam ">" "\n"))
        (d-mode
         (re-search-forward "(")
         (backward-char)
         ;; TODO for variables: (insert "template (" tparam-concept " " tparam ")!" "\n")
         (insert "(")
         (when (> (length tparam-concept) 0)
           (insert tparam-concept " "))
         (insert tparam ")")))
      ))
  (goto-char (defun-afpt-beginning-position)))

(defun c++-templatize-function (&optional source dest mode)
  "Templatize Current Function in C++."
  (interactive)
  (c-templatize-thing source dest 'defun mode))

(defun d-templatize-function (&optional source dest mode)
  "Templatize Current Function in D."
  (interactive)
  (c-templatize-thing source dest 'defun mode))

;; \see http://stackoverflow.com/questions/7782741/template-template-parameter-on-function
(defun c++-templatize-template-argument () "Templatize Current Template Argument." (interactive))
(defun c++-templatize-class () "Templatize Current Class." (interactive))
(defun c++-templatize-buffer () "Templatize Current Buffer." (interactive))
(defun c++-template-dwim ()
  (interactive)
  (if (region-active-p)
      (if (string-match (rx (: (| "class"
                                  "typename"))
                            (+ space)
                            "T")
                        (region-string))
          (c-templatize-thing nil nil nil 'c++-mode))
    (call-interactively 'c++-insert-template-stub)))

;; ---------------------------------------------------------------------------

(defun c++11-read-for-each-stub-arguments ()
  "Read C++11 For Each Expression Stub Arguments."
  (list (read-ectag-name-or-key "Container variable" nil 'variable)))

(defun c++11-read-lambda-expression-stub-arguments ()
  "Read C++11 Lambda Expression Stub Arguments."
  (list (completing-read "Capture Caller Variables (=X (X by value), &X (X by reference) or empty for none, where X defaults to all if empty): "
                         '("=" "&"))
        (read-string "Parameters (empty for none): ")
        ;; NOTE: The return type can be omitted only if the lambda function is of the
        ;; form return expression (or if the lambda returns nothing).
        (read-ectag-name-or-key "Return type (empty for auto)" nil 'type)))

(defun c++11-insert-lambda-expression-stub (capture parameters return-type)
  "Insert C++11 Lambda Expression Stub.
See http://www2.research.att.com/~bs/C++11FAQ.html#lambda"
  (interactive (c++11-read-lambda-expression-stub-arguments))
  (let ((return-flag (and return-type
                          (not (= 0 (length (string-strip return-type)))))))
    (insert "[" capture "]"
            "(" parameters ")"
            (if return-flag
                (concat "->" return-type)
              "")
            " { "
            (if return-flag "return " "")
            "; }")
    (c-indent-command)
    (backward-char 3)
    ))

(defun c++11-insert-for-each-lambda-expression-stub (container capture parameters return-type)
  "Insert C++11 For Each (std::for_each) with Lambda Expression Stub."
  (interactive (append (c++11-read-for-each-stub-arguments)
                       (c++11-read-lambda-expression-stub-arguments)))
  (c++11-insert-lambda-expression-stub capture parameters return-type))

;; TODO Support class member functions if inside class member Class::start():
;; std::thread(&Class::fun, this);
(defun c++11-insert-thread-stub (function thread-name &optional join)
  "Insert C++11 Thread FUNCTION Creation Stub using std::thread."
  (interactive (list (read-string "Thread variable name: ")
                     (read-ectag-name-or-key "Thread Function" nil 'function)
                     (yes-or-no-p "Join with calling thread?")))
  (insert-indented "std::thread" " " thread-name "(" function ");")
  (insert-indented "\n")
  (when join
    (insert-indented thread-name ".join();")
    (insert-indented "\n")
    ))

(defun c++11-insert-virtual-override-member ()
  "Insert C++11 Overriding Virtual Member Function.
Example: virtual f() override;"
  )

;; ---------------------------------------------------------------------------

(defun c++-insert-enum-stub (descr name packed alignment new-file-flag class-flag)
  "Insert a C++ Enumeration (\"enum\") Statement."
  (interactive "sShort Description: \nsName: \ns(GCC) Packed (in bytesize) ([y]/n)?: \ns(GCC) Aligned in memory (in bytes)?: \nsInsert in new file (y/[n])?: ")

  (when (equal new-file-flag "y")
    (find-file (concat name "_enum.hpp"))
    )

  (insert "\n")
  (c-insert-general-doxygen-stub descr)

  (insert-indented "enum " (when class-flag "class ") name " ")

  ;; alignment
  (if (not (string-equal alignment ""))
      (let ((num (string-to-number alignment)))
        (if (> num 0)
            (progn
              (insert "__attribute__ ((aligned ("
                      (number-to-string num)
                      "))) ")
              )
          )))
  (insert-indented "{")

  (insert-indented "\n")
  (insert "\n}")

  ;; byte-packing
  (when (or (string-equal packed "y")
            (string-equal packed ""))		;default to yes
    (insert " __attribute__ ((packed))"))

  (insert-indented ";")
  (insert-indented "\n")
  (forward-line -2)
  (c-indent-command)
  (end-of-line))

(defun c++-insert-enum-class-stub (descr name packed alignment new-file-flag)
  "Insert a C++11 Enumeration (\"enum class\") Statement."
  (interactive "sShort Description: \nsName: \ns(GCC) Packed (in bytesize) ([y]/n)?: \ns(GCC) Aligned in memory (in bytes)?: \nsInsert in new file (y/[n])?: ")
  (c++-insert-enum-stub descr name packed alignment new-file-flag t))

;; ---------------------------------------------------------------------------

(defun region-parenthesized-p ()
  "Return non-nil if region is surrounded by balanced parenthesises."
  (interactive)
  (and (eq (char-after) ?\()
       (= (region-beginning)
          (point)
          )
       (= (region-end)
          (save-excursion
            (forward-sexp)
            (point))
          )
       ))
;; Use: (region-parenthesized-p)

;;; TODO Move to relangs
(defun c-insert-function-type (r-type type-1)
  "Insert C/C++-Style Function (Pointer) Type.
Example is `R(*cmp)(T1, T2)' and
`R(*)(T1, T2)'."
  (interactive "sReturn Type: \nsFirst Argument: ")
  (insert r-type "(*)(" type-1 ")")
  )

;;; TODO Move to relangs
(defun c++11-insert-function-type (r-type type-1)
  "Insert C++11-Style Function Type.
Example std::function<R(T1,T2,...)>"
  (interactive "sReturn Type: \nsFirst Argument: ")
  (insert "std::function<" r-type "(" type-1 ")>")
  )

(defconst c++-casts
  '(("static_cast" nil nil (:doc "Value cast."))
    ("const_cast" nil nil (:doc "Set or Remove Constness."))
    ("reinterpret_cast" nil nil (:doc "Converts any pointer type to any other pointer type, even of unrelated classes."))
    ("dynamic_cast" nil nil (:doc "Try to cast any pointer to a super or sub-type using RTTI. Return 0 (nullptr) on failure."))
    ("boost::lexical_cast" nil nil (:doc "Boost Lexical Cast."))
    )
  "C++ Style Casts.")

(defun c-insert-type-cast (&optional mode)
  "Insert C++/D-style type cast."
  (interactive)
  (let ((mode (or mode major-mode)))
    (if (use-region-p)                  ;if region given
        (progn
          (goto-char (region-beginning))
          (unless (region-parenthesized-p)
            (insert-parentheses 1))))
    (let* ((cast (cond ((eq mode 'd-mode)
                        '("cast"))
                       ((eq mode 'c++-mode)
                        (let ((default-cast "static_cast"))
                          (read-c++-symbol "C++ Cast" c++-casts 'font-lock-keyword-face default-cast)))))
           (cast (if (listp cast)
                     (car cast)
                   cast))
           ;; (cast (completing-read (format "C++ Cast%s: "
           ;;                                (when default-cast
           ;;                                  (concat " (" default-cast ")")))
           ;;                        c++-casts nil t nil nil default-cast))
           (default-type (propertize "double" 'face 'font-lock-type-face))
           (type-msg (if (string-equal cast "dynamic_cast")
                         "pointed "
                       ""))
           (type (completing-read (format "Cast Destination %sType%s: "
                                          type-msg
                                          (when default-type
                                            (format " (%s)" (faze default-type 'type))))
                                  c-builtin-types nil nil nil nil default-type)))
      (when (string-equal type "boost::lexical_cast")
        (c-assure-include "<boost/lexical_cast.hpp>" "boost::lexical_cast"))
      (cond ((eq mode 'd-mode)
             (insert cast "(" type ")")
             (backward-char))
            ((eq mode 'c++-mode)
             (if (and (string-equal cast "dynamic_cast")
                      (y-or-n-p-defaults "Insert dynamic_cast as a scoped variable declaration inside the predicate of an if-statement?"))
                 (let ((var (read-string "Variable name: " nil nil "__scoped_variable__")))
                   (insert-indented
                    (concat "if (auto " var " = " cast "<" type "*>" ") {\n\n}\n"))
                   (forward-line -1)
                   (c-indent-command)
                   (forward-line -1)
                   (c-indent-command)
                   (message "Do something with non-null pointer or reference variable %s" var))
               (insert cast "<" type ">")
               (backward-char))))
      )))

(defun d-insert-conv-to (type)
  "Insert D Type Conversion using template function std.conv.to. See:
- http://forum.dlang.org/thread/tnvjjvvonuiigcrkiyac@forum.dlang.org#post-tnvjjvvonuiigcrkiyac:40forum.dlang.org
- http://stackoverflow.com/questions/19836984/enumeration-type-safety-in-d?noredirect=1#comment29498059_19836984"
  (interactive (list (read-string "Cast Destination Type: ")))
  (d-assure-import "std.conv" "to")
  (if (use-region-p)                ;if region given
      (progn
        (goto-char (region-beginning))
        (unless (region-parenthesized-p)
          (insert-parentheses 1))))
  (insert-indented "to!" type "()")
  (backward-char))

;; ---------------------------------------------------------------------------

;; \see http://stackoverflow.com/questions/1569726/difference-stdruntime-error-vs-stdexception
(defvar c++-exceptions-tree
  '((:exception "std::exception"
                :file "<stdexcept>"
                :derivations
                (:exception "std::bad_cast")
                (:exception "std::bad_alloc") ;if memory can not be allocated
                (:exception "std::bad_typeid")
                (:exception "std::bad_exception")
                ((:exception "std::logic_error"
                             :derivations
                             ((:exception "std::domain_error")
                              (:exception "std::invalid_argument")
                              (:exception "std::length_error")
                              (:exception "std::out_of_range")
                              )))
                ((:exception "std::runtime_error"  ;has argument (const std::string&)
                             :derivations
                             ((:exception "std::range_error")
                              (:exception "std::overflow_error")

                              (:exception "std::system_error")
                              ))))
    )
  "Tree Hierarchy of C++ Exceptions.")

(defconst c++-std-exceptions
  '("std::exception"
    "std::runtime_error"

    "std::domain_error"
    "std::invalid_argument"
    "std::length_error"
    "std::out_of_range"

    "std::logic_error"
    "std::bad_cast"
    "std::bad_alloc"
    "std::bad_typeid"
    "std::bad_exception"

    "std::range_error"
    "std::overflow_error"
    "std::system_error"
    )
  "Tree Hierarchy of C++ Exceptions.")

(defconst c++-default-std-exception "std::exception")

(defun c++-insert-throw-stub ()
  "Insert C++ \"throw\" Statement."
  (interactive "")
  (insert "throw;")
  )

(defun read-c++-exception-type ()
  "Completing Read C++ Exception Type."
  (completing-read "C++ Exception: " c++-std-exceptions nil nil nil nil c++-default-std-exception))

(defun c++-insert-try-catch-stub (e-type e-name)
  "Insert C++ \"try-catch\" Statement.
Exception is named E-NAME and type E-TYPE."
  (interactive (list ;; (read-ectag-name-or-key "Exception type" nil 'function)
                (read-c++-exception-type)
                (read-string "Exception name: ")
                ))
  (let* ((pnt (point))
         (kr (when (region-active-p)
               (cons (region-beginning)
                     (region-end))))
         kill)
    (when kr
      (kill-region (car kr) (cdr kr))
      (setq kill (car kill-ring)))
    (insert-indented "try {")
    (insert "\n")
    (if kr
        (c-insert-indented-kill kill))
    (insert-indented "\n} catch (const " (or e-type "") "&" (if e-name (concat " " e-name) "") ") {")
    (insert-indented "\n\n}")

    ;; TODO Functionize
    (unless (looking-forward "[[:space]]*$")
      (insert-indented "\n")
      )

    ;; Move cursor in place
    (goto-char pnt)
    (if kr
        (forward-line 3)
      (forward-line 1))
    (eol)
    (c-indent-command)
    )
  ;; (c-assure-include "<stdexcept>" "vector" "std")
  )

;; ---------------------------------------------------------------------------

;; C/C++ Refactoring Functions. TODO (defgroup c++ify-refactor)

;; Block Movers: Probably you can use ‘delete-and-extract-region’
;; instead of ‘kill-region’ plus ‘yank’.

(defun c-move-function-up ()
  "Move current C function up. Keywords: refactoring"
  (interactive)
  (save-excursion
    (c-mark-function)
    (kill-region (region-beginning) (region-end))
    (c-beginning-of-defun 1)
    (yank)))

(defun c-move-function-down ()
  "Move current C function down. Keywords: refactoring"
  (interactive)
  (save-excursion
    (c-mark-function)
    (kill-region (region-beginning) (region-end))
    (c-beginning-of-defun -1)
    (yank)))

;; (re-search-forward (concat "\\(" _1 "\\|" "\n" "\\)*")) ;ToDo: Make it support newlines aswell.
(defun c++-convert-typedef-enum-to-c++-enum ()
  "Convert C typedef \"enum\" Statement to C++ form.
Keywords: refactoring."
  (interactive)
  (if (re-search-forward (concat "typedef" _* "enum" _*) nil t) ;search for it
      (progn                            ;if search found
        (replace-match "enum " nil nil)
        (forward-sexp 1)
        (let ((beg (point)))
          (c-end-of-statement)
          (backward-char 1)
          (kill-region beg (point))
          (backward-sexp 1)
          (backward-char 1)
          (yank)
          (forward-sexp 1)
          )
        t)
    (message "No C typedef enum found!")))

(defun c-make-function-inline-and-move-to-header ()
  "Make C function inline and move it to the corresponding header file."
  (interactive)
  (save-excursion
    (c-mark-function)
    (kill-region (region-beginning) (region-end))
    (if (toggle-source-dwim-other-window)
        (progn
          (goto-char (point-max))
          (yank)
          (c-beginning-of-defun 1)
          (insert "static inline ")
          (c-beginning-of-defun 1)
          (toggle-source-dwim)
          )
      )))

(defun c-postfix-to-prefix-inc-dec ()
  "Convert Postfix Increment/Decrement Operators to Prefix Versions."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((replace-prompt "Refactor Postfix to Prefix"))
      (query-replace-regexp (rx (: (| ?\; ?\()
                                   (* space)
                                   (group (+ (in word)))
                                   (* space)
                                   (group (| "++" "--"))
                                   (* space)
                                   (| ?\; ?\))))
                            "\\2\\1")
      )))

(defun c-int-to-bool ()
  "Convert int,FALSE,TRUE to bool,false,true"
  (interactive)
  (query-replace-regexp "int" "bool")
  (query-replace-regexp "FALSE" "false")
  (query-replace-regexp "true" "true"))

(defun c-make-copy-ctor-noncopyable ()
  (interactive)
  )

(defun c-make-member-variable-global ()
  "Make member variable global."
  (interactive)
  )

(defun c-make-member-function-global ()
  "Make member function global."
  (interactive)
  )

(defun c-make-global-variable-member ()
  (interactive)
  )

(defun c-make-global-function-member ()
  (interactive)
  )

(defun class-propertize (object)
  "Fontify whole OBJECT with `font-lock-class-face'."
  (interactive)
  (put-text-property 0 (length object) 'face 'font-lock-class-face object)
  )
;; Use: (setq dummy "alpha") (class-propertize dummy)

(defun c++ify-strip-struct-c-inherit-refs ()
  "Convert &A+ -> B+ (.C+)* to A")

(defun c++ify-struct-function-to-member-function ()
  "Find decl and def of pob_do_something(pOb * pobj, ...) change it to
  pobj->op(...) and all its call are renames as
  pob_op(pOb * x, ...) to x->op(

  Return non-nil if a replace occurred."
  (interactive)
  (let ((sym (concat "\\(" c-id-regexp "\\)"))) ;C-style identifier (symbol) regexp
    (if (re-search-forward c-function-declaration-regexp nil t)
        ;; if function prefix equals type name (case-insensitivily)
        (when (eq (compare-strings (match-string 1) 0 nil
                                   (match-string 2) 0 nil t) t)
          ;; ToDo: Complete here
          (replace-match "...")
          t
          )
      nil)))
;; Use: (c++ify-struct-function-to-member-function)
;; static inline int int_add(int x, int y);

(defun keyword-fontify-string (object)
  "Fontify whole OBJECT with `font-lock-keyword-face'."
  (interactive)
  (put-text-property 0 (length object) 'face 'font-lock-keyword-face object)
  )
;; Use: (setq dummy "alpha") (keyword-fontify-string dummy)

(defun c++ify-new-function-to-constructor ()
  "Return non-nil if a replace occurred."
  (interactive)
  (let ((op "new"))
    (if (re-search-forward
         (concat "\\([[:alpha:]]\\)" "\\(\\w+\\)" "_" op "_" "\\(.*\\)" "\\_>") nil t)
        (let ((type (concat (match-string 1)
                            (capitalize (match-string 2)))))
          (keyword-fontify-string op)
          (class-propertize type)
          (let ((new (concat op " " type)))
            (if (y-or-n-p-defaults (concat "Replace " (match-string 0) " with " new "? "))
                (progn (replace-match new) t) ;return t to indicate that replace occurred
              ))
          nil))))
;; Use: (c++ify-new-function-to-constructor)
;; palt_new_from_cstr()
;; Note: Alternatively do an INTERACTIVE CALL to
;; (query-replace-regexp "\_<p\(\w+\)_new_.*\_>(" "new p\,(capitalize \1)(")

;; Strip away C-style old Polymorphism Base-Class Redirection
;; (query-replace-regexp "&?\_<\([a-zA-Z0-9_]?*\)->pobj\_>" "\")

;; ---------------------------------------------------------------------------

(defun c++11ify-to-nullptr (&optional start end)
  "C++11ify C Macro NULL to C++11's nullptr."
  (interactive)
  (save-excursion
    (unless (use-region-p)
      (goto-char (point-min)))
    (let ((replace-prompt "Rename NULL to C++11's nullptr"))
      (query-replace-symbol "NULL" "nullptr" start end
                            replace-prompt))))

(defun c++11ify-stl-begin-and-end (&optional start end)
  "Convert C++ STL \"x.begin()\" and \"x.end()\" to their, by C++11,
  preferred non-member variants \"begin(x)\" and \"end(x)\",
  where \"x\" is an STL-compliant container."
  (interactive)
  (save-excursion
    (unless (use-region-p)
      (goto-char (point-min)))
    (let ((replace-prompt ""))
      (query-replace-regexp (eval `(rx+ symbol-start
                                        (group (+ id))
                                        (* space)
                                        (| "." "->")
                                        (* space)
                                        (group (| "begin"
                                                  "end"))
                                        (* space)
                                        "(" (* space) ")"))
                            "\\2(\\1)" nil start end))))

(defun c++11ify-strongly-retype-enum ()
  "Convert a C++ Enumeration to a C++11 Strongly Typed Enumeration (Class)."
  (interactive)
  )

;; ---------------------------------------------------------------------------

(defun c++ify-min-and-max ()
  (interactive)
  (query-replace-regexp "\\_<MIN\\s-*(" "std::min(")
  (query-replace-regexp "\\_<MAX\\s-*(" "std::max(")
  )

(defun c-alloc-free-to-new-delete ()
  (interactive)
  )

(defun c++ify-c-type-casts ()
  "C++ify C Casts."
  (interactive)
  )

(defun c++ify-c-comments ()
  "C++ify C Comments."
  (interactive)
  )

(defun c++ify-buffer (fn)
  "C++ify current buffer with function FN."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (funcall fn))
    ))
;; Use: (c++ify-buffer 'c++ify-new-function-to-constructor)
;; palt_new_from_xstr()
;; palt_new_from_cstr()
;; palt_new_empty()

;; ---------------------------------------------------------------------------

;; ---------------------------------------------------------------------------

(defun fontify-assistant-alist (alist face)
  "Fontify the car of each element ALIST using FACE for side
effects only."
  (mapcar
   (lambda (x)
     (let ((x0 (car x))
           (x1 (cdr x)))
       (message-object x)
       (cons (put-text-property 0 (length x0) 'face face x0)
             x1)))
   alist))
;; Use: (fontify-assistant-alist c++-boost-smart-pointers 'font-lock-class-face)

;; ---------------------------------------------------------------------------

(defun semantic-gcc-version ()
  "Return default GCC version as a string."
  (when (and (require 'semantic/bovine/gcc nil t)
             (boundp 'semantic-gcc-setup-data))
    (cdr (assq 'version semantic-gcc-setup-data))))
;; Use: (semantic-gcc-version)
(defun semantic-gcc-version-major-number () (string-to-number (substring (semantic-gcc-version) 0 1)))
;; Use: (semantic-gcc-version-major-number)
(defun semantic-gcc-version-minor-number () (string-to-number (substring (semantic-gcc-version) 2 3)))
;; Use: (semantic-gcc-version-minor-number)
(defun semantic-gcc-version-major-and-minor () (substring (semantic-gcc-version) 0 3))
;; Use: (semantic-gcc-version-major-and-minor)

(defun semantic-gcc-c++-include-directory ()
  (when (and (require 'semantic/bovine/gcc nil t)
             (boundp 'semantic-gcc-setup-data))
    (cdr (assq '--with-gxx-include-dir semantic-gcc-setup-data))))
;; Use: (semantic-gcc-c++-include-directory)

;; ---------------------------------------------------------------------------

(defun require-c-include-headers-in-buffer (&optional buffer include-dirs)
  "Require All Header Files included by BUFFER if in a c-like mode.
If a header is not present install it using the default package
management tool, otherwise do nothing."
  (interactive "bC/C++-Header Buffer")
  (when (cc-derived-mode-p)
    (unless include-dirs
      (setq include-dirs (list "/usr/include"))
      (case major-mode
        (c++-mode
         (setq include-dirs
               (nconc include-dirs (list (semantic-gcc-c++-include-directory))))
         )))
    (save-excursion
      (when buffer (set-buffer buffer))
      (goto-char (point-min))
      (while (re-search-forward (concat "^" _* "#include" _+ "<" "\\(.*\\)" ">") nil t) ;for all includes. TODO Reuse regexp
        (let ((include-file (match-string-no-properties 1)))
          (unless (catch 'exist
                    (dolist (dir include-dirs)
                      (let ((include-full (expand-file-name include-file dir)))
                        (when (file-exists-p include-full)
                          (throw 'exist include-full))))
                    nil)
            (require-system-header-file include-file nil include-dirs)))
        ))))
;; Use: (require-c-include-headers-in-buffer)

;;(add-hook 'after-save-hook 'require-c-include-headers-in-buffer t)
;;(remove-hook 'after-save-hook 'require-c-include-headers-in-buffer)

(defun c-assure-include (hdr sym &optional query warn-flag)
  "Assure that the C header file HDR is #included in the current
buffer, and if not add (if possible together with the other
existing headers). If QUERY is non-nil the user must confirm the
operation. If WARN-FLAG is non-nil warn if header is already included."
  (save-excursion
    (if (not (re-search-backward (concat "^" _* "#include" _+ hdr) nil t))
        (when (or (not query)
                  (y-or-n-p-defaults (format "Include C/C++ header file %s providing %s? "
                                             (faze hdr 'file)
                                             (faze sym (ectag-get-kind-face sym)) ;TODO Add 'f suffix to make lookups work
                                             )))
          (insert-relative (concat "#include " hdr "\n")
                           (concat "^" _* "#" _* "include" _+ "[<\"]" ".*" "[\">]" _* "\n") 'last))
      (when warn-flag
        (message (concat "File already includes " hdr "!")))
      )))
;; Use: (c-assure-include "<vector>" "vector" "std")

(defun c-assure-include-from-symbol (sym alist &optional namespace)
  "Assure that \"#include\" Statement Corresponding to the C++/Boost
  Symbol String SYM is inserted above point."
  (save-excursion
    (let* ((full-sym (if namespace
                         (concat namespace "::" sym)
                       sym))
           (entry (assoc full-sym alist)))
      (if entry
          (let ((hdr (or (elt entry 2)        ;either header file specified
                         (concat "<" sym ">") ;or use same as name without namespace
                         )))
            (c-assure-include hdr sym t))))))
;; (re-search-backward (concat "^" _* "#include" _+ "<algorithm>") nil t)
;; (re-search-backward (concat "^" _* "#include" _+ "<.*>" _* "\n") nil t)
;; Use: (c-assure-include-from-symbol "copy" c++-stl-algorithms)
;; Use: (c-assure-include-from-symbol "copy" c++-stl-algorithms "std")

(defun d-assure-import (module-name &optional symbol-name)
  "Assure that current buffer imports MODULE-NAME optionally with symbol named SYMBOL-NAME."
  (interactive "sModule name: \nsSymbol name: ")
  (unless (save-excursion
            (or (re-search-backward
                 ;; either specific import
                 (concat "import[[:space:]\n]+"
                         (regexp-quote module-name)
                         (when (and symbol-name
                                    (length symbol-name))
                           " : "
                           symbol-name)
                         "[[:space:]\n]*,;") nil t)
                ;; or plain import
                (re-search-backward
                 (concat "import[[:space:]\n]+"
                         (regexp-quote module-name)
                         "[[:space:]\n]*,;") nil t)))
    (c-indent-command)
    (insert-indented (concat "import " module-name ": " symbol-name ";\n"))
    ))

;; ---------------------------------------------------------------------------

(eval-when-compile
  (assert-equal
   (list "std" "string")
   (let ((matcher (concat "\\`\\(std\\|__gnu_parallel\\|boost\\|tbb\\)" "::" "\\(.*\\)\\'"))
         (str "std::string"))
     (string-match matcher str)
     (list
      (match-string 1 str)
      (match-string 2 str)))))

;; ---------------------------------------------------------------------------

;; TODO Create hash-table: NAMESPACE::SYMBOL-NAME => INCLUDE-FILE and use it here.
(defun assure-c++-include-from-symbol (&optional beg end length)
  "Assure that the required C++ STL header is included in current
buffer and if not, include it (if possible where the other
includes are placed. FUN-DUMMY is needed by
`abbrev-expand-functions', see below."
  (interactive)
  (when (not (memq this-command '(undo
                                  undo-tree-undo undo-tree-visualize-undo
                                  undo-tree-redo undo-tree-visualize-redo
                                  )))
    (let* ((str (ignore-errors (and (require 'semantic-ctxt nil t)
                                    (semantic-ctxt-current-symbol)))))
      (when (and (>= (length str) 2))   ;at least one namespace/class scope level
        (let ((scope (first str))       ;namespace/scope
              (base (car (last str))))  ;symbol base name without scope
          (when (and (member scope '("std" "__gnu_parallel" "boost" "tbb"))
                     (not (zerop (length base)))
                     (at-syntax-code-p)  ;if we are in real code
                     )
            (let (case-fold-search)
              (c-assure-include-from-symbol
               base
               (append
                ;; C++ Iostream
                c++-iostream-classes
                c++-iostream-objects
                c++-iostream-types
                c++-iostream-manipulators

                ;; C++ STL
                c++-stl-containers
                c++-stl-algorithms

                ;; GNU Parallel
                c++-gnu-parallel-algorithms

                ;; Boost
                c++-boost-containers
                c++-boost-algorithms
                c++-boost-smart-pointers

                ;; Smart Pointer
                c++-smart-pointers
                c++11-smart-pointers

                ;; Intel TBB
                c++-tbb-containers
                c++-tbb-blocked-ranges
                c++-tbb-algorithms

                ;; Microsoft PPL
                c++-ppl-containers

                c-functions
                c++11-functions
                )
               scope))))))))

;; My suggestion is to make Emacs call a function each time a character
;; is inserted into buffer:
;; `pre-abbrev-expand-hook' is only called at the end of words,
;; which might even be better. `after-change-functions' is called
;; after every character.
(defun assure-c++-include-from-symbol--after-change (beg end length)
  ;; (assure-c++-include-from-symbol)
  )
(add-hook 'c++-mode-hook (lambda () (add-hook 'after-change-functions 'assure-c++-include-from-symbol--after-change t t)) t)
(when nil
  (defun assure-c++-include-from-symbol--pre-abbrev-expand (&optional fun-dummy)
    (assure-c++-include-from-symbol))
  (add-hook 'c++-mode-hook (lambda () (add-hook 'abbrev-expand-functions 'assure-c++-include-from-symbol t t)) t))

;; ---------------------------------------------------------------------------

(defun c++-insert-symbol (sym alist &optional prompt namespace face)
  "Insert symbol SYM from ALIST.
SYM is optionally defined in NAMESPACE."
  (interactive (read-c++-symbol prompt alist face))
  ;; (when namespace
  ;;   (insert namespace "::"))
  (insert-indented sym "<>") (backward-char)
  (c-assure-include-from-symbol sym alist namespace))

;;; TODO Merge `c++-insert-smart-pointer' and `c++11-insert-smart-pointer'.
(defun c++-insert-smart-pointer (ptr-type value-type name)
  (interactive (list (car (read-c++-symbol "C++ Smart Pointer" c++-smart-pointers
                                           'font-lock-class-face
                                           (caar c++-smart-pointers)))
                     (read-ectag-name-or-key "Pointer to Type" nil 'type)
                     (read-string "Pointer Instance Name: ")))
  (insert-indented ptr-type "<" value-type ">" " " name "(new " value-type ");"))
(defun c++11-insert-smart-pointer (ptr-type value-type name)
  (interactive (list (car (read-c++-symbol "C++11 Smart Pointer" c++11-smart-pointers
                                           'font-lock-class-face
                                           (caar c++11-smart-pointers)))
                     (read-ectag-name-or-key "Pointer to Type" nil 'type)
                     (read-string "Pointer Instance Name: ")))
  (insert-indented ptr-type "<" value-type ">" " " name "(new " value-type ");"))

(defun c++-insert-stl-container (sym)
  (interactive (read-c++-symbol "C++ STL Container" c++-stl-containers 'font-lock-class-face))
  (c++-insert-symbol sym c++-stl-containers nil "std"))
;; Use: (call-interactively 'c++-insert-stl-container)

(defun c++-insert-stl-algorithm (sym)
  (interactive (read-c++-symbol "C++ STL Algorithms" c++-stl-algorithms 'font-lock-function-name-face))
  (save-excursion
    (if (region-active-p)
        (progn)
      (c++-insert-symbol sym c++-stl-algorithms nil "std"))))
;; Use: (call-interactively 'c++-insert-stl-algorithm)
;; Use: (c++-insert-stl-algorithm "sort")

(defun c++-insert-iostream-class (sym)
  (interactive (read-c++-symbol "C++ IOstream Class" c++-iostream-classes 'font-lock-class-face))
  (c++-insert-symbol sym c++-iostream-classes nil "std"))
;; Use: (c++-insert-iostream-class "ifstream")

(defun c++-insert-iostream-object (sym)
  (interactive (read-c++-symbol "C++ IOstream Object" c++-iostream-objects 'font-lock-variable-name-face))
  (c++-insert-symbol sym c++-iostream-objects nil "std"))
;; Use: (c++-insert-iostream-object "cin")std::cin<>

(defun c++-insert-iostream-type (sym)
  (interactive (read-c++-symbol "C++ IOstream Type" c++-iostream-types 'font-lock-type-face))
  (c++-insert-symbol sym c++-iostream-types nil "std"))
;; Use: (c++-insert-iostream-type "fpos")

(defun c++-insert-iostream-manipulator (sym)
  (interactive (read-c++-symbol "C++ IOstream Manipulator" c++-iostream-manipulators 'font-lock-variable-name-face))
  (c++-insert-symbol sym c++-iostream-manipulators nil "std"))
;; Use: (c++-insert-iostream-manipulator "cin")

(defun c++-insert-boost-container (sym)
  (interactive (read-c++-symbol "C++ Boost Container" c++-boost-containers 'font-lock-class-face))
  (c++-insert-symbol sym c++-boost-containers nil "boost"))
;; Use: (c++-insert-boost-container "tuple")boost::tuple<>

(defun c++-insert-boost-algorithm (sym)
  (interactive (read-c++-symbol "C++ Boost Algorithms" c++-boost-algorithms 'font-lock-function-name-face))
  (c++-insert-symbol sym c++-boost-algorithms nil "boost"))
;; Use: (c++-insert-boost-algorithm "tuple")

(defun c++-insert-tbb-container (sym)
  (interactive (read-c++-symbol "C++ TBB Container" c++-tbb-containers 'font-lock-class-face))
  (c++-insert-symbol sym c++-tbb-containers nil "tbb"))
;; Use: (c++-insert-tbb-container "concurrent_vector")

(defun c++-insert-ppl-container (sym)
  (interactive (read-c++-symbol "C++ PPL Container" c++-ppl-containers 'font-lock-class-face))
  (c++-insert-symbol sym c++-ppl-containers nil "ppl"))
;; Use: (c++-insert-ppl-container "concurrent_vector")

(defun c++-insert-tbb-blocked-range (sym)
  (interactive (read-c++-symbol "C++ TBB Blocked Range" c++-tbb-blocked-ranges 'font-lock-class-face))
  (c++-insert-symbol sym c++-tbb-blocked-ranges nil "tbb"))
;; Use: (c++-insert-tbb-blocked-range "blocked_range")

(defun c++-insert-tbb-algorithm (sym)
  (interactive (read-c++-symbol "C++ TBB Algorithm" c++-tbb-algorithms 'font-lock-function-name-face))
  (c++-insert-symbol sym c++-tbb-algorithms nil "tbb"))
;; Use: (c++-insert-tbb-algorithm "parallel_do")

;; TODO If ARG C++ify C-comment to C++ if in c++-mode.
(defun c-insert-doxygen-line-comment (&optional arg)
  "Insert a Doxygen-styled line comment at the end of the current line."
  (interactive)
  (comment-dwim nil)
  (case major-mode
    (c-mode                          ;C
     (if (looking-back "[^/]/\\* ") ;after a standard C comment opening: /*
         (progn
           (backward-char)
           (insert "*<")
           (forward-char))
       (re-search-forward "/*\\**[<!]*\\s-*")
       (backward-char)))
    ((c++-mode d-mode)                        ;C++
     (cond ((looking-back "[^/]// ") ;after a standard C++ comment opening: /*
            (backward-char)
            (insert "/<")
            (forward-char))
           ((looking-back "[^/]/\\* ") ;after a standard C comment opening: /*
            (backward-char)
            (insert "*<")
            (forward-char))
           (t
            (re-search-forward (concat "/*" "\\**" "[<!]*" _?))
            )))
    (t
     nil)))

;; TODO Call c-insert-doxygen-line-comment if we are standing after a variable declaration/definition.
(defun c-end-of-doxygen-line-comment ()
  "Go to end of enhanced (Doxygen) line comments."
  (when (cc-derived-mode-p)
    (unless (looking-back _1)
      (re-search-forward (concat "/*\\**" "[<!]*"
                                 "\\("
                                 _*
                                 "\\_<" ;text already present
                                 "\\|"
                                 " "
                                 "\\)")))))

(defadvice comment-dwim (after end-of-c-doxygen-line activate)
  "Adjust cursor to correct position of enhanced comments."
  (c-end-of-doxygen-line-comment))
(ad-activate 'comment-dwim)

(defun c-insert-doxygen-group-comment (group-doc)
  "Insert a Doxygen-styled group."
  (interactive "sDocumentation for group: ")
  (insert-indented "" (c-block-comment-start) "")
  (insert-indented "\n* " (c-doxygen-tag "name") group-doc)
  (insert-indented "\n*/")
  (insert-indented "\n/* @{ */")
  (insert-indented "\n\n/* @} */")
  (insert "\n")
  (forward-line -2)
  (beginning-of-line) (c-indent-command))

(defun c-insert-embedded-gdb-breakpoint ()
  "Embed GDB Breakpoint."
  (interactive)
  (cond ((and (looking-back "^[[:space:]]*")
              (looking-at "[[:space:]]*$"))
         (insert-indented "EMBED_BREAKPOINT;"))
        ((looking-back "^[[:space:]]*")
         (insert-indented "EMBED_BREAKPOINT; "))
        ((looking-at "[[:space:]]*$")
         (insert " EMBED_BREAKPOINT;"))))

(defun d-insert-pragma-msg (message)
  "Insert DMD's own pragma(msg, MESSAGE)"
  (interactive "sMessage: ")
  (insert-indented "pragma(msg, \"" message "\");\n"))

(defun d-insert-pragma-lib (library-name)
  "Insert DMD's own pragma(lib, LIBRARY-NAME).
See http://forum.dlang.org/thread/mailman.695.1349857389.5162.digitalmars-d@puremagic.com."
  (interactive "sLibrary Name (without lib prefix, for instance dl for libdl): ")
  (insert-indented "pragma(lib, \"" library-name "\");\n"))

(defun d-insert-compiles-trait (expr)
  "Insert D Trait that checks if EXPR compiles."
  (interactive "sD Expression: ")
  (insert-indented "__traits(compiles, { " expr " } );\n"))

(defun c-insert-pragma-gcc-diagnostic-ignored ()
  "Insert #pragma GCC diagnostic ignored \"-Wall\""
  (interactive)
  (insert-indented "#pragma GCC diagnostic ignored \"-Wall\"\n"))

(defun d-insert-visual-c++-pragma-comment-lib (library-name)
  "Clang supports the Microsoft #pragma comment(lib, \"foo.lib\")
  feature for automatically linking against the specified
  library. Currently this feature only works with the Visual C++
  linker."
  (interactive "sLibrary Name (without .lib suffix, for instance dl for libdl): ")
  (insert-indented "#pragma comment(lib, \"" library-name ".lib\")\n"))

(defun d-insert-visual-c++-pragma-comment-linker (library-name)
  "Clang supports the Microsoft #pragma comment(linker,
  \"/flag:foo\") feature for adding linker flags to COFF object
  files. The user is responsible for ensuring that the linker
  understands the flags."
  (interactive "sLibrary Name (without .lib suffix, for instance dl for libdl): ")
  (insert-indented "#pragma comment(lib, \"/flag:" library-name "\")\n"))

(defun d-insert-static-assert (expr)
  (interactive "sAssert Expression: ")
  (insert-indented "static assert(" expr ");\n"))

(defun d-insert-static-map (name)
  (interactive "sMap Variable name: ")
  (insert-indented "enum " name " = [ 0 : 'a', ];\n"))
(defalias 'd-insert-static-hash-table 'd-insert-static-map)

(defun d-insert-debug-print (args)
  (interactive "sPrint (writeln) Arguments: ")
  (d-assure-import "std.stdio" "writeln")
  (insert-indented " debug writeln(" args ");\n"))

(defun c++11-insert-static-assert (expr message)
  "See http://dl.dropbox.com/u/13100941/C%2B%2B11.pdf"
  (interactive "sAssert Expression: \nsAssert Failure Message: ")
  (insert-indented "static_assert(" expr ", " message ");\n"))

(defun d-insert-import-file-string (filename var)
  "Insert D's auto s = import(FILE)."
  (interactive "sBinary file (string contents): \nsString Variable name: ")
  (insert-indented "string " var " = import(" filename ");\n"))

(defun d-insert-import-module-function (module function)
  "Insert D's import MODULE : FUNCTION;."
  (interactive "sModule name: \nsFunction name: "))

(defun d-insert-scoped-stack-allocation-instance (var type)
  "Insert D scoped allocation on stack of type TYPE reference by the variable VAR.
See http://dlang.org/memory.html#stackclass"
  (interactive "sVariable name: \nsType name: ")
  (insert-indented "scope " var " = new " type "();")
  (insert-indented "\n")
  )

(defconst d-versions
  '(("DigitalMars" . "DMD (Digital Mars D) is the compiler")
    ("GNU" . "GDC (GNU D Compiler) is the compiler")
    ("LDC" . "LDC (LLVM D Compiler) is the compiler")
    ("SDC" . "SDC (Stupid D Compiler) is the compiler")
    ("Windows" . "Microsoft Windows systems")
    ("Win32" . "Microsoft 32-bit Windows systems")
    ("Win64" . "Microsoft 64-bit Windows systems")
    ("linux" . "All Linux systems")
    ("OSX" . "Mac OS X")
    ("FreeBSD" . "FreeBSD")
    ("OpenBSD" . "OpenBSD")
    ("NetBSD" . "NetBSD")
    ("DragonFlyBSD" . "DragonFlyBSD")
    ("BSD" . "All other BSDs")
    ("Solaris" . "Solaris")
    ("Posix All" . "POSIX systems (includes Linux, FreeBSD, OS X, Solaris, etc.)")
    ("AIX" . "IBM Advanced Interactive eXecutive OS")
    ("Haiku The" . "Haiku operating system")
    ("SkyOS The" . "SkyOS operating system")
    ("SysV3 System" . "V Release 3")
    ("SysV4 System" . "V Release 4")
    ("Hurd" . "GNU Hurd")
    ("Android" . "The Android platform")
    ("Cygwin The" . "Cygwin environment")
    ("MinGW" . "The MinGW environment")
    ("X86" . "Intel and AMD 32-bit processors")
    ("X86_64" . "Intel and AMD 64-bit processors")
    ("ARM" . "The ARM architecture (32-bit) (AArch32 et al)")
    ("ARM_Thumb" . "ARM in any Thumb mode")
    ("ARM_SoftFloat" . "The ARM soft floating point ABI")
    ("ARM_SoftFP" . "The ARM softfp floating point ABI")
    ("ARM_HardFloat" . "The ARM hardfp floating point ABI")
    ("AArch64" . "The Advanced RISC Machine architecture (64-bit)")
    ("PPC" . "The PowerPC architecture, 32-bit")
    ("PPC_SoftFloat" . "The PowerPC soft float ABI")
    ("PPC_HardFloat" . "The PowerPC hard float ABI")
    ("PPC64" . "The PowerPC architecture, 64-bit")
    ("IA64" . "The Itanium architecture (64-bit)")
    ("MIPS32" . "The MIPS architecture, 32-bit")
    ("MIPS64" . "The MIPS architecture, 64-bit")
    ("MIPS_O32" . "The MIPS O32 ABI")
    ("MIPS_N32" . "The MIPS N32 ABI")
    ("MIPS_O64" . "The MIPS O64 ABI")
    ("MIPS_N64" . "The MIPS N64 ABI")
    ("MIPS_EABI" . "The MIPS EABI")
    ("MIPS_SoftFloat" . "The MIPS soft-float ABI")
    ("MIPS_HardFloat" . "The MIPS hard-float ABI")
    ("SPARC" . "The SPARC architecture, 32-bit")
    ("SPARC_V8Plus" . "The SPARC v8+ ABI")
    ("SPARC_SoftFloat" . "The SPARC soft float ABI")
    ("SPARC_HardFloat" . "The SPARC hard float ABI")
    ("SPARC64" . "The SPARC architecture, 64-bit")
    ("S390" . "The System/390 architecture, 32-bit")
    ("S390X" . "The System/390X architecture, 64-bit")
    ("HPPA" . "The HP PA-RISC architecture, 32-bit")
    ("HPPA64" . "The HP PA-RISC architecture, 64-bit")
    ("SH" . "The SuperH architecture, 32-bit")
    ("SH64" . "The SuperH architecture, 64-bit")
    ("Alpha" . "The Alpha architecture")
    ("Alpha_SoftFloat" . "The Alpha soft float ABI")
    ("Alpha_HardFloat" . "The Alpha hard float ABI")
    ("LittleEndian" . "Byte order, least significant first")
    ("BigEndian" . "Byte order, most significant first")
    ("D_Coverage" . "Code coverage analysis instrumentation (command line switch -cov) is being generated")
    ("D_Ddoc" . "Ddoc documentation (command line switch -D) is being generated")
    ("D_InlineAsm_X86" . "Inline assembler for X86 is implemented")
    ("D_InlineAsm_X86_64" . "Inline assembler for X86-64 is implemented")
    ("D_LP64" . "Pointers are 64 bits (command line switch -m64). (Do not confuse this with C's LP64 model)")
    ("D_X32" . "Pointers are 32 bits, but words are still 64 bits (x32 ABI) (This can be defined in parallel to X86_64)")
    ("D_HardFloat" . "The target hardware has a floating point unit")
    ("D_SoftFloat" . "The target hardware does not have a floating point unit")
    ("D_PIC" . "Position Independent Code (command line switch -fPIC) is being generated")
    ("D_SIMD" . "Vector extensions (via __simd) are supported")
    ("D_Version2" . "This is a D version 2 compiler")
    ("D_NoBoundsChecks" . "Array bounds checks are disabled (command line switch -noboundscheck)")
    ("unittest" . "Unit tests are enabled (command line switch -unittest)")
    ("assert" . "assert expressions are enabled")
    ("none" . "Never defined\\; used to just disable a section of code")
    ("all" . "Always defined\\; used as the opposite of none")
    )
  "Predefined D Versions. See: http://dlang.org/version.html#PredefinedVersions")

(defun icicle-find-d-version-candidate-help (cand)
  "Get help (documentation) for DMD Version Identifier Candidate CAND."
  (let ((entry (if (boundp 'd-version-option-candidates)
                   (assoc cand d-version-option-candidates)
                 cand)))
    (message (cond ((stringp entry)
                    entry)
                   ((consp entry)
                    (if (cdr entry)
                        (concat (faze (car entry) 'var)
                                ": "
                                (faze (cdr entry) 'doc))
                      (car entry))))))
  (sit-for 4))

(defun read-d-version ()
  (let* ((icicle-candidate-help-fn 'icicle-find-d-version-candidate-help)
         (d-version-option-candidates d-versions))
    (completing-read "D Version Identifier: " d-versions)))
;;; Use: (read-d-version)

(defun d-insert-version (version)
  "Insert a D Versioned Statement.
See http://dlang.org/version.html"
  (interactive (list (read-d-version)))
  (c-indent-command)
  (insert-indented (concat "version(" version ") { }"))
  (backward-char 3))

(defconst d-string-types
  '(("UTF-8" "string")
    ("UTF-16" "wstring")
    ("UTF-32" "dstring")
    )
  "D Strings Types.")

(defun d-insert-string-type (kind)
  "Insert D string (type)."
  (interactive (list (second (assoc (completing-read "String Variant: " d-string-types)
                                    d-string-types))))
  (when kind
    (c-indent-command)
    (insert-indented kind)))

(defun d-insert-map-reduce-expression (arguments map-expression reduce-expression)
  "Insert D map-reduce expression."
  (interactive (let ((args (read-strings "Map-Reduce Argument (Variable) Names")))
                 (list
                  args
                  (read-string (format "Reduce Expression (%s): " args))
                  (read-string (format "Reduce Expression (%s): " args)))))
  (insert-indented (concat "map!\"" map-expression "\"(" (mapconcat 'identity arguments ", ") ")"
                           ".reduce!\"" reduce-expression "\"")))
;; Use: (d-insert-map-reduce-expression '("u" "v") "a*b" "a+b")

(defvar c-stubs-menu nil
  "Menu for C Mode Stubs.
This menu will get created automatically if you have the `easymenu' package.")

(defconst c-stubs-menu-list
  '("Insert"

    ["main()" c-insert-main-stub t]
    "--"
    ["if ()" c-insert-if-stub t]
    ["if-else ()" c-insert-if-else-stub t]
    ["while ()" c-insert-while-stub t]
    ["do-while ()" c-insert-do-while-stub t]
    ["switch ()" c-insert-switch-stub t]
    ["for ()" c-insert-for-stub t]
    "--"
    ["Array Declaration" c-insert-array-declaration-stub t]
    ["Array Definition" c-insert-array-definition-stub t]
    "--"
    ["Function Declaration" c-insert-function-declaration-stub t]
    ["Function Definition" c-insert-function-definition-stub t]
    "--"
    ["Enumeration Type Definition (typedef enum)" c-insert-typedef-enum-stub t]
    ["Structure Type Definition (typedef struct)" c-insert-typedef-struct-stub t]
    "--"
    ["C-Style Function Type" c-insert-function-type t]
    "--"
    ["Doxygen Line Comment" c-insert-doxygen-line-comment t]
    "--"
    ["Embed GDB Breakpoint" c-insert-embedded-gdb-breakpoint t]
    "--"
    ["pragma diagnostic ignored" c-insert-pragma-gcc-diagnostic-ignored t]
    )
  "Menu Stubs in C mode.")

;; TODO Reuse `c-stubs-menu-list' here.
(defconst c++-stubs-menu-list
  '("Insert"

    ["main()" c-insert-main-stub t]
    "--"
    ["if ()" c-insert-if-stub t]
    ["if-else ()" c-insert-if-else-stub t]
    ["while ()" c-insert-while-stub t]
    ["do-while ()" c-insert-do-while-stub t]
    ["switch ()" c-insert-switch-stub t]
    ["for ()" c-insert-for-stub t]
    ["Range-Based for () (C++11)" c++11-insert-range-based-for-stub t]
    ["try-catch ()" c++-insert-try-catch-stub t]
    ["static_assert ()" c++11-insert-static-assert t]
    "--"
    ["Array Declaration" c-insert-array-declaration-stub t]
    ["Array Definition" c-insert-array-definition-stub t]
    "--"
    ["Function Definition" c-insert-function-definition-stub t]
    ["Operator Definition (C++)" c++-insert-operator-definition-stub t]
    ["Literal Suffix Operator Definition (C++11)" c++11-insert-user-defined-literal-suffix-operator-stub t]
    ["Raw String Literal (C++11)" c++11-insert-raw-string-literal t]
    "--"
    ["Enumeration (enum)" c++-insert-enum-stub t]
    ["Enumeration Class (C++11)" c++-insert-enum-class-stub t]
    ["Structure Definition (typedef struct)" c-insert-typedef-struct-stub t]
    "--"
    ["Class Definition (C++)" c++-insert-class-definition-stub t]
    ["Functor/Monad Definition (C++)" c++-insert-functor-definition-stub t]
    ["Template Definition (C++)" c++-insert-template-stub t]
    ["Variadic Template (C++11)" c++11-insert-variadic-template-stub t]
    "--"
    ["Type Cast (C++)" c-insert-type-cast t]
    "--"
    ["C-Style Function Type" c-insert-function-type t]
    ["C++11-Style Function Type" c++11-insert-function-type t]
    "--"
    ["Lambda Expression (C++11)" c++11-insert-lambda-expression-stub t]
    ["For Each Lambda Expression (C++11)" c++11-insert-for-each-lambda-expression-stub t]
    ["Standard Thread (C++11)" c++11-insert-thread-stub t]
    "--"
    ["STL IOstream Class (C++)..." c++-insert-iostream-class t]
    ["STL IOstream Object (C++)..." c++-insert-iostream-object t]
    ["STL IOstream Type (C++)..." c++-insert-iostream-type t]
    ["STL IOstream Manipulator (C++)..." c++-insert-iostream-manipulator t]
    "--"
    ["Smart Pointer (C++)..." c++-insert-smart-pointer t]
    ["Smart Pointer (C++11)..." c++11-insert-smart-pointer t]
    "--"
    ["STL Container (C++)..." c++-insert-stl-container t]
    ["STL Algorithm (C++)..." c++-insert-stl-algorithm t]
    "--"
    ["Boost Container (C++)..." c++-insert-boost-container t]
    ["Boost Algorithm (C++)..." c++-insert-boost-algorithm t]
    "--"
    ["TBB Container (C++)..." c++-insert-tbb-container t]
    ["TBB Blocked Range (C++)..." c++-insert-tbb-blocked-range t]
    ["TBB Algorithm (C++)..." c++-insert-tbb-algorithm t]
    "--"
    ["PPL Container (C++)..." c++-insert-ppl-container t]
    "--"
    ["Doxygen Line Comment" c-insert-doxygen-line-comment t]
    "--"
    ["Embed GDB Breakpoint" c-insert-embedded-gdb-breakpoint t]
    "--"
    ["Insert Visual C++ pragma comment lib" d-insert-visual-c++-pragma-comment-lib t]
    ["Insert Visual C++ pragma comment linker" d-insert-visual-c++-pragma-comment-linker t]
    )
  "Menu Stubs in C/C++ mode.")

;; TODO Reuse `c-stubs-menu-list' here.
(defconst d-stubs-menu-list
  '("Insert"

    ["main()" c-insert-main-stub t]
    ["if ()" c-insert-if-stub t]
    ["if-else ()" c-insert-if-else-stub t]
    ["while ()" c-insert-while-stub t]
    ["do-while ()" c-insert-do-while-stub t]
    ["with ()" d-insert-while-stub t]
    ["switch ()" c-insert-switch-stub t]
    ["for ()" c-insert-for-stub t]
    ["foreach ()" d-insert-foreach-stub t]
    ["static assert ()" d-insert-static-assert t]
    ["alias" d-insert-alias-stub t]
    "--"
    ["Array Declaration" c-insert-array-declaration-stub t]
    ["C Array Definition" c-insert-array-definition-stub t]
    ["Array Definition" d-insert-array-definition-stub t]
    ["Static Map (Hash table)" d-insert-static-map t]
    "--"
    ["Function Declaration" c-insert-function-declaration-stub t]
    ["Function Definition" d-insert-function-definition-stub t]
    "--"
    ["Enumeration Type Definition: enum" c-insert-typedef-enum-stub t]
    ["Structure Type Definition: struct" c-insert-typedef-struct-stub t]
    ["Struct" d-insert-struct-stub t]
    ["Struct Documentation" d-insert-struct-ddoc-standard-sections-stub]
    ["Class" d-insert-class-stub t]
    ["Module" d-insert-module-stub t]
    ["Debug Print ()" d-insert-debug-print t]
    "--"
    ["Unittest" d-insert-unittest-stub t]
    "--"
    ["Function Type (D)" c-insert-function-type t]
    "--"
    ["Type Cast (Unsafe) (D)" c-insert-type-cast t]
    ["Convert To (Safe) (D)" d-insert-conv-to t]
    "--"
    ["Doxygen Line Comment" c-insert-doxygen-line-comment t]
    "--"
    ["Embed GDB Breakpoint" c-insert-embedded-gdb-breakpoint t]
    "--"
    ["Compiles Trait: __traits(compiles, EXP)" d-insert-compiles-trait t]
    "--"
    ["Compilation Message: pragma(msg)" d-insert-pragma-msg t]
    ["Linker Library: pragma(lib)" d-insert-pragma-lib t]
    ["File into String" d-insert-import-file-string t]
    ["Module Function Import" d-insert-import-module-function t]
    ["Scoped Stack Allocation" d-insert-scoped-stack-allocation-instance t]
    ["Versioned Statement" d-insert-version t]
    ["String Type" d-insert-string-type t]
    ["Map-Reduce Expression" d-insert-map-reduce-expression t]
    )
  "Menu Stubs in D mode.")

(defconst c-refactor-menu-list
  '("Refactor"

    ["Move Function Up" c-move-function-up t]
    ["Move Function Down" c-move-function-down t]
    "--"
    ["Make Function Inline and Move to the Header (inside Class Definition)" c-make-function-inline-and-move-to-header t]
    ["Postfix Increment/Decrement Operators to Prefix" c-postfix-to-prefix-inc-dec t]
    ["Convert int,FALSE,TRUE to bool,false,true" c-int-to-bool t] ;TODO
    "--"
    ["Make member variable global" c-make-member-variable-global t] ;TODO
    ["Make member function global" c-make-member-function-global t] ;TODO
    "--"
    ["Make global variable a member" c-make-global-variable-member t] ;TODO
    ["Make global function a member" c-make-global-function-member t] ;TODO
    )
  "C Refactorings (in both C and C++).")

(defconst c++-refactor-menu-list
  '("Refactor"

    ["Disable Copy Constructor using boost::noncopyable" c-make-copy-ctor-noncopyable t]
    ["Convert [m,c,re]alloc and free to new and delete or delete[]" c-alloc-free-to-new-delete t] ;TODO
    ;; Look especially in ctors and dtors.
    "--"
    ["C++ify Type Cast" c++ify-c-type-casts t]
    ;; - [[static_cast<T>()]] Type Conversion
    ;; - [[const_cast<T>()]] To and from Constness
    ;; - [[reinterpret_cast<T>()]] Incompatible Pointer Type Conversion
    ;; - [[dynamic_cast<T>()]] (RTTI Polymorphism)
    "--"
    ["Convert std::vector into std/boost::array if never resized" c++-vector-to-array t] ;TODO
    ["Convert variable length stack array into std/boost::array if never resized" c++-vector-to-array t] ;TODO
    ["Convert function to C++ member function" c-function-to-c++-member-function t] ;TODO
    "--"
    ["C++ify Type Limits" c-function-to-c++-member-function t] ;TODO (SIZE/SHORT/INT/LONG)_MIN/MAX int stdint.h converts std::numeric_limits<size_t>::min()/max() to in <limits>
    ["C++ify Comments" c++ify-c-comments t]
    ["C++ify C MIN and MAX macros calls to std::min and std::max" c++ify-min-and-max t]
    ["C++ify Logical Operators" c-to-c++-logical-operators t] ;TODO && to and, || to or, ! to not
    ["C++ify Convert &A+ -> B+ (.C+)* to A" c++ify-strip-struct-c-inherit-refs t]
    ["C++ify Struct Function to Member Function" c++ify-struct-function-to-member-function t]
    ["C++ify new function to constructor" c++ify-new-function-to-constructor t]
    "--"
    ["C++ Templatize Function" c++-templatize-function t]
    ["C++ Templatize Class" c++-templatize-class t]
    ["C++ Templatize Buffer" c++-templatize-buffer t]
    ["C++ Templatize Thing" c-templatize-thing t]
    ;; using if () expression following function header
    ;; see: http://channel9.msdn.com/Events/GoingNative/GoingNative-2012/Static-If-I-Had-a-Hammer
    ["Restrict Template Function" c++-restrict-template-function t]
    ;; Note: Merge for example
    ;; f(a...) all float
    ;; f(a...) all double
    ;; to
    ;; typename std::enable_if<std::is_integral<T>::value, T>::type sadd(a...)
    ["C++ Merge Template Specializations to Type Traits" c++-merge-template-specialization-to-enable-if-type-trait t]
    ;; Fore example to
    ;; typename std::enable_if<std::is_class<T>::value, T>::type sadd(a...)
    ["C++ Restrict Algorithm Type" c++-restrict-algorithm-type t]
    "--"

    ["C++11ify C Macro NULL to C++11's nullptr"
     c++11ify-to-nullptr t]
    ["C++11ify STL begin() and end() member functions to non-member variants begin(Cont) and end(Cont)"
     c++11ify-stl-begin-and-end t]
    ["C++11ify Strongly Retype Enumeration"
     c++11ify-strongly-retype-enum t]
    ["C++11ify Emplaceify insert() and push_back(). Use emplace(x...) instead of insert(std::make_pair(x...)"
     c++11ify-emplace-instead-of-make-pair t]
    ["C++11ify Change Arguments Passing from Constant Reference to By Value in functions that return a mutated version of the input argument such as std::sort(Container)."
     c++11ify-emplace-instead-of-make-pair t]
    )
  "C++ Refactorings.")

(defconst d-refactor-menu-list
  '("Refactor"

    ["Move Function Up" c-move-function-up t]
    ["Move Function Down" c-move-function-down t]
    "--"
    ["Make Function Inline and Move to the Header (inside Class Definition)" c-make-function-inline-and-move-to-header t]
    ["Postfix Increment/Decrement Operators to Prefix" c-postfix-to-prefix-inc-dec t]
    ["Convert int,FALSE,TRUE to bool,false,true" c-int-to-bool t] ;TODO
    "--"
    ["Make member variable global" c-make-member-variable-global t] ;TODO
    ["Make member function global" c-make-member-function-global t] ;TODO
    "--"
    ["Make global variable a member" c-make-global-variable-member t] ;TODO
    ["Make global function a member" c-make-global-function-member t] ;TODO
    "--"
    ["D Templatize Function" d-templatize-function t]
    )
  "D Refactorings (in both C and D).")

;; TODO Make these sub-menu of "C" and "C++" menu.
(add-hook 'c-mode-hook (lambda () (easy-menu-define c-stubs-menu c-mode-map "C Stubs Menu" c-stubs-menu-list)) t)
(add-hook 'c-mode-hook (lambda () (easy-menu-define c-refactor-menu c-mode-map "C Refactor Menu" c-refactor-menu-list)) t)

(add-hook 'c++-mode-hook (lambda () (easy-menu-define c++-stubs-menu c++-mode-map "C++ Stubs Menu" c++-stubs-menu-list)) t)
(add-hook 'c++-mode-hook (lambda () (easy-menu-define c++-refactor-menu c++-mode-map "C++ Refactor Menu" c++-refactor-menu-list)) t)

(add-hook 'd-mode-hook (lambda () (easy-menu-define d-stubs-menu d-mode-map "D Stubs Menu" d-stubs-menu-list)) t)
(add-hook 'd-mode-hook (lambda () (easy-menu-define d-refactor-menu d-mode-map "D Refactor Menu" d-refactor-menu-list)) t)

;;; TODO C-to-C++ Refactorings
;; ** Enums are type-safe in C++
;; ** Cache members should be declared in C++ as =mutable=
;; ** Templatize
;; saturated_add/sub/mul.[hc], [vec|box|rect|...][0-9][a-z].[hc]
;; Use specializations and call C-functions that are assembler optimized.
;; ** Replace rangerand (file:~/pnw/src/rangerand.h) with boost::uniform_int<>
;; ** Remove my macro =__mutable__= in file:~/pnw/src/PMDb/ppatt.h
;; ** Use Safer Casts
;; Remove all explicit casts especially pointer casts and replace with
;; C++ reinterpret_cast.

;; ---------------------------------------------------------------------------

;; Note:
(when nil
  (list (functionp (lambda () nil))
        (commandp (lambda () nil))
        (commandp (lambda () (interactive) nil)))
  (call-interactively (lambda () (interactive) (insert "First line.")))
  (call-interactively (lambda () (interactive) (insert "Second line.")))
  (commandp (quote (lambda nil (interactive) (insert "std::cin"))))
  )

;; Note: Learned this initialization pattern from yas/define-snippets()
(defun generate-keymap-menu (keymap-menu-name insert-prefix alist)
  (let ((m (make-sparse-keymap keymap-menu-name)))
    (dolist (elm (reverse alist))
      (let* ((str (concat insert-prefix (elt elm 0)))
             (key (elt elm 1))
             (doc (elt elm 3))
             )
        (define-key m key `(menu-item ,str (lambda () (interactive) (insert ,str)) :help ,doc))))
    m))
;; Use: (generate-keymap-menu "IOstream Objects" "std::" c++-iostream-objects)

;; ---------------------------------------------------------------------------

(defconst c++-iostream-objects-menu
  (generate-keymap-menu "IOstream Objects" "std::" c++-iostream-objects)
  "C++ IOstream Objects Menu")

(add-hook 'c++-mode-hook
          (lambda ()
            (define-key-after c-c++-menu [cc-tools/separator]
              '(menu-item "--"))
            (define-key-after c-c++-menu [iostream-objects]
              (cons "IOstream Objects" c++-iostream-objects-menu) t))
          t)

;; ---------------------------------------------------------------------------

(defun rename-refs (before-regexp file after-regexp newname files)
  "Rename all references of BEFORE-REGEXP FILE AFTER-REGEXP to
NEWNAME under a given directory."
  (interactive "sBefore (regexp): sCurrent file name: sAfter (regexp): \nsNew file name: \nsReplace in files (regexp or return for all files except backups): ")
  (let* ((dir (read-directory-name
               (concat "Rename references of " file " to " newname
                       " under directory: ")
               nil nil t))
         (rel-file (file-name-nondirectory file))
         (rel-newname (file-relative-name-to-file file newname)))
    (message "rel-file: %s" rel-file)
    (message "rel-newname: %s" rel-newname)
    (message "dir: %s" dir)
    (query-replace-in-directory (regexp-quote rel-file) rel-newname files dir 'words)
    ))
;; Use:

(defun rename-refs-plain (file newname files)
  "Rename all references of FILE to NEWNAME under a given directory."
  (interactive "sCurrent file name: \nsNew file name: \nsReplace in files (regexp or return for all files except backups): ")
  (rename-refs "" file "" newname files)
  )

;; Use: (rename-refs-plain "/etc/passwd" "/etc2/passwd2" nil)

(defun rename-file-with-refs (file newname &optional ok-if-already-exists)
  (interactive "fRename File: \nFRename %s to file: ")
  (rename-file file newname ok-if-already-exists)
  (rename-refs "" file "" newname nil))
(defalias 'move-file-with-refs 'rename-file-with-refs)

(defun rename-c-includes (file newname files)
  "Rename all C \"#include\" Statements of the FILE to NEWNAME under a given directory."
  (interactive "sCurrent file name: \nsNew file name: " )
  (rename-refs (concat "#include " "\"")
               file
               ""
               (concat "#include " "\""newname)
               files)
  )

(defun update-c-c++-includes (file newname)
  "Update C and C++ \"#include\" Statements upon Rename of FILE to NEWNAME."
  (when (and
         ;; 	   (and (not (equal file newname))
         ;; 		(not (equal file (concat newname "~"))))
         )
    (when (and (file-match file 'C-Header 'name-or-contents-recog) ;source is C header
               (file-match newname 'C-Header 'name-or-contents-recog) ;dest is C header
               )
      (if (y-or-n-p-defaults "Update C #includes along with file-renaming? ")
          ;; ToDo: We need to strip parts of the path from FILE and NEWNAME
          (let ((files (read-string "Update C #includes in files (regexp or return for all files except backups): ")))
            (rename-c-includes file newname files)))
      )
    (when (and (file-match file 'C++-Header 'name-or-contents-recog) ;source is C++ header
               (file-match newname 'C++-Header 'name-or-contents-recog) ;dest is C++ header
               )
      (if (y-or-n-p-defaults "Update C++ #includes along with file-renaming? ")
          ;; ToDo: We need to strip parts of the path from FILE and NEWNAME
          (let ((files (read-string "Update C++ #includes in files (regexp or return for all files except backups): ")))
            (rename-c-includes file newname files)))
      )
    ))

;; ---------------------------------------------------------------------------

(defun delete-comment ()
  "Delete the first Comment found following the current position."
  (interactive)
  (let ((start-len (length comment-start))
        (end-len (length comment-end)))
    (when (> start-len 0)
      (when (search-forward comment-start nil t)
        (goto-char (match-beginning 0))
        (let ((start (point)))
          (if (== end-len 0)   ;if comments can span multiple lines
              (kill-line)
            (when (search-forward comment-end nil t) ;find end
              (delete-region start (point)))))))))

(defun c-delete-all-comments ()
  "Delete all C Comments in the current buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (delete-comment))))

;; ---------------------------------------------------------------------------

;; Got these from http://www.emacswiki.org/emacs-en/CcMode

(defun mark-c-scope-beg ()
  "Marks the c-scope (region between {}) enclosing the point.
   Naive, as will be confused by { } within strings"
  (let ((depth 1))                      ;scope depth
    (while (not (= depth 0))
      (search-backward-regexp "}\\|{")  ;backwards
      ;;      (if (string= (char-to-string (char-before)) "}")
      (if (eq (char-before) ?\})
          (setq depth (1+ depth))
        (setq depth (1- depth)))))
  (point))

(defun mark-c-scope-end ()
  "Marks the c-scope (region between {}) enclosing the point.
   Naive, as will be confused by { } within strings"
  (let ((depth 1))                      ;scope depth
    (while (not (= depth 0))
      (search-forward-regexp "}\\|{")   ;forwards
      ;;      (if (string= (char-to-string (char-before)) "{")
      (if (eq (char-before) ?\{)
          (setq depth (1+ depth))
        (setq depth (1- depth)))))
  (point))

(defun kill-c-scope ()
  (interactive)
  (let ((inital-point (point)))
    (save-excursion
      (let ((beg (mark-c-scope-beg)))
        (goto-char inital-point)
        (let ((end (mark-c-scope-end))))))))

;; ---------------------------------------------------------------------------
;; Indentation Styles

(c-add-style "nordlöw-c"
             '("gnu"
               (c-tab-always-indent        . t)
               (c-comment-only-line-offset . 0)
               (c-hanging-braces-alist     . ((substatement-open after)
                                              (brace-list-open)))
               (c-hanging-colons-alist     . ((member-init-intro before)
                                              (inher-intro)
                                              (case-label after)
                                              (label after)
                                              (access-label after)))
               (c-cleanup-list             . (scope-operator
                                              empty-defun-braces
                                              defun-close-semi))
               (c-offsets-alist            . ((arglist-close . c-lineup-arglist)
                                              (substatement-open . 0)
                                              (case-label        . 0)
                                              (block-open        . 0)

                                              (inline-open       . 0)
                                              (inline-close      . 0)

                                              (inextern-lang     . 0)
                                              (extern-lang-open  . 0)
                                              (extern-lang-close . 0)

                                              (knr-argdecl-intro . -)))
               (c-echo-syntactic-information-p . t)))

(c-add-style "nordlöw-c++"
             '("stroustrup"
               (c-tab-always-indent        . t)
               (c-comment-only-line-offset . 0)
               (c-hanging-braces-alist     . ((substatement-open after)
                                              (brace-list-open)))
               (c-hanging-colons-alist     . ((member-init-intro before)
                                              (inher-intro)
                                              (case-label after)
                                              (label after)
                                              (access-label after)))
               (c-cleanup-list             . (scope-operator
                                              empty-defun-braces
                                              defun-close-semi))
               (c-offsets-alist            . ((arglist-close . c-lineup-arglist)
                                              (substatement-open . 0)
                                              (case-label        . 0)
                                              (block-open        . 0)

                                              (inline-open       . 0)
                                              (inline-close      . 0)

                                              (namespace-open    . 0)
                                              (namespace-close   . 0)
                                              (innamespace       . 0)

                                              (inextern-lang     . 0)
                                              (extern-lang-open  . 0)
                                              (extern-lang-close . 0)

                                              (knr-argdecl-intro . -)))
               (c-echo-syntactic-information-p . t)))
(add-hook 'c-mode-hook (lambda () (c-set-style "nordlöw-c")) t)
(add-hook 'c++-mode-hook (lambda () (c-set-style "nordlöw-c++")) t)
(add-hook 'objc-mode-hook (lambda () (c-set-style "nordlöw-c++")) t)
(add-hook 'd-mode-hook (lambda () (c-set-style "nordlöw-c")) t)

;; ---------------------------------------------------------------------------

(defun c-kill-statement (&optional arg)
  "Kill the Statement Following Point.
With ARG, kill that many statements after point.
Negative arg -N means kill N statements before point.
This command assumes point is not in a string or comment."
  (interactive "p")
  (let ((opoint (point)))
    (c-end-of-statement (or arg 1))
    (kill-region opoint (point))))

(defun c-backward-kill-statement (&optional arg)
  "Kill the Statement Preceeding Point.
With ARG, kill that many statements before point.
Negative arg -N means kill N statements after point.
This command assumes point is not in a string or comment."
  (interactive "p")
  (let ((opoint (point)))
    (c-beginning-of-statement (or arg 1))
    (kill-region (point) opoint)))

;; ---------------------------------------------------------------------------

(defun c-assist-common-hook ()
  "Common Assistance for C, C++ and ObjC."

  ;;(c-toggle-auto-state 1)		; automatic newlines etc.
  (c-toggle-hungry-state 1)	; hungry delete
  ;;(c-toggle-auto-hungry-state 1)	; both

  ;; keybindings for all supported languages.  We can put these in
  ;; c-mode-base-map because c-mode-map, c++-mode-map, objc-mode-map,
  ;; java-mode-map, and idl-mode-map inherit from it.
  (define-key c-mode-base-map "\C-m" 'newline-and-indent)

  ;; make sure spaces are used instead of tabs
  (setq indent-tabs-mode nil)

  ;; if on a #include line, use the included file as the tag
  (defun my-C-find-tag-default ()
    (interactive)
    (or (save-excursion
          (beginning-of-line)
          (if (looking-at
               cpp-include-regexp)
              (match-string 1)))
        (find-tag-default)))

  (setq info-lookup-mode 'c-mode)

  ;; Stepping in long symbols
  (when (and (require 'subword nil t)
             (fboundp 'c-subword-mode))
    (c-subword-mode t)
    (local-set-key [(meta f)] 'subword-forward)
    (local-set-key [(meta b)] 'subword-backward)
    ;;(local-set-key [(meta f)] 'c-forward-subword)
    ;;(local-set-key [(meta b)] 'c-backward-subword)
    )
  ;; stub insert keys
  (charedit-local-set-key ?M 'c-insert-main-stub 'code)
  (charedit-local-set-key ?i 'c-insert-if-stub 'code)
  (charedit-local-set-key ?I 'c-insert-if-else-stub 'code)
  (charedit-local-set-key ?w 'c-insert-while-stub 'code)
  (charedit-local-set-key ?W 'd-insert-with-stub 'code)
  (charedit-local-set-key ?s 'c-insert-switch-stub 'code)
  (charedit-local-set-key ?d 'c-insert-do-while-stub 'code)
  (charedit-local-set-key ?f 'c-insert-for-stub 'code)
  (charedit-local-set-key ?U 'c-insert-function-declaration-stub 'code)
  (charedit-local-set-key ?u 'c-insert-function-definition-stub 'code)
  (charedit-local-set-key ?e 'c-insert-typedef-enum-stub 'code)
  (charedit-local-set-key ?r 'c-insert-typedef-struct-stub 'code)
  (charedit-local-set-key ?Y 'c-insert-array-declaration-stub 'code)
  (charedit-local-set-key ?y 'c-insert-array-definition-stub 'code)
  (local-set-key [(control meta \;)]  'c-insert-doxygen-line-comment)
  (local-set-key [(control c) (control t)] 'sgml-tag)
  ;;(local-set-key [(control meta backspace)] 'c-delete-backward-expr)
  ;;(local-set-key [(control meta delete)] 'c-delete-forward-expr)
  (local-set-key [(meta shift delete)] 'c-kill-statement)
  (local-set-key [(meta shift backspace)] 'c-backward-kill-statement)
  ;;(local-set-key [(control h) f] 'semantic-ia-show-doc)
  ;;(local-set-key [(control shift return)] semantic-ia-complete-symbol-menu)
                                        ;Tell `info-look' what mode to use.
  (local-set-key [(meta ?\()] 'c-insert-parens)
  (charedit-local-set-key ?B 'c-insert-embedded-gdb-breakpoint 'code)
  )
(add-hook 'c-mode-common-hook 'c-assist-common-hook t)

(defun c++-assist-hook ()
  "Common Assistance for C++."
  (charedit-local-set-key ?t 'c++-template-dwim 'code)
  (charedit-local-set-key ?n 'c++-insert-namespace-stub 'code)
  (charedit-local-set-key ?F 'c++11-insert-range-based-for-stub 'code)
  (charedit-local-set-key ?T 'c++11-insert-variadic-template-stub 'code)
  (charedit-local-set-key ?l 'c++11-insert-lambda-expression-stub 'code)
  (charedit-local-set-key ?L 'c++11-insert-for-each-lambda-expression-stub 'code)
  (charedit-local-set-key ?h 'c++11-insert-thread-stub 'code)
  (charedit-local-set-key ?c 'c++-insert-class-definition-stub 'code)
  (charedit-local-set-key ?C 'c++-insert-stl-container 'code)
  (charedit-local-set-key ?a 'c++-insert-stl-algorithm 'code)
  (charedit-local-set-key ?p 'c++11-insert-smart-pointer 'code)
  (charedit-local-set-key ?e 'c-insert-typedef-enum-stub 'code)
  (charedit-local-set-key ?E 'c++-insert-enum-stub 'code)
  (charedit-local-set-key ?A 'c++-insert-enum-class-stub 'code)
  (charedit-local-set-key ?N 'c++-convert-typedef-enum-to-c++-enum 'code)
  (charedit-local-set-key ?S 'c-insert-type-cast 'code)
  (charedit-local-set-key ?W 'c++-insert-throw-stub 'code)
  (charedit-local-set-key ?H 'c++-insert-try-catch-stub 'code)
  (charedit-local-set-key ?_ 'c++11-insert-static-assert 'code)
  (local-set-key [(control c) (control i)] 'assure-c++-include-from-symbol)
  )
(add-hook 'c++-mode-hook 'c++-assist-hook t)

(require 'ddoc-mode)

(defun d-insert-ddoc-macro (macro)
  "Insert DDoc Macro MACRO."
  (interactive (list
                ;; TODO Support Icicles explanations using Control up-down
                (completing-read "DDoc Macro: " d-ddoc-macros)
                ))
  (insert "$(" macro " )")
  (backward-char))

(defun d-assist-hook ()
  "Common Assistance for D."
  (charedit-local-set-key ?_ 'd-insert-static-assert 'code)
  (charedit-local-set-key ?a 'd-insert-alias-stub 'code)
  (charedit-local-set-key ?! 'd-insert-pragma-msg 'code)
  (charedit-local-set-key ?L 'd-insert-pragma-lib 'code)
  (charedit-local-set-key ?= 'd-insert-compiles-trait 'code)
  (charedit-local-set-key ?p 'd-insert-import-file-string 'code)
  (charedit-local-set-key ?o 'd-insert-scoped-stack-allocation-instance 'code)
  (charedit-local-set-key ?v 'd-insert-version 'code)
  (charedit-local-set-key ?S 'd-insert-struct-stub 'code)
  (charedit-local-set-key ?C 'd-insert-class-stub 'code)
  (charedit-local-set-key ?m 'd-insert-module-stub 'code)
  (charedit-local-set-key ?T 'd-insert-unittest-stub 'code)
  (charedit-local-set-key ?F 'd-insert-foreach-stub 'code)
  (charedit-local-set-key ?y 'c-insert-type-cast 'code)
  (charedit-local-set-key ?c 'd-insert-conv-to 'code)
  ;; DDoc Shortcuts
  (charedit-local-set-key ?\  'd-insert-ddoc-macro 'comment)
  )
(add-hook 'd-mode-hook 'd-assist-hook t)

(add-to-list 'auto-mode-alist '("\\.[Tt][Cc][Cc]$" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.ipp$" . c++-mode))

;; ---------------------------------------------------------------------------

(eval-when-compile (require 'cl))

(defun buffer-standard-include-p ()
  "Returns true if the current buffer is contained within one of
the directories in the INCLUDE environment variable."
  (and (getenv "INCLUDE")
       (file-in-directory-list-p buffer-file-name (split-string (getenv "INCLUDE") path-separator))))
(defalias 'buffer-standard-include? 'buffer-standard-include-p)

(add-to-list 'magic-fallback-mode-alist '(buffer-standard-include-p . c++-mode))

;; ---------------------------------------------------------------------------

(defun my-javadoc-return ()
  "Advanced C-m for Javadoc multiline comments.
Inserts `*' at the beggining of the new line if unless return was
pressed outside the comment"
  (interactive)
  (let* ((last (point))
         (is-inside (if (search-backward "*/" nil t)
                        ;; there are some comment endings - search forward
                        (if (search-forward "/*" last t)
                            't
                          'nil)
                      ;; it's the only comment - search backward
                      (goto-char last)
                      (if (search-backward "/*" nil t)
                          't
                        'nil))))
    (goto-char last)
    ;; the point is inside some comment, insert `*'
    (if is-inside
        (progn
          (insert "\n*")
          (indent-for-tab-command))
      ;; else insert only new-line
      (insert "\n"))))

;; (add-hook 'c-mode-common-hook (lambda ()
;;                                 (local-set-key "\r" 'my-javadoc-return)
;;                                 ))

;; ---------------------------------------------------------------------------

(when nil
  (setq emacs-images "/tmp")
  (add-hook 'c-mode-hook
            (lambda ()
              (define-key c-mode-map [tool-bar csearch-forw]
                `(menu-item "csearch forward" csearch-forward
                            :image (image :type xpm :file ,(concat emacs-images
                                                                   "/right-arrow.xpm"))))
              (define-key c-mode-map [tool-bar csearch-back]
                `(menu-item "csearch backward" csearch-backward
                            :image (image :type xpm :file ,(concat emacs-images
                                                                   "/left-arrow.xpm")))))))

;; ---------------------------------------------------------------------------

;;;
;; I have the following key binding to use them efficiently.
;;
;; (defun my-c++-mode-hook ()
;;   (interactive)
;;   (define-key c++-mode-map (kbd "C-c k f")
;;     'c++-generate-definition-as-kill)
;;   (define-key c++-mode-map (kbd "C-y")
;;     'c++-yank)
;;   ;; other entries removed.
;;   )
;; (add-hook 'c++-mode-hook 'my-c++-mode-hook)

;; ======================================================================
;; interface for the user

;;; TODO Maybe reuse some of these...
(when nil
  (defun c++-generate-definition-as-kill ()
    "generate a class member definition (constructors, functions, static variables) for the declaration before point and put it in kill-ring. After that you can `yank' it to your implementation file. you can also use `c++-yank-member-function' which will indent after yank and place the point nicely.

if this function successfully generated a function, `c++-member-function-killed' will be set to t."
    (interactive)
    (let ((code (c++-generate-definition)))
      (if (null code)
          (message "sorry, code generation failed")
        (kill-new code)
        (setq c++-member-function-killed t)
        (message "definition generated"))))

  (defun c++-generate-definition ()
    ;;
    ;; FIXME remove default parameter automatically.
    ;; FIXME static variable not working.
    ;;
    "generate a class member definition (constructors, functions, static variables) for the declaration before point. return the generated code or nil if failed."
    (interactive)
    (let ((class (c++-class-at-point)))
      (if (null class)
          (message "I can't see a class here.")
        (let ((stmt (c++-statement-at-point)))
          (or (c++-generate-definition-for-friend-func stmt)
              (progn
                ;; parse class
                (let ((class-properties (c++-parse-class-name class)))
                  (setq template-header (car class-properties))
                  (setq class-name (cdr class-properties))
                  (if template-header
                      (setq class-name (concat class-name
                                               (c++-template-var template-header)))))

                ;; parse stmt

                (if (c++-funcp stmt)
                    (let ((func-properties (c++-parse-func-declaration stmt)))
                      (setq before-class-name (car func-properties))
                      (setq after-class-name (concat (cdr func-properties)
                                                     "{\n\n}")))
                  ;; (if (c++-varp stmt)
                  ;; else assume it's a var
                  (let ((var-properties (c++-parse-var-declaration stmt)))
                    (setq before-class-name (car var-properties))
                    (setq after-class-name (concat (cdr var-properties)
                                                   " = \n"))))

                (setq result nil)
                (if template-header
                    (setq result (concat result
                                         template-header "\n")))
                (if before-class-name
                    (setq result (concat result
                                         before-class-name " ")))
                (concat result
                        class-name "::" after-class-name)))))))

  (defun c++-generate-definition-for-friend-func (stmt)
    "This is for consistence only."
    (interactive)
    (and (string-match (concat "^friend"
                               c++-pattern-space
                               "\\([^;]*\\)")
                       stmt)
         (concat (match-string 1 stmt)
                 "{\n\n}")))

  (defun c++-yank-definition ()
    "Yank the function generated by `c++-generate-definition-from-header-as-kill'"
    (interactive)
    (yank)
    (indent-region (region-beginning) (region-end))
    (forward-line -1)
    ;; if this is not working, use the following
    ;; (indent-according-to-mode)
    (funcall indent-line-function))

  (defun c++-yank ()
    "if there is an active generated member function, do `c++-yank-definition', else do a normal `yank'."
    (interactive)
    (if (and (boundp 'c++-member-function-killed)
             c++-member-function-killed)
        (progn
          (setq c++-member-function-killed nil)
          (c++-yank-member-function))
      (yank)))

  ;; support functions

  (setq c++-pattern-id "\\([a-zA-Z_][a-zA-Z_0-9]*\\)")
  (setq c++-pattern-id-no-catch "\\(?:[a-zA-Z_][a-zA-Z_0-9]*\\)")
  (setq c++-pattern-space "[ 	]+")
  (setq c++-pattern-space-optional "[ 	]*")
  (setq c++-pattern-space-newline "[ 	\n]+")
  (setq c++-pattern-space-newline-optional "[ 	\n]*")

  (setq c++-pattern-template
        (concat "\\(template"
                c++-pattern-space-newline-optional
                "<"
                c++-pattern-space-newline-optional
                "\\(?:"
                "\\(?:class\\|typename\\)"
                c++-pattern-space
                c++-pattern-id-no-catch
                c++-pattern-space-optional
                ",?"
                c++-pattern-space-newline-optional
                "\\)+"
                ">\\)"))

  (setq c++-pattern-typename
        (concat "\\(?:typename\\|class\\)"
                c++-pattern-space
                "\\([^,>]+\\)"))

  (setq c++-pattern-constructor
        (concat "^"
                c++-pattern-id
                c++-pattern-space-optional
                "([^;]*"))

  ;; virtual ~foo();
  (setq c++-pattern-destructor
        (concat "^\\(?:virtual"
                c++-pattern-space-optional
                "\\)?\\(~"
                c++-pattern-id
                c++-pattern-space-optional
                "([^;]*\\)"))

  (setq c++-pattern-operator-optional-no-catch
        "\\(?:++\\|--\\|==\\|!=\\|()\\|+\\|-\\)?")
  (setq c++-pattern-function
        (concat "\\(?:"
                (concat "virtual" c++-pattern-space-newline "\\|")
                (concat "inline" c++-pattern-space-newline "\\|")
                "\\)*"
                "\\(.*\\)"		;return type
                c++-pattern-space-newline
                "\\("
                c++-pattern-id-no-catch
                c++-pattern-space-optional
                c++-pattern-operator-optional-no-catch
                c++-pattern-space-optional
                "([^;]*\\)"))

  (defun c++-in-class-p ()
    "return inclass position from `c-guess-basic-syntax' if point is inside a class. return nil otherwise."
    (let ((syntax (c-guess-basic-syntax)))
      (or (cadr (assoc 'inclass syntax))
          ;; when func arguments span over lines or func return type is
          ;; in separate line, inclass is not set. but the following are set.
          (if (or (assoc 'arglist-cont-nonempty syntax)
                  (assoc 'topmost-intro-cont syntax))
              (save-excursion
                (forward-line -1)
                (c++-in-class-p))))))

  (defun c++-class-at-point ()
    "return class name if point is inside a class. return nil otherwise."
    (interactive)
    (let ((inclass (c++-in-class-p)))
      (and inclass
           (save-excursion
             (goto-char inclass)
             ;; inclass could be at beginning of class name or end of class name.
             ;; depending on whether the user put { on a separate line.
             (if (looking-at "{")
                 ;; we are at the end of class name
                 (progn
                   (c-beginning-of-statement-1)
                   (buffer-substring-no-properties (point) (1- inclass)))
               ;; we are at the beginning of class name
               (c-end-of-statement)
               (buffer-substring-no-properties inclass (point)))))))

  (defun c++-statement-at-point ()
    "Return Statement at Point. return nil if we are at point 1."
    (save-excursion
      (or (looking-back (concat ";" c++-pattern-space-optional))
          (c-end-of-statement))
      (let ((stmt-end (point)))
        (c-beginning-of-statement-1)
        (buffer-substring-no-properties (point) stmt-end))))

  (defun c++-parse-class-name (class)
    "return a pair containing template-header and class-name."
    (interactive)
    (and class
         (string-match (concat c++-pattern-space-newline-optional
                               c++-pattern-template "?"
                               c++-pattern-space-newline-optional
                               "class"
                               c++-pattern-space-newline
                               c++-pattern-id)
                       class)
         (cons (match-string 1 class)
               (match-string 2 class))))

  (defun c++-funcp (stmt)
    "Return none nil if given statement is a function."
    (and stmt
         (string-match (concat c++-pattern-id
                               c++-pattern-space-optional
                               c++-pattern-operator-optional-no-catch
                               c++-pattern-space-optional
                               "(")
                       stmt)))

  (defun c++-parse-func-declaration (stmt)
    "return a pair (return-type . name-and-arguments). or nil if stmt is not func."
    (interactive)
    (and stmt
         (cond
          ((string-match c++-pattern-constructor stmt)
           (cons nil (match-string 0 stmt)))
          ((string-match c++-pattern-destructor stmt)
           (cons nil (match-string 1 stmt)))
          ((string-match c++-pattern-function stmt)
           (cons (match-string 1 stmt)
                 (match-string 2 stmt)))
          (t nil))))

  (defun c++-template-var (str)
    "translate \"template <typename T, class U>\" to < T, U >.
return nil if no template var found."
    (interactive)
    ;; add first var to result
    (string-match c++-pattern-typename str)
    (setq result (concat "< " (match-string 1 str)))
    (setq start-from (match-end 0))

    ;; add rest vars to result, separate by comma
    (while (string-match c++-pattern-typename str start-from)
      (setq result (concat result ", " (match-string 1 str)))
      (setq start-from (match-end 0)))

    ;; add final angel bracket
    (concat result " >"))

  ;; tests for c++-template-var
  ;; (string-equal "< T, U  >"
  ;; 	      (c++-template-var "template < typename T, typename U >"))
  ;; (string-equal "< T, M, U  >"
  ;; 	      (c++-template-var "template < typename T, class M, class U >"))


  )

(provide 'cc-assist)
