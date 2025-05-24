;; Performance Measurement Contract
;; Tracks efficiency gains and KPIs

(define-map performance-metrics
  { metric-id: uint }
  {
    facility-id: uint,
    metric-name: (string-ascii 50),
    metric-type: (string-ascii 30),
    value: uint,
    unit: (string-ascii 20),
    timestamp: uint,
    period: (string-ascii 20),
    target: uint,
    recorder: principal
  }
)

(define-map kpi-definitions
  { kpi-name: (string-ascii 50) }
  {
    description: (string-ascii 200),
    calculation-method: (string-ascii 100),
    target-range-min: uint,
    target-range-max: uint,
    frequency: (string-ascii 20)
  }
)

(define-map facility-performance
  { facility-id: uint, period: (string-ascii 20) }
  {
    overall-efficiency: uint,
    waste-reduction: uint,
    cost-savings: uint,
    quality-score: uint,
    last-updated: uint
  }
)

(define-data-var next-metric-id uint u1)

(define-constant ERR-INVALID-METRIC (err u400))
(define-constant ERR-METRIC-NOT-FOUND (err u401))
(define-constant ERR-UNAUTHORIZED-RECORD (err u402))

(define-public (record-performance-metric
  (facility-id uint)
  (metric-name (string-ascii 50))
  (metric-type (string-ascii 30))
  (value uint)
  (unit (string-ascii 20))
  (period (string-ascii 20))
  (target uint)
)
  (let ((metric-id (var-get next-metric-id)))
    (map-set performance-metrics
      { metric-id: metric-id }
      {
        facility-id: facility-id,
        metric-name: metric-name,
        metric-type: metric-type,
        value: value,
        unit: unit,
        timestamp: block-height,
        period: period,
        target: target,
        recorder: tx-sender
      }
    )
    (var-set next-metric-id (+ metric-id u1))
    (ok metric-id)
  )
)

(define-public (define-kpi
  (kpi-name (string-ascii 50))
  (description (string-ascii 200))
  (calculation-method (string-ascii 100))
  (target-min uint)
  (target-max uint)
  (frequency (string-ascii 20))
)
  (begin
    (map-set kpi-definitions
      { kpi-name: kpi-name }
      {
        description: description,
        calculation-method: calculation-method,
        target-range-min: target-min,
        target-range-max: target-max,
        frequency: frequency
      }
    )
    (ok true)
  )
)

(define-public (update-facility-performance
  (facility-id uint)
  (period (string-ascii 20))
  (efficiency uint)
  (waste-reduction uint)
  (cost-savings uint)
  (quality-score uint)
)
  (begin
    (map-set facility-performance
      { facility-id: facility-id, period: period }
      {
        overall-efficiency: efficiency,
        waste-reduction: waste-reduction,
        cost-savings: cost-savings,
        quality-score: quality-score,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

(define-read-only (get-performance-metric (metric-id uint))
  (map-get? performance-metrics { metric-id: metric-id })
)

(define-read-only (get-kpi-definition (kpi-name (string-ascii 50)))
  (map-get? kpi-definitions { kpi-name: kpi-name })
)

(define-read-only (get-facility-performance (facility-id uint) (period (string-ascii 20)))
  (map-get? facility-performance { facility-id: facility-id, period: period })
)

(define-read-only (calculate-efficiency-trend (facility-id uint))
  ;; Simplified calculation - in practice would compare multiple periods
  (match (map-get? facility-performance { facility-id: facility-id, period: "current" })
    current-perf (ok (get overall-efficiency current-perf))
    (ok u0)
  )
)

(define-read-only (is-target-met (metric-id uint))
  (match (map-get? performance-metrics { metric-id: metric-id })
    metric-data
    (>= (get value metric-data) (get target metric-data))
    false
  )
)
