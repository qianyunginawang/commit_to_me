# Setting
Runtime University, one fall semester (14 weeks). The heroine is a CS freshman. Each language is an upperclassman who tutors her in their own features, and every tutorial chapter doubles as a date.

## How this doc is organized
The campus has **11 buildings**. Each building has **rooms** (or wings, floors, and outdoor spots). This matches how the campus map works (Roadmap, Phase 2 step 3):

- **Building** = one clickable shape on the map. Its bubble shows which love interests are in any of its rooms right now.
- **Room** = one entry in the list that opens when you click a building. A room with a love interest starts a scene and a lesson list. A room with nobody there shows its "walk-in" line and a button back to the map.
- Every room has an **id**. Ids that already exist in `data/locations.json` are kept, so `calendar.json`, `curriculum.json` and `routes/*.json` keep working. Rooms marked **(new)** need to be added to `locations.json`.
- Outdoor areas (the quad, the gardens, the athletic fields) are treated as buildings too, so the map works the same way everywhere.

Event names below match `data/calendar.json`. "Generic N" is a subject from the general curriculum (1 to 33). "Jay/Monty/Ciel/Julian Ch N" is a special chapter from that character's route. Generic lessons happen with whoever is in the room, so a generic subject's room is only its flavor setting.

## Campus layout
The map is a 4 by 3 grid, north at the top. The main quad sits in the middle and takes two cells.

```
            A                   B                  C                   D
      +-----------------+-----------------+-----------------+-----------------+
  1   |  Turing Hall    |  Oracle Hall    | Lovelace Library|  Knuth Hall     |
      |  (lectures)     |  (admin, gala)  |                 |  (Hopper Lab)   |
      +-----------------+-----------------+-----------------+-----------------+
  2   |  Student Union  |            Main Quad              |  Observatory    |
      |  (west edge)    |   fountain, stage, picnic hill    |  (on the hill)  |
      +-----------------+-----------------+-----------------+-----------------+
  3   |  The Commons    |  Babbage Hall   |  Greenhouse     |  Athletic       |
      |  (food, shops)  |  (your dorm)    |  and Gardens    |  Complex        |
      +-----------------+-----------------+-----------------+-----------------+
```

