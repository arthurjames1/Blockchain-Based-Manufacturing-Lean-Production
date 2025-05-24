;; Best Practice Sharing Contract
;; Distributes lean methodologies and successful practices

(define-map best-practices
  { practice-id: uint }
  {
    contributor: principal,
    facility-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 1000),
    category: (string-ascii 50),
    methodology: (string-ascii 200),
    results-achieved: (string-ascii 500),
    implementation-cost: uint,
    savings-generated: uint,
    difficulty-level: uint,
    verification-status: (string-ascii 20),
    votes: uint,
    timestamp: uint
  }
)

(define-map practice-implementations
  { implementation-id: uint }
  {
    practice-id: uint,
    implementing-facility: uint,
    implementer: principal,
    start-date: uint,
    completion-date: uint,
    status: (string-ascii 20),
    results: (string-ascii 500),
    adaptation-notes: (string-ascii 500)
  }
)

(define-map practice-votes
  { practice-id: uint, voter: principal }
  { vote-type: (string-ascii 10), timestamp: uint }
)

(define-data-var next-practice-id uint u1)
(define-data-var next-implementation-id uint u1)

(define-constant ERR-PRACTICE-NOT-FOUND (err u500))
(define-constant ERR-ALREADY-VOTED (err u501))
(define-constant ERR-IMPLEMENTATION-NOT-FOUND (err u502))
(define-constant ERR-NOT-AUTHORIZED (err u503))

(define-public (share-best-practice
  (facility-id uint)
  (title (string-ascii 100))
  (description (string-ascii 1000))
  (category (string-ascii 50))
  (methodology (string-ascii 200))
  (results-achieved (string-ascii 500))
  (implementation-cost uint)
  (savings-generated uint)
  (difficulty-level uint)
)
  (let ((practice-id (var-get next-practice-id)))
    (map-set best-practices
      { practice-id: practice-id }
      {
        contributor: tx-sender,
        facility-id: facility-id,
        title: title,
        description: description,
        category: category,
        methodology: methodology,
        results-achieved: results-achieved,
        implementation-cost: implementation-cost,
        savings-generated: savings-generated,
        difficulty-level: difficulty-level,
        verification-status: "pending",
        votes: u0,
        timestamp: block-height
      }
    )
    (var-set next-practice-id (+ practice-id u1))
    (ok practice-id)
  )
)

(define-public (vote-for-practice (practice-id uint) (vote-type (string-ascii 10)))
  (let ((vote-key { practice-id: practice-id, voter: tx-sender }))
    (if (is-none (map-get? practice-votes vote-key))
      (match (map-get? best-practices { practice-id: practice-id })
        practice-data
        (begin
          (map-set practice-votes
            vote-key
            { vote-type: vote-type, timestamp: block-height }
          )
          (if (is-eq vote-type "upvote")
            (map-set best-practices
              { practice-id: practice-id }
              (merge practice-data { votes: (+ (get votes practice-data) u1) })
            )
            true
          )
          (ok true)
        )
        ERR-PRACTICE-NOT-FOUND
      )
      ERR-ALREADY-VOTED
    )
  )
)

(define-public (implement-practice (practice-id uint) (implementing-facility uint))
  (match (map-get? best-practices { practice-id: practice-id })
    practice-data
    (let ((implementation-id (var-get next-implementation-id)))
      (map-set practice-implementations
        { implementation-id: implementation-id }
        {
          practice-id: practice-id,
          implementing-facility: implementing-facility,
          implementer: tx-sender,
          start-date: block-height,
          completion-date: u0,
          status: "in-progress",
          results: "",
          adaptation-notes: ""
        }
      )
      (var-set next-implementation-id (+ implementation-id u1))
      (ok implementation-id)
    )
    ERR-PRACTICE-NOT-FOUND
  )
)

(define-public (update-implementation-status
  (implementation-id uint)
  (new-status (string-ascii 20))
  (results (string-ascii 500))
  (adaptation-notes (string-ascii 500))
)
  (match (map-get? practice-implementations { implementation-id: implementation-id })
    impl-data
    (if (is-eq (get implementer impl-data) tx-sender)
      (begin
        (map-set practice-implementations
          { implementation-id: implementation-id }
          (merge impl-data {
            status: new-status,
            results: results,
            adaptation-notes: adaptation-notes,
            completion-date: (if (is-eq new-status "completed") block-height (get completion-date impl-data))
          })
        )
        (ok true)
      )
      ERR-NOT-AUTHORIZED
    )
    ERR-IMPLEMENTATION-NOT-FOUND
  )
)

(define-public (verify-practice (practice-id uint))
  (match (map-get? best-practices { practice-id: practice-id })
    practice-data
    (begin
      (map-set best-practices
        { practice-id: practice-id }
        (merge practice-data { verification-status: "verified" })
      )
      (ok true)
    )
    ERR-PRACTICE-NOT-FOUND
  )
)

(define-read-only (get-best-practice (practice-id uint))
  (map-get? best-practices { practice-id: practice-id })
)

(define-read-only (get-practice-implementation (implementation-id uint))
  (map-get? practice-implementations { implementation-id: implementation-id })
)

(define-read-only (get-practice-vote (practice-id uint) (voter principal))
  (map-get? practice-votes { practice-id: practice-id, voter: voter })
)

(define-read-only (calculate-practice-roi (practice-id uint))
  (match (map-get? best-practices { practice-id: practice-id })
    practice-data
    (let (
      (savings (get savings-generated practice-data))
      (cost (get implementation-cost practice-data))
    )
      (if (> cost u0)
        (ok (/ (* savings u100) cost))
        (ok u0)
      )
    )
    ERR-PRACTICE-NOT-FOUND
  )
)
