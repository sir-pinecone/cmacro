(in-package :cl-user)
(defpackage :cmacro.token
  (:use :cl :anaphora)
  (:import-from :trivial-types
                :proper-list)
  (:import-from :split-sequence
                :split-sequence)
  (:export :<token>
           :token-position
           :token-line
           :token-text
           :token-equal
           :list-type
           :<void-token>
           :<number>
           :<integer>
           :<real>
           :<identifier>
           :<string>
           :<operator>
           :<variable>
           :var-name
           :var-rest-p
           :var-qualifiers
           :make-variable
           :var-list-p
           :var-array-p
           :var-block-p
           :var-group-p))
(in-package :cmacro.token)

;;; Tokens

(defclass <token> ()
  ((line :initarg :line
         :reader token-line
         :type integer)))

(defclass <void-token> (<token>) ())

(defclass <text-token> (<token>)
  ((text :initarg :text
         :reader token-text
         :type string)))

(defmethod print-object ((tok <text-token>) stream)
  (format stream "~A" (token-text tok)))

(defmethod token-equal ((a <text-token>) (b <text-token>))
  (equal (token-text a) (token-text b)))

(defun ast-equal (ast-a ast-b)
  (let* ((ast-a (flatten ast-a))
         (ast-b (flatten ast-b))
         (len-a (length ast-a))
         (len-b (length ast-b)))
    (when (eql len-a len-b)
      ;; Compare individual items
      (loop for i from 0 to (1- len-a) do
        (if (not (token-equal (nth i ast-a)
                              (nth i ast-b)))
            (return nil)))
        t)))

(defparameter +group-types+ (list :list :array :block))

(defun list-type (list)
  (aif (first list)
       (and (keywordp it)
            (first (member it +group-types+)))))

;;; Token subclasses

(defclass <number> (<text-token>) ())
(defclass <integer> (<number>) ())
(defclass <real> (<number>) ())
(defclass <identifier> (<text-token>) ())
(defclass <string> (<text-token>) ())
(defclass <operator> (<text-token>) ())

;;; Variables

(defclass <variable> (<token>)
  ((name :initarg :name
         :reader var-name
         :type string)
   (restp :initarg :restp
          :reader var-rest-p
          :type boolean)
   (qualifiers :initarg :qualifiers
               :reader var-qualifiers
               :type (proper-list string))))

(defun make-variable (text)
  (let* ((args (split-sequence #\Space text))
         (name (pop args))
         (restp (if (member "rest" args :test #'equal) t)))
  (make-instance '<variable>
                 :name name
                 :restp restp
                 :qualifiers (remove-duplicates args))))

;;; Utility functions

(defun var-p (pattern)
  (eq (type-of pattern) '<variable>))

(defun rest-p (pattern)
  (and (var-p pattern) (var-rest-p pattern)))

(defun atomic-var-p (pattern)
  (and (var-p pattern) (not (rest-p pattern))))

(defmethod var-list-p ((var <variable>))
  (if (member "list" (var-qualifiers var) :test #'equal) t))

(defmethod var-array-p ((var <variable>))
  (if (member "array" (var-qualifiers var) :test #'equal) t))

(defmethod var-block-p ((var <variable>))
  (if (member "block" (var-qualifiers var) :test #'equal) t))

(defmethod var-group-p ((var <variable>))
  "The variable matches any kind of group: Lists, arrays and blocks."
  (if (member "group" (var-qualifiers var) :test #'equal) t))  

(defmethod var-command-p ((var <variable>))
  "Is the variable a template command?"
  (char= #\@ (elt (var-name var) 0)))
