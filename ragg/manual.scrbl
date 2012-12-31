#lang scribble/manual
@(require scribble/eval
          (for-label racket))


@title{ragg: a Racket AST Generator Generator}
@author+email["Danny Yoo" "dyoo@hashcollision.org"]


@section{Informal Quickstart}

@(define informal-eval (make-base-eval))
@(informal-eval '(require ragg/examples/nested-word-list))
@(informal-eval '(require racket/list))
Let's consider the following scenario: say that we're given the following string:
@racketblock["(radiant (humble))"]


@margin-note{(... and pretend that we don't already know about the built-in
@racket[read] function.)}  How do we go about turn this kind of string into a
structured value?  That is, how would we @emph{parse} it?  We need to first
consider the shape of the things we'd like to parse.

The string above looks like a deeply nested list of words.  How might we
describe this formally?  A convenient notation to describe the shape of these
things is
@link["http://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form"]{Backus-Naur
Form} (BNF).  So let's try to notate the structure of nested word lists in BNF.


@nested[#:style 'code-inset]{
@verbatim{
nested-word-list: WORD
                | LEFT-PAREN nested-word-list* RIGHT-PAREN
}}

What we intend by this notation is this: @racket[nested-word-list] is either an
atomic @racket[WORD], or a parenthesized list of any number of
@racket[nested-word-list]s.  We use the character @litchar{*} to represent zero
or more repetitions of the previous thing, and we treat the uppercased
@racket[LEFT-PAREN], @racket[RIGHT-PAREN], and @racket[WORD] as placeholders
for atomic @emph{tokens}.

Here are a few examples of tokens:
@interaction[#:eval informal-eval
(require ragg/support)
(token 'LEFT-PAREN)
(token 'WORD "crunchy")
(token 'RIGHT-PAREN)]


Have we made progress?  At this point, we only have a BNF description in hand,
but we're still missing a @emph{parser}, something to take that description and
use it to building structure.


It's clear that we don't yet have a program: there's no @litchar{#lang} line.
We should add one.  Put @litchar{#lang ragg} at the top of the BNF
description, and save it as a file called @filepath{nested-word-list.rkt}.

@filebox["nested-word-list.rkt"]{
@verbatim{
#lang ragg
nested-word-list: WORD
                | LEFT-PAREN nested-word-list* RIGHT-PAREN
}}

Ok... now it's a program.  But what does it do?

@interaction[#:eval informal-eval
@eval:alts[(require "nested-word-list.rkt") (void)]
parse
]
It gives us a @racket[parse] function.  What else is in there?
@interaction[#:eval informal-eval
@eval:alts[(module->exports "nested-word-list.rkt")
           (module->exports 'ragg/examples/nested-word-list)]]

Hmmm... It appears to have a few other things in there.  Let's investigate what
@racket[parse] does for us.  Let's try using @racket[parse] by
passing it a sequence of tokens.

@interaction[#:eval informal-eval
             (define a-parsed-value
               (parse (list (token 'LEFT-PAREN "(")
                            (token 'WORD "some")
                            (token 'LEFT-PAREN "[") 
                            (token 'WORD "pig")
                            (token 'RIGHT-PAREN "]") 
                            (token 'RIGHT-PAREN ")"))))
             a-parsed-value]

Wait... that looks suspiciously like a syntax object!
@interaction[#:eval informal-eval
(syntax->datum a-parsed-value)
]


That's @racket[(some [pig])], essentially.  So it appears the @racket[parse]
function can take a sequence of tokens and build structure.  What happens if we
pass it a more substantial source of tokens?

@interaction[#:eval informal-eval
@code:comment{make-tokenizer: string -> (-> (U token-struct void))}
@code:comment{Generate tokens from a string:}
(define (make-tokenizer s)
  (define tokens (regexp-match* #px"\\(|\\)|\\w+" s))
  (define (get-next)
    (cond [(empty? tokens)
           (void)]
          [else
           (define next-token
             (cond
               [(string=? (first tokens) "(")
                (token 'LEFT-PAREN (first tokens))]
               [(string=? (first tokens) ")")
                (token 'RIGHT-PAREN (first tokens))]
               [else
                (token 'WORD (first tokens))]))
           (set! tokens (rest tokens))
           next-token]))
  get-next)
@code:comment{For example:}
(define token-source (make-tokenizer "(welcome (to (((ragg)) ())))"))
(define v (parse token-source))
(syntax->datum v)
]

Welcome to @tt{ragg}.


@close-eval[informal-eval]




@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@section{Introduction}



@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@section{The language}




@section{Support API}

@defmodule[ragg/support]
@subsection{Token sources}


@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


@section{Bugs and caveats}

@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


@section{Miscellaneous and thanks}

Thanks to Joe Politz for advice and feedback.  Also, he suggested the name
``ragg''.  Other alternatives I'd been considering were
``autogrammar'' or ``chompy''.  Thankfully, he is a better Namer than me.
Daniel Patterson provided feedback that led to @racket[make-rule-parser].