;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-rating (err u103))

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

;; Profile management
(define-public (create-profile (skill (string-ascii 100)) (latitude uint) (longitude uint))
  (let ((profile-exists (is-some (map-get? profiles tx-sender))))
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

;; Offering management
(define-public (post-offering (title (string-ascii 100)) (description (string-ascii 500)) (latitude uint) (longitude uint))
  (let ((offering-id (var-get next-offering-id)))
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

;; Rating system
(define-public (rate-meetup (meetup-id uint) (rating uint))
  (let ((meetup (unwrap! (map-get? meetups meetup-id) err-not-found)))
    (asserts! (<= rating u5) err-invalid-rating)
    (asserts! (is-eq (get completed meetup) false) err-unauthorized)
    (let ((user-profile (unwrap! (map-get? profiles (get teacher meetup)) err-not-found)))
      (map-set profiles (get teacher meetup) 
        (merge user-profile { 
          reputation: (+ (get reputation user-profile) rating)
        })
      )
      (map-set meetups meetup-id (merge meetup { completed: true }))
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
