# SkillTide
A decentralized platform for skill-swapping with location-based meetups built on Stacks blockchain.

## Features
- Create skill profiles with location data
- Post skill offerings and requests
- Match users based on complementary skills
- Schedule and confirm meetups
- Rate participants after meetups
- Track reputation scores

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a skill profile
(contract-call? .skill-tide create-profile "Web Development" u10 u20)

;; Post a skill offering
(contract-call? .skill-tide post-offering "JavaScript Tutoring" "Looking to teach JS basics" u10 u20)

;; Request a skill
(contract-call? .skill-tide request-skill "Python Mentoring" "Need help with Django" u10 u20)

;; Schedule a meetup
(contract-call? .skill-tide schedule-meetup u1 u2 u1234567890)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
