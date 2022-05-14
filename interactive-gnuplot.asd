(asdf:defsystem #:interactive-gnuplot
  :author "Erik Davis <erik@cadlag.org>"
  :license "MIT"
  :description "An extremely lightweight interface to a Gnuplot process."
  :depends-on (#:named-readtables)
  :serial t
  :pathname "src/"
  :components ((:file "package")
               (:file "gnuplot")
	       (:file "reader-extension")))
