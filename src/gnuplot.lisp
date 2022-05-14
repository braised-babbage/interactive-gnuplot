(in-package #:interactive-gnuplot)

(defvar *gnuplot-process* nil
  "Process info for the active Gnuplot process.")

(defparameter *gnuplot-timeout-seconds* 1d0
  "Default number of seconds to allow for a response from the Gnuplot process.")

(defun launch-gnuplot ()
  "Launch the Gnuplot process, if there is none active."
  (flet ((launch-op ()
	   (uiop:launch-program
	    (list "gnuplot" "--persist")
	    :input :stream
	    :output :stream
	    :error-output :stream)))
    (cond ((null *gnuplot-process*)
	   (setf *gnuplot-process* (launch-op)))
	  ((not (uiop:process-alive-p *gnuplot-process*))
	   (uiop:close-streams *gnuplot-process*)
	   (setf *gnuplot-process* (launch-op)))
	  (t nil))))

(defstruct (gnuplot-fragment
	    (:constructor fragment (string)))
  "A representation of part of a gnuplot command."
  string)


(defgeneric translate-to-fragment (obj)
  (:documentation "Translate a Lisp object to a Gnuplot fragment.")
  
  (:method ((obj symbol))
    (fragment (string-downcase (symbol-name obj))))

  (:method ((obj string))
    (fragment (format nil "~S" obj)))

  (:method ((obj integer))
    (fragment (format nil "~D" obj)))

  (:method ((obj real))
    (fragment (format nil "~F" (coerce obj 'double-float))))

  (:method ((obj list))
    (fragment
     (format nil "~{~A~^,~}"
	     (mapcar (lambda (elt) (gnuplot-fragment-string (translate-to-fragment elt)))
		     obj))))

  (:method ((obj gnuplot-fragment))
    obj))

(defun gnuplot-command-string (args)
  "Translate a list of fragments or Lisp objects into a command string."
  (format nil "~{~A~^ ~}"
	  (mapcar (lambda (x)
		    (gnuplot-fragment-string
		     (translate-to-fragment x)))
		  args)))

(defun execute-command (command)
  "Execute a command via the active gnuplot process. 

If there is no active process, this creates one."
  (unless *gnuplot-process*
    (setf *gnuplot-process* (launch-gnuplot)))
  (let* ((sentinel (write-to-string (random (expt 2 64)))))
    (format (uiop:process-info-input *gnuplot-process*)
	    "~A~%" command)
    (format (uiop:process-info-input *gnuplot-process*)
	    "print ~S~%" sentinel)
    (finish-output (uiop:process-info-input *gnuplot-process*))
    (multiple-value-bind (msg read-success)
	(read-input-until-sentinel
	 (uiop:process-info-error-output *gnuplot-process*)
	 sentinel)
      (unless read-success
	(error "Timeout reading from gnuplot output. Partial result: ~%~A" msg))
      (if (zerop (length msg))
	  nil
	  msg))))


(defun read-input-until-sentinel (stream sentinel &key (timeout-seconds *gnuplot-timeout-seconds*))
  "Try to read the input stream STREAM until the string SENTINEL is detected.

This consumes the stream up through SENTINEL, but returns a resulting string with SENTINEL stripped.

The second return value is T if the read is successful, and NIL if the total read time exceeds TIMEOUT-SECONDS.
"
  (let ((start-time (get-internal-real-time))
	(chars nil)
	(index 0)
	(n (length sentinel)))
    (loop :for c := (read-char-no-hang stream)
	   :for elapsed := (/ (- (get-internal-real-time) start-time)
			      internal-time-units-per-second)
	   :until (or (> elapsed timeout-seconds)
		      (>= index n))
	   :when c
	     :do (progn
		   (push c chars)
		   (setf index (if (char= c (elt sentinel index))
				   (1+ index)
				   0))))
    (if (>= index n)
	(values (coerce (nreverse (subseq chars n))
			'string)
		t)
	(values (coerce (nreverse chars) 'string)
		nil))))

(defmacro gnuplot (&body commands)
  "Compile and execute the provided Gnuplot commands."
  `(progn
     ,@(loop :for args :in commands
	     :collect 
	     `(execute-command
	       (gnuplot-command-string (list ,@args))))))
