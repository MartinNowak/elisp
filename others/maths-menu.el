;;; maths-menu.el --- insert maths characters from a menu  -*-coding: iso-2022-7bit;-*-

;; Copyright (C) 2003, 2009  Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: convenience
;; $Revision: 1.6 $
;; URL: http://www.loveshack.ukfsn.org/emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Defines a minor mode which defines a menu bar item allowing a wide
;; range of maths/technical characters (roughly the LaTeX repertoire)
;; to be inserted into the buffer by selecting menu items.

;; Menu display only works properly under X with Gtk menus and if the
;; menu uses a font with a suitable repertoire.  (Lucid and Motif
;; toolkit menus can't display multilingual text.  I don't know about
;; MS Windows or Nextstep.)  It will work with tmm in tty mode iff the
;; tty displays Unicode.  The tmm version (via F10) is also useful
;; under a window system when the menus don't display the characters
;; correctly, but where the symbols have word syntax, tmm won't
;; provide an ASCII selector for them, which can be a pain to use
;; without a mouse.

;; See also the TeX and sgml Quail input modes.  These will probably
;; behave better if you can remember the input sequences.  For
;; instance, this minor mode won't give you the ability to insert into
;; the minibuffer via the menu, though presumably it could be added to
;; the minibuffer menu.

;;; Code:

(defun maths-menu-build-menu (spec)
  (let ((map (make-sparse-keymap "Characters")))
    (dolist (pane spec)
      (let* ((name (pop pane))
	     (pane-map (make-sparse-keymap name)))
	(define-key-after map (vector (intern name)) (cons name pane-map))
	(dolist (elt pane)
	  (define-key-after pane-map
	    (vector (intern (string (car elt)))) ; convenient unique symbol
	    (cons (format "%c  %s" (car elt) (cadr elt))
		  ;; Using a string here doesn't work (when compiled).
		  ;; You get a `Wrong type argument: commandp,' error.
		  ;; That looks like a bug, since
		  ;;   (commandp "a") => t
		  ;; It does work when interpreted...
		  `(lambda ()
		     (interactive)
		     (insert ,(car elt))))))))
    map))

