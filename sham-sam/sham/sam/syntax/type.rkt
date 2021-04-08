#lang racket

(require "spec.rkt"
         (only-in "private/utils.rkt" info-value type-from-id))
;; TODO

(provide (all-defined-out))

(define (group-arg-type-assoc gargs spec)
  (match-define (ast:group id parent args nodes ginfo) spec)
  (for/list ([orig (info-value ginfo `#:common)]
             [fmted gargs])
    (cons orig
          (match (symbol->string (syntax->datum fmted))
            [(regexp #rx"^!identifier$") (ast:type:identifier)]
            [(regexp #rx"^!(.*)$" (list _ checker)) (ast:type:unboxed checker)]
            [(pregexp #px"^(.*):(.*)" (list _ id type))
             (ast:type:internal
              (map (compose (curry datum->syntax #f) string->symbol)
                   (string-split type ".")) 0)]))))

(define (node-arg-type nspec)
  (match-define (ast:node id args pat info) nspec)
  (define (rec pat depth)
    (match pat
      [(ast:pat:single c s) (ast:node:arg s (if c (ast:type:external c depth) (type-from-id s depth)) #f)]
      [(ast:pat:datum d) #f]
      [(ast:pat:multiple s) (map (curryr rec depth) (vector->list s))]
      [(ast:pat:repeat r k) (rec r (add1 depth))]))
  (filter (compose not false?) (flatten (rec pat 0))))