Why things sit where they do:
- The **Student Union** is on the west edge, so its rooftop has the best sunset on campus (Jay's switch happens at sunset).
- **Knuth Hall** (the CS building) is on the east edge, so its rooftop faces the sunrise (Ciel's dawn confession).
- **Oracle Hall** is right above the quad, so the council balcony looks over it.
- The **picnic hill** is the corner of the quad nearest the library.
- The **greenhouse** is just south of the quad, so its lights show during the end-of-term festival.
- The **observatory** is on the hill at the east edge, away from campus lights.
- **Babbage Hall** is next to The Commons, so the heroine is never far from food.

## Buildings at a glance
| Map cell | Building | Building id | Rooms | Who's usually here |
|---|---|---|---|---|
| A1 | Turing Hall | `turing` | Lecture hall, Locker hallway, TA office, Tutoring center, Exam hall | Day Jay (days), Monty (weeknights) |
| B1 | Oracle Hall | `oracle_hall` | Student council room, Council balcony, Server room, Oracle Great Hall | Julian (weekend nights) |
| C1 | Lovelace Library | `library` | Reading room, The stacks, University Archive (Sun Wing) | Nobody regularly |
| D1 | Knuth Hall | `knuth_hall` | Hopper Computer Lab, Capstone team room, Knuth Hall rooftop | Ciel (weeknights) |
| A2 | Student Union | `student_union` | Hackathon hall, Game dev club room, Arcade, Union rooftop | Night Jay (weekend nights), Ciel (weekend days) |
| B2–C2 | Main Quad | `main_quad_area` | Quad lawn, Fountain bench, Picnic hill, Festival stage (week 14 only) | Nobody regularly |
| D2 | Observatory | `observatory_bld` | Observatory dome | Nobody regularly |
| A3 | The Commons | `commons` | The Stack (dining hall), Café Cache, Campus bookstore | Julian (weekday mornings) |
| B3 | Babbage Hall | `babbage` | Your room, Common room, Laundry room | Quack (always) |
| C3 | Greenhouse and Gardens | `gardens` | Greenhouse, Hedge maze garden, Duck pond | Monty (weekend days) |
| D3 | Athletic Complex | `athletics` | Gym, Running track | Nobody regularly |

Totals: 11 buildings, 35 rooms. Rooms marked (new) aren't in `data/locations.json` yet.

---

## A1. Turing Hall
The main lecture building, where Intro to Programming is taught. Long hallways lined with numbered lockers. Day Jay is the TA here.

### Lecture hall
- **id:** `turing_hall` (kept, now just the lecture hall)
- **Open:** Day
- **Description:** A big tiered lecture hall with a projector that takes three tries to turn on.
- **Story events:** First problem set due (week 3), Spring course registration opens (week 10)
- **Lessons:** Generic 3 (Variables and assignment), Generic 9 (If/else)
- **Endings:** Jay bad ending, undefined (Day Jay calls roll and reads her name as "undefined")

### Locker hallway (new)
- **id:** `locker_hallway` (new)
- **Open:** Day
- **Description:** A long hallway of numbered lockers, starting at 0.
- **Lessons:** Generic 16 (Arrays and lists: a row of numbered lockers)

### TA office
- **id:** `ta_office`
- **Open:** Day only
- **Description:** A small, very tidy room with a whiteboard and a sign-up sheet.
- **Recurring:** Office hours (Day Jay, Mon to Fri, Day)
- **Story events:** Orientation campus tour, Jay's stop
- **Special chapters:** Jay Ch2 (Type annotations, Day), Jay Ch4 (Interfaces, Day)
- **Endings:** Jay normal day ending, Strict mode (Day Jay keeps holding office hours, polite, proper, and a little hollow)

### Tutoring center
- **id:** `tutoring_center`
- **Open:** Day and Night
- **Description:** Couches, snacks, and a whiteboard covered in other people's handwriting. Monty volunteers here.
- **Recurring:** Tutoring center shift (Monty, Mon to Fri, Night)
- **Special chapters:** Monty Ch1 (The Zen of Python: Monty types `import this` into the REPL)
- **Lessons:** Generic 12 (For loops)
- **Endings:** Monty bad ending, DeprecationWarning (Monty helps her the same way he helps everyone else, kind but distant)

### Exam hall
- **id:** `exam_hall`
- **Open:** Day
- **Description:** Rows of single desks and a big clock on the wall that ticks too loudly.
- **Story events:** Midterms week (week 7), Finals week (week 14)
- **Lessons:** Generic 33 (Dynamic programming: a finals-week cram session)

---

## B1. Oracle Hall
The administration building, donated by the Oracle family. President Fortran's office is upstairs. The student council works out of the second floor, and the basement runs the campus servers.

### Student council room
- **id:** `council_room`
- **Open:** Day and Night
- **Description:** Labeled folders, two coffee mugs, and a very large binder. Julian is always here early.
- **Recurring:** Student council office hours (Julian, Fri to Sun, Night)
- **Story events:** Orientation campus tour, Julian's stop. Julian's half-birthday (week 12, Sat, Day). Polyglot: talk to Julian (week 13)
- **Special chapters:** Julian Ch1 (The JVM: the heroine is "drafted" for council paperwork), Julian Ch2 (== vs .equals(): two identical forms), Julian Ch5 (Checked exceptions)
- **Endings:** Julian good ending CG (two mugs on the council desk)

### Council balcony
- **id:** `council_balcony`
- **Open:** Night (story only)
- **Description:** A stone balcony off the council room that looks over the main quad.
- **Endings:** Julian confession (after the winter gala, tie loosened for the first time)

### Server room
- **id:** `server_room`
- **Open:** Story only (Julian has the key)
- **Description:** The basement. Ancient, humming servers that have run campus systems forever.
- **Special chapters:** Julian Ch1, second half (the server room tour: "write once, run anywhere")

### Oracle Great Hall
- **id:** `oracle_great_hall`
- **Open:** Story only
- **Description:** The formal ballroom. Chandeliers and a long guest list.
- **Story events:** Winter gala (week 14, Tue, Night)
- **Special chapters:** Julian Ch6 (Generics and streams final: planning the winter gala)
- **Endings:** Julian normal ending, Next release (at the end of the gala, Julian raises a toast to his most trusted council member)

---

## C1. Lovelace Library
Tall shelves, reading lamps, and big west windows. Open in the Day slot, plus late nights during finals week.

### Reading room
- **id:** `lovelace_library` (kept, now the reading room)
- **Open:** Day (and Night in week 14)
- **Description:** Long tables, green reading lamps, and a card catalog nobody uses but Monty.
- **Story events:** Ada Lovelace Day talk (week 6, Tue, Day)
- **Special chapters:** Jay Ch7 (Convert the festival site to TypeScript, final, at dusk: working under the library lights as the sun sets)
- **Lessons:** Generic 17 (Maps and dictionaries: the catalog maps call numbers to books)
- **Endings:** Monty normal ending, In the next version (studying side by side at the same table every night)

### The stacks (new)
- **id:** `library_stacks` (new)
- **Open:** Day
- **Description:** Narrow aisles of shelves and a cart of returns that never gets shorter.
- **Lessons:** Generic 31 (Searching), Generic 32 (Sorting: reshelving returns)

### University Archive (Sun Wing)
- **id:** `university_archive`
- **Open:** Story only (Julian has a key)
- **Description:** Dusty records and old portraits of the Sun household, which the Oracle family later absorbed.
- **Special chapters:** Julian Ch4 (Null and Optional: the missing portrait in the Duke family archive)
- **Lessons:** Generic 21 (Inheritance and polymorphism: family-tree portraits), Generic 23 (File reading and writing: digging through old records)
- **Endings:** Julian bad ending, NullPointerException (she reaches for Julian's hand among the old portraits and finds nothing there)

---

## D1. Knuth Hall
Home of the computer science department, named after Donald Knuth. The lab is in the basement, the project rooms are upstairs, and a fire door at the top of the stairwell opens onto the roof.

### Hopper Computer Lab
- **id:** `hopper_lab`
- **Open:** Day and Night (always open)
- **Description:** The basement. Rows of humming machines and flickering lights. Ciel practically lives here at 2 a.m.
- **Recurring:** Midnight lab session (Ciel, Mon to Thu, Night)
- **Story events:** Orientation campus tour, Ciel's stop (last stop, after dark). Ciel's birthday (week 7, Mon, Night). Polyglot: talk to Ciel (week 13, Night)
- **Special chapters:** Ciel Ch1 (Compiling and types: the heroine stumbles in late at night), Ciel Ch2 (Pointers and references), Ciel Ch3 (Memory management), Ciel Ch5 (Classes and the STL), Ciel Ch6 (Templates final, an all-nighter)
- **Lessons:** Generic 8 (Debugging)
- **Endings:** Ciel normal ending (the lab door left unlocked for her), Ciel good ending CG (both asleep on the keyboard)

### Capstone team room
- **id:** `capstone_room`
- **Open:** Day (Polyglot route only)
- **Description:** Third floor. A glass-walled project room with a big screen for code review.
- **Story events:** Polyglot: the capstone project (week 9), Polyglot: the merge conflict (week 12), Polyglot: the integration test (week 14)

### Knuth Hall rooftop
- **id:** `cs_rooftop`
- **Open:** Story only
- **Description:** Through the fire door at the top of the lab stairwell. Quiet, cold, and facing the sunrise.
- **Endings:** Ciel confession (at dawn after the Templates all-nighter, coat around her shoulders)

---

## A2. Student Union
The loud, busy building on the west edge of campus. Clubs, events, and the best sunset on campus.

### Hackathon hall
- **id:** `hackathon_hall`
- **Open:** Night (doubles as the makerspace in the Day)
- **Description:** A big open room with power strips everywhere, pizza boxes, and LED strips.
- **Recurring:** Hackathon night (Night Jay, Sat and Sun, Night)
- **Story events:** Day 256 Hackathon (week 2, Fri and Sat, Night), Halloween costume party (week 9, Thu, Night)
- **Special chapters:** Jay Ch1 (Variables, night: the heroine meets a wild hacker over pizza), Jay Ch5 (Closures and the DOM: building the campus festival site)
- **Lessons:** Generic 22 (Error handling), Generic 30 (Big-O basics: racing a slow solution against a fast one)
- **Endings:** Jay good ending (launching the site they built together)

### Game dev club room
- **id:** `game_dev_club_room`
- **Open:** Day
- **Description:** A cramped room off the main hall with old consoles and a whiteboard of engine diagrams. Not officially a club. Ciel runs it from the shadows.
- **Recurring:** Game dev club (Ciel, Fri to Sun, Day)
- **Special chapters:** Ciel Ch4 (RAII and smart pointers: Ciel admits he doesn't have to manage everything alone)
- **Endings:** Ciel bad ending, Segmentation fault (the club room is locked and dark, with a note on the door: "Segmentation fault (core dumped)")

### Arcade
- **id:** `union_arcade`
- **Open:** Night
- **Description:** The union basement. Old arcade machines with strange rules and a scoreboard that adds wrong.
- **Special chapters:** Jay Ch3 (Equality and coercion, night: an arcade date full of weird games, where the scoreboard says '5' + 3 is '53')
- **Endings:** Jay normal night ending, Runs everywhere (Night Jay is always at the arcade, always fun, never quite there when it matters)

### Union rooftop
- **id:** `union_rooftop`
- **Open:** Dusk and Night
- **Description:** String lights, a couple of beat-up beanbags, and the best sunset on campus. Night Jay's favorite spot ("We're going to the roof").
- **Story events:** Polyglot: talk to Jay (week 13, Night)
- **Special chapters:** Jay Ch2 ending (the heroine watches the sunset switch happen: the reveal), Jay Ch6 (Async and promises, dusk)
- **Endings:** Polyglot confession (at dusk, so both sides of Jay are there), Polyglot ending epilogue CG (all five at sunset, Quack on her shoulder)

---

## B2–C2. Main Quad
The open center of campus: a big lawn, a fountain with benches, and a sunny hill up toward the library. Hosts orientation, the club fair, and the end-of-term festival.

### Quad lawn
- **id:** `main_quad` (kept, now the lawn)
- **Open:** Day and Night
- **Description:** The center of campus. Students everywhere, a frisbee always in the air.
- **Story events:** Orientation day and campus tour (week 1, Sun: President Fortran's welcome speech, the heroine gets Quack), Club fair (week 1, Fri), Polyglot: the rivalry (week 5)
- **Lessons:** Generic 1 (Printing to the console: the orientation-day help desk), Generic 20 (Classes and objects: the club fair, where every club is an object)

### Fountain bench
- **id:** `fountain_bench`
- **Open:** Day and Night
- **Description:** A stone bench by the quad fountain. A good place to sit and think.
- **Endings:** Merge conflict ending, last scene (the heroine alone with Quack: "So. You and me, then.")

### Picnic hill
- **id:** `picnic_lawn`
- **Open:** Day
- **Description:** The sunny hill at the corner of the quad, up toward the library.
- **Special chapters:** Monty Ch3 (Comprehensions: packing a picnic basket)

### Festival stage (week 14 only)
- **id:** `festival_stage`
- **Open:** Week 14 only (built for the end-of-term festival)
- **Description:** A temporary stage on the quad that runs on the site Jay built.
- **Story events:** End-of-term festival and Jay's birthday (week 14, Wed, Day), End-of-term festival (week 14, Wed, Night)
- **Endings:** Jay confession (at sunset, glasses pushed up into his hair, both sides at once), Merge conflict ending, first scene (everyone walks away at the festival)

---

## D2. Observatory
A small domed building on the hill at the east edge of campus, away from the lights.

### Observatory dome
- **id:** `observatory`
- **Open:** Night (stargazing nights)
- **Description:** A big old telescope under a dome that opens with a loud crank.
- **Lessons:** Generic 28 (Graphs: constellations as nodes and edges)

---

## A3. The Commons
Food and shopping, all under one roof next to the dorms. Short hours during Thanksgiving break.

### The Stack (dining hall)
- **id:** `the_stack`
- **Open:** Day and Night
- **Description:** A big, loud dining hall with a stack of trays at the door and a long lunch line.
- **Lessons:** Generic 4 (Numbers and math: splitting the bill, counting meal swipes), Generic 6 (Booleans and comparisons: comparing meal options), Generic 25 (Stacks and queues: the tray stack and the lunch line)

### Café Cache
- **id:** `cafe_cache`
- **Open:** Day
- **Description:** The campus coffee shop, with a bubble tea counter in the back for Jay. Home of the coffee appreciation society.
- **Recurring:** Coffee appreciation society (Julian, Mon to Thu, Day)
- **Special chapters:** Julian Ch3 (Primitives and wrappers: Julian's formal café mug versus his private thermos), Monty Ch2 (Slicing and unpacking: sharing a playlist with one earbud each)
- **Lessons:** Generic 5 (Strings: names misspelled on cups), Generic 14 (Functions: a drink order goes in, a drink comes out)

### Campus bookstore
- **id:** `bookstore`
- **Open:** Day
- **Description:** Textbooks, hoodies, and a wall of laptop stickers.
- **Lessons:** Generic 2 (Comments: sticky notes in used textbooks), Generic 18 (Sets: a sticker collection with no duplicates), Generic 19 (Iterating over collections: browsing the shelves)

---

## B3. Babbage Hall
The heroine's dorm. Quack talks to her here every night.

### Your room
- **id:** `babbage_hall` (kept, now the heroine's room)
- **Open:** Day and Night
- **Description:** A bed, a desk, a laptop, and a rubber duck with opinions.
- **Story events:** Quack's check-in (week 4, Sat, Night), Thanksgiving break (week 13)
- **Special chapters:** Polyglot week 4 choice (the heroine admits to Quack she can't pick: "You absolute multithreader.")
- **Lessons:** Generic 15 (Scope: what's in your own room versus the common room)

### Common room (new)
- **id:** `dorm_common_room` (new)
- **Open:** Day and Night
- **Description:** A shared lounge with a lumpy couch, a TV, and a bulletin board.
- **Lessons:** Generic 7 (User input: a dorm survey)

### Laundry room
- **id:** `laundry_room`
- **Open:** Day and Night
- **Description:** Four washers and a schedule on the wall that Monty scripted. It actually works.
- **Lessons:** Generic 26 (Recursion: folding a fitted sheet. Fold it in half, then fold that in half, until it's small enough)

---

## C3. Greenhouse and Gardens
Monty's corner of campus: a glass greenhouse, winding garden paths, and a small pond.

### Greenhouse
- **id:** `greenhouse`
- **Open:** Day (lights stay on during the festival)
- **Description:** Warm, humid, and full of labeled plant pots. The gardening club's home.
- **Recurring:** Gardening club (Monty, Sat and Sun, Day)
- **Story events:** Orientation campus tour, Monty's stop. Polyglot: talk to Monty (week 13)
- **Special chapters:** Monty Ch5 (Context managers: cleaning up the potting bench, "it's okay to fail")
- **Endings:** Monty confession (under the greenhouse lights at the end-of-term festival), Monty good ending CG (a plant labeled with her name)

### Hedge maze garden
- **id:** `campus_garden`
- **Open:** Day
- **Description:** Winding paths next to the greenhouse, with a small hedge maze at the center.
- **Special chapters:** Monty Ch6 (Generators and decorators final: exploring the garden paths one step at a time with `yield`)
- **Lessons:** Generic 27 (Trees), Generic 29 (Graph traversal: BFS and DFS through the maze)

### Duck pond
- **id:** `duck_pond`
- **Open:** Day
- **Description:** A small pond by the garden. Quack has opinions about the real ducks.
- **Special chapters:** Monty Ch4 (Duck typing: Quack's starring role)

---

## D3. Athletic Complex
The gym and the running track around the athletic field.

### Gym
- **id:** `fitness_center` (kept, now just the gym)
- **Open:** Day and Night
- **Description:** Weights, mirrors, and a lot of people counting reps.
- **Lessons:** Generic 10 (Logical operators: the front desk lets you in with a student ID AND a signed waiver), Generic 13 (Nested loops and break/continue: sets and reps, and stopping early)

### Running track
- **id:** `running_track`
- **Open:** Day and Night
- **Description:** A loop around the athletic field. Everyone is counting laps.
- **Lessons:** Generic 11 (While loops: running laps until you're tired), Generic 24 (Linked lists: a relay race, where each runner only knows who to hand the baton to next)

---

## Event index
The same information as above, looked up by event. Use this to check `calendar.json`, the route files, and `curriculum.json`.

### Recurring events
| Event (calendar id) | Who | When | Building | Room |
|---|---|---|---|---|
| Office hours (`office_hours`) | Day Jay | Mon–Fri, Day | Turing Hall | TA office |
| Hackathon night (`hackathon_night`) | Night Jay | Sat–Sun, Night | Student Union | Hackathon hall |
| Student council office hours (`council_office_hours`) | Julian | Fri–Sun, Night | Oracle Hall | Student council room |
| Coffee appreciation society (`coffee_society`) | Julian | Mon–Thu, Day | The Commons | Café Cache |
| Gardening club (`gardening_club`) | Monty | Sat–Sun, Day | Greenhouse and Gardens | Greenhouse |
| Tutoring center shift (`tutoring_shift`) | Monty | Mon–Fri, Night | Turing Hall | Tutoring center |
| Game dev club (`game_dev_club`) | Ciel | Fri–Sun, Day | Student Union | Game dev club room |
| Midnight lab session (`midnight_lab`) | Ciel | Mon–Thu, Night | Knuth Hall | Hopper Computer Lab |

### Story and info events
| Week | Event (calendar id) | Building | Room |
|---|---|---|---|
| 1 | Orientation day and campus tour (`orientation`) | Main Quad | Quad lawn, then the four tour stops |
| 1 | Club fair (`club_fair`) | Main Quad | Quad lawn |
| 2 | Day 256 Hackathon (`day_256_hackathon`) | Student Union | Hackathon hall |
| 3 | First problem set due (`problem_set_1`) | Turing Hall | Lecture hall |
| 4 | Quack's check-in (`quack_check_in`) | Babbage Hall | Your room |
| 5 | Polyglot: the rivalry (`polyglot_rivalry`) | Main Quad | Quad lawn |
| 6 | Ada Lovelace Day talk (`ada_lovelace_day`) | Lovelace Library | Reading room |
| 7 | Midterms week (`midterms`) | Turing Hall | Exam hall |
| 7 | Ciel's birthday (`ciel_birthday`) | Knuth Hall | Hopper Computer Lab |
| 9 | Halloween costume party (`halloween_party`) | Student Union | Hackathon hall |
| 9 | Polyglot: the capstone project (`polyglot_capstone`) | Knuth Hall | Capstone team room |
| 10 | Spring course registration opens (`spring_registration`) | Turing Hall | Lecture hall |
| 12 | Julian's half-birthday (`julian_half_birthday`) | Oracle Hall | Student council room |
| 12 | Polyglot: the merge conflict (`polyglot_merge_conflict`) | Knuth Hall | Capstone team room |
| 13 | Thanksgiving break (`thanksgiving_break`) | Babbage Hall | Your room |
| 13 | Polyglot: talk to Monty (`polyglot_resolve_python`) | Greenhouse and Gardens | Greenhouse |
| 13 | Polyglot: talk to Julian (`polyglot_resolve_java`) | Oracle Hall | Student council room |
| 13 | Polyglot: talk to Ciel (`polyglot_resolve_cpp`) | Knuth Hall | Hopper Computer Lab |
| 13 | Polyglot: talk to Jay (`polyglot_resolve_javascript`) | Student Union | Union rooftop |
| 14 | Finals week (`finals`) | Turing Hall | Exam hall |
| 14 | Winter gala (`winter_gala`) | Oracle Hall | Oracle Great Hall |
| 14 | End-of-term festival and Jay's birthday (`jay_birthday_festival`) | Main Quad | Festival stage |
| 14 | End-of-term festival, night (`festival_night`) | Main Quad | Festival stage |
| 14 | Polyglot: the integration test (`polyglot_integration_test`) | Knuth Hall | Capstone team room |

### Orientation tour stops
| Order | Love interest | Building | Room |
|---|---|---|---|
| 1 | Monty | Greenhouse and Gardens | Greenhouse |
| 2 | Jay | Turing Hall | TA office |
| 3 | Julian | Oracle Hall | Student council room |
| 4 (after dark) | Ciel | Knuth Hall | Hopper Computer Lab |

### Special chapters
| Character | Ch | Title | Building | Room |
|---|---|---|---|---|
| Jay | 1 | Variables (night) | Student Union | Hackathon hall |
| Jay | 2 | Type annotations (day, reveal at sunset) | Turing Hall, then Student Union | TA office, then Union rooftop |
| Jay | 3 | Equality and coercion (night) | Student Union | Arcade |
| Jay | 4 | Interfaces (day) | Turing Hall | TA office |
| Jay | 5 | Closures and the DOM (night) | Student Union | Hackathon hall |
| Jay | 6 | Async and promises (dusk) | Student Union | Union rooftop |
| Jay | 7 | Festival site to TypeScript (final, dusk) | Lovelace Library | Reading room |
| Monty | 1 | The Zen of Python | Turing Hall | Tutoring center |
| Monty | 2 | Slicing and unpacking | The Commons | Café Cache |
| Monty | 3 | Comprehensions | Main Quad | Picnic hill |
| Monty | 4 | Duck typing | Greenhouse and Gardens | Duck pond |
| Monty | 5 | Context managers | Greenhouse and Gardens | Greenhouse |
| Monty | 6 | Generators and decorators (final) | Greenhouse and Gardens | Hedge maze garden |
| Julian | 1 | The JVM | Oracle Hall | Student council room, then Server room |
| Julian | 2 | == vs .equals() | Oracle Hall | Student council room |
| Julian | 3 | Primitives and wrappers | The Commons | Café Cache |
| Julian | 4 | Null and Optional | Lovelace Library | University Archive |
| Julian | 5 | Checked exceptions | Oracle Hall | Student council room |
| Julian | 6 | Generics and streams (final) | Oracle Hall | Oracle Great Hall |
| Ciel | 1 | Compiling and types | Knuth Hall | Hopper Computer Lab |
| Ciel | 2 | Pointers and references | Knuth Hall | Hopper Computer Lab |
| Ciel | 3 | Memory management | Knuth Hall | Hopper Computer Lab |
| Ciel | 4 | RAII and smart pointers | Student Union | Game dev club room |
| Ciel | 5 | Classes and the STL | Knuth Hall | Hopper Computer Lab |
| Ciel | 6 | Templates (final) | Knuth Hall | Hopper Computer Lab |

### Endings
Each route ending plays in one room. Confessions come right before the good endings.

| Route | Ending | Building | Room |
|---|---|---|---|
| Monty | Confession | Greenhouse and Gardens | Greenhouse |
| Monty | Good: Co-authors | Greenhouse and Gardens | Greenhouse |
| Monty | Normal: In the next version | Lovelace Library | Reading room |
| Monty | Bad: DeprecationWarning | Turing Hall | Tutoring center |
| Julian | Confession | Oracle Hall | Council balcony |
| Julian | Good: Vice president | Oracle Hall | Student council room |
| Julian | Normal: Next release | Oracle Hall | Oracle Great Hall |
| Julian | Bad: NullPointerException | Lovelace Library | University Archive |
| Ciel | Confession | Knuth Hall | Knuth Hall rooftop |
| Ciel | Good: In the credits | Knuth Hall | Hopper Computer Lab |
| Ciel | Normal: Door unlocked | Knuth Hall | Hopper Computer Lab |
| Ciel | Bad: Segmentation fault | Student Union | Game dev club room |
| Jay | Confession | Main Quad | Festival stage |
| Jay | Good: Both halves | Student Union | Hackathon hall |
| Jay | Normal (day): Strict mode | Turing Hall | TA office |
| Jay | Normal (night): Runs everywhere | Student Union | Arcade |
| Jay | Bad: undefined | Turing Hall | Lecture hall |
| Polyglot | Confession | Student Union | Union rooftop |
| Polyglot | Good: The Polyglot ending | Student Union | Union rooftop |
| Polyglot | Bad: The merge conflict ending | Main Quad | Festival stage, then Fountain bench |

### Generic subjects
| # | Subject | Building | Room |
|---|---|---|---|
| 1 | Printing to the console | Main Quad | Quad lawn |
| 2 | Comments | The Commons | Campus bookstore |
| 3 | Variables and assignment | Turing Hall | Lecture hall |
| 4 | Numbers and math | The Commons | The Stack |
| 5 | Strings | The Commons | Café Cache |
| 6 | Booleans and comparisons | The Commons | The Stack |
| 7 | User input | Babbage Hall | Common room (new) |
| 8 | Debugging | Knuth Hall | Hopper Computer Lab |
| 9 | If/else | Turing Hall | Lecture hall |
| 10 | Logical operators | Athletic Complex | Gym |
| 11 | While loops | Athletic Complex | Running track |
| 12 | For loops | Turing Hall | Tutoring center |
| 13 | Nested loops and break/continue | Athletic Complex | Gym |
| 14 | Functions | The Commons | Café Cache |
| 15 | Scope | Babbage Hall | Your room |
| 16 | Arrays and lists | Turing Hall | Locker hallway (new) |
| 17 | Maps and dictionaries | Lovelace Library | Reading room |
| 18 | Sets | The Commons | Campus bookstore |
| 19 | Iterating over collections | The Commons | Campus bookstore |
| 20 | Classes and objects | Main Quad | Quad lawn |
| 21 | Inheritance and polymorphism | Lovelace Library | University Archive |
| 22 | Error handling | Student Union | Hackathon hall |
| 23 | File reading and writing | Lovelace Library | University Archive |
| 24 | Linked lists | Athletic Complex | Running track |
| 25 | Stacks and queues | The Commons | The Stack |
| 26 | Recursion | Babbage Hall | Laundry room |
| 27 | Trees | Greenhouse and Gardens | Hedge maze garden |
| 28 | Graphs | Observatory | Observatory dome |
| 29 | Graph traversal (BFS, DFS) | Greenhouse and Gardens | Hedge maze garden |
| 30 | Big-O basics | Student Union | Hackathon hall |
| 31 | Searching | Lovelace Library | The stacks (new) |
| 32 | Sorting | Lovelace Library | The stacks (new) |
| 33 | Dynamic programming | Turing Hall | Exam hall |

---

## What changed from the old Setting.md
- Locations are grouped by **building** instead of by theme ("Academic buildings", "Outdoors"), so each map shape has a clear room list.
- The CS building is now **Knuth Hall** (Gee, 2026-11-03).
- The made-up "Council hall" is now **Oracle Hall**, the administration building. It holds the council room, balcony, server room and Oracle Great Hall.
- "Food court" is now **The Commons**.
- The exam hall and tutoring center are now clearly inside **Turing Hall** (they were placed there in `locations.json` but not in this doc).
- Outdoor spots are grouped into three areas: **Main Quad** (with the picnic hill moved onto it from "behind the library"), **Greenhouse and Gardens**, and **Athletic Complex** (gym and track).
- Rooms split out so specialty spots have their own entry: Locker hallway, The stacks, Common room, Laundry room, Running track.
- **The carnival is gone** (Gee, 2026-11-03), including Fright Night, because generic lessons shouldn't be tied to time-limited events. Generic 10 moved to the gym, Generic 24 to the running track, Generic 26 to the laundry room, and Jay Ch3 to the new union Arcade.
- Orientation tour stops (Gee, 2026-11-03): Monty in the greenhouse, Jay in the TA office, Julian in the council room, Ciel in Hopper Lab.
