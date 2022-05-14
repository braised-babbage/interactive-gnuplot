(in-package #:interactive-gnuplot)

(defconstant +left-brace+ #\{)
(defconstant +right-brace+ #\})

(defun read-left-brace (stream char)
  "Read from a left brace until we have a matching right brace."
  (declare (ignore char))
  (fragment
   (with-output-to-string (out-stream)
     (loop :with unmatched-braces := 1
           :for c := (peek-char nil stream nil nil t)
	   :until (or (null c)
		      (zerop unmatched-braces))
	   ;; Ok, consume the next character.
	   :do (progn
		 (read-char stream t nil t)
		 (incf unmatched-braces
		       (cond ((char= c +left-brace+) 1)
			     ((char= c +right-brace+) -1)
			     (t 0)))
		 (when (plusp unmatched-braces)
		   (write-char c out-stream)))))))

(defun error-on-delimiter (stream char)
  "Raise an error if we hit a delimiter (e.g. }) in an unexpected context."
  (declare (ignore stream))
  (error "Delimiter ~S shouldn't be read alone" char))

(named-readtables:defreadtable fragment-syntax
  (:merge :standard)
  (:macro-char +left-brace+ #'read-left-brace)
  (:macro-char +right-brace+ #'error-on-delimiter))
