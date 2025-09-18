;; ---------------------------------------------------------
;; Contract: RepCredX
;; Purpose: On-Chain Reputation Badge System (Non-transferable)
;; ---------------------------------------------------------

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_HAS_BADGE (err u101))
(define-constant ERR_NO_BADGE (err u102))

;; ----------------------------
;; Data Maps
;; ----------------------------

;; badge-types: badge-id -> { name, description }
(define-map badge-types
  { id: uint }
  { name: (string-ascii 32), description: (string-ascii 128) })

;; user-badges: (badge-id, user) -> bool
(define-map user-badges
  { badge-id: uint, user: principal }
  { has: bool })

;; ----------------------------
;; Contract Owner
;; ----------------------------
(define-constant contract-owner tx-sender)

;; ----------------------------
;; Helper Functions
;; ----------------------------

(define-private (is-owner (caller principal))
  (is-eq caller contract-owner))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Add a new badge type (only owner)
(define-public (add-badge-type (id uint) (name (string-ascii 32)) (description (string-ascii 128)))
  (if (is-owner tx-sender)
      (begin
        (map-set badge-types { id: id } { name: name, description: description })
        (ok true))
      ERR_UNAUTHORIZED))

;; Assign a badge to a user (non-transferable)
(define-public (assign-badge (id uint) (user principal))
  (if (is-owner tx-sender)
      (if (is-some (map-get? user-badges { badge-id: id, user: user }))
          ERR_ALREADY_HAS_BADGE
          (begin
            (map-set user-badges { badge-id: id, user: user } { has: true })
            (ok true)))
      ERR_UNAUTHORIZED))

;; Revoke a badge from a user
(define-public (revoke-badge (id uint) (user principal))
  (if (is-owner tx-sender)
      (if (is-some (map-get? user-badges { badge-id: id, user: user }))
          (begin
            (map-delete user-badges { badge-id: id, user: user })
            (ok true))
          ERR_NO_BADGE)
      ERR_UNAUTHORIZED))

;; Check if user has a specific badge
(define-read-only (has-badge (id uint) (user principal))
  (default-to false (get has (map-get? user-badges { badge-id: id, user: user }))))
