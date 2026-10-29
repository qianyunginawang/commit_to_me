# Balance
How lessons turn into affection. Affection runs from 0 to 100 for each love interest. Lessons are the only source of affection. Recurring events and other calendar events are just chances to do a lesson.

## Affection per lesson
Every lesson, generic or special, uses the same rule:
- Completing a lesson gives **+6** affection to the character you do it with.
- Each lesson has **2 hints** from Quack. Each hint used costs **-2**.
    - No hints: +6
    - One hint: +4
    - Both hints: +2
- Wrong answers don't lose affection. The player just tries again. A lesson never gives less than +2.

## Generic lessons
- There are 33 generic subjects (see the General section of DatesAndRoutes.md). The lesson is in the language of the character you take it with, so each subject has 5 versions: Python, Java, C++, and TypeScript or JavaScript for Jay depending on the slot.
- Any subject can be done with any character, once per character. Jay counts as one character, so a subject done with Day Jay or Night Jay uses up Jay's turn for it.
- Subjects unlock in order: finishing a subject with anyone opens the next one for everyone. The player can also choose to do an already completed lesson with a different character
- Generic 1 (Printing to the console) is done with all four characters on the campus tour, so every route starts at 6.

## Special chapters
- Same rule as generic lessons: +6, with 2 hints at -2 each.
- Special chapters stand out through story, locations and CGs, not extra points. Raising them (even to +8) makes the Polyglot route too easy.
- Monty, Ciel and Julian have 6 special chapters each. Jay has 7.

## Endings
- **Good:** 80+ affection and the final challenge passed.
- **Normal:** 50 to 79.
- **Bad:** under 50.

## How one route plays out
| | Monty, Ciel, Julian | Jay |
|---|---|---|
| Meeting (Generic 1) | 6 | 6 |
| All special chapters, no hints | 36 | 42 |
| Total before other generic lessons | 42 (bad) | 48 (bad) |
| Generic lessons needed for normal (50+) | 2 | 1 |
| Generic lessons needed for good (80+), no hints | 7 | 6 |
| Generic lessons needed for good, every hint used on special chapters | 11 | 10 |

Skipping a character's special chapters is the main way to end up with a bad ending. A player who leans on hints can still get a good ending by taking more generic lessons with that character.

## Jay's day and night sides
- Jay has one affection meter, plus a day/night balance.
- Lessons in a Day slot count as day lessons and lessons in a Night slot count as night lessons. Dusk chapters count as both. Generic lessons can happen in either slot, so the player balances Jay by choosing when to take generic lessons with them.
- **Jay's good ending:** 80+ affection, and the day and night lesson counts within 2 of each other.
- Jay's two normal endings depend on which side has more lessons: day-heavy gives the TypeScript ending, night-heavy gives the JavaScript ending.
- Two separate 0-to-100 meters would need about 21 lessons with Jay alone, which breaks the Polyglot math.

## Polyglot route
- All four need 80+ by week 14.
- With no hints, that's about 56 lessons in total: the 4 campus tour lessons, 25 special chapters, and about 27 generic lessons spread across the four.
- Since any subject can be done with every character, subjects no longer limit affection. The limit is time.

## Time
- Each day has a Day slot and a Night slot, and a lesson uses up one slot. The orientation-day campus tour is the exception: all four tour lessons happen in one slot.
- Lessons only happen at events where that character is around: their recurring events and the story events in data/calendar.json. There's no weekly cap (decided 2026-10-29), so the limit is where everyone is and when, and that their events sometimes overlap.
- The player can also just wait, which moves time to the next slot.

## Week 4: the hidden Polyglot choice
- There is no route lock. Every character stays available all semester, and a character the player ignores just ends up with a bad ending.
- At the end of week 4, on a replay after at least one good ending, the hidden Polyglot choice appears if all four are at 20+. By week 4 the player has only 10 generic subjects (2 to 11) plus 7 special chapters to spread, so a higher gate isn't reachable.
