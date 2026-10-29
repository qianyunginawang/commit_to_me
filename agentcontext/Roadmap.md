# Roadmap
The work needed to turn the design docs (Setting, Calendar, StoryBeats, Balance, Characters, DatesAndRoutes) into the game. The phases go in order. Inside a phase, items marked **(parallel)** can be split between people.

## Where the game is today
- Main menu, a hub with four character cards, one date per character, and a coding challenge screen.
- Real code runs through the bundled runtimes (Python, Node/TypeScript, Java, C++), with a grader and tests.
- Affection is a single number per character, saved to one save file. Dates are JSON dialogue in `data/dates/`. Dialogue choices currently change affection.
- Characters use their final names (Monty, Jay, Julian, Ciel), and the heroine's default name is Grace. There's no art in `assets/portraits/` yet.
- Design decisions: generic lessons use the language of the character you take them with (5 versions per subject, 165 generic challenges, with TypeScript for Day Jay and JavaScript for Night Jay), and any generic lesson can happen in a Day or Night slot.

## Phase 1: Core systems
These change the game from "pick a date from a menu" to "live through a semester". Do them in this order, because each one builds on the one before.
1. **Lesson data format.** One JSON shape for both generic and special lessons, where a generic subject holds one version per language: subject or chapter id, character, prerequisites, location, Day/Night slot, the challenge, and 2 hints.
2. **Affection and hints (Balance.md).** +6 per lesson, -2 per hint, never below +2. Dialogue choices stop changing affection. Add a hint button that Quack answers.
3. **Unlock system.** Generic subjects open in curriculum order. Special chapters open when their subjects and the character's previous chapter are done.
4. **Calendar and time.** Week, day and Day/Night slot in the save. Doing a lesson uses up a slot, and time moves forward. Fixed events (orientation, hackathon, carnival, midterms and so on) and recurring events show as lesson opportunities on the right days.
5. **Campus map.** Pick a location for the current slot and see who's there and which lessons are available. This replaces the hub.
6. **Jay's day/night tracking.** Count day and night lessons for the balance rule.
7. **Endings.** Check the ending thresholds in week 14, run the final challenge, and play the right confession and ending.
8. **Replay profile.** A file kept across playthroughs that records endings seen. It unlocks the hidden Polyglot choice (after one good ending) and the Ferris route (after all four good endings).
9. **Polyglot branch.** The week 4 hidden choice (all four at 20+) and the Polyglot story beats.

## Phase 2: Vertical slice
Build weeks 1 to 3 end to end with placeholder art: orientation, the campus tour, the club fair, the hackathon, and the first special chapters. Play it, check that the pacing and affection feel right, and fix the systems before making lots of content. Monty is the best character to polish first, since his route is the easy one and the recommended first playthrough.

## Phase 3: Content (parallel)
The biggest phase, and the easiest to split up.
- **Generic lessons:** 33 subjects × 5 versions (Python, Java, C++, TypeScript for Day Jay, JavaScript for Night Jay) = 165 challenges. The TypeScript and JavaScript versions can share most of their content. Each one needs the challenge, 2 hints, a test solution in `tests/solutions/`, and short dialogue in that character's voice. Write them one subject at a time (all 5 versions together), in curriculum order, so the vertical slice and early weeks are finished first. Splitting by language also works, with one person on Python and Java and another on C++ and JS/TS.
- **Special chapters:** 25 total (6 each for Monty, Ciel and Julian, 7 for Jay), including the four final challenges.
- **Story beat scenes:** the 15 beats in StoryBeats.md, plus Quack's lines (hints, affection reports, tutorials).
- **Event scenes:** birthdays, Halloween, the carnival, midterms, the gala, and the festival.
- **Confessions and endings:** 4 confessions, 13 route endings (Jay has two normal endings), and the Polyglot and merge conflict endings.

## Phase 4: Art and audio (parallel, can start during Phase 2)
- **Character sprites:** Monty, Ciel, Julian, Jay in both day and night looks, and Quack. Each needs the expressions listed in Characters.md.
- **Backgrounds:** the 28 locations in Setting.md, with day and night versions for the ones used in both slots. Start with the most-used ones: Hopper Lab, Turing Hall, the student union rooftop, the council room, Café Cache, and the main quad.
- **CGs:** the sunset switch, the confessions, the epilogue CGs, and the joke rubber duck ending.
- **UI:** text box, map, calendar, affection display, hint button, and code editor styling.
- **Music and sound effects:** a theme for each character, campus ambience, and success and fail jingles.

## Phase 5: Polish and ship
1. Playtest the whole semester for each route and for the Polyglot route, and tune the numbers in Balance.md.
2. Add save slots, skip, auto-play, back, and the gallery (from FEATUREWORK.md).
3. Build the game for Mac and Windows with the bundled runtimes, and test it on a computer that has none of the languages installed.
