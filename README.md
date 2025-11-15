Original App Design Project - README Template
===

# Think Fast Trivia

## Table of Contents

1. [Overview](#Overview)
2. [Product Spec](#Product-Spec)
3. [Wireframes](#Wireframes)
4. [Schema](#Schema)

## Overview

### Description

Think Fast Trivia is a iOS trivia game that challenges users with timed quizzes across various categories. The app features an engaging UI with progress tracking, timed challenges, and detailed results.

### App Evaluation

- **Category:** Education, Entertainment, Gaming
- **Mobile:** iOS native application with SwiftUI
- **Story:** Think Fast Trivia challenges users to test their knowledge under time pressure, creating an exciting and competitive experience while learning new facts.
- **Market:** Trivia enthusiasts, casual gamers, educational institutions, and anyone looking to test their knowledge in an engaging format.
- **Habit:** Regular usage encouraged through daily challenges, new question sets, and competitive leaderboards.
- **Scope:** Focused on delivering a polished trivia experience with timed challenges, multiple categories, and performance tracking.

## Product Spec

### 1. User Stories (Required and Optional)

**Required Must-have Stories**

- [x] User can select from various trivia categories
- [x] User can play time-limited trivia games
- [x] User can navigate between questions during gameplay
- [x] User can see their progress during a game session
- [x] User can view detailed results after completing a quiz
- [x] User can track time remaining with visual indicators
- [x] User can submit answers before the timer expires

**Optional Nice-to-have Stories**

[x] User can create an account to save their progress
[ ] User can view leaderboards to compare scores with others
[ ] User can earn achievements for milestones
[ ] User can customize game difficulty
[ ] User can create custom trivia sets
[ ]User can challenge friends to beat their scores
[x]User can access offline play mode

### 2. Screen Archetypes

- [x] **Home Screen**
  * User can select trivia categories
  * User can view game statistics
  * User can access settings

- [ ] **Game Screen**
  * User can view and answer trivia questions
  * User can track remaining time
  * User can navigate between questions
  * User can submit final answers

- [ ] **Results Screen**
  * User can view performance statistics
  * User can see correct/incorrect answers
  * User can share results
  * User can restart or choose a new category


### 3. Navigation

**Flow Navigation** (Screen to Screen)

- [x] **Home Screen**
  * Leads to Category Selection
  * Leads to Settings

- [x] **Category Selection**
  * Leads to Game Screen

- [ ] **Game Screen**
  * Leads to Results Screen (upon completion or timeout)

- [ ] **Results Screen**
  * Leads back to Home Screen
  * Leads to New Game (same category)
     
## Build Progress

<div>
    <a href="https://go.screenpal.com/watch/cTX6efnFkEl">
      <p>Trivia Build Progress</p>
    </a>
    <a href="https://go.screenpal.com/watch/cTX6efnFkEl">
      <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/e8d9600bc9624407ac1f046b81157290-c85775fcd22101bf-full-play.gif">
    </a>
  </div>


## Wireframes
![Add picture of your hand sketched wireframes in this section](https://imgur.com/a/ywYZJo3.PNG)

## Implementation Status
### Project Structure:
```
Think Fast Trivia/
├── models/
│   └── TriviaModels.swift       # Data models and enums
├── controllers/
│   └── TriviaService.swift      # API integration
├── views/
│   ├── OptionsView.swift        # Home/settings screen
│   ├── QuestionCardView.swift   # Question display component
│   ├── TriviaGameView.swift     # Main game screen
│   └── ResultsView.swift        # Results and review screen
├── ContentView.swift            # App entry point
└── Think_Fast_TriviaApp.swift   # Main app file
```

### Models/Schema

**TriviaResponse**
| Property | Type | Description |
|----------|------|-------------|
| responseCode | Int | API response code (0 = success) |
| results | [TriviaQuestion] | Array of trivia questions |
| isSuccess | Bool | Whether the API request was successful |
| errorMessage | String? | Human-readable error message based on response code |

**TriviaQuestion**
| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier for the question |
| category | String | Question category |
| type | String | Question type (multiple, boolean) |
| difficulty | String | Question difficulty level |
| question | String | The trivia question text (HTML encoded) |
| correctAnswer | String | The correct answer (HTML encoded) |
| incorrectAnswers | [String] | Array of incorrect answer options (HTML encoded) |
| allAnswers | [String] | All answer options (shuffled) |
| decodedQuestion | String | Decoded question text for display |
| decodedCorrectAnswer | String | Decoded correct answer for display |
| decodedAllAnswers | [String] | All decoded answers for display |

**UserAnswer**
| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier for the user answer |
| question | TriviaQuestion | Reference to the question |
| selectedAnswer | String? | User's selected answer (nil if unanswered) |
| isCorrect | Bool? | Whether the selected answer is correct (nil if unanswered) |

**TriviaCategory**
| Case | API Value | Description |
|------|-----------|-------------|
| any | nil | Any category (no filter) |
| generalKnowledge | "9" | General Knowledge questions |
| books | "10" | Book-related questions |
| film | "11" | Film-related questions |
| music | "12" | Music-related questions |
| *and 21 more categories* | ... | Various specialized topics |

**TriviaDifficulty**
| Case | API Value | Description |
|------|-----------|-------------|
| any | nil | Any difficulty level |
| easy | "easy" | Easy difficulty questions |
| medium | "medium" | Medium difficulty questions |
| hard | "hard" | Hard difficulty questions |

**TriviaQuestionType**
| Case | API Value | Description |
|------|-----------|-------------|
| any | nil | Any question type |
| multipleChoice | "multiple" | Multiple choice questions |
| trueFalse | "boolean" | True/False questions |


### Networking

The app connects to the Open Trivia Database API to fetch questions:

- `GET /api.php?amount=10&type=multiple` - Fetch 10 multiple-choice questions
- `GET /api.php?amount=10&category=9&difficulty=medium` - Fetch medium difficulty questions from General Knowledge category
