;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-invalid-location (err u104))
(define-constant err-invalid-status (err u105))
(define-constant err-already-completed (err u106))

;; Data structures
(define-map profiles
  principal
  {
    skill: (string-ascii 100),
    latitude: uint,
    longitude: uint,
    reputation: uint,
    active: bool
  }
)

(define-map offerings
  uint
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    latitude: uint,
    longitude: uint,
    active: bool
  }
)

(define-map requests
  uint
  {
    requester: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    latitude: uint,
    longitude: uint,
    active: bool
  }
)

(define-map meetups
  uint
  {
    teacher: principal,
    student: principal,
    offering-id: uint,
    timestamp: uint,
    status: (string-ascii 20),
    completed: bool
  }
)

;; Data variables
(define-data-var next-offering-id uint u1)
(define-data-var next-request-id uint u1)
(define-data-var next-meetup-id uint u1)

;; Helper functions
(define-private (validate-location (latitude uint) (longitude uint))
  (and 
    (<= latitude u90)
    (<= longitude u180)
  )
)

(define-private (calculate-distance (lat1 uint) (lon1 uint) (lat2 uint) (lon2 uint))
  ;; Simple Manhattan distance calculation
  (+ (abs (- lat1 lat2)) (abs (- lon1 lon2)))
)

;; Profile management
(define-public (create-profile (skill (string-ascii 100)) (latitude uint) (longitude uint))
  (let ((profile-exists (is-some (map-get? profiles tx-sender))))
    (asserts! (validate-location latitude longitude) err-invalid-location)
    (if profile-exists
      err-already-exists
      (ok (map-set profiles tx-sender {
        skill: skill,
        latitude: latitude,
        longitude: longitude,
        reputation: u0,
        active: true
      }))
    )
  )
)

(define-public (update-profile (skill (string-ascii 100)) (latitude uint) (longitude uint))
  (let ((existing-profile (unwrap! (map-get? profiles tx-sender) err-not-found)))
    (asserts! (validate-location latitude longitude) err-invalid-location)
    (ok (map-set profiles tx-sender 
      (merge existing-profile {
        skill: skill,
        latitude: latitude,
        longitude: longitude
      })
    ))
  )
)

(define-public (deactivate-profile)
  (let ((existing-profile (unwrap! (map-get? profiles tx-sender) err-not-found)))
    (ok (map-set profiles tx-sender 
      (merge existing-profile { active: false })
    ))
  )
)

;; Offering management
(define-public (post-offering (title (string-ascii 100)) (description (string-ascii 500)) (latitude uint) (longitude uint))
  (let ((offering-id (var-get next-offering-id)))
    (asserts! (validate-location latitude longitude) err-invalid-location)
    (map-set offerings offering-id {
      owner: tx-sender,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      active: true
    })
    (var-set next-offering-id (+ offering-id u1))
    (ok offering-id)
  )
)

;; Request management
(define-public (request-skill (title (string-ascii 100)) (description (string-ascii 500)) (latitude uint) (longitude uint))
  (let ((request-id (var-get next-request-id)))
    (asserts! (validate-location latitude longitude) err-invalid-location)
    (map-set requests request-id {
      requester: tx-sender,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      active: true
    })
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

;; Meetup management
(define-public (schedule-meetup (offering-id uint) (student principal) (timestamp uint))
  (let (
    (meetup-id (var-get next-meetup-id))
    (offering (unwrap! (map-get? offerings offering-id) err-not-found))
  )
    (asserts! (is-eq (get owner offering) tx-sender) err-unauthorized)
    (map-set meetups meetup-id {
      teacher: tx-sender,
      student: student,
      offering-id: offering-id,
      timestamp: timestamp,
      status: "scheduled",
      completed: false
    })
    (var-set next-meetup-id (+ meetup-id u1))
    (ok meetup-id)
  )
)

(define-public (cancel-meetup (meetup-id uint))
  (let ((meetup (unwrap! (map-get? meetups meetup-id) err-not-found)))
    (asserts! (or 
      (is-eq tx-sender (get teacher meetup))
      (is-eq tx-sender (get student meetup))
    ) err-unauthorized)
    (asserts! (not (get completed meetup)) err-already-completed)
    (ok (map-set meetups meetup-id 
      (merge meetup { 
        status: "cancelled",
        completed: true 
      })
    ))
  )
)

;; Rating system
(define-public (rate-meetup (meetup-id uint) (rating uint))
  (let ((meetup (unwrap! (map-get? meetups meetup-id) err-not-found)))
    (asserts! (<= rating u5) err-invalid-rating)
    (asserts! (is-eq (get completed meetup) false) err-unauthorized)
    (asserts! (is-eq (get status meetup) "scheduled") err-invalid-status)
    (let ((user-profile (unwrap! (map-get? profiles (get teacher meetup)) err-not-found)))
      (map-set profiles (get teacher meetup) 
        (merge user-profile { 
          reputation: (+ (get reputation user-profile) rating)
        })
      )
      (map-set meetups meetup-id (merge meetup { 
        status: "completed",
        completed: true 
      }))
      (ok true)
    )
  )
)

;; Read functions
(define-read-only (get-profile (user principal))
  (map-get? profiles user)
)

(define-read-only (get-offering (offering-id uint))
  (map-get? offerings offering-id)
)

(define-read-only (get-request (request-id uint))
  (map-get? requests request-id)
)

(define-read-only (get-meetup (meetup-id uint))
  (map-get? meetups meetup-id)
)

(define-read-only (get-distance-between (lat1 uint) (lon1 uint) (lat2 uint) (lon2 uint))
  (ok (calculate-distance lat1 lon1 lat2 lon2))
)
