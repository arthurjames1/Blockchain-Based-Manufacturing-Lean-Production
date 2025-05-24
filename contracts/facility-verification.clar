;; Facility Verification Contract
;; Validates production sites and their capabilities

(define-map facilities
  { facility-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    location: (string-ascii 200),
    certification-level: uint,
    verified: bool,
    verification-date: uint,
    capacity: uint
  }
)

(define-map facility-certifications
  { facility-id: uint, cert-type: (string-ascii 50) }
  {
    issued-by: principal,
    issue-date: uint,
    expiry-date: uint,
    valid: bool
  }
)

(define-data-var next-facility-id uint u1)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-FACILITY-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VERIFIED (err u102))
(define-constant ERR-INVALID-CERTIFICATION (err u103))

(define-public (register-facility (name (string-ascii 100)) (location (string-ascii 200)) (capacity uint))
  (let ((facility-id (var-get next-facility-id)))
    (map-set facilities
      { facility-id: facility-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        certification-level: u0,
        verified: false,
        verification-date: u0,
        capacity: capacity
      }
    )
    (var-set next-facility-id (+ facility-id u1))
    (ok facility-id)
  )
)

(define-public (verify-facility (facility-id uint) (cert-level uint))
  (match (map-get? facilities { facility-id: facility-id })
    facility-data
    (begin
      (map-set facilities
        { facility-id: facility-id }
        (merge facility-data {
          verified: true,
          verification-date: block-height,
          certification-level: cert-level
        })
      )
      (ok true)
    )
    ERR-FACILITY-NOT-FOUND
  )
)

(define-public (add-certification (facility-id uint) (cert-type (string-ascii 50)) (expiry-date uint))
  (match (map-get? facilities { facility-id: facility-id })
    facility-data
    (if (is-eq (get owner facility-data) tx-sender)
      (begin
        (map-set facility-certifications
          { facility-id: facility-id, cert-type: cert-type }
          {
            issued-by: tx-sender,
            issue-date: block-height,
            expiry-date: expiry-date,
            valid: true
          }
        )
        (ok true)
      )
      ERR-NOT-AUTHORIZED
    )
    ERR-FACILITY-NOT-FOUND
  )
)

(define-read-only (get-facility (facility-id uint))
  (map-get? facilities { facility-id: facility-id })
)

(define-read-only (get-certification (facility-id uint) (cert-type (string-ascii 50)))
  (map-get? facility-certifications { facility-id: facility-id, cert-type: cert-type })
)

(define-read-only (is-facility-verified (facility-id uint))
  (match (map-get? facilities { facility-id: facility-id })
    facility-data (get verified facility-data)
    false
  )
)
