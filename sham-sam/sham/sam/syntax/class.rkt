#lang racket

(require syntax/parse)

(require "kw-info.rkt"
         "ooo.rkt")

(module* pat #f
  (require "pat.rkt"
           "ooo.rkt")
  (provide (all-defined-out))
  (define-syntax-class syn-pat
    (pattern name:id #:attr pat (pat:syn #`name)))
  (define-syntax-class dat-pat
    (pattern ((~datum quote) val:id) #:attr pat (pat:dat #`val)))
  (define-splicing-syntax-class seq-pat
    (pattern (~seq v:expr ...) #:attr pat (pat:seq (attribute v))))
  (define-splicing-syntax-class ooo-pat
    (pattern (~seq maybe-repeat:expr maybe-ooo:id)
             #:when (ooo? #`maybe-ooo)
             #:attr pat (pat:ooo (attribute maybe-repeat) (ooo #`maybe-ooo))))
  (define-syntax-class app-pat
    (pattern (v:expr . body:expr) #:attr pat (pat:app #`v #`body)))
  (define-syntax-class pat-cls))

(module* ast #f
  (provide (all-defined-out))
  (require (submod "spec.rkt" ast))
  (define-syntax-class node-pattern
    (pattern name:id
             #:attr spec (ast:pat:single #f #`name))
    (pattern ((~datum quote) datum:id)
             #:attr spec (ast:pat:datum #`datum))
    (pattern ((~datum ?) check:id name:id)
             #:attr spec (ast:pat:single (cons '? #`check) #`name))
    (pattern ((~datum ~) type:expr name:id)
             #:attr spec (ast:pat:single (cons '~ #`type) #`name))
    (pattern ((~datum !) type:expr name:id)
             #:attr spec (ast:pat:single (cons '! #`type) #`name))
    (pattern (multiple:node-multiple-pattern ...)
             #:attr spec (ast:pat:multiple (apply vector-immutable (attribute multiple.spec)))))
  (define-splicing-syntax-class node-multiple-pattern
    ;; (pattern (~seq repeat:node-pattern (~datum ...))
    ;;          #:attr spec (ast:pat:repeat (attribute repeat.spec) (cons 0 #f)))
    (pattern (~seq maybe-repeat:node-pattern maybe-ooo:id)
             #:when (ooo? #`maybe-ooo)
             #:attr spec (ast:pat:repeat (attribute maybe-repeat.spec) (ooo #`maybe-ooo)))
    (pattern ms:node-pattern
             #:attr spec (attribute ms.spec)))

  (define-syntax-class ast-node
    #:description "node production production"
    (pattern (var:id def:node-pattern info:keyword-info)
             #:attr spec (ast:node #`var (attribute info.spec) #f (attribute def.spec))))

  (define-syntax-class ast-group
    #:description "ast group specification"
    (pattern (name:id (~optional parent:id) nodes:ast-node ... info:keyword-info)
             #:attr spec (ast:group #`name (attribute info.spec) (attribute parent) #f (attribute nodes.spec))))

  (define-splicing-syntax-class ast-spec
    (pattern (~seq name:id groups:ast-group ... info:keyword-info)
             #:attr spec (ast #f #`name (attribute groups.spec) (attribute info.spec)))))

#;(module* reader #f
  (require (submod "spec.rkt" reader))
  (provide (all-defined-out))
  (define-syntax-class language-spec
    #:description "language specification"
    (pattern (lang:id (name:id var:id ...) ...)))
  (define-splicing-syntax-class reader-spec
    #:description "sham language reader specification"
    (pattern (~seq ast:id info:keyword-info)
             #:attr spec (reader #`ast (attribute info.spec)))))

(module* compiler #f
  (require (submod "spec.rkt" compiler))
  (provide (all-defined-out))

  (define-syntax-class compiler-type
    (pattern (from:id (~datum ->) to:id) #:attr spec (cmplr:type #'from #'to)))

  (define-syntax-class compiler-group
    (pattern (name:id type:compiler-type (node-binding:expr node-body:expr ...) ... info:keyword-info)
             #:attr spec (cmplr:group #`name
                                      (attribute type.spec)
                                      (map cons (attribute node-binding) (attribute node-body))
                                      (attribute info.spec))))

  (define-splicing-syntax-class compiler-header
    (pattern (~seq (name:id [arg:id dflt:expr] ...) type:compiler-type)
             #:attr spec (cmplr:header #`name (map cons (attribute arg) (attribute dflt)) (attribute type.spec))))

  (define-splicing-syntax-class compiler-spec
    (pattern (~seq header:compiler-header groups:compiler-group ... info:keyword-info)
             #:attr spec (cmplr (attribute header.spec) (attribute groups.spec) (attribute info.spec)))))