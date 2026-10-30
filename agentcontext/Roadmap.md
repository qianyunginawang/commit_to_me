# Roadmap
The work needed to turn the design docs (Setting, Calendar, StoryBeats, Balance, Characters, DatesAndRoutes) into the game. The phases go in order. Inside a phase, items marked **(parallel)** can be split between people.

## Where the game is today
- **Semester:** the game runs a full 14-week semester (Aug 31 to Dec 6). Week, day and Day/Night slot are saved, and each lesson uses up a slot. Story events and recurring events in `data/calendar.json` decide who is where.
- **Campus map:** replaces the old hub. Pick a location to see who's there, which lessons they can teach right now, and any story scene to watch.
- **Lessons:** one JSON format for generic subjects (`data/curriculum.json`, `data/lessons/`) and special chapters (`data/routes/`). Each challenge has 2 Quack hints. A lesson gives +6 affection, -2 per hint used, never below +2. Dialogue choices don't change affection.
- **Unlocks:** finishing a subject with anyone opens the next one for everyone, and each subject can be done once with each character. Special chapters open when their subjects and the previous chapter are done.
- **Jay:** day and night lessons are counted for the balance rule.
- **Endings:** checked in week 14. The route goes to the highest affection, with good, normal and bad endings (Jay has day and night normal endings).
- **Replay profile:** records endings seen. One good ending unlocks the hidden Polyglot choice in week 4, and all four unlock the Ferris route (not built yet).
- **Polyglot branch:** the week 4 choice, 8 group scenes and the Polyglot or merge conflict ending. The integration test challenge is still a placeholder.
- **Code runner:** real code runs through the bundled runtimes (Python, Node/TypeScript, Java, C++), with a grader and tests.
- **Still missing:** most lesson and scene content (placeholders for now) and all art. Characters use their final names (Monty, Jay, Julian, Ciel), and the heroine's default name is Grace.

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