(defvar maths-menu-menu
  (maths-menu-build-menu
   '(("Binops 1"
      (?,A1(B "plus-minus sign")
      (?$,1x3(B "minus-or-plus sign")
      (?,AW(B "multiplication sign")
      (?,Aw(B "division sign")
      (?$,1x2(B "minus sign")
      (?$,1x7(B "asterisk operator")
      (?$,1z&(B "star operator")
      (?$,1x8(B "ring operator")
      (?$,2"+(B "white circle")
      (?$,2"O(B "large circle")
      (?$,1x9(B "bullet operator")
;;       (?$,1s"(B "bullet")
      (?$,1z%(B "dot operator")
;;       (?,A7(B "middle dot")
      (?$,1xI(B "intersection")
      (?$,1xJ(B "union")
      (?$,1yN(B "multiset union")
      (?$,1yS(B "square cap")
      (?$,1yT(B "square cup")
      (?$,1xH(B "logical or")
      (?$,1xG(B "logical and")
      (?$,1x6(B "set minus")
      (?$,1x`(B "wreath product")
      (?$,2-(B "amalgamation or coproduct"))
     ("Binops 2"
      (?$,1z$(B "diamond operator")
      (?$,2!s(B "white up-pointing triangle")
      (?$,2!}(B "white down-pointing triangle")
      (?$,2"#(B "white left-pointing small triangle")
      (?$,2!y(B "white right-pointing small triangle")
      (?$,2"!(B "white left-pointing triangle")
      (?$,2!w(B "white right-pointing triangle")
      (?$,1yU(B "circled plus")
      (?$,1yV(B "circled minus")
      (?$,1yW(B "circled times")
      (?$,1yX(B "circled division slash")
      (?$,1yY(B "circled dot operator")
      (?$,2"O(B "large circle")
      (?$,1s (B "dagger")
      (?$,1s!(B "double dagger")
      (?$,1yt(B "normal subgroup of or equal to")
      (?$,1yu(B "contains as normal subgroup or equal to"))
     ("Relations 1"
      (?$,1y$(B "less-than or equal to")
      (?$,1y:(B "precedes")
      (?$,1y*(B "much less-than")
      (?$,1yB(B "subset of")
      (?$,1yF(B "subset of or equal to")
      (?$,1yO(B "square image of")
      (?$,1yQ(B "square image of or equal to")
      (?$,1x((B "element of")
      (?$,1x)(B "not an element of")
      (?$,1yb(B "right tack")
      (?$,1y%(B "greater-than or equal to")
      (?$,1y;(B "succeeds")
      (?$,1y=(B "succeeds or equal to")
      (?$,1y+(B "much greater-than")
      (?$,1yC(B "superset of")
      (?$,1yG(B "superset of or equal to")
      (?$,1yP(B "square original of")
      (?$,1yR(B "square original of or equal to")
      (?$,1x+(B "contains as member")
      (?$,1y!(B "identical to")
      (?$,1y"(B "not identical to") )
     ("Relations 2"
      (?$,1yc(B "left tack")
      (?$,1x\(B "tilde operator")
      (?$,1xc(B "asymptotically equal to")
      (?$,1xm(B "equivalent to")
      (?$,1xh(B "almost equal to")
      (?$,1xe(B "approximately equal to")
      (?$,1y (B "not equal to")
      (?$,1xp(B "approaches the limit")
      (?$,1x=(B "proportional to")
      (?$,1yg(B "models")
      (?$,1xC(B "divides")
      (?$,1xE(B "parallel to")
      (?$,1z((B "bowtie")
      (?$,1z((B "bowtie")
      (?$,2-](B "join")
      (?$,1{#(B "smile")
      (?$,1{"(B "frown")
      (?$,1xy(B "estimates")
      (?$,1z_(B "z notation bag membership")
      (?$,1xU(B "because")
      (?$,1y3(B "greater than or equivalent to")
      (?$,1y2(B "less-than or equivalent to")
      (?$,1xo(B "difference between")
      (?$,1x|(B "delta equal to"))
     ("Arrows 1"
      (?$,1vp(B "leftwards arrow")
      (?$,2'u(B "long leftwards arrow")
      (?$,1wP(B "leftwards double arrow")
      (?$,2'x(B "long leftwards double arrow")
      (?$,1w)(B "leftwards arrow with hook")
      (?$,1w<(B "leftwards harpoon with barb upwards")
      (?$,1w=(B "leftwards harpoon with barb downwards")
      (?$,1wK(B "leftwards harpoon over rightwards harpoon")
      (?$,1vr(B "rightwards arrow")
      (?$,2'v(B "long rightwards arrow")
      (?$,1wR(B "rightwards double arrow")
      (?$,2'y(B "long rightwards double arrow")
      (?$,1w&(B "rightwards arrow from bar")
      (?$,2'|(B "long rightwards arrow from bar")
      (?$,1w[(B "rightwards triple arrow")
      (?$,1w*(B "rightwards arrow with hook")
      (?$,1w@(B "rightwards harpoon with barb upwards")
      (?$,1wA(B "rightwards harpoon with barb downwards")
      (?$,1v}(B "rightwards wave arrow")
      (?$,1wL(B "rightwards harpoon over leftwards harpoon"))
     ("Arrows 2"
      (?$,1vt(B "left right arrow")
      (?$,2'w(B "long left right arrow")
      (?$,1wT(B "left right double arrow")
      (?$,2'z(B "long left right double arrow")
      (?$,1vq(B "upwards arrow")
      (?$,1wQ(B "upwards double arrow")
      (?$,1vs(B "downwards arrow")
      (?$,1wS(B "downwards double arrow")
      (?$,1vu(B "up down arrow")
      (?$,1wU(B "up down double arrow")
      (?$,1vw(B "north east arrow")
      (?$,1vx(B "south east arrow")
      (?$,1vy(B "south west arrow")
      (?$,1vv(B "north west arrow")
      (?$,1wF(B "leftwards arrow over rightwards arrow")
      (?$,1w?(B "upwards harpoon with barb leftwards")
      (?$,1wC(B "downwards harpoon wth barb leftwards")
      (?$,1w>(B "upwards harpoon with barb rightwards")
      (?$,1wB(B "downwards harpoon wth barb righttwards"))
     ("Symbols 1"
      (?$,1uu(B "alef symbol") ; don't use letter alef (avoid bidi confusion)
      (?$,1uO(B "planck constant over two pi")
      (?$,1 Q(B "latin small letter dotless i")
      (?$,1uS(B "script small l")
      (?$,1uX(B "script capital p")
      (?$,1u\(B "black-letter capital r")
      (?$,1uQ(B "black-letter capital i")
      (?$,1ug(B "inverted ohm sign")
      (?$,1s2(B "prime")
      (?$,1x%(B "empty set")
      (?$,1x'(B "nabla")
      (?$,1x:(B "square root")
      (?$,1x;(B "cube root")
      (?$,1yd(B "down tack")
      (?$,1ye(B "up tack")
      (?$,1x@(B "angle")
      (?$,1x (B "for all")
      (?$,1x#(B "there exists")
      (?$,1x$(B "there does not exist")
      (?,A,(B "not sign")
      (?$,2#o(B "music sharp sign")
      (?$,2#m(B "music flat sign")
      (?$,1x"(B "partial differential")
      (?$,1x>(B "infinity")
      (?$,1yh(B "true")
      (?$,1uC(B "degree celsius"))
     ("Symbols 2"
      (?$,2!a(B "white square")
      (?$,2"'(B "white diamond")
      (?$,2"*(B "lozenge")
      (?$,2!u(B "white up-pointing small triangle")
      (?$,2!(B "white down-pointing small triangle")
      (?$,1x1(B "n-ary summation")
      (?$,1x/(B "n-ary product")
      (?$,1x0(B "n-ary coproduct")
      (?$,1xK(B "integral")
      (?$,1xN(B "contour integral")
      (?$,1z"(B "n-ary intersection")
      (?$,1z#(B "n-ary union")
      (?$,1z!(B "n-ary logical or")
      (?$,1z (B "n-ary logical and")
      (?$,1uU(B "double-struck capital n")
      (?$,1uY(B "double-struck capital p")
      (?$,1u](B "double-struck capital r")
      (?$,1ud(B "double-struck capital z")
      (?$,1uP(B "script capital i")
      (?$,1![(B "latin small letter lambda with stroke")
      (?$,1xT(B "therefore")
      (?$,1s&(B "horizontal ellipsis")
      (?$,1zO(B "midline horizontal ellipsis")
      (?$,1zN(B "vertical ellipsis")
      (?$,1zQ(B "down right diagonal ellipsis")
      (?$,1zP(B "up right diagonal ellipsis"))
     ("Symbols 3"      
      (?$,2,!(B "z notation spot")
      (?$,2,"(B "z notation type colon")
      (?$,2-_(B "z notation schema composition")
      (?$,2-`(B "z notation schema piping")
      (?$,2-a(B "z notation schema projection")
      (?$,2-~(B "z notation relational composition")
      (?$,2.D(B "z notation domain antirestriction")
      (?$,2.E(B "z notation range antirestriction")
      (?$,1x.(B "end of proof")
      (?$,2'B(B "perpendicular")
      (?$,2#c(B "black club suit")
      (?$,2#b(B "white diagonal suit")
      (?$,2#e(B "black heart suit")
      (?$,2#`(B "black spade suit")
      (?$A!C(B"ratio")
      (?$A!K(B "proportion")
      (?$,1xA(B "measured angle")
      (?$,1xB(B "spherical angle"))
     ("Delimiters"
      (?\$,1zj(B "left floor")
      (?\$,1zh(B "left ceiling")
      (?\$,1{)(B "left-pointing angle bracket")
      (?\$,1zk(B "right floor")
      (?\$,1zi(B "right ceiling")
      (?\$,1{*(B "right-pointing angle bracket")
      (?\$,2=Z(B "left white square bracket")
      (?\$,2=[(B "right white square bracket")
      (?\$,2=J(B "left double angle bracket")
      (?\$,2=K(B "right double angle bracket")
      (?\$,2,'(B "z notation left image bracket")
      (?\$,2,((B "z notation right image bracket")
      (?\$,2,)(B "z notation left binding bracket")
      (?\$,2,*(B "z notation right binding bracket"))
     ("Greek LC"
      (?$,1'1(B "alpha")
      (?$,1'2(B "beta")
      (?$,1'3(B "gamma")
      (?$,1'4(B "delta")
      (?$,1'5(B "epsilon")
      (?$,1'u(B "greek lunate epsilon symbol")
      (?$,1'6(B "zeta")
      (?$,1'7(B "eta")
      (?$,1'8(B "theta")
      (?$,1'Q(B "theta symbol")
      (?$,1'9(B "iota")
      (?$,1':(B "kappa")
      (?$,1';(B "lamda")
      (?$,1'<(B "mu")
      (?$,1'=(B "nu")
      (?$,1'>(B "xi")
      (?$,1'@(B "pi")
      (?$,1'V(B "pi symbol")
      (?$,1'A(B "rho")
      (?$,1'q(B "rho symbol")
      (?$,1'C(B "sigma")
      (?$,1'B(B "final sigma")
      (?$,1'D(B "tau")
      (?$,1'E(B "upsilon")
      (?$,1'R(B "greek upsilon with hook symbol")
      (?$,1'F(B "phi")
      (?$,1'U(B "phi symbol")
      (?$,1'G(B "chi")
      (?$,1'H(B "psi")
      (?$,1'I(B "omega")
      (?$,1'](B "greek small letter digamma")
      (?$,1'p(B "greek kappa symbol"))
     ("Greek UC"
      (?$,1&s(B "Gamma")
      (?$,1&t(B "Delta")
      (?$,1&x(B "Theta")
      (?$,1&{(B "Lamda")
      (?$,1&~(B "Xi")
      (?$,1' (B "Pi")
      (?$,1'#(B "Sigma")
      (?$,1'%(B "Upsilon")
      (?$,1'&(B "Phi")
      (?$,1'((B "Psi")
      (?$,1')(B "Omega"))
     ("Sub/super"
      (?$,1s}(B "superscript left parenthesis")
      (?$,1s~(B "superscript right parenthesis")
      (?$,1sz(B "superscript plus sign")
      (?$,1s{(B "superscript minus")
      (?$,1sp(B "superscript zero")
      (?,A9(B "superscript one")
      (?,A2(B "superscript two")
      (?,A3(B "superscript three")
      (?$,1st(B "superscript four")
      (?$,1su(B "superscript five")
      (?$,1sv(B "superscript six")
      (?$,1sw(B "superscript seven")
      (?$,1sx(B "superscript eight")
      (?$,1sy(B "superscript nine")
      (?$,1t-(B "subscript left parenthesis")
      (?$,1t.(B "subscript right parenthesis")
      (?$,1t*(B "subscript plus sign")
      (?$,1t+(B "subscript minus")
      (?$,1t (B "subscript zero")
      (?$,1t!(B "subscript one")
      (?$,1t"(B "subscript two")
      (?$,1t#(B "subscript three")
      (?$,1t$(B "subscript four")
      (?$,1t%(B "subscript five")
      (?$,1t&(B "subscript six")
      (?$,1t'(B "subscript seven")
      (?$,1t((B "subscript eight")
      (?$,1t)(B "subscript nine")))))

;;; Others from auctex maths menu.  I'm not sure how many of these are
;;; worth ading, but note that some of them are combining characters,
;;; which probably need a post-insertion hook.

;; (nil "preceq" "Relational" 10927) ;; #X2AAF $,2//(B
;; (nil "succeq" "Relational" 10928) ;; #X2AB0 $,2/0(B
;; (nil "jmath" "Misc Symbol" 120485) ;; #X1D6A5 
;; (?/ "not" "Misc Symbol" 824) ;; #X0338 $,1%x(B
;; (nil "bigsqcup" "Var Symbol" 10758) ;; #X2A06 $,2-F(B
;; (nil "bigodot" "Var Symbol" 10752) ;; #X2A00 $,2-@(B
;; (nil "bigotimes" "Var Symbol" 10754) ;; #X2A02 $,2-B(B
;; (nil "bigoplus" "Var Symbol" 10753) ;; #X2A01 $,2-A(B
;; (nil "biguplus" "Var Symbol" 10756) ;; #X2A04 $,2-D(B
;; (nil "rmoustache" "Delimiters" 9137) ;; #X23B1 $,1|Q(B
;; (nil "lmoustache" "Delimiters" 9136) ;; #X23B0 $,1|P(B
;; (nil "widetilde" "Constructs" 771) ;; #X0303 $,1%C(B
;; (nil "widehat" "Constructs" 770) ;; #X0302 $,1%B(B
;; (nil "overleftarrow" "Constructs" 8406) ;; #X20D6 $,1tv(B
;; (nil "overbrace" "Constructs" 65079) ;; #XFE37 $,3pW(B
;; (nil "underbrace" "Constructs" 65080) ;; #XFE38 $,3pX(B
;; (?^ "hat" "Accents" 770) ;; #X0302 $,1%B(B
;; (nil "acute" "Accents" 769) ;; #X0301 $,1%A(B
;; (nil "bar" "Accents" 772) ;; #X0304 $,1%D(B
;; (nil "dot" "Accents" 775) ;; #X0307 $,1%G(B
;; (nil "breve" "Accents" 774) ;; #X0306 $,1%F(B
;; (nil "check" "Accents" 780) ;; #X030C $,1%L(B
;; (nil "grave" "Accents" 768) ;; #X0300 $,1%@(B
;; (nil "vec" "Accents" 8407) ;; #X20D7 $,1tw(B
;; (nil "ddot" "Accents" 776) ;; #X0308 $,1%H(B
;; (?~ "tilde" "Accents" 771) ;; #X0303 $,1%C(B
;; (nil "beth" ("AMS" "Hebrew") 8502) ;; #X2136 $,1uv(B
;; (nil "daleth" ("AMS" "Hebrew") 8504) ;; #X2138 $,1ux(B
;; (nil "gimel" ("AMS" "Hebrew") 8503) ;; #X2137 $,1uw(B
;; (nil "leftleftarrows" ("AMS" "Arrows") 8647) ;; #X21C7 $,1wG(B
;; (nil "Lleftarrow" ("AMS" "Arrows") 8666) ;; #X21DA $,1wZ(B
;; (nil "twoheadleftarrow" ("AMS" "Arrows") 8606) ;; #X219E $,1v~(B
;; (nil "leftarrowtail" ("AMS" "Arrows") 8610) ;; #X21A2 $,1w"(B
;; (nil "looparrowleft" ("AMS" "Arrows") 8619) ;; #X21AB $,1w+(B
;; (nil "curvearrowleft" ("AMS" "Arrows") 8630) ;; #X21B6 $,1w6(B
;; (nil "Lsh" ("AMS" "Arrows") 8624) ;; #X21B0 $,1w0(B
;; (nil "upuparrows" ("AMS" "Arrows") 8648) ;; #X21C8 $,1wH(B
;; (nil "multimap" ("AMS" "Arrows") 8888) ;; #X22B8 $,1yx(B
;; (nil "leftrightsquigarrow" ("AMS" "Arrows") 8621) ;; #X21AD $,1w-(B
;; (nil "looparrowright" ("AMS" "Arrows") 8620) ;; #X21AC $,1w,(B
;; (nil "curvearrowright" ("AMS" "Arrows") 8631) ;; #X21B7 $,1w7(B
;; (nil "Rsh" ("AMS" "Arrows") 8625) ;; #X21B1 $,1w1(B
;; (nil "downdownarrows" ("AMS" "Arrows") 8650) ;; #X21CA $,1wJ(B
;; (nil "nleftarrow" ("AMS" "Neg Arrows") 8602) ;; #X219A $,1vz(B
;; (nil "nrightarrow" ("AMS" "Neg Arrows") 8603) ;; #X219B $,1v{(B
;; (nil "nLeftarrow" ("AMS" "Neg Arrows") 8653) ;; #X21CD $,1wM(B
;; (nil "nRightarrow" ("AMS" "Neg Arrows") 8655) ;; #X21CF $,1wO(B
;; (nil "nleftrightarrow" ("AMS" "Neg Arrows") 8622) ;; #X21AE $,1w.(B
;; (nil "nLeftrightarrow" ("AMS" "Neg Arrows") 8654) ;; #X21CE $,1wN(B
;; (nil "leqq" ("AMS" "Relational I") 8806) ;; #X2266 $,1y&(B
;; (nil "leqslant" ("AMS" "Relational I") 10877) ;; #X2A7D $,2.](B
;; (nil "eqslantless" ("AMS" "Relational I") 10901) ;; #X2A95 $,2.u(B
;; (nil "lessapprox" ("AMS" "Relational I") 10885) ;; #X2A85 $,2.e(B
;; (nil "approxeq" ("AMS" "Relational I") 8778) ;; #X224A $,1xj(B
;; (nil "lessdot" ("AMS" "Relational I") 8918) ;; #X22D6 $,1z6(B
;; (nil "lll" ("AMS" "Relational I") 8920) ;; #X22D8 $,1z8(B
;; (nil "lessgtr" ("AMS" "Relational I") 8822) ;; #X2276 $,1y6(B
;; (nil "lesseqgtr" ("AMS" "Relational I") 8922) ;; #X22DA $,1z:(B
;; (nil "lesseqqgtr" ("AMS" "Relational I") 10891) ;; #X2A8B $,2.k(B
;; (nil "risingdotseq" ("AMS" "Relational I") 8787) ;; #X2253 $,1xs(B
;; (nil "fallingdotseq" ("AMS" "Relational I") 8786) ;; #X2252 $,1xr(B
;; (nil "backsim" ("AMS" "Relational I") 8765) ;; #X223D $,1x](B
;; (nil "backsimeq" ("AMS" "Relational I") 8909) ;; #X22CD $,1z-(B
;; (nil "subseteqq" ("AMS" "Relational I") 10949) ;; #X2AC5 $,2/E(B
;; (nil "Subset" ("AMS" "Relational I") 8912) ;; #X22D0 $,1z0(B
;; (nil "preccurlyeq" ("AMS" "Relational I") 8828) ;; #X227C $,1y<(B
;; (nil "curlyeqprec" ("AMS" "Relational I") 8926) ;; #X22DE $,1z>(B
;; (nil "precsim" ("AMS" "Relational I") 8830) ;; #X227E $,1y>(B
;; (nil "precapprox" ("AMS" "Relational I") 10935) ;; #X2AB7 $,2/7(B
;; (nil "vartriangleleft" ("AMS" "Relational I") 8882) ;; #X22B2 $,1yr(B
;; (nil "Vvdash" ("AMS" "Relational I") 8874) ;; #X22AA $,1yj(B
;; (nil "Bumpeq" ("AMS" "Relational I") 8782) ;; #X224E $,1xn(B
;; (nil "geqq" ("AMS" "Relational II") 8807) ;; #X2267 $,1y'(B
;; (nil "geqslant" ("AMS" "Relational II") 10878) ;; #X2A7E $,2.^(B
;; (nil "eqslantgtr" ("AMS" "Relational II") 10902) ;; #X2A96 $,2.v(B
;; (nil "gtrapprox" ("AMS" "Relational II") 10886) ;; #X2A86 $,2.f(B
;; (nil "gtrdot" ("AMS" "Relational II") 8919) ;; #X22D7 $,1z7(B
;; (nil "ggg" ("AMS" "Relational II") 8921) ;; #X22D9 $,1z9(B
;; (nil "gtrless" ("AMS" "Relational II") 8823) ;; #X2277 $,1y7(B
;; (nil "gtreqless" ("AMS" "Relational II") 8923) ;; #X22DB $,1z;(B
;; (nil "gtreqqless" ("AMS" "Relational II") 10892) ;; #X2A8C $,2.l(B
;; (nil "eqcirc" ("AMS" "Relational II") 8790) ;; #X2256 $,1xv(B
;; (nil "circeq" ("AMS" "Relational II") 8791) ;; #X2257 $,1xw(B
;; (nil "supseteqq" ("AMS" "Relational II") 10950) ;; #X2AC6 $,2/F(B
;; (nil "Supset" ("AMS" "Relational II") 8913) ;; #X22D1 $,1z1(B
;; (nil "curlyeqsucc" ("AMS" "Relational II") 8927) ;; #X22DF $,1z?(B
;; (nil "succsim" ("AMS" "Relational II") 8831) ;; #X227F $,1y?(B
;; (nil "succapprox" ("AMS" "Relational II") 10936) ;; #X2AB8 $,2/8(B
;; (nil "vartriangleright" ("AMS" "Relational II") 8883) ;; #X22B3 $,1ys(B
;; (nil "Vdash" ("AMS" "Relational II") 8873) ;; #X22A9 $,1yi(B
;; (nil "between" ("AMS" "Relational II") 8812) ;; #X226C $,1y,(B
;; (nil "pitchfork" ("AMS" "Relational II") 8916) ;; #X22D4 $,1z4(B
;; (nil "blacktriangleleft" ("AMS" "Relational II") 9664) ;; #X25C0 $,2" (B
;; (nil "backepsilon" ("AMS" "Relational II") 1014) ;; #X03F6 $,1'v(B
;; (nil "blacktriangleright" ("AMS" "Relational II") 9654) ;; #X25B6 $,2!v(B
;; (nil "nless" ("AMS" "Neg Rel I") 8814) ;; #X226E $,1y.(B
;; (nil "nleq" ("AMS" "Neg Rel I") 8816) ;; #X2270 $,1y0(B
;; (nil "lneq" ("AMS" "Neg Rel I") 10887) ;; #X2A87 $,2.g(B
;; (nil "lneqq" ("AMS" "Neg Rel I") 8808) ;; #X2268 $,1y((B
;; (nil "lnsim" ("AMS" "Neg Rel I") 8934) ;; #X22E6 $,1zF(B
;; (nil "lnapprox" ("AMS" "Neg Rel I") 10889) ;; #X2A89 $,2.i(B
;; (nil "nprec" ("AMS" "Neg Rel I") 8832) ;; #X2280 $,1y@(B
;; (nil "precnsim" ("AMS" "Neg Rel I") 8936) ;; #X22E8 $,1zH(B
;; (nil "precnapprox" ("AMS" "Neg Rel I") 10937) ;; #X2AB9 $,2/9(B
;; (nil "nsim" ("AMS" "Neg Rel I") 8769) ;; #X2241 $,1xa(B
;; (nil "nshortmid" ("AMS" "Neg Rel I") 8740) ;; #X2224 $,1xD(B
;; (nil "nmid" ("AMS" "Neg Rel I") 8740) ;; #X2224 $,1xD(B
;; (nil "nvdash" ("AMS" "Neg Rel I") 8876) ;; #X22AC $,1yl(B
;; (nil "nvDash" ("AMS" "Neg Rel I") 8877) ;; #X22AD $,1ym(B
;; (nil "ntriangleleft" ("AMS" "Neg Rel I") 8938) ;; #X22EA $,1zJ(B
;; (nil "ntrianglelefteq" ("AMS" "Neg Rel I") 8940) ;; #X22EC $,1zL(B
;; (nil "nsubseteq" ("AMS" "Neg Rel I") 8840) ;; #X2288 $,1yH(B
;; (nil "subsetneq" ("AMS" "Neg Rel I") 8842) ;; #X228A $,1yJ(B
;; (nil "subsetneqq" ("AMS" "Neg Rel I") 10955) ;; #X2ACB $,2/K(B
;; (nil "ngtr" ("AMS" "Neg Rel II") 8815) ;; #X226F $,1y/(B
;; (nil "ngeq" ("AMS" "Neg Rel II") 8817) ;; #X2271 $,1y1(B
;; (nil "gneq" ("AMS" "Neg Rel II") 10888) ;; #X2A88 $,2.h(B
;; (nil "gneqq" ("AMS" "Neg Rel II") 8809) ;; #X2269 $,1y)(B
;; (nil "gnsim" ("AMS" "Neg Rel II") 8935) ;; #X22E7 $,1zG(B
;; (nil "gnapprox" ("AMS" "Neg Rel II") 10890) ;; #X2A8A $,2.j(B
;; (nil "nsucc" ("AMS" "Neg Rel II") 8833) ;; #X2281 $,1yA(B
;; (nil "succnsim" ("AMS" "Neg Rel II") 8937) ;; #X22E9 $,1zI(B
;; (nil "succnapprox" ("AMS" "Neg Rel II") 10938) ;; #X2ABA $,2/:(B
;; (nil "ncong" ("AMS" "Neg Rel II") 8775) ;; #X2247 $,1xg(B
;; (nil "nshortparallel" ("AMS" "Neg Rel II") 8742) ;; #X2226 $,1xF(B
;; (nil "nparallel" ("AMS" "Neg Rel II") 8742) ;; #X2226 $,1xF(B
;; (nil "nvDash" ("AMS" "Neg Rel II") 8877) ;; #X22AD $,1ym(B
;; (nil "nVDash" ("AMS" "Neg Rel II") 8879) ;; #X22AF $,1yo(B
;; (nil "ntriangleright" ("AMS" "Neg Rel II") 8939) ;; #X22EB $,1zK(B
;; (nil "ntrianglerighteq" ("AMS" "Neg Rel II") 8941) ;; #X22ED $,1zM(B
;; (nil "nsupseteq" ("AMS" "Neg Rel II") 8841) ;; #X2289 $,1yI(B
;; (nil "supsetneq" ("AMS" "Neg Rel II") 8843) ;; #X228B $,1yK(B
;; (nil "supsetneqq" ("AMS" "Neg Rel II") 10956) ;; #X2ACC $,2/L(B
;; (nil "dotplus" ("AMS" "Binary Op") 8724) ;; #X2214 $,1x4(B
;; (nil "Cap" ("AMS" "Binary Op") 8914) ;; #X22D2 $,1z2(B
;; (nil "Cup" ("AMS" "Binary Op") 8915) ;; #X22D3 $,1z3(B
;; (nil "barwedge" ("AMS" "Binary Op") 8892) ;; #X22BC $,1y|(B
;; (nil "veebar" ("AMS" "Binary Op") 8891) ;; #X22BB $,1y{(B
;; (nil "doublebarwedge" ("AMS" "Binary Op") 8966) ;; #X2306 $,1zf(B
;; (nil "boxminus" ("AMS" "Binary Op") 8863) ;; #X229F $,1y_(B
;; (nil "boxtimes" ("AMS" "Binary Op") 8864) ;; #X22A0 $,1y`(B
;; (nil "boxdot" ("AMS" "Binary Op") 8865) ;; #X22A1 $,1ya(B
;; (nil "boxplus" ("AMS" "Binary Op") 8862) ;; #X229E $,1y^(B
;; (nil "divideontimes" ("AMS" "Binary Op") 8903) ;; #X22C7 $,1z'(B
;; (nil "ltimes" ("AMS" "Binary Op") 8905) ;; #X22C9 $,1z)(B
;; (nil "rtimes" ("AMS" "Binary Op") 8906) ;; #X22CA $,1z*(B
;; (nil "leftthreetimes" ("AMS" "Binary Op") 8907) ;; #X22CB $,1z+(B
;; (nil "rightthreetimes" ("AMS" "Binary Op") 8908) ;; #X22CC $,1z,(B
;; (nil "curlywedge" ("AMS" "Binary Op") 8911) ;; #X22CF $,1z/(B
;; (nil "curlyvee" ("AMS" "Binary Op") 8910) ;; #X22CE $,1z.(B
;; (nil "circleddash" ("AMS" "Binary Op") 8861) ;; #X229D $,1y](B
;; (nil "circledast" ("AMS" "Binary Op") 8859) ;; #X229B $,1y[(B
;; (nil "circledcirc" ("AMS" "Binary Op") 8858) ;; #X229A $,1yZ(B
;; (nil "intercal" ("AMS" "Binary Op") 8890) ;; #X22BA $,1yz(B
;; (nil "circledS" ("AMS" "Misc") 9416) ;; #X24C8 $,1H(B
;; (nil "measuredangle" ("AMS" "Misc") 8737) ;; #X2221 $,1xA(B
;; (nil "Finv" ("AMS" "Misc") 8498) ;; #X2132 $,1ur(B
;; (nil "Game" ("AMS" "Misc") 8513) ;; #X2141 $,1v!(B
;; (nil "Bbbk" ("AMS" "Misc") 120156) ;; #X1D55C 
;; (nil "backprime" ("AMS" "Misc") 8245) ;; #X2035 $,1s5(B
;; (nil "blacktriangle" ("AMS" "Misc") 9652) ;; #X25B4 $,2!t(B
;; (nil "blacktriangledown" ("AMS" "Misc") 9662) ;; #X25BE $,2!~(B
;; (nil "blacksquare" ("AMS" "Misc") 9632) ;; #X25A0 $,2!`(B
;; (nil "blacklozenge" ("AMS" "Misc") 10731) ;; #X29EB $,2-+(B
;; (nil "bigstar" ("AMS" "Misc") 9733) ;; #X2605 $,2"e(B
;; (nil "sphericalangle" ("AMS" "Misc") 8738) ;; #X2222 $,1xB(B
;; (nil "complement" ("AMS" "Misc") 8705) ;; #X2201 $,1x!(B
;; (nil "eth" ("AMS" "Misc") 240) ;; #X00F0 ,Ap(B
;; (nil "diagup" ("AMS" "Misc") 9585) ;; #X2571 $,2!1(B
;; (nil "diagdown" ("AMS" "Misc") 9586) ;; #X2572 $,2!2(B
;; (nil "dddot" ("AMS" "Accents") 8411) ;; #X20DB $,1t{(B
;; (nil "ddddot" ("AMS" "Accents") 8412) ;; #X20DC $,1t|(B
;; (nil "ulcorner" ("AMS" "Delimiters") 8988) ;; #X231C $,1z|(B
;; (nil "urcorner" ("AMS" "Delimiters") 8989) ;; #X231D $,1z}(B
;; (nil "llcorner" ("AMS" "Delimiters") 8990) ;; #X231E $,1z~(B
;; (nil "lrcorner" ("AMS" "Delimiters") 8991) ;; #X231F $,1z(B

(defvar maths-menu-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [menu-bar maths]
      `(menu-item "Maths" ,maths-menu-menu
		  :help "Menu of maths characters to insert"))
    map))

;; Unless we have Gtk menus, we probably can't display the maths
;; correctly in the menu bar.  Actually, it seems to work with Athena
;; widgets in a UTF-8 locale in Ubuntu with Emacs 22; or it seemed to
;; -- I can't now reproduce that.
;; Fixme:  Sort out the conditions in which it does work.
(unless (or (string-match "--with-x-toolkit=gtk" system-configuration-options)
	    (string-match "--with-gtk" system-configuration-options))
  (define-key-after maths-menu-menu [warnl] '(menu-item "--"))
  (define-key-after maths-menu-menu [warn1]
    '(menu-item "NB. This Emacs may display"))
  (define-key-after maths-menu-menu [warn2]
    '(menu-item "the maths chars wrongly"))
  (define-key-after maths-menu-menu [warn3]
    '(menu-item "in the menus."))
  ;; Another approach:
;;;       (define-key maths-menu-mode-map [menu-bar maths]
;;; 	(cons "Maths" (lambda ()
;;; 			(interactive)
;;; 			(tmm-prompt maths-menu-menu))))
  )

;;;###autoload
(define-minor-mode maths-menu-mode
  "Install a menu for entering mathematical characters.
Uses window system menus only when they can display multilingual text.
Otherwise the menu-bar item activates the text-mode menu system.
This mode is only useful with a font which can display the maths repertoire."
  nil nil maths-menu-mode-map)

(provide 'maths-menu)
;;; maths-menu.el ends here